# TODO: Comprehensive Testing Matrix Execution

- Module: unit, widget, integration, e2e, perf, security lanes
- Priority: P0
- Estimated Effort: 6-10 days
- Dependencies: module TODO execution and CI pipeline stability

## Tasks

### TEST-001 - Canonical Coverage Lane Stabilization
- Files: CI workflows, `test/**/*`, `coverage_logic_lowest_raw.txt`
- Description: Stabilize full `flutter test --coverage` lane and refresh canonical hotspot ranking artifact.
- Acceptance Criteria: deterministic coverage lane; hotspot file reproducibly generated.
- Testing: run lane twice consecutively with identical pass/fail.
- Status: completed (2026-03-12)

### TEST-002 - Critical Journey Integration Suite
- Files: `integration_test/e2e_onboarding_to_chat_test.dart`, related helpers
- Description: Expand deterministic assertions for onboarding -> discovery -> match -> chat -> report/block.
- Acceptance Criteria: full journey asserts route/state checkpoints, not just presence checks.
- Testing: integration suite on CI emulator.
- Status: in_progress

### TEST-003 - Startup Readiness Guard
- Files: `integration_test/startup_smoke_test.dart`, CI config
- Description: Enforce cold start smoke test to prevent blank-launch regressions.
- Acceptance Criteria: test fails fast if first frame content not visible in timeout.
- Testing: dedicated startup lane in CI.
- Status: completed (2026-03-12)

### TEST-004 - Device Matrix Runbook
- Files: `docs/web_testing_plan.md`, new `docs/device_matrix_report.md`
- Description: Formalize required iOS/Android/web device/browser matrix and evidence capture.
- Acceptance Criteria: runbook includes required devices, OS versions, and pass evidence format.
- Testing: dry run evidence pack for at least one device per platform.
- Status: completed (2026-03-12)

### TEST-005 - Security and Abuse Test Lanes
- Files: `functions/src/**/*`, CI workflows
- Description: Add automated tests for auth abuse, OTP limits, report/block abuse, and unauthorized access.
- Acceptance Criteria: CI lane blocks merges on critical security path failures.
- Testing: function test suite with malicious fixture set.
- Status: completed (2026-03-12)
