import 'dart:io';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/realtime/realtime_connection.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_transport_adapter.dart';

/// Default chat transport adapter backed by [ApiClient] + [WebSocketConnection].
class HttpChatTransportAdapter implements ChatTransportAdapter {
  HttpChatTransportAdapter({
    required ApiClient apiClient,
    WebSocketConnection? webSocket,
  }) : _apiClient = apiClient,
       _webSocket = webSocket;

  final ApiClient _apiClient;
  final WebSocketConnection? _webSocket;

  @override
  Stream<Map<String, dynamic>> get realtimeMessageStream =>
      _webSocket?.messageStream ?? const Stream<Map<String, dynamic>>.empty();

  @override
  Stream<ConnectionState> get realtimeStateStream =>
      _webSocket?.stateStream ?? const Stream<ConnectionState>.empty();

  @override
  bool get isRealtimeConnected => _webSocket?.isConnected ?? false;

  @override
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _apiClient.get<T>(
      endpoint,
      queryParams: queryParams,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<ApiResult<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _apiClient.post<T>(
      endpoint,
      body: body,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<ApiResult<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _apiClient.patch<T>(
      endpoint,
      body: body,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? parser,
    bool requiresAuth = true,
  }) {
    return _apiClient.delete<T>(
      endpoint,
      parser: parser,
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<ApiResult<T>> uploadFile<T>({
    required String endpoint,
    required File file,
    String fieldName = 'file',
    Map<String, String>? fields,
    T Function(dynamic)? parser,
    bool requiresAuth = true,
    void Function(int sent, int total)? onProgress,
  }) {
    return _apiClient.uploadFile<T>(
      endpoint: endpoint,
      file: file,
      fieldName: fieldName,
      fields: fields,
      parser: parser,
      requiresAuth: requiresAuth,
      onProgress: onProgress,
    );
  }

  @override
  void sendRealtimeEvent(RealtimeEvent event) {
    final socket = _webSocket;
    if (socket == null || !socket.isConnected) {
      return;
    }
    socket.sendEvent(event);
  }
}
