import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/network/realtime/realtime_connection.dart';

void main() {
  group('WebSocketConnection', () {
    test('connects, sends, receives, and disconnects cleanly', () async {
      final server = await _WsTestServer.start();
      final connection = WebSocketConnection(
        url: server.url,
        reconnectAttempts: 1,
        heartbeatInterval: const Duration(seconds: 5),
      );

      final states = <ConnectionState>[];
      final stateSub = connection.stateStream.listen(states.add);

      await connection.connect();
      expect(connection.isConnected, isTrue);

      final incomingFuture = connection.messageStream.first;
      connection.send({'type': 'custom', 'value': 1});
      final outbound = await server.messages.first;
      expect(outbound, contains('"type":"custom"'));
      expect(outbound, contains('"value":1'));

      await server.sendJson({'type': 'chat', 'id': 'msg-1'});
      final incoming = await incomingFuture;
      expect(incoming['type'], 'chat');
      expect(incoming['id'], 'msg-1');

      connection.sendEvent(
        const TypingEvent(
          conversationId: 'conv-1',
          userId: 'u-1',
          isTyping: true,
        ),
      );
      final typedOutbound = await server.messages.first;
      expect(typedOutbound, contains('"type":"typing"'));
      expect(typedOutbound, contains('"conversation_id":"conv-1"'));

      await connection.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(connection.state, ConnectionState.disconnected);
      expect(
        states,
        containsAll([
          ConnectionState.connecting,
          ConnectionState.connected,
          ConnectionState.disconnected,
        ]),
      );

      await stateSub.cancel();
      connection.dispose();
      await server.close();
    });

    test('ignores pong payloads and emits parse errors', () async {
      final server = await _WsTestServer.start();
      final connection = WebSocketConnection(
        url: server.url,
        reconnectAttempts: 0,
      );

      await connection.connect();

      var messageCount = 0;
      final messageSub = connection.messageStream.listen((_) => messageCount++);
      await server.sendRaw('{"type":"pong"}');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(messageCount, 0);

      final parseErrorFuture = connection.errorStream.first;
      await server.sendRaw('not-json');
      final parseError = await parseErrorFuture.timeout(
        const Duration(seconds: 2),
      );
      expect(parseError, isA<Object>());

      await messageSub.cancel();
      await connection.disconnect();
      connection.dispose();
      await server.close();
    });

    test('fails immediately when connection cannot be established', () async {
      final connection = WebSocketConnection(
        url: 'ws://127.0.0.1:1',
        reconnectAttempts: 0,
        initialReconnectDelay: const Duration(milliseconds: 10),
      );

      await connection.connect();
      expect(connection.state, ConnectionState.failed);

      connection.dispose();
    });

    test(
      'unintentional close triggers reconnecting then failed at limit',
      () async {
        final server = await _WsTestServer.start();
        final connection = WebSocketConnection(
          url: server.url,
          reconnectAttempts: 0,
          initialReconnectDelay: const Duration(milliseconds: 10),
        );

        final states = <ConnectionState>[];
        final sub = connection.stateStream.listen(states.add);

        await connection.connect();
        await server.closeFirstClient();

        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(states, contains(ConnectionState.reconnecting));
        expect(connection.state, ConnectionState.failed);

        await connection.disconnect();
        await sub.cancel();
        await server.close();
      },
    );

    test('heartbeat sends ping messages while connected', () async {
      final server = await _WsTestServer.start();
      final connection = WebSocketConnection(
        url: server.url,
        heartbeatInterval: const Duration(milliseconds: 30),
      );

      await connection.connect();

      final pingMessage = await server.messages
          .firstWhere((value) => value.contains('"type":"ping"'))
          .timeout(const Duration(seconds: 2));
      expect(pingMessage, contains('"timestamp"'));

      await connection.disconnect();
      connection.dispose();
      await server.close();
    });

    test('heartbeat timeout closes stale socket before marking failed', () async {
      final server = await _WsTestServer.start();
      final connection = WebSocketConnection(
        url: server.url,
        reconnectAttempts: 0,
        heartbeatInterval: const Duration(milliseconds: 30),
      );

      await connection.connect();
      expect(connection.state, ConnectionState.connected);
      expect(server.activeClientCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 220));

      expect(connection.state, ConnectionState.failed);
      expect(server.activeClientCount, 0);

      await connection.disconnect();
      await connection.dispose();
      await server.close();
    });

    test('send and sendEvent are no-ops when disconnected', () {
      final connection = WebSocketConnection(url: 'ws://127.0.0.1:1');

      connection.send({'type': 'noop'});
      connection.sendEvent(
        const ReadReceiptEvent(
          conversationId: 'c',
          userId: 'u',
          lastReadMessageId: 'm',
        ),
      );

      expect(connection.isConnected, isFalse);
      connection.dispose();
    });
  });

  group('RealtimeEvent models', () {
    test('MessageReceivedEvent toJson/fromJson and type', () {
      final now = DateTime.parse('2026-02-21T12:00:00.000Z');
      final event = MessageReceivedEvent(
        conversationId: 'c1',
        messageId: 'm1',
        senderId: 'u1',
        content: 'hello',
        timestamp: now,
      );
      expect(event.type, 'message_received');
      expect(event.toJson()['timestamp'], '2026-02-21T12:00:00.000Z');

      final parsed = MessageReceivedEvent.fromJson({
        'conversation_id': 'c1',
        'message_id': 'm1',
        'sender_id': 'u1',
        'content': 'hello',
        'message_type': 'text',
        'timestamp': '2026-02-21T12:00:00.000Z',
      });
      expect(parsed.conversationId, 'c1');
      expect(parsed.timestamp, now);
    });

    test('TypingEvent toJson/fromJson', () {
      const event = TypingEvent(
        conversationId: 'c2',
        userId: 'u2',
        isTyping: true,
      );
      expect(event.type, 'typing');
      expect(event.toJson()['is_typing'], isTrue);

      final parsed = TypingEvent.fromJson({
        'conversation_id': 'c2',
        'user_id': 'u2',
        'is_typing': false,
      });
      expect(parsed.isTyping, isFalse);
    });

    test('ReadReceiptEvent toJson/fromJson', () {
      const event = ReadReceiptEvent(
        conversationId: 'c3',
        userId: 'u3',
        lastReadMessageId: 'm3',
      );
      expect(event.type, 'read_receipt');
      expect(event.toJson()['last_read_message_id'], 'm3');

      final parsed = ReadReceiptEvent.fromJson({
        'conversation_id': 'c3',
        'user_id': 'u3',
        'last_read_message_id': 'm3',
      });
      expect(parsed.lastReadMessageId, 'm3');
    });

    test('PresenceEvent and NewMatchEvent parse defaults safely', () {
      final presence = PresenceEvent.fromJson(const {});
      expect(presence.type, 'presence');
      expect(presence.userId, '');
      expect(presence.isOnline, isFalse);

      final match = NewMatchEvent.fromJson(const {});
      expect(match.type, 'new_match');
      expect(match.matchId, '');
      expect(match.matchedUserId, '');
      expect(match.isSuperLike, isFalse);
    });
  });
}

class _WsTestServer {
  _WsTestServer._(this._server) {
    _server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      _clients.add(socket);
      socket.listen(
        (data) {
          if (data is String) {
            _messages.add(data);
          } else {
            _messages.add(data.toString());
          }
        },
        onDone: () {
          _clients.remove(socket);
        },
      );
    });
  }

  final HttpServer _server;
  final List<WebSocket> _clients = <WebSocket>[];
  final StreamController<String> _messages =
      StreamController<String>.broadcast();

  static Future<_WsTestServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _WsTestServer._(server);
  }

  String get url => 'ws://${_server.address.address}:${_server.port}';

  Stream<String> get messages => _messages.stream;

  int get activeClientCount => _clients.length;

  Future<void> sendJson(Map<String, dynamic> message) async {
    final payload = jsonEncode(message);
    for (final client in List<WebSocket>.from(_clients)) {
      client.add(payload);
    }
  }

  Future<void> sendRaw(String payload) async {
    for (final client in List<WebSocket>.from(_clients)) {
      client.add(payload);
    }
  }

  Future<void> closeFirstClient() async {
    if (_clients.isEmpty) return;
    await _clients.first.close(WebSocketStatus.normalClosure);
  }

  Future<void> close() async {
    for (final client in List<WebSocket>.from(_clients)) {
      await client.close(WebSocketStatus.normalClosure);
    }
    await _server.close(force: true);
    await _messages.close();
  }
}
