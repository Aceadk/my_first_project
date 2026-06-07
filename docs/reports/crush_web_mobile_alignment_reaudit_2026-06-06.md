# Crush Web and Mobile Alignment Re-Audit

- Date: 2026-06-06
- Repositories:
  - `/Users/ace/my_first_project` - Flutter clients, Firebase rules, Cloud Functions, contracts, and primary collaboration docs.
  - `/Users/ace/crush-web` - Next.js marketing and authenticated web app.
- Previous baseline: `docs/reports/crush_web_mobile_alignment_plan_2026-06-03.md`
- Scope: Evidence-based audit and roadmap. No application behavior was changed.

## Executive Verdict

Substantial alignment work has been completed since the June 3 plan. The web repo now has canonical V2 chat/match adapters, migration tooling, backend-aligned service contracts, auth error mapping, entitlement normalization, notification route mapping, refreshed branding, stronger CI commands, workflow docs, match pinning, and an i18n foundation.

The system is still not aligned enough for a production web release. The central problem has shifted from "missing implementation" to "implemented but not operational":

1. Canonical V2 chat/match behavior is flag-gated and disabled by default.
2. The web app does not initialize Firebase App Check, while production callables and REST paths enforce it.
3. Web CSP excludes the Cloud Functions origin used by the new callable/REST paths.
4. Several live web features still read or write paths that current Firestore rules reject.
5. Some web-owned security and entitlement state is client-controlled.
6. Domain, deployment, route, and production-validation decisions remain unresolved.

The next milestone should not be more UI feature work. It should be a production-operational alignment gate that proves the current web app can complete onboarding, discovery, match, chat, report/block, notification registration, subscription, and account lifecycle flows against the same deployed backend and rules as mobile.

## Audit Method And Evidence Standard

The audit covered repository inventories, route trees, large implementation hotspots, backend exports, Firestore rules, client collection paths, callable/REST usage, feature flags, CSP, App Check, auth/session flows, subscriptions, notifications, calls, localization, design tokens, accessibility surfaces, CI, TODOs, and collaboration reports.

Status terms used in this report:

- **Verified complete:** implemented and supported by passing automated or production evidence.
- **Implemented, not operational:** code exists but is flag-gated, not migrated, not deployed, or incompatible with production controls.
- **Partial:** important paths are aligned, but meaningful drift remains.
- **Open:** required implementation or decision is absent.
- **Blocked:** completion requires external device, environment, provider, or product decision.

Repository scale sampled during the audit:

| Area | Current evidence |
|---|---:|
| Mobile Dart sources | 617 |
| Mobile/integration Dart tests | 278 |
| Mobile screen files | 62 |
| Web TypeScript/TSX sources | 257 |
| Web route pages | 46 |
| Web TSX components | 124 |
| Web source test files | 17 |
| Cloud Functions main implementation | `functions/src/index.ts`, 13,708 lines |
| Functions maintained tests | 24 JavaScript test files |

## Progress Against The June 3 Plan

| Original finding | Current status | What changed | What remains |
|---|---|---|---|
| Backend contract drift | **Partial** | V2 web chat/match services, adapters, contract tests, discovery REST adapter, and `setMatchPinned` exist. | V2 is off by default; many web mutations remain direct Firestore; no generated cross-repo contract. |
| Firestore schema mismatch | **Partial / release blocker** | Canonical match/message adapters and migration script exist. | Migration/cutover is not proven; stories, streaks, promos, blocked users, tokens, and legacy match/chat paths still conflict with rules. |
| User/profile schema | **Partial / release blocker** | Web reads/writes a nested canonical `profile` object and entitlement mapping improved. | Web create/update builders still mutate legacy flat profile keys rejected by current rules. |
| Routes/deep links | **Partial** | Notification route parity mapping and tests were added. | The route matrix describes many routes that do not exist and does not distinguish as-built from target routes. |
| Environment/domain drift | **Open** | A domain/environment decision document exists. | The production domain is still undecided and live code references several domains. |
| Auth/session alignment | **Partial** | Shared web auth error mapping and account deletion callables improved. | App Check is absent; platform auth support differs; device trust is client-writable. |
| Subscription/entitlement | **Partial** | Canonical entitlement resolver exists. | Promo writes and boost entitlement remain client-controlled; Stripe/backend/native billing paths are not one reconciled lifecycle. |
| Notifications | **Partial** | Web push service, route mapper, and route tests exist. | Web token subcollection access is not allowed by current rules; App Check and production browser validation remain. |
| Branding/design | **Partial** | Logo, manifest, metadata, and dark brand background improved. | Mobile and web typography, radii, breakpoints, and component tokens remain separate and undocumented. |
| Testing/CI | **Partial** | Web lint, test, typecheck, and build commands are represented in CI. | Current typecheck/build fail; Playwright, rules emulator, contract integration, and docs-sync lanes are absent. |
| Feature parity | **Partial / open** | Web has broad discovery, profile, safety, premium, and messaging UI coverage. | Calls, full i18n, profile richness, settings/security, and several backend-wired behaviors remain. |
| Documentation/workflow | **Mostly complete** | Web AGENTS/workflow structure improved and old duplicate trackers were removed. | Route/domain/contract matrices and routing TODOs drift from current code. |
| Repo hygiene | **Verified complete** | Tracked dependency/build artifacts were removed. | Keep CI guardrails so they do not return. |

## What Is Genuinely Completed

The following work is materially complete at the implementation level:

- Phase 0 planning artifacts exist for backend contracts, routes, domains, web CI, and chat/match migration.
- Web V2 chat/match service and adapter contracts exist with focused tests.
- Web match pinning has a backend-managed mutation path.
- Notification route translation covers backend/mobile route names and has focused parity tests.
- Auth error normalization and entitlement normalization have focused tests.
- Web branding assets and metadata are closer to the mobile brand.
- Web CI configuration includes lint, unit test, typecheck, and build intentions.
- The web repo has current collaboration instructions.
- Generated/dependency artifact hygiene was corrected.
- Main backend TypeScript builds successfully.
- Web unit tests currently pass: 12 files, 150 tests.

These items should remain marked as implemented, but several must not be called production-complete until the operational gates below pass.

## Release Blockers

### P0.1 Make Canonical Web Paths Operational

Evidence:

- `packages/core/src/config/features.ts` defaults `NEXT_PUBLIC_USE_V2_CHAT` to `false`.
- The legacy match/message stores remain the default runtime path.
- The migration script and plan exist, but no staging/production migration and cutover evidence was found.

Required work:

1. Inventory existing `conversations`, legacy `matches`, messages, typing state, and unread metadata in each environment.
2. Run migration dry-run, execute it in staging, and verify counts plus representative records.
3. Enable V2 in staging and run authenticated discovery -> match -> chat -> edit/unsend/read/pin/report/block flows.
4. Enable V2 in production only after rollback criteria and monitoring are ready.
5. Remove legacy services and the feature flag after a defined observation window.

Exit gate:

- No production web mutation uses legacy `conversations`, `typing_indicators`, directional matches, or direct swipes.

### P0.2 Fix App Check And CSP Before Enabling Backend Calls

Evidence:

- Web Firebase bootstrap initializes app/auth/firestore/functions/storage but not App Check.
- Backend callable and REST helpers enforce App Check in production runtimes.
- Web CSP `connect-src` does not include the Cloud Functions host used by callables and discovery REST.

Required work:

1. Initialize web App Check with environment-specific providers and token refresh.
2. Add the approved callable/REST origins to CSP.
3. Add staging checks that fail when App Check or CSP blocks a required endpoint.
4. Confirm local/emulator behavior remains explicit and does not weaken production enforcement.

Exit gate:

- Every web callable and REST path succeeds with valid App Check and fails predictably without it in staging.

### P0.3 Reconcile Every Live Web Data Path With Firestore Rules

Confirmed conflicts:

| Web path/behavior | Current issue |
|---|---|
| User/profile create and update | Web builder still writes legacy flat fields such as `age`, `gender`, `bio`, and `interests`; current rules reject new/mutated flat profile fields. |
| Stories | Web storage uses `users/{uid}/stories`, but Firestore story behavior expects top-level `stories/{storyId}`. |
| Streaks | Web writes `user_streaks`; no current client rule permits it. |
| Promos | Web reads/writes `promoCodes` and `promoCodeRedemptions`; no current safe client rule permits it. |
| Blocked users | Web uses `users/{uid}/blocked`; canonical rules/backend use top-level block behavior. |
| Reports | A web direct report shape differs from the canonical rule/backend report shape. |
| Notification tokens | Web writes `users/{uid}/fcmTokens`; no nested rule currently permits it. |
| Legacy match/chat | Direct writes conflict with backend-managed canonical matches/messages. |

Required work:

1. Build a machine-readable client-path inventory for web and mobile.
2. Route sensitive mutations through backend commands.
3. Keep direct reads only where rules explicitly support the canonical shape.
4. Add Firestore emulator tests for every retained direct client query and write.
5. Delete unsupported service paths after migration.

Exit gate:

- A rules-emulator suite proves every live web read/write path, including denial cases.

### P0.4 Remove Client-Controlled Security And Entitlement Decisions

Evidence:

- Web device trust is stored under the owner-writable user document and `trustCurrentDevice` directly adds the current browser.
- The app shell uses this state as a security gate.
- Web boost activation directly updates `boost.*` under the user document.
- Promo redemption and premium-related logic still includes direct client data paths.

Required work:

1. Decide whether device trust is security enforcement or UX convenience.
2. If it is security enforcement, require a backend challenge, verified factor, audited command, and server-owned trusted-device records.
3. Route boost activation, promo redemption, and final entitlement writes through server-owned commands.
4. Protect entitlement/security fields in Firestore rules.
5. Add abuse tests for replay, self-grant, cooldown bypass, and forged state.

Exit gate:

- A client cannot self-grant trust, premium state, promo benefits, or boost eligibility by editing its own document.

### P0.5 Establish One Contract And Deployment Source Of Truth

Evidence:

- Dart DTOs, TypeScript DTOs, callable payloads, REST payloads, rules, and documentation are maintained independently.
- The route matrix lists many target routes as if they already exist.
- Domain planning is not implemented; code still mixes `crush.app`, `crushhour.app`, `crushapp.com`, and `app.crush.dating`.
- Vercel is configured for Next.js, while Firebase hosting configuration points at a static `apps/web/out` shape without a static-export configuration.

Required work:

1. Choose the canonical production/staging domains and hosting path.
2. Mark matrices with `as-built`, `target`, `deprecated`, and `blocked` states.
3. Generate or validate shared DTO fixtures/schemas across Dart, TypeScript, backend, and rules tests.
4. Add CI checks for deprecated domains, missing routes, unsupported collection paths, and contract drift.
5. Record deployment evidence and version for every release gate.

Exit gate:

- One deployment path, one domain matrix, one route manifest, and one validated contract set drive both clients.

## Module Alignment Matrix

| Module | Mobile/backend state | Web state | Alignment assessment | Next required outcome |
|---|---|---|---|---|
| Auth/session | Broad Firebase/mobile auth, OTP/account lifecycle, backend commands | Email/password, phone, Google, session cookie, device-trust UI | **Partial / high risk** | App Check, support matrix, server-owned device verification, shared lifecycle E2E |
| Onboarding/profile | Rich canonical nested profile and broad fields | Strong onboarding/profile UI, but incompatible legacy flat writes remain | **Partial / release blocker** | Canonical-only writes, shared fixtures, rules tests, field-support matrix |
| Discovery/matching | Backend discovery and matching services exist; some advanced engine work is not wired | Discovery REST adapter exists, but legacy/direct behavior remains in places | **Partial** | One backend command path, migration/cutover, shared ranking/filter evidence |
| Matches/chat | Canonical `matches/{id}/messages`, backend commands, mobile UI | V2 adapters exist; default runtime remains legacy | **Implemented, not operational** | Execute migration and remove legacy runtime |
| Safety/report/block | Canonical backend/rules behavior and safety surfaces | Safety UI exists; some direct report/block paths use unsupported shapes | **Partial / high risk** | Use canonical commands and prove denial/audit behavior |
| Calls | Mobile signaling and UI exist; native rendering/lifecycle/device proof remains open | No real calls route/service/UI; permissions policy blocks camera/mic | **Open / blocked** | Finish mobile reliability first, then define web WebRTC product scope |
| Notifications | Backend/mobile push is broad; route parity improved | Web push service and route mapper exist | **Partial** | Rules/App Check/VAPID/prod-browser validation and shared prefs schema |
| Subscription | Native/provider/backend paths exist; lifecycle risks remain | Stripe and premium UI exist; entitlement resolver improved | **Partial / high risk** | One server-owned entitlement model and provider reconciliation tests |
| Settings/account | Mobile has broad settings and lifecycle coverage | Web has account, blocked, discovery, incognito, notifications, privacy | **Partial** | Shared capability matrix; add only supported settings with canonical APIs |
| I18n/content | Mobile has broad ARB/locales with remaining hardcoded strings | Translation foundation exists but is not mounted in the app | **Open / early foundation** | Mount provider, translate routes, localize metadata/errors, add locale E2E |
| Analytics/observability | Analytics and audits exist, but some matching analytics are not wired | Analytics/Sentry usage exists; performance integration is incomplete | **Partial** | Shared event taxonomy, release dashboards, SLOs, redaction checks |
| Marketing/legal | Mobile and web both expose legal/help surfaces | Claims and domains are inconsistent; calls are marketed before web support | **Partial** | Canonical claims, domains, support identity, and product capability truth |
| Platform/deploy | Mobile CI and backend checks are broad; device evidence remains | Web CI improved but current typecheck/build fail; deployment state unclear | **Partial / release blocker** | Green required CI, authenticated E2E, staging release evidence |

## UI And UX Alignment

### What Is Working

- Both clients use a dark, relationship-focused product identity and the refreshed Crush brand.
- The web app has broad route coverage, loading/empty-state handling inside major pages, responsive containers, and dedicated marketing/app layouts.
- Mobile has deeper native flows, richer profile/settings surfaces, more localization coverage, and stronger platform-specific behavior.
- Web notification route translation reduces dead-end navigation from mobile/backend route names.

### What Is Not Yet Aligned

#### Information Architecture

- Mobile primary navigation emphasizes Discover, Matches, Chats, and Profile.
- Web navigation adds Likes You and Settings as primary sidebar items and uses different route names.
- The difference may be appropriate for desktop, but it is undocumented. A shared user-flow specification should define equivalent goals, not force identical navigation.

#### Design System

- Mobile shared tokens use Plus Jakarta Sans and Playfair with a different radius and breakpoint philosophy.
- Web uses Inter/JetBrains and a compact Tailwind-based system.
- Brand assets are closer, but component behavior, typography hierarchy, spacing, radii, motion, and breakpoints are not one intentional system.

Required outcome:

- Publish a platform-neutral semantic token contract for color, typography roles, spacing roles, radius roles, elevation, motion, focus, and states.
- Allow platform-specific rendering, but document deliberate deviations.

#### Responsive And Desktop Behavior

- Web routes generally constrain content widths, but several large pages own layout, data behavior, and interaction logic in one file.
- Mobile/iPad manual evidence remains incomplete.
- Cross-platform responsive acceptance should cover narrow mobile web, tablet, laptop, wide desktop, orientation, keyboard, and reduced-motion behavior.

#### Accessibility

- Web has accessibility utility/tests and many labels, but no automated authenticated axe/keyboard lane was found.
- Reduced-motion utilities exist without broad demonstrated adoption.
- Mobile VoiceOver, TalkBack, external keyboard, and iPad evidence remain blocked or pending.

Required outcome:

- Add keyboard-only, focus-order, dialog focus-trap, contrast, reduced-motion, screen-reader-label, zoom, and authenticated axe checks to the release gate.

#### Loading, Error, Empty, And Offline States

- Web has route/group error boundaries but no route-level `loading.tsx` files; many states are implemented ad hoc inside large pages.
- Mobile offline queue hardening exists, but chat send/connectivity restore is not fully wired.
- Define one state model per shared flow: initial load, refresh, pagination, optimistic mutation, partial failure, offline, retry, empty, blocked, and permission denied.

#### Localization And Content Truth

- Web i18n is a scaffold, not an integrated product capability. The root app still defaults to English, and hardcoded UI copy remains extensive.
- Current web typecheck fails in the i18n tests due to overly literal message typing.
- Marketing/FAQ claims must not imply web calling is available before it exists.

## Architecture And Maintainability

### Backend

- `functions/src/index.ts` is 13,708 lines and contains many unrelated domains. This increases regression risk, cold-start coupling, review difficulty, and test isolation problems.
- Split by bounded context while preserving exports: auth, profile, discovery, match/chat, safety, notifications, subscription, calls, and shared middleware/contracts.
- Keep a thin export/composition file and require focused tests per module.

### Mobile

High-complexity UI and implementation hotspots include profile setup, sign-up, profile edit, discovery filters, Firebase auth repository, and fake repositories.

Open deeper work includes:

- Wire the advanced matching/filter/analytics pipeline into production discovery.
- Wire offline chat queue behavior into real send/connectivity restore flows.
- Resolve chat backend N+1 behavior and retention-trigger emulator coverage.
- Finish native call rendering/lifecycle and device validation.
- Continue incremental Auth/Chat/Discovery/Profile/Settings refactors.

### Web

High-complexity hotspots include the chat room, onboarding flow, profile edit, discover page, settings pages, legacy match/message services, and auth store.

Recommended cleanup order:

1. Remove legacy data services after canonical cutover.
2. Extract page orchestration from presentational components.
3. Create shared flow-state primitives for async/loading/error/empty states.
4. Move sensitive mutations behind typed backend commands.
5. Split large stores by bounded context and remove duplicated mapping logic.

## Testing And Verification Gaps

Current audit verification:

| Check | Result |
|---|---|
| `functions/npm run build` | Passed |
| `crush-web/pnpm test` | Passed: 12 files, 150 tests |
| `crush-web/pnpm typecheck` | Failed in `src/lib/__tests__/i18n.test.ts` due to literal-value message typing |
| `crush-web/pnpm build` | Passed; the build does not catch the failing test-file typecheck |
| `crush-web/pnpm lint` | Passed with 35 warnings, including hook-dependency, async-client-component, missing-alt, and unused-code warnings |

Missing release evidence:

- Firestore rules emulator allow/deny tests.
- Authenticated Playwright flow in CI.
- App Check and CSP integration tests.
- Cross-repo contract fixture validation.
- Staging migration/cutover evidence.
- Production web deployment evidence for recent alignment commits.
- Browser push validation across supported browsers.
- Mobile/iPad/VoiceOver/TalkBack/external-keyboard evidence.
- Subscription provider lifecycle/reconciliation evidence.
- Calls device matrix.

## Clean Target Architecture

The aligned system should follow these boundaries:

1. **Canonical contracts:** Versioned schemas define REST/callable payloads, Firestore documents, routes, notification payloads, and entitlements. Dart and TypeScript validate against the same fixtures.
2. **Server-owned commands:** Auth lifecycle, matching, chat mutations, safety actions, trust, boost, promos, subscription state, and account lifecycle are backend-owned.
3. **Explicit client reads:** Direct Firestore reads are permitted only when documented, indexed, and covered by rules-emulator tests.
4. **One route manifest:** Each feature records mobile route, web route, public URL, notification target, aliases, and implementation status.
5. **One environment manifest:** Domains, Firebase projects, App Check, CORS, CSP, Stripe/provider modes, and deployment targets are environment-specific and validated.
6. **Semantic design contract:** Shared brand and UX semantics with documented platform-specific navigation and component behavior.
7. **Release evidence:** A feature is complete only after implementation, migration, deployment, automated verification, and production/staging observation are recorded.

## Prioritized Execution Roadmap

### Gate 0 - Restore A Green, Truthful Baseline

- Fix current web typecheck/build regression.
- Decide canonical production/staging domains and deployment target.
- Update route/domain/contract matrices to distinguish as-built and target state.
- Add web App Check and required CSP origins.
- Add a minimal rules-emulator harness.

Exit criteria:

- Required web CI commands are green.
- Staging web can call protected backend paths.
- Documentation no longer presents target routes as implemented routes.

### Gate 1 - Canonical Data And Mutation Cutover

- Fix canonical-only user/profile writes.
- Reconcile notifications tokens, reports, blocks, stories, streaks, promos, and boost.
- Run chat/match migration and enable V2 in staging.
- Add authenticated cross-repo discovery -> match -> chat -> safety E2E.
- Remove unsupported legacy services after observation.

Exit criteria:

- All live web paths pass current rules and backend authorization.
- No client-controlled trust/entitlement mutation remains.

### Gate 2 - Account, Subscription, And Notification Reliability

- Publish auth-method and account-lifecycle support matrix.
- Make device verification server-owned or explicitly label it UX-only.
- Reconcile Stripe, native billing, promos, and final entitlement writes.
- Validate push registration, preferences, routes, and browser behavior.
- Add provider lifecycle and abuse tests.

Exit criteria:

- Account and entitlement state remain consistent across web, mobile, backend, and providers.

### Gate 3 - Product And UX Parity

- Complete web i18n integration and prioritized locales.
- Align profile field/media capabilities and settings support.
- Publish semantic design tokens and shared flow-state patterns.
- Complete accessibility and responsive evidence.
- Decide and implement or explicitly defer web calling.

Exit criteria:

- Shared user goals have equivalent, documented behavior across platforms.
- Marketing claims match deployed capabilities.

### Gate 4 - Scale And Maintainability

- Decompose the Functions monolith by bounded context.
- Break down the largest web/mobile hotspots incrementally.
- Wire matching analytics, offline queue, and performance monitoring.
- Add generated contract/route/domain validation and production SLO dashboards.

Exit criteria:

- Contract drift, route drift, domain drift, and unsupported client paths fail automatically in CI.

## Immediate Next Tasks

Recommended order for the next focused tasks:

1. **WEB-PROD-001:** Fix web typecheck/build, initialize App Check, and correct CSP with integration tests.
2. **RULES-001:** Add Firestore emulator tests and reconcile user/profile plus notification-token writes first.
3. **WEB-DATA-001:** Replace unsupported block/report/story/streak/promo/boost paths with canonical backend commands or remove them.
4. **CHAT-CUTOVER-001:** Execute staging migration, enable V2, run authenticated E2E, and prepare production rollback.
5. **PLATFORM-001:** Decide domains/hosting and convert route/domain matrices into validated as-built manifests.
6. **SECURITY-001:** Move device trust and entitlement-affecting state behind server-owned commands.
7. **UX-ALIGN-001:** Publish semantic design/IA/state contracts, then complete i18n, accessibility, responsive, and settings parity.

## Definition Of Aligned

Crush web and mobile should be called aligned only when:

- They use the same canonical backend contracts and persisted data shapes.
- Sensitive mutations and entitlements are server-owned.
- Every retained direct client data path is proven by rules-emulator tests.
- Routes, notifications, public URLs, domains, and deployment targets are generated or validated from shared manifests.
- Equivalent user goals have documented cross-platform behavior.
- Required CI, authenticated E2E, migration, staging, and device evidence are green.
- Product claims match deployed capability.
