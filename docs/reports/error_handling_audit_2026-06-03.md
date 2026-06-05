# Error Handling & Resilience Audit - 2026-06-03

Scope: `ERR-001`, `ERR-002`, `ERR-003` from [`docs/TODO_ERROR_HANDLING.md`](../TODO_ERROR_HANDLING.md).

Surface reviewed: `lib/core/utils/result.dart`, `lib/core/utils/error_messages.dart`,
`lib/core/errors/` + `errors.dart`, `lib/core/widgets/error_boundary.dart`,
`lib/core/services/crash_reporting_service.dart`, `lib/core/network/api_client.dart`,
`lib/core/network/circuit_breaker.dart`, `lib/core/utils/retry_policy.dart`,
`lib/core/cache/offline_queue.dart`, and `lib/main.dart` / `lib/app.dart`.

## Result

The resilience infrastructure is mature and meets all three acceptance criteria.
One concrete gap was **fixed** (retry backoff had no jitter — a thundering-herd
risk). Two pieces of dead/duplicated code are flagged as cleanup.

Legend: ✅ verified · 🔧 fixed · 🔎 cleanup tracked.

---

## ERR-001 - Network/backend error taxonomy

Status: ✅ Pass

- A single, consistent failure-signalling convention is used across modules: every
  repository call returns/!throws through `Result<T>` (`Result.guard`,
  `Result.failure`) — **98 feature files** use it — and user-facing strings come
  from one central map, `ErrorMessages` (`error_messages.dart`), which categorizes
  the required cases: `networkError`, `timeout`, `serverError`,
  `unauthorized` (session-expired), and `offline`.
- Auth has a richer typed taxonomy (`AuthFailureType` enum + `AuthFailure` +
  `AuthFailureMapper`) for its many distinct states, layered on the same base.
- 🔎 Cleanup: `RepositoryException` (in `core/errors.dart`) is referenced only by
  `result.dart`/`auth_failures.dart` and is not thrown by feature modules (they use
  `Result` + `ErrorMessages`). It's a redundant base type — either adopt it as the
  typed carrier or remove it; not blocking since the `Result`+`ErrorMessages`
  taxonomy is the de-facto standard and is consistently applied.

## ERR-002 - Global crash recovery and graceful fallback UI

Status: ✅ Pass (comprehensive)

All four layers of uncaught-error capture are wired:
- **Framework errors:** `FlutterError.onError` → Crashlytics
  `recordFlutterFatalError` in release, console dump in debug
  (`crash_reporting_service.dart`).
- **Async/platform errors:** `PlatformDispatcher.instance.onError` → Crashlytics
  (`fatal: true`).
- **Isolate errors:** `RawReceivePort` isolate error listener → Crashlytics.
- **Zone:** `runZonedGuarded` wraps `runApp` in `main.dart`.
- **Fallback UI:** `installErrorWidgetBuilder()` is called at startup
  (`main.dart:34`) and replaces the default red/grey error box with a branded
  recoverable widget; `ErrorBoundary` (`app.dart`) provides a scoped recovery
  surface. Startup-service failures degrade to an actionable error screen rather
  than a blank screen.

## ERR-003 - Retry, backoff, and circuit-breaker behavior

Status: 🔧 jitter added; otherwise ✅ Pass

- **Idempotent-only retries (verified correct):** `ApiClient._shouldRetryTransportFailure`
  retries **only `GET`** on transport failure; `POST`/`PUT`/`PATCH`/`DELETE` are
  never auto-retried, so a transient failure can't double-send a message or
  double-charge. 401s get a single silent token-refresh-then-retry, not a loop.
- **Circuit breaker:** `CircuitBreaker` (closed/open/half-open with failure
  window + reset timeout + half-open probe) guards the HTTP profile and chat
  repositories, preventing repeated-failure stampedes.
- **Offline queue:** `OfflineActionQueue` retries with exponential backoff + jitter,
  FIFO-preserving, idempotent enqueue, dead-letter on budget exhaustion
  (hardened in CHAT-RT-003).
- 🔧 **Fix — backoff jitter.** `ApiClient`'s transport-retry delay was pure
  exponential (`retryDelay * 2^(attempt-1)`) with **no jitter**, so clients that
  failed in the same instant would retry in lockstep and re-stampede the backend.
  Added a pure, seedable `ApiClient.retryBackoffDelay(base, attempt, {random})`
  that applies ±20% jitter, and routed `_delay` through it. Covered by 3 new cases
  in `api_client_test.dart` (within-band, jitter-varies, zero-base safe).
- 🔎 Cleanup: `RetryPolicy` (`retry_policy.dart`) is a well-built exponential+jitter
  helper but is currently **unused** — `ApiClient` has its own inline retry. Worth
  consolidating the two onto `RetryPolicy` in a follow-up (low risk, not blocking).

---

## Verification
- `flutter analyze lib/core/network/api_client.dart` — no issues.
- `flutter test test/core/network/api_client_test.dart` — **39 passing** (incl. 3 new jitter cases).
- ERR-001/002 verified by source review of the taxonomy, crash-reporting wiring, and error-boundary installation.

## Tracked follow-ups
- Consolidate `ApiClient` retry onto the existing `RetryPolicy` and remove the duplicate inline logic (ERR-003 cleanup).
- Decide whether to adopt `RepositoryException` as the typed error carrier or remove it (ERR-001 cleanup).
