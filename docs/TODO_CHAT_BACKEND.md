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
- Status: done — fixed + verified 2026-05-31 (tsc clean; `test/chatAuthz.test.js` 9 passing standalone; existing `chatRestPagination.test.js` 12 passing, unbroken). Found & fixed a real gap: `POST /v1/chat/:id/send` and `/read` had no server-side authz (Admin SDK bypasses rules), so any authenticated user could post to / mark-read any conversation. Both now enforce participant membership (`ensureUserInMatch` → 403/404), block relationship via `hasBlockingRelationship` (either direction → 403), and active-match status; send validates content. Authz matrix documented; malicious-fixture tests added. Code-complete + verified locally; not yet deployed (`firebase deploy --only functions`). NB: aggregate `npm test` has a pre-existing cross-file mock-isolation failure (unrelated). See `docs/reports/chat_backend_audit_2026-05-31.md`.

### CHAT-BE-002 - Optimize history pagination and storage access
- Files: message history queries, indexes, pagination helpers
- Description: Review long-thread history fetch performance, cursor usage, and any N+1 document loading patterns.
- Acceptance Criteria: p95 history fetch targets defined; missing indexes and expensive fan-out paths tracked or fixed.
- Testing: backend tests plus query/index review.
- Status: in progress — audited + verified 2026-05-31. Pagination is already keyset-based (messages: createdAt cursor; conversations/matches: lastMessageAt cursor, users batch-fetched in 30-chunks) with composite index `matches: users ARRAY_CONTAINS + lastMessageAt DESC` and `messages: createdAt DESC`. p95 targets defined (messages <250ms, conversations <400ms). Tracked (not fixed inline, with rationale): (1) N+1 last-message read in `/v1/chat/conversations` — needs match-doc denormalization + client coordination; (2) `cleanupExpiredMessages` collection-group `expiresAt` filter not declared in indexes.json — verify/enable in console. See `docs/reports/chat_backend_audit_2026-05-31.md`.

### CHAT-BE-003 - Verify moderation and retention pipeline for user-generated content
- Files: moderation triggers, report handlers, message retention/deletion flows
- Description: Ensure reported content, removed users, and retention/deletion rules are handled consistently across storage and cache layers.
- Acceptance Criteria: moderation and retention semantics documented and test-covered.
- Testing: functions tests and deletion/report regression coverage.
- Status: in progress — audited + verified 2026-05-31. Documented full pipeline: create→`onMessageCreated` (moderateContent, hold+flagUserForReview), read→`onMessageRead` (stamps tier-based `expiresAt`), hourly `cleanupExpiredMessages` (prunes `visibleTo`/deletes), report escalation thresholds (≥3 needs_review, ≥5 automatedFlags). Found & fixed a real consistency gap: REST-sent messages wrote only `senderId`, so `onMessageCreated` early-returned (no moderation/push) and missing `visibleTo` made them never expire; the CHAT-BE-001 send fix now writes fromUserId/toUserId/visibleTo/isRead so REST messages share the SDK lifecycle (test-covered). Remaining: emulator-based trigger tests for the moderation/retention sweep. See `docs/reports/chat_backend_audit_2026-05-31.md`.

### CHAT-BE-004 - Execute canonical web chat and match cutover
- Files: `/Users/ace/crush-web/packages/core/src/services/message_v2.ts`, `match_v2.ts`, stores/feature flag, migration scripts, backend match/chat commands, canonical Firestore documents
- Description: Migrate web runtime behavior from legacy `conversations`, `typing_indicators`, directional matches, and direct swipes to backend-managed canonical matches and `matches/{matchId}/messages`.
- Dependencies: `SEC-FE-004`, `DB-004`, `API-007`, `TEST-007`
- Acceptance Criteria:
  - Existing environment data is inventoried and migration field mappings are approved.
  - Migration dry-run, staging execution, count reconciliation, representative-record validation, backup, and rollback criteria are recorded.
  - V2 is enabled in staging and passes match creation, list, send, read, edit, unsend, reaction, typing, pin, block, and report flows.
  - Production cutover includes monitoring and an observation window.
  - Legacy services, feature flag, and unsupported collection paths are removed after the observation window.
- Testing:
  - Migration validation tests and staging data reconciliation.
  - Authenticated multi-browser/device E2E including reconnect, duplicate prevention, and permission denial.
  - Backend authz/moderation/retention regression tests.
- Status: open — P0 cutover task; V2 exists but is disabled by default.
