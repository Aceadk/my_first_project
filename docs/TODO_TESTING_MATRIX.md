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
- Status: open

### TEST-006 - iPad and Tablet Evidence Matrix
- Files: `docs/device_matrix_report.md`, iPad/tablet smoke tests, screenshot evidence
- Description: Run and document the iPad and tablet matrix required by the CEO directive, including portrait, landscape, Split View, and Slide Over where applicable.
- Acceptance Criteria: evidence pack includes each required target class, orientation coverage, and pass/fail notes with blockers linked to module TODOs.
- Testing: manual matrix run on high-fidelity simulators or real devices.
- Status: open
