# TODO: Authentication & Security Module
**Priority:** P0 – Critical
**Estimated Effort:** 40-60 hours
**Dependencies:** None (foundation module)
**Assigned:** AI + Developer

---

## AUTH-SEC-001: Audit and Harden Token Storage
**Files:** `lib/core/security/`, `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`
**Description:** Verify `flutter_secure_storage` usage for all sensitive tokens. Confirm no tokens in SharedPreferences or UserDefaults. Audit token lifecycle: creation → storage → refresh → expiry → revocation.
**Acceptance Criteria:**
- [ ] All tokens stored in flutter_secure_storage (Keychain iOS / Keystore Android)
- [ ] No sensitive data in SharedPreferences
- [ ] Token cleared on logout and account deletion
**Testing:** Unit test verifying secure storage read/write/delete for auth tokens.

---

## AUTH-SEC-002: Verify PKCE Implementation for OAuth Providers
**Files:** `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`
**Description:** Firebase Auth handles PKCE internally for Google and Apple sign-in. Verify PKCE is active via Firebase Auth SDK version (>= 6.0) and that no custom OAuth flows bypass it.
**Acceptance Criteria:**
- [ ] Firebase Auth SDK version supports PKCE (confirmed: v6.1.3)
- [ ] No custom OAuth code exchange flows that skip PKCE
- [ ] Apple Sign-In uses AuthorizationCodeFlow (via sign_in_with_apple package)
**Testing:** Manual verification via network inspection during OAuth flows.

---

## AUTH-SEC-003: Implement Silent Token Refresh with Request Retry
**Files:** `lib/core/network/api_client.dart`, `lib/features/auth/presentation/bloc/session_bloc.dart`
**Description:** Currently Firebase Auth handles token refresh automatically. For HTTP mode, verify ApiClient retries failed requests after token refresh. Ensure 401 responses trigger refresh, not logout.
**Acceptance Criteria:**
- [ ] ApiClient intercepts 401 responses and retries with refreshed token
- [ ] Only logout after refresh token failure (not on first 401)
- [ ] Session is preserved during background token refresh
**Testing:** Unit test with mocked HTTP client returning 401 then 200 after refresh.

---

## AUTH-SEC-004: Audit Rate Limiting on Auth Endpoints
**Files:** `functions/src/index.ts` (lines 258-400)
**Description:** Verify rate limiting on: login, signup, OTP request, password reset. Cloud Functions have `auth_rate_limits` collection. Confirm limits are enforced and properly configured.
**Acceptance Criteria:**
- [ ] Login: max 5 attempts per 15 minutes per IP/email
- [ ] OTP request: max 3 per hour per phone/email
- [ ] Password reset: max 3 per hour per email
- [ ] Rate limit responses include clear error message and retry-after hint
**Testing:** Cloud Function integration tests with rapid-fire requests.

---

## AUTH-SEC-005: Verify Account Deletion Completeness (GDPR/CCPA)
**Files:** `functions/src/index.ts` (requestAccountDeletion, cascadeDeleteUserData, processScheduledAccountDeletions)
**Description:** Account deletion has 14-day grace period. Verify cascade deletes ALL user data: Firestore documents, Storage files, RTDB entries, Analytics data, FCM tokens.
**Acceptance Criteria:**
- [ ] All Firestore collections cleaned: users, matches, messages, likes, reports, blocks, stories
- [ ] All Storage files deleted: photos, videos, verification docs, chat media
- [ ] FCM tokens revoked
- [ ] Account recovery works within grace period
- [ ] Deletion confirmation email sent
**Testing:** Integration test: create user → populate data → delete → verify all data gone after grace period.

---

## AUTH-SEC-006: Implement Biometric Authentication with Fallback
**Files:** `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`, `ios/Runner/Info.plist`
**Description:** NSFaceIDUsageDescription present in Info.plist but biometric auth UI is incomplete. Implement Face ID / Touch ID / fingerprint as optional login method with PIN fallback.
**Acceptance Criteria:**
- [ ] Biometric prompt shows on supported devices
- [ ] Fallback to password/PIN if biometric fails
- [ ] User can enable/disable in settings
- [ ] Works on iPad (Face ID on newer iPads, Touch ID on older)
**Testing:** Widget test for biometric settings toggle; manual test on device.

---

## AUTH-SEC-007: Verify Sign in with Apple Implementation
**Files:** `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart` (line 529-537), `lib/features/auth/presentation/screens/auth_gateway_screen.dart`
**Description:** Sign in with Apple is implemented (`supportsAppleSignIn: true`). Verify it's visible in the auth gateway UI, handles email hiding, and works on iPad.
**Acceptance Criteria:**
- [ ] Apple Sign-In button shown on auth gateway (iOS only)
- [ ] Handles "Hide My Email" relay addresses
- [ ] Works on all iPad models
- [ ] Proper error handling for Apple Sign-In failures
- [ ] Revocation webhook handling (Apple requires this)
**Testing:** Manual test on iOS device; unit test for Apple credential handling.
**Status:** Partially implemented — verify UI visibility and iPad support.

---

## AUTH-SEC-008: Concurrent Session Management
**Files:** `lib/features/auth/presentation/bloc/session_bloc.dart`, `functions/src/index.ts`
**Description:** Audit what happens when user logs in from multiple devices. Ensure: sessions don't conflict, password change invalidates other sessions, account deletion signs out all devices.
**Acceptance Criteria:**
- [ ] Password change triggers signOut on other devices (Firebase Auth handles this)
- [ ] FCM tokens registered per device (not overwritten)
- [ ] Account deletion signs out all active sessions
- [ ] No stale state shown on secondary devices after changes on primary
**Testing:** Manual test with two devices logged into same account.

---

## AUTH-SEC-009: Auth Error Messages Don't Leak System Information
**Files:** `lib/core/utils/error_messages.dart`, `functions/src/index.ts`
**Description:** Verify error messages use generic text ("Invalid credentials") not specific ("Email not found" vs "Wrong password"). Check both client-side and server-side error messages.
**Acceptance Criteria:**
- [ ] Login errors: "Invalid email or password" (not "Email not found")
- [ ] Rate limit errors: "Too many attempts. Try again later." (not IP/count details)
- [ ] Server errors: "Something went wrong" (not stack traces or internal details)
- [ ] OTP errors: "Invalid or expired code" (not "Code expired 5 minutes ago")
**Testing:** Review all error strings in error_messages.dart and Cloud Functions.

---

## AUTH-SEC-010: Harden Password Reset Flow Against Abuse
**Files:** `functions/src/index.ts` (requestPasswordReset, verifyPasswordResetOtp, resetPasswordWithToken)
**Description:** Verify password reset: OTP is time-limited, single-use, rate-limited. Token cannot be reused. Email notifications sent on password change.
**Acceptance Criteria:**
- [ ] OTP expires after 10 minutes
- [ ] OTP is single-use (marked used after verification)
- [ ] Password reset triggers email notification to account owner
- [ ] Rate limited: max 3 reset requests per hour
- [ ] New password meets strength requirements (min 8 chars, server-side validated)
**Testing:** Unit test with expired/reused OTP; rate limit test.

---

## AUTH-SEC-011: Age Verification Enforcement (Store Requirement)
**Files:** `lib/features/auth/presentation/screens/basic_info_screen.dart`, `functions/src/index.ts`
**Description:** Dating apps require 18+ age verification. Currently DOB is collected and age checked, but users under 18 only get a warning, not rejection. Enforce server-side.
**Acceptance Criteria:**
- [ ] Client-side: DOB picker prevents selecting dates making user < 18
- [ ] Server-side: Account creation rejects users under 18
- [ ] Error message: Clear "You must be 18 or older to use Crush"
- [ ] No workaround by editing DOB after signup
**Testing:** Unit test with DOB making user 17 years old.
