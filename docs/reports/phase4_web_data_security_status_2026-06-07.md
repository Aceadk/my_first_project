# Phase 4 — Web Data Reconciliation & Entitlement Security: Status

- Date: 2026-06-07
- Scope: re-audit Phase 4 (Steps 6 + 7) — reconcile web data services and secure
  device trust / entitlements.
- Branches: my_first_project `codex/publish-auth-startup-hardening`, crush-web
  `codex/auth-storage-cleanup`.

## Step 7 "Done when" — MET

> A modified client cannot self-grant trust, premium benefits, promos, or boosts.

| Vector | Enforcement | Evidence |
|--------|-------------|----------|
| Premium | `plan`, `subscriptionExpiresAt`, `subscriptionLifecycle`, `subscriptionTier`, `isPremium`, `premiumPlan` rejected on client writes (firestore.rules) | rules-emulator abuse tests |
| Boost | `boost` field rejected on client writes; activation via server-owned `activateBoost` callable (Plus + 30-day cooldown server-side) | rules-emulator + callable test |
| Promos | `promoCodes`/`promoCodeRedemptions` deny-by-default; validate/redeem via server-owned callables (free-access grants premium via admin only) | rules-emulator + callable tests |
| Trust | Decision: device trust is **UX-only**, confers no privilege (see `docs/contracts/device_trust_decision_2026-06-07.md`) | decision doc |

## Step 6 — reconcile every web data service

| Item | Status |
|------|--------|
| Notification tokens (`users/{uid}/fcmTokens`) | ✅ owner-scoped rule (both clients use it) |
| Blocked users (`users/{uid}/blocked`) | ✅ → top-level `blocks` + `blockUser`/`unblockUser`/`getBlockedUsers` callables |
| Reports | ✅ → `reportUser` callable (canonical shape) |
| User/profile writes (legacy flat) | ✅ → canonical `profile.*` only (Step 5) |
| Promo validation/redemption | ✅ → `validatePromoCode`/`redeemPromoCode` callables |
| Boost activation/cooldown | ✅ → `activateBoost` callable + rules lock |
| Stories (`users/{uid}/stories`) | ⏳ **pending migration** to top-level `stories/{storyId}` + a `views` subcollection rule. Sizable model + feed-query change; not a self-grant risk. |
| `user_streaks` | ⏳ **blocked on product decision** (below) |
| Remove direct match/swipe mutations + delete obsolete services | ⏳ **blocked on V2 production cutover** (needs staging) |

## Decisions still required (owner input)

1. **Streak → like-limit semantics.** The backend authoritatively enforces a
   FLAT daily like limit in `rateLimits/{uid}` (`enforceDailyLikeLimit`),
   independent of any streak bonus. The web streak model advertises a streak
   bonus (up to 69 likes). To make streaks real + server-owned, the backend
   limit logic must incorporate the streak bonus — a product decision. Until
   then `user_streaks` stays deny-by-default (web streak features inert, no
   self-grant risk). **Do NOT build a parallel streak limit without this call.**

2. **Stories model.** Migrate `users/{uid}/stories` (+ `views` subcollection) to
   the canonical top-level `stories/{storyId}`. Needs a `views` subcollection
   rule (viewer creates own receipt; owner reads) and a feed-query rewrite
   (`collectionGroup`/`where userId in …`). Mechanical but sizable; best done
   with the ability to run the web app to verify the stories feed.

3. **V2 chat/match production cutover.** Removing the legacy match/message/swipe
   services and the `NEXT_PUBLIC_USE_V2_CHAT` flag requires running the Phase 1.5
   migration on staging, enabling V2, and validating E2E — needs a staging
   service account. Until then the legacy services remain (their direct
   match/swipe writes are already deny-by-default, so they are inert, not a
   security hole).

## Verification (local)

- `functions/`: build + lint clean; `callables.test.js` 18 passing (incl. auth
  tests for activateBoost / validatePromoCode / redeemPromoCode / getBlockedUsers
  / setMatchPinned).
- `firestore-tests/`: rules-emulator 77 passing (incl. self-grant abuse tests for
  boost/premium/promos and fcmTokens owner-scoping).
- `crush-web`: lint + typecheck + build clean; vitest 198 passing.
