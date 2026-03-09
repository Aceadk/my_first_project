import 'dart:io';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/realtime/realtime_connection.dart';

/// Domain-facing transport adapter for chat repositories.
///
/// This hides concrete HTTP/WebSocket clients behind a stable interface so
/// repositories can be tested with fake transports.
abstract class ChatTransportAdapter {
  /// Stream of raw realtime payloads emitted by the transport.
  Stream<Map<String, dynamic>> get realtimeMessageStream;

  /// Stream of realtime connection state transitions.
  Stream<ConnectionState> get realtimeStateStream;

  /// Whether realtime transport is currently connected.
  bool get isRealtimeConnected;

  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  });

  Future<ApiResult<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  });

  Future<ApiResult<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  });

  Future<ApiResult<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  });

  Future<ApiResult<T>> uploadFile<T>({
    required String endpoint,
    required File file,
    String fieldName = 'file',
    Map<String, String>? fields,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
    void Function(int sent, int total)? onProgress,
  });

  /// Sends a realtime event payload through the transport when available.
  void sendRealtimeEvent(RealtimeEvent event);
}
