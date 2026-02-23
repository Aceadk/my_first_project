# Chat Realtime Module

Priority: P1-P2

This document tracks outstanding remediation and audit actions for the Chat Realtime domain.

## Action Items

### [x] RT-001: Auth headers not passed to WebSocket connection (P1)

- **Description**: `connect()` builds an `Authorization: Bearer` header map but never passes it to `WebSocketChannel.connect()`. The `protocols` parameter is set to `['json']` but the `headers` dict is unused. WebSocket connections are effectively unauthenticated.
- **Affected Files**: `lib/core/network/realtime/realtime_connection.dart` (lines 88-94)
- **Fix**: Use `WebSocketChannel.connect(uri, protocols: ['json'], headers: headers)` or pass the auth token as a query parameter if the server doesn't accept WS headers.

### [x] RT-002: No pong timeout — stale connections go undetected (P1)

- **Description**: The heartbeat sends `ping` every 30s but never checks if a `pong` was received. If the server silently drops the connection, the client stays in `connected` state indefinitely with no messages flowing.
- **Affected Files**: `lib/core/network/realtime/realtime_connection.dart` (lines 203-213)
- **Fix**: Track `_lastPongReceived` timestamp. If no pong arrives within 2× heartbeat interval, trigger reconnect.

### [x] RT-003: `dispose()` ignores `disconnect()` Future (P2)

- **Description**: `dispose()` calls `disconnect()` (async) but doesn't await it. Resources may not be cleaned up before stream controllers are closed.
- **Affected Files**: `lib/core/network/realtime/realtime_connection.dart` (lines 258-263)
- **Fix**: Make `dispose()` async and await `disconnect()`, or use `unawaited()` with a comment if fire-and-forget is intentional.

### [x] RT-004: `ChatSessionCubit` calls `setE2eeEnabled(true)` at init — crashes on HTTP backend (P1)

- **Description**: `ChatSessionCubit` constructor calls `chatRepository.setE2eeEnabled(_e2eeEnabled)` where `_e2eeEnabled` defaults to `true`. After CHAT-006, the HTTP repository now throws an exception when E2EE is enabled. This causes a crash at chat session initialization on the HTTP backend.
- **Affected Files**: `lib/features/chat/presentation/bloc/chat_session_cubit.dart` (line 68)
- **Fix**: Wrap the `setE2eeEnabled` call in a try-catch, or check `chatRepository.isE2eeEnabled` support before calling.

### [x] RT-005: `read_receipt` events not handled in WebSocket listener (P2)

- **Description**: The WebSocket `_onWebSocketMessage` handler in `HttpChatRepository` handles `message_received`, `typing`, and `presence` events but ignores `read_receipt` events. The `ReadReceiptEvent` class exists but is never used.
- **Affected Files**: `lib/features/chat/data/repositories/impl/http_chat_repository.dart`
- **Fix**: Add a `read_receipt` case to the WebSocket message handler that triggers a message refresh or updates read status locally.

### [x] RT-006: Weak jitter in reconnect delay calculation (P2)

- **Description**: `_calculateReconnectDelay()` uses `DateTime.now().millisecond / 1000 - 0.5` for jitter, which produces a very limited and predictable range. If many clients reconnect simultaneously (server restart), they'll cluster.
- **Affected Files**: `lib/core/network/realtime/realtime_connection.dart` (lines 240-249)
- **Fix**: Use `Random.secure()` for proper jitter: `Random.secure().nextDouble() * 0.4 - 0.2` (±20%).
