# Chat Realtime Audit — CHAT-RT-001 / 002 / 003

- Date: 2026-06-01
- Source TODO: `docs/TODO_CHAT_REALTIME.md`
- Scope: realtime transports (`lib/core/network/realtime/`), chat repositories
  (`lib/features/chat/data/repositories/impl/`), message-handling BLoC + state,
  typing/presence emitters, app-lifecycle handlers, and the offline action
  queue (`lib/core/cache/offline_queue.dart`).
- Verification (local, full toolchain):
  - `flutter analyze` on all changed files: **clean, 0 issues.**
  - `flutter test` (12 suites, the new ones + every chat/realtime suite that
    exercises the changed code): **103 passing.** Suites:
    `message_reconciler_test`, `offline_queue_test`,
    `message_handling_bloc_test`, `chat_bloc_test`,
    `chat_bloc_media_limit_test`, `chat_event_test`,
    `chat_state_collection_semantics_test`, `realtime_state_cubit_test`,
    `http_chat_repository_transport_adapter_test`,
    `http_chat_repository_contract_test`,
    `http_chat_repository_realtime_polling_test`,
    `realtime_connection_test`.
  - Not run here (needs a device/emulator): manual background↔foreground and
    screen-reader passes — tracked below.

Legend: ✅ already correct · ⚠️ gap found · 🔧 fixed this pass · 🔎 tracked.

---

## CHAT-RT-001 — Reconnect, dedupe, message ordering (🔧 fixed)

### What was already correct
- `WebSocketConnection` (`realtime_connection.dart`) has exponential backoff +
  jitter, heartbeat/pong-timeout detection, and re-entrancy guards on
  connection-loss handling.
- `MessageHandlingBloc._onNewMessages` already de-duplicated incoming messages
  by id before appending.
- The Firestore repository orders by `sentAt` server-side; the HTTP repository
  uses keyset pagination.

### ⚠️ Gaps found
1. **Out-of-order live messages.** `_onNewMessages` *appended* new messages
   (`[...existing, ...new]`), assuming every new message is chronologically
   after the current tail. A message authored earlier but delivered late
   (offline sync, slow fan-out, clock skew, reconnect replay) rendered at the
   bottom instead of its true position.
2. **Unstable ordering.** Every sort used `sentAt` alone. Two messages sharing a
   timestamp (common for batched writes) could visibly reshuffle between
   rebuilds and differ across devices.
3. **Optimistic/server duplication window.** Optimistic reconciliation (drop the
   temp bubble once the server echo lands) existed *only* in the legacy stream
   path. In the paginated path, the display getter (`allMessages`) merged
   pending + confirmed with no signature reconciliation, so a "sending" bubble
   and its just-arrived server copy could both show briefly.

### 🔧 Fix
New pure module `lib/features/chat/domain/usecases/message_reconciler.dart` —
no I/O, no clock, no singletons, so the delivery guarantees are exhaustively
unit-testable:
- `mergeServerMessages` — dedupe by id (server copy wins, carrying
  authoritative read/moderation/reaction state), **deterministic total order**
  (`sentAt` then `id` tie-break), out-of-order repair, idempotent under replay,
  non-mutating.
- `combineForDisplay` / `resolvedPendingIds` / `prunePending` — reconcile
  optimistic temp messages with confirmed copies by id or by content signature
  within a 30s window, so a confirmed send never double-renders.
- `capKeepingNewest` / `capKeepingOldest` — memory-cap eviction that respects
  the user's anchor (drop oldest while live-tailing; drop newest while paging
  up through history).

Wired into `MessageHandlingBloc` (`_onNewMessages`, `_onLoadMore`,
`_onLegacyMessages`) and both display getters (`MessageHandlingState`,
`ChatState`). The previous bespoke signature loop in `_onLegacyMessages` was
replaced by `prunePending` so all reconciliation shares one window/definition.

Covered by `message_reconciler_test.dart` (dedupe, out-of-order insertion,
idempotent replay, deterministic ties, optimistic resolution in/out of window,
memory caps) plus the existing bloc-level dedupe tests.

> Note: the dedupe fix surfaced an unrealistic fixture in
> `chat_bloc_media_limit_test.dart` that seeded 8 media messages with identical
> ids (`List.filled`). Correct dedup collapsed them to one, so the media-count
> limit was never reached. The fixture now uses unique ids (`List.generate`),
> which matches production and preserves the test's intent.

---

## CHAT-RT-002 — Typing & read receipts under lifecycle (🔧 fixed)

### ⚠️ Gaps found
1. **Lingering outgoing "typing…".** The sender's typing state was cleared only
   on the 2.5s debounce (`ChatInputBar`) or chat close. When the app is
   backgrounded the OS freezes those timers, so the peer kept seeing "typing…"
   indefinitely. `ChatBloc` cleared typing/presence on `ChatClosed` (screen
   dispose) but **not** on app background — the common case.
2. **No receiver-side typing TTL on the WebSocket path.** The HTTP/WS repository
   showed typing purely from the last `typing:true` event with no expiry, so a
   peer who stopped typing without emitting `typing:false` (closed tab, crash,
   frozen background timer) left the indicator stuck. (The Firestore path
   self-heals via its 5s freshness window; the WS path had no equivalent.)

### 🔧 Fix
- `ChatBloc` now observes app lifecycle (`WidgetsBindingObserver`, registration
  guarded so the BLoC still builds in binding-less unit tests). It records the
  active conversation from `ChatOpened`; on `paused`/`hidden`/`detached` it
  emits `setTyping(isTyping:false)` and `setPresence(false)`, and on `resumed`
  restores `setPresence(true)`. `inactive` is ignored to avoid flapping on
  momentary interruptions. New `ChatAppLifecycleChanged` event keeps the logic
  in the testable event pipeline.
- `ChatInputBar` resets its local debounce/`_isTypingSent` flag on background so
  re-typing after resume correctly re-announces.
- `HttpChatRepository` adds a receiver-side typing TTL (default 6s, injectable
  for tests) that auto-clears the indicator if no refresh arrives, mirroring the
  Firestore 5s freshness window with jitter margin. An explicit `typing:false`
  still clears immediately.

Covered by new cases in `chat_bloc_test.dart` (background clears typing +
presence; resume restores presence; no-op when no active conversation) and
`http_chat_repository_transport_adapter_test.dart` (TTL auto-clear; explicit
stop clears immediately).

### 🔎 Tracked
- Manual device pass: confirm the indicator timing feels right and the
  screen-reader announces typing/online transitions on real hardware.

---

## CHAT-RT-003 — Offline queue & sync recovery policy (🔧 fixed)

`OfflineActionQueue` existed but had no consumers yet and three correctness
gaps for ordered messaging:

### ⚠️ Gaps found
1. **Retry reordered the queue.** On `ActionResult.retryable` the action was
   moved to the **back** (`removeFirst` + `add`), so a transiently-failing
   message could be overtaken by a later one — breaking the very ordering
   guarantee `MessageReconciler` restores on the read side.
2. **No idempotency.** Enqueuing the same logical action twice (double-tap,
   replayed mutation, re-hydration after restart) duplicated side effects.
3. **Silent eviction.** At the 500-entry cap the oldest action was dropped with
   no signal — silent data loss (potentially an unsent message).

### 🔧 Fix + documented policy
Rewrote `processAll` and `enqueue` (public API kept backward-compatible;
persisted JSON still parses, with `dedupeKey` back-filled from `id`):
- **Strict FIFO, head-blocking.** The head is never reordered; a failing action
  is retried in place so action _N+1_ never overtakes action _N_.
- **Transient vs. bounded failure.** A thrown error (network/outage) is
  transient: the head is preserved and retried with exponential backoff + jitter
  **without** consuming the retry budget, so a genuine send survives an
  arbitrarily long outage. A handler returning `retryable` consumes
  `maxRetries` and is dead-lettered when exhausted; `failed` drops immediately.
- **Idempotent enqueue** via `PendingAction.dedupeKey` (defaults to `id`).
- **Observable eviction** — capacity drops increment `QueueStatus.droppedCount`
  / `hasDropped` and log, surfacing data loss instead of hiding it.

Covered by new `offline_queue_test.dart`: FIFO success order; transient head
blocks later actions until it succeeds; transient failures don't consume the
budget; `retryable` dead-letters after `maxRetries` then continues; `failed`
drops immediately; idempotent enqueue; observable eviction; persistence +
dedupeKey reload + legacy back-fill.

### 🔎 Tracked
- Wire the hardened queue into the send path (register a `send_message` handler
  and enqueue with a stable `dedupeKey` such as `send:$matchId:$clientId`) and
  trigger `processAll` on connectivity restore. The queue is now ready; the
  repository wiring + connectivity trigger is a follow-up integration step.

---

## Summary of changes this pass
- `lib/features/chat/domain/usecases/message_reconciler.dart` — new pure module.
- `lib/features/chat/presentation/bloc/message_handling_bloc.dart`,
  `chat_state.dart` — route ordering/dedupe/optimistic display through it.
- `lib/features/chat/presentation/bloc/chat_bloc.dart`, `chat_event.dart` —
  lifecycle-driven typing/presence (`ChatAppLifecycleChanged`).
- `lib/features/chat/presentation/widgets/chat_input_bar.dart` — reset local
  typing flag on background.
- `lib/features/chat/data/repositories/impl/http_chat_repository.dart` —
  receiver-side typing TTL (injectable).
- `lib/core/cache/offline_queue.dart` — FIFO-preserving retry + backoff,
  idempotent enqueue, observable eviction, dead-letter policy.
- Tests: `message_reconciler_test.dart` (new),
  `offline_queue_test.dart` (new), additions to `chat_bloc_test.dart` and
  `http_chat_repository_transport_adapter_test.dart`, fixture fix in
  `chat_bloc_media_limit_test.dart`.

## Tracked follow-ups
1. Wire `OfflineActionQueue` into the chat send path + connectivity-triggered
   `processAll` (queue is ready).
2. Manual device pass for typing/presence timing and screen-reader behaviour
   across background/foreground/tablet-multitasking.
