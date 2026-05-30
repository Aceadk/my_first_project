# Auth Token Storage Audit — 2026-05-27

Scope: `AUTH-SEC-001` from `docs/TODO_AUTH_SECURITY.md`.

## Summary

The mobile app does not store active Firebase ID tokens or refresh tokens in `SharedPreferences`. Auth-critical mobile artifacts use Firebase SDK persistence or `flutter_secure_storage`. Web session access is represented by an HttpOnly cookie set by the Next.js API route. This pass closed two cleanup gaps:

- mobile logout/data-clearance now also clears secure-storage session, route, and biometric/PIN artifacts;
- web sign-out now clears pending email-link state and removes all legacy non-HttpOnly auth session cookies if the server cookie-clear request fails.

## Storage Matrix

| Surface | Artifact | Storage | Cleanup path | Status |
| --- | --- | --- | --- | --- |
| Mobile Firebase auth | Firebase ID/refresh session | Firebase Auth SDK platform persistence | `FirebaseAuthRepository.signOut()` / account deletion calls `signOut()` | OK |
| Mobile email link | `pending_email_link_email` | `AuthSecureStorage` over `flutter_secure_storage` with volatile debug fallback | completion deletes key; repository `signOut()` deletes key | OK |
| Mobile HTTP auth | legacy `auth_access_token`, `auth_refresh_token`, `auth_user_id` | `AuthSecureStorage`; current HTTP repo uses Firebase session bridge for ID tokens | `HttpAuthRepository._clearTokens()` on bootstrap without user and sign-out | OK |
| Mobile session timeout | `last_activity_timestamp` | `flutter_secure_storage` | now cleared by `UserDataClearanceService.clearAllUserData()` | Fixed |
| Mobile preserved route | `app_last_route`, `app_last_route_timestamp` | `flutter_secure_storage` | now cleared by `UserDataClearanceService.clearAllUserData()` | Fixed |
| Mobile biometric fallback | `biometric_auth_enabled`, `biometric_pin_hash` | `flutter_secure_storage` | now cleared by `UserDataClearanceService.clearAllUserData()` | Fixed |
| Mobile app/user preferences | safety, privacy, discovery, offline queue/cache keys | `SharedPreferences` | `UserDataClearanceService.clearAllUserData()` | OK |
| Mobile push token | FCM device token | Firebase Messaging SDK; Firestore user token document | `SessionBloc` unregister path; no local token persistence found | OK for local storage |
| Web Firebase auth | Firebase ID/refresh session | Firebase Web SDK persistence | `authService.signOut()` | OK |
| Web middleware session | `auth-token`, `session-last-active`, `session-remember-me` | HttpOnly SameSite=Lax cookies via `/api/auth/session` | `/api/auth/session DELETE`; legacy fallback now clears all three names | Fixed |
| Web email link | `emailForSignIn` | `localStorage` pending email only, not a token | success removes key; sign-out now removes key | Fixed |
| Web remember me | `crush.rememberMe` | `localStorage` preference only, not a token | intentionally retained as user preference | OK |
| Web trusted device id | `crush.trustedDeviceId` | `localStorage` device identifier | retained so trusted-device checks survive browser restarts | Tracked non-token identifier |

## Findings

1. `UserDataClearanceService` previously only cleared user-specific `SharedPreferences` and image cache. It did not clear secure-storage artifacts that could restore user-specific app state after logout. This is fixed by clearing `SessionManager`, `AppStatePreserver`, and `BiometricService` through the shared clearance path.
2. Web sign-out previously depended on the `/api/auth/session DELETE` route for HttpOnly cookie cleanup. If that request failed, the fallback cleared only `auth-token`, leaving non-HttpOnly legacy `session-last-active` and `session-remember-me` cookies. The fallback now clears all three cookie names.
3. Web email-link sign-in stored `emailForSignIn` in `localStorage` until successful completion. It is not a token, but it is a pending-auth PII artifact. `authService.signOut()` now removes it and clears the in-memory phone confirmation result.
4. Backend legacy REST endpoints still expose custom-token-shaped `access_token` / `refresh_token` fields, but the current Flutter HTTP auth repository no longer stores or refreshes those values directly. Broader endpoint-contract cleanup remains owned by the existing API/auth TODOs, not this storage audit.

## Verification

- `flutter test test/core/services/user_data_clearance_service_test.dart`
- `flutter test test/features/auth/data/repositories/auth_secure_storage_test.dart test/features/auth/data/repositories/http_auth_repository_contract_test.dart test/core/services/user_data_clearance_service_test.dart`
- `flutter analyze lib/core/services/user_data_clearance_service.dart test/core/services/user_data_clearance_service_test.dart`
- `flutter analyze`
- `pnpm --dir /Users/ace/crush-web --filter @crush/core typecheck`
- `pnpm --dir /Users/ace/crush-web --filter @crush/core lint` (passes with existing warnings outside changed files)
- `git diff --check`
- `git -C /Users/ace/crush-web diff --check`
- `scripts/check_ai_docs_sync.sh --files docs/Developer_agent_chat.md docs/TODO_AUTH_SECURITY.md docs/ai_workboard.md docs/reports/auth_token_storage_audit_2026-05-27.md ios/Flutter/Debug.xcconfig ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist lib/core/services/user_data_clearance_service.dart lib/design_system/widgets/glass_bottom_nav_bar.dart lib/features/profile/presentation/screens/profile_setup_screen.dart lib/features/settings/presentation/screens/appearance_settings_screen.dart test/core/services/user_data_clearance_service_test.dart test/features/profile/presentation/screens/profile_setup_screen_keyboard_overflow_test.dart test/design_system/glass_bottom_nav_bar_test.dart test/features/settings/presentation/screens/appearance_settings_screen_test.dart /Users/ace/crush-web/packages/core/src/services/auth.ts /Users/ace/crush-web/packages/core/src/stores/auth.ts`

## Manual Follow-Up

- Manual iOS/Android/iPad/web login/logout and account-deletion smoke checks are still required on real runtime environments before store submission.
