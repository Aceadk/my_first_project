# TODO: Chat & Messaging — UI
**Priority:** P0
**Estimated Effort:** 40-60 hours
**Dependencies:** TODO_IPAD_COMPLIANCE.md, TODO_RESPONSIVE_DESIGN.md
**Assigned:** AI + Developer

---

## CHAT-UI-001: Implement Responsive Chat Layout for iPad
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart` (3230 lines), `chat_list_screen.dart`
**Description:** ChatScreen has ZERO responsive layout code (no LayoutBuilder, no MediaQuery checks). On iPad, implement split-view: conversation list (left) + active chat (right). Use AdaptiveLayout widget.
**Acceptance Criteria:**
- [ ] iPad (>600px): side-by-side layout — conversation list (320px) + chat
- [ ] iPhone (<600px): current single-column navigation preserved
- [ ] Smooth transition between layouts on orientation change
- [ ] Conversation selection updates right panel without full navigation
**Testing:** iPad Air 10.9" in portrait and landscape.

---

## CHAT-UI-002: Fix Keyboard Handling on iPad
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`
**Description:** Chat input has no keyboard visibility management. On iPad with external keyboard, the input area should adapt. On-screen keyboard should not obscure messages.
**Acceptance Criteria:**
- [ ] External keyboard: Enter sends message, Shift+Enter for new line
- [ ] On-screen keyboard: message list scrolls to show latest messages
- [ ] Keyboard dismiss on tap outside input area
- [ ] Input bar stays above keyboard in all orientations
- [ ] iPad Split View: keyboard width adapts to window width
**Testing:** iPad with Magic Keyboard and on-screen keyboard.

---

## CHAT-UI-003: Add Accessibility Labels to All Chat Elements
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`, all chat widgets
**Description:** ChatScreen has ZERO Semantics calls. Add semantic labels to: message bubbles, timestamps, media, send button, call buttons, typing indicator, voice recorder.
**Acceptance Criteria:**
- [ ] Message bubbles: "Message from [name]: [content], sent at [time]"
- [ ] Media messages: "Photo from [name]" / "Voice note from [name], [duration]"
- [ ] Send button: "Send message"
- [ ] Call buttons: "Start voice call" / "Start video call"
- [ ] Typing indicator: "[name] is typing" (announced as live region)
- [ ] Read receipts: "Read at [time]" / "Delivered"
- [ ] Input field: "Type a message to [name]"
**Testing:** VoiceOver on iPhone and iPad; TalkBack on Android.

---

## CHAT-UI-004: Implement Media Preview Sizing for All Screen Sizes
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`
**Description:** Media previews (photos, videos) in chat should adapt to screen size. On iPhone: max 70% width. On iPad: max 400px width. On desktop: max 500px width.
**Acceptance Criteria:**
- [ ] Image bubble max width: 70% on phone, 400px on tablet, 500px on desktop
- [ ] Video thumbnail maintains aspect ratio
- [ ] Tap to expand to full-screen viewer (works on all sizes)
- [ ] Loading placeholder shown during download
**Testing:** Send image in chat, verify on iPhone SE, iPad Air, iPad Pro 12.9".

---

## CHAT-UI-005: Fix Stream Listener Cleanup in ChatBloc
**Files:** `lib/features/chat/presentation/bloc/chat_bloc.dart`
**Description:** _typingSub, _presenceSub, _mediaSub are cancelled in ChatClosed handler, but if that handler fails, streams stay active. Sub-BLoCs (_realtimeCubit, _sessionCubit, _messageBloc) never explicitly closed. Risk of memory leaks.
**Acceptance Criteria:**
- [ ] All stream subscriptions cancelled in close() method (not just ChatClosed)
- [ ] Sub-BLoCs explicitly closed in ChatBloc.close()
- [ ] Error in one cleanup doesn't prevent others from running
- [ ] No dangling Firestore listeners after navigating away from chat
**Testing:** Unit test: open chat → close → verify all subscriptions cancelled.

---

## CHAT-UI-006: Add EXIF Stripping to Chat Media Uploads
**Files:** `lib/features/chat/data/repositories/impl/firebase_chat_repository.dart`
**Description:** Photos shared in chat retain EXIF metadata (GPS location, device info, timestamps). Strip EXIF before upload for privacy.
**Acceptance Criteria:**
- [ ] All image uploads strip EXIF data before sending to Firebase Storage
- [ ] GPS coordinates removed
- [ ] Device model/software info removed
- [ ] Image quality preserved after EXIF stripping
**Testing:** Upload photo with known GPS EXIF → download → verify EXIF empty.

---

## CHAT-UI-007: Add Message List Virtualization for Large Histories
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`
**Description:** Chat uses reversed ListView. For conversations with 1000+ messages, performance degrades. Implement proper virtualization or pagination with limited in-memory messages.
**Acceptance Criteria:**
- [ ] Maximum 100 messages in memory at a time
- [ ] Smooth scrolling up triggers pagination (load 50 more)
- [ ] No jank when scrolling through long histories
- [ ] Scroll position maintained during pagination loads
**Testing:** Test with 500+ messages in a conversation; profile with Flutter DevTools.

---

## CHAT-UI-008: Implement Message Retry UI
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`
**Description:** Failed messages should show error indicator with tap-to-retry. Currently, retry exists in BLoC but UI feedback is unclear.
**Acceptance Criteria:**
- [ ] Failed message shows red error icon
- [ ] Tap on failed message shows "Retry" / "Delete" options
- [ ] Retry uses exponential backoff
- [ ] Failed messages persisted across app restart
**Testing:** Turn off network, send message, verify error UI, turn on network, tap retry.
