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
