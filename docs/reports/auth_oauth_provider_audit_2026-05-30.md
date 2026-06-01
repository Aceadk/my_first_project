# OAuth Provider Compliance Audit — 2026-05-30

Scope: `AUTH-SEC-003` from `docs/TODO_AUTH_SECURITY.md`.
Surface: provider auth repositories, iOS entitlements/Info.plist, Android
manifest, and the web auth routes.

## Summary

Sign in with Apple and Google are both implemented with the correct
replay-protection and platform configuration, and Apple is offered alongside
Google on iOS — satisfying App Store Guideline 4.8. The shared
`FirebaseAuthException` mapping that both provider failure mappers duplicated
was extracted into one helper, and the previously-untested shared error
branches now have coverage.

## Provider Matrix

| Provider | iOS | Android | Web | Replay / config |
| --- | --- | --- | --- | --- |
| Apple | ✅ native `SignInWithApple` | ✅ (Firebase OAuth) | ❌ (not offered) | `nonce = sha256(rawNonce)`, `rawNonce` passed to the Firebase credential; entitlement `com.apple.developer.applesignin = [Default]` in both `Runner.entitlements` (dev) and `RunnerRelease.entitlements` (prod) |
| Google | ✅ native `google_sign_in` | ✅ native | ✅ `signInWithPopup` | iOS reversed-client-ID URL scheme present in `Info.plist`; native flow falls back from `idToken` to authorized `accessToken`; web/Windows request `email`+`profile` scopes |
| Email link | ✅ | ✅ | ✅ | passwordless, separate flow |
| Password | ✅ | ✅ | ✅ | backend callable |

## Compliance Findings

1. **App Store Guideline 4.8 — satisfied.** The iOS app offers Sign in with
   Apple in addition to Google. Apple sign-in:
   - checks `SignInWithApple.isAvailable()` before starting;
   - generates a cryptographically secure nonce (`Random.secure()`) and sends
     its SHA-256 to Apple, passing the raw nonce to the Firebase OAuth
     credential — the standard replay-protection (PKCE-equivalent) pattern;
   - requests `email` + `fullName` scopes and applies Apple's name to the
     Firebase display name on first authorization;
   - rejects a missing identity token.
2. **Entitlements correct for submission.** `applesignin` is present in both the
   development and release entitlements, and `aps-environment` is correctly
   `development`/`production` per file. The Google keychain-sharing access group
   is present for native Google sign-in on iOS.
3. **Platform-specific failure handling is comprehensive.** Both mappers handle
   cancellation, device/config errors with actionable guidance (Apple ID setup,
   iOS Google client config, keychain entitlement), and the Firebase provider
   errors (`account-exists-with-different-credential`, `operation-not-allowed`,
   `invalid-credential`/`missing-or-invalid-nonce`, `too-many-requests`,
   `network-request-failed`).

## Refactor (this change)

Both `apple_sign_in_failure_mapper.dart` and `google_sign_in_failure_mapper.dart`
duplicated the entire `FirebaseAuthException` `switch`. Extracted
`mapProviderFirebaseAuthFailure(error, providerLabel, invalidCredentialMessage,
invalidCredentialCodes)` into
`provider_firebase_auth_failure_mapper.dart`; each mapper now delegates the
shared codes and keeps only its provider-specific branches. Behavior is
unchanged (Apple still maps `missing-or-invalid-nonce` to credential rejection;
each provider keeps its own `operation-not-allowed`/`invalid-credential`
wording) and is verified by the expanded mapper tests.

## Tracked / Non-Blocking

- **Web does not offer Apple sign-in.** Acceptable: Guideline 4.8 targets the
  native iOS app (which offers it); the web app offers Google + email-link +
  password. Tracked as an optional parity item, not a submission blocker.
- **Associated-domains entitlement is empty (`<array/>`).** Universal Links are
  not currently configured; deep-link auth on iOS relies on custom URL schemes.
  No action required unless Universal Links are adopted.

## Verification

- `flutter analyze` (provider mappers + tests) — clean
- `flutter test test/features/auth/data/repositories/apple_sign_in_failure_mapper_test.dart test/features/auth/data/repositories/google_sign_in_failure_mapper_test.dart` (17 passing; 6 new shared-branch cases)

## Manual Follow-Up

- Real-device provider smoke tests remain required before store submission:
  Apple + Google sign-in on a physical iPhone and Android device, plus Google
  popup on web, including the cancel and account-collision paths.
