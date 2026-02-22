# Authentication & Security Module

Priority: P0 - Critical
Scope: Login, signup, password reset, token management, session handling, biometric auth, OAuth providers, account deletion.

## Action Items

### [x] AUTH-SEC-001: Audit token storage mechanism across all platforms

- **Description**: Migrate all sensitive token storage from SharedPreferences to FlutterSecureStorage (Keychain on iOS, Keystore on Android). Update push_notification_service.dart and app_state_preserver.dart.
- **Affected Files**: lib/core/services/push_notification_service.dart, lib/core/services/app_state_preserver.dart, lib/core/di.dart
- **Acceptance Criteria**: SharedPreferences is only used for non-sensitive preferences. Auth tokens are 100% in secure storage.
- **Testing Requirements**: Unit test secure storage wrapper. E2E test confirming tokens persist securely across app restarts.

### AUTH-SEC-002: Verify PKCE implementation for all OAuth providers

- **Description**: Ensure Google and Apple sign-in flows use PKCE to prevent authorization code interception attacks.
- **Affected Files**: lib/features/auth/data/repositories/impl/http_auth_repository.dart
- **Acceptance Criteria**: Code challenge and code challenge methods are securely generated and validated.
- **Testing Requirements**: Integration test simulating OAuth flow verifying PKCE parameters are present.

### AUTH-SEC-003: Implement silent token refresh with request retry logic

- **Description**: The app currently risks logging users out prematurely if a token expires. Implement a Dio interceptor that catches 401s, uses refresh_token to get a new JWT, and seamlessly retries the failed request.
- **Affected Files**: lib/core/network/dio_client.dart
- **Acceptance Criteria**: 401 Unauthorized triggers silent refresh. User is only logged out if the refresh token itself is expired.
- **Testing Requirements**: Unit test mocking a 401 response and a successful refresh response.

### AUTH-SEC-004: Audit rate limiting on all auth endpoints

- **Description**: Prevent brute force attacks on login and OTP endpoints.
- **Affected Files**: Backend API definitions and frontend error handling logic.
- **Acceptance Criteria**: Frontend respects 429 Too Many Requests and shows a timer/countdown.
- **Testing Requirements**: Test submitting 10 invalid passwords rapidly triggers the rate limit UI.

### AUTH-SEC-005: Verify account deletion completeness (GDPR compliance)

- **Description**: Account deletion must permanently expunge all user records, matches, chats, and photos across all databases, conforming to Apple's strict in-app deletion requirements.
- **Affected Files**: lib/features/auth/data/repositories/impl/\*
- **Acceptance Criteria**: Deletion wipes all Firebase/HTTP data and revokes third-party access tokens.
- **Testing Requirements**: E2E automated test that creates an account, uploads a photo, sends a message, deletes the account, and asserts 404s for all previous data.

### AUTH-SEC-006: Enforce iPad Layout Bounds on Auth Screens

- **Description**: Fix missing LayoutBuilder boundaries on terms_conditions_screen.dart, email_protection_screen.dart, change_email_screen.dart, and new_device_screen.dart.
- **Affected Files**: lib/features/auth/presentation/screens/\*.dart
- **Acceptance Criteria**: Max content width constrained to 600px on iPad to prevent stretched text fields.
- **Testing Requirements**: Launch app on iPad Pro 12.9" simulator and visually verify auth forms are centered and constrained.
