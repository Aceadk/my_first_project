# Testing Matrix Execution - 2026-06-03

Scope: `TEST-002`, `TEST-006` from [`docs/TODO_TESTING_MATRIX.md`](../TODO_TESTING_MATRIX.md).

## Result

TEST-002 is satisfied by the existing critical-journey integration suite (verified
by review + static analysis). TEST-006's evidence-pack scaffold is prepared, but
its actual pass/fail outcomes **require a human device run** and cannot be produced
from this headless environment — it is left open/blocked, not falsely closed.

---

## TEST-002 - Critical Journey Integration Suite

Status: ✅ Done

`integration_test/e2e_onboarding_to_chat_test.dart` already asserts deterministic
route + state checkpoints across the full journey, which is exactly the acceptance
("route/state checkpoints, not just presence checks"):
- **Onboarding:** asserts the router path at every step
  (auth gateway → terms → basic info → profile setup → home) **and** the user's
  onboarding-flag state (`hasAcceptedTerms`, `hasCompletedBasicInfo`,
  `hasCompletedProfileSetup`, `isOnboardingComplete`) after each transition.
- **Discovery → match:** asserts deck non-empty, candidate ≠ self, and both the
  current user's match record (`MatchStatus.mutual`, correct `otherUserId`) and the
  reciprocal match for the candidate.
- **Chat:** asserts the chat route, then live message stream delivery
  (`watchMessages` + `watchNewMessages`), pagination ordering, and read-receipt
  state after `markMessagesRead`.
- **Safety:** asserts the persisted report record (reporter/reported/reason/match/
  source) and the block set.

The only `find...findsOneWidget` is the ChatScreen presence check, immediately
paired with a route-path assertion — so it is a route checkpoint, not a bare
presence check.

Verification: `flutter analyze integration_test/e2e_onboarding_to_chat_test.dart`
(and the sibling safety e2e) — no issues. Execution is the CI-emulator lane per the
task's own testing note; this dev host has no attached device
(`flutter test integration_test/...` reports "No devices connected").

## TEST-006 - iPad and Tablet Evidence Matrix

Status: ⛔ Blocked on manual device run (scaffold ready)

- Added an iPad/tablet evidence matrix to
  [`docs/device_matrix_report.md`](../device_matrix_report.md): iPad Pro 12.9",
  iPad Air 10.9", iPad mini, and an Android large-screen tablet, each with
  portrait + landscape, plus iPad **Split View** and **Slide Over** rows — with
  run IDs, scenario packs, evidence paths, and a sign-off coverage contract.
- ⛔ The actual `Pass`/`Fail`/`Blocked` results + screenshots must be captured on
  high-fidelity simulators or real hardware (the task is explicitly a "manual
  matrix run"). That step cannot be performed from a headless dev/CI environment,
  so TEST-006 remains open pending a human execution pass. The structure is ready
  to fill, and layout blockers should link back to `TODO_IPAD_COMPLIANCE.md` /
  `TODO_RESPONSIVE_DESIGN.md`.

---

## Verification
- `flutter analyze` on both e2e integration tests — no issues.
- Device-matrix scaffold added and reviewed; results intentionally left `Pending`.
