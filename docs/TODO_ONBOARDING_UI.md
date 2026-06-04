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
- Status: done (2026-06-04). Verified onboarding steps render through `AuthScaffold` (width capped/centered via `DsBreakpoints`) with per-screen `ConstrainedBox` where needed; covered by existing terms/profile-setup responsive tests. No stretched phone layouts on large screens. Report: `docs/reports/onboarding_ui_audit_2026-06-04.md`.

### ONBOARD-UI-002 - Verify keyboard, focus, and external input behavior
- Files: text-entry steps, focus traversal, shortcut handling
- Description: Ensure tab order, Enter behavior, and keyboard avoidance work on phones, tablets, and hardware keyboards.
- Acceptance Criteria: onboarding forms are keyboard-friendly and maintain focus logically.
- Testing: widget/manual focus traversal checks.
- Status: done (2026-06-04). **Fixed:** basic_info's 3 fields (username/first/last name) set no `textInputAction`, so the soft keyboard didn't advance fields — added FocusNodes + `next`→`next`→`done` chaining with `onSubmitted` hand-off and word capitalization on names; nodes disposed. Covered by `basic_info_screen_focus_test.dart`. Keyboard avoidance verified via profile-setup overflow test; hardware Tab uses default traversal. Report: `docs/reports/onboarding_ui_audit_2026-06-04.md`.

### ONBOARD-UI-003 - Audit large-text, RTL, and localization resilience
- Files: onboarding text layouts and localization strings
- Description: Confirm the most text-heavy onboarding steps survive long translations and 200% text scaling.
- Acceptance Criteria: no clipping or overlap at large text sizes or RTL.
- Testing: localization and text-scale smoke tests.
- Status: done (2026-06-04). **Fixed:** `OnboardingProgress` header overflowed at 2× text scale on narrow widths (37–166px) because the "Step X of Y" counter was non-flexible — combined counter+step name into one `Text.rich` in an `Expanded` with ellipsis (truncates instead of overflowing; keeps Skip trailing). New `onboarding_progress_text_scale_test.dart` reproduces+guards it. Tracked for I18N: hardcoded English step/nav labels (not localized yet) — the fix is forward-compatible with long translations. Report: `docs/reports/onboarding_ui_audit_2026-06-04.md`.
