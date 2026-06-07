# Auth-Method & Account-Lifecycle Support Matrix (Phase 7 Step 12)

- Date: 2026-06-07
- Sources: mobile `pubspec.yaml` + auth repository; web
  `crush-web/packages/core/src/services/auth.ts` + auth store; backend
  `functions/src/index.ts` callables/REST.

## Auth methods

| Method | Mobile | Web | Backend |
|---|---|---|---|
| Email + password | ✅ | ✅ `signInWithEmail` / `signUpWithEmail` | `loginWithPassword`/`signUpWithPassword` callables + `/v1/auth/...` |
| Phone OTP | ✅ | ✅ `signInWithPhoneNumber` (+ reCAPTCHA) | `/v1/auth/otp/{send,verify}` |
| Email OTP | ✅ | (email-link instead) | `requestEmailOtp`/`verifyEmailOtp` |
| Passwordless email link | (n/a) | ✅ `sendSignInLinkToEmail`/`signInWithEmailLink` (`/finishSignIn`) | Firebase Auth |
| Google | ✅ `google_sign_in` | ✅ `signInWithPopup(Google)` | Firebase Auth |
| **Apple** | ✅ `sign_in_with_apple` | **❌ excluded (see decision)** | Firebase Auth (OAuth) |
| Device verification | ✅ `/new-device` | ✅ `/auth/device-verify` (UX-only, see device_trust_decision) | — |

## Apple Sign-In on Web — DECISION: excluded (documented)

**Decision:** Apple Sign-In is **not** offered on the web app at this time;
it remains a mobile-only method. Web users use Google, email/password, phone
OTP, or the passwordless email link.

**Rationale:**
- "Sign in with Apple" on web (Firebase `OAuthProvider('apple.com')` +
  `signInWithPopup`) requires Apple Developer infrastructure that is not a code
  change: an Apple **Services ID**, a registered **Return URL**
  (`https://crush.app/__/auth/handler`), a verified domain, and a private key —
  configured in the Apple Developer portal + Firebase console.
- Google + email/password + phone + email-link already cover web sign-in.
- Apple's "Sign in with Apple" App Store requirement applies to the iOS app
  (which has it), not the web app.

**Path to add later (if desired):**
1. Apple Developer: create a Services ID, enable Sign in with Apple, register the
   return URL + verify `crush.app`, create a Sign-in key.
2. Firebase console: enable Apple provider with the Services ID + key.
3. Web: add `signInWithApple()` to `auth.ts`
   (`signInWithPopup(auth, new OAuthProvider('apple.com').addScope('email'))`),
   wire a button into the login/signup pages, and route errors through
   `getAuthErrorMessage`.

## Account lifecycle

| Lifecycle action | Mobile | Web | Backend (source of truth) |
|---|---|---|---|
| Email verification | ✅ | ✅ `/auth/verify-email` | Firebase Auth + `isEmailVerified` |
| Password reset | ✅ | ✅ `/auth/forgot-password` | `requestPasswordReset`/`resetPasswordWithToken` |
| Password change | ✅ | ✅ `updatePassword` (reauth) | `changePassword` / `/v1/auth/password/change` |
| Email change | ✅ `/change-email` | ✅ `updateEmail` (reauth) | OTP-verified |
| Session expiry | session services | HttpOnly cookie + middleware idle-timeout | ID token TTL + App Check |
| Account deletion (grace) | ✅ | ✅ `/settings/account` | `requestAccountDeletion` + `processScheduledAccountDeletions` |
| Cancel deletion | ✅ | ✅ | `cancelAccountDeletion` |
| Data export (GDPR) | ✅ | ✅ | `requestDataExport` → `processDataExportRequest` |

## Shared error presentation

Both web flows present errors via `getAuthErrorMessage`
(`packages/core/src/services/auth_errors.ts`) — Firebase Auth + callable codes
mapped to consistent friendly messages (never raw Firebase strings).

## Done-when status (Step 12)

- ✅ Support matrix published (this doc).
- ✅ Apple-on-web explicitly documented (excluded + path).
- ✅ Login/signup/phone/email-verify/password-reset/deletion/cancellation/export
  aligned to backend commands.
- ⏳ Cross-platform account-lifecycle **E2E** (onboarding redirect, session
  timeout, deletion grace period, cancelled deletion) — needs a staging
  environment; tracked with the Phase 5 cutover/E2E work.
