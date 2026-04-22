# TODO: State Management

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_ERROR_HANDLING.md`, `docs/TODO_REALTIME.md`
- Assigned: AI + Developer

## Tasks

### STATE-001 - Audit stale-state risks across navigation and background return
- Files: blocs/cubits, repositories, startup/router flows
- Description: Find screens that show outdated data after navigation, refresh, or resume and document the owning invalidation path.
- Acceptance Criteria: stale-state hotspots are listed with fix plans or resolved.
- Testing: targeted bloc/repository tests and manual resume/navigation checks.
- Status: open

### STATE-002 - Audit stream/controller disposal and memory leaks
- Files: blocs/cubits, controllers, listeners, long-lived services
- Description: Verify all subscriptions, timers, controllers, and stream listeners are disposed correctly.
- Acceptance Criteria: disposal policy documented; obvious leaks are fixed or tracked.
- Testing: targeted unit tests and analyzer/devtools review where needed.
- Status: open

### STATE-003 - Standardize optimistic update and rollback behavior
- Files: chat, discovery, settings, subscription, profile state flows
- Description: Define how optimistic UI updates are applied, retried, and rolled back after backend failure.
- Acceptance Criteria: optimistic operations have consistent rollback semantics and user feedback.
- Testing: bloc/repository tests for success and rollback scenarios.
- Status: open
