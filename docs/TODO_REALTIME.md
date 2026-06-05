# TODO: Real-Time Infrastructure

- Priority: P0 – Critical
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_CHAT_REALTIME.md`, `docs/TODO_CHAT_BACKEND.md`, `docs/TODO_CALLS.md`
- Assigned: AI + Developer

## Tasks

### REAL-001 - Audit connection lifecycle and authorization
- Files: realtime transports, websocket/connectivity helpers, backend subscription gates
- Description: Verify connection auth, reconnect rules, subscription permissions, and graceful disconnect handling.
- Acceptance Criteria: unauthorized subscriptions are blocked; lifecycle semantics are documented.
- Testing: realtime auth and reconnect smoke coverage.
- Status: done (2026-06-02). Verified unauthorized subscriptions are blocked (firestore.rules + database.rules.json deny-by-default; callables require auth + App Check). Documented connect/reconnect/graceful-disconnect lifecycle. **Fixed the stale-online graceful-disconnect gap:** `watchPresence` now applies the `lastSeen` freshness window unconditionally (pure `isPresenceOnline`) and `ChatBloc` runs a 45s presence heartbeat, so a crashed/killed client decays to offline; covered by `firebase_chat_repository_presence_test.dart` + new `chat_bloc_test.dart` cases. Remaining findings (dead `FirebaseRealtimeService`, unused/unreadable ICE signaling, WS token-in-query [http mode], unused RTDB read-receipt tree, RTDB `onDisconnect` backstop) recorded with recommendations. Report: `docs/reports/realtime_audit_2026-06-02.md`.

### REAL-002 - Define concurrent device/tab semantics
- Files: session tracking, realtime presence, delivery/read state handlers
- Description: Document what happens when users connect from multiple devices or browser tabs simultaneously.
- Acceptance Criteria: concurrent-session behavior is deterministic for messaging, calls, and notifications.
- Testing: multi-session manual or automated smoke tests.
- Status: done (2026-06-02). Documented deterministic multi-device semantics for messaging (Firestore convergence + `MessageReconciler`), read state, calls (first-answer-wins via receiver-only transactional `answerCall`), and notifications (FCM multicast + server filters). The one non-deterministic case — multi-device presence (single last-writer-wins doc) — is now self-correcting via the REAL-001 heartbeat (an active device re-asserts online within 45s of another device's background write); full per-connection ref-counting via RTDB `onDisconnect` remains recommended. Manual multi-session smoke checklist in report. Report: `docs/reports/realtime_audit_2026-06-02.md`.

### REAL-003 - Add load and observability baselines for realtime paths
- Files: monitoring hooks, metrics docs, load-test helpers
- Description: Establish basic connection-count, latency, and failure-rate observability for realtime services.
- Acceptance Criteria: core realtime metrics and alert thresholds are documented.
- Testing: load-test dry run or simulated metric capture.
- Status: done (2026-06-02). Authored `docs/REALTIME_OBSERVABILITY.md` — core metric catalog (M1–M11: callable error-rate/latency, Firestore reads, RTDB connections, deletion-queue age, call setup success, scheduled-job health), alert thresholds, dashboards, and a load-test dry-run procedure with a simulated metric capture. Ops follow-ups (create dashboard/alerts, log-based metrics, first staging run) tracked in §5.
