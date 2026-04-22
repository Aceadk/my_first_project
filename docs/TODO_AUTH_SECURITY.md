# TODO: Authentication & Security Module

- Priority: P0 – Critical
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_API_ARCHITECTURE.md`, `docs/TODO_SECURITY_BACKEND.md`, `docs/TODO_SECURITY_FRONTEND.md`
- Assigned: AI + Developer

## Tasks

### AUTH-SEC-001 - Audit token storage across iOS, Android, iPad, and web
- Files: `lib/features/auth/**`, `lib/core/**`, `/Users/ace/crush-web/**/auth/**`
- Description: Trace every token, refresh token, session cookie, and pending-auth artifact. Verify secure storage, session cleanup, logout clearing, and deletion clearing.
- Acceptance Criteria: storage matrix documented; insecure storage paths removed or tracked; logout and delete flows clear all auth artifacts.
- Testing: unit coverage for storage wrappers plus manual login/logout validation on mobile and web.
- Status: open

### AUTH-SEC-002 - Implement silent token refresh with safe request retry
- Files: auth repositories, HTTP client wrappers, token/session managers
- Description: Standardize silent refresh behavior so expired sessions retry once after refresh and only hard-fail when refresh is invalid.
- Acceptance Criteria: no forced logout on first expiry; duplicate retries prevented; refresh failure routes users to re-auth cleanly.
- Testing: mocked token-expiry integration tests and manual stale-session verification.
- Status: open

### AUTH-SEC-003 - Verify OAuth compliance and provider completeness
- Files: provider-specific auth repositories, iOS entitlements, Android manifests, web auth routes
- Description: Audit Google, Apple, and any other OAuth providers for PKCE, required store compliance, and platform-specific failure handling.
- Acceptance Criteria: Sign in with Apple is compliant for iOS submission; provider flows are documented; provider-specific blockers are tracked with fixes.
- Testing: provider smoke tests on iOS, Android, and web where applicable.
- Status: open

### AUTH-SEC-004 - Harden auth abuse protection
- Files: Functions/auth endpoints, rate-limit helpers, OTP/password-reset flows
- Description: Verify brute-force, OTP abuse, and password-reset abuse protections with clear limits, logging, and safe user-facing messaging.
- Acceptance Criteria: rate limits documented and enforced; abuse tests exist; user-facing errors do not leak account existence details.
- Testing: functions security tests and abuse-fixture coverage.
- Status: open

### AUTH-SEC-005 - Verify account deletion completeness
- Files: account deletion flows, auth repositories, backend user-deletion handlers
- Description: Confirm that account deletion revokes sessions, removes user-owned data, cancels premium access correctly, and meets GDPR/CCPA expectations.
- Acceptance Criteria: deletion map exists; downstream cleanup is complete or explicitly tracked; in-app deletion path is easy to reach.
- Testing: deletion integration test plus manual verification checklist.
- Status: open
