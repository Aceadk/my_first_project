import 'dart:async';
import 'dart:io';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/realtime/realtime_connection.dart';
import 'package:crushhour/features/chat/data/repositories/impl/http_chat_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_transport_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpChatRepository contract mapping', () {
    test(
      'submitSafetyAppeal posts to the supported REST appeal route',
      () async {
        final transport = _RecordingChatTransportAdapter();
        final repository = HttpChatRepository(transportAdapter: transport);

        await repository.submitSafetyAppeal(
          userId: 'user-1',
          reason: 'Please review this moderation action.',
          targetType: 'account',
          targetId: 'user-1',
        );

        expect(transport.postEndpoints, ['/safety/appeal']);
        expect(transport.postBodies.single, <String, dynamic>{
          'reason': 'Please review this moderation action.',
          'target_type': 'account',
          'target_id': 'user-1',
        });

        repository.dispose();
        await transport.dispose();
      },
    );

    test('reportUser uses the live /users/report route', () async {
      final transport = _RecordingChatTransportAdapter();
      final repository = HttpChatRepository(transportAdapter: transport);

      await repository.reportUser(
        reporterId: 'user-1',
        reportedId: 'user-2',
        reason: 'spam',
        description: 'Repeated unsolicited links',
      );

      expect(transport.postEndpoints.single, '/users/report');
      expect(transport.postBodies.single, <String, dynamic>{
        'reporter_id': 'user-1',
        'reported_id': 'user-2',
        'reason': 'spam',
        'description': 'Repeated unsolicited links',
      });

      repository.dispose();
      await transport.dispose();
    });
  });
}

class _RecordingChatTransportAdapter implements ChatTransportAdapter {
  final List<String> postEndpoints = <String>[];
  final List<Map<String, dynamic>> postBodies = <Map<String, dynamic>>[];

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
  bool get isRealtimeConnected => false;

  @override
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic p1)? parser,
    bool requiresAuth = true,
  }) async {
    if (parser != null) {
      return ApiResult.success(parser(<String, dynamic>{}));
    }
    return ApiResult.success(null as T);
  }

  @override
  Future<ApiResult<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic p1)? parser,
    bool requiresAuth = true,
  }) async {
    postEndpoints.add(endpoint);
    postBodies.add(
      Map<String, dynamic>.from(body ?? const <String, dynamic>{}),
    );
    if (parser != null) {
      return ApiResult.success(parser(<String, dynamic>{'success': true}));
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
        parser(<String, dynamic>{'url': 'https://example.com/file'}),
      );
    }
    return ApiResult.success(null as T);
  }

  @override
  void sendRealtimeEvent(RealtimeEvent event) {}

  @override
  void connectRealtime() {}

  @override
  void disconnectRealtime() {}

  Future<void> dispose() async {
    await _messageController.close();
    await _stateController.close();
  }
}
