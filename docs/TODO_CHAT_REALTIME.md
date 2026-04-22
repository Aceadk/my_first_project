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
- Status: open

### CHAT-RT-002 - Audit typing indicators and read receipts under lifecycle changes
- Files: typing/read receipt emitters, debounce logic, app lifecycle handlers
- Description: Ensure indicators stay accurate when the app backgrounds, foregrounds, or resizes in tablet multitasking.
- Acceptance Criteria: indicators do not linger or disappear incorrectly during lifecycle transitions.
- Testing: realtime logic tests plus manual background/foreground checks.
- Status: open

### CHAT-RT-003 - Define offline queue and sync recovery policy
- Files: offline caches, pending message stores, reconnect sync logic
- Description: Document and harden what happens when users compose or receive messages offline and reconnect later.
- Acceptance Criteria: offline send/receive semantics are defined; rollback/retry behavior is tested.
- Testing: offline/reconnect integration coverage.
- Status: open
