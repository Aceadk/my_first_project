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
- Status: open

### REAL-002 - Define concurrent device/tab semantics
- Files: session tracking, realtime presence, delivery/read state handlers
- Description: Document what happens when users connect from multiple devices or browser tabs simultaneously.
- Acceptance Criteria: concurrent-session behavior is deterministic for messaging, calls, and notifications.
- Testing: multi-session manual or automated smoke tests.
- Status: open

### REAL-003 - Add load and observability baselines for realtime paths
- Files: monitoring hooks, metrics docs, load-test helpers
- Description: Establish basic connection-count, latency, and failure-rate observability for realtime services.
- Acceptance Criteria: core realtime metrics and alert thresholds are documented.
- Testing: load-test dry run or simulated metric capture.
- Status: open
