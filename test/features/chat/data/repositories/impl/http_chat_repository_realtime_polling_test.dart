import 'dart:async';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/realtime/realtime_connection.dart';
import 'package:crushhour/features/chat/data/repositories/impl/http_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpChatRepository realtime polling fallback', () {
    test('pauses and resumes polling when websocket state changes', () async {
      final apiClient = _FakeApiClient();
      final webSocket = _FakeWebSocketConnection();
      final repo = HttpChatRepository(
        apiClient: apiClient,
        webSocket: webSocket,
      );

      repo.watchMessages('match-1');
      repo.watchPresence('user-1');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repo.activePollingTimerKeys, contains('messages_match-1'));
      expect(repo.activePollingTimerKeys, contains('presence_user-1'));

      webSocket.emitState(ConnectionState.connected);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.activePollingTimerKeys, isNot(contains('messages_match-1')));
      expect(repo.activePollingTimerKeys, isNot(contains('presence_user-1')));

      webSocket.emitState(ConnectionState.reconnecting);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.activePollingTimerKeys, contains('messages_match-1'));
      expect(repo.activePollingTimerKeys, contains('presence_user-1'));

      // Re-emitting non-connected state should not duplicate timers.
      final timerCountBefore = repo.activePollingTimerKeys.length;
      webSocket.emitState(ConnectionState.failed);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.activePollingTimerKeys.length, timerCountBefore);

      repo.dispose();
      await webSocket.disposeFake();
      apiClient.dispose();
    });

    test('watchers created while connected start polling after disconnect', () async {
      final apiClient = _FakeApiClient();
      final webSocket = _FakeWebSocketConnection(
        initialState: ConnectionState.connected,
      );
      final repo = HttpChatRepository(
        apiClient: apiClient,
        webSocket: webSocket,
      );

      repo.watchMessages('match-2');
      repo.watchPresence('user-2');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repo.activePollingTimerKeys, isNot(contains('messages_match-2')));
      expect(repo.activePollingTimerKeys, isNot(contains('presence_user-2')));

      webSocket.emitState(ConnectionState.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repo.activePollingTimerKeys, contains('messages_match-2'));
      expect(repo.activePollingTimerKeys, contains('presence_user-2'));

      repo.dispose();
      await webSocket.disposeFake();
      apiClient.dispose();
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(enableCertificatePinning: false);

  @override
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) async {
    dynamic payload = <String, dynamic>{};
    if (endpoint.contains('/messages')) {
      payload = <String, dynamic>{'messages': <Map<String, dynamic>>[]};
    } else if (endpoint.endsWith('/presence')) {
      payload = <String, dynamic>{'is_online': false};
    }

    if (parser != null) {
      return ApiResult.success(parser(payload));
    }
    return ApiResult.success(payload as T);
  }
}

class _FakeWebSocketConnection extends WebSocketConnection {
  _FakeWebSocketConnection({
    ConnectionState initialState = ConnectionState.disconnected,
  }) : _state = initialState,
       super(url: 'ws://127.0.0.1:1');

  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  ConnectionState _state;

  @override
  Stream<ConnectionState> get stateStream => _stateController.stream;

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  bool get isConnected => _state == ConnectionState.connected;

  void emitState(ConnectionState state) {
    _state = state;
    _stateController.add(state);
  }

  Future<void> disposeFake() async {
    await _stateController.close();
    await _messageController.close();
  }
}
