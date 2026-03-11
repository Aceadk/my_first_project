# Crush Environment Key Matrix

This document defines the canonical environment keys for app + web-shell builds and the deprecation plan for legacy aliases.

## Policy

- Canonical keys are the only keys that should appear in new scripts, docs, and CI configs.
- Legacy keys are still supported in runtime for controlled migration only.
- New work must not introduce additional legacy aliases.

## App/Web-Shell Dart Defines (This Repository)

| Domain | Canonical Key | Legacy Alias | Resolution Order | Source of Truth |
| --- | --- | --- | --- | --- |
| Runtime flavor | `FLAVOR` | `APP_ENV` | `FLAVOR` -> `APP_ENV` -> `development` | `lib/config/app_config.dart` |
| Backend base URL | `API_BASE_URL` | `CRUSH_API_BASE_URL` | `API_BASE_URL` -> `CRUSH_API_BASE_URL` -> default | `lib/config/app_config.dart` |
| Firebase emulator toggle | `USE_FIREBASE_EMULATOR` | `USE_EMULATORS` | `USE_FIREBASE_EMULATOR` -> `USE_EMULATORS` -> `false` | `lib/config/app_config.dart`, `lib/core/firebase_emulator.dart` |
| Firebase emulator host | `FIREBASE_EMULATOR_HOST` | `EMULATOR_HOST` | `FIREBASE_EMULATOR_HOST` -> `EMULATOR_HOST` -> `localhost` | `lib/config/app_config.dart`, `lib/core/firebase_emulator.dart` |

## Build/Release Script Compatibility

- `scripts/build_release.sh` now treats `FLAVOR` as canonical.
- If only `APP_ENV` is provided, it maps to `FLAVOR` and prints a deprecation warning.
- If both are provided, `FLAVOR` wins and `APP_ENV` is ignored with warning.

## Guardrails

- CI/static guard: `scripts/check_deprecated_env_aliases.sh`
- Migration checkpoint: `scripts/check_env_alias_migration_status.sh`
- Audit artifact generator: `scripts/generate_env_alias_migration_audit_report.sh`
- Cutover ticket scaffold helper: `scripts/create_production_cutover_ticket.sh`
- Cutover ticket contract validator: `scripts/check_release_cutover_ticket_contract.sh`
- Release-ref concrete ticket gate: `scripts/check_release_cutover_ticket_release_ref_gate.sh`
- Release-ref gate regression tests: `scripts/test_release_cutover_ticket_release_ref_gate.sh`
- Cutover script invalid-input tests: `scripts/test_release_cutover_ticket_invalid_input_cases.sh`
- Release-ref gate supports optional resolution overrides:
  - `RELEASE_CUTOVER_TICKET_PATH` (explicit ticket path)
  - `RELEASE_CUTOVER_TICKET_GLOB` (custom fallback glob, mainly for deterministic test harnesses)
- Release-ref gate regression coverage now includes:
  - `GITHUB_REF` unset skip behavior,
  - explicit path-over-glob precedence behavior.
  - path-precedence failure semantics (invalid explicit path still fails even if glob fallback can resolve valid tickets).
- Production cutover go/no-go runbook:
  - `docs/RELEASE_GUIDE.md` -> `Operator Runbook: Env Alias Migration Go/No-Go`
- Enforced in CI workflow (`.github/workflows/ci.yml`) under Security checks.
- Guard blocks deprecated aliases outside the approved compatibility allowlist.
- Migration checkpoint validates:
  - allowlist guard state,
  - no active alias emitters in machine-executed workflow/script paths,
  - date-based freeze/removal milestones.
- Audit generator writes dated report artifacts in `docs/reports/ENV_ALIAS_MIGRATION_AUDIT_YYYY-MM-DD.md`.
- Temporary exclusions for AI task logs:
  - `docs/ai_workboard.md`
  - `docs/Developer_agent_chat.md`

## Functions Env Keys

Cloud Functions no longer uses legacy `functions.config()` and is already standardized on `.env` + `firebase-functions/params` contracts (`functions/.env.example` + `functions/src/index.ts`).

## Deprecation Timeline

- **2026-03-11:** Canonical resolver + compatibility fallback completed (Pass 15) and matrix published (Pass 16).
- **2026-06-30:** Freeze date for updating deployment scripts/CI/docs to canonical keys only.
- **2026-09-30:** Planned fallback removal window for legacy aliases:
  - `APP_ENV`
  - `CRUSH_API_BASE_URL`
  - `USE_EMULATORS`
  - `EMULATOR_HOST`

If any external pipeline still requires legacy keys after **2026-09-30**, it must be explicitly documented in `docs/risk_notes.md` before extending fallback support.

## Migration Checklist

1. Update all local scripts/CI workflows to canonical keys.
2. Update all operator docs/runbooks to canonical keys.
3. Confirm no active deployment pipeline still emits legacy keys.
4. Remove fallback aliases from `AppConfig` and related tests.
5. Run `scripts/check_env_alias_migration_status.sh` before each production release.
6. Generate and store an audit artifact:
   - `scripts/generate_env_alias_migration_audit_report.sh`
7. Scaffold cutover ticket with prefilled dated artifact path:
   - `scripts/create_production_cutover_ticket.sh`
8. Create/validate cutover ticket with exact dated artifact reference:
   - `scripts/check_release_cutover_ticket_contract.sh <cutover-ticket-path>`
9. Verify release-ref CI gate behavior (for release branches/tags):
   - `scripts/check_release_cutover_ticket_release_ref_gate.sh`
