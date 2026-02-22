# TODO: Internationalization and Localization

- Module: localization extraction, formatting, RTL
- Priority: P2
- Estimated Effort: 3-5 days
- Dependencies: string audit, UI stabilization

## Tasks

### I18N-001 - String Externalization Completion
- Files: `lib/features/*/presentation/**/*`, `lib/l10n/*`
- Description: Move all user-facing strings into localization resources.
- Acceptance Criteria: No hardcoded UI strings outside l10n wrappers.
- Testing: Static grep + widget smoke in multiple locales.
- Status: todo

### I18N-002 - Locale-Aware Formatting
- Files: `lib/core/formatters/*`, `lib/features/*/presentation/*`
- Description: Normalize date/time/count formats using locale-aware formatters.
- Acceptance Criteria: Time and pluralization are locale-correct.
- Testing: Unit tests for representative locales.
- Status: todo

### I18N-003 - RTL Layout Readiness
- Files: `lib/features/*/presentation`, `lib/design_system/widgets/*`
- Description: Validate mirrored layouts and directional icons/text alignment in RTL.
- Acceptance Criteria: Core flows are fully usable in RTL mode.
- Testing: Widget tests with RTL `Directionality`.
- Status: todo
