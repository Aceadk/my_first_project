# Chat Backend Module

Priority: P1-P2

This document tracks outstanding remediation and audit actions for the Chat Backend domain.

## Action Items

### [x] CHAT-001: Missing Circuit Breaker on `unblockUser` and `unmatch` (P1)

- **Description**: `unblockUser()` and `unmatch()` bypass the circuit breaker — if the backend is down, these calls will silently fail or throw uncaught exceptions instead of tripping the breaker.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart`
- **Fix**: Wrap both methods with `_circuitBreaker.allowRequest()` guard and record success/failure.

### [x] CHAT-002: `toUserId` hardcoded to empty string in message mapper (P1)

- **Description**: `ChatMapper.messageFromDto(m, toUserId: '')` is called in `fetchMessagesPaginated()` and `_fetchMessages()` with an empty string for `toUserId`. This may cause incorrect "is mine" checks in the UI.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart` (lines 103, 168)
- **Fix**: Pass the authenticated user's ID as `toUserId` so the mapper can correctly determine message ownership.

### [x] CHAT-003: No file size validation on media upload (P2)

- **Description**: `uploadMedia()` checks that the file exists but doesn't validate file size before uploading. Large files will consume bandwidth and may time out or hit server-side limits without a clear error.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart`
- **Fix**: Add file size check (e.g., 25 MB for images, 100 MB for video) before making the upload request.

### [x] CHAT-004: Message requests throw `UnsupportedError` (P2)

- **Description**: `sendMessageRequest()` throws `UnsupportedError` in the HTTP repository. If called from the UI, this creates an unhandled crash instead of a user-friendly error.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart` (line 738)
- **Fix**: Implement as an HTTP POST to `/chat/message-requests/send`, or at minimum throw a user-friendly `Exception` instead of `UnsupportedError`.

### [x] CHAT-005: WebSocket message listener not wired (P1)

- **Description**: `_startMessagePolling()` correctly skips polling when WebSocket is connected, but there's no code actually listening to incoming WebSocket message events to push them into `_messageControllers`. This means real-time message delivery is broken when WebSocket is active.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart`
- **Fix**: Subscribe to `_webSocket.onMessage` (or equivalent) in the constructor and route incoming events to the appropriate `_messageControllers[matchId]` stream.

### [x] CHAT-006: E2EE stubs should log warning when toggled (P2)

- **Description**: `setE2eeEnabled()` is a no-op in the HTTP implementation. If a user toggles E2EE in the UI, nothing happens and no feedback is given.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart` (line 831)
- **Fix**: Log a warning and throw an informative exception when E2EE is toggled but not supported.

### [x] CHAT-007: Typing indicator auto-cancel timer missing (P2)

- **Description**: `setTyping(isTyping: true)` is sent via WebSocket or HTTP, but there's no auto-cancel timer on the client side. If the app crashes while typing, the "is typing..." indicator shows indefinitely for the other user.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart`
- **Fix**: Add a 10-second `Timer` that automatically sends `setTyping(isTyping: false)` when no new keystrokes are detected.

### [x] CHAT-008: `editMessage` missing content sanitization (P1)

- **Description**: `editMessage()` in the repository directly sends `newContent` to the server without running it through `InputSanitizer.sanitizeMessage()`. While `SendMessageUseCase` sanitizes on initial send, the edit path bypasses sanitization entirely.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart` (line 304)
- **Fix**: Apply `InputSanitizer.sanitizeMessage(newContent)` before sending the PATCH request.
