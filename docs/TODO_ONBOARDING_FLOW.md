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
- Status: open

### ONBOARD-002 - Verify permission request ordering and rationale screens
- Files: onboarding permission steps, location/camera/photo/push rationale UI
- Description: Confirm permission prompts are contextual, sequenced, and compliant with store expectations.
- Acceptance Criteria: no stacked permission barrage; rationale copy exists before system prompts where appropriate.
- Testing: manual first-run flow on iOS, Android, and web.
- Status: open

### ONBOARD-003 - Verify age gating, terms acceptance, and completion semantics
- Files: onboarding validation, terms screens, auth/profile completion flags
- Description: Ensure age checks, terms acceptance, and onboarding completion state are enforced consistently across platforms.
- Acceptance Criteria: underage or incomplete users cannot bypass required gates.
- Testing: unit/integration coverage for onboarding route resolution and validation rules.
- Status: open
