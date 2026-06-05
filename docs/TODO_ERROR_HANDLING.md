# TODO: Error Handling & Resilience

- Priority: P0 – Critical
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_STATE_MANAGEMENT.md`, `docs/TODO_PERFORMANCE.md`
- Assigned: AI + Developer

## Tasks

### ERR-001 - Standardize network and backend error taxonomy
- Files: shared result/error helpers, repositories, localized message mappings
- Description: Ensure timeouts, offline states, auth failures, malformed responses, and 4xx/5xx paths are categorized consistently.
- Acceptance Criteria: one error taxonomy exists and is used across modules.
- Testing: unit tests for error mappers and repository failure paths.
- Status: done (2026-06-03). Verified the single de-facto taxonomy: `Result<T>` (`Result.guard`/`failure`, used in 98 feature files) + central `ErrorMessages` map (network/timeout/server/unauthorized/offline) + typed `AuthFailureType`/`AuthFailureMapper` for auth. Cleanup tracked: `RepositoryException` is an unused base type. Report: `docs/reports/error_handling_audit_2026-06-03.md`.

### ERR-002 - Add or verify global crash recovery and graceful fallback UI
- Files: app startup, root widgets, error boundaries, crash logging integration
- Description: Prevent blank screens and ensure uncaught failures degrade into recoverable user-facing states.
- Acceptance Criteria: crash boundaries log errors and show actionable recovery UI.
- Testing: forced-failure smoke tests and crash-reporting verification.
- Status: done (2026-06-03). Verified comprehensive capture: `FlutterError.onError`, `PlatformDispatcher.onError`, isolate error listener (all → Crashlytics), `runZonedGuarded` around `runApp`, branded `installErrorWidgetBuilder()` (called in main.dart) replacing the default error box, `ErrorBoundary` recovery surface, and an actionable startup-failure screen. Report: `docs/reports/error_handling_audit_2026-06-03.md`.

### ERR-003 - Audit retry, backoff, and circuit-breaker behavior
- Files: network clients, repository wrappers, retry helpers, background sync jobs
- Description: Verify transient failures retry safely and repeated backend failures do not stampede services.
- Acceptance Criteria: retry policy documented; idempotent retries only; high-failure paths have backoff safeguards.
- Testing: unit tests for retry helpers and simulated transient failure flows.
- Status: done (2026-06-03). Verified idempotent-only transport retries (GET only; POST/PUT/PATCH/DELETE never), `CircuitBreaker` guarding HTTP repos, and `OfflineActionQueue` backoff. **Fixed:** added ±20% jitter to `ApiClient` retry backoff (was pure exponential — thundering-herd risk) via the pure, tested `retryBackoffDelay` (api_client_test → 39 passing). Cleanup tracked: consolidate onto the unused `RetryPolicy`. Report: `docs/reports/error_handling_audit_2026-06-03.md`.
