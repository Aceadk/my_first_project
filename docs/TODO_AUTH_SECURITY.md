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
- Status: completed 2026-05-27
- Evidence: `docs/reports/auth_token_storage_audit_2026-05-27.md`
- Verification: `flutter test test/core/services/user_data_clearance_service_test.dart`, `flutter test test/features/auth/data/repositories/auth_secure_storage_test.dart test/features/auth/data/repositories/http_auth_repository_contract_test.dart test/core/services/user_data_clearance_service_test.dart`, `flutter analyze lib/core/services/user_data_clearance_service.dart test/core/services/user_data_clearance_service_test.dart`, `flutter analyze`, `pnpm --dir /Users/ace/crush-web --filter @crush/core typecheck`, `pnpm --dir /Users/ace/crush-web --filter @crush/core lint`
- Manual Follow-up: real-device/browser login, logout, and account-deletion smoke checks remain required before store submission.

### AUTH-SEC-002 - Implement silent token refresh with safe request retry
- Files: auth repositories, HTTP client wrappers, token/session managers
- Description: Standardize silent refresh behavior so expired sessions retry once after refresh and only hard-fail when refresh is invalid.
- Acceptance Criteria: no forced logout on first expiry; duplicate retries prevented; refresh failure routes users to re-auth cleanly.
- Testing: mocked token-expiry integration tests and manual stale-session verification.
- Status: completed 2026-05-30
- Evidence: `docs/reports/auth_silent_refresh_2026-05-30.md`
- Verification: `flutter test test/core/network/api_client_test.dart`, `flutter test test/features/auth/data/repositories/http_auth_repository_contract_test.dart`, `flutter analyze lib/core/network/api_client.dart test/core/network/api_client_test.dart`
- Manual Follow-up: real-device/browser stale-session refresh and re-auth smoke checks remain required before store submission.

### AUTH-SEC-003 - Verify OAuth compliance and provider completeness
- Files: provider-specific auth repositories, iOS entitlements, Android manifests, web auth routes
- Description: Audit Google, Apple, and any other OAuth providers for PKCE, required store compliance, and platform-specific failure handling.
- Acceptance Criteria: Sign in with Apple is compliant for iOS submission; provider flows are documented; provider-specific blockers are tracked with fixes.
- Testing: provider smoke tests on iOS, Android, and web where applicable.
- Status: completed 2026-05-30
- Evidence: `docs/reports/auth_oauth_provider_audit_2026-05-30.md`
- Verification: `flutter analyze` (provider mappers + tests), `flutter test test/features/auth/data/repositories/apple_sign_in_failure_mapper_test.dart test/features/auth/data/repositories/google_sign_in_failure_mapper_test.dart` (17 passing)
- Refactor: extracted shared `mapProviderFirebaseAuthFailure`; closed the untested shared-error-branch coverage gap.
- Manual Follow-up: real-device Apple/Google (iOS, Android) and web Google popup smoke checks remain required before store submission.

### AUTH-SEC-004 - Harden auth abuse protection
- Files: Functions/auth endpoints, rate-limit helpers, OTP/password-reset flows
- Description: Verify brute-force, OTP abuse, and password-reset abuse protections with clear limits, logging, and safe user-facing messaging.
- Acceptance Criteria: rate limits documented and enforced; abuse tests exist; user-facing errors do not leak account existence details.
- Testing: functions security tests and abuse-fixture coverage.
- Status: completed 2026-05-30
- Evidence: `docs/reports/auth_abuse_protection_audit_2026-05-30.md`
- Verification: `npm run build` + `npm run lint` (in `functions/`), `npx mocha --exit test/securityAbuseLanes.test.js` (7 passing), `npx mocha --exit test/callables.test.js` (11 passing)
- Refactor: extracted shared `matchOtpCandidate` (timing-safe OTP match + per-code lockout) used by email-OTP and password-reset verification.
- Manual Follow-up: live brute-force/OTP lockout and reset-enumeration smoke checks remain before store submission.

### AUTH-SEC-005 - Verify account deletion completeness
- Files: account deletion flows, auth repositories, backend user-deletion handlers
- Description: Confirm that account deletion revokes sessions, removes user-owned data, cancels premium access correctly, and meets GDPR/CCPA expectations.
- Acceptance Criteria: deletion map exists; downstream cleanup is complete or explicitly tracked; in-app deletion path is easy to reach.
- Testing: deletion integration test plus manual verification checklist.
- Status: completed 2026-05-30
- Evidence: `docs/reports/auth_account_deletion_audit_2026-05-30.md`
- Verification: `npm run build` + `npm run lint` (in `functions/`), `npx mocha --exit test/accountDeletionMap.test.js` (4 passing), `npx mocha --exit test/callables.test.js` (11 passing)
- Fixes: `cascadeDeleteUserData` now deletes matches across `users`/`userIds`/`participants` (was missing matches) and scrubs top-level `likes`/`swipes`/`blocks`/`reports`; extracted tested `deleteDocsByQuery` + `userRelationDeletionTargets` deletion map.
- Manual Follow-up: staging end-to-end deletion run (grace → cancel → purge) and store-subscription cancellation reminder before submission.
