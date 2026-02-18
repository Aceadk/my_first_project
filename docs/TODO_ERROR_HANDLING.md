# TODO: Error Handling Module
**Priority:** P1 – High
**Estimated Effort:** 35-45 hours
**Dependencies:** Result pattern (`lib/core/utils/result.dart`), CrashReportingService, ErrorMessages
**Assigned:** AI + Developer

---

## ERR-001: Implement Global Error Boundary Widget
**Files:** `lib/app.dart`, `lib/core/widgets/error_boundary.dart` (new)
**Description:** No global error boundary. Rendering errors show red/grey screen. Create ErrorBoundary widget wrapping app root and each feature section for graceful fallback.
**Acceptance Criteria:**
- [ ] `ErrorBoundary` widget catches FlutterError and shows branded fallback UI
- [ ] Fallback: "Something went wrong" with retry and go-home buttons
- [ ] Error logged to CrashReportingService with screen name and stack trace
- [ ] Feature-level boundaries: chat crash doesn't crash discovery
- [ ] Boundary resets state on retry
**Testing:** Widget test throwing in child; integration test verifying isolation.

---

## ERR-002: Implement Circuit Breaker Pattern for API Calls
**Files:** `lib/core/network/circuit_breaker.dart` (new), `lib/core/network/api_client.dart`
**Description:** No circuit breaker. Backend downtime causes repeated failing calls, poor UX, battery drain. Track failures per endpoint group and "open" after N failures.
**Acceptance Criteria:**
- [ ] CircuitBreaker: tracks failures per endpoint group (auth, chat, discovery, profile)
- [ ] Opens after 5 consecutive failures within 60 seconds
- [ ] Returns immediate error when open; half-opens after 30s cooldown
- [ ] State exposed for UI ("Reconnecting..." banner)
**Testing:** Unit test for circuit state transitions; integration test for UI state.

---

## ERR-003: Replace Generic Error Messages with Specific User-Facing Messages
**Files:** `lib/core/utils/error_messages.dart`, all BLoCs
**Description:** Many BLoCs use generic "Could not..." strings instead of `ErrorMessages` constants. Map all error codes to specific, localized messages.
**Acceptance Criteria:**
- [ ] All BLoC error states use `ErrorMessages` constants
- [ ] Network errors: "No internet connection. Check your connection and try again."
- [ ] Rate limit: "Too many attempts. Please wait [X] minutes."
- [ ] All error messages in ARB files for localization
- [ ] No raw exception `.toString()` shown to users
**Testing:** Unit test for error code mapping; grep audit for inline error strings.

---

## ERR-004: Standardize Retry with Exponential Backoff
**Files:** `lib/core/utils/retry_policy.dart` (new), all BLoCs
**Description:** Ad-hoc retry implementations in some BLoCs, none in others. Create shared `RetryPolicy` utility.
**Acceptance Criteria:**
- [ ] `RetryPolicy` class: configurable max retries, base delay, max delay, jitter
- [ ] Default: 3 retries, 1s base, 30s max
- [ ] All BLoCs migrated to shared RetryPolicy
- [ ] Non-retryable errors (4xx, auth) skip retry
- [ ] Each attempt logged with delay info
**Testing:** Unit test for delay sequence, max retries, non-retryable skip.

---

## ERR-005: Add Structured Error Logging with Context
**Files:** `lib/core/app_logger.dart`, `lib/core/errors.dart`
**Description:** Error logs lack structured context. Add: BLoC name, action, entity ID, and extra context to every error log.
**Acceptance Criteria:**
- [ ] `AppLogger.error()` accepts structured context parameters
- [ ] CrashReportingService attaches BLoC name and action as breadcrumbs
- [ ] All BLoC error handlers pass context
- [ ] No PII in error logs
**Testing:** Unit test for context attachment; security audit for PII.

---

## ERR-006: Handle Offline State with Cached Data Fallback
**Files:** `lib/core/cache/`, chat/discovery/profile screens
**Description:** Cache infrastructure exists but offline handling in UI is inconsistent. Some screens show errors instead of cached data.
**Acceptance Criteria:**
- [ ] Global connectivity monitoring via `ConnectivityCubit`
- [ ] Chat: show cached messages + "Offline" banner
- [ ] Discovery: show cached deck + offline banner, hide swipe actions
- [ ] Profile: render from cache with "Last updated" note
- [ ] Write operations queue in `offline_queue.dart`, sync on reconnect
- [ ] Banner auto-dismisses on reconnection
**Testing:** Integration test toggling connectivity; manual airplane mode test.

---

## ERR-007: Add User-Recoverable Error Actions
**Files:** `lib/design_system/widgets/error_banner.dart`, all error states
**Description:** Error states often lack actionable recovery options. Every error should offer: retry, go back, or contact support.
**Acceptance Criteria:**
- [ ] All error states have at least one action button
- [ ] Discovery: "Try Again" + "Change Filters"
- [ ] Profile save: "Try Again" preserves input + "Discard Changes"
- [ ] Network errors: "Check Connection" deep link to WiFi settings
- [ ] Error recovery actions fire analytics events
**Testing:** Widget tests for action buttons; manual test of recovery paths.
