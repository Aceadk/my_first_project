# Account Deletion Completeness Audit — 2026-05-30

Scope: `AUTH-SEC-005` from `docs/TODO_AUTH_SECURITY.md`. Complements the
high-level `docs/reports/account_management_compliance_2026-05-30.md` (ACCT) with
a backend deletion-completeness deep dive.

## Summary

The deletion lifecycle (14-day grace → scheduled cascade → Auth deletion) is
sound, but the cascade had two real completeness bugs: it queried matches only
by `participants` (matches are created with `users`/`userIds`, so matches and
their messages were not being deleted), and it never scrubbed the top-level
`likes`/`swipes`/`blocks`/`reports` collections. Both are fixed; the deletion
map is now expressed as tested helpers.

## Deletion Lifecycle

1. **`requestAccountDeletion`** (callable, App Check + auth) — marks
   `isPendingDeletion`, schedules deletion 14 days out, writes an
   `account_deletions` tracking record. The mobile client then signs out.
2. **`cancelAccountDeletion`** — recovery: signing in within the grace period
   clears the pending state.
3. **`processScheduledAccountDeletions`** (every 6 h) — runs `cascadeDeleteUserData`
   for past-grace pending accounts and 6-month-old deactivated accounts.
4. **`cascadeDeleteUserData`** — cascading purge across Firestore, Storage, RTDB,
   and Auth.

## Deletion Map (`cascadeDeleteUserData`)

| Data | Location | Status |
| --- | --- | --- |
| Matches + messages | `matches` (membership: `users` / `userIds` / `participants`) + `messages` subcollection | **Fixed** — was `participants`-only, missing real matches |
| Block/report/like subcollections | `users/{uid}/{blocked,reports,likes_given,likes_received}` | OK |
| Message requests | `message_requests` (sent + received) | OK |
| Outgoing likes/swipes | `likes.fromUserId`, `swipes.swiperId` | **Fixed** — added |
| Inbound like/swipe pointers | `likes.toUserId`, `swipes.targetId` | **Fixed** — added (orphan cleanup) |
| Outgoing blocks/reports | `blocks.blockerId`, `reports.reporterId` | **Fixed** — added |
| Inbound blocks/reports about the user | `blocks.blockedId`, `reports.reportedId` | **Retained by design** (abuse/safety history) |
| Account tracking | `account_deletions`, `account_deactivations` | OK |
| Auth credentials | `auth_credentials/{uid}` | OK |
| Cloud Storage | `photos/{uid}/`, `chat_media/{uid}/` | OK |
| RTDB | `presence`, `typing`, `last_seen` | OK |
| User document (incl. premium/entitlement state) | `users/{uid}` | OK |
| Firebase Auth user | `admin.auth().deleteUser(uid)` | OK |

## Acceptance Criteria

- **Sessions revoked:** `deleteUser` invalidates all refresh tokens/sessions at
  purge time; during the grace period the user stays signed in intentionally
  (so they can cancel), and the client `deleteAccount` path signs out
  immediately. `revokeRefreshTokens` is also used by password-change/reset and
  deactivation flows.
- **User-owned data removed:** see the map; outgoing personal-data records are
  now fully scrubbed across subcollections and top-level relation collections.
- **Premium cancelled correctly:** entitlement state lives on the user document
  (no separate `subscriptions` collection), so in-app premium access ends when
  the user doc is deleted. Store-side recurring subscriptions (Apple/Google)
  cannot be server-cancelled — the user must cancel in the store. Documented
  platform limitation (see ACCT report), not a data-deletion gap.
- **In-app path easy to reach:** Account Actions settings screen → Delete
  Account, behind password/confirmation (see ACCT report).
- **GDPR/CCPA:** right-to-erasure satisfied by the cascade; right-to-access by
  the existing data export (`ACCT-002`); 14-day grace + cancel provides a safe
  undo window.

## Fixes & Refactor (this change)

- **Matches membership bug:** `cascadeDeleteUserData` now queries all of
  `MATCH_MEMBERSHIP_FIELDS` (`users`, `userIds`, `participants`) and dedupes by
  document id, so a deleted user's matches and chat history are actually removed.
- **Top-level relation scrub:** new step deletes the user's footprint from
  `likes`/`swipes`/`blocks`/`reports` via `userRelationDeletionTargets()`
  (outgoing for all four; inbound for likes/swipes only).
- **Refactor:** extracted `deleteDocsByQuery` (paginated, batch-capped delete
  with logging) — also fixes a latent correctness issue where the original
  `.limit(500)`-single-batch blocks would silently drop anything beyond 500
  documents. The deletion map (`userRelationDeletionTargets`,
  `matchMembershipFields`) is now unit-tested.

## Verification

- `npm run build` + `npm run lint` (in `functions/`) — clean
- `npx mocha --exit test/accountDeletionMap.test.js` (4 passing — match fields,
  outgoing scrub, inbound pointer cleanup, abuse-history retention)
- `npx mocha --exit test/callables.test.js` (11 passing — incl.
  `requestAccountDeletion` auth gate)
- Full-suite delta: `npm test` 131 passing / 50 failing (the 50 are pre-existing
  cross-file mock contamination); this change adds the 4 new passing tests and
  zero new failures.

## Tracked / Manual Follow-Up

1. Store-side subscription cancellation is the user's action (platform limit);
   surface a reminder in the deletion UI if not already present.
2. `cascadeDeleteUserData` execution is destructive and verified by the unit-
   tested deletion map plus manual staging runs; a full emulator integration
   test of the cascade remains a worthwhile future add.
3. Manual pre-submission checklist: request deletion → confirm grace, cancel,
   and post-grace purge remove matches/messages/likes/swipes/storage and revoke
   sessions on a staging account.
