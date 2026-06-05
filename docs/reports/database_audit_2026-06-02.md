# Database Audit - 2026-06-02

Scope: `DB-001`, `DB-002`, and `DB-003` from [`docs/TODO_DATABASE.md`](../TODO_DATABASE.md).

Surface reviewed: [`firestore.rules`](../../firestore.rules),
[`firestore.indexes.json`](../../firestore.indexes.json),
[`firebase.json`](../../firebase.json), the Cloud Functions backend
([`functions/src/index.ts`](../../functions/src/index.ts)), the Flutter chat
repository, and the existing schema doc
[`docs/project_er_diagram.md`](../project_er_diagram.md).

## Result

All three tasks are complete for the current codebase. Two defects were found
and fixed (a silently-broken account-deletion sweep and a cascade that never
deleted `message_requests`); the schema/index doc was refreshed to match the
live config; and a backup/restore runbook was added with a validated dry run.
Residual items are deploy-time and ops actions, listed per task below.

---

## DB-001 - Refresh schema map and index inventory

Status: Pass (doc refreshed; issues identified and, where code-level, fixed)

### Schema/ERD currency
- [`docs/project_er_diagram.md`](../project_er_diagram.md) §5 (Indexing Strategy)
  was stale: it listed 6 composite indexes that did **not** match
  `firestore.indexes.json` (e.g. it claimed `matches(userIds,status,matchedAt)`,
  a `messages` COLLECTION_GROUP `sentAt` index, and `reports(status,createdAt)` —
  none of which exist), and omitted the user discovery composites,
  `auth_rate_limits`, `messages(toUserId,isRead)`, `blocks(blockerId,blockedId)`,
  and `reports(reporterId,createdAt)`. §5 was regenerated from the live file.
- §6.3 embedded a heavily simplified ~75-line copy of the security rules (no
  block-relationship checks, premium gating, retention/`visibleTo`, message
  validation, stories, calls, or `message_requests`). The live rules are 351
  lines. The inline copy was replaced with a pointer to `firestore.rules` plus an
  accurate summary of what the rules enforce.
- Summary Statistics index counts were corrected (6/5 → 20 composite / 3
  single-field overrides).

### Missing indexes (found + fixed)
- `processScheduledAccountDeletions` runs two equality-plus-inequality queries on
  `users` (`isPendingDeletion == true AND deletionScheduledAt < now`, and
  `isDeactivated == true AND scheduledDeletionAt < now`). Both require composite
  indexes that were **absent**, so the queries threw `FAILED_PRECONDITION`. The
  function caught and logged the error, masking the fact that **scheduled account
  deletions had not been running**. Added both composite indexes to
  `firestore.indexes.json`. (Cross-impacts DB-002.)

### Dead / misconfigured index (identified, left in place)
- `messages (visibleTo array-contains, createdAt desc)` references `createdAt`,
  but messages are written with `sentAt` (see `sendMessage`) and all client
  queries order by `sentAt`. No live query matches it. Documented in §5.3 as
  dead; not removed pending confirmation no admin tooling relies on it.

### Ambiguous document shapes (identified)
- Dual user shape during web migration: nested `profile.*` vs legacy flat
  (`displayName`, `photos`, `location`, `interestedIn`, `gender`, `age`, root
  completion flags). Both are live and both are indexed.
- Match membership keyed three ways (`users` / `userIds` / `participants`, per
  `MATCH_MEMBERSHIP_FIELDS`); rules and match composites use `userIds`.
- `message_requests` participants are `fromUserId`/`toUserId`, not
  `senderId`/`recipientId` (see DB-002).

All three are now documented in `project_er_diagram.md` §5.4.

Deploy-time follow-up:
- `firebase deploy --only firestore:indexes` to build the two new `users`
  composites before relying on the deletion sweep.

---

## DB-002 - Audit deletion cascades, retention, and archival rules

Status: Pass (one cascade defect fixed; policy documented)

### Deletion cascade defect (found + fixed)
- `cascadeDeleteUserData` deleted `message_requests` by querying `senderId` and
  `recipientId`, but top-level `message_requests` documents are written with
  `fromUserId`/`toUserId` (Flutter `firebase_chat_repository.dart` and
  `firestore.rules`). The queries matched nothing, so a deleted user's pre-match
  request content, both user IDs, and cached names/photo URLs were **left
  behind** — a privacy/GDPR gap. Fixed to query `fromUserId`/`toUserId` via a new
  documented `MESSAGE_REQUEST_PARTICIPANT_FIELDS` constant, and locked with a
  regression test in `functions/test/accountDeletionMap.test.js`.
- The scheduled deletion job itself was also blocked by the missing indexes in
  DB-001; both are now addressed.

### Cascade coverage (verified correct)
- `cascadeDeleteUserData` removes: matches across all 3 membership fields + their
  `messages` subcollections; `users/{uid}` relation subcollections; top-level
  `likes`/`swipes`/`blocks`/`reports` the user authored (and inbound like/swipe
  pointers); `message_requests` (now fixed); `account_deletions` /
  `account_deactivations` / `auth_credentials`; Storage `photos/{uid}` and
  `chat_media/{uid}`; RTDB presence/typing/last_seen; the user doc; and finally
  the Firebase Auth user.
- Inbound `reports.reportedId` and `blocks.blockedId` are **intentionally
  retained** for abuse history (asserted by test). Documented as policy.

### Retention (verified, working)
- Messages: free 1h after read (24h if extended), Plus 7 days
  (`RETENTION_FREE_DEFAULT` / `_EXTENDED` / `RETENTION_PLUS`). Driven by
  `onMessageRead` → RTDB `message_deletion_queue` (`deleteAt`) →
  `processMessageDeletionQueue` (every 15 min) which strips the user from
  `visibleTo` and deletes the message when `visibleTo` is empty. Unread messages
  never expire by design (retention starts at read).
- `message_requests` expire after 48h; `cleanupExpiredMessageRequests` (hourly)
  deletes by `expiresAt < now` (single-field, auto-indexed — OK).
- Account deletion: 14-day grace (`DELETION_GRACE_PERIOD_DAYS`); deactivated
  accounts auto-delete at 6 months (`scheduledDeletionAt`);
  `processScheduledAccountDeletions` runs every 6h.

### Archival
- There is no archival tier — deleted-user data is hard-deleted (only backups in
  DB-003 retain copies, ≤30 days). Abuse records (inbound reports/blocks) are
  retained **indefinitely** with no defined TTL. Recommend defining an explicit
  retention period for abuse history (open item, not blocking).

Manual staging checklist:
- For a disposable staging user with a pending `message_requests` row in both
  directions, force the deletion sweep and confirm the rows are gone.
- Confirm `processScheduledAccountDeletions` no longer logs `FAILED_PRECONDITION`
  after the new indexes deploy, and that a pending account is actually deleted
  once `deletionScheduledAt` passes.
- Send + read a message and confirm it disappears from `visibleTo` after the
  retention window for the reader's plan.

---

## DB-003 - Verify backup and restore procedures

Status: Pass (runbook added; dry run validated). Ops follow-ups tracked.

- Authored [`docs/BACKUP_RESTORE_RUNBOOK.md`](../BACKUP_RESTORE_RUNBOOK.md):
  backup cadence/scope/destination/retention/owner, one-time bucket + lifecycle +
  IAM + PITR setup, and the production restore procedure
  (`gcloud firestore import`, staging-first).
- Backup mechanism in place: `scheduledFirestoreBackup` exports all collections
  daily (UTC) to `gs://crush-265f7-firestore-backups/<date>/`.
- **Validated dry run (2026-06-02):** seeded a marker doc + subcollection into the
  Firestore emulator, exported with `--export-on-exit`, then started a fresh
  emulator with `--import` and verified both documents restored cleanly. Scripts:
  `functions/scripts/backup_dryrun_seed.js` / `backup_dryrun_verify.js`. The
  emulator export format matches `gcloud firestore export`/`import`, so the same
  restore path is exercised.

Ops follow-ups (in runbook §5):
- Create the backup bucket + 30-day lifecycle per environment.
- Add failure alerting (the function currently logs and swallows export errors).
- Enable PITR on `(default)`.
- Run and record the first production export → staging import drill.

---

## Verification

- `npm run build` (in `functions/`) — TypeScript compiles clean.
- `npx mocha --exit test/accountDeletionMap.test.js` (in `functions/`) — 5 passing
  (includes the new `message_requests` field guard).
- `node -e "require('./firestore.indexes.json')"` — valid JSON; 20 composite
  indexes, 3 field overrides.
- Backup/restore dry run: emulator export→import round trip, `[verify] restore
  OK`, exit 0.
