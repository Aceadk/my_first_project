# Real-Time Infrastructure Audit - 2026-06-02

Scope: `REAL-001`, `REAL-002`, and `REAL-003` from [`docs/TODO_REALTIME.md`](../TODO_REALTIME.md).

Surface reviewed: realtime transports (`lib/core/network/realtime/`), connectivity
(`lib/core/connectivity/`), chat realtime (`firebase_chat_repository.dart`, chat
BLoCs), calls (`lib/features/calls/`, `functions/src/calls/signaling.ts`), presence/
typing (Cloud Function callables + `database.rules.json`), security rules
([`firestore.rules`](../../firestore.rules), [`database.rules.json`](../../database.rules.json)),
and DI wiring ([`lib/core/di.dart`](../../lib/core/di.dart)).

Related prior work (not re-litigated here): [`chat_realtime_audit_2026-06-01.md`](chat_realtime_audit_2026-06-01.md)
covers chat-level reconnect/dedupe/ordering/typing-TTL/offline-queue. This audit
is at the infrastructure altitude (connection auth, multi-device semantics,
observability) and spans messaging, calls, and notifications.

## Result

All three tasks are complete. Authorization on realtime subscriptions is
enforced by deny-by-default rules plus authenticated + App Check-gated callables
(REAL-001). Concurrent device/tab behavior is deterministic for messaging,
calls, and notifications and is documented below, with one non-deterministic case
(multi-device presence) called out with a fix recommendation (REAL-002). Metrics
and alert thresholds are documented in the new
[`docs/REALTIME_OBSERVABILITY.md`](../REALTIME_OBSERVABILITY.md) (REAL-003). No
production security gaps were found; the findings are dead/parallel code and
graceful-disconnect/heartbeat improvements, captured as recommendations.

Legend: ✅ verified correct · ⚠️ finding/recommendation · 📋 documented.

---

## Architecture (as built)

Production runs `BackendMode.firebase` / `hybrid`
([`di.dart:224-251`](../../lib/core/di.dart)) → realtime is **Firebase-native**:

| Channel | Transport | Auth | Authorization |
|---------|-----------|------|---------------|
| Chat messages, chat list, matches | Firestore `snapshots()` (`firebase_chat_repository.dart`) | Firebase ID token (SDK auto-refresh) | `firestore.rules` |
| Presence | Firestore `presence/{uid}` (`watchPresence`/`setPresence`) | ID token | `firestore.rules` (owner write; premium read) |
| Typing | Firestore `matches/{id}.typing.{uid}` via `setTyping` callable | ID token + App Check | callable + match-membership check |
| New-match push | RTDB `users/{uid}/newMatches` (`realtime_match_service.dart:46`) | ID token | `database.rules.json` |
| Calls (signaling/state) | `initiateCall`/`answerCall`/`endCall` callables → `calls/{id}` doc snapshot (`call_service.dart:348`) | ID token + App Check | callable participant checks + `firestore.rules` |
| Calls (media) | Agora (`generateAgoraToken`/`getAgoraToken`) | ID token + App Check | server-minted Agora token |
| Connectivity | `ConnectivityCubit` DNS poll every 15s (`connectivity_cubit.dart`) | n/a | n/a |

`BackendMode.http` is an **alternate, non-production** REST path
(`HttpChatRepository` → `HttpChatTransportAdapter` → `WebSocketConnection`). It is
not used by the Firebase build; findings against it are marked accordingly.

---

## REAL-001 - Connection lifecycle and authorization

Status: Pass (authorization verified; lifecycle documented; findings are
dead/parallel code + a graceful-disconnect gap)

### ✅ Unauthorized subscriptions are blocked
- Firestore subscriptions are gated by `firestore.rules` (audited in
  `database_audit_2026-06-02.md`): `matches`/`messages` require active membership
  + no block relationship; `presence` non-owner reads require premium; `auth_*`,
  `usernames` deny all client access; `calls` reads require participant.
- RTDB subscriptions are gated by `database.rules.json`: `premium_users`,
  `message_deletion_queue` deny all client access; `presence`/`typing`/`last_seen`/
  `read_receipts` reads require premium; `users/{uid}/newMatches` is owner-only;
  `$other` denies everything else.
- All Cloud Function callables require auth (`requireAuth`) and, in production,
  a valid **App Check** token (`enforceCallableAppCheck = isProductionRuntime`,
  `functions/src/shared/callable.ts:20`). Call signaling additionally enforces
  participant checks (`assertCallParticipant`), receiver-only answer, a 1-call/10s
  rate limit, and a 30s ring timeout (`signaling.ts`).

### 📋 Lifecycle semantics (documented)
- **Connect:** Firestore/RTDB connections are established and authenticated by the
  Firebase SDK using the current ID token; no app-level handshake.
- **Reconnect:** Firestore/RTDB reconnect and re-attach listeners automatically
  (SDK-managed, with local cache continuity). The `WebSocketConnection` (http
  mode) implements exponential backoff + jitter, a 5-attempt cap, and
  heartbeat/pong-timeout (2× interval) detection — covered by
  `realtime_connection_test.dart`.
- **Graceful disconnect:** `ChatBloc` observes app lifecycle and writes
  `setPresence(false)` + clears typing on background/hidden/detached, and
  `setPresence(true)` on resume (see `chat_realtime_audit_2026-06-01.md`,
  CHAT-RT-002). Intentional WS disconnects set `_intentionalDisconnect` to suppress
  reconnect storms.

### ⚠️ Findings
1. **Dead realtime service with wrong schema.** `FirebaseRealtimeService`
   (`firebase_realtime_service.dart`) has **no production references** (only its
   own test). It targets a nonexistent `conversations` collection and snake_case
   fields (`created_at`, `participant_ids`, `is_online`, `user_ids`) that do not
   match the live schema (`matches`, `sentAt`, `userIds`, `isOnline`).
   *Recommend:* delete it (and its test) to remove a misleading "how realtime
   works" reference. Left in place this pass (parallels the dead-index decision in
   the DB audit).
2. **Unused/unreadable WebRTC ICE signaling.** The backend exposes
   `addIceCandidate`/`getIceServers` and writes `calls/{callId}/iceCandidates/*`
   (`signaling.ts:554`), but the mobile client never reads `iceCandidates` (no
   references in `lib/`; media uses Agora). That subcollection also has **no
   `firestore.rules` match** (deny-by-default, no recursive wildcard), so clients
   could not read it even if they tried. *Recommend:* either remove the unused
   WebRTC signaling functions, or add rules + client wiring if WebRTC is intended
   for the web client.
3. **WS auth weaknesses (http mode only, non-production).** `WebSocketConnection`
   passes the auth token as a URL query param (`?token=`,
   `realtime_connection.dart:92`) — leakable via logs/proxies — and captures the
   token once, reusing it on every reconnect with **no refresh**, so a long-lived
   reconnect uses a stale/expired token. *Recommend (only if http mode is ever
   productionized):* move the token to a header/subprotocol and inject a
   token-provider for refresh on reconnect.
4. **RTDB `read_receipts` write is not participant-scoped.** `read_receipts/$matchId/$messageId`
   has `.write: auth != null` (no participant check; RTDB rules cannot cross-check
   Firestore membership). Reads are premium-gated and require knowing
   `matchId`+`messageId`, and the canonical read state is Firestore `message.isRead`,
   so impact is low. Note the RTDB `presence`/`typing`/`read_receipts` trees are
   largely **unused** by the current Firestore-based client. *Recommend:* drop the
   unused RTDB trees, or move read receipts behind a callable if they are revived.
5. **Graceful-disconnect / stale-online gap — 🔧 FIXED (2026-06-02).**
   Previously `watchPresence` returned online whenever `isOnline == true`,
   applying the 2-minute `lastSeen` freshness window **only** when
   `isOnline == false` — so a hard crash/kill/network-drop with no clean
   background event left the peer shown "online" indefinitely. Fix:
   - `watchPresence` now delegates to the pure
     `FirebaseChatRepository.isPresenceOnline(data, now)`, which returns online
     **iff** `isOnline == true` **and** `lastSeen` is within
     `presenceFreshnessWindow` (2 min) — the freshness check is unconditional, so
     a stale heartbeat decays to offline.
   - To stop an actively-open chat from wrongly decaying, `ChatBloc` now runs a
     **presence heartbeat** (`ChatPresenceHeartbeatTick`, every 45s < the 2-min
     window) that refreshes `lastSeen` while a chat is open and foregrounded;
     it is stopped on background/close/reset and restarted on resume.
   - Covered by `firebase_chat_repository_presence_test.dart` (freshness/stale/
     boundary cases) and new `chat_bloc_test.dart` heartbeat cases.
   A server-side RTDB `onDisconnect` would still be the most robust backstop
   (instant offline on socket drop rather than after the window) and is left as a
   future enhancement.

Test coverage (existing): `realtime_connection_test.dart` (connect/send/receive,
pong-ignore, fail-fast, exhausted-reconnect→failed, heartbeat ping, heartbeat
timeout closes stale socket), `realtime_state_cubit_test.dart`,
`session_manager_test.dart`, `session_bloc_test.dart`.

---

## REAL-002 - Concurrent device/tab semantics

Status: Pass (deterministic for messaging/calls/notifications; one
non-deterministic case documented with a recommendation)

A user may be signed in on multiple devices/tabs simultaneously (Firebase Auth
supports concurrent sessions natively; each app instance holds its own session).
Behavior per channel:

| Channel | Multi-device behavior | Deterministic? |
|---------|----------------------|----------------|
| **Messaging** | Firestore is the single source of truth; every device/tab attaches its own listener and converges to the same ordered set. Optimistic sends are reconciled by `MessageReconciler` (dedupe by id, then content signature within 30s). | ✅ Yes |
| **Read state** | `message.isRead`/`readAt` are per-message in Firestore; marking read on one device propagates to all. | ✅ Yes |
| **Calls** | Incoming call FCM fans out to **all** of the receiver's `fcmTokens` (every device rings). `answerCall` is receiver-only, transactional, and requires `status == 'ringing'` (`signaling.ts:471-500`), so the **first device to answer wins**; other devices observe `status → ongoing` via the `calls/{id}` snapshot and stop ringing. The 30s ring timeout marks `missed` if no device answers. | ✅ Yes (first-answer-wins) |
| **Notifications** | FCM multicast to all tokens; server applies quiet-hours/muted/block filters. New-match RTDB notifications at `users/{uid}/newMatches/{matchId}` are read-then-deleted by the client (`.write` requires `!newData.exists()`); concurrent devices may each display once before the first delete clears it. | ✅ Yes (at-least-once; brief double-display possible) |
| **Presence** | Single `presence/{uid}` document, last-writer-wins. | ⚠️ **No** — see below |

### ⚠️ Non-deterministic: multi-device presence (partially mitigated 2026-06-02)
Presence is a single per-user document with no per-connection ref-counting.
Backgrounding or signing out on **one** device writes `isOnline = false`, flipping
the user's global presence to offline even if another device is still active.
The presence heartbeat added for REAL-001 #5 now **self-corrects** this: an active
device re-asserts `isOnline:true` on its next ≤45s heartbeat, so the flip is a
brief flicker rather than a stuck-offline state. The fully deterministic fix —
track presence per connection (RTDB `onDisconnect` with a connections list; mark
offline only when the last connection drops) — remains recommended.

Manual multi-session smoke checklist:
- Sign in on two devices; send from A, confirm B and a third (web) tab converge to
  the same order with no duplicate optimistic bubble.
- Call a user signed in on two devices; confirm both ring, answering on one stops
  the other, and the caller sees `ongoing`.
- Mark a thread read on A; confirm unread count clears on B.
- Background device A while device B stays active; confirm presence behavior matches
  the documented (and recommended) semantics.

---

## REAL-003 - Load and observability baselines

Status: Pass (metrics + thresholds documented; load-test dry run documented with a
simulated capture)

- Authored [`docs/REALTIME_OBSERVABILITY.md`](../REALTIME_OBSERVABILITY.md): the
  core realtime metric catalog (active listeners, Firestore reads/sec, RTDB
  connections, callable latency/error rate, message-deletion-queue depth, call
  setup success rate, push delivery), alert thresholds, dashboards, and a
  load-test dry-run procedure with a simulated metric capture.
- Existing instrumentation: Crashlytics (`CrashReportingService.recordError`),
  Firebase Performance traces (`performance_monitor.dart`), and 108 structured
  `console.*` events in the functions backend (Cloud Logging → log-based metrics).
- ⚠️ Gap: there is no metric/dashboard for active realtime listener counts,
  message delivery latency, or callable error-rate, and several functions swallow
  errors as warnings (e.g., backup export, push failures). Thresholds + the
  log-based-metric definitions to close this are specified in the observability doc.

---

## Verification

- One code fix was made (the stale-online presence gap, REAL-001 #5):
  `firebase_chat_repository.dart` (`watchPresence` → pure `isPresenceOnline` with
  an unconditional freshness window), `chat_bloc.dart` + `chat_event.dart`
  (presence heartbeat). The remaining findings stay as documented recommendations
  because their fixes (WS token handling, removing dead services/rules, RTDB
  `onDisconnect`) need product + cross-platform decisions.
- `flutter analyze` on the changed lib + test files — **no issues**.
- `flutter test test/features/chat/data/repositories/impl/firebase_chat_repository_presence_test.dart test/chat_bloc_test.dart` — **33 passing** (7 new presence-freshness cases + 2 new heartbeat cases + unchanged CHAT-RT-002 lifecycle cases).
- Regression check: `flutter test test/message_handling_bloc_test.dart test/realtime_state_cubit_test.dart test/matches_bloc_test.dart test/core/network/realtime/realtime_connection_test.dart` — **52 passing**.
- Authorization was verified by source review of [`firestore.rules`](../../firestore.rules),
  [`database.rules.json`](../../database.rules.json), and
  `functions/src/shared/callable.ts` (auth + App Check enforcement) against each
  subscription path in the architecture table.
- Existing reconnect/auth/session smoke coverage reviewed (not modified):
  `realtime_connection_test.dart`, `session_manager_test.dart`,
  `session_bloc_test.dart`, `realtime_match_service_test.dart`.
