import 'dart:async';
import 'dart:io';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/realtime/realtime_connection.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/chat/data/repositories/impl/http_chat_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_transport_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpChatRepository transport adapter', () {
    test('setTyping uses realtime transport when connected', () async {
      final transport = _FakeChatTransportAdapter(isRealtimeConnected: true);
      final repo = HttpChatRepository(transportAdapter: transport);

      await repo.setTyping(
        matchId: 'match-1',
        userId: 'user-1',
        isTyping: true,
      );

      expect(transport.sentRealtimeEvents.length, 1);
      expect(transport.sentRealtimeEvents.first, isA<TypingEvent>());
      expect(transport.postEndpoints, isEmpty);

      repo.dispose();
      await transport.dispose();
    });

    test(
      'setTyping falls back to HTTP when realtime is disconnected',
      () async {
        final transport = _FakeChatTransportAdapter(isRealtimeConnected: false);
        final repo = HttpChatRepository(transportAdapter: transport);

        await repo.setTyping(
          matchId: 'match-2',
          userId: 'user-1',
          isTyping: true,
        );

        expect(transport.sentRealtimeEvents, isEmpty);
        expect(transport.postEndpoints, contains('/chat/match-2/typing'));

        repo.dispose();
        await transport.dispose();
      },
    );

    test(
      'fetchMessagesPaginated maps adapter payloads into domain messages',
      () async {
        final transport = _FakeChatTransportAdapter(
          isRealtimeConnected: false,
          messagesPayload: {
            'messages': [
              {
                'id': 'm-1',
                'from_user_id': 'user-a',
                'to_user_id': 'user-b',
                'content': 'hello',
                'type': 'text',
                'sent_at': '2026-03-08T00:00:00.000Z',
                'is_read': false,
                'is_deleted_for_sender': false,
                'reactions': <String, dynamic>{},
              },
            ],
          },
        );
        final repo = HttpChatRepository(
          transportAdapter: transport,
          currentUserId: 'user-b',
        );

        final result = await repo.fetchMessagesPaginated('match-3', limit: 10);

        expect(result.items, hasLength(1));
        expect(result.items.first.id, 'm-1');
        expect(result.items.first.content, 'hello');
        expect(result.items.first.type, MessageType.text);
        expect(transport.getEndpoints, contains('/chat/match-3/messages'));

        repo.dispose();
        await transport.dispose();
      },
    );
  });
}

class _FakeChatTransportAdapter implements ChatTransportAdapter {
  _FakeChatTransportAdapter({
    required bool isRealtimeConnected,
    Map<String, dynamic>? messagesPayload,
  }) : _isRealtimeConnected = isRealtimeConnected,
       _messagesPayload =
           messagesPayload ?? {'messages': <Map<String, dynamic>>[]};

  final bool _isRealtimeConnected;
  final Map<String, dynamic> _messagesPayload;

  final List<RealtimeEvent> sentRealtimeEvents = <RealtimeEvent>[];
  final List<String> getEndpoints = <String>[];
  final List<String> postEndpoints = <String>[];

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();

  @override
  Stream<Map<String, dynamic>> get realtimeMessageStream =>
      _messageController.stream;

  @override
  Stream<ConnectionState> get realtimeStateStream => _stateController.stream;

  @override
  bool get isRealtimeConnected => _isRealtimeConnected;

  @override
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic p1)? parser,
    bool requiresAuth = true,
  }) async {
    getEndpoints.add(endpoint);

    dynamic payload = <String, dynamic>{};
    if (endpoint.contains('/messages')) {
      payload = _messagesPayload;
    } else if (endpoint.endsWith('/presence')) {
      payload = <String, dynamic>{'is_online': false};
    }

    if (parser != null) {
      return ApiResult.success(parser(payload));
    }
    return ApiResult.success(payload as T);
  }

  @override
  Future<ApiResult<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic p1)? parser,
    bool requiresAuth = true,
  }) async {
    postEndpoints.add(endpoint);

    if (parser != null) {
      return ApiResult.success(parser(<String, dynamic>{}));
    }
    return ApiResult.success(null as T);
  }

  @override
  Future<ApiResult<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic p1)? parser,
    bool requiresAuth = true,
  }) async {
    if (parser != null) {
      return ApiResult.success(parser(<String, dynamic>{}));
    }
    return ApiResult.success(null as T);
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String endpoint, {
    T Function(dynamic p1)? parser,
    bool requiresAuth = true,
  }) async {
    if (parser != null) {
      return ApiResult.success(parser(<String, dynamic>{}));
    }
    return ApiResult.success(null as T);
  }

  @override
  Future<ApiResult<T>> uploadFile<T>({
    required String endpoint,
    required File file,
    String fieldName = 'file',
    Map<String, String>? fields,
    T Function(dynamic p1)? parser,
    bool requiresAuth = true,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (parser != null) {
      return ApiResult.success(
        parser({'url': 'https://example.com/media.png'}),
      );
    }
    return ApiResult.success(null as T);
  }

  @override
  void sendRealtimeEvent(RealtimeEvent event) {
    sentRealtimeEvents.add(event);
  }

  @override
  void connectRealtime() {}

  @override
  void disconnectRealtime() {}

  Future<void> dispose() async {
    await _messageController.close();
    await _stateController.close();
  }
}
