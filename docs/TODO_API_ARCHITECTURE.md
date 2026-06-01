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
- Status: completed 2026-05-30
- Evidence: `docs/reports/api_pagination_ratelimit_audit_2026-05-30.md`
- Verification: `npm run build` (in `functions/`), `npx mocha --exit test/chatRestPagination.test.js`, `npx mocha --exit test/callRestRateLimit.test.js test/securityAbuseLanes.test.js`, `npx mocha --exit test/callables.test.js`
- Refactor: extracted shared `parseBeforeTimestampCursor` for the `matches`/`conversations` cursor endpoints; pagination + rate-limit matrices and client/server retry-safety contract documented in the evidence report.
