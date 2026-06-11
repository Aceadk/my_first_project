# Production Readiness Audit — Crush (Mobile + Web)

- Date: 2026-06-11
- Scope: `Crush App` (Flutter + Firebase backend), `crush-web` (Next.js), `crushhour-recommendation-service`, `Credentials/` folder.
- Method: code inspection, live Firebase CLI checks against `crush-f5352`, analyzer/typecheck/test runs executed this date, and verification of the 2026-06-05/06/07 alignment reports against current code.
- Verdict in one line: **the codebase is in good shape and locally green; the product is broken in production because the new Firebase project (`crush-f5352`) has no database, no Storage, and no deployed Cloud Functions.** Production readiness is now an *operations* problem first, a code problem second.

---

## 1. Project Understanding Summary

| Part | What it is | State |
|---|---|---|
| `Crush App/` | Flutter app (iOS/Android/web target) + the entire Firebase backend: `functions/` (14,194-line `index.ts`, ~70 callables/triggers/webhooks), `firestore.rules` (364 lines), `storage.rules`, `database.rules.json`, emulator rule tests | `flutter analyze`: **0 issues** (617 Dart files). Functions tests 205/205 green (2026-06-07 gate). 278 test files. |
| `crush-web/` | Next.js 14 monorepo (pnpm + turbo): `apps/web` + `packages/core` (Firebase services, Zustand stores) + `packages/ui` | `tsc --noEmit` clean, `vitest` **256/256 passing** (verified 2026-06-11) |
| `crushhour-recommendation-service/` | Node/Express recommendation scorer (Dockerfile) | **Duplicated** — diverged copy also lives inside `Crush App/`; deployment status unknown |
| `Credentials/` | Apple .p8 push key, dev/dist certs, provisioning profiles, **Firebase Admin SDK service-account JSON (crush-f5352)**, Android release keystore + plaintext backup notes | Outside git (parent dir is not a repo) but on disk unencrypted; the Admin key is already flagged internally as **exposed / rotation required** |
| Architecture | Mobile: clean layering — `features/<x>/{presentation,domain,data}` + BLoC/Cubit, repository interfaces with Firebase/HTTP/Stub impls selected in `lib/core/di.dart` (default `BackendMode.firebase`). Web: services + typed callables in `packages/core`, Zustand stores, App Check + CSP + middleware guards | Coherent on both sides; the AGENTS.md contract ("backend is source of truth") is respected in current code |
| History | A 9-phase web/mobile alignment program completed 2026-06-07 (`final_alignment_release_gate_2026-06-07.md`: engineering gate GREEN). On 2026-06-07–09 the team decided a **clean start** on a new Firebase project `crush-f5352`, discarding all old data (`FIREBASE_CLEAN_START_CHECKLIST_2026-06-07.md`); cutover is **incomplete** (`docs/firebase_vercel_cutover_runbook_2026-06-09.md`, uncommitted) | Mid-cutover — this is the source of nearly all current breakage |

Live state verified 2026-06-11 via Firebase CLI (account now has access — the 403 from the 06-09 session is resolved):

- `firebase firestore:databases:list --project crush-f5352` → **"No databases found."**
- `firebase apps:list` → Android/iOS/Web apps registered correctly.
- Functions listing fails (nothing deployed; Spark plan blocks Functions/Storage).
- Per the runbook: only Email/Password auth is enabled; Google/Phone/Apple are not.
- All client configs (`firebase_options.dart`, `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`, both `.firebaserc`, web env) correctly point at `crush-f5352`.

**Consequence:** every data-driven screen on mobile and web fails against production today — discovery, onboarding writes, chat, matches, profiles, subscriptions. This, not client code, explains "blank page" symptoms.

---

## 2. Mobile vs Web Comparison Table

(Cross-checked against `docs/contracts/profile_settings_capability_matrix_2026-06-07.md`, `route_deeplink_matrix_2026-06-05.md`, and current code.)

| Feature | Mobile | Web | Works correctly? | Problem found | Priority | Suggested fix |
|---|---|---|---|---|---|---|
| Email/password auth | ✅ | ✅ | Code ✅ / prod ⏳ | Backend not provisioned | P0 | Run cutover runbook |
| Google / Phone / Apple auth | ✅ | ✅ (Google/Phone; Apple n/a) | ❌ in prod | Providers not enabled in console | P0 | Enable in Firebase console |
| Onboarding (terms → basic info → profile setup → verification) | ✅ | ✅ `/onboarding` | Code ✅ | Step granularity differs (mobile multi-route, web single route) — by design, mapped in route matrix | P3 | Keep matrix as canonical map |
| Discovery deck | ✅ | ✅ `/discover` | ❌ in prod | `fetchDiscoveryCandidates` callable + REST not deployed | P0 | Deploy functions |
| Likes you | ✅ `/likes-you` | ✅ `/likes` | Code ✅ | Route name differs (documented) | P3 | None (matrix) |
| Weekly picks / date ideas / compatibility quiz / insights | ✅ | ✅ | Code ✅ | — | — | — |
| Match → chat (V2 canonical `matches/{id}/messages`) | ✅ via callables | ✅ code, **flag OFF** | ❌ on web | `NEXT_PUBLIC_USE_V2_CHAT` defaults OFF → web falls back to legacy direct-Firestore `conversations/` writes, which `firestore.rules` **reject** (`matches` create/update `if false`, no `conversations` rules). On the clean-start DB there is no legacy data to preserve | **P1** | Set flag ON in all envs at cutover; then delete legacy path per `legacy_chat_match_removal_manifest_2026-06-07.md`; skip the now-moot migration scripts |
| Message requests (pre-match) | ✅ | ✅ `/messages/requests` | Code ✅ | — | — | — |
| Voice/video calls | ✅ (Agora + CallKit/PiP) | ➖ deliberately mobile-only | ✅ decision | Documented in `calls_capability_decision_2026-06-07.md` | P3 | Web: show "calls available on mobile" affordance |
| Stories | ✅ | ❓ partial | Unverified | Gender-gated posting in rules (`isFemale`) — check product intent on web | P2 | Verify story surfaces + rules on web |
| Profile view/edit (nested canonical `profile.*`) | ✅ | ✅ | Code ✅ | Photo cap parity fixed (9) | — | — |
| Settings (account/privacy/notifications/discovery/blocked/incognito) | ✅ | ✅ | Code ✅ | Aligned per capability matrix | — | — |
| Subscription | StoreKit/Play Billing + verify callables | Stripe Checkout | ⚠️ | **Two web Stripe paths**: Next.js `/api/stripe/*` routes (used by `premium-view.tsx`) AND functions `createCheckoutSession`/`stripeWebhook`. Next route accepts `userId`/`userEmail` from request body with no token verification; tier names drift (`platinum_*` vs canonical `plan: 'free'|'plus'`) | **P1** | Pick the Cloud Functions path as canonical; make web call the callable; delete or fully harden the Next routes; register exactly one webhook in Stripe |
| Push notifications | FCM + APNs | FCM web push (SW) | ⏳ | FCM/APNs keys + VAPID for new project not configured | P0/P1 | Console setup at cutover |
| Notification deep links | ✅ `notification_routes.dart` | ✅ `resolveNotificationRoute` | Code ✅ | Parity-tested | — | — |
| Report/block/unmatch/boost/streaks/promos | ✅ callables | ✅ callables | Code ✅ | — | — | — |
| i18n | 21+ locales (`lib/l10n`) | **3** (en/es/ar) | ✅ by design | Parity gap acknowledged | P3 | Expand web locales post-launch |
| Theme (light/dark/system, glass design system) | ✅ tokens | ✅ tokens | ✅ | Design-token parity is unit-tested on web (`design-token-parity.test.ts`) | — | — |
| App Check | ✅ | ✅ (reCAPTCHA Enterprise) | ⏳ | Site keys/debug tokens for new project not registered | P1 | Configure at cutover, enforce in staging first |

---

## 3. Routing Problems Found

Both routers are fundamentally sound: mobile uses a single GoRouter with a pure, unit-testable redirect (`lib/core/routing/route_redirect.dart`) covering auth → terms → basic info → profile setup → verification ordering; web uses middleware guards + redirect-after-login + idle timeout. Specific issues:

1. **Unknown routes render the login screen for logged-in users (mobile, worst on Flutter web).**
   - File: `lib/core/router.dart:58-60` — `errorPageBuilder` returns `AuthGatewayScreen`.
   - Why it breaks: an authenticated user who hits a bad/stale URL sees the auth gateway at that URL (the redirect doesn't rescue it because the path isn't an `/auth` route). Looks like being logged out.
   - Fix: dedicated `NotFoundScreen` with "Go home"; redirect logged-in users to `/home`. Affects mobile + Flutter web. **P2**
2. **`/test-agora` debug route is registered in release builds.**
   - File: `lib/core/router.dart:208-211` (`CrushRoutes.testAgora` → `TestVideoScreen`). `widgetCatalog` is correctly `kDebugMode`-gated; this one is not.
   - Fix: wrap in `if (kDebugMode)`. **P2**
3. **Two deployed web apps create a routing identity crisis.**
   - `Crush App/vercel.json` deploys the **Flutter web build** (SPA fallback to `index.html`, Vercel project `my_first_project`; last commit "trigger new vercel deployment"), while `crush-web` deploys the Next.js app (project `crush-web`). They expose different URL schemes (`/home`, `/likes-you`, `/chat/:matchId` vs `/discover`, `/likes`, `/messages/:matchId`).
   - Why it breaks: shared links, SEO, email links, and notification routes can land users on the wrong product; two PWAs claim the same brand.
   - Fix: declare `crush-web` the only public web app (it has marketing pages, CSP, App Check, SEO); keep Flutter web for internal preview only or stop deploying it. **P2 (product decision, do at cutover)**
4. **Chat deep link loads `fetchMatches(currentUserId)` (all matches) to find one match** — `lib/core/router.dart:302-305`. O(n) reads per deep link; add a `fetchMatchById`. **P3**
5. Web middleware matcher **excludes `/api`** — fine for CSP, but means API routes are *not* auth-guarded by middleware; see Security #1 (the checkout route's comment claims otherwise). **Feeds P1.**
6. Browser refresh / back-button on web: middleware + `redirect` param handle it; mobile preserves route across background via `AppStatePreserver`. No issues found. ✅

---

## 4. Backend Problems Found

1. **P0 — The backend does not exist in production.** No Firestore DB, no Storage, no deployed Functions, Spark plan, Email/Password only (verified 2026-06-11). Every other finding is downstream. Execute `docs/firebase_vercel_cutover_runbook_2026-06-09.md` end-to-end:
   1. `firebase firestore:databases:create "(default)" --location nam5 --project crush-f5352`
   2. `firebase deploy --only firestore:rules,firestore:indexes,database`
   3. Enable Google/Phone/Apple auth providers
   4. Upgrade to Blaze → `firebase deploy --only storage,functions`
   5. Vercel: verify `NEXT_PUBLIC_FIREBASE_*`, add **freshly-rotated** Admin JSON, `vercel --prod`, check `/api/health`
   6. App Check (reCAPTCHA Enterprise site keys + Play Integrity/App Attest), FCM web VAPID key, APNs key upload, Stripe webhook registration + secrets in Functions config
2. **P1 — Web legacy chat path vs rules** (see table row above): with `NEXT_PUBLIC_USE_V2_CHAT` unset, web writes legacy `conversations/`-style paths that the deployed rules will reject. Clean-start makes the migration scripts moot — flip the flag ON everywhere at cutover and remove the legacy code path.
3. **P1 — Duplicate Stripe surface** (web `/api/stripe/*` vs functions `createCheckoutSession` + `stripeWebhook`): two checkout creators and two webhook handlers for one Stripe account; the Next.js one trusts client-supplied `userId`/`userEmail` (see Security). Also tier drift: `platinum_*` price IDs on the web route vs canonical `plan: 'free'|'plus'`.
4. **P2 — `functions/src/index.ts` is a 14,194-line monolith.** A decomposition plan already exists (Phase 9 `media_limits` extraction started). Continue extracting domains (auth/otp, chat, discovery, subscription, safety, notifications) — improves cold start (smaller bundles per function group is a later step), reviewability, and test isolation. Don't block launch on it.
5. **P2 — Message-create security rule is effectively dead code**: direct client `messages` creates require *both* users `isIdVerified == true`, but both mobile and web V2 send via the `sendMessage` callable (Admin SDK bypasses rules). Once V2 is confirmed everywhere, tighten direct create to `if false` to shrink the attack surface; today the dual path invites drift.
6. **P3 — Recommendation service duplicated and unowned**: root copy vs `Crush App/` copy with diverged `index.js`, plus a stray `node_modules 2/` folder. Decide if it ships at launch; keep exactly one copy (suggest repo root), document deploy target (Cloud Run), or delete.
7. Models/consistency: canonical nested `profile.*` with legacy flat keys blocked by rules on create/update (`legacyFlatProfileKeys()` guard) — good. Entitlement derived from `plan` — good. Field-name parity is contract-tested on web. No collection-name mismatches found in current code.

---

## 5. Frontend / UI Problems Found

- Mobile design system (`lib/design_system/` tokens + glass widgets) is consistent; web mirrors tokens with a parity unit test. Light/dark/system supported on both.
- Uncommitted work in progress: floating-pill bottom nav redesign (`glass_bottom_nav_bar.dart`, tests pass), `web/index.html`/`manifest.json` renamed to "Crush App". Commit or revert before cutover so the release baseline is clean.
- Unknown-route page (Routing #1) is the main UX hole.
- Empty/loading/error states: deep-link loaders have explicit loading + error scaffolds; web has error components and `getAuthErrorMessage` mapping. Verify empty states for likes/matches/messages on web during the staging pass (axe/keyboard/responsive specs exist but the authenticated E2E lane hasn't run — gate item ⏳).
- Accessibility: mobile has `DsTextScaleCap`, semantics helpers, a11y TODO docs; web has axe/keyboard specs gated on the E2E lane. Device-matrix sign-off (VoiceOver/TalkBack/iPad) is an open operational gate.
- i18n: web locale switcher exists but only en/es/ar vs mobile's 21 — fine for launch, flag as known gap.

## 6. State Management Problems Found

- Mobile: **uniformly BLoC/Cubit** + repository interfaces; composition root `CrushDI.buildRepositories()/buildBlocs()` in `lib/core/di.dart`; router refresh via `GoRouterRefreshStream(authBloc.stream)`; `app.dart` cancels all stream subscriptions in `dispose()` and debounces foreground refresh. No mixed patterns, no GetX/Riverpod残留. ✅
- Web: **uniformly Zustand** stores backed by services in `packages/core`. The only structural risk is the dual legacy/V2 store paths in `stores/match.ts` / `stores/message.ts` — resolved by flipping the flag and deleting legacy (P1 above).
- `BackendMode` default is `firebase`; stub/hybrid modes are test/dev-only with explicit setters. The old "dummy profiles in production" finding is fixed. ✅
- One residue: `lib/presentation/` (home screen, test video screen) sits outside the `features/` convention, and root-level `lib/data/models` holds shared models — acceptable, but fold `presentation/screens/test/` into dev-only code. **P3**

## 7. Security Risks Found

| # | Risk | Severity | Evidence | Fix |
|---|---|---|---|---|
| 1 | **Web session cookie is never verified.** `/api/auth/session` sets any client-supplied string as the HttpOnly `auth-token` cookie (no `verifyIdToken`); middleware checks only cookie *presence*; `/api` routes are excluded from middleware entirely. `/api/stripe/create-checkout-session` then trusts `userId`/`userEmail` from the request body → forged checkout sessions / entitlement attached to arbitrary UIDs via the webhook | **Critical (web)** | `apps/web/src/app/api/auth/session/route.ts:62-77`, `middleware.ts` matcher, `api/stripe/create-checkout-session/route.ts:43-50` | Use Firebase **session cookies**: `adminAuth.createSessionCookie()` on POST (verify the ID token first), verify the cookie in API routes (Admin SDK) and ideally in middleware (edge JWT verification); derive `userId`/`email` server-side from the verified token, never from the body |
| 2 | **Firebase Admin SDK private key exposed** (already flagged in `ai_workboard.md` as rotation-required; file sits in `Credentials/crush-f5352-firebase-adminsdk-*.json`) | **Critical** | Workboard 2026-06-09 entry; file on disk | Rotate in console **before** first production deploy; add new key only to Vercel env; never store the live key in `Credentials/` |
| 3 | Plaintext keystore backup (`crushhour-keystore-backup.txt` beside `crushhour-release.keystore`), Apple `.p8` push key, certs all in one unencrypted folder | High | `Credentials/` listing | Move secrets to a password manager / encrypted store; keep only public config (plists/json) on disk; verify folder can never be committed |
| 4 | App Check enforced by backend but not yet configured for `crush-f5352` (no site keys/attestation registered) — at cutover, *either* everything is blocked *or* enforcement gets disabled and forgotten | High | AGENTS.md App Check matrix; new project state | Register providers at cutover; enforce in staging; verify callables fail without tokens, then enable enforcement in prod |
| 5 | Stripe duplication (finding 4.3) — second unverified checkout path + possibility of two webhook endpoints | High | see above | Single canonical path (functions); delete the rest |
| 6 | Direct-write message rule path unused but live (4.5) | Medium | `firestore.rules:214-235` | Tighten to `if false` post-V2 |
| 7 | `/test-agora` + `TestVideoScreen` in release builds | Medium | `router.dart:208` | `kDebugMode` gate |
| 8 | Old project `crush-265f7` in `DELETE_REQUESTED`; stale references confined to historical docs + `AUDIT_REPORT.md:135` | Low | workboard scan | Archive `AUDIT_REPORT.md` as historical |
| 9 | `.env` (Agora) is gitignored and untracked ✅; no hardcoded secrets found in `functions/src`, web `src`, or `packages/core` (grep for `sk_live|sk_test|whsec_|AIza`) ✅ | — | — | Keep Agora creds via `--dart-define`/CI as documented |

## 8. Performance Issues Found

- **Functions monolith** (4.4): one giant bundle per function deployment → slower cold starts; decomposition plan exists.
- **Chat deep link O(n) match fetch** (Routing #4).
- Flutter web initial bundle is heavy by nature — another reason to make Next.js the only public web app (it has route-level code splitting + Lighthouse evidence from `docs/reports/lighthouse/2026-02-23-phase9`).
- Pagination/rate-limit audits exist (`api_pagination_ratelimit_audit_2026-05-30.md`) and were implemented; web rate limiter degrades to per-instance in-memory when Redis env is absent — set Upstash/Redis env in production so limits are real across serverless instances. **P2**
- Realtime listeners: mobile cancels subscriptions on dispose; `REALTIME_OBSERVABILITY.md` covers listener budgets. No leak patterns found in spot checks.
- Re-verify Lighthouse + image optimization on the production domain after cutover (old numbers predate the domain/deployment change).

## 9. Duplicate / Unused Files List

Safe-to-delete (verified unreferenced by code; all are artifacts/logs/one-off scripts at `Crush App/` root):
`analyze.txt`, `analyze_out.txt`, `analyze_errors.txt`, `a11y_analyze.txt`, `coverage_logic_lowest_raw.txt`, `hardcoded_strings.txt`, `flutter_01.log`, `firestore-debug.log`, `mass_replace.js`, `mass_replace2.js`, `fix_plans.js`, `test-agora.js`, `crushhour.iml`, `Crush_Hour.iml`, `my_first_project.iml`.
Decide-then-delete: duplicated `crushhour-recommendation-service` (keep one), its `node_modules 2/` folder, `AUDIT_REPORT.md` (archive to `docs/reports/` as historical), Flutter-web Vercel project (`Crush App/.vercel`, `vercel.json`) if Next.js wins the web decision, and the V2-migration scripts (`apps/web/scripts/migrate-*.mjs`) once clean-start launch makes them moot.
Keep: everything under `docs/` (institutional memory), stub repositories (used by tests/dev modes).

## 10. Clean Architecture Plan

Both apps already match the target architecture; do **not** restructure. Remaining moves:

- Mobile: `features/<domain>/{presentation,domain,data}` + `core/` + `design_system/` is in place. Fold `lib/presentation/` leftovers into `features/home` and dev-only code; keep `CrushRoutes` as the single route source.
- Web: `packages/core` (services/api/stores) + `apps/web` (routes/components) is in place. Delete legacy chat/match path post-flag-flip so each store has one backend.
- Functions: continue the existing extraction plan — `src/{auth,chat,discovery,profile,subscription,safety,notifications,calls}/` modules re-exported from a thin `index.ts`.
- Contracts: `docs/reports/shared_backend_contract_matrix_2026-06-05.md` remains the cross-platform source of truth; keep updating it with any callable change.

## 11. Step-by-Step Refactor Roadmap

- **Phase 1 — Commit the baseline (today, zero risk).** Commit/revert dirty files in both repos (nav pill + manifest rename + runbook; web script/test tweaks). Delete the §9 junk list. Test: `flutter analyze` + nav-bar test (already passing), `vitest`.
- **Phase 2 — Backend cutover (the P0; operations).** Execute the runbook (§4.1). Rotate the Admin key first (§7.2). Risk: medium (console/billing work); everything is scripted. Test: `/api/health`, emulator-less smoke — sign up, onboard, swipe, match, chat on staging web + a debug mobile build.
- **Phase 3 — Web auth/session hardening (P1, ~1-2 days).** Firebase session cookies + server-side verification + body-trust removal in checkout; single Stripe path; flip `NEXT_PUBLIC_USE_V2_CHAT=true`. Files: `api/auth/session/route.ts`, `api/auth/activity/route.ts`, `middleware.ts`, `api/stripe/*`, `premium-view.tsx`, env. Risk: medium (auth-critical) — add vitest contract tests for the session route; manual login/logout/refresh/timeout pass.
- **Phase 4 — Routing polish (P2, hours).** NotFound screen + `kDebugMode` gate on `/test-agora` (mobile); decide and execute the single-web-app decision. Test: unknown-URL manual checks, route manifest tests.
- **Phase 5 — Legacy removal (P2).** Delete web legacy chat/match path per the removal manifest; tighten message-create rule to `if false`; remove migration scripts. Test: rules emulator suite (77 tests) + web chat E2E.
- **Phase 6 — Functions decomposition + perf (P3, ongoing).** Extract modules; add `fetchMatchById`; Redis rate-limit env; re-run Lighthouse on prod domain.
- **Phase 7 — Operational gates (release).** Run the already-defined ⏳/📋 items in `infrastructure_release_evidence_checklist_2026-06-07.md`: authenticated Playwright lane, provider-sandbox subscription tests, App Check staging enforcement, device matrices, store compliance.

## 12. Testing Checklist

Automated (all runnable now): `flutter analyze` ✅0 · `flutter test` (278 files) · functions `npm test` (205) · firestore-tests (77 rules tests) · web `vitest` ✅256 · web/core `tsc` ✅ · eslint lanes · parity guards (`check_firestore_rules_sync.sh`, deprecated-domain guard).
Post-cutover staging smoke (mobile + web, same checklist): signup (email/Google/phone) → verify → onboarding completion → discovery deck loads real users → like/dislike → match notification → chat send/receive/read/edit/unsend → media upload (photo profile + chat image) → report/block → unmatch → subscription purchase/cancel (sandbox) → entitlement reflects on both platforms → settings (notifications, privacy, discovery prefs, blocked list) → account deletion request + grace cancel → logout/login → browser refresh on every web route → deep links (`/messages/:id`, notification taps) → theme switch → offline behavior.
Provider sandboxes: Stripe (web), StoreKit sandbox (iOS), Play Billing test track (Android) — purchase→renew→cancel→expire→restore.

## 13. Deployment Checklist

1. Rotate Admin SDK key; store nowhere on disk. 2. Firestore create + rules/indexes/database deploy. 3. Auth providers (Google/Phone/Apple) + authorized domains. 4. Blaze upgrade → deploy functions + storage rules. 5. Functions secrets (Stripe keys, webhook secret, Agora cert, email provider). 6. Stripe: products/prices for `plus_*`, single webhook → chosen endpoint, test mode first. 7. App Check: reCAPTCHA Enterprise key (web), Play Integrity + App Attest (mobile); staging enforce → prod enforce. 8. FCM: web VAPID key, APNs .p8 upload. 9. Vercel (`crush-web`): env verify, Admin JSON, Redis env, `vercel --prod`, `/api/health`. 10. Domain decision executed (crush.app canonical per domain matrix), old Flutter-web deployment retired or fenced. 11. Mobile builds against prod: TestFlight + Play internal track. 12. Monitoring: Crashlytics/Sentry, Functions error alerting, billing budget alert on Blaze. 13. Record evidence in `PRODUCTION_CUTOVER_TICKET_TEMPLATE.md`.

## 14. Change Log Format

Use the existing repo convention (AGENTS.md §7): every task logged in `docs/Developer_agent_chat.md` (request → refined prompt → status → outcome: files + verification + next step) and `docs/ai_workboard.md` (goal/scope, key changes, decisions, risks, verification). For each change record: file(s), what/why, risk level, how to test, affects mobile/web/both. The docs-sync guard (`scripts/check_ai_docs_sync.sh`) already enforces this on commit.

## 15. Priority Action List

| # | Priority | Action |
|---|---|---|
| 1 | **P0** | Execute the Firebase/Vercel cutover runbook — create Firestore, deploy rules/indexes, enable auth providers, Blaze, deploy functions+storage, Vercel env + redeploy |
| 2 | **P1** | Rotate the exposed Firebase Admin key before any deploy |
| 3 | **P1** | Web session-cookie verification (Firebase session cookies; verify in API routes; stop trusting body `userId`) |
| 4 | **P1** | Single Stripe path (functions canonical); fix tier drift; one webhook |
| 5 | **P1** | `NEXT_PUBLIC_USE_V2_CHAT=true` everywhere at cutover (clean DB ⇒ no migration needed) |
| 6 | **P1** | App Check + FCM/APNs configuration for the new project |
| 7 | **P2** | One public web app decision (Next.js); retire Flutter-web Vercel deployment |
| 8 | **P2** | NotFound route page; `kDebugMode`-gate `/test-agora` |
| 9 | **P2** | Delete legacy web chat/match path + tighten message rules post-V2 |
| 10 | **P2** | Production Redis for web rate limits |
| 11 | **P3** | Junk-file cleanup (§9); dedupe recommendation service; archive stale `AUDIT_REPORT.md` |
| 12 | **P3** | Functions decomposition; `fetchMatchById`; Lighthouse re-run; web locale expansion |
