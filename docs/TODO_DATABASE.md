# TODO: Database Audit

- Priority: P0 – Critical
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_API_ARCHITECTURE.md`, `docs/TODO_SECURITY_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### DB-001 - Refresh schema map and index inventory
- Files: Firestore rules/indexes, schema docs, backend query paths
- Description: Rebuild the canonical data-model and index map for the current repo and backend query surface.
- Acceptance Criteria: ERD/schema doc is current; missing indexes and ambiguous document shapes are identified.
- Testing: schema validation tests and query/index review.
- Status: done (2026-06-02). Regenerated `docs/project_er_diagram.md` §5/§6.3 from the live config; added two missing `users` deletion-sweep composite indexes; identified the dead `messages(visibleTo,createdAt)` index and the dual-shape/ambiguous fields. Report: `docs/reports/database_audit_2026-06-02.md`. Deploy-time follow-up: `firebase deploy --only firestore:indexes`.

### DB-002 - Audit deletion cascades, retention, and archival rules
- Files: user deletion handlers, cleanup triggers, retention jobs
- Description: Verify user deletion, report retention, moderation records, and audit data follow an explicit policy.
- Acceptance Criteria: retention and deletion rules are documented and enforced where required.
- Testing: backend deletion and retention-path validation.
- Status: done (2026-06-02). Fixed `cascadeDeleteUserData` to delete `message_requests` by `fromUserId`/`toUserId` (was `senderId`/`recipientId`, matching nothing) with a regression test; documented message/account retention and abuse-history retention policy. Report: `docs/reports/database_audit_2026-06-02.md`. Open (non-blocking): define an explicit TTL for retained abuse records.

### DB-003 - Verify backup and restore procedures
- Files: release/prod docs, ops scripts, backup references
- Description: Confirm backup cadence, restore steps, and ownership are documented and tested.
- Acceptance Criteria: backup and restore runbook exists with one validated test or dry run.
- Testing: documented dry run or validated restore exercise.
- Status: done (2026-06-02). Added `docs/BACKUP_RESTORE_RUNBOOK.md` (cadence, ownership, setup, restore steps) and validated an emulator export→import dry run via `functions/scripts/backup_dryrun_{seed,verify}.js`. Ops follow-ups (bucket lifecycle, failure alerting, PITR, prod drill) tracked in runbook §5.
