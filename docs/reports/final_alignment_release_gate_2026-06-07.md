# Final Alignment Release Gate (Phase 9 Step 22)

- Date: 2026-06-07
- Purpose: the capstone gate for the web–mobile alignment program. Records what
  is **verified locally now** vs what is **operational** (needs deployed staging,
  credentials, real devices, or live provider sandboxes — all itemized in
  `infrastructure_release_evidence_checklist_2026-06-07.md`).
- Legend: ✅ pass (run this date) · ⏳ operational (gated, see hand-off) · 📋 evidence to record at release.

## A. Automated gates — verified locally (2026-06-07)

| Gate | Command | Result |
|---|---|---|
| Functions build | `functions: tsc` | ✅ clean |
| Functions lint | `functions: eslint` | ✅ clean |
| Functions tests | `functions: npm test` (per-file isolated) | ✅ **205 passing / 0 failing** (was 146/59 — see §C) |
| Web lint | `apps/web: eslint --max-warnings=0` | ✅ clean |
| Web typecheck | `apps/web: tsc --noEmit` | ✅ clean |
| Web unit tests | `apps/web: vitest run` | ✅ **256 passing** (25 files) |
| Core lint + typecheck | `packages/core` | ✅ clean |
| Firestore rules emulator | `firestore-tests: npm test` | ✅ **77 passing** |
| Firestore rules parity guard | `check_firestore_rules_sync.sh` | ✅ in sync |
| Deprecated-domain guard | `check-deprecated-domains.mjs` | ✅ clean |
| Docs-sync guard | `check_ai_docs_sync.sh` | ✅ passes on each commit |

## B. Cross-cutting validations — status

| Item | Status | Reference |
|---|---|---|
| App Check + CSP | code ✅ / staging enforcement ⏳ | Phase 2; hand-off §1 |
| Routes (manifest ↔ filesystem, notif routes) | ✅ tests | `route_manifest_2026-06-07.md` |
| Domains (crush.app canonical, guard) | code ✅ / infra cutover ⏳ | `domain_deployment_decision_2026-06-07.md`; hand-off §4 |
| Shared backend contracts (auth/entitlement/notifications/profile/calls) | ✅ documented + tests | `shared_backend_contract_matrix_*`, Phase 7/9 contracts |
| Accessibility automation (axe/keyboard/responsive) | code ✅ / E2E-lane run ⏳ / device matrix 📋 | `accessibility_responsive_validation_2026-06-07.md` |
| Localization (provider/switcher/es+ar/E2E) | ✅ code + unit / E2E-lane run ⏳ | `web_localization_2026-06-07.md` |
| Profile/settings parity | ✅ matrix + photo-cap fix + parity test | `profile_settings_capability_matrix_2026-06-07.md` |

## C. The 59 functions failures — RESOLVED (test-harness fix)
**Root cause (diagnosed + fixed 2026-06-07):** cross-file test pollution, NOT a
product bug. Six integration suites mutate the shared `firebase-admin` singleton
(`admin.auth/firestore/storage`) at module load; under one `mocha` process the
LAST-loaded stub won for the whole run, so earlier suites (`chatAuthz`,
`chatRestPagination`, `callRestRateLimit`, `profileRestEndpoints`) ran against the
wrong mock → uniform "Invalid token" → 401 (~57 failures). The remaining 2 were a
**stale test** in `profileRestEndpoints` (asserted the legacy top-level
`preferences` dual-write; the handler now canonically deletes that mirror via
`deleteField()`, which the mock didn't model).

**Fixes (test-harness only — zero product-code changes):**
1. `test/run-isolated.js` runs each test file in its own process (fresh module
   registry → no singleton pollution); wired into `npm test` (old recursive run
   kept as `npm run test:shared`).
2. `profileRestEndpoints`: added a `FieldValue.delete` sentinel the mock `update()`
   honors, and updated 2 assertions to the canonical "legacy mirror removed"
   contract.
3. `profileCompleteness` + `profileRestValidation`: made self-sufficient via the
   `FIREBASE_CONFIG` demo-project env pattern so they load `../lib/index` in
   isolation.

**Result:** `npm test` → **205 passing / 0 failing** across 23 files (was 146/59).
No product behavior changed.

## D. Operational gates — required for production sign-off (⏳ / 📋)
All itemized with owners/commands/acceptance in
`infrastructure_release_evidence_checklist_2026-06-07.md`:
- ⏳ Authenticated web E2E lane (Playwright + Firestore emulator): runs
  `a11y-authenticated`, `a11y-interaction`, `responsive`, `visual`, `i18n`,
  `app-flow`, `auth*` specs; generate + commit visual baselines on the CI OS.
- 📋 Cross-platform **discovery → match → chat → safety** flow (web + mobile
  against staging) — mobile e2e exists
  (`test/e2e_onboarding_discovery_chat_safety_flow_test.dart`); record the
  cross-platform run.
- 📋 Subscription + account-lifecycle tests in provider sandboxes (Stripe/Apple/
  Google): purchase→renew→cancel→expire→restore; deletion grace + data export.
- 📋 App Check enforced in staging (callables/REST succeed with, fail without; no
  CSP violations).
- 📋 Accessibility device matrix + calls device matrix signed off
  (VoiceOver/TalkBack/iPad/external-kbd; PushKit/CallKit/PiP/reconnect).
- 📋 Data migrations executed + verified (flat-profile + chat/match cutover);
  V2 enabled; legacy removed.
- 📋 Migration, deployment, rollback, monitoring, and **production evidence**
  recorded in the release ticket (runbooks:
  `chat_match_cutover_runbook_2026-06-07.md`,
  `legacy_chat_match_removal_manifest_2026-06-07.md`).

## E. Gate decision
- **Engineering gate (local automated):** ✅ **GREEN** — all local lanes pass,
  including the functions suite (205/0 after the §C test-harness fix). No known
  failing tests remain locally.
- **Release gate (production):** ⏳ NOT yet — blocked only on the operational
  items in §D (staging, credentials, devices, provider sandboxes, production
  evidence). The codebase changes for the entire alignment program (Phases 0–9)
  are complete, verified locally, and pushed.
