# Auth Silent Refresh & Safe Retry — 2026-05-30

Scope: `AUTH-SEC-002` from `docs/TODO_AUTH_SECURITY.md`.

## Summary

Standardized silent token refresh in the shared HTTP client wrapper so an
expired session refreshes once and retries the original request, and only
hard-fails (routing the user to re-auth) when the refresh itself is invalid.

The previous implementation already retried a single request once after a 401
refresh, but two gaps remained against the acceptance criteria:

- **Refresh storms** — when several requests expired at the same moment, each
  one independently called `tokenRefreshProvider`, so the refresh token was
  consumed/rotated multiple times. On rotating-refresh-token backends this can
  invalidate the just-issued token and force an unnecessary logout.
- **Repeated re-auth routing** — `onAuthError` (wired to `signOut`) fired once
  per failed request, so a burst of 401s triggered multiple logout handlers
  instead of a single clean re-auth.

Both are now closed in `lib/core/network/api_client.dart`.

## Behavior Matrix

| Scenario | Before | After |
| --- | --- | --- |
| Single request, token expired, refresh succeeds | Retried once with new token | Unchanged — retries once with new token |
| Single request, refresh returns null/throws | 401 surfaced, `onAuthError` fired | 401 surfaced, `onAuthError` fired once |
| N concurrent requests expire together | N refresh calls (refresh storm) | 1 shared in-flight refresh; all N retry once |
| N concurrent requests, refresh fails | `onAuthError` fired N times → N logouts | `onAuthError` fired once → single re-auth |
| Request succeeds after re-auth | Latch never reset | Success clears latch so a later expiry routes again |
| Retry still returns 401 (token truly rejected) | Hard-fail (no second retry) | Unchanged — hard-fail, no duplicate retry |

## Changes

- `ApiClient._refreshAuthToken()` coalesces concurrent refreshes into one
  in-flight `Future` (`_inFlightRefresh`), cleared in a `finally` so the next
  genuine expiry can refresh again. Concurrent 401s await the same refresh and
  then each retry once.
- `ApiClient._notifyAuthError()` routes to re-auth via `onAuthError` exactly
  once per expiry, guarded by `_authErrorNotified`.
- The latch resets on any 2xx response and after a successful refresh, so the
  client recovers cleanly once auth is healthy again.
- Per-request single-retry is still enforced by `hasAttemptedTokenRefresh`, so
  no request ever retries more than once.

## Notes / Boundaries

- The refresh is wired in `lib/core/di.dart` to
  `HttpAuthRepository.refreshToken()`, which force-refreshes the Firebase ID
  token via the session bridge. The Firebase SDK already coalesces its own
  token fetches; the new single-flight guard protects the HTTP layer (and any
  non-Firebase refresh provider) from refresh storms regardless of backend.
- This is HTTP-client-wrapper hardening and applies to all `http_*`
  repositories that share the DI `ApiClient`. Firebase-mode repositories use
  the SDK directly and are unaffected.

## Verification

- `flutter test test/core/network/api_client_test.dart`
- `flutter test test/features/auth/data/repositories/http_auth_repository_contract_test.dart`
- `flutter analyze lib/core/network/api_client.dart test/core/network/api_client_test.dart`

## Manual Follow-Up

- Manual stale-session verification on real mobile/web runtimes (let a session
  expire, confirm in-app actions silently refresh and continue, and confirm an
  invalidated session routes cleanly to re-auth without a refresh storm) is
  still required before store submission.
