# Crush Parity Restoration Report (Pass 1 through Pass 28)
Date: 2026-03-11
Owner: Codex
Scope: Flutter mobile + Flutter web shell + Firebase rules + Cloud Functions integration points

## Executive Summary
- CRUSH mobile app and webapp are primarily a single shared Flutter codebase (`lib/`), which gives strong baseline feature parity.
- Highest-risk parity drifts were found in configuration and backend rule maintenance, not core UI feature implementations.
- This pass implemented immediate fixes for:
  - Environment key drift (`API_BASE_URL` vs `CRUSH_API_BASE_URL`, `USE_EMULATORS` vs `USE_FIREBASE_EMULATOR`)
  - Firestore rules file drift risk between root and `functions/`
  - Support content parity issues previously reported in runtime UX
  - Canonical user schema migration safeguards for nested profile fields (`birthDate`, `preferences`, `privacySettings`, `favourites`)
  - Deep-link ownership consolidation through shared runtime handler contract (including auth-required pending-link processing)
  - App-shell deep-link navigation callback wiring and expanded auth-transition coverage across chat/profile/settings/support routes
  - Release go/no-go runbook criteria tied to env-alias migration audit artifacts (`Checkpoint status`, `Allowlist guard status`, and pass-marker evidence)
  - Release ticket/template contract enforcement for exact dated env-alias audit artifact references
  - Ticket scaffolding helper for prefilled dated cutover artifacts to reduce manual release-entry drift
  - Release-ref/tag CI gate to require concrete cutover ticket validation during release pipelines
  - Script-level regression tests for release-ref gate ref matching and ticket-path resolution behavior
  - Script-level invalid-input regression tests for scaffold/contract release-ticket scripts
  - Release-ref gate fallback-no-ticket regression coverage when no `PRODUCTION_CUTOVER_*.md` files are resolvable
  - Release-ref gate regression coverage for `GITHUB_REF` unset behavior and path-over-glob precedence
  - Release-ref path-precedence failure regression coverage (invalid explicit path overrides valid glob fallback)
- Remaining major parity risks are concentrated in:
  - residual dual-shape read compatibility paths (migration tail)
  - long-tail naming/copy consistency monitoring (`Crush`, intentional `wordCrush` noun keys, legal `CrushHour Inc.` entity references)

## Parity Matrix
| Domain | Status | Evidence (App) | Evidence (Web) | Notes |
|---|---|---|---|---|
| Architecture layering | Partially aligned | `lib/features/*/{data,domain,presentation}` | same codepath | Shared structure is strong; duplicated utility/config surfaces still exist |
| Routing/navigation | Fully aligned (core) -> hardened this pass | `lib/core/router.dart`, `lib/core/routing/*`, `lib/core/deep_link_bootstrap.dart`, `lib/app.dart` | same router on web | Deep-link handler contract is consolidated, app-shell callback is wired, and auth-transition integration regressions cover chat/profile/settings/support |
| Auth/session | Fully aligned (core) | `lib/features/auth/**`, `lib/core/session/session_bootstrap_service.dart` | same logic | Platform-specific sign-in button exposure differs by policy |
| Onboarding/profile completion | Fully aligned (core) | `lib/features/profile/presentation/screens/profile_setup_screen.dart` | same logic | Keyboard/runtime UX fixes already applied in prior tasks |
| Discovery/matching | Fully aligned (core) | `lib/features/discovery/**` | same logic | Same repository + bloc flows |
| Messaging/chat | Fully aligned (core) | `lib/features/chat/**` | same logic | Same domain/repo layers |
| Notifications | Partially aligned (expected platform diff) | `lib/core/services/push_notification_service.dart` | browser/web constraints | Push capabilities differ by platform; UX contract should be documented |
| Subscription/monetization | Partially aligned (expected platform diff) | native store handling in `lib/features/subscription/data/repositories/impl/firebase_subscription_repository.dart` | web checkout/restore patterns | Entitlement model shared; purchase rails differ by platform |
| Support/help UX | Fully aligned after fixes | `lib/config/support_config.dart`, support screens | same shared UI | Q&A + label parity fixes landed |
| Config/env management | Mostly aligned -> hardened in Pass 15 | `lib/config/app_config.dart`, `lib/core/app_env.dart`, `lib/core/firebase_emulator.dart` | same build defines | Canonical flavor resolution + legacy fallback compatibility + regression coverage |
| Firestore/storage security rules | Partially aligned -> improved this pass | root `firestore.rules`, `storage.rules` | same backend rules | Duplicate function-level rules drift was mitigated |
| Analytics events | Mostly aligned | `lib/core/services/analytics_service.dart` | same event service | Platform-triggered events can still vary where OS capability differs |

## Critical Issues
### C1. Firestore Rules Drift Across Two Rule Files (Fixed)
- What exists in app: canonical Firestore rules at `firestore.rules`.
- What exists in web: same backend contract expected.
- Difference: `functions/firestore.rules` had older permissive/legacy logic divergent from root file.
- Risk: high security/config drift risk during maintenance and local validation.
- Recommended fix: keep files synchronized and enforce guard script.
- Files affected:
  - `firestore.rules`
  - `functions/firestore.rules`
  - `scripts/check_firestore_rules_sync.sh`
- How to verify:
  - `scripts/check_firestore_rules_sync.sh`

### C2. Legacy Nested-vs-Flat User Data Semantics (Partially Mitigated)
- What exists in app: auth repository now canonicalizes legacy user documents into nested profile shape during reads and schedules cleanup writes.
- What exists in web: same shared Flutter auth repository behavior on web runtime.
- Difference: server and rules still keep legacy read compatibility during migration window.
- Risk: medium (reduced from high) while compatibility paths remain.
- Recommended fix: complete migration telemetry + cutoff to remove legacy read fallbacks.
- Files affected:
  - `firestore.rules`
  - `functions/firestore.rules`
  - `functions/src/index.ts`
  - `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`
  - `lib/core/schema/user_document_schema.dart`
- How to verify:
  - `flutter test test/core/schema/user_document_schema_test.dart`
  - `npm --prefix functions run build`
  - production sample query validation on user docs

### C3. Deep-Link Contract Consolidation (Mitigated)
- What exists in app: `DeepLinkBootstrap` now delegates all route deep-link decisions to shared `DeepLinkHandler` contract from `lib/core/routing/deep_links.dart`.
- What exists in web: same shared bootstrap and handler behavior.
- Difference: no behavioral split for route deep-link auth gating; pending auth-required links are now queued and resumed after authentication.
- Risk: low (reduced from medium) with remaining risk limited to broader app-level integration permutations.
- Recommended fix: keep integration coverage green in CI and extend only if new deep-link routes are introduced.
- Files affected:
  - `lib/core/deep_link_bootstrap.dart`
  - `lib/core/routing/deep_links.dart`
  - `test/core/deep_link_bootstrap_test.dart`
  - `test/core/routing/deep_links_test.dart`
  - `test/core/deep_link_auth_transition_integration_test.dart`
  - `lib/app.dart`
- How to verify:
  - `flutter test test/core/deep_link_bootstrap_test.dart test/core/routing/deep_links_test.dart test/core/deep_link_auth_transition_integration_test.dart`

## Architecture Issues
- Config entry points are now partially rationalized:
  - `lib/config/app_config.dart` is canonical for flavor/env-key precedence.
  - `lib/core/app_env.dart` derives mode from canonical `AppConfig.flavor`.
  - `lib/core/config/env_config.dart` remains separate for SMTP secure runtime credentials.
- Duplicate backend rules artifact:
  - root and `functions/` rules files (now synchronized but still two copies)
- Deep-link flow is consolidated through shared handler contract; keep integration coverage expanding for more route permutations.

## Feature Mismatches
### Support
- App: support categories + category detail with expandable Q&A.
- Web: same shared screens.
- Difference: previously missing Q&A and label drift; fixed.
- Files:
  - `lib/config/support_config.dart`
  - `lib/features/settings/presentation/screens/support_category_detail_screen.dart`

### Profile route/deep-link load
- App: self-profile route now bypasses remote loader.
- Web: same route path now avoids endless spinner case for own profile.
- Difference: previously web could hang on `Loading profile...`; fixed in prior task.
- Files:
  - `lib/core/router.dart`

### Config naming
- App: mixed env keys across modules.
- Web: same build/runtime config path.
- Difference: env key drift plus flavor/mode default drift (`FLAVOR` vs `APP_ENV`) caused avoidable setup mismatches; now fixed with canonical resolution + compatibility fallback.
- Files:
  - `lib/config/app_config.dart`
  - `lib/core/app_env.dart`
  - `lib/core/firebase_emulator.dart`
  - `lib/data/repositories/fake_repositories.dart`

## Storage Rules and Security Review
- Firestore rules are restrictive for protected collections (`usernames`, `auth_*`, server-managed writes on `matches` etc.).
- Storage rules enforce content-type and size limits for user media and block sensitive paths.
- Key observation:
  - security model assumes server-managed writes for critical entities, but still includes compatibility logic for mixed profile document shapes.
- Action implemented this pass:
  - synchronized `functions/firestore.rules` with canonical root rules and added drift guard script.

## Navigation and Routing Review
- Route constants are centralized in `lib/core/routing/crush_routes.dart`.
- Redirect policy is centralized and testable in `lib/core/routing/route_redirect.dart`.
- Main mismatch area:
  - deep-link ownership is still split between parser + bootstrap modules, though runtime wiring is now in place.
- Previous parity bug already fixed:
  - self profile deep-link route no longer stalls in loader (`lib/core/router.dart`).

## UI/UX Consistency Review
- Shared Flutter UI gives strong baseline parity across app/web.
- Fixed parity copy/content issues:
  - support category labels now match required wording
  - support Q&A now populated and interaction works on tap
- Remaining copy parity risk:
  - high-traffic runtime and legal surfaces are normalized.
  - residual tail is mostly intentional/non-brand vocabulary (`wordCrush`) and future-copy regression prevention.

## Analytics and Event Consistency Review
- Event dispatch is centralized in `lib/core/services/analytics_service.dart`, which supports parity.
- Expected divergence remains where platform capabilities differ (push permissions, tracking consent).
- Recommendation:
  - add explicit parity assertions on event name/payload for key funnel actions in widget/integration tests.

## Dead Code and Cleanup Review
- Candidate duplicated assets:
  - deep-link logic split across parser/bootstrap modules (now integrated, cleanup still pending)
  - duplicate Firestore rule file in `functions/` (kept but now synchronized and guarded)

## Implemented Fixes
1. Config env parity normalization
- `lib/data/repositories/fake_repositories.dart`
  - Added fallback resolution to prefer `API_BASE_URL` and support legacy `CRUSH_API_BASE_URL`.
- `lib/core/firebase_emulator.dart`
  - Added compatibility for both `USE_FIREBASE_EMULATOR` and `USE_EMULATORS`.
  - Added compatibility for both `FIREBASE_EMULATOR_HOST` and `EMULATOR_HOST`.

2. Rules parity safeguard
- Synced `functions/firestore.rules` with canonical `firestore.rules`.
- Added `scripts/check_firestore_rules_sync.sh`.

3. Deep-link parity hardening
- `lib/core/deep_link_bootstrap.dart`
  - Wired runtime deep-link handling into `DeepLinkConfig.parse(...)`.
  - Added navigation callback path + router fallback navigation.
- `lib/core/routing/deep_links.dart`
  - Added parsing support for `/user-profile/:userId`.
  - Added parsing support for `/support/category/:categoryId`.
- Added tests:
  - `test/core/deep_link_bootstrap_test.dart` (navigation deep-link regression)
  - `test/core/routing/deep_links_test.dart` (parser coverage for user-profile/support/share-link)

4. Canonical user schema parity hardening (Pass 3)
- `lib/core/schema/user_document_schema.dart`
  - Added canonicalization helper for legacy flat-to-nested profile migration.
  - Added `birthDate` normalization and cleanup of nested `dateOfBirth` legacy key.
- `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`
  - Reads now canonicalize user docs and persist background cleanup updates.
  - Profile DOB parsing now supports canonical `birthDate` with legacy fallback.
- `firestore.rules` + `functions/firestore.rules`
  - Block new/changed legacy flat profile writes on `/users/{uid}` create/update.
- `functions/src/index.ts`
  - `/v1/profile/preferences` now removes legacy top-level `preferences` mirror after updating `profile.preferences`.
- Added tests:
  - `test/core/schema/user_document_schema_test.dart`

5. Deep-link ownership consolidation (Pass 4)
- `lib/core/deep_link_bootstrap.dart`
  - Replaced ad-hoc route deep-link navigation with shared `DeepLinkHandler`.
  - Added auth-state stream processing to replay pending auth-required deep links after login.
- `lib/core/routing/deep_links.dart`
  - Reduced coupling by using direct `crush_routes.dart` import.
- Added tests:
  - `test/core/deep_link_bootstrap_test.dart` (auth-required pending-link replay)
  - `test/core/routing/deep_links_test.dart` (handler pending-link behavior)

6. Deep-link auth-transition integration hardening (Pass 5)
- `lib/core/deep_link_bootstrap.dart`
  - Moved auth-status stream binding to `didChangeDependencies` to avoid context/provider timing misses.
- Added tests:
  - `test/core/deep_link_auth_transition_integration_test.dart` (bootstrap + auth + router pending-link replay)

7. App-shell deep-link callback wiring + route permutation coverage (Pass 6)
- `lib/app.dart`
  - Passed `onNavigate` callback to `DeepLinkBootstrap` using `_router.go(...)` so parsed deep links always resolve through router in runtime.
- `test/core/deep_link_auth_transition_integration_test.dart`
  - Expanded integration coverage to auth transitions for `/chat/:id`, `/user-profile/:id`, `/settings`, and unauth public `/support/category/:id`.

8. Schema migration telemetry + fallback cutoff control (Pass 7)
- `functions/src/index.ts`
  - Added `PROFILE_PREFERENCES_LEGACY_FALLBACK_CUTOFF` runtime param (default `2026-06-30T00:00:00.000Z`).
  - Added structured legacy fallback telemetry logs:
    - `legacy_profile_preferences_fallback_read`
    - `legacy_profile_preferences_fallback_blocked_after_cutoff`
  - Wired route source + uid context for fallback telemetry from profile/discovery endpoints.
  - Enforced cutoff behavior: legacy top-level `preferences` fallback returns empty object after cutoff.
- `functions/test/profileRestValidation.test.js`
  - Added deterministic helper regression tests for pre-cutoff fallback, post-cutoff block, and nested-preferences priority.

9. Firestore rules CI parity guard (Pass 8)
- `.github/workflows/ci.yml`
  - Added mandatory CI step `Verify Firestore rules parity` running `scripts/check_firestore_rules_sync.sh`.
  - Prevents merge of drift between `firestore.rules` and `functions/firestore.rules`.

10. Branding copy normalization across app/web/backend runtime surfaces (Pass 9)
- `lib/app.dart`
  - Updated app title to `CRUSH`.
- `web/index.html`, `web/manifest.json`
  - Updated web shell metadata/manifest naming to `CRUSH`.
- `lib/config/support_config.dart`, `lib/features/settings/presentation/screens/support_screen.dart`, `lib/features/settings/presentation/screens/support_category_detail_screen.dart`
  - Normalized support runtime copy (`CRUSH Support`, `CRUSH Plus`, app-version label).
- `lib/core/services/data_export_service.dart`, `lib/features/settings/data/commands/default_account_action_commands.dart`
  - Normalized data-export share copy to `CRUSH`.
- `functions/src/index.ts`, `functions/src/calls/signaling.ts`
  - Normalized high-visibility transactional copy in emails/push labels to `CRUSH`.

11. Localization brand normalization + codegen sync (Pass 10)
- `lib/l10n/app_*.arb`
  - Normalized localized brand tokens to `CRUSH` across 22 locale files.
  - Preserved key names and kept noun-style `wordCrush` entries unchanged.
- `lib/l10n/generated/*`
  - Regenerated localization outputs with `flutter gen-l10n` to keep runtime strings aligned.

12. Legal copy branding hardening + regression coverage (Pass 11)
- `lib/presentation/screens/terms_of_service_screen.dart`, `lib/presentation/screens/privacy_policy_screen.dart`
  - Normalized legal-screen product references to `CRUSH` while preserving `CrushHour Inc.` legal-entity wording.
- `lib/config/legal_config.dart`
  - Updated legal config comment branding to `CRUSH`.
- `test/presentation/screens/legal_branding_copy_test.dart`
  - Added widget regression coverage that enforces product/entity naming contract on legal screens.

13. Runtime non-legal branding sweep + regression coverage (Pass 12)
- `lib/presentation/widgets/plus_feature_gate.dart`, `lib/presentation/screens/safety_screen.dart`, `lib/presentation/screens/community_guidelines_screen.dart`, `lib/presentation/screens/home/settings_screen.dart`, `lib/main.dart`, `lib/features/about/presentation/screens/pricing_screen.dart`, `lib/features/about/presentation/screens/product_features_screen.dart`, `lib/features/discovery/presentation/widgets/deck_screen_app_bar.dart`, `lib/features/discovery/presentation/screens/likes_you_screen.dart`, `lib/features/settings/presentation/screens/appearance_settings_screen.dart`, `lib/features/auth/presentation/bloc/biometric_cubit.dart`, `lib/features/auth/presentation/widgets/biometric_prompt.dart`, `lib/features/auth/presentation/screens/pin_fallback_screen.dart`, `lib/features/auth/presentation/screens/email_auth_screen.dart`, `lib/features/auth/presentation/screens/auth_gateway_screen.dart`, `lib/core/widgets/update_dialog.dart`, `lib/core/services/location_service.dart`, `lib/features/chat/presentation/screens/matches_screen.dart`, `lib/dev/widget_catalog/widget_catalog_screen.dart`
  - Normalized remaining high-traffic non-legal user-facing strings to `CRUSH`/`CRUSH Plus`/`CRUSH Premium`.
- `lib/core/config/env_config.dart`, `lib/core/services/app_update_service.dart`
  - Normalized default sender/app-name fallback values to `CRUSH`.
- `test/core/update_dialog_branding_test.dart`
  - Added widget regression tests for update-dialog default `CRUSH` branding copy.

14. Brand-case regression coverage expansion (Pass 13)
- `test/brand_copy_case_regression_test.dart`
  - Added localization casing checks for `en`, `zh`, and `yue` to enforce `Crush` title case and block uppercase brand regressions.
  - Added high-traffic runtime source casing checks for onboarding/discovery/premium prompts in:
    - `likes_you_screen.dart`
    - `matches_screen.dart`
    - `settings_screen.dart`
    - `welcome_tutorial_overlay.dart`
    - `appearance_settings_screen.dart`
    - `biometric_prompt.dart`
    - `main.dart`

15. Guarded-route + deep-link integration expansion (Pass 14)
- `lib/core/routing/route_redirect.dart`
  - Added explicit `isPublicUnauthRoute` handling so unauthenticated users can access public legal/support routes without being forced to auth.
- `test/router_redirect_test.dart`
  - Added coverage for unauth public legal/support route access and protection checks for unauth-only restricted routes.
- `test/core/routing/deep_links_test.dart`
  - Added parser coverage for `/match/:id`, `/premium`, `/upgrade`, and `/verify-email` query-preservation/fullPath behavior.
- `test/core/deep_link_auth_transition_integration_test.dart`
  - Added auth-replay integration cases for pending `/premium` -> `/settings` and `/match/:id` -> `/chat/:id`.

16. Config-surface rationalization + env precedence hardening (Pass 15)
- `lib/config/app_config.dart`
  - Added canonical flavor resolver: `FLAVOR` -> legacy `APP_ENV` -> fallback `development`.
  - Added alias normalization (`dev/development`, `prod/production`, `stage/staging`).
  - Aligned key precedence for:
    - `API_BASE_URL` -> `CRUSH_API_BASE_URL`
    - `USE_FIREBASE_EMULATOR` -> `USE_EMULATORS`
    - `FIREBASE_EMULATOR_HOST` -> `EMULATOR_HOST`
- `lib/core/app_env.dart`
  - Removed independent `APP_ENV` parsing and now derives dev/prod mode from canonical `AppConfig.flavor`.
  - Keeps strict safety mapping (`development` => dev, others => prod).
- `test/config/app_config_env_resolution_test.dart`
  - Added precedence/normalization fallback regression coverage for flavor resolution.
- `test/core/app_env_mode_resolution_test.dart`
  - Added regression coverage for flavor-to-mode mapping.

17. Config key matrix + release-script deprecation bridge (Pass 16)
- `docs/ENV_KEY_MATRIX.md`
  - Added canonical env-key contract and explicit deprecation dates for legacy aliases.
- `scripts/build_release.sh`
  - Added canonical `FLAVOR` normalization and fallback support for deprecated `APP_ENV` with warnings.
- `.env.example`
  - Updated emulator keys to canonical names and marked legacy aliases as deprecated.
- `docs/RELEASE_GUIDE.md`
  - Linked canonical env-key matrix and clarified legacy-key policy for release operations.

18. Deprecated env-alias CI/static allowlist guard (Pass 17)
- `scripts/check_deprecated_env_aliases.sh`
  - Added static guard to fail deprecated alias usage outside approved compatibility files.
  - Guard enforces alias policy for:
    - `APP_ENV`
    - `CRUSH_API_BASE_URL`
    - `USE_EMULATORS`
    - `EMULATOR_HOST`
- `.github/workflows/ci.yml`
  - Added Security job step to run `scripts/check_deprecated_env_aliases.sh`.
- `docs/ENV_KEY_MATRIX.md`
  - Added guardrail section referencing CI enforcement and approved exclusions.

19. Env-alias migration checkpoint automation (Pass 18)
- `scripts/check_env_alias_migration_status.sh`
  - Added operator migration checkpoint script that:
    - runs deprecated-alias allowlist guard,
    - verifies no active deprecated-alias emitters in machine-executed workflow/script paths,
    - enforces date-aware freeze/removal milestones (`2026-06-30`, `2026-09-30`).
- `.github/workflows/ci.yml`
  - Added Security job step to run `scripts/check_env_alias_migration_status.sh`.
- `scripts/check_deprecated_env_aliases.sh`
  - Updated exclusions to treat migration checkpoint script as approved policy file.
- `docs/ENV_KEY_MATRIX.md`, `docs/RELEASE_GUIDE.md`
  - Updated guardrails/release checklist to include migration checkpoint execution.

20. Env-alias migration audit artifact generation (Pass 19)
- `scripts/generate_env_alias_migration_audit_report.sh`
  - Added operator audit generator that writes dated migration artifacts:
    - `docs/reports/ENV_ALIAS_MIGRATION_AUDIT_YYYY-MM-DD.md`
  - Includes checkpoint and allowlist guard outputs in one report.
- `docs/reports/ENV_ALIAS_MIGRATION_AUDIT_2026-03-11.md`
  - Generated first dated migration audit artifact (PASS).
- `scripts/check_deprecated_env_aliases.sh`
  - Updated exclusions for audit generator policy script.
- `docs/ENV_KEY_MATRIX.md`, `docs/RELEASE_GUIDE.md`
  - Updated migration checklist and release checklist to require audit artifact generation.

21. Operator runbook go/no-go criteria for env-alias audit artifacts (Pass 20)
- `docs/RELEASE_GUIDE.md`
  - Added mandatory production runbook with explicit GO/NO-GO gates bound to Pass 19 artifact output:
    - `Checkpoint status: PASS`
    - `Allowlist guard status: PASS`
    - required output markers in checkpoint/allowlist sections.
- `docs/ENV_KEY_MATRIX.md`
  - Linked guardrail policy to the release runbook section to keep operator and policy docs aligned.
- `docs/risk_notes.md`
  - Updated `R-060` mitigation with explicit release gate requirements from the runbook.

22. Release ticket/template contract enforcement for env-alias audit evidence (Pass 21)
- `docs/PRODUCTION_CUTOVER_TICKET_TEMPLATE.md`
  - Added canonical production cutover ticket template with mandatory env-alias audit artifact and `PASS` status fields.
- `scripts/check_release_cutover_ticket_contract.sh`
  - Added validator that enforces:
    - template contract requirements,
    - exact dated artifact path format in concrete tickets,
    - required `PASS` statuses and artifact file existence.
- `.github/workflows/ci.yml`
  - Added Security check step to run `scripts/check_release_cutover_ticket_contract.sh` (template contract enforcement).
- `docs/RELEASE_GUIDE.md`, `docs/ENV_KEY_MATRIX.md`
  - Updated runbook and migration checklist to require concrete cutover ticket validation.

23. Cutover ticket scaffolding helper for dated artifact references (Pass 22)
- `scripts/create_production_cutover_ticket.sh`
  - Added helper to generate `docs/reports/PRODUCTION_CUTOVER_<date>.md` from template with:
    - prefilled `Cutover date (UTC)`,
    - prefilled dated env-alias audit artifact path,
    - prefilled audit evidence link field.
- `scripts/check_release_cutover_ticket_contract.sh`
  - Updated concrete-ticket validation to accept both `PASS` and `` `PASS` `` formatting for status fields.
- `docs/RELEASE_GUIDE.md`
  - Updated runbook commands to use scaffold helper before contract validation.
- `docs/ENV_KEY_MATRIX.md`, `docs/risk_notes.md`
  - Updated migration checklist/mitigations to include scaffold helper usage.

24. Release-ref/tag CI gate for concrete cutover ticket validation (Pass 23)
- `scripts/check_release_cutover_ticket_release_ref_gate.sh`
  - Added CI-oriented gate that:
    - detects release refs (release branches/tags),
    - resolves concrete cutover ticket path (override or latest report),
    - enforces concrete ticket validation via existing contract checker.
- `.github/workflows/ci.yml`
  - Extended push triggers to include release branches/tags.
  - Added Security step to run release-ref concrete ticket gate.
- `docs/RELEASE_GUIDE.md`, `docs/ENV_KEY_MATRIX.md`, `docs/risk_notes.md`
  - Updated runbook/guardrails/risk mitigation to document the release-ref gate behavior.

25. Release-ref gate script regression tests (Pass 24)
- `scripts/test_release_cutover_ticket_release_ref_gate.sh`
  - Added targeted script-level tests covering:
    - non-release ref skip behavior,
    - release branch/tag pass behavior with explicit ticket override,
    - fallback latest-ticket path resolution,
    - invalid override failure behavior.
- `.github/workflows/ci.yml`
  - Added Security step to execute release-ref gate regression tests.
- `docs/ENV_KEY_MATRIX.md`, `docs/risk_notes.md`
  - Updated guardrails/risk mitigation to include regression-test enforcement.

26. Invalid-input regression tests for cutover scaffold/contract scripts (Pass 25)
- `scripts/test_release_cutover_ticket_invalid_input_cases.sh`
  - Added script-level invalid-input coverage for:
    - scaffold script usage errors/invalid date/existing output failure,
    - contract script usage errors/missing ticket/missing artifact path/missing status failure.
- `.github/workflows/ci.yml`
  - Added Security step to execute invalid-input regression tests.
- `docs/ENV_KEY_MATRIX.md`, `docs/risk_notes.md`
  - Updated guardrails/risk mitigation to include invalid-input test enforcement.

27. Release-ref gate fallback-no-ticket regression coverage (Pass 26)
- `scripts/check_release_cutover_ticket_release_ref_gate.sh`
  - Added optional `RELEASE_CUTOVER_TICKET_GLOB` override to make fallback ticket-resolution behavior deterministic in test harnesses.
- `scripts/test_release_cutover_ticket_release_ref_gate.sh`
  - Added explicit failure-path coverage for release refs when no concrete `PRODUCTION_CUTOVER_*.md` files are resolvable.
- `docs/ENV_KEY_MATRIX.md`, `docs/risk_notes.md`
  - Updated guardrails/risk mitigation to document deterministic fallback-resolution testing support.

28. Release-ref gate unset-ref + override-precedence coverage (Pass 27)
- `scripts/test_release_cutover_ticket_release_ref_gate.sh`
  - Added explicit regression cases for:
    - `GITHUB_REF` unset skip behavior,
    - `RELEASE_CUTOVER_TICKET_PATH` precedence over `RELEASE_CUTOVER_TICKET_GLOB`.
- `docs/ENV_KEY_MATRIX.md`, `docs/risk_notes.md`
  - Updated guardrails/risk mitigation notes to document this added coverage.

29. Release-ref path-precedence failure semantics coverage (Pass 28)
- `scripts/test_release_cutover_ticket_release_ref_gate.sh`
  - Added explicit failure-path regression where:
    - `RELEASE_CUTOVER_TICKET_PATH` is invalid,
    - `RELEASE_CUTOVER_TICKET_GLOB` resolves a valid ticket,
    - gate still fails (path override precedence preserved).
- `docs/ENV_KEY_MATRIX.md`, `docs/risk_notes.md`
  - Updated guardrails/risk mitigation notes with path-precedence failure-semantics coverage.

30. Prior parity fixes already completed in this audit sequence
- Support Q&A content + tap-to-reveal behavior.
- Support category text alignment.
- Web profile deep-link loader hang fix for self-profile.

## Remaining Risks
- Low: legacy profile preference fallback is now telemetry-backed and time-bounded; residual risk is cutoff rollout execution.
- Low: deep-link flow now consolidated with expanded parser/guard/auth-replay permutation coverage; continue extending coverage for new routes.
- Low: core legal/runtime brand copy is normalized and regression-covered (now including onboarding/discovery/localization hotspots); residual risk is future-copy drift and intentional noun-key ambiguity.
- Low: legacy env aliases are still in compatibility mode until planned cutoff; risk is primarily rollout discipline across external pipelines.

## Recommended Next Actions
### Immediate (P0)
1. Monitor `legacy_profile_preferences_fallback_*` telemetry and remove legacy fallback code once usage remains zero.
2. Use Pass 19 audit artifacts to remediate any external pipeline aliases before 2026-06-30 freeze.

### Next (P1)
1. Add parity-focused integration tests for additional guarded deep-link permutations introduced in future route additions.
2. Decide whether noun-style localization keys (`wordCrush`) remain intentional product vocabulary or should move to a stricter neutral glossary.
3. Add regression coverage for release-ref gate branch-pattern edge cases (`refs/heads/release-*`, `refs/heads/release`) and tag-pattern behavior alignment with workflow triggers.

### Monitor (P2)
1. Add release parity checklist gate (features, routes, rules, analytics).
2. Monitor data-shape usage metrics until legacy path reaches zero.

---

## File-by-File Action List
### Edited in this pass
- `lib/data/repositories/fake_repositories.dart`
  - Added env fallback resolver for API base URL key parity.
- `lib/core/firebase_emulator.dart`
  - Added emulator key compatibility fallback behavior.
- `functions/firestore.rules`
  - Synced with root canonical rules.
- `scripts/check_firestore_rules_sync.sh`
  - New guard script for rule drift detection.
- `test/core/firebase_emulator_env_parity_test.dart`
  - New regression tests for emulator host fallback logic.
- `test/fake_repositories_env_parity_test.dart`
  - New regression tests for API base URL env fallback order.
- `lib/core/deep_link_bootstrap.dart`
  - Runtime deep-link routing now uses shared parser.
- `lib/core/routing/deep_links.dart`
  - Added `/user-profile` + `/support/category` parsing.
- `test/core/deep_link_bootstrap_test.dart`
  - Added deep-link navigation regression case.
- `test/core/routing/deep_links_test.dart`
  - Added parser regression coverage.
- `test/core/deep_link_auth_transition_integration_test.dart`
  - Added app-shell integration regressions for auth-required pending-link replay across chat/profile/settings and public support-category links.
- `functions/src/index.ts`
  - Added legacy preferences fallback telemetry and cutoff-controlled deprecation behavior.
- `functions/test/profileRestValidation.test.js`
  - Added deterministic pre/post-cutoff fallback helper regressions.
- `.github/workflows/ci.yml`
  - Added CI gate step to enforce Firestore rules parity via `scripts/check_firestore_rules_sync.sh`.
- `lib/app.dart`
  - Updated runtime app title branding to `CRUSH`.
- `web/index.html`
  - Updated web shell metadata/title branding to `CRUSH`.
- `web/manifest.json`
  - Updated app name/short name/description branding to `CRUSH`.
- `lib/features/settings/presentation/screens/support_screen.dart`
  - Updated support version footer and support-email subject branding.
- `lib/features/settings/presentation/screens/support_category_detail_screen.dart`
  - Updated support-email subject branding.
- `lib/config/support_config.dart`
  - Updated support FAQ/subject defaults to `CRUSH` naming.
- `lib/features/settings/data/commands/default_account_action_commands.dart`
  - Updated data-export share copy branding.
- `lib/core/services/data_export_service.dart`
  - Updated data-export share copy branding.
- `functions/src/calls/signaling.ts`
  - Updated incoming call push body branding.
- `lib/l10n/app_*.arb`
  - Updated localized brand tokens from `Crush` to `CRUSH` (value-level only).
- `lib/l10n/generated/*`
  - Regenerated localization runtime artifacts after ARB updates.
- `lib/presentation/screens/terms_of_service_screen.dart`
  - Updated legal screen product branding to `CRUSH`, preserving `CrushHour Inc.` legal-entity text.
- `lib/presentation/screens/privacy_policy_screen.dart`
  - Updated legal screen product branding to `CRUSH`, preserving `CrushHour Inc.` legal-entity text.
- `lib/config/legal_config.dart`
  - Updated legal config comment branding wording to `CRUSH`.
- `test/presentation/screens/legal_branding_copy_test.dart`
  - Added legal-copy product/entity brand regression coverage.
- `lib/presentation/widgets/plus_feature_gate.dart`
  - Updated premium gate paywall title to `CRUSH Plus`.
- `lib/presentation/screens/safety_screen.dart`
  - Updated in-app safety copy branding to `CRUSH`.
- `lib/presentation/screens/community_guidelines_screen.dart`
  - Updated community-guidelines intro/safety phrasing branding to `CRUSH`.
- `lib/presentation/screens/home/settings_screen.dart`
  - Updated upgrade/premium status copy to `CRUSH Plus`.
- `lib/main.dart`
  - Updated startup/error text branding to `CRUSH`.
- `lib/features/about/presentation/screens/pricing_screen.dart`
  - Updated plan naming to `CRUSH Plus` and `CRUSH Platinum`.
- `lib/features/about/presentation/screens/product_features_screen.dart`
  - Updated feature overview copy/subtitle branding to `CRUSH Plus`.
- `lib/features/discovery/presentation/widgets/deck_screen_app_bar.dart`
  - Updated app-bar wordmark label to `CRUSH`.
- `lib/features/discovery/presentation/screens/likes_you_screen.dart`
  - Updated upsell copy branding to `CRUSH Plus`.
- `lib/features/settings/presentation/screens/appearance_settings_screen.dart`
  - Updated premium theme gate label to `CRUSH Premium`.
- `lib/features/auth/presentation/bloc/biometric_cubit.dart`
  - Updated biometric prompt reason branding to `CRUSH`.
- `lib/features/auth/presentation/widgets/biometric_prompt.dart`
  - Updated biometric prompt title branding to `CRUSH`.
- `lib/features/auth/presentation/screens/pin_fallback_screen.dart`
  - Updated PIN fallback prompt branding to `CRUSH`.
- `lib/features/auth/presentation/screens/email_auth_screen.dart`
  - Updated new-user helper copy branding to `CRUSH`.
- `lib/features/auth/presentation/screens/auth_gateway_screen.dart`
  - Updated auth gateway wordmark text to `CRUSH`.
- `lib/core/widgets/update_dialog.dart`
  - Updated default update-status messages to `CRUSH`.
- `lib/core/services/app_update_service.dart`
  - Updated fallback app name to `CRUSH`.
- `lib/core/services/location_service.dart`
  - Updated location foreground notification copy branding to `CRUSH`.
- `lib/features/chat/presentation/screens/matches_screen.dart`
  - Updated matches upsell copy branding to `CRUSH Plus`.
- `lib/core/config/env_config.dart`
  - Updated SMTP sender-name defaults/docs to `CRUSH`.
- `lib/dev/widget_catalog/widget_catalog_screen.dart`
  - Updated widget-catalog title branding to `CRUSH`.
- `test/core/update_dialog_branding_test.dart`
  - Added update-dialog brand-copy regression coverage.

### Additional files requiring follow-up edits
- `lib/l10n/app_*.arb` + `lib/l10n/generated/*` noun-style `wordCrush` vocabulary (intentional today; product glossary decision pending).

## Flow-by-Flow Comparison
### Onboarding
- App: route-gated via `resolveRouteRedirect`.
- Web: same route-gated flow.
- Difference: none major in core logic; historical UI overflow issues already fixed.

### Authentication
- App: email/password, OTP, email-link, platform-specific provider availability.
- Web: same core auth repository contracts, but platform-specific sign-in buttons differ by OS constraints.
- Difference: expected platform-compliance differences.

### Profile management
- App: nested profile document model.
- Web: same frontend model.
- Difference: backend enforces canonical writes; legacy read fallback is temporarily retained with telemetry + cutoff.

### Discovery/matching
- App/Web: shared repository/bloc/domain logic.
- Difference: none found in this pass.

### Messaging
- App/Web: shared chat repositories and state flow.
- Difference: none found in core behavior; media/push capability can vary by platform runtime support.

### Notifications
- App: mobile push lifecycle + badge behavior.
- Web: constrained by browser capabilities.
- Difference: expected; requires explicit product contract docs.

### Premium/subscription
- App: native in-app purchase rails.
- Web: web-compatible checkout paths.
- Difference: payment rails differ; entitlements should remain shared.

### Settings
- App/Web: shared settings routes and screens.
- Difference: none major after support parity fixes.

### Moderation
- App/Web: shared report/block contracts to backend.
- Difference: none major found in this pass.

### Account lifecycle
- App/Web: shared repository and backend function contracts.
- Difference: none major found in this pass; monitor delete/export operational paths.

## Schema and Rules Comparison
### Canonical entities (from rules/functions usage)
- `users`
- `matches`
- `matches/{matchId}/messages`
- `message_requests`
- `likes`
- `reports`
- `blocks`
- `stories`
- `calls`
- `presence`
- server-only auth/support collections (`auth_*`, `usernames`, etc.)

### Key parity observation
- Canonical write controls are mostly server-side for sensitive entities.
- New writes now block legacy flat user profile fields; remaining read compatibility is telemetry-instrumented and cutoff-controlled.

### Policy boundary checks
- Owner checks and signed-in checks are present.
- Sensitive paths in Storage are blocked by default.
- Legacy/duplicate rules artifact drift was corrected in this pass.

## Route and Navigation Comparison
- Route source of truth: `lib/core/routing/crush_routes.dart`.
- Route definitions: `lib/core/router.dart`, `lib/core/routing/settings_routes.dart`, `auth_routes.dart`, `public_routes.dart`.
- Route guarding: `lib/core/routing/route_redirect.dart`.
- Deep-link contract is consolidated via `DeepLinkHandler`; app-shell callback is wired and integration coverage now includes auth-transition route permutations.

## Copy and UX Consistency Review
- Fixed:
  - support category titles/subtitles and category question answers.
  - runtime and localized brand strings normalized to `CRUSH` across app/web/backend/l10n surfaces.
  - legal/policy screens now use `CRUSH` product naming while preserving `CrushHour Inc.` legal-entity references.
  - non-legal high-traffic runtime copy (auth/discovery/settings/safety/about/update) is now normalized to `CRUSH`.
- Remaining:
  - intentional noun-style localization vocabulary (`wordCrush`) and long-tail regression prevention.

## Technical Debt Register
1. Deep-link app-shell integration coverage should be maintained as new routes are added (low).
2. Legacy schema compatibility not fully retired; remove fallback once telemetry is zero (low).
3. Multiple config systems/keys with partial overlap (medium).
4. Duplicate Firestore rules file maintenance burden (low, mitigated with sync script + CI gate).
5. Naming/copy consistency debt across product surfaces (low, now mostly glossary policy and regression-guard expansion).

## Regression Testing Plan (Parity-Focused)
1. Routing parity
- Add integration tests for deep links: profile/chat/support category (auth + unauth paths).
2. Schema parity
- Add tests that reject/flag flat user profile writes once migration is complete.
3. Rules parity
- Keep CI step `scripts/check_firestore_rules_sync.sh` required and green.
4. Config parity
- Add tests for env-key fallback behavior (added in this pass).
5. UX parity
- Keep widget tests for support FAQ expansion and profile keyboard overflow.
6. Release gate
- Before release, run: analyze, targeted parity tests, rules sync script, docs sync script.
