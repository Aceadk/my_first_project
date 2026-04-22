# TODO: Refactor Chat

- Priority: P2 – Medium
- Estimated Effort: 2-4 days
- Dependencies: `docs/TODO_CHAT_UI.md`, `docs/TODO_CHAT_REALTIME.md`, `docs/TODO_CHAT_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### REF-CHAT-001 - Separate transport concerns from chat state orchestration
- Files: chat repositories, realtime transports, bloc/store coordination
- Description: Clarify ownership between transport delivery guarantees and UI-facing message state.
- Acceptance Criteria: chat state management is easier to test without live transport dependencies.
- Testing: repository/bloc regression coverage.
- Status: open

### REF-CHAT-002 - Decompose composer and attachment flows
- Files: composer widgets, attachment pickers, pending/failed state helpers
- Description: Split the composer surface into smaller concerns so keyboard, media, retry, and moderation behavior are easier to maintain.
- Acceptance Criteria: composer hotspots have extraction plan or completed refactor steps.
- Testing: widget tests for composer subcomponents.
- Status: open
