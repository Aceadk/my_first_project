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
- Status: open

### A11Y-002 - Validate dynamic type, focus order, and hardware-keyboard navigation
- Files: forms, dialogs, lists, navigation containers
- Description: Confirm 200% text scaling, visible focus, logical tab order, and keyboard-only navigation on supported devices.
- Acceptance Criteria: no major layout breakage at large text; focus order is deterministic.
- Testing: large-text widget checks and manual external-keyboard passes.
- Status: open

### A11Y-003 - Audit contrast, reduced motion, and color-independent status communication
- Files: design tokens, animation wrappers, status indicators
- Description: Ensure color contrast passes, reduced-motion preferences are respected, and states are not conveyed by color alone.
- Acceptance Criteria: contrast issues and motion violations are tracked or fixed; state cues include text/icon semantics.
- Testing: visual audit plus targeted widget checks.
- Status: open
