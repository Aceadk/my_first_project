# Chat UI Audit — CHAT-UI-001 / 002 / 003

- Date: 2026-06-01
- Source TODO: `docs/TODO_CHAT_UI.md`
- Scope: chat screens & conversation list
  (`lib/features/chat/presentation/screens/`), message composer, message list /
  bubble surfaces, attachment previews, failed/pending/retry controls
  (`lib/features/chat/presentation/widgets/`).
- Verification (local, full toolchain):
  - `flutter analyze` on all changed files: **clean, 0 issues.**
  - `flutter test` (4 suites): **16 passing** —
    `chat_composer_keyboard_test`, `chat_failed_message_actions_test`,
    `chat_list_screen_responsive_test`, `chat_screen_responsive_test`.
  - Not run here (needs a device): manual iPad portrait/landscape, hardware-
    keyboard, and screen-reader passes — tracked below.

Legend: ✅ already correct · ⚠️ gap found · 🔧 fixed this pass · 🔎 tracked.

---

## CHAT-UI-001 — Wide-screen chat layout & navigation model (🔧 fixed)

### What was already correct
- The conversation list (`chat_list_screen.dart`) already renders a
  **master-detail split view** on tablet/desktop (list pane + embedded
  `ChatScreen` detail) and a single column on phones.
- `ChatScreen` constrains the conversation column to a readable max width
  (`chatConversationMaxWidthFor`, 720/960) so message columns don't stretch on
  wide screens, and message bubbles cap at 480px.
- Pane width is computed responsively (`chatListPaneWidthFor`).

### ⚠️ Gap found — navigation model could disagree with itself
The layout decided single-column vs. split-view from the `LayoutBuilder`
**constraints** (`constraints.maxWidth`), but `_onChatTileTap` decided push-vs-
select from **`MediaQuery.of(context).size.width`** (the whole device/window).
These differ whenever the list is rendered in a constrained region (a tablet
shell with a nav rail, or iPad split-screen multitasking where the app occupies
a narrow column of a wide device). The failure modes:
- constraints say *mobile* (no detail pane) but MediaQuery says *tablet* →
  tapping a conversation calls `setState(_selectedChat = …)`, which the
  single-column layout ignores → **the tap appears to do nothing**;
- the inverse → a full-screen push stacked over the split view.

### 🔧 Fix
Introduced a single source of truth — `chatUsesSplitView(double width)` — and
used it in **both** the `LayoutBuilder` branch and the tile tap handler (the tap
handler now receives the layout's decision rather than re-deriving it from a
different width). Also made the "Select a conversation" detail-pane placeholder
theme-aware (it hard-coded the light-mode muted colour).

Covered by `chat_list_screen_responsive_test.dart` (`chatUsesSplitView` phone vs
tablet/desktop) alongside the existing pane-width cases.

### 🔎 Tracked
- Manual iPad portrait/landscape + split-screen multitasking pass to confirm the
  pane proportions and that selection survives rotation.

---

## CHAT-UI-002 — Keyboard / composer behaviour (🔧 fixed)

### What was already correct
- `ChatInputBar` handles Enter (send) / Shift+Enter (newline) via a raw key
  handler, uses a `FocusTraversalGroup(OrderedTraversalPolicy())` so focus order
  follows reading order (media buttons → field → send), and the scaffold
  (`AsyncStateScaffold` → `Scaffold`) resizes for the soft keyboard.

### ⚠️ Gap found — Enter fired on key-repeat
The handler sent on `KeyDownEvent` **or** `KeyRepeatEvent`, so holding Enter
fired a burst of duplicate sends. The Enter/Shift semantics were also inlined in
the widget, making them impossible to unit-test.

### 🔧 Fix
New pure policy `chat_composer_keyboard.dart` —
`ChatComposerKeyboard.actionForEnter({isKeyDown, isKeyRepeat, isShiftPressed})`
→ `send` / `insertNewline` / `ignore`:
- plain Enter sends **only on the initial key-down** (repeat/up are consumed, so
  a held Enter can't spam-send and no stray newline is inserted);
- Shift+Enter inserts a newline on press and repeat (hold to add lines).

`ChatInputBar._handleKeyEvent` now delegates to it and also recognises
numpad-Enter. Covered exhaustively by `chat_composer_keyboard_test.dart`.

### 🔎 Tracked
- Manual hardware-keyboard pass on iPad (Tab focus traversal, external keyboard
  Enter/Shift+Enter, orientation change while composing).

---

## CHAT-UI-003 — Media preview, failed-send & retry UX (🔧 fixed + 🔎 finding)

### What was already correct
- Media is size-capped (≤400px wide, ≤40% screen height) with broken-media
  placeholders; pending-scan and held/blocked states render explanatory text +
  shield icon (not colour alone); read receipts show an icon + "Seen" text.

### ⚠️ Gaps found (in the live `chat_message_list.dart`)
1. **Duplicate "Sending…" indicator.** For an outgoing `sending` message the
   list rendered the spinner+"Sending…" row **twice** — once in the status row
   and again in a separate "Sending indicator" block — so the text appeared
   doubled.
2. **Inaccessible failed-send controls.** "Retry"/"Delete" were bare
   `GestureDetector`+`Text` with sub-44dp tap targets and no button semantic
   labels.

### 🔧 Fix
- Removed the duplicate sending block (the status row already renders "Sending…"
  consistently with the sent/seen states).
- Extracted `ChatFailedMessageActions` — an icon+text failure label (visible
  without colour) plus Retry/Delete as real buttons with ≥48dp
  (`kMinInteractiveDimension`) tap targets and explicit screen-reader labels
  ("Retry sending message" / "Delete failed message"). The list now uses it and
  passes closures that dispatch the existing retry/discard events.

Covered by `chat_failed_message_actions_test.dart` (failure visible via text +
icon; Retry/Delete invoke callbacks; explicit semantic labels; 48dp tap
targets).

### 🔎 Finding (tracked, not changed) — dead duplicate bubble widget
`lib/features/chat/presentation/widgets/chat_message_bubble.dart`
(`ChatMessageBubble`, ~600 lines) is **never referenced** anywhere — the live UI
renders bubbles inline in `chat_message_list.dart`. It carried the *same*
duplicate-"Sending…" bug. Left in place (deleting a large, unreferenced file is
out of scope for this audit and risks hidden imports), but it should be removed
or the inline list refactored to use it so there is one bubble implementation.

---

## Summary of changes this pass
- `lib/features/chat/presentation/widgets/chat_composer_keyboard.dart` — new
  pure Enter/Shift policy.
- `lib/features/chat/presentation/widgets/chat_input_bar.dart` — delegate key
  handling to the policy; recognise numpad-Enter; no key-repeat send.
- `lib/features/chat/presentation/screens/chat_list_screen.dart` —
  `chatUsesSplitView` single source of truth for the navigation model;
  theme-aware detail placeholder.
- `lib/features/chat/presentation/widgets/chat_failed_message_actions.dart` —
  new accessible failed-send actions widget.
- `lib/features/chat/presentation/widgets/chat_message_list.dart` — drop the
  duplicate sending indicator; use `ChatFailedMessageActions`.
- Tests: `chat_composer_keyboard_test.dart` (new),
  `chat_failed_message_actions_test.dart` (new), `chatUsesSplitView` cases added
  to `chat_list_screen_responsive_test.dart`.

## Tracked follow-ups
1. Remove the dead `ChatMessageBubble` (or refactor the list to use it) so there
   is a single bubble implementation.
2. Manual device passes: iPad portrait/landscape + split-screen (CHAT-UI-001),
   hardware keyboard + orientation (CHAT-UI-002), screen-reader over
   failed/pending/media states (CHAT-UI-003).
