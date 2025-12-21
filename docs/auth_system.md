# Auth System Design (Username + Email OTP)

## Best approach (recommended)
Firebase-first: keep Firebase Auth for identity + tokens, Firestore for user data, and add Cloud Functions to handle email OTP + username uniqueness + audit logs. This fits the existing Flutter + Firebase stack, minimizes new infra, and still meets OTP + security requirements.

## Option A: Firebase-first implementation

### Core flows (concise)
- Sign up
  - Phone OTP or email OTP login (passwordless). After auth, user chooses a unique username.
- Login (username or email)
  - User enters username or email -> request email OTP -> verify OTP -> sign in with Firebase custom token.
- Add/Verify Email (account protection)
  - Logged-in user enters email -> request OTP -> verify OTP -> update Firebase Auth email + Firestore fields.
- Change Email
  - Same as add/verify, but also update previous email fields and audit.
- Forgot Password (if password exists)
  - User enters email or username -> request OTP -> verify OTP -> set new password.
- New device / risky action 2FA
  - Request OTP with purpose = new_device or sensitive_action -> verify OTP before proceeding.

### Threat model highlights
- Enumeration: all OTP requests return a uniform response regardless of account existence.
- OTP reuse: OTPs are one-time, hashed at rest, with 10-minute expiry.
- Abuse: per-IP + per-identifier rate limits + cooldown after failed attempts.
- Brute force: lock OTP record after repeated failures; add exponential cooldown.
- Auditability: append-only auth audit log records all actions + outcomes.

### Data model (Firestore)
- users/{uid}
  - username: string
  - usernameLower: string
  - email: string?
  - emailLower: string?
  - isEmailVerified: bool
  - phoneNumber: string?
  - isPhoneVerified: bool
  - isIdVerified: bool
  - plan: "free" | "plus"
  - profile: {...}
- usernames/{usernameLower}
  - uid: string
  - createdAt: timestamp
- auth_email_otps/{otpId}
  - identifierHash: string (hash of email/username)
  - emailLower: string? (if resolved)
  - uid: string? (if resolved)
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

### Cloud Functions (callable) endpoints
- requestEmailOtp
  - Request: { identifier: "usernameOrEmail", purpose: "login" | ... , email?: "user@email.com" }
  - Response: { status: "ok" }
  - Notes: resolves username -> email if possible, sends OTP via email, stores hashed OTP.
- verifyEmailOtp
  - Request: { identifier: "usernameOrEmail", purpose: "login" | ... , otp: "123456", newEmail?: "...", newPassword?: "..." }
  - Response (login): { status: "ok", customToken: "..." }
  - Response (other): { status: "ok" }
- claimUsername
  - Request: { username: "myname" }
  - Response: { status: "ok", username: "myname" }
- (Optional) resolveIdentifier
  - Request: { identifier: "usernameOrEmail" }
  - Response: { status: "ok" } (no enumeration)

### Email templates (OTP)
Subject: Your CrushHour verification code
Body:
Hello,

Your CrushHour verification code is: {{OTP}}
This code expires in 10 minutes and can only be used once.

If you did not request this, you can ignore this email.

Thanks,
CrushHour Security

### Frontend screens & state
- Sign up / login
  - EmailAuthScreen -> add Email OTP tab (username or email).
  - OTP screen for email verification (inline or dedicated).
- Add/Verify Email screen (account protection)
  - Enter email -> request OTP -> verify OTP.
- Change Email screen
  - Same flow as add/verify with updated copy.
- Forgot Password screen
  - Enter identifier -> OTP -> new password.
- New Device / sensitive action prompt
  - OTP verify step before action proceeds.

### Testing checklist / edge cases
- OTP expires at 10 minutes, cannot be reused.
- Multiple OTP requests in window -> rate limit triggers.
- Failed OTP attempts -> lockout cooldown.
- Username uniqueness enforced (case-insensitive).
- Email added later: verify OTP and update user doc + Firebase Auth email.
- Login with username -> OTP -> sign-in works.
- Uniform errors: no account enumeration via responses or timing.
- Audit logs recorded for all request/verify actions.

### Implementation plan & folder structure
- functions/src/index.ts
  - Add OTP + username functions + helpers.
- lib/data/repositories/
  - Update AuthRepository + FirebaseAuthRepository + FakeAuthRepository.
  - Update ProfileRepository (optional) for username claim.
- lib/logic/auth/
  - Add events + state for email OTP flows.
- lib/presentation/screens/
  - Update EmailAuthScreen; add EmailProtectionScreen + ForgotPasswordScreen.
- lib/core/router.dart
  - Add routes for new screens.

## Option B: Custom backend implementation (overview)

### Stack
- API: Node.js (Fastify/Express) + PostgreSQL
- Rate limiting / OTP: Redis
- Email: SendGrid or SES
- Auth: JWT + refresh tokens

### Core endpoints
- POST /auth/otp/request
- POST /auth/otp/verify
- POST /auth/username/claim
- POST /auth/password/reset
- POST /auth/login
- POST /auth/email/change

### Data tables (example)
- users (id, username, email, password_hash, email_verified, created_at)
- username_index (username_lower, user_id)
- otp_challenges (id, identifier_hash, otp_hash, salt, expires_at, used_at, failed_attempts)
- rate_limits (key, attempts, window_start, blocked_until)
- auth_audit_log (id, user_id, action, status, ip, user_agent, created_at)

### Notes
- Same OTP + rate limiting + audit rules as Firebase-first design.
- JWT scopes to protect sensitive actions.
