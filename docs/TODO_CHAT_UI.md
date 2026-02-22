# Chat & Messaging Frontend Module
Priority: P0
Scope: 1:1 messaging, typing indicators, media sharing, iPad multitasking modes.

## Action Items
### CHAT-UI-001: Implement responsive master-detail chat layout for iPad
- **Description**: Split the chat list and active conversation into a two-pane layout for screens wider than 600dp.
- **Affected Files**: lib/features/chat/presentation/screens/chat_list_screen.dart, lib/features/chat/presentation/screens/chat_screen.dart
- **Acceptance Criteria**: On iPad, tapping a conversation updates the right pane instead of pushing a new route. Ensure state is preserved when device rotates.
- **Testing Requirements**: Widget test rendering the app at 1024x768 and asserting both widgets are simultaneously in the tree.

### CHAT-UI-002: Fix keyboard handling on iPad (external keyboard)
- **Description**: Ensure the chat input respects hardware keyboards. Enter should send, Shift+Enter should newline.
- **Affected Files**: lib/features/chat/presentation/widgets/chat_input_bar.dart
- **Acceptance Criteria**: Hardware keyboard usage doesn't trigger the on-screen keyboard, and standard shortcuts apply.
- **Testing Requirements**: Manual test on iPad Pro with Magic Keyboard.

### CHAT-UI-003: Implement proper media preview sizing
- **Description**: Image attachments in chat should limit their height dynamically based on screen size, preventing oversized images on iPads.
- **Affected Files**: lib/features/chat/presentation/widgets/chat_attachment_tile.dart
- **Acceptance Criteria**: Media bubbles never exceed 40% of the screen height or 400px width.
- **Testing Requirements**: Visual verification with portrait/landscape photos on all device sizes.