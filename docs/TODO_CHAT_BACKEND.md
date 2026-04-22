# TODO: Chat Backend Module

- Priority: P0 – Critical
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_DATABASE.md`, `docs/TODO_SECURITY_BACKEND.md`, `docs/TODO_API_ARCHITECTURE.md`
- Assigned: AI + Developer

## Tasks

### CHAT-BE-001 - Audit message authorization and visibility rules
- Files: message endpoints/callables, backend repositories, moderation readers
- Description: Verify only valid participants can read/write conversation data and that block/report/moderation rules are enforced server-side.
- Acceptance Criteria: authz matrix documented; blocked or removed relationships cannot continue chatting.
- Testing: backend authz tests with malicious fixtures.
- Status: open

### CHAT-BE-002 - Optimize history pagination and storage access
- Files: message history queries, indexes, pagination helpers
- Description: Review long-thread history fetch performance, cursor usage, and any N+1 document loading patterns.
- Acceptance Criteria: p95 history fetch targets defined; missing indexes and expensive fan-out paths tracked or fixed.
- Testing: backend tests plus query/index review.
- Status: open

### CHAT-BE-003 - Verify moderation and retention pipeline for user-generated content
- Files: moderation triggers, report handlers, message retention/deletion flows
- Description: Ensure reported content, removed users, and retention/deletion rules are handled consistently across storage and cache layers.
- Acceptance Criteria: moderation and retention semantics documented and test-covered.
- Testing: functions tests and deletion/report regression coverage.
- Status: open
