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
- Status: open

### DISC-UI-002 - Audit filter UX, empty states, and no-results handling
- Files: filter dialogs/sheets, discovery empty/error states
- Description: Ensure filter combinations, conflicting filters, and exhausted decks produce clear UX with recovery actions.
- Acceptance Criteria: no-result scenarios are actionable; filter state is visible and reversible.
- Testing: widget tests for empty/error/filter states.
- Status: open

### DISC-UI-003 - Add accessible alternatives to gesture-only discovery actions
- Files: swipe controls, card action buttons, semantics wiring
- Description: Provide non-swipe alternatives and strong semantics for users who cannot rely on drag gestures.
- Acceptance Criteria: like/pass/super-like actions are available without swipes; semantics and keyboard access are present where supported.
- Testing: accessibility-focused widget tests and manual screen-reader checks.
- Status: open
