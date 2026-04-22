# TODO: Chat UI Module

- Priority: P0 – Critical
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_CHAT_REALTIME.md`, `docs/TODO_RESPONSIVE_DESIGN.md`, `docs/TODO_ACCESSIBILITY.md`
- Assigned: AI + Developer

## Tasks

### CHAT-UI-001 - Build intentional chat layouts for iPad, tablet, and web
- Files: chat screens, conversation lists, message detail surfaces
- Description: Audit whether chat should use master-detail on wider screens and whether composer/list spacing remains readable at all widths.
- Acceptance Criteria: wide-screen chat has an intentional navigation model; no stretched message columns.
- Testing: widget/manual checks on iPad portrait/landscape and desktop widths.
- Status: open

### CHAT-UI-002 - Verify keyboard, external keyboard, and composer behavior
- Files: message composer, keyboard avoidance helpers, focus handlers
- Description: Ensure Enter/Shift+Enter semantics, tab focus, hardware keyboards, and orientation changes behave correctly.
- Acceptance Criteria: composer works with hardware and software keyboards; focus order is predictable.
- Testing: widget tests where possible and manual iPad keyboard checks.
- Status: open

### CHAT-UI-003 - Audit media preview, failed-send, and retry UX
- Files: message bubble widgets, attachment previews, resend controls
- Description: Ensure media, failed sends, pending states, and moderation/blocked states are communicated clearly and accessibly.
- Acceptance Criteria: failed and pending message states are recoverable and visible without color alone.
- Testing: widget tests for failed/pending/media states.
- Status: open
