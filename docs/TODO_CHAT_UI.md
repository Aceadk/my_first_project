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
- Status: in progress — audited + fixed + verified 2026-06-01 (analyze clean; responsive tests passing). Already correct: tablet/desktop master-detail split view, readable conversation max-width (`chatConversationMaxWidthFor` 720/960), 480px bubble cap. Fixed a real navigation-model bug: the layout decided split-vs-single from `LayoutBuilder` constraints but the tile tap handler decided from `MediaQuery` screen width, so in a constrained shell / iPad split-screen the two could disagree and a tap would either do nothing or push over the split view. Introduced `chatUsesSplitView(width)` as the single source of truth used by both, and made the detail-pane placeholder theme-aware. Covered by `chat_list_screen_responsive_test.dart`. Remaining: manual iPad portrait/landscape + split-screen pass. See `docs/reports/chat_ui_audit_2026-06-01.md`.

### CHAT-UI-002 - Verify keyboard, external keyboard, and composer behavior
- Files: message composer, keyboard avoidance helpers, focus handlers
- Description: Ensure Enter/Shift+Enter semantics, tab focus, hardware keyboards, and orientation changes behave correctly.
- Acceptance Criteria: composer works with hardware and software keyboards; focus order is predictable.
- Testing: widget tests where possible and manual iPad keyboard checks.
- Status: in progress — audited + fixed + verified 2026-06-01 (analyze clean; keyboard-policy tests passing). Already correct: ordered focus traversal (media → field → send), soft-keyboard avoidance via Scaffold resize. Fixed: Enter sent on key-repeat too, so a held Enter spam-sent; the semantics were also un-testable inlined. Extracted pure `chat_composer_keyboard.dart` (`ChatComposerKeyboard.actionForEnter` → send/insertNewline/ignore) — plain Enter sends only on key-down, repeat/up are consumed, Shift+Enter inserts newline on press+repeat; also handles numpad-Enter. Covered by `chat_composer_keyboard_test.dart`. Remaining: manual iPad hardware-keyboard + orientation pass. See `docs/reports/chat_ui_audit_2026-06-01.md`.

### CHAT-UI-003 - Audit media preview, failed-send, and retry UX
- Files: message bubble widgets, attachment previews, resend controls
- Description: Ensure media, failed sends, pending states, and moderation/blocked states are communicated clearly and accessibly.
- Acceptance Criteria: failed and pending message states are recoverable and visible without color alone.
- Testing: widget tests for failed/pending/media states.
- Status: in progress — audited + fixed + verified 2026-06-01 (analyze clean; failed-actions widget tests passing). Already correct: media size caps + broken-media placeholders, pending-scan/held states shown with icon+text (not colour alone), read receipts as icon+"Seen". Fixed in the live `chat_message_list.dart`: (1) duplicate "Sending…" indicator (rendered twice for outgoing sending messages); (2) inaccessible failed-send controls — extracted `ChatFailedMessageActions` with an icon+text failure label (visible without colour) and Retry/Delete as real buttons with ≥48dp tap targets + explicit semantic labels. Covered by `chat_failed_message_actions_test.dart`. Finding (tracked): `chat_message_bubble.dart` (`ChatMessageBubble`) is dead, unreferenced duplicate code carrying the same bug — should be removed or adopted. Remaining: manual screen-reader pass. See `docs/reports/chat_ui_audit_2026-06-01.md`.
