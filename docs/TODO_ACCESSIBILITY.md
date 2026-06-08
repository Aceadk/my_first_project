# TODO: Accessibility

- Priority: P0 – Critical
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_RESPONSIVE_DESIGN.md`, `docs/TODO_TESTING_MATRIX.md`
- Assigned: AI + Developer

## Tasks

### A11Y-001 - Run semantics and screen-reader sweep on critical flows
- Files: auth, onboarding, discovery, chat, profile, settings UI
- Description: Verify every interactive element has correct semantics labels, roles, and screen-reader context.
- Acceptance Criteria: critical flows are screen-reader navigable without unlabeled controls.
- Testing: semantics widget checks plus manual VoiceOver/TalkBack passes.
- Status: automated coverage complete; manual VoiceOver/TalkBack device pass pending.
- Progress (2026-05-30):
  - Added an automated `labeledTapTargetGuideline` sweep (Flutter's "every tappable node has a label" audit) over the auth gateway, login, chat composer, and account-actions screens in `test/accessibility_regression_lane_test.dart`.
  - Fixed the unlabeled controls the sweep surfaced: the password show/hide toggle (now `GlassTextField.suffixSemanticLabel` wired in `login_screen.dart` + `sign_up_screen.dart`) and the chat send button (now a single labeled, tappable `MergeSemantics` node).
  - Paired the chat-list online indicator with a screen-reader label so online state is no longer color-only.
- Remaining (manual/device): VoiceOver (iOS) and TalkBack (Android) end-to-end passes over the full critical journeys.

### A11Y-002 - Validate dynamic type, focus order, and hardware-keyboard navigation
- Files: forms, dialogs, lists, navigation containers
- Description: Confirm 200% text scaling, visible focus, logical tab order, and keyboard-only navigation on supported devices.
- Acceptance Criteria: no major layout breakage at large text; focus order is deterministic.
- Testing: large-text widget checks and manual external-keyboard passes.
- Status: automated coverage complete; manual external-keyboard device pass pending.
- Progress (2026-05-30):
  - Wired the previously-unused `DsTextScaleCap` into the app root (`app.dart` `MaterialApp.router` builder) so 200%+ system text is bounded to a layout-safe 2.0x globally; added clamp tests in `test/accessibility_dynamic_type_test.dart`.
  - Added deterministic focus-order and keyboard-activation tests (`DsFocusTraversalScreen` reading order, Enter/Space button activation) alongside the existing 2x large-text and Tab-traversal coverage in the regression lane.
- Remaining (manual/device): physical external-keyboard pass and visible-focus inspection on supported devices.

### A11Y-003 - Audit contrast, reduced motion, and color-independent status communication
- Files: design tokens, animation wrappers, status indicators
- Description: Ensure color contrast passes, reduced-motion preferences are respected, and states are not conveyed by color alone.
- Acceptance Criteria: contrast issues and motion violations are tracked or fixed; state cues include text/icon semantics.
- Testing: visual audit plus targeted widget checks.
- Status: complete (audited, fixed, and regression-tested locally).
- Progress (2026-05-30):
  - Added `test/accessibility_token_contrast_test.dart` codifying the WCAG AA contrast contracts of the design tokens (body/muted text, brand fills, status colors, on-glass text).
  - Fixed `DsAccessibility.accessibleTextColor`, which mis-picked white on mid-tone tokens (success/mint reached only 2.16:1); it now selects the higher-contrast ink/paper.
  - Fixed the resulting low-contrast success snackbars (`snackbar_utils.dart` + 3 direct call sites) to use a legible dark foreground (9.72:1).
  - Added `test/accessibility_reduced_motion_test.dart` verifying every DS entrance/press animation wrapper renders statically under `disableAnimations`.
  - Made the chat-list online status non-color-only by pairing the indicator with a label (the shared `CrushAvatar`/`GlassStatusBadge` already do this).

### A11Y-004 - Add authenticated web accessibility release coverage
- Files: `/Users/ace/crush-web/apps/web/**`, Playwright/axe tests, shared web components, authenticated route fixtures
- Description: Extend web accessibility checks beyond utility/unit coverage into real authenticated journeys and complete manual cross-platform assistive-technology evidence.
- Dependencies: `TEST-007`, `RESP-004`
- Acceptance Criteria:
  - Authenticated axe checks cover onboarding, discovery, matches/chat, profile, safety, premium, and settings.
  - Keyboard-only navigation, focus order, dialog focus trapping/restoration, visible focus, zoom, reduced motion, and error announcements are verified.
  - Interactive controls have meaningful names and status is not color-only.
  - VoiceOver, TalkBack, external-keyboard, and supported browser evidence is recorded.
- Testing:
  - Playwright + axe authenticated CI lane.
  - Keyboard/focus/reduced-motion automated checks.
  - Manual assistive-technology matrix.
- Status: open — P1 release evidence task.
