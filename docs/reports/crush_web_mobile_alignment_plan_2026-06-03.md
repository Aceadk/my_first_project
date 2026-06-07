# Crush Web and Mobile Alignment Plan

> Historical baseline. For the current completion and gap assessment, see
> `docs/reports/crush_web_mobile_alignment_reaudit_2026-06-06.md`.

- Date: 2026-06-03
- Repositories compared:
  - `/Users/ace/my_first_project` — Flutter mobile/iPad/web shell plus Firebase backend/functions.
  - `/Users/ace/crush-web` — Next.js web app and marketing monorepo.
- Scope: Planning and audit only. No application code was changed in either repo.

## Method

- Built complete non-ignored file inventories with `git ls-files --cached --others --exclude-standard`.
- Inventory counts:
  - `my_first_project`: 2,868 files.
  - `crush-web`: 253 files.
- Checked current dirty state:
  - `crush-web` is clean.
  - `my_first_project` has active local changes, including the logo replacement work plus other chat/backend/docs changes already in progress.
- Compared high-impact surfaces after inventory:
  - Firebase config, env/domain values, hosting config, CI config.
  - Mobile routes, web routes, redirects, notification/deep-link mappings.
  - Cloud Functions REST/callable exports and web service usage.
  - Firestore/storage rules, indexes, and client collection paths.
  - User/profile schema canonicalization.
  - Discovery, matching, chat, notifications, safety, subscription, calls, branding, testing, and docs.

## Executive Summary

The two repos are feature-related, but they are not yet aligned as one production system. The biggest gap is not UI parity; it is contract drift. `my_first_project` has the current backend, Firestore rules, API endpoints, mobile repositories, and canonical nested user profile schema. `crush-web` implements many app features, but several web services still write directly to Firestore using older or separate collection shapes.

The safest direction is to treat `my_first_project/functions` plus the mobile DTO/schema tests as the backend source of truth, then move the web app onto the same REST/callable contracts and shared schema tests. Only after that should UI/branding parity be finished.

## P0 Findings

### 1. Backend Contract Drift

Mobile/backend has a centralized REST surface under `/v1/...` and many Cloud Function callables:

- REST examples: `/v1/discovery/deck`, `/v1/discovery/swipe`, `/v1/chat/:conversationId/messages`, `/v1/chat/:conversationId/send`, `/v1/profile/me`, `/v1/subscription/current`.
- Callable examples used by mobile: `fetchDiscoveryCandidates`, `swipeRight`, `swipeLeft`, `sendMessage`, `markMessagesRead`, `editMessage`, `unsendMessage`, `blockUser`, `unblockUser`, `reportUser`, `createCheckoutSession`, `syncSubscriptionStatus`, `verifyPurchaseReceipt`, `initiateCall`, `requestDataExport`.

`crush-web` currently calls Cloud Functions only for `requestAccountDeletion` and `cancelAccountDeletion`; most app behavior goes through direct Firebase SDK services.

Plan:
- Make Cloud Functions/REST the shared mutation boundary for web and mobile.
- Keep direct web reads only where Firestore rules explicitly allow the current schema.
- Add contract tests that compare web service DTOs to `ApiEndpoints`, callables, and Firestore schema expectations.

### 2. Firestore Schema Mismatch

Current rules in `my_first_project/firestore.rules` expect the canonical backend/mobile shape:

- Matches use top-level `matches/{matchId}` with participant `userIds`, `status == 'active'`, and messages in `matches/{matchId}/messages`.
- Match create/update/delete is backend-managed.
- Chat message retention uses fields such as `visibleTo`, `isRead`, and `readAt`.

`crush-web` direct services use different or additional shapes:

- `packages/core/src/services/message.ts` uses top-level `conversations/{conversationId}/messages` and top-level `typing_indicators`.
- `packages/core/src/services/match.ts` creates directional match docs with `userId`, `otherUserId`, `status: 'mutual'`, and direct `swipes`.
- Web stories use `users/{uid}/stories`, while mobile rules include top-level `/stories/{storyId}` and storage `/users/{uid}/stories/{storyId}`.
- Web uses `user_streaks`, `promoCodes`, and `promoCodeRedemptions` directly; current local Firestore rules do not expose those as safe client-write surfaces.

Plan:
- Pick one canonical chat/match model. Recommended: use the backend/mobile model, `matches/{matchId}/messages`, and backend-created matches.
- Replace web direct match/message mutations with backend REST/callables.
- Either remove web-only `conversations` and `typing_indicators`, or write a migration with rules/indexes/tests before allowing them.
- Add Firestore emulator tests for all web queries after migration.

### 3. User/Profile Schema Is Partially Bridged, Not Fully Unified

Mobile has `lib/core/schema/user_document_schema.dart`, which canonicalizes nested `profile.*` fields and handles legacy flat fields. Web has `packages/core/src/services/user_document.ts`, which writes nested `profile` fields but also keeps flat mirrors such as `displayName`, `photos`, `settings`, `interestedIn`, `notificationPrefs`, and `subscriptionTier`.

Plan:
- Define a single user document contract with:
  - Canonical persisted fields.
  - Allowed legacy read-only fields.
  - Mirror fields that are still intentionally maintained.
  - Retirement dates for legacy fallback fields.
- Add equivalent Dart and TypeScript fixtures for user profile create/update/read mapping.
- Keep web and mobile mappers green against the same fixtures.

### 4. Route and Deep-Link Naming Drift

Mobile routes include `/chat/:matchId`, `/message-requests`, `/likes-you`, `/paywall`, `/profile-insights`, `/privacy-policy`, `/terms-of-service`, `/notifications`, and several call/settings routes.

Web routes include `/messages/:matchId`, `/messages/requests`, `/likes`, `/premium`, `/insights`, `/privacy`, `/terms`, plus marketing pages. Web redirects already map `/chat` to `/messages` and `/likes-you` to `/likes`, but route naming is not centralized across mobile, web, notifications, and links.

Plan:
- Create a shared route/deep-link matrix covering:
  - Mobile route.
  - Web route.
  - Public URL.
  - Notification target route.
  - Redirect/backward-compatible aliases.
- Make notification route mapping use this matrix on both clients.
- Keep aliases for existing links, but document one canonical public path per feature.

### 5. Environment and Domain Drift

The repos reference multiple domains and names:

- Firebase project: `crush-265f7`.
- Firebase hosting site: `crushapp`.
- Domains in code/docs/config: `crush.app`, `crushhour.app`, `app.crush.dating`, and `crushapp.com`.
- Backend CORS defaults include `crushhour.app`, while web metadata defaults to `https://crush.app`.

Plan:
- Create one env/domain matrix for dev, staging, and production.
- Update CORS, Stripe success/cancel URLs, metadata, notification allowed hosts, Firebase hosting, Vercel envs, and public legal/support emails to match that matrix.
- Add a script that fails CI if deprecated domains reappear outside approved redirects/legal history.

## P1 Findings

### 6. Auth and Session Flow Differences

Mobile uses AuthBloc/session services, Firebase Auth, OTP callables, account lifecycle commands, and mobile-specific verification flows. Web uses Firebase client SDK plus a Next.js HttpOnly session cookie, middleware protection, and device-trust state.

Plan:
- Align auth methods supported per platform: email/password, email link, phone OTP, Google, Apple, device verification, account deletion/cancel deletion.
- Decide whether web OTP/password flows should call the backend callables or remain Firebase client SDK flows.
- Add shared auth error codes and redirect rules.
- Add E2E coverage for onboarding redirect, session timeout, account deletion grace period, and cancelled deletion.

### 7. Subscription and Entitlement Drift

Mobile includes native purchase validation paths and callable validation. Web includes Stripe Next API routes and a Stripe webhook. Field names overlap but differ across `plan`, `subscriptionTier`, `billingPeriod`, legacy `isPremium`, and promo fields.

Plan:
- Define one entitlement document model.
- Update web and mobile to read the same derived entitlement fields.
- Keep web Stripe and mobile IAP providers, but write final entitlement through one backend function.
- Add tests for plan changes, cancelled subscriptions, expired entitlements, promos, and restored purchases.

### 8. Notifications Need Route and Preference Parity

Both clients use `users/{uid}/fcmTokens`; web uses FCM web/VAPID and mobile uses native push. Preference keys overlap but are not fully centralized.

Plan:
- Create one `notificationPrefs` schema with platform-specific token metadata.
- Align notification categories: calls, messages, matches, likes, subscriptions, safety alerts, promos.
- Use the shared route matrix for payload `targetRoute`.
- Add web push setup docs and VAPID env validation to CI/health checks.

### 9. Branding and Design Are Not Fully Aligned

`my_first_project` now has generated PNG app/PWA icons, launcher assets, and splash artwork from the new logo. `crush-web` still uses SVG-generated favicon/OG/icon routes and a separate Tailwind visual system.

Plan:
- Copy or generate web assets from the same source logo set:
  - favicon
  - PWA icons
  - Apple touch icon
  - OG/Twitter images
  - manifest theme/background colors
- Decide whether web should adopt the mobile token export in `docs/design_tokens.json`, or whether the current web Tailwind system is intentionally distinct.
- At minimum align brand colors, dark background `#0D0E12`, logo mark, app name metadata, and social preview.

### 10. Testing and CI Are Uneven

`my_first_project` CI runs docs sync, Flutter analyze/tests, functions lint/tests, security lanes, and Firestore rules checks.

`crush-web` CI currently runs lint and unit tests. It does not run build, typecheck, Playwright E2E, docs sync, or backend contract checks.

Plan:
- Add web CI lanes:
  - `pnpm typecheck`
  - `pnpm build`
  - `pnpm test`
  - Playwright smoke and authenticated app flow
  - contract/schema tests against shared fixtures
  - docs sync guard or equivalent task logging rule
- Add cross-repo verification for discovery -> match -> chat and account lifecycle.

## P2 Findings

### 11. Feature Parity Gaps

Web has many app routes, but not everything mobile supports is fully aligned:

- Calls/RTC: mobile has signaling, call screens, CallKit/PiP paths; web has no full WebRTC calling flow yet.
- I18N: mobile has many ARB locales; web is mostly English.
- Profile richness: mobile has broader profile editing fields and media handling.
- Account/security/settings: mobile has more settings subroutes and device/security affordances.
- Social/analytics features need shared backend contracts before final UI parity.

Plan:
- After P0/P1 contract work, implement remaining web parity by module:
  - Calls/RTC.
  - I18N.
  - Profile fields/media.
  - Settings/security/account actions.
  - Social and insights.

### 12. Documentation and Workflow Drift

`my_first_project` has the current AGENTS workflow and required docs sync guard. `crush-web` still contains older workflow docs: `docs/ai_change_log.md`, `docs/ai_tasks_board.md`, and a stale/incomplete `docs/Developer_agent_chat.md`.

Plan:
- Add a web repo `AGENTS.md` or explicitly point it to the main workflow.
- Replace old web tracking docs with the current task-log/workboard pattern, or document that all cross-repo work is tracked in `my_first_project/docs`.
- Keep one source of truth for web parity status; do not maintain duplicate checklists.

### 13. Repo Hygiene

`my_first_project` has tracked generated/dependency files:

- `crushhour-recommendation-service/node_modules` has 1,449 tracked files.
- `functions/build` has tracked build artifacts.

Plan:
- Clean this in a separate, explicit task because it changes many files.
- Remove tracked dependency/build artifacts with `git rm --cached`.
- Keep source files and lockfiles only.
- Add/verify ignore rules and CI guard for generated artifacts.

## Recommended Work Sequence

### Phase 0 — Stabilize The Alignment Process

1. Confirm canonical production domain and Firebase project matrix.
2. Create the route/deep-link matrix.
3. Create the backend contract matrix: REST endpoints, callables, Firestore collections, Storage paths.
4. Add web docs workflow alignment.
5. Plan the repo hygiene cleanup separately.

Exit criteria:
- One written matrix for domains, routes, and backend contracts.
- Web and mobile teams know which backend model is canonical.

### Phase 1 — Fix P0 Backend/Data Drift

1. Move web discovery/match/chat mutations from direct Firestore to backend REST/callables.
2. Align web chat with `matches/{matchId}/messages`, or formally migrate/allow `conversations`.
3. Align match status and participant fields.
4. Align story, streak, promo, report/block, and notification preference write paths.
5. Add Firestore emulator tests and web contract tests.

Exit criteria:
- Web app behavior works under the same Firestore rules deployed for mobile/backend.
- Discovery, match creation, messages, read state, typing/presence, report/block, and message requests pass authenticated E2E.

### Phase 2 — Align Auth, Subscription, Notifications

1. Decide web auth callables versus Firebase client SDK for each auth flow.
2. Unify account deletion, deactivation, data export, and device verification handling.
3. Unify entitlement fields and payment providers.
4. Align notification preferences, FCM token docs, and route targets.

Exit criteria:
- Account lifecycle and subscription state are consistent across mobile and web.
- Web push and mobile push route users to equivalent destinations.

### Phase 3 — Align UI, Branding, Responsive UX

1. Apply the new logo assets to `crush-web`.
2. Align manifest, favicon, Apple icon, OG/Twitter image, theme color, and metadata.
3. Decide token parity: import mobile tokens or document intentional web token differences.
4. Verify responsive web layouts against mobile/iPad expectations.
5. Add accessibility checks for keyboard, focus, screen reader labels, reduced motion, and contrast.

Exit criteria:
- Brand identity is consistent across native mobile, Flutter web shell, and Next.js web app.
- Core app flows look intentional on phone, tablet/iPad, desktop, and PWA install surfaces.

### Phase 4 — Complete Remaining Feature Parity

1. Calls/RTC web implementation.
2. I18N strategy for web.
3. Full profile field/media parity.
4. Social/date ideas/compatibility/insights parity.
5. Admin/moderation if still planned.

Exit criteria:
- Web parity is measured by the module TODOs, not by ad hoc page existence.

### Phase 5 — Release Readiness

1. Add web CI build/typecheck/E2E.
2. Add cross-repo contract checks.
3. Add staging smoke tests for web + mobile against the same backend.
4. Verify CORS, App Check, Stripe, Firebase Admin, Storage, Firestore indexes, and hosting.
5. Run manual core journey:
   - onboarding -> auth -> profile -> discovery -> match/chat -> notifications -> settings/account.

Exit criteria:
- Both repos can be changed safely without silent contract drift.

## Immediate Next Tasks

1. **P0 Contract Matrix:** Create `docs/reports/shared_backend_contract_matrix_2026-06-03.md` from current functions, rules, mobile endpoints, and web services.
2. **P0 Web Chat/Match Migration Plan:** Decide whether web will use backend `matches/{matchId}/messages` directly or keep `conversations` with a formal migration.
3. **P0 Domain/Env Matrix:** Pick canonical domains and update CORS, metadata, Stripe URLs, notification allowed hosts, and docs.
4. **P0 Web CI Upgrade:** Add build/typecheck/Playwright/contract checks to `crush-web`.
5. **P1 Web Branding Pass:** Replace `crush-web` favicon/PWA/OG/icon route outputs with the new logo asset pipeline.
6. **Repo Hygiene Task:** Remove tracked `crushhour-recommendation-service/node_modules` and `functions/build` artifacts from `my_first_project` in a dedicated cleanup.

## Verification For This Audit

- Local repo inventories were generated for both repositories.
- Key config/source/docs were inspected in both repositories.
- No app code was modified.
- Required workflow docs were updated in `my_first_project`.
