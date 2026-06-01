# TODO: Chat Realtime Module

- Priority: P0 – Critical
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_REALTIME.md`, `docs/TODO_CHAT_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### CHAT-RT-001 - Harden reconnect, dedupe, and message ordering
- Files: realtime transports, chat repositories, local queue/sync helpers
- Description: Verify message delivery guarantees under reconnect, retry, tab/device duplication, and weak networks.
- Acceptance Criteria: out-of-order, duplicate, and dropped-message paths are covered and deterministic.
- Testing: repository/integration tests simulating reconnects and concurrent sends.
- Status: done — fixed + verified 2026-06-01 (analyze clean; 103 chat/realtime tests passing). Added pure `lib/features/chat/domain/usecases/message_reconciler.dart` (dedupe by id, deterministic `sentAt`+`id` ordering, out-of-order repair, idempotent under reconnect replay, optimistic↔server reconciliation within a 30s window, anchor-aware memory caps) and wired it into `MessageHandlingBloc` (`_onNewMessages`/`_onLoadMore`/`_onLegacyMessages`) and both display getters. Fixed: live messages were appended (out-of-order), sorts had no tie-break, and optimistic dedup was missing from the paginated display path. Covered by `test/features/chat/domain/usecases/message_reconciler_test.dart`. See `docs/reports/chat_realtime_audit_2026-06-01.md`.

### CHAT-RT-002 - Audit typing indicators and read receipts under lifecycle changes
- Files: typing/read receipt emitters, debounce logic, app lifecycle handlers
- Description: Ensure indicators stay accurate when the app backgrounds, foregrounds, or resizes in tablet multitasking.
- Acceptance Criteria: indicators do not linger or disappear incorrectly during lifecycle transitions.
- Testing: realtime logic tests plus manual background/foreground checks.
- Status: in progress — fixed + verified 2026-06-01 (analyze clean; lifecycle tests passing). `ChatBloc` now observes app lifecycle (guarded `WidgetsBindingObserver`) and, for the active conversation, clears the user's own typing + sets presence offline on background and restores presence on resume (new `ChatAppLifecycleChanged` event); `ChatInputBar` resets its local typing flag on background; `HttpChatRepository` gained a receiver-side typing TTL (injectable, default 6s) so a peer's indicator self-clears if no refresh arrives. Fixed: outgoing "typing…" lingered when backgrounding froze the debounce timer, and the WS path had no receiver-side typing expiry. Covered by new cases in `chat_bloc_test.dart` and `http_chat_repository_transport_adapter_test.dart`. Remaining: manual device/screen-reader pass for timing across background/foreground/tablet-multitasking. See `docs/reports/chat_realtime_audit_2026-06-01.md`.

### CHAT-RT-003 - Define offline queue and sync recovery policy
- Files: offline caches, pending message stores, reconnect sync logic
- Description: Document and harden what happens when users compose or receive messages offline and reconnect later.
- Acceptance Criteria: offline send/receive semantics are defined; rollback/retry behavior is tested.
- Testing: offline/reconnect integration coverage.
- Status: in progress — policy defined + hardened + verified 2026-06-01 (analyze clean; `test/core/cache/offline_queue_test.dart` passing). Rewrote `lib/core/cache/offline_queue.dart`: strict FIFO head-blocking replay (a failing action is retried in place so later actions can't overtake it — preserving the ordering `MessageReconciler` guarantees on read); transient (network/outage) failures retry with exponential backoff + jitter without consuming the retry budget, while handler-reported `retryable` consumes `maxRetries` then dead-letters and `failed` drops immediately; idempotent enqueue via `PendingAction.dedupeKey`; observable capacity eviction (`QueueStatus.droppedCount`/`hasDropped`). Public API + persisted JSON kept backward-compatible. Remaining: wire the queue into the send path with a stable dedupeKey and trigger `processAll` on connectivity restore (queue is ready). See `docs/reports/chat_realtime_audit_2026-06-01.md`.
