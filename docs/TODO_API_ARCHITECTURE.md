# TODO: API Architecture

- Priority: P0 – Critical
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_DATABASE.md`, `docs/TODO_SECURITY_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### API-002 - Audit pagination, rate limiting, and retry semantics
- Files: list endpoints, pagination helpers, rate-limit middleware, client wrappers
- Description: Ensure list endpoints use consistent cursor/offset semantics and rate limits match endpoint risk.
- Acceptance Criteria: pagination strategy is documented per endpoint; rate limits and retry safety are defined.
- Testing: endpoint tests for pagination and abuse/rate-limit paths.
- Status: open
