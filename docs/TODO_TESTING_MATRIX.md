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
