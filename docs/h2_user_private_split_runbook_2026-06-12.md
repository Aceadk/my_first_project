# H-2 — users/{uid} public/private split — Runbook (2026-06-12)

Closes the cross-user sensitive-field leak (SECURITY_AUDIT_2026-06.md H-2). Firestore
has no field-level read rules, so any viewer allowed to read a profile reads the whole
user doc — billing IDs, KYC, safety flags, entitlement, email/phone, exact geo. Fix =
move those to an owner-only `users/{uid}/private/account` doc.

**Decisions (2026-06-12):** staged rollout · move ALL sensitive fields private (only core
display + coarse location stays public) · public geo rounded to ~1km, precise geo private.

## Phase 1 — additive (shipped in this change; non-breaking)
Done:
- **Rules** (`firestore.rules` + `functions/firestore.rules`, in parity):
  - `users/{uid}/private/{docId}` → `read: isOwner(uid)`, `write: false` (backend-only).
  - `stripe_customers/{customerId}` → server-only (reverse lookup).
- **Backfill** `crush-web/apps/web/scripts/migrate-user-private-split.mjs` — copies sensitive
  fields + precise geo into `private/account` and builds the Stripe map. Deletes nothing.
- **Web Stripe webhook** (`apps/web/src/app/api/stripe/webhook/route.ts`) — now dual-writes
  billing/entitlement to `private/account` and maintains `stripe_customers`; `resolveUserId`
  prefers the map, falls back to the legacy field query.
- **Rules tests** (`firestore-tests/rules.test.mjs`) — non-owner/anon cannot read the private
  doc; owner cannot self-write it; `stripe_customers` is server-only.

Functions dual-write — DONE (centralized, additive):
- **`functions/src/index.ts`** now has `mirrorToPrivate(uid, fields)` (non-fatal helper) plus a
  single Firestore trigger **`mirrorUserPrivateFields`** (`users/{userId}`.onWrite) that mirrors
  the sensitive subset (`SENSITIVE_USER_FIELDS` + precise geo) into `users/{uid}/private/account`
  and maintains `stripe_customers/{id}` on every public-doc write — by ANY writer (web webhook,
  callables, client). Chosen over editing the 9+ scattered write sites; writing the subcollection
  does not re-trigger the parent handler. Must be `npm run build`-verified + deployed.

Remaining before cutover:
- **Flutter owner reads** (`lib/.../firebase_profile_repository.dart`, discovery): when the
  signed-in user needs their OWN billing/entitlement/precise geo, read `users/{uid}/private/account`.
  Other users' cards must stop expecting those fields (they'll be gone after cutover). Not changed
  here — needs device validation and is not required for the non-breaking Phase 1 (public doc still
  carries the fields until cutover).

### Phase 1 deploy
```bash
cd "Crush App"
firebase deploy --only firestore:rules --project crush-f5352
cd ../crush-web/apps/web
node scripts/migrate-user-private-split.mjs --project crush-f5352            # dry run
node scripts/migrate-user-private-split.mjs --project crush-f5352 --execute  # apply
```
After this, the private store exists, is protected, and stays fresh via dual-write — but the
public doc STILL contains the sensitive fields, so the leak is not yet closed.

## Phase 2 — cutover (closes the leak; do only after validation)
1. Confirm every reader uses the private doc (own billing/geo) and no client reads other
   users' sensitive fields.
2. Run the cutover migration (to be written): for each `users/{uid}` —
   - round public geo: `location.latitude/longitude` and `profile.latitude/longitude` → 2 dp (~1.1km);
   - `delete` the sensitive top-level fields (the `PRIVATE_SCALAR_FIELDS` list) from the public doc.
3. Tighten rules: extend the `users/{uid}` update guard so clients cannot re-introduce the
   sensitive keys on the public doc, and (optionally) assert geo precision ≤ 2 dp.
4. Deploy rules + functions + web together.

### Verification checklist
- `cd "Crush App/firestore-tests" && npm test` → private-doc + stripe_customers tests green.
- `cd crush-web && pnpm typecheck && pnpm lint` green.
- Manual: another user viewing a profile cannot see billing/KYC/safety/precise geo (inspect the
  network read); owner still sees own subscription state; a Stripe test webhook still resolves
  the user and updates entitlement; discovery distances still render (now ~1km-rounded).

## Field inventory (moved private)
`email, phoneNumber, stripeCustomerId, stripeSubscriptionId, kycVerificationStatus, safetyFlags,
subscriptionLifecycle, isIdVerified, isEmailVerified, emailVerified, plan, subscriptionTier,
isPremium, premiumPlan, subscriptionExpiresAt, premiumExpiresAt, premiumAutoRenew, billingPeriod,
boost` + precise geo (`location.*`, `profile.latitude/longitude`).
