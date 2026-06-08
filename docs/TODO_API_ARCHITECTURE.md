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
- Status: done 2026-05-30
- Evidence: `docs/reports/api_pagination_ratelimit_audit_2026-05-30.md`
- Verification: `npm run build` (in `functions/`), `npx mocha --exit test/chatRestPagination.test.js`, `npx mocha --exit test/callRestRateLimit.test.js test/securityAbuseLanes.test.js`, `npx mocha --exit test/callables.test.js`
- Refactor: extracted shared `parseBeforeTimestampCursor` for the `matches`/`conversations` cursor endpoints; pagination + rate-limit matrices and client/server retry-safety contract documented in the evidence report.

### API-007 - Establish canonical cross-repo contracts and mutation boundaries
- Files: `docs/API_CATALOG.md`, backend validators/contracts, Dart DTOs, TypeScript DTOs, shared fixtures, client service inventories
- Description: Replace independently maintained assumptions with validated contracts for REST/callable payloads, Firestore documents, notification payloads, and server-owned mutations. Explicitly classify direct client reads, direct client writes, backend commands, deprecated paths, and unsupported paths.
- Dependencies: `DB-004`, `TEST-007`
- Acceptance Criteria:
  - One contract manifest covers each live endpoint/callable/document shape and owning client.
  - Dart, TypeScript, and backend validators run against shared fixtures or generated schemas.
  - Sensitive mutations are classified as backend-owned and have no direct-client alternative.
  - Contract drift, unsupported collection paths, and stale endpoint names fail CI.
  - Deprecated paths include retirement criteria and dates.
- Testing:
  - Cross-language fixture validation.
  - Contract tests for all critical auth, profile, discovery, match/chat, safety, notification, and subscription commands.
  - CI drift check against backend exports and client wrappers.
- Status: open — P0 alignment foundation.

### API-008 - Establish canonical domains, routes, and deployment manifests
- Files: domain/environment matrix, route/deep-link matrix, Firebase/Vercel config, CORS, CSP, auth hosts, Stripe redirects, metadata, notification route mappers
- Description: Turn the current planning matrices into validated as-built manifests. Choose canonical staging/production domains and one supported web deployment path, then align every consumer.
- Dependencies: product/operations domain decision
- Acceptance Criteria:
  - Each domain and route is marked `implemented`, `target`, `alias`, `deprecated`, or `blocked`.
  - One production and staging deployment path is documented and reproducible.
  - CORS, CSP, Firebase Auth hosts, App Check, Stripe redirects, metadata, email/support identity, and notification hosts use the approved environment manifest.
  - Route checks verify that implemented notification/deep-link destinations exist.
  - Deprecated domains/routes fail CI outside approved redirects and historical docs.
- Testing:
  - Manifest validation scripts.
  - Route existence/redirect tests.
  - Staging deployment and deep-link smoke tests.
- Status: open — P0 decision and release blocker.

### API-009 - Decompose the Cloud Functions monolith by bounded context
- Files: `functions/src/index.ts`, domain modules, shared middleware/contracts, functions tests
- Description: Incrementally split the 13,708-line Functions implementation into auth, profile, discovery, match/chat, safety, notifications, subscription, calls, and shared infrastructure while preserving public exports and deployed behavior.
- Dependencies: `API-007`; begin after P0 production path remediation is stable
- Acceptance Criteria:
  - `index.ts` becomes a thin composition/export layer.
  - Domain modules own validators, handlers, and focused tests.
  - No callable, REST route, webhook, trigger, or schedule is lost or renamed unintentionally.
  - Test isolation and build/deploy behavior improve without broad behavior changes.
- Testing:
  - Export/route inventory regression check before each extraction.
  - Existing functions test suite plus focused module tests.
  - Staging smoke test after each bounded-context extraction.
- Status: open — P2 maintainability task.
