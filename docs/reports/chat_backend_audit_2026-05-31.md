# Chat Backend Audit — CHAT-BE-001 / 002 / 003

- Date: 2026-05-31
- Source TODO: `docs/TODO_CHAT_BACKEND.md`
- Scope: `functions/src/index.ts` (chat REST handlers, moderation/retention
  triggers), `firestore.rules`, `firestore.indexes.json`.
- Verification:
  - `npm run build` (tsc): **clean, 0 errors.**
  - `npx mocha test/chatAuthz.test.js` (new, malicious fixtures): **9 passing.**
  - `npx mocha test/chatRestPagination.test.js` (existing, regression): **12
    passing** — unaffected by this change.
  - Note: the aggregate `npm test` (mocha `--recursive`) has a **pre-existing
    cross-file test-isolation failure** unrelated to this work — each chat/profile
    test file redefines the shared `admin.*` globals, so running them in one
    process clobbers each other (baseline before this change: 117 passing /
    70 failing; with this change: 133 / 59). Individually each suite is green.
    Run chat suites in isolation (as above) to verify this change.

Legend: ✅ already correct · ⚠️ gap found · 🔧 fixed this pass · 🔎 tracked
(needs follow-up / console verification).

---

## CHAT-BE-001 — Message authorization & visibility (🔧 fixed)

### Finding: the REST send + read handlers had no authorization

`POST /v1/chat/:conversationId/send` wrote directly to
`matches/{id}/messages` with **no membership, block, or status check** — any
authenticated user could inject messages into any conversation by supplying a
known/guessed conversation id. `POST /v1/chat/:conversationId/read` likewise
updated `readBy.{uid}` on any match without checking participation. (The read
*history* handler `GET /v1/chat/:id/messages` already checked membership; send
and read did not.) The Firestore security rules enforce participant + block +
active-match constraints for direct SDK writes, but the REST handlers run with
the Admin SDK and **bypass rules**, so the checks must be explicit in code.

### Fix
Both handlers now call the existing `ensureUserInMatch(conversationId, uid)`
helper (throws `not-found` → 404 / `permission-denied` → 403, mapped via the
existing `isHttpsError` / `httpStatusFromHttpsErrorCode`). The send handler
additionally:
- rejects when `hasBlockingRelationship(uid, otherUser)` is true (either
  direction, incl. the legacy `blocker_id`/`blocked_id` fallback) → 403;
- rejects when the match carries a non-`active` `status` → 403;
- validates content via the existing `validateMessageContent` (empty → 400).

### Authorization matrix (server-enforced after this change)

| Endpoint | Signed in | Participant | Not blocked | Match active | Result |
| --- | --- | --- | --- | --- | --- |
| `GET /v1/chat/:id/messages` | ✓ | ✓ | (rules at SDK layer) | — | 200 |
| `GET /v1/chat/:id/messages` | ✓ | ✗ | — | — | **403** |
| `POST /v1/chat/:id/send` | ✓ | ✓ | ✓ | ✓ | 200 |
| `POST /v1/chat/:id/send` | ✓ | ✗ | — | — | **403** |
| `POST /v1/chat/:id/send` | ✓ | ✓ | ✗ (blocked) | — | **403** |
| `POST /v1/chat/:id/send` | ✓ | ✓ | ✓ | ✗ (unmatched) | **403** |
| `POST /v1/chat/:id/send` | ✓ | — | — | missing match | **404** |
| `POST /v1/chat/:id/read` | ✓ | ✓ | — | — | 200 |
| `POST /v1/chat/:id/read` | ✓ | ✗ | — | — | **403** |
| any | ✗ | — | — | — | 401 (authMiddleware) |

### Tests
`functions/test/chatAuthz.test.js` (malicious fixtures): non-participant send
→403 (and nothing written), missing match →404, block relationship →403,
inactive match →403, empty content →400, plus the read-handler authz cases.

---

## CHAT-BE-002 — History pagination & storage access (✅ + 🔎 tracked)

### What is already correct
- **Messages history** (`GET /v1/chat/:id/messages`): keyset pagination via
  `orderBy(createdAt desc).limit(limit+1)` with a `createdAt <` cursor (or
  `startAfter(doc)`); `has_more`/`next_cursor` derived from the `limit+1` probe.
  Bounded page size (1–100). Backed by the `messages` collection index on
  `createdAt DESC`.
- **Conversations / matches** (`/v1/chat/conversations`, `/v1/matches`):
  `where(users array-contains uid).orderBy(lastMessageAt desc)` with a
  `lastMessageAt <` cursor; participant user docs **batch-fetched** in `in`
  chunks of 30 (no per-row user lookup). Backed by the composite index
  `matches: users ARRAY_CONTAINS, lastMessageAt DESC`.

### Proposed p95 targets (documented)
- Messages page (≤50): **p95 < 250 ms** server time (single indexed range scan).
- Conversations/matches page (≤50): **p95 < 400 ms** (one indexed scan + one
  batched users `in` query).

### ⚠️/🔎 Findings tracked (not fixed inline — see rationale)
1. **N+1 last-message read in `/v1/chat/conversations`.** For each conversation
   on the page it issues a separate `messages.orderBy(createdAt desc).limit(1)`
   read (≤50 extra reads/page). _Not fixed inline_ because the documented
   response contract (and `chatRestPagination.test.js`) requires
   `last_message.id` / `sender_id` from the actual message doc; removing the
   read requires denormalizing the full last-message onto the match document
   (id, sender, content) plus a backfill + client coordination. Concrete plan:
   extend `onMessageCreated` / send to stamp `lastMessage{Id,SenderId,Preview}`
   on the match doc, then read those fields and drop the per-row query.
2. **`cleanupExpiredMessages` relies on a collection-group `expiresAt` filter**
   (`collectionGroup("messages").where("expiresAt","<=",now)`) but `expiresAt`
   is **not declared** in `firestore.indexes.json` (no `fieldOverrides`).
   Single-field collection-group indexing is often auto-provisioned, but since
   the hourly retention sweep depends on it, _verify in the Firestore console_
   and, if absent, add a `fieldOverrides` entry enabling collection-group scope
   for `messages.expiresAt`. (Left as a tracked config change rather than an
   unvalidated edit to the index manifest, since `firebase deploy
   --only firestore:indexes` cannot be run here.)

---

## CHAT-BE-003 — Moderation & retention pipeline (🔧 consistency fix + ✅ audit)

### Pipeline (documented)
- **Create → moderate + notify:** `onMessageCreated`
  (`matches/{matchId}/messages/{messageId}.onCreate`) runs `moderateContent`,
  stamps a `moderation{status,action,reason,severity,flagged,reviewedAt}` block,
  and on `action === "hold"` calls `flagUserForReview` and suppresses the push.
  **It early-returns unless both `fromUserId` and `toUserId` are present.**
- **Read → retention countdown:** `onMessageRead`
  (`…/messages/{id}.onUpdate`) stamps `expiresAt` from the reader's retention
  tier (free 1 h / 24 h extended, Plus 7 d — per `firestore.rules` comments).
- **Sweep → expire:** scheduled `cleanupExpiredMessages` (hourly) removes
  elapsed users from `visibleTo` (deleting the doc when empty); `cleanupExpiredData`
  handles broader retention.
- **Visibility:** rules' `isMessageVisible()` requires the reader to be in
  `visibleTo` (legacy docs without the field are treated as always-visible).
- **Reports/blocks:** `reportUser` escalates (`safetyFlags.status` →
  `needs_review` at ≥3 open reports in 7 days; `automatedFlags` at ≥5); `blockUser`
  writes `blocks/{blocker_blocked}`, which the read/send rules and the
  send-handler block check both honour.

### ⚠️→🔧 Finding: REST-sent messages skipped moderation **and** retention
The old send handler wrote only `senderId` (no `fromUserId`/`toUserId`/
`visibleTo`). Consequences: `onMessageCreated` early-returned → **no moderation,
no push**; and with no `visibleTo`, the message was treated as legacy
always-visible → **never expired** by the retention sweep. The CHAT-BE-001 fix
now writes `fromUserId`, `toUserId`, `visibleTo: [participants]`, and
`isRead: false` alongside the legacy `senderId`, so REST-sent messages enter the
exact same moderation + retention lifecycle as SDK-written ones. Asserted by
`chatAuthz.test.js` ("persists moderation/retention fields").

### Test coverage
The send-handler field persistence is covered. Trigger bodies
(`onMessageCreated`/`onMessageRead`/`cleanupExpiredMessages`) are Firestore
event functions; existing suites (`reportReasonNormalization`, `safety*`) cover
the report/moderation-status path. Full pipeline trigger tests would need the
firebase emulator (tracked).

---

## Summary of changes this pass
- `functions/src/index.ts`: authz + moderation/retention-field writes on
  `POST /v1/chat/:id/send`; authz on `POST /v1/chat/:id/read`.
- `functions/test/chatAuthz.test.js`: new (9 cases).
- Docs: this report + `docs/TODO_CHAT_BACKEND.md` status updates.

## Tracked follow-ups
1. Denormalize last message onto the match doc to remove the conversations N+1.
2. Verify/declare the `messages.expiresAt` collection-group index.
3. Emulator-based trigger tests for moderation + retention sweep.
