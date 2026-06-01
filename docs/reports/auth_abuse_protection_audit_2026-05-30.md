# Auth Abuse-Protection Audit — 2026-05-30

Scope: `AUTH-SEC-004` from `docs/TODO_AUTH_SECURITY.md`.
Surface: Cloud Functions auth callables, the durable rate-limit helper, and the
OTP / password-reset flows.

## Summary

Brute-force, OTP-abuse, and password-reset-abuse protections are present,
enforced, and layered (durable Firestore rate limits + per-OTP lockout +
constant-time comparisons + enumeration-safe messaging + hashed-identifier audit
logging). No security gap was found. The OTP candidate-matching/lockout loop —
previously duplicated verbatim between email-OTP and password-reset-OTP
verification — was extracted into one shared `matchOtpCandidate` helper.

## Rate-Limit Matrix (durable, Firestore-backed `applyRateLimit`)

| Flow | Limiter keys | Limit | Window | Block | Extra controls |
| --- | --- | --- | --- | --- | --- |
| Password login | `login:ip:<ip>`, `login:id:<idHash>` | 8 | 10 min | 20 min | dummy-hash constant-time verify; generic `Invalid credentials.` |
| OTP request (login/verify/forgot) | `otp:req:ip:<ip>`, `otp:req:id:<idHash>` | 10 | 10 min | 20 min | 30 s resend cooldown |
| OTP verify | `otp:verify:ip:<ip>`, `otp:verify:id:<idHash>` | 10 | 10 min | 20 min | per-OTP `failedAttempts` cap 5 → 15 min lock; timing-safe compare |
| Password-reset request | `otp:req:*` | 10 | 10 min | 20 min | constant response on every branch |
| Password-reset verify | `otp:verify:*` | 10 | 10 min | 20 min | per-OTP lockout via `matchOtpCandidate` |
| REST auth (`/v1/auth/otp/send|verify`) | Express `rateLimitAuth` | 20 | 10 min | — | in-memory per-instance (best-effort; see `API-002`) |

Constants live together at the top of `index.ts`
(`LOGIN_ATTEMPT_*`, `OTP_REQUEST_*`, `OTP_VERIFY_*`, `OTP_VERIFY_MAX_ATTEMPTS=5`,
`OTP_VERIFY_LOCK_MS=15m`, `OTP_RESEND_COOLDOWN_MS=30s`).

## Brute-Force / OTP Defenses

- **Login** rate-limits by **both** client IP and identifier hash before any
  lookup, then runs bcrypt verify against the real hash **or a dummy hash** so a
  non-existent user costs the same time (no timing oracle) and returns the same
  generic error.
- **OTP verify** bounds brute force two ways: a per-identifier/IP request-rate
  limit **and** a per-code `failedAttempts` counter that locks the specific OTP
  after 5 wrong guesses (a 6-digit code can't be ground down). Comparison is
  `timingSafeEqualHex` over salted+secret OTP hashes; codes are single-use
  (`usedAt`) and expiring (`expiresAt`).

## Enumeration / Messaging Safety

| Path | User-facing result | Leaks existence? |
| --- | --- | --- |
| Login (any failure) | `Invalid credentials.` | No — identical for unknown user / no password / wrong password |
| Password-reset request | constant `FORGOT_PASSWORD_RESPONSE` | No — same response for invalid email, rate-limited, cooldown, unknown user, unverified email, no-password |
| OTP verify (any failure) | `Invalid or expired code.` | No |
| Sign-up with existing email | `That email is already in use.` | **Yes — by design** (standard signup UX; mitigated by OTP/signup rate limiting). Documented as an accepted tradeoff. |

## Audit Logging

`logAuthAudit` records `action`, `status` (`ok`/`invalid`/`blocked`/`error`),
**hashed** identifier (`hashIdentifier`), uid, ip, user-agent, and metadata
(e.g. `cooldown`, `skippedSend`, `purpose`). No plaintext email/username or
credential material is logged. Blocked attempts are logged before the
rate-limit error is thrown.

## Refactor (this change)

The OTP candidate-matching loop (skip used/expired/locked → constant-time hash
compare → record failed attempt → lock after `OTP_VERIFY_MAX_ATTEMPTS`) was
byte-for-byte identical in `verifyEmailOtp` and `verifyPasswordResetOtpCore`.
Extracted into `matchOtpCandidate(candidates, otp)`; both verifiers now delegate
to it, so the timing-safe matching and lockout behavior cannot drift between the
two paths. Behavior is unchanged (verified by the abuse + callable suites).

## Verification

- `npm run build` (in `functions/`) + `npm run lint` — clean
- `npx mocha --exit test/securityAbuseLanes.test.js` (7 passing — OTP send/verify
  throttles, report/block abuse lanes)
- `npx mocha --exit test/callables.test.js` (11 passing)
- Full-suite delta: `npm test` is **127 passing / 50 failing with and without
  this change** (the 50 are pre-existing cross-file `admin`-mock contamination);
  the refactor adds zero new failures.

## Tracked / Non-Blocking

1. Sign-up email-existence disclosure is an accepted, rate-limited UX tradeoff;
   revisit only if strict anti-enumeration signup is required.
2. The REST `rateLimitAuth` limiter is per-instance/in-memory — the durable
   callable limiter is the authoritative control (shared follow-up with
   `API-002`/`SEC-BE`).

## Manual Follow-Up

- Live abuse smoke test before submission: confirm lockouts/backoff trigger on
  repeated bad login/OTP attempts and that reset emails reveal nothing about
  account existence.
