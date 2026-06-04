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
- Status: done (2026-06-03). Documented the owning invalidation path for each primary surface: global resume refresh in `app.dart` (debounced 30s `SubscriptionRestoreRequested` + `ProfileLoadRequested` + location), chat lifecycle re-sync (CHAT-RT-002), auth verification re-check on resume, discovery deck/location refresh. No load-once-never-refresh hotspot on core journeys; manual device resume/nav spot-checks remain a release-gate item. Report: `docs/reports/state_management_audit_2026-06-03.md`.

### STATE-002 - Audit stream/controller disposal and memory leaks
- Files: blocs/cubits, controllers, listeners, long-lived services
- Description: Verify all subscriptions, timers, controllers, and stream listeners are disposed correctly.
- Acceptance Criteria: disposal policy documented; obvious leaks are fixed or tracked.
- Testing: targeted unit tests and analyzer/devtools review where needed.
- Status: done (2026-06-03). **Fixed** a real leak: `FirebaseFeatureFlagRepository` never cancelled its `onConfigUpdated` subscription and could `add()` to a closed controller after `dispose()` (StateError) — now stored+cancelled with an `isClosed` guard, covered by a new disposal test. Verified all 31 blocs/cubits cancel subscriptions in `close()`, all StatefulWidget controllers are disposed, and owned services close their controllers. Documented the 5-point disposal policy; app-lifetime singleton broadcast controllers tracked as acceptable. Report: `docs/reports/state_management_audit_2026-06-03.md`.

### STATE-003 - Standardize optimistic update and rollback behavior
- Files: chat, discovery, settings, subscription, profile state flows
- Description: Define how optimistic UI updates are applied, retried, and rolled back after backend failure.
- Acceptance Criteria: optimistic operations have consistent rollback semantics and user feedback.
- Testing: bloc/repository tests for success and rollback scenarios.
- Status: done (2026-06-03). Documented the standard optimistic pattern (capture pre-state → optimistic emit → roll back to captured state + user feedback on failure), verified applied identically across all 3 discovery swipe handlers and chat (optimistic pending → `failedMessages` + Retry/Discard via `ChatFailedMessageActions`, `MessageReconciler` convergence). Settings/profile/subscription are intentionally load-then-confirm (no rollback needed). No optimistic-without-rollback path found. Report: `docs/reports/state_management_audit_2026-06-03.md`.
