# Auth System Design (Username + Email + Password + OTP)

## Acceptance criteria
- App opens to an Auth Gateway with two explicit options: Login and Sign Up.
- A valid, unexpired session routes directly to Home; otherwise show the Auth Gateway.
- Sign Up is only accessible from the Auth Gateway.
- Login supports username or email + password with uniform error messages.
- Forgot password uses email OTP and requires re-login after reset.
- OTP is 6 digits, expires in 10 minutes, one-time use, rate limited, and stored hashed.
- Passwords are hashed with bcrypt before storage.
- Rate limits and audit logs are enforced for OTP and password logins.

## Recommended approach (Option A)
Firebase-first with Cloud Functions for password auth (bcrypt), OTP workflows, rate limiting, and audit logging. Sessions use Firebase custom tokens (JWT) + refresh tokens handled by Firebase Auth, which stores them securely on device.

Policy choices:
- Email required at sign up to support password recovery and reduce account takeover risk.
- Email is verified immediately after sign up via OTP.
- Password reset requires re-login (safer than auto-login after recovery).

## Architecture + navigation flow (text diagram)
1) App launch -> Splash -> if session valid -> Home
2) Splash -> Auth Gateway -> (Login | Sign Up)
3) Login -> identifier + password -> loginWithPassword -> Firebase custom token -> Home
4) Sign Up -> username + email + password -> signUpWithPassword -> custom token -> send OTP -> verify OTP -> Home
5) Forgot password -> email -> requestEmailOtp(reset_password) -> verify OTP -> set new password -> back to Login
6) Account security screens -> Add/Verify Email, Change Email, New Device -> request/verify OTP

## Threat model highlights
- Enumeration resistance: uniform responses for login and OTP requests.
- OTP security: 6 digits, 10-minute TTL, one-time use, hashed, lockout after failures.
- Abuse protection: per-IP + per-identifier rate limiting for OTP and login.
- Auditability: append-only auth audit logs with action/status/ip/ua.

## Data model (Firestore)
- users/{uid}
  - username: string
  - usernameLower: string
  - email: string
  - emailLower: string
  - isEmailVerified: bool
  - phoneNumber: string
  - isPhoneVerified: bool
  - isIdVerified: bool
  - plan: "free" | "plus"
  - profile: {...}
- usernames/{usernameLower}
  - uid: string
  - createdAt: timestamp
- auth_credentials/{uid}
  - passwordHash: string (bcrypt)
  - passwordUpdatedAt: timestamp
- auth_email_otps/{otpId}
  - identifierHash: string (hash of email/username)
  - uid: string?
  - purpose: "login" | "add_email" | "change_email" | "reset_password" | "new_device" | "sensitive_action"
  - otpHash: string
  - otpSalt: string
  - expiresAt: timestamp
  - usedAt: timestamp?
  - failedAttempts: number
  - lockedUntil: timestamp?
  - createdAt: timestamp
- auth_rate_limits/{key}
  - key: string (ip:xxx or id:xxx)
  - attempts: number
  - windowStart: timestamp
  - blockedUntil: timestamp?
- auth_audit_logs/{logId}
  - uid: string?
  - identifierHash: string?
  - ip: string?
  - action: string
  - status: "ok" | "blocked" | "invalid" | "error"
  - metadata: map
  - createdAt: timestamp

## Cloud Functions (callable) endpoints
- signUpWithPassword
  - Request: { username: "ava", email: "ava@example.com", password: "..." }
  - Response: { status: "ok", customToken: "..." }
- loginWithPassword
  - Request: { identifier: "ava" | "ava@example.com", password: "..." }
  - Response: { status: "ok", customToken: "..." }
- requestEmailOtp
  - Request: { identifier: "usernameOrEmail", purpose: "add_email" | "reset_password" | ... , email?: "user@email.com" }
  - Response: { status: "ok" }
- verifyEmailOtp
  - Request: { identifier: "usernameOrEmail", purpose: "add_email" | "reset_password" | ... , otp: "123456", newEmail?: "...", newPassword?: "..." }
  - Response: { status: "ok" }
- claimUsername
  - Request: { username: "ava" }
  - Response: { status: "ok", username: "ava" }

Example (login with password):
Request -> loginWithPassword
  { "identifier": "ava@example.com", "password": "supersecret" }
Response:
  { "status": "ok", "customToken": "..." }

Example (forgot password):
Request -> requestEmailOtp
  { "identifier": "ava@example.com", "purpose": "reset_password" }
Response:
  { "status": "ok" }

Request -> verifyEmailOtp
  { "identifier": "ava@example.com", "purpose": "reset_password", "otp": "123456", "newPassword": "newsecret" }
Response:
  { "status": "ok" }

## Frontend screens + state
- AuthGatewayScreen (Login | Sign Up)
- LoginScreen (username/email + password)
- SignUpScreen (username + email + password -> OTP verify)
- ForgotPasswordScreen (email -> OTP -> new password)
- EmailProtectionScreen (add/verify email)
- ChangeEmailScreen (change email)
- NewDeviceScreen (OTP for new device)

Flutter implementations:
- lib/features/auth/presentation/screens/auth_gateway_screen.dart
- lib/features/auth/presentation/screens/login_screen.dart
- lib/features/auth/presentation/screens/sign_up_screen.dart
- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/features/auth/presentation/screens/email_protection_screen.dart
- lib/features/auth/presentation/screens/change_email_screen.dart
- lib/features/auth/presentation/screens/new_device_screen.dart

## Web parity
- Web uses the same Flutter routes and screens as mobile, so auth flows are identical.
- Ensure Functions CORS is enabled (authApi already sets CORS headers).
- If you deploy to a non-default Functions domain, pass `--dart-define=CRUSH_AUTH_FUNCTION_BASE_URL=...` (and optionally `CRUSH_AUTH_FUNCTION_NAME`) for web builds.

## Email template (OTP)
Subject: Your CrushHour verification code
Body:
Hello,

Your CrushHour verification code is: {{OTP}}
This code expires in 10 minutes and can only be used once.

If you did not request this, you can ignore this email.

Thanks,
CrushHour Security

## Testing plan + key automated tests
- Unit: password hashing + verification (bcrypt), OTP hash/verify, rate limit windows.
- Unit: loginWithPassword uniform errors for unknown user vs wrong password.
- Integration: signup -> login -> verify email OTP flow.
- Integration: forgot password -> reset -> re-login.
- Integration: lockout/cooldown after repeated OTP failures.
- UI: Auth Gateway routes only to Login/Sign Up.

## Implementation plan & folder structure
- functions/src/index.ts
  - Add signUpWithPassword + loginWithPassword + bcrypt helpers.
  - Extend OTP flows to update hashed passwords.
- lib/data/repositories/
  - Add loginWithPassword + signUpWithPassword.
  - Update FirebaseAuthRepository + FakeAuthRepository.
- lib/features/auth/presentation/screens/
  - Add AuthGatewayScreen, LoginScreen, SignUpScreen.
  - Update ForgotPasswordScreen to email-only reset.
- lib/core/router.dart
  - Add routes for Auth Gateway, Login, Sign Up.
- lib/features/auth/presentation/screens/splash_screen.dart
  - Route unauthenticated users to Auth Gateway.

## Option B: Custom backend implementation (overview)
- API: Node.js (Fastify/Express) + PostgreSQL
- Rate limiting / OTP: Redis
- Email: SendGrid or SES
- Auth: JWT + refresh tokens

Core endpoints:
- POST /auth/signup
- POST /auth/login
- POST /auth/otp/request
- POST /auth/otp/verify
- POST /auth/password/reset
- POST /auth/email/change

Data tables:
- users (id, username, email, password_hash, email_verified, created_at)
- username_index (username_lower, user_id)
- otp_challenges (id, identifier_hash, otp_hash, salt, expires_at, used_at, failed_attempts)
- rate_limits (key, attempts, window_start, blocked_until)
- auth_audit_log (id, user_id, action, status, ip, user_agent, created_at)
