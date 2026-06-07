# Device Trust — Security Decision (2026-06-07)

Phase 4 Step 7 requires deciding whether web "device trust" is **security
enforcement** or **UX-only**, then either backing it with a verified backend
challenge (if security) or treating it as convenience (if UX).

## Decision: Device trust is UX-only convenience — NOT a security boundary

The web `deviceSecurityService` remembers devices (`users/{uid}/security.
trustedDevices`) so returning users on a known device get a smoother sign-in UX.
It is **not** an authorization input and grants **no** privileges.

### Rationale

- The actual session/security boundary is **Firebase Auth** (verified
  credentials, ID tokens, App Check attestation) plus the Next.js HttpOnly
  session cookie + middleware route protection. None of these consult
  `trustedDevices`.
- Implementing real device verification (server-issued challenge, verified
  second factor, audited, server-owned records) is a large effort with no
  current product requirement; treating the existing list as a security gate
  would be security theatre.

### Consequences / rules

- `security.trustedDevices` stays under the owner-writable user document. Because
  it grants nothing, a client editing it cannot escalate privilege — so the
  Step 7 "cannot self-grant trust" bar is met by the **decision** (trust confers
  no privilege), not by locking the field.
- **No authorization logic may key off `trustedDevices`.** If a future feature
  needs real device trust as a security control, it must be re-scoped: move to a
  server-issued challenge + server-owned `trustedDevices` records (admin-written)
  and add it to the protected-fields list in `firestore.rules`, with replay /
  forged-state / self-grant tests.
- The genuinely entitlement-bearing fields ARE locked in `firestore.rules`
  (client writes rejected; server-owned): `plan`, `isIdVerified`, `stripe*`,
  `isEmailVerified`, `createdAt`, `kycVerificationStatus`, `boost`,
  `subscriptionExpiresAt`, `subscriptionLifecycle`, `subscriptionTier`,
  `isPremium`, `premiumPlan`, `safetyFlags`. Boost activation and block/report
  go through backend callables. `promoCodes`/`promoCodeRedemptions`/`user_streaks`
  are deny-by-default (no client rule).

## "Done when" status (Step 7)

A modified client cannot self-grant:
- **premium** — `plan`/entitlement fields are rules-protected (tested).
- **boosts** — `boost` is rules-protected; activation is a server-owned callable
  enforcing Plus + cooldown (tested).
- **promos** — `promoCodes`/`promoCodeRedemptions` are deny-by-default (tested).
- **trust** — confers no privilege by decision (UX-only).

## Follow-ups (not blocking)

- Move promo validation/redemption and streak updates to backend commands so the
  features actually function (currently deny-by-default → the direct client
  paths are inert). Tracked in `firestore-tests/README.md`.
- Audit events for entitlement/security mutations are emitted server-side by the
  callables (block/report/appeal already log; boost activation writes are
  admin-only). A dedicated audit-event review is a separate hardening task.
