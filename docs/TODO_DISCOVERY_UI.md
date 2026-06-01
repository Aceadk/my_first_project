# TODO: Discovery UI Module

- Priority: P0 – Critical
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_MATCHING_LOGIC.md`, `docs/TODO_DISCOVERY_BACKEND.md`, `docs/TODO_RESPONSIVE_DESIGN.md`
- Assigned: AI + Developer

## Tasks

### DISC-UI-001 - Audit discovery deck layout across phone, iPad, tablet, and web
- Files: `lib/features/discovery/presentation/**`, `/Users/ace/crush-web/**/discover/**`
- Description: Verify swipe deck, card content density, controls, and fallback states on all supported widths and orientations.
- Acceptance Criteria: discovery UI feels intentional on large screens; no clipped controls or unreadable stretched cards.
- Testing: widget/manual checks on phone, iPad portrait/landscape, and desktop web.
- Status: in progress — audited 2026-05-30, follow-ups landed + verified 2026-05-31 (flutter analyze clean, tests green). Card width capped at 500 on tablet/desktop (LayoutBuilder + ConstrainedBox); explore-grid alternative on non-mobile; action-button column now overflow-guarded for short viewports (SingleChildScrollView + IntrinsicHeight); explore-grid action parity confirmed (grid card → profile screen Like/Pass). Remaining: manual device/orientation pass on real iPad + web. See `docs/reports/discovery_ui_audit_2026-05-30.md`.

### DISC-UI-002 - Audit filter UX, empty states, and no-results handling
- Files: filter dialogs/sheets, discovery empty/error states
- Description: Ensure filter combinations, conflicting filters, and exhausted decks produce clear UX with recovery actions.
- Acceptance Criteria: no-result scenarios are actionable; filter state is visible and reversible.
- Testing: widget tests for empty/error/filter states.
- Status: in progress — audited 2026-05-30, follow-ups landed + verified 2026-05-31. Dedicated empty/error/skeleton views with recovery actions (refresh, retry countdown, passport upsell) confirmed. Screen-reader announcements added on deck state transitions (ready/empty). Filter invalid-range: not possible (two-thumb RangeSlider); zero-result recovery already present (Adjust filters + refresh + passport). Remaining: manual screen-reader pass. See `docs/reports/discovery_ui_audit_2026-05-30.md`.

### DISC-UI-003 - Add accessible alternatives to gesture-only discovery actions
- Files: swipe controls, card action buttons, semantics wiring
- Description: Provide non-swipe alternatives and strong semantics for users who cannot rely on drag gestures.
- Acceptance Criteria: like/pass/super-like actions are available without swipes; semantics and keyboard access are present where supported.
- Testing: accessibility-focused widget tests and manual screen-reader checks.
- Status: in progress — refactored 2026-05-30, verified 2026-05-31 (flutter analyze clean; deck_action_button_test 7/7 + discovery suite 53 + presentation 20 green). DeckActionButton hardened (≥48dp hit target, Semantics.enabled, tooltip); all 9 action paths (gesture/button/keyboard) unified through a single gated `_performSwipe` + `_SwipeAction` enum; gesture-equivalent semantic hints added; explore-grid card semantics de-duplicated; deck state-change announcements added. Remaining (optional): spoken per-action/match outcomes; manual screen-reader pass to close. See `docs/reports/discovery_ui_audit_2026-05-30.md`.
