# TODO: Refactor Settings

- Priority: P2 – Medium
- Estimated Effort: 2-4 days
- Dependencies: `docs/TODO_SETTINGS_UI.md`, `docs/TODO_ACCOUNT_MGMT.md`
- Assigned: AI + Developer

## Tasks

### REF-SET-001 - Continue separating settings sections from route shells
- Files: settings root screen and shared section widgets
- Description: Keep large settings surfaces modular so account, privacy, support, and billing concerns remain isolated.
- Acceptance Criteria: route shells stay thin and section logic lives in focused components.
- Testing: widget tests for section components and route smoke coverage.
- Status: open

### REF-SET-002 - Isolate destructive account actions into command-style abstractions
- Files: account action handlers, settings/account screens
- Description: Ensure destructive flows have reusable command boundaries instead of ad hoc UI-triggered logic.
- Acceptance Criteria: account actions are easier to test and reason about without UI coupling.
- Testing: command/unit tests and settings smoke coverage.
- Status: open
