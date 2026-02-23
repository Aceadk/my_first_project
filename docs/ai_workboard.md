# AI Workboard (Unified)

Single source of truth for AI planning, execution logs, and high-risk collaboration decisions.

Created on 2026-02-22 by consolidating the former multi-file AI tracking workflow.

## Update Rules

For every task, update this file once using one unified entry:
- Task metadata (ID, date, owner, status)
- Goal and scope
- Key changes (files/modules)
- Decisions/handoffs (only if relevant)
- Verification and next step

Keep only actionable and planning-relevant information. Avoid duplicate notes across multiple documents.

## Active Queue

| Task ID | Opened | Title | Status | Next Step |
| --- | --- | --- | --- | --- |
| T-2026-02-06-01 | 2026-02-06 | Post-Blaze Firebase setup | In Progress | Initialize Firebase Storage in console, then run `firebase deploy --only storage`. |
| T-2026-02-01-03 | 2026-02-01 | Integration test failures (l10n + auth UI) | In Progress | Re-run `flutter test integration_test/app_test.dart` with a longer timeout/device stability check. |

## Priority Context

1. R-055 ship blocker: Native in-app purchase is still missing (`docs/TODO_SUBSCRIPTION.md`).
2. Remaining onboarding analytics gap: abandonment tracking is not yet wired.
3. Maintain domain-first layering: presentation imports domain interfaces, not data implementations.

## Durable Decisions (For Future Agents)

- Clean architecture rule: new repositories/interfaces go under `domain/repositories`; presentation depends on domain abstractions.
- If a file imports `cloud_functions`, use `app_result.Result` aliasing for app Result type to avoid type collisions.
- Discovery tutorial persistence key is `has_seen_deck_tutorial` in SharedPreferences.
- Docs sync is enforced in CI; every task change set must include `docs/ai_workboard.md` and `docs/Developer_agent_chat.md`.
- Deprecated docs were removed: `docs/ai_change_log.md`, `docs/ai_tasks_board.md`, `docs/ai_collab_chat.md`.

## Recent Completed (Highlights)

| Task ID | Date | Summary | Verification |
| --- | --- | --- | --- |
| T-2026-02-20-CLEAN | 2026-02-20 | Tokenized chat inline styles and removed safe widget duplicates. | `flutter analyze` clean, tests at baseline. |
| T-2026-02-20-I18N-B | 2026-02-20 | Locale-aware date/time formatting + CJK typography fallback and line heights. | `flutter analyze` clean, tests adjusted and passing baseline. |
| T-2026-02-20-I18N | 2026-02-20 | I18N audit + device-language follow mode in settings. | `flutter analyze` clean. |
| T-2026-02-19-ONBOARD004 | 2026-02-19 | Onboarding analytics wired across 5 steps with completion duration. | `flutter analyze` clean. |
| T-2026-02-19-ONBOARD005 | 2026-02-19 | Deck tutorial overlay added with one-time persistence + a11y support. | `flutter analyze` clean. |

## Unified Task Log

### T-2026-02-22-DOCS-UNIFY
- Date: 2026-02-22
- Owner: Codex
- Status: Completed
- Goal: Merge AI task board, change log, and collaboration chat into one concise planning/execution document.
- Scope: Process/docs only (`docs/`, `AGENTS.md`), no app runtime code.
- Key Changes:
  - Created `docs/ai_workboard.md` as canonical workflow document.
  - Deprecated the former tracking files (`ai_change_log`, `ai_tasks_board`, `ai_collab_chat`) pending removal.
  - Updated `AGENTS.md` to use the unified process.
- Decisions/Handoffs:
  - Stop writing new entries to the deprecated tracking files; use `docs/ai_workboard.md` only.
- Verification:
  - `rg -n "ai_change_log\.md|ai_tasks_board\.md|ai_collab_chat\.md|ai_workboard\.md" AGENTS.md docs/risk_notes.md docs/Developer_agent_chat.md`
  - `git diff -- docs/ai_workboard.md AGENTS.md docs/risk_notes.md docs/Developer_agent_chat.md`
- Next Step: Use this file as the only AI planning + execution tracker going forward.

### T-2026-02-22-R035-CLOSE
- Date: 2026-02-22
- Owner: Codex
- Status: Completed
- Goal: Eliminate process drift risk (R-035) with enforceable automation instead of policy-only guidance.
- Scope: Repo workflow/process enforcement (`scripts/`, `.github/workflows/`, `docs/`, `AGENTS.md`).
- Key Changes:
  - Added `scripts/check_ai_docs_sync.sh` to enforce required workflow docs in every change set.
  - Added CI `docs_sync` job to run the guard on push and pull_request.
  - Updated `AGENTS.md` so the guard is mandatory in closeout.
  - Updated `docs/risk_notes.md` R-035 from `Mitigated` to `Closed`.
- Decisions/Handoffs:
  - Deprecated tracking docs must remain removed; guard checks reject reintroduction/modification.
- Verification:
  - `scripts/check_ai_docs_sync.sh --files scripts/check_ai_docs_sync.sh .github/workflows/ci.yml AGENTS.md docs/risk_notes.md docs/ai_workboard.md docs/Developer_agent_chat.md`
  - `bash -n scripts/check_ai_docs_sync.sh`
- Next Step: Keep the guard as a required quality gate for all future AI tasks.

### T-2026-02-22-DOCS-REMOVE
- Date: 2026-02-22
- Owner: Codex
- Status: Completed
- Goal: Remove deprecated AI tracking docs and keep one clean tracker (`docs/ai_workboard.md`).
- Scope: Documentation/process cleanup only.
- Key Changes:
  - Deleted `docs/ai_change_log.md`.
  - Deleted `docs/ai_tasks_board.md`.
  - Deleted `docs/ai_collab_chat.md`.
  - Updated guard/policy/docs to treat these as removed/deprecated.
- Decisions/Handoffs:
  - Historical references in old task notes are retained as history only; no new usage.
- Verification:
  - `ls docs/ai_change_log.md docs/ai_tasks_board.md docs/ai_collab_chat.md` (expected: not found)
  - `scripts/check_ai_docs_sync.sh --range HEAD`
- Next Step: Continue using `docs/ai_workboard.md` as the single source of AI planning/execution truth.

### T-2026-02-22-WEB-CI
- Date: 2026-02-22
- Owner: Codex
- Status: Completed
- Goal: Start execution of `docs/TODO_WEBAPP.md` with the first concrete item: GitHub Actions CI for web (lint + test).
- Scope: Web repo CI setup (`/Users/ace/crush-web`) and TODO document updates (`docs/TODO_WEBAPP.md`).
- Key Changes:
  - Added `/Users/ace/crush-web/.github/workflows/ci.yml` with separate `lint` and `test` jobs.
  - Marked GitHub Actions CI items complete in `docs/TODO_WEBAPP.md`.
  - Added change log line in `docs/TODO_WEBAPP.md` for 2026-02-22.
- Decisions/Handoffs:
  - CI uses `pnpm@8.15.0`, `node@20`, and runs `pnpm lint` + `pnpm test`.
  - Existing lint warnings are pre-existing baseline and do not block current CI job success.
- Verification:
  - `pnpm lint` (pass, warnings only) in `/Users/ace/crush-web`
  - `pnpm test` (pass: 40/40 tests) in `/Users/ace/crush-web`
- Next Step: Continue `docs/TODO_WEBAPP.md` with next highest-priority item (Google sign-in integration or Lighthouse audit).

### T-2026-02-22-WEB-AUTH-MSG
- Date: 2026-02-22
- Owner: Codex
- Status: Completed
- Goal: Continue `docs/TODO_WEBAPP.md` with concrete feature delivery: auth/session hardening and messaging UX parity.
- Scope: Web app implementation in `/Users/ace/crush-web` plus TODO/status docs in this repo.
- Key Changes:
  - Added remember-me aware session cookie policy in `/Users/ace/crush-web/apps/web/src/app/api/auth/session/route.ts`.
  - Added idle activity sync endpoint in `/Users/ace/crush-web/apps/web/src/app/api/auth/activity/route.ts`.
  - Enforced inactivity timeout handling in `/Users/ace/crush-web/apps/web/src/middleware.ts` and wired client activity/idle logic in `/Users/ace/crush-web/apps/web/src/shared/providers/auth-initializer.tsx`.
  - Added passwordless email-link login trigger + remember-me UI wiring in `/Users/ace/crush-web/apps/web/src/app/auth/login/login-form.tsx` and auth store/service (`/Users/ace/crush-web/packages/core/src/stores/auth.ts`, `/Users/ace/crush-web/packages/core/src/services/auth.ts`).
  - Improved messaging parity with pinned conversations and ice-breakers integration in `/Users/ace/crush-web/apps/web/src/app/(app)/messages/page.tsx` and `/Users/ace/crush-web/apps/web/src/app/(app)/messages/[matchId]/chat-room.tsx`.
  - Enabled page-view analytics provider in `/Users/ace/crush-web/apps/web/src/shared/providers/app-providers.tsx`.
  - Updated TODO status/coverage in `docs/TODO_WEBAPP.md`.
- Decisions/Handoffs:
  - Chose server-enforced idle timeout (middleware + HttpOnly activity cookie) instead of client-only timers for better reliability.
  - Kept "new device verification" open; current pass focused on shippable auth/session items without introducing weak pseudo-verification.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass, warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass, 40/40 tests)
- Next Step: Implement remaining auth hardening item (`new device verification`) and real Sentry/uptime monitoring.

### T-2026-02-23-WEB-DEVICE-VERIFY
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Complete TODO_WEBAPP authentication hardening by implementing new-device verification with full user-facing flow and account-level management.
- Scope: Web app implementation in `/Users/ace/crush-web` plus status/docs updates in this repository.
- Key Changes:
  - Added trusted-device service in `/Users/ace/crush-web/packages/core/src/services/device-security.ts` and exported it via `/Users/ace/crush-web/packages/core/src/index.ts`.
  - Extended auth store in `/Users/ace/crush-web/packages/core/src/stores/auth.ts` with device trust state/actions (`checkDeviceTrust`, `trustCurrentDevice`, `loadTrustedDevices`, `revokeTrustedDevice`).
  - Enforced trusted-device gating on authenticated app routes in `/Users/ace/crush-web/apps/web/src/app/(app)/layout.tsx`.
  - Added verification UI flow:
    - `/Users/ace/crush-web/apps/web/src/app/auth/device-verify/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/auth/device-verify/complete/page.tsx`
  - Updated login messaging for device-verification redirect reason in `/Users/ace/crush-web/apps/web/src/app/auth/login/login-form.tsx`.
  - Added trusted-device management card in `/Users/ace/crush-web/apps/web/src/app/(app)/settings/account/page.tsx`.
  - Updated TODO status/changelog in `docs/TODO_WEBAPP.md`.
- Decisions/Handoffs:
  - Device trust enforcement applies to verified email sessions; phone-only/unverified-email sessions bypass this check to avoid conflicting with primary email-verification flow.
  - Trust metadata is stored in Firestore user security metadata (`security.trustedDevices`) with current-device matching via persistent browser-local device ID.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass, warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass, 40/40 tests)
- Next Step: Continue TODO_WEBAPP on monitoring hardening (real Sentry integration + uptime monitoring) and remaining realtime/chat resiliency items.

### T-2026-02-23-WEB-MONITORING
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Complete TODO_WEBAPP monitoring hardening with production-usable error tracking and uptime monitoring.
- Scope: Web monitoring implementation in `/Users/ace/crush-web` and required status/docs updates in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Replaced mock monitoring wrapper with real Sentry-backed implementation in `/Users/ace/crush-web/apps/web/src/lib/sentry.ts`.
  - Initialized monitoring and synced authenticated user context in `/Users/ace/crush-web/apps/web/src/shared/providers/auth-initializer.tsx`.
  - Added health endpoint in `/Users/ace/crush-web/apps/web/src/app/api/health/route.ts` with env checks, Firebase Admin ping, and rate limiting.
  - Added scheduled uptime workflow in `/Users/ace/crush-web/.github/workflows/uptime-monitor.yml` (cron + manual trigger) with failure on degraded health response.
  - Added monitoring env documentation in:
    - `/Users/ace/crush-web/.env.example`
    - `/Users/ace/crush-web/apps/web/.env.example`
  - Updated TODO completion status/changelog in `docs/TODO_WEBAPP.md`.
- Decisions/Handoffs:
  - Health endpoint treats missing Firebase Admin credentials as `warn` (degraded only on explicit failures), keeping local/dev operable while still surfacing production misconfiguration.
  - Uptime workflow defaults to `https://crush-web-chi.vercel.app/api/health` and supports repository secret override `UPTIME_HEALTHCHECK_URL`.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint`
  - `pnpm -C /Users/ace/crush-web test`
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP on realtime resiliency (`Reconnection logic / offline indicator`) and analytics funnel events.

### T-2026-02-23-WEB-REALTIME-ANALYTICS
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Complete TODO_WEBAPP messaging resiliency and analytics funnel/event tracking with production-usable behavior.
- Scope: Web app implementation in `/Users/ace/crush-web` and required tracker/todo updates in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Added network status hook in `/Users/ace/crush-web/apps/web/src/shared/hooks/use-network-status.ts` and exported via `/Users/ace/crush-web/apps/web/src/shared/hooks/index.ts`.
  - Implemented offline indicators + reconnect refresh logic for conversation list in `/Users/ace/crush-web/apps/web/src/app/(app)/messages/page.tsx`.
  - Implemented offline indicators, reconnect recovery flow, and offline-safe compose behavior in `/Users/ace/crush-web/apps/web/src/app/(app)/messages/[matchId]/chat-room.tsx`.
  - Expanded analytics event model and provider dispatch support with funnel-step typing in `/Users/ace/crush-web/apps/web/src/lib/analytics.ts` and exports in `/Users/ace/crush-web/apps/web/src/components/analytics/index.ts`.
  - Added event/funnel tracking across core conversion paths:
    - Auth login: `/Users/ace/crush-web/apps/web/src/app/auth/login/login-form.tsx`
    - Auth signup: `/Users/ace/crush-web/apps/web/src/app/auth/signup/page.tsx`
    - Onboarding progression/completion: `/Users/ace/crush-web/apps/web/src/app/onboarding/onboarding-flow.tsx`
    - Discovery swipes/matches: `/Users/ace/crush-web/apps/web/src/app/(app)/discover/page.tsx`
    - Messaging pin + conversation actions: `/Users/ace/crush-web/apps/web/src/components/messages/pinned-conversations.tsx`, `/Users/ace/crush-web/apps/web/src/app/(app)/messages/page.tsx`, `/Users/ace/crush-web/apps/web/src/app/(app)/messages/[matchId]/chat-room.tsx`
    - Premium checkout funnel: `/Users/ace/crush-web/apps/web/src/app/(app)/premium/premium-view.tsx`
  - Updated TODO completion/changelog in `docs/TODO_WEBAPP.md`.
- Decisions/Handoffs:
  - Reconnection strategy uses browser online/offline events and explicit refresh/openConversation rehydration on reconnect, instead of passive snapshot waiting.
  - Offline compose is intentionally blocked for now (no queued outbox yet) to avoid silent delivery failures and keep UX deterministic.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP on remaining polish backlog (retry logic for failed requests, accessibility audits, Lighthouse/Core Web Vitals).

### T-2026-02-23-WEB-RETRY-LOGIC
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Close TODO_WEBAPP error-handling gap by implementing real retry logic for failed requests in the messaging flow.
- Scope: Messaging store/UI code in `/Users/ace/crush-web` and TODO/workflow documentation in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Added bounded retry utility logic for transient failures in `/Users/ace/crush-web/packages/core/src/stores/message.ts`.
  - Applied automatic retry to:
    - `loadConversations`
    - `loadMessages`
    - `loadMoreMessages`
    - `sendMessage`
  - Added manual resend action `retryFailedMessage(messageId, currentUserId)` in `/Users/ace/crush-web/packages/core/src/stores/message.ts`.
  - Updated chat UI to expose resend control for failed outbound messages in `/Users/ace/crush-web/apps/web/src/app/(app)/messages/[matchId]/chat-room.tsx`.
  - Added analytics funnel/feature events for resend attempts in `/Users/ace/crush-web/apps/web/src/app/(app)/messages/[matchId]/chat-room.tsx`.
  - Updated TODO completion/changelog in `docs/TODO_WEBAPP.md`.
- Decisions/Handoffs:
  - Retry policy is intentionally bounded (3 attempts, exponential backoff) and only for transient/network-like errors to avoid repeated retries on permanent failures.
  - Outbound failures remain visible with explicit manual retry control to keep user behavior deterministic.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP on remaining quality backlog (Lighthouse/Core Web Vitals and accessibility audit items).

### T-2026-02-23-WEB-FEATURE-GATING
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Complete TODO_WEBAPP subscription feature-gating tasks by introducing reusable premium gate infrastructure and applying it across existing ad-hoc pages.
- Scope: Web UI components/pages in `/Users/ace/crush-web` and required workflow/todo updates in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Added reusable upsell modal in `/Users/ace/crush-web/apps/web/src/features/premium/components/upsell-modal.tsx`.
  - Added reusable plus feature wrapper gate in `/Users/ace/crush-web/apps/web/src/features/premium/components/plus-feature-gate.tsx`.
  - Exported new premium gating components in:
    - `/Users/ace/crush-web/apps/web/src/features/premium/components/index.ts`
  - Replaced duplicated inline premium gate blocks with shared component usage in:
    - `/Users/ace/crush-web/apps/web/src/app/(app)/likes/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/(app)/insights/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/(app)/messages/requests/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/(app)/settings/incognito/page.tsx`
  - Applied build-stability fixes discovered during verification:
    - `/Users/ace/crush-web/apps/web/src/lib/sentry.ts` (strict type-safe cast for span status setter)
    - `/Users/ace/crush-web/apps/web/src/components/analytics/analytics-provider.tsx` (removed `useSearchParams` hook dependency from global provider)
    - `/Users/ace/crush-web/apps/web/src/app/(app)/layout.tsx` (removed `useSearchParams` dependency from protected app layout redirects)
  - Updated TODO status/changelog in `docs/TODO_WEBAPP.md`.
- Decisions/Handoffs:
  - Added gate+modal analytics hooks (`feature_used` + subscription funnel steps) so upsell interactions are measurable by feature source.
  - Kept gated-content behavior deterministic: non-premium users see contextual previews while premium-only actions remain blocked.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `pnpm -C /Users/ace/crush-web build` (still failing on pre-existing Next.js 16 `useSearchParams`/Suspense requirement at `/auth/device-verify`)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP with remaining quality backlog and close the repo-wide Next.js `useSearchParams`/Suspense build blocker across auth routes.

### T-2026-02-23-WEB-BUILD-SUSPENSE
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Continue TODO_WEBAPP by closing the Next.js 16 `useSearchParams` suspense migration blocker so production web build succeeds.
- Scope: Auth route/pages and shared routing/analytics providers in `/Users/ace/crush-web`, with required workflow/todo updates in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Added Suspense-safe wrapper pattern to auth pages using `useSearchParams`:
    - `/Users/ace/crush-web/apps/web/src/app/auth/device-verify/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/auth/device-verify/complete/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/auth/forgot-password/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/auth/signup/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/auth/phone/page.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/auth/verify-email/page.tsx`
  - Removed `useSearchParams` dependency from global/shared surfaces to avoid static prerender bailouts:
    - `/Users/ace/crush-web/apps/web/src/components/analytics/analytics-provider.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/(app)/layout.tsx`
  - Kept previously applied strict typing fix:
    - `/Users/ace/crush-web/apps/web/src/lib/sentry.ts`
  - Updated TODO changelog in `docs/TODO_WEBAPP.md`.
- Decisions/Handoffs:
  - Used minimal structural migration (outer Suspense + inner content component) to preserve current client-side behavior and avoid broad auth flow rewrites.
  - Standardized URL query reads in shared providers/layout to `window.location.search` to remove hook-level Suspense requirements in global contexts.
- Verification:
  - `pnpm -C /Users/ace/crush-web build` (pass)
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP quality backlog (Lighthouse/Core Web Vitals and accessibility audits).

### T-2026-02-23-WEB-INTEREST-FILTER
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Continue TODO_WEBAPP by shipping discovery `Interest filtering` as an end-to-end functional filter (not UI-only).
- Scope: Core discovery filter model/service logic in `/Users/ace/crush-web/packages/core` and discover filter UI in `/Users/ace/crush-web/apps/web`, plus required docs updates in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Extended discovery filter type with optional interests array:
    - `/Users/ace/crush-web/packages/core/src/types/match.ts`
  - Added case-insensitive shared-interest filtering in discovery profile retrieval:
    - `/Users/ace/crush-web/packages/core/src/services/match.ts`
  - Extended discover filter dialog with shared-interest chip selection and clear action:
    - `/Users/ace/crush-web/apps/web/src/features/discover/components/filter-dialog.tsx`
  - Updated TODO status/changelog in:
    - `docs/TODO_WEBAPP.md`
- Decisions/Handoffs:
  - Shared-interest filtering requires at least one overlap between selected filter interests and candidate profile interests.
  - Interest matching is normalized (`trim + lowercase`) to avoid case/whitespace mismatch issues.
  - Aligned discover dialog gender option keys with profile model (`non_binary`, `other`) while touching the filter controls.
- Verification:
  - `pnpm -C /Users/ace/crush-web build` (pass)
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP quality backlog (Lighthouse/Core Web Vitals and accessibility audits), or implement next discovery gap (`Daily limits`).

### T-2026-02-23-WEB-DAILY-LIMITS
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Continue TODO_WEBAPP by shipping discovery swipe daily limits with real enforcement and clear user feedback.
- Scope: Core swipe logic in `/Users/ace/crush-web/packages/core`, discovery/weekly-picks UX in `/Users/ace/crush-web/apps/web`, and required docs updates in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Enforced like-limit consumption inside central swipe service (covers discovery + weekly picks + other swipe callers):
    - `/Users/ace/crush-web/packages/core/src/services/match.ts`
  - Added per-action disabling support for discovery action buttons:
    - `/Users/ace/crush-web/apps/web/src/features/discover/components/action-buttons.tsx`
  - Added discover-page limit UX and behavior:
    - compact limit indicator
    - disabled like/super-like actions when depleted
    - limit-reached toasts + analytics event tracking
    - limit refresh after successful positive swipes
    - `/Users/ace/crush-web/apps/web/src/app/(app)/discover/page.tsx`
  - Added user-facing daily-limit handling in weekly picks positive swipe actions:
    - `/Users/ace/crush-web/apps/web/src/app/(app)/weekly-picks/page.tsx`
  - Updated TODO status/changelog in:
    - `docs/TODO_WEBAPP.md`
- Decisions/Handoffs:
  - Limit enforcement is centralized in `matchService.swipe` to prevent bypass from alternative swipe surfaces.
  - Like usage increments only for first-time positive swipe records for a target profile (`like`/`superlike`), avoiding duplicate consumption on repeat writes.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `pnpm -C /Users/ace/crush-web build` (pass)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP with remaining discovery/profile polish tasks or Phase 9 quality audits (Lighthouse/Core Web Vitals/accessibility).

### T-2026-02-23-WEB-BLOCKED-DISCOVERY-RULE
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Complete TODO_WEBAPP safety item by enforcing blocked-user exclusion in discovery at backend/service layer (not UI-only filtering).
- Scope: Core match/discovery service in `/Users/ace/crush-web/packages/core` and required status docs in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Added blocked-user resolution helper supporting both canonical and legacy data models:
    - Canonical: top-level `/blocks` docs (`blockerId`, `blockedId`)
    - Legacy fallback: `/users/{uid}/blocked/{blockedUid}`
    - `/Users/ace/crush-web/packages/core/src/services/match.ts`
  - Applied blocked-user exclusions to discovery candidate sources:
    - `getDiscoveryProfiles`
    - `getWeeklyPicks`
    - `/Users/ace/crush-web/packages/core/src/services/match.ts`
  - Updated TODO status/changelog:
    - `docs/TODO_WEBAPP.md`
- Decisions/Handoffs:
  - Used `Promise.allSettled` for block-source reads so missing/legacy-incompatible sources do not break discovery loading.
  - Centralized filtering in core service to ensure all discovery surfaces inherit the rule consistently.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `pnpm -C /Users/ace/crush-web build` (pass)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP on remaining discovery backlog (`Profile stories`, `Boost`, `Passport`) or profile/edit polish tasks.

### T-2026-02-23-WEB-PHOTO-CAROUSEL
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Continue TODO_WEBAPP by completing discovery `Photo carousel on profile cards` with explicit, accessible multi-photo navigation.
- Scope: Discover swipe-card UI in `/Users/ace/crush-web/apps/web` and required status docs in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Upgraded swipe-card photo browsing to an explicit carousel UX:
    - Visible previous/next controls
    - Keyboard left/right navigation for focused top card
    - Photo position indicator (`current/total`)
    - Maintained existing tap-zone navigation
    - `/Users/ace/crush-web/apps/web/src/features/discover/components/swipe-card.tsx`
  - Updated TODO status/changelog:
    - `docs/TODO_WEBAPP.md`
- Decisions/Handoffs:
  - Kept carousel behavior localized to discover profile cards to avoid risky cross-surface rewrites.
  - Preserved swipe-deck gesture behavior while improving photo-level navigation clarity and accessibility.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `pnpm -C /Users/ace/crush-web build` (pass)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP discovery backlog (`Profile stories`, `Boost`, `Passport mode`).

### T-2026-02-23-WEB-BOOST-FEATURE
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Continue TODO_WEBAPP by implementing `Boost feature` in discovery with real activation status, cooldown behavior, and discovery ranking impact.
- Scope: Core boost and discovery logic in `/Users/ace/crush-web/packages/core`, discover UI controls in `/Users/ace/crush-web/apps/web`, and required status docs in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Added dedicated boost domain model/service/store:
    - `/Users/ace/crush-web/packages/core/src/types/boost.ts`
    - `/Users/ace/crush-web/packages/core/src/services/boost.ts`
    - `/Users/ace/crush-web/packages/core/src/stores/boost.ts`
    - `/Users/ace/crush-web/packages/core/src/index.ts` (exports)
  - Extended user typing/mapping for persisted boost metadata:
    - `/Users/ace/crush-web/packages/core/src/types/user.ts`
    - `/Users/ace/crush-web/packages/core/src/services/user.ts`
  - Extended discovery profile shape with boost metadata and added boosted-profile prioritization:
    - `/Users/ace/crush-web/packages/core/src/types/match.ts`
    - `/Users/ace/crush-web/packages/core/src/services/match.ts`
  - Added discover boost control UI with:
    - activation confirmation modal
    - active/cooldown countdowns
    - premium upsell path for non-premium users
    - boost activation analytics
    - `/Users/ace/crush-web/apps/web/src/features/discover/components/boost-control.tsx`
    - `/Users/ace/crush-web/apps/web/src/features/discover/index.ts`
    - `/Users/ace/crush-web/apps/web/src/app/(app)/discover/page.tsx`
  - Added boosted-profile visual indicator on discover cards:
    - `/Users/ace/crush-web/apps/web/src/features/discover/components/swipe-card.tsx`
  - Updated TODO status/changelog:
    - `docs/TODO_WEBAPP.md`
- Decisions/Handoffs:
  - Boost activation is premium-gated and persists activation/cooldown metadata under `users.{uid}.boost.*` with compatibility for pre-existing `boost.expiresAt` values.
  - Discovery ranking now explicitly prioritizes currently boosted profiles before verified/recently-active tie-breakers.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `pnpm -C /Users/ace/crush-web build` (pass)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP discovery backlog with `Passport mode` or `Profile stories`.

### T-2026-02-23-WEB-PASSPORT-MODE
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Continue TODO_WEBAPP by implementing `Passport mode` in discovery with premium-gated destination controls and actual discovery-distance behavior changes.
- Scope: Core user/match logic in `/Users/ace/crush-web/packages/core`, discovery/settings UI in `/Users/ace/crush-web/apps/web`, and required status docs in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Extended user settings model with passport fields:
    - `passportMode?: boolean`
    - `passportLocation?: GeoLocation`
    - `/Users/ace/crush-web/packages/core/src/types/user.ts`
  - Hardened user mapping to merge defaults with persisted settings (backward-safe passport defaults):
    - `/Users/ace/crush-web/packages/core/src/services/user.ts`
  - Added passport-aware discovery reference-location and distance computation:
    - choose passport location when enabled, otherwise profile location
    - haversine distance fallback before legacy `distance`
    - `/Users/ace/crush-web/packages/core/src/services/match.ts`
  - Added premium-gated Passport section to Discovery Settings with:
    - mode toggle
    - destination city/country inputs
    - "Use Current Location" helper
    - persisted save flow + inline error handling
    - `/Users/ace/crush-web/apps/web/src/app/(app)/settings/discovery/page.tsx`
  - Added active-passport destination indicator in Discover UI:
    - `/Users/ace/crush-web/apps/web/src/app/(app)/discover/page.tsx`
  - Updated TODO status/changelog:
    - `docs/TODO_WEBAPP.md`
- Decisions/Handoffs:
  - Passport behavior is enforced in core discovery filtering/ranking so all discovery surfaces inherit the same location baseline.
  - Passport settings are premium-gated in UI while still stored in standard user settings schema for compatibility.
- Verification:
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `pnpm -C /Users/ace/crush-web build` (pass)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md`
- Next Step: Continue TODO_WEBAPP discovery backlog with `Profile stories`.

### T-2026-02-23-WEB-PROFILE-STORIES
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Continue TODO_WEBAPP by implementing `Profile stories` as a complete discovery capability (creation, viewing, and story-aware discovery UI), not a placeholder badge.
- Scope: Story domain/state in `/Users/ace/crush-web/packages/core`, discovery UI in `/Users/ace/crush-web/apps/web`, and required status docs in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Added story domain model and utilities:
    - `/Users/ace/crush-web/packages/core/src/types/story.ts`
  - Added Firestore-backed story service with:
    - active story loading (single + multi-user)
    - create story + create-from-file flow
    - per-user active story limits
    - story view tracking with deduplicated viewer records + view count increment
    - `/Users/ace/crush-web/packages/core/src/services/story.ts`
  - Added story Zustand store with:
    - per-user story map
    - viewed-story tracking state
    - upload progress state
    - load/create/remove/view actions
    - `/Users/ace/crush-web/packages/core/src/stores/story.ts`
  - Extended storage service with story media upload support (image/video validation + limits):
    - `/Users/ace/crush-web/packages/core/src/services/storage.ts`
  - Exported new story types/service/store through core index:
    - `/Users/ace/crush-web/packages/core/src/index.ts`
  - Added discovery story UI components:
    - Story tray with upload CTA and story chips:
      - `/Users/ace/crush-web/apps/web/src/features/discover/components/story-tray.tsx`
    - Full-screen story viewer with progress bars, photo/video playback, keyboard navigation, and view callbacks:
      - `/Users/ace/crush-web/apps/web/src/features/discover/components/story-viewer.tsx`
    - Discover card story badge + tap-to-open hooks:
      - `/Users/ace/crush-web/apps/web/src/features/discover/components/swipe-card.tsx`
    - Component exports:
      - `/Users/ace/crush-web/apps/web/src/features/discover/index.ts`
  - Wired discovery page end-to-end story flow:
    - load stories for current + candidate users
    - open viewer from tray/cards
    - add story via file picker and upload flow
    - view tracking callbacks
    - `/Users/ace/crush-web/apps/web/src/app/(app)/discover/page.tsx`
  - Updated architecture/data-flow docs for story model + flow changes:
    - `docs/project_flowchart.md`
    - `docs/project_dfd.md`
    - `docs/project_er_diagram.md`
  - Updated TODO status/changelog:
    - `docs/TODO_WEBAPP.md`
- Decisions/Handoffs:
  - Story persistence uses `users/{uid}/stories` docs with `views/{viewerId}` subdocs to avoid double-counting views.
  - Story upload supports image/video media with explicit size/type validation at storage-service layer.
  - Discovery story UI was integrated into both normal and empty discovery states so users can still add/view stories when no new cards are available.
- Verification:
  - `pnpm -C /Users/ace/crush-web/packages/core exec eslint src/types/story.ts src/services/story.ts src/stores/story.ts src/services/storage.ts src/index.ts` (pass)
  - `pnpm -C /Users/ace/crush-web/apps/web exec eslint "src/app/(app)/discover/page.tsx" src/features/discover/components/swipe-card.tsx src/features/discover/components/story-tray.tsx src/features/discover/components/story-viewer.tsx src/features/discover/index.ts` (pass)
  - `pnpm -C /Users/ace/crush-web lint` (pass; warnings only baseline)
  - `pnpm -C /Users/ace/crush-web test` (pass; 40/40 tests)
  - `pnpm -C /Users/ace/crush-web build` (pass)
  - `scripts/check_ai_docs_sync.sh --files docs/TODO_WEBAPP.md docs/ai_workboard.md docs/Developer_agent_chat.md` (pass)
- Next Step: Continue TODO_WEBAPP remaining backlog with `Audio/Video calls`, `Push notifications`, or Phase 9 quality audits.

### T-2026-02-23-WEB-PHASE9-QUALITY-AUDITS
- Date: 2026-02-23
- Owner: Codex
- Status: Completed
- Goal: Continue Phase 9 quality work by executing Lighthouse/CWV/accessibility audits and shipping targeted fixes with measurable score improvements.
- Scope: Marketing homepage and global web provider architecture in `/Users/ace/crush-web/apps/web`, plus required status docs in `/Users/ace/my_first_project/docs`.
- Key Changes:
  - Completed Lighthouse baseline + follow-up audit runs for `/` (mobile + desktop), with JSON artifacts:
    - `/Users/ace/my_first_project/docs/reports/lighthouse/2026-02-23-phase9/home-mobile.json`
    - `/Users/ace/my_first_project/docs/reports/lighthouse/2026-02-23-phase9/home-desktop.json`
    - `/Users/ace/my_first_project/docs/reports/lighthouse/2026-02-23-phase9/home-mobile-final.json`
    - `/Users/ace/my_first_project/docs/reports/lighthouse/2026-02-23-phase9/home-desktop-final.json`
  - Fixed homepage accessibility audit failures:
    - removed unnecessary client boundary from marketing page
    - corrected footer heading hierarchy (`h4` -> `h3`) to resolve `heading-order`
    - `/Users/ace/crush-web/apps/web/src/app/(marketing)/page.tsx`
  - Fixed low-contrast `bg-primary` surfaces by updating brand primary/ring tokens to WCAG-safe values:
    - `/Users/ace/crush-web/apps/web/src/styles/globals.css`
  - Reduced marketing-route runtime overhead by splitting providers:
    - root providers now keep theme + cookie consent + page-view tracking only
    - moved auth/query/user-analytics/toaster stack into dedicated runtime providers used by app/auth/onboarding layouts
    - `/Users/ace/crush-web/apps/web/src/shared/providers/app-providers.tsx`
    - `/Users/ace/crush-web/apps/web/src/shared/providers/runtime-providers.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/(app)/layout.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/auth/layout.tsx`
    - `/Users/ace/crush-web/apps/web/src/app/onboarding/layout.tsx`
  - Split analytics concerns into route-level page tracking vs authenticated user identity tracking:
    - `/Users/ace/crush-web/apps/web/src/components/analytics/page-analytics-provider.tsx`
    - `/Users/ace/crush-web/apps/web/src/components/analytics/user-analytics-provider.tsx`
    - `/Users/ace/crush-web/apps/web/src/components/analytics/analytics-provider.tsx`
    - `/Users/ace/crush-web/apps/web/src/components/analytics/index.ts`
  - Updated TODO progress/changelog:
    - `docs/TODO_WEBAPP.md`
- Decisions/Handoffs:
  - Kept authenticated runtime behavior intact by relocating (not removing) QueryClient/AuthInitializer/UserAnalytics from root to route layouts that need them.
  - Maintained page-view analytics on all routes while restricting user-identity analytics to runtime/authenticated routes.
- Verification:
  - `pnpm -C /Users/ace/crush-web/apps/web exec eslint 'src/app/(marketing)/page.tsx' src/components/analytics/analytics-provider.tsx src/components/analytics/page-analytics-provider.tsx src/components/analytics/user-analytics-provider.tsx src/components/analytics/index.ts src/shared/providers/app-providers.tsx src/shared/providers/runtime-providers.tsx 'src/app/(app)/layout.tsx' src/app/auth/layout.tsx src/app/onboarding/layout.tsx` (pass)
  - `pnpm -C /Users/ace/crush-web/apps/web test src/lib/__tests__/accessibility.test.ts` (pass; 17/17 tests)
  - `pnpm -C /Users/ace/crush-web/apps/web build` (pass)
  - Lighthouse final scores for `/`:
    - mobile: Performance `0.78`, Accessibility `1.00`, Best Practices `0.92`, SEO `0.92`
    - desktop: Performance `0.94`, Accessibility `1.00`, Best Practices `0.92`, SEO `0.92`
- Next Step: Continue remaining Phase 9 quality backlog with bundle analysis/code-splitting and image optimization audit, then expand accessibility audit coverage beyond marketing homepage.
