# Canonical Entitlement Model (Phase 7 Step 13)

- Date: 2026-06-07
- Sources: `functions/src/index.ts` (setUserPlan, purchase validation, stripe/
  google/apple webhooks, redeemPromoCode); web
  `packages/core/src/services/entitlement.ts`; `firestore.rules`.

## Canonical persisted fields (on `users/{uid}`)

| Field | Type | Meaning |
|---|---|---|
| `plan` | `'free' \| 'plus'` | **THE entitlement flag.** Source of truth for premium. Firestore rules gate premium features on `plan == 'plus'`. |
| `subscriptionExpiresAt` | Timestamp | When the current entitlement period ends (omitted/deleted for free). |
| `subscriptionLifecycle` | map | `{ provider, status, currentPeriodEnd, cancelAtPeriodEnd, lastValidatedAt }` |
| `stripeCustomerId` / `stripeSubscriptionId` | string | Stripe linkage (backend-only) |
| `applePurchase` / `googlePlayPurchase` | map | Provider receipt records (backend-only) |
| `premiumSource` / `premiumPromoCode` | string | Set for promo-granted premium |

`provider` ∈ `stripe | app_store | google_play | promo`.

**All of these are client-WRITE-protected** by `firestore.rules` (only backend/
admin writes them). Legacy mirrors (`isPremium`, `subscriptionTier`,
`premiumPlan`, `premiumExpiresAt`) are **derived/read-only** and also protected.

## Derivation (read side)

Both clients derive entitlement from `plan` via the shared resolver
(`entitlement.ts` on web; the schema canonicalizer on mobile):

- `isPremium` = `plan === 'plus'`
- `tier` = `plan` (web preserves a display-only `platinum`)
- `expiresAt` = `subscriptionExpiresAt` → `premiumExpiresAt` → `lifecycle.currentPeriodEnd`
- precedence: canonical `plan` ALWAYS wins over stale legacy flags.

## Write paths — all backend-owned commands

| Source | Backend command | Effect |
|---|---|---|
| Stripe checkout/webhook | web `/api/stripe/webhook` (admin) + backend `stripeWebhook` | writes `plan` + `subscriptionExpiresAt` + `subscriptionLifecycle{provider:'stripe'}` |
| Apple IAP | `verifyAppleTransaction` / `appleSubscriptionWebhook` | `setUserPlan` + `subscriptionLifecycle{provider:'app_store'}` |
| Google Play | `verifyGooglePurchaseToken` / `googleRtdnWebhook` | `setUserPlan` + `subscriptionLifecycle{provider:'google_play'}` |
| Promo (free-access) | `redeemPromoCode` callable | `setUserPlan('plus')` + `subscriptionLifecycle{provider:'promo'}` |
| Sync | `syncSubscriptionStatus` callable | re-derives entitlement from the active provider |

No client writes entitlement directly (rules-enforced; abuse-tested in the
rules emulator: cannot self-grant plan/subscription*/isPremium/premiumPlan).

## State reconciliation

| State | Resolution |
|---|---|
| Active | `plan='plus'`, `subscriptionExpiresAt` future, `status='active'` |
| Renewal | provider webhook bumps `subscriptionExpiresAt`/`currentPeriodEnd` |
| Cancellation (at period end) | `cancelAtPeriodEnd=true`; stays `plus` until expiry |
| Expiration | webhook/sync sets `plan='free'`, clears `subscriptionExpiresAt` |
| Restoration (re-purchase) | provider validation re-grants `plan='plus'` |
| Promo over paid | promo grants `plus` with `provider:'promo'`; paid webhook later reconciles provider |
| Conflicting legacy flags | ignored — `plan` is authoritative (resolver precedence) |

## Done-when status (Step 13)

- ✅ One canonical model defined (this doc); `plan` is the single source of truth.
- ✅ Final entitlement writes routed through backend commands (Stripe/Apple/Google
  webhooks + verify callables + promo callable + syncSubscriptionStatus).
- ✅ Client cannot write entitlement (rules + abuse tests).
- ⏳ **Provider webhook + reconciliation tests** beyond the existing
  receipt-validation tests (appleReceiptValidation, googlePlayPurchaseValidation,
  appleS2sLifecycle, googleRtdnLifecycle, purchaseReceiptValidation) — add
  cross-provider reconciliation cases (e.g. promo→paid handoff, expiry race).
  Many require the emulator/provider sandboxes (operational).
