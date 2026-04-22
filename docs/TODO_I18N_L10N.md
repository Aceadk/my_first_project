# TODO: Internationalization & Localization

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_ACCESSIBILITY.md`, `docs/TODO_ONBOARDING_UI.md`
- Assigned: AI + Developer

## Tasks

### I18N-001 - Remove remaining hardcoded user-facing strings
- Files: mobile and web UI presentation layers, shared helpers
- Description: Audit the remaining hardcoded strings and move them into localization resources with stable keys.
- Acceptance Criteria: critical flows have no hardcoded user-facing copy outside approved exception lists.
- Testing: localization extraction audit and targeted UI spot checks.
- Status: open

### I18N-002 - Verify RTL, locale formatting, and text expansion resilience
- Files: localized strings, date/number formatters, mirrored layouts
- Description: Ensure RTL layouts, locale-aware formatters, and long translations do not break major screens.
- Acceptance Criteria: RTL and long-string hotspots are tested and tracked; locale formatting is consistent.
- Testing: widget/manual checks with Arabic/Hebrew and long-language pseudolocales.
- Status: open

### I18N-003 - Audit pluralization and embedded-text asset risks
- Files: localization resources, UI copy, icons/images with embedded text
- Description: Validate plural rules and ensure visual assets do not contain language-specific baked-in text.
- Acceptance Criteria: plural-sensitive flows use proper localization APIs; embedded-text assets are removed or tracked.
- Testing: localization QA and asset review.
- Status: open
