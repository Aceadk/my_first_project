# TODO: Onboarding Flow Module

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_ONBOARDING_UI.md`, `docs/TODO_AUTH_SECURITY.md`, `docs/TODO_IPAD_COMPLIANCE.md`
- Assigned: AI + Developer

## Tasks

### ONBOARD-001 - Audit onboarding resume and interruption recovery
- Files: onboarding routes, persisted progress state, startup routing
- Description: Ensure users can resume after app kills, auth refreshes, or device rotation without losing progress.
- Acceptance Criteria: resume rules are deterministic; incomplete onboarding does not strand or loop users.
- Testing: interruption smoke tests and route-state regression coverage.
- Status: done (2026-06-04). Verified `resolveRouteRedirect` is a pure, deterministic resolver (terms→basic-info→profile-setup→email-verify→home); each gate target is a fixed point (no loop) and partially-onboarded resume-from-deep-route maps to the correct next step (no strand), covered by `router_redirect_test.dart` (11 cases). `AppStatePreserver` saves/restores route on background/resume, then the redirect re-gates. Report: `docs/reports/onboarding_flow_audit_2026-06-04.md`.

### ONBOARD-002 - Verify permission request ordering and rationale screens
- Files: onboarding permission steps, location/camera/photo/push rationale UI
- Description: Confirm permission prompts are contextual, sequenced, and compliant with store expectations.
- Acceptance Criteria: no stacked permission barrage; rationale copy exists before system prompts where appropriate.
- Testing: manual first-run flow on iOS, Android, and web.
- Status: done (2026-06-04). Verified permissions are contextual/sequenced: location requested only after `PermissionRationaleScreen` in profile setup; push requested via the notifications settings toggle (not a cold-start barrage); camera/photo via native picker on demand. No stacked first-run prompts. Full first-run ordering on physical iOS/Android/web remains a manual release-gate check. Report: `docs/reports/onboarding_flow_audit_2026-06-04.md`.

### ONBOARD-003 - Verify age gating, terms acceptance, and completion semantics
- Files: onboarding validation, terms screens, auth/profile completion flags
- Description: Ensure age checks, terms acceptance, and onboarding completion state are enforced consistently across platforms.
- Acceptance Criteria: underage or incomplete users cannot bypass required gates.
- Testing: unit/integration coverage for onboarding route resolution and validation rules.
- Status: done (2026-06-04). Verified the 18+ input gate (date picker `lastDate = now-18y` + `_handleNext` blocks `age < ValidationConstants.minAge`) and terms gating. **Hardened:** `CrushUser.hasCompletedBasicInfo` now requires `age >= minAge` (was `age > 0`) so an underage age from legacy data/API/bug can't satisfy the onboarding gate — defense-in-depth, with a new underage regression case in `user_model_hotspot_test.dart`. Report: `docs/reports/onboarding_flow_audit_2026-06-04.md`.
