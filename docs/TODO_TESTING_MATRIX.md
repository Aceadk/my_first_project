# TODO: Comprehensive Testing Matrix Execution

- Module: unit, widget, integration, e2e, perf, security, device matrix lanes
- Priority: P0
- Estimated Effort: 4-7 days
- Dependencies: module TODO execution and CI pipeline stability

## Tasks

### TEST-002 - Critical Journey Integration Suite
- Files: `integration_test/e2e_onboarding_to_chat_test.dart`, related helpers
- Description: Expand deterministic assertions for onboarding -> discovery -> match -> chat -> report/block.
- Acceptance Criteria: full journey asserts route/state checkpoints, not just presence checks.
- Testing: integration suite on CI emulator.
- Status: done (2026-06-03). Verified `integration_test/e2e_onboarding_to_chat_test.dart` already asserts deterministic checkpoints (not presence): route path at every onboarding step + user onboarding-flag state, match state (mutual + reciprocal), chat message stream/pagination/read-receipt state, and persisted report+block safety state. `flutter analyze` clean. Execution is the CI-emulator lane (this dev host has no attached device). Report: `docs/reports/testing_matrix_2026-06-03.md`.

### TEST-006 - iPad and Tablet Evidence Matrix
- Files: `docs/device_matrix_report.md`, iPad/tablet smoke tests, screenshot evidence
- Description: Run and document the iPad and tablet matrix required by the CEO directive, including portrait, landscape, Split View, and Slide Over where applicable.
- Acceptance Criteria: evidence pack includes each required target class, orientation coverage, and pass/fail notes with blockers linked to module TODOs.
- Testing: manual matrix run on high-fidelity simulators or real devices.
- Status: blocked on manual device run (2026-06-03). Evidence-pack scaffold prepared in `docs/device_matrix_report.md` (iPad Pro 12.9"/Air/mini + Android tablet × portrait/landscape + Split View + Slide Over, with scenario packs, evidence paths, and a sign-off coverage contract). Remaining work is the actual simulator/device execution to fill `Pass`/`Fail`/`Blocked` + attach screenshots — cannot be done from the headless dev/CI environment; requires a human on high-fidelity simulators or hardware. Report: `docs/reports/testing_matrix_2026-06-03.md`.

### TEST-007 - Establish the web production-alignment release gate
- Files: `/Users/ace/crush-web/.github/workflows/**`, Playwright tests, rules-emulator tests, contract checks, staging smoke tooling
- Description: Make web completion evidence enforceable. The release gate must cover green static checks, protected backend access, rules semantics, authenticated critical journeys, route/domain manifests, and migration/cutover behavior.
- Dependencies: `SEC-FE-004`, `DB-004`, `API-007`, `API-008`
- Acceptance Criteria:
  - Required CI runs lint, standalone typecheck, unit tests, production build, rules-emulator tests, contract/manifest checks, and authenticated Playwright smoke.
  - Current i18n test-file typecheck failure is fixed.
  - Critical journey covers onboarding -> profile -> discovery -> match -> chat -> report/block plus notifications, subscription, and account lifecycle checkpoints.
  - App Check/CSP denial and success paths are tested in staging.
  - Migration/cutover evidence and rollback criteria are attached before V2 production enablement.
- Testing:
  - CI execution on pull requests and protected branches.
  - Scheduled or release-triggered staging E2E with redacted artifacts.
  - Failure-injection checks for auth expiry, offline/reconnect, permission denial, and backend rejection.
- Status: open — P0 release gate.
