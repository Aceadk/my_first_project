# TODO: Onboarding UI Module

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_ONBOARDING_FLOW.md`, `docs/TODO_RESPONSIVE_DESIGN.md`, `docs/TODO_ACCESSIBILITY.md`
- Assigned: AI + Developer

## Tasks

### ONBOARD-UI-001 - Make onboarding screens intentional on iPad, tablet, and web
- Files: onboarding presentation widgets and screens
- Description: Audit each onboarding step for large-screen readability, spacing, and content width rather than stretched phone layouts.
- Acceptance Criteria: onboarding layouts look intentional on large screens in portrait and landscape.
- Testing: screenshot/manual review on iPad and desktop widths.
- Status: open

### ONBOARD-UI-002 - Verify keyboard, focus, and external input behavior
- Files: text-entry steps, focus traversal, shortcut handling
- Description: Ensure tab order, Enter behavior, and keyboard avoidance work on phones, tablets, and hardware keyboards.
- Acceptance Criteria: onboarding forms are keyboard-friendly and maintain focus logically.
- Testing: widget/manual focus traversal checks.
- Status: open

### ONBOARD-UI-003 - Audit large-text, RTL, and localization resilience
- Files: onboarding text layouts and localization strings
- Description: Confirm the most text-heavy onboarding steps survive long translations and 200% text scaling.
- Acceptance Criteria: no clipping or overlap at large text sizes or RTL.
- Testing: localization and text-scale smoke tests.
- Status: open
