import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connection state for real-time connections.
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Base class for real-time events.
abstract class RealtimeEvent {
  const RealtimeEvent();

  String get type;
  Map<String, dynamic> toJson();
}

/// WebSocket-based real-time connection manager.
///
/// Features:
/// - Automatic reconnection with exponential backoff
/// - Heartbeat/ping-pong for connection health
/// - Event-based message handling
/// - Connection state management
class WebSocketConnection {
  WebSocketConnection({
    required this.url,
    this.authToken,
    this.reconnectAttempts = 5,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.heartbeatInterval = const Duration(seconds: 30),
  });

  final String url;
  final String? authToken;
  final int reconnectAttempts;
  final Duration initialReconnectDelay;
  final Duration maxReconnectDelay;
  final Duration heartbeatInterval;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectCount = 0;
  bool _intentionalDisconnect = false;

  final _stateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<dynamic>.broadcast();

  ConnectionState _state = ConnectionState.disconnected;

  /// Current connection state.
  ConnectionState get state => _state;

  /// Stream of connection state changes.
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// Stream of incoming messages.
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream of errors.
  Stream<dynamic> get errorStream => _errorController.stream;

  /// Whether currently connected.
  bool get isConnected => _state == ConnectionState.connected;

  /// Connect to the WebSocket server.
  Future<void> connect() async {
    if (_state == ConnectionState.connected ||
        _state == ConnectionState.connecting) {
      return;
    }

    _intentionalDisconnect = false;
    _setState(ConnectionState.connecting);

    try {
      final uri = Uri.parse(url);
      final headers = <String, String>{};

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      _channel = WebSocketChannel.connect(uri, protocols: ['json']);

      // Wait for connection to be established
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _setState(ConnectionState.connected);
      _reconnectCount = 0;
      _startHeartbeat();

      debugPrint('WebSocketConnection: Connected to $url');
    } catch (e) {
      debugPrint('WebSocketConnection: Connection failed - $e');
      _setState(ConnectionState.failed);
      _errorController.add(e);
      _scheduleReconnect();
    }
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _stopHeartbeat();
    _cancelReconnect();

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _setState(ConnectionState.disconnected);
    debugPrint('WebSocketConnection: Disconnected');
  }

  /// Send a message to the server.
  void send(Map<String, dynamic> message) {
    if (!isConnected || _channel == null) {
      debugPrint('WebSocketConnection: Cannot send - not connected');
      return;
    }

    try {
      final encoded = jsonEncode(message);
      _channel!.sink.add(encoded);
    } catch (e) {
      debugPrint('WebSocketConnection: Send error - $e');
      _errorController.add(e);
    }
  }

  /// Send a typed event.
  void sendEvent(RealtimeEvent event) {
    send({
      'type': event.type,
      ...event.toJson(),
    });
  }

  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> message;
      if (data is String) {
        message = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        message = data;
      } else {
        debugPrint('WebSocketConnection: Unknown message format');
        return;
      }

      // Handle pong messages internally
      if (message['type'] == 'pong') {
        return;
      }

      _messageController.add(message);
    } catch (e) {
      debugPrint('WebSocketConnection: Parse error - $e');
      _errorController.add(e);
    }
  }

  void _onError(dynamic error) {
    debugPrint('WebSocketConnection: Error - $error');
    _errorController.add(error);
  }

  void _onDone() {
    debugPrint('WebSocketConnection: Connection closed');
    _stopHeartbeat();

    if (!_intentionalDisconnect) {
      _setState(ConnectionState.reconnecting);
      _scheduleReconnect();
    } else {
      _setState(ConnectionState.disconnected);
    }
  }

  void _setState(ConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (isConnected) {
        send({
          'type': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch
        });
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect || _reconnectCount >= reconnectAttempts) {
      _setState(ConnectionState.failed);
      return;
    }

    _cancelReconnect();

    // Exponential backoff with jitter
    final delay = _calculateReconnectDelay();
    debugPrint(
        'WebSocketConnection: Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectCount + 1}/$reconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      _reconnectCount++;
      connect();
    });
  }

  Duration _calculateReconnectDelay() {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, ...
    final baseDelay =
        initialReconnectDelay.inMilliseconds * (1 << _reconnectCount);
    final cappedDelay = baseDelay.clamp(0, maxReconnectDelay.inMilliseconds);

    // Add jitter (±20%)
    final jitter =
        (cappedDelay * 0.2 * (DateTime.now().millisecond / 1000 - 0.5)).round();
    return Duration(milliseconds: cappedDelay + jitter);
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Dispose resources.
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
    _errorController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REALTIME EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Chat message received event.
class MessageReceivedEvent extends RealtimeEvent {
  const MessageReceivedEvent({
    required this.conversationId,
    required this.messageId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    this.timestamp,
  });

  final String conversationId;
  final String messageId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime? timestamp;

  @override
  String get type => 'message_received';

  @override
  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'message_id': messageId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };

  factory MessageReceivedEvent.fromJson(Map<String, dynamic> json) {
    return MessageReceivedEvent(
      conversationId: json['conversation_id'] as String? ?? '',
      messageId: json['message_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
    );
  }
}

/// Typing indicator event.
class TypingEvent extends RealtimeEvent {
  const TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  final String conversationId;
  final String userId;
  final bool isTyping;

  @override
  String get type => 'typing';

  @override
  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
      };

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      conversationId: json['conversation_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      isTyping: json['is_typing'] as bool? ?? false,
    );
  }
}

/// Read receipt event.
class ReadReceiptEvent extends RealtimeEvent {
  const ReadReceiptEvent({
    required this.conversationId,
    required this.userId,
    required this.lastReadMessageId,
  });

  final String conversationId;
  final String userId;
  final String lastReadMessageId;

  @override
  String get type => 'read_receipt';

  @override
  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'user_id': userId,
        'last_read_message_id': lastReadMessageId,
      };

  factory ReadReceiptEvent.fromJson(Map<String, dynamic> json) {
    return ReadReceiptEvent(
      conversationId: json['conversation_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      lastReadMessageId: json['last_read_message_id'] as String? ?? '',
    );
  }
}

/// User presence event.
class PresenceEvent extends RealtimeEvent {
  const PresenceEvent({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;

  @override
  String get type => 'presence';

  @override
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'is_online': isOnline,
        if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      };

  factory PresenceEvent.fromJson(Map<String, dynamic> json) {
    return PresenceEvent(
      userId: json['user_id'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'] as String)
          : null,
    );
  }
}

/// New match event.
class NewMatchEvent extends RealtimeEvent {
  const NewMatchEvent({
    required this.matchId,
    required this.matchedUserId,
    this.matchedUserName,
    this.matchedUserPhoto,
    this.isSuperLike = false,
  });

  final String matchId;
  final String matchedUserId;
  final String? matchedUserName;
  final String? matchedUserPhoto;
  final bool isSuperLike;

  @override
  String get type => 'new_match';

  @override
  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'matched_user_id': matchedUserId,
        if (matchedUserName != null) 'matched_user_name': matchedUserName,
        if (matchedUserPhoto != null) 'matched_user_photo': matchedUserPhoto,
        'is_super_like': isSuperLike,
      };

  factory NewMatchEvent.fromJson(Map<String, dynamic> json) {
    return NewMatchEvent(
      matchId: json['match_id'] as String? ?? '',
      matchedUserId: json['matched_user_id'] as String? ?? '',
      matchedUserName: json['matched_user_name'] as String?,
      matchedUserPhoto: json['matched_user_photo'] as String?,
      isSuperLike: json['is_super_like'] as bool? ?? false,
    );
  }
}
