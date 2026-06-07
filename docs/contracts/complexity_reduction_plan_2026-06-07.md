# Complexity Reduction Plan (Phase 9 Step 21)

- Date: 2026-06-07
- Scope: reduce high-risk complexity across the Cloud Functions backend, the web
  app, and the mobile app — **safely and incrementally**, with the build/lint/
  test suites as guardrails on every step (no behavior change without a green
  gate). This phase ships the first verified slices + the blueprint for the rest.

## Principle: behavior-preserving, verified, incremental
A 14k-line production backend and 1k+-line UI files cannot be safely torn apart
in one pass when the backend deploys to production only and integration tests
need an emulator. Every extraction must keep the deployed surface identical
(Firebase deploys by export name) and pass `tsc` + lint + the test suite before
merge. Big-bang rewrites are explicitly rejected.

## Backend: `functions/src/index.ts` (14,205 → domain modules)

Already extracted: `shared/callable.ts` (111), `calls/signaling.ts` (721),
**`shared/media_limits.ts` (this phase — pure media/MIME tables, verified: build
+ lint clean, tests 146 passing / 59 pre-existing failing unchanged).**

Target domain modules (each = the `export const X = callable(...)` /
`app.<verb>(...)` handlers + their private helpers, re-exported from index.ts so
the deploy surface is byte-identical):

| Module | Contents | Approx callables/routes |
|---|---|---|
| `auth/` | OTP, username, password, token refresh/logout | requestEmailOtp, verifyEmailOtp, claimUsername, signUpWithPassword, loginWithPassword, requestPasswordReset…, `/v1/auth/*` |
| `profile/` | profile CRUD + validation + photos | `/v1/profile/*`, `validateProfilePatchPayload`, photo helpers |
| `discovery/` | deck, swipes, boost | fetchDiscoveryCandidates, swipeRight/Left, `/v1/discovery/*`, candidate filtering |
| `chat/` | messages, reactions, typing, media, settings | sendMessage, editMessage, unsendMessage, markMessagesRead, addReaction, setTyping, `/v1/chat/*`, getChatMediaSignedUrl |
| `matches/` | match list, unmatch, pin | unmatch, setMatchPinned, `/v1/matches/*` |
| `subscription/` | checkout, verification, webhooks, sync | createCheckoutSession, verifyApple/Purchase, syncSubscriptionStatus, stripe/apple/google webhooks |
| `safety/` | block, report, appeal, moderation | blockUser, unblockUser, getBlockedUsers, reportUser, appealSafetyAction, moderate* |
| `engagement/` | boost, promo, streak | activateBoost, validate/redeemPromoCode, getStreakStatus, recordStreakActivity |
| `account/` | deletion, export | requestAccountDeletion, cancelAccountDeletion, requestDataExport |
| `notifications/` | category gating, token cleanup | isNotificationCategoryAllowed, send helpers |
| `shared/` | constants, validators, admin init, types | media_limits (done), validation primitives, requireObjectRecord, etc. |

Extraction order (lowest-risk first): shared constants/validators → safety →
engagement → account → profile → chat → discovery → subscription → auth. Keep
`index.ts` as the thin export aggregator. Run `npm test` after each module;
require **no new failures vs the 59-failure baseline** (see release-gate report).

## Web: decompose large files

Largest files (lines): `messages/[matchId]/chat-room.tsx` (1578),
`onboarding/onboarding-flow.tsx` (1157), `profile/edit/profile-edit-form.tsx`
(819→), `discover/page.tsx` (744), `settings/settings-view.tsx` (734),
`settings/discovery/page.tsx` (730), `settings/account/page.tsx` (718).

Shipped this phase (verified, behavior-neutral): extracted static tables + form
types out of `profile-edit-form.tsx` → `profile-edit-constants.ts` (lint +
typecheck clean, 256 tests pass).

Decomposition pattern per file:
1. Extract pure helpers / constants / types / Zod schemas into colocated modules
   (zero behavior risk; tsc-verified). ← start here.
2. Extract self-contained presentational subcomponents (props-only).
3. Extract stateful logic into custom hooks (`useChatRoom`, `useOnboardingFlow`)
   so the page becomes orchestration only.
4. Add/keep tests around extracted logic.

Targets: chat-room → `useChatRoom` hook + `MessageList`/`Composer`/`CallBar`
subcomponents; onboarding → per-step components + `useOnboardingFlow`; discover →
`useDiscoveryDeck` + `DeckCard`; settings pages → shared `SettingRow`/`ToggleRow`
+ per-section components.

## Mobile: incremental refactors + wiring

### Matching analytics — ALREADY WIRED (verified)
`discovery_bloc` emits `AnalyticsService.instance.log{DeckLoaded,DeckEmpty,
SwipeRight,SwipeLeft,SuperLike,Match}`; `MatchQualityAnalytics` shapes the
events. No action needed beyond confirming the deck-depletion rejection-cause
breakdown (`candidate_filter_pipeline` → analytics) reaches the production sink
during device validation.

### Offline chat queue — design (NOT shipped this phase; requires device validation)
`lib/core/cache/offline_queue.dart` (`OfflineActionQueue`) is complete and
unit-tested (`test/core/cache/offline_queue_test.dart`, 9 tests, green: idempotent
dedupe, FIFO `processAll`, persistence, dead-letter, capacity eviction). It is
**not** wired into the chat send flow.

**Why not auto-wired now:** `message_handling_bloc.dart` already has an
optimistic-message + `failedMessages` + manual-retry mechanism. Adding the queue
as a parallel auto-retry risks **double-sends / state divergence**, and the
correct behavior (offline send → reconnect → exactly-once, no dupes) can only be
validated on a device/with widget tests — not in this environment. Shipping it
unverified would regress production chat.

**Wiring design (turn-key for the device-validation pass):**
1. Register a handler: `queue.registerHandler('send_message', (a) => repo.sendMessage(...))`.
2. On send, instead of (or in addition to) the current optimistic path, enqueue
   `PendingAction(type:'send_message', dedupeKey:'send:<matchId>:<clientId>', payload)`.
   The `clientId` (existing temp id) is the idempotency key — reuse it as the
   server-side message id so a retried send is a no-op (matches the chat cutover
   acceptance: "offline send → reconnect → no duplicate messages").
3. Unify with `failedMessages`: a queued action's state drives the optimistic
   bubble (sending → sent/failed); remove the separate manual-retry path so there
   is ONE source of truth.
4. Call `queue.processAll()` on connectivity-restored (existing
   `realtime_state_cubit`/connectivity signal) and on app resume.
5. Verify: extend the chat bloc tests with an offline→reconnect exactly-once case;
   then device-validate (part of the Step 20/Step 22 device matrix).

### Other incremental mobile refactors (ongoing)
auth/chat/discovery/profile/settings blocs → continue extracting use-cases and
splitting large blocs; covered by the existing `flutter analyze` + `flutter test`
gates.

## Done-when status (Step 21)
- ✅ Backend domain-split started (media_limits extracted, verified) + full
  blueprint with risk-ordered sequence.
- ✅ Web decomposition started (profile-edit constants/types extracted, verified)
  + per-file blueprint.
- ✅ Mobile: matching analytics confirmed wired; offline-queue wiring fully
  designed (deferred to device-validation pass with rationale — not shipped
  unverified).
- ⏳ Remaining extractions are incremental follow-ups, each gated green.
