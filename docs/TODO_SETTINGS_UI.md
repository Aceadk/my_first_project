# TODO: Settings UI Module

- Priority: P1 – High
- Estimated Effort: 2-4 days
- Dependencies: `docs/TODO_ACCOUNT_MGMT.md`, `docs/TODO_RESPONSIVE_DESIGN.md`, `docs/TODO_ACCESSIBILITY.md`
- Assigned: AI + Developer

## Tasks

### SET-UI-001 - Audit settings navigation and content width on large screens
- Files: settings root and sub-screens across mobile and web
- Description: Ensure settings content remains readable on iPad, tablet, and desktop and uses intentional navigation for larger widths.
- Acceptance Criteria: settings screens respect max width and adaptive navigation rules.
- Testing: widget/manual checks on tablet and desktop widths.
- Status: done (2026-06-04). Verified all 13 settings screens center+cap content via `ConstrainedBox(maxWidth: DsBreakpoints.contentMaxWidth(...))`, and navigation flows through the adaptive shell (bottom-nav ↔ rail per breakpoints). No stretched layouts on large widths. Report: `docs/reports/settings_ui_audit_2026-06-04.md`.

### SET-UI-002 - Verify accessibility and interaction quality for toggles, forms, and destructive actions
- Files: settings widgets, toggle controls, confirmation modals
- Description: Validate semantics, focus order, tap targets, and confirmation UX across settings flows.
- Acceptance Criteria: settings controls are accessible and destructive flows are clear and reversible where appropriate.
- Testing: accessibility widget checks and manual screen-reader validation.
- Status: done (2026-06-04). **Fixed:** 3 screens (privacy, notifications, account_security) rendered bare `Switch` in `ListTile.trailing` with no label association — a screen reader announced "on/off, switch" without the setting name. Wrapped the `_PrivacyTile`/`_SettingsTile`/`_SecurityTile` builders in `MergeSemantics` so label+subtitle+control collapse into one labeled toggle node; covered by `settings_toggle_semantics_test.dart`. Verified destructive flows (account delete = multi-step type-to-confirm + password re-auth via `AdaptiveDialog`) are clear/reversible. Manual VoiceOver/TalkBack sweep remains a release-gate item. Report: `docs/reports/settings_ui_audit_2026-06-04.md`.

### SET-UI-003 - Standardize loading, empty, and error states in settings
- Files: settings screens and shared components
- Description: Remove ad hoc handling and ensure every settings surface has consistent retry/help behavior.
- Acceptance Criteria: network-bound settings screens surface loading/error/retry consistently.
- Testing: widget tests for loading and error states.
- Status: done (2026-06-04). Verified network-bound screens (subscription, account_security, chat, language_region) surface loading/error/retry; preference screens (notifications, privacy, discovery_filters, data_storage) are local-first `SharedPreferences` cubits with optimistic writes + best-effort remote sync (errors swallowed, reconciled on hydrate), so no loading/error surface is applicable. No blocking network load lacks a state — consistent by design. Report: `docs/reports/settings_ui_audit_2026-06-04.md`.
