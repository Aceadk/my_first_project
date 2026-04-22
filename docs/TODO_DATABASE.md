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
- Status: open

### DB-002 - Audit deletion cascades, retention, and archival rules
- Files: user deletion handlers, cleanup triggers, retention jobs
- Description: Verify user deletion, report retention, moderation records, and audit data follow an explicit policy.
- Acceptance Criteria: retention and deletion rules are documented and enforced where required.
- Testing: backend deletion and retention-path validation.
- Status: open

### DB-003 - Verify backup and restore procedures
- Files: release/prod docs, ops scripts, backup references
- Description: Confirm backup cadence, restore steps, and ownership are documented and tested.
- Acceptance Criteria: backup and restore runbook exists with one validated test or dry run.
- Testing: documented dry run or validated restore exercise.
- Status: open
