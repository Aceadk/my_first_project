# TODO: Internationalization and Localization

- Module: localization extraction, formatting, RTL
- Priority: P2
- Estimated Effort: 3-5 days
- Dependencies: string audit, UI stabilization

## Audit Summary

### ✅ What's Already Working

- **22 locales** supported (AR, BN, DE, EN, ES, FR, HI, ID, JA, KO, NE, PT, RU, TA, TE, TR, UR, VI, YO, YUE, ZH + pseudolocale)
- **1,790 string keys** in `app_en.arb`
- **`AppLocalizations.of(context)`** used extensively across chat, discovery, auth modules
- **Locale-aware formatting**: `DateFormat` and `NumberFormat` accept locale param in `date_time_formatter.dart`
- **RTL-ready**: 86 files use `EdgeInsetsDirectional`/`PositionedDirectional`; only 3 `EdgeInsets.only(bottom:)` remain (RTL-safe, vertical-only)

## Tasks

### [/] I18N-001 - String Externalization Completion

- Files: `lib/features/*/presentation/**/*`, `lib/l10n/*`
- Description: Move all user-facing strings into localization resources.
- Acceptance Criteria: No hardcoded UI strings outside l10n wrappers.
- Testing: Static grep + widget smoke in multiple locales.
- Status: **mostly done** — ~12 hardcoded strings remain in `chat_screen.dart` (banners, error messages, mute summaries). Full string externalization requires adding new ARB keys across all 22 locales.
- **Remaining strings in `chat_screen.dart`**:
  - `'Checking your profile completeness with the server…'` (line 317)
  - `'Internet connection error. Messages may not send.'` (line 349)
  - `'Refresh'` (line 360)
  - `'You unmatched with {name}...'` (line 381)
  - `'You blocked {name}...'` (line 403)
  - `'Complete your profile to continue messaging.'` (line 432)
  - `'Missing: ...'` (line 444)
  - `'Call {name}?'` (line 595)
  - `'This will remove your match with {name}...'` (line 801)
  - Mute summary strings (lines 764-769)
  - Various snackbar messages

### [x] I18N-002 - Locale-Aware Formatting

- Files: `lib/core/formatters/*`, `lib/features/*/presentation/*`
- Description: Normalize date/time/count formats using locale-aware formatters.
- Acceptance Criteria: Time and pluralization are locale-correct.
- Testing: Unit tests for representative locales.
- Status: **done** — `DateFormat.jm(locale)`, `DateFormat.yMMMd(locale)`, `NumberFormat.decimalPattern(locale)` all pass locale in `date_time_formatter.dart` and `semantics_helper.dart`.

### [x] I18N-003 - RTL Layout Readiness

- Files: `lib/features/*/presentation`, `lib/design_system/widgets/*`
- Description: Validate mirrored layouts and directional icons/text alignment in RTL.
- Acceptance Criteria: Core flows are fully usable in RTL mode.
- Testing: Widget tests with RTL `Directionality`.
- Status: **done** — 86 files use `EdgeInsetsDirectional`/`PositionedDirectional`/`AlignmentDirectional`. Only 3 `EdgeInsets.only(bottom:)` survive, all vertical-only (RTL-safe).
