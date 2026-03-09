import 'dart:async';
import 'dart:io';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/circuit_breaker.dart';
import 'package:crushhour/core/network/dto/chat_dto.dart' as dto;
import 'package:crushhour/core/network/dto/discovery_dto.dart';
import 'package:crushhour/core/network/dto/upload_response_dto.dart';
import 'package:crushhour/core/network/mappers/chat_mapper.dart';
import 'package:crushhour/core/network/mappers/discovery_mapper.dart';
import 'package:crushhour/core/network/realtime/realtime_connection.dart';
import 'package:crushhour/core/security/input_sanitizer.dart';
import 'package:crushhour/core/utils/managed_timer_registry.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_transport_adapter.dart';
import 'package:flutter/foundation.dart';

import '../chat_repository.dart';
import 'http_chat_transport_adapter.dart';

/// HTTP-based implementation of ChatRepository.
///
/// Uses HTTP for CRUD operations and WebSocket for real-time updates.
/// Polling is used as a fallback when WebSocket is unavailable.
class HttpChatRepository implements ChatRepository {
  HttpChatRepository({
    ApiClient? apiClient,
    String currentUserId = '',
    WebSocketConnection? webSocket,
    ChatTransportAdapter? transportAdapter,
  }) : assert(
         transportAdapter != null || apiClient != null,
         'Either transportAdapter or apiClient must be provided.',
       ),
       _transportAdapter =
           transportAdapter ??
           HttpChatTransportAdapter(
             apiClient: apiClient!,
             webSocket: webSocket,
           ),
       _currentUserId = currentUserId,
       _circuitBreaker = CircuitBreakerRegistry.instance.get('chat') {
    // CHAT-005: Wire WebSocket listener for real-time message delivery
    _webSocketSubscription = _transportAdapter.realtimeMessageStream.listen(
      _onWebSocketMessage,
    );
    _webSocketStateSubscription = _transportAdapter.realtimeStateStream.listen(
      _onWebSocketStateChanged,
    );
  }

  final ChatTransportAdapter _transportAdapter;
  String _currentUserId;
  final CircuitBreaker _circuitBreaker;
  StreamSubscription<Map<String, dynamic>>? _webSocketSubscription;
  StreamSubscription<ConnectionState>? _webSocketStateSubscription;
  static const _typingCancelTimerKey = 'typing_cancel';

  /// Update the current user ID after authentication.
  void updateCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POLLING CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  // These intervals are used when WebSocket is unavailable (fallback mode).
  // When WebSocket is connected, real-time events are used instead.

  /// Message polling interval (fallback only).
  /// 10 seconds provides good balance between responsiveness and battery/network usage.
  static const _messagePollingInterval = Duration(seconds: 10);

  /// Presence polling interval.
  /// 30 seconds is sufficient for online status which changes infrequently.
  static const _presencePollingInterval = Duration(seconds: 30);

  // Stream controllers for real-time data
  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  final Map<String, StreamController<Set<String>>> _typingControllers = {};
  final Map<String, StreamController<bool>> _presenceControllers = {};
  final Map<String, StreamController<bool>> _mediaSendingControllers = {};

  // Polling timers (fallback when WebSocket unavailable)
  final ManagedTimerRegistry _pollingTimers = ManagedTimerRegistry();
  final ManagedTimerRegistry _lifecycleTimers = ManagedTimerRegistry();

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    if (!_messageControllers.containsKey(matchId)) {
      _messageControllers[matchId] =
          StreamController<List<Message>>.broadcast();
      _startMessagePolling(matchId);
    }
    return _messageControllers[matchId]!.stream;
  }

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      AppLogger.warning(
        'HttpChatRepository: fetchMessagesPaginated blocked by circuit breaker',
      );
      return const PaginatedResult(items: [], total: -1, hasMore: false);
    }

    final queryParams = <String, String>{'limit': limit.toString()};
    if (beforeTimestamp != null) {
      queryParams['before'] = beforeTimestamp.toIso8601String();
    }

    final result = await _transportAdapter.get<Map<String, dynamic>>(
      ApiEndpoints.chatMessages(matchId),
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      return const PaginatedResult(items: [], total: -1, hasMore: false);
    }

    _circuitBreaker.recordSuccess();

    final response = dto.MessagesResponseDto.fromJson(result.data!);
    final messages = response.messages
        .map((m) => ChatMapper.messageFromDto(m, toUserId: _currentUserId))
        .toList();

    return PaginatedResult(
      items: messages,
      total: -1,
      hasMore: messages.length >= limit,
    );
  }

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) {
    // Use the existing message stream but filter for new messages
    return watchMessages(matchId).map(
      (messages) =>
          messages.where((m) => m.sentAt.isAfter(afterTimestamp)).toList(),
    );
  }

  void _startMessagePolling(String matchId) {
    _ensureMessagePolling(matchId);
  }

  void _ensureMessagePolling(String matchId) {
    // Initial fetch
    _fetchMessages(matchId);

    // Skip polling if WebSocket is connected (real-time events will be used)
    if (_transportAdapter.isRealtimeConnected) {
      AppLogger.debug(
        'HttpChatRepository: WebSocket connected, skipping message polling',
      );
      return;
    }

    final timerKey = 'messages_$matchId';
    if (_pollingTimers.contains(timerKey)) {
      return;
    }

    // Fallback: Poll at configured interval when WebSocket unavailable
    _pollingTimers.startPeriodic(
      timerKey,
      _messagePollingInterval,
      (_) => _fetchMessages(matchId),
    );
  }

  Future<void> _fetchMessages(String matchId) async {
    if (!_circuitBreaker.allowRequest()) {
      AppLogger.warning(
        'HttpChatRepository: _fetchMessages blocked by circuit breaker',
      );
      return;
    }

    final result = await _transportAdapter.get<Map<String, dynamic>>(
      ApiEndpoints.chatMessages(matchId),
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      return;
    }

    _circuitBreaker.recordSuccess();

    if (result.isSuccess && result.data != null) {
      final response = dto.MessagesResponseDto.fromJson(result.data!);
      final messages = response.messages
          .map((m) => ChatMapper.messageFromDto(m, toUserId: ''))
          .toList();
      _messageControllers[matchId]?.add(messages);
    }
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final request = dto.SendMessageRequestDto(
      type: _mapMessageType(type),
      content: type == MessageType.text ? content : null,
      mediaUrl: type != MessageType.text ? content : null,
    );

    final result = await _transportAdapter.post<void>(
      ApiEndpoints.chatSend(matchId),
      body: request.toJson(),
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to send message');
    }

    _circuitBreaker.recordSuccess();

    // Refresh messages
    await _fetchMessages(matchId);
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // CHAT-003: Validate file size before uploading
    final fileSize = await file.length();
    const maxImageSize = 25 * 1024 * 1024; // 25 MB
    const maxVideoSize = 100 * 1024 * 1024; // 100 MB
    final maxSize = type == MessageType.video ? maxVideoSize : maxImageSize;
    if (fileSize > maxSize) {
      throw Exception('File too large (max ${maxSize ~/ (1024 * 1024)} MB)');
    }

    // Determine the upload endpoint and field name based on type
    final endpoint = '/chat/$matchId/media';
    final mediaType = switch (type) {
      MessageType.image => 'image',
      MessageType.video => 'video',
      MessageType.voice => 'audio',
      MessageType.text => 'file',
    };

    final result = await _transportAdapter.uploadFile<UploadResponseDto>(
      endpoint: endpoint,
      file: file,
      fieldName: 'media',
      fields: {'type': mediaType},
      parser: (data) =>
          UploadResponseDto.fromJson(data as Map<String, dynamic>),
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to upload media');
    }

    _circuitBreaker.recordSuccess();

    // Extract the URL from the response
    final mediaUrl = result.data?.url;
    if (mediaUrl == null) {
      throw Exception('No media URL returned from server');
    }

    return mediaUrl;
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    final result = await _transportAdapter.post<void>(
      ApiEndpoints.chatRead(matchId),
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpChatRepository: Failed to mark messages read - ${result.error}',
      );
    }
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.delete<void>(
      '/chat/$matchId/messages/$messageId',
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to unsend message');
    }

    _circuitBreaker.recordSuccess();

    await _fetchMessages(matchId);
  }

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    // CHAT-008: Sanitize edited content
    final sanitizedContent = InputSanitizer.sanitizeMessage(newContent);

    final result = await _transportAdapter.patch<void>(
      '/chat/$matchId/messages/$messageId',
      body: {'content': sanitizedContent},
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to edit message');
    }

    _circuitBreaker.recordSuccess();

    await _fetchMessages(matchId);
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      '/chat/$matchId/messages/$messageId/hide',
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to delete message');
    }

    _circuitBreaker.recordSuccess();

    await _fetchMessages(matchId);
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      ApiEndpoints.reportUser,
      body: {
        'reporter_id': reporterId,
        'reported_id': reportedId,
        'reason': reason,
        'match_id': ?matchId,
        'message_id': ?messageId,
        'source': ?source,
        'description': ?description,
      },
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to report user');
    }

    _circuitBreaker.recordSuccess();
  }

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      '/chat/$matchId/messages/$messageId/reactions',
      body: {'emoji': emoji},
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to add reaction');
    }

    _circuitBreaker.recordSuccess();

    await _fetchMessages(matchId);
  }

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.delete<void>(
      '/chat/$matchId/messages/$messageId/reactions',
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to remove reaction');
    }

    _circuitBreaker.recordSuccess();

    await _fetchMessages(matchId);
  }

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      '/safety/appeal',
      body: {
        'user_id': userId,
        'reason': reason,
        'target_type': ?targetType,
        'target_id': ?targetId,
      },
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to submit appeal');
    }

    _circuitBreaker.recordSuccess();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPING INDICATORS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Set<String>> watchTyping(String matchId) {
    if (!_typingControllers.containsKey(matchId)) {
      _typingControllers[matchId] = StreamController<Set<String>>.broadcast();
      // Typing indicators typically don't need polling - just return empty set initially
      _typingControllers[matchId]!.add(<String>{});
    }
    return _typingControllers[matchId]!.stream;
  }

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    // CHAT-007: Auto-cancel typing indicator after 10 seconds
    _lifecycleTimers.cancel(_typingCancelTimerKey);
    if (isTyping) {
      _lifecycleTimers.startOneShot(
        _typingCancelTimerKey,
        const Duration(seconds: 10),
        () {
          unawaited(
            setTyping(matchId: matchId, userId: userId, isTyping: false),
          );
        },
      );
    }

    // Send via WebSocket if available
    if (_transportAdapter.isRealtimeConnected) {
      _transportAdapter.sendRealtimeEvent(
        TypingEvent(
          conversationId: matchId,
          userId: userId,
          isTyping: isTyping,
        ),
      );
      return;
    }

    // Fallback to HTTP
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      '/chat/$matchId/typing',
      body: {'is_typing': isTyping},
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
    } else {
      _circuitBreaker.recordSuccess();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRESENCE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<bool> watchPresence(String userId) {
    if (!_presenceControllers.containsKey(userId)) {
      _presenceControllers[userId] = StreamController<bool>.broadcast();
      _startPresencePolling(userId);
    }
    return _presenceControllers[userId]!.stream;
  }

  void _startPresencePolling(String userId) {
    _ensurePresencePolling(userId);
  }

  void _ensurePresencePolling(String userId) {
    _fetchPresence(userId);

    // Skip polling if WebSocket is connected (real-time events will be used)
    if (_transportAdapter.isRealtimeConnected) {
      AppLogger.debug(
        'HttpChatRepository: WebSocket connected, skipping presence polling',
      );
      return;
    }

    final timerKey = 'presence_$userId';
    if (_pollingTimers.contains(timerKey)) {
      return;
    }

    // Fallback: Poll at configured interval when WebSocket unavailable
    _pollingTimers.startPeriodic(
      timerKey,
      _presencePollingInterval,
      (_) => _fetchPresence(userId),
    );
  }

  Future<void> _fetchPresence(String userId) async {
    if (!_circuitBreaker.allowRequest()) {
      return;
    }

    final result = await _transportAdapter.get<Map<String, dynamic>>(
      '/users/$userId/presence',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      return;
    }

    _circuitBreaker.recordSuccess();

    if (result.isSuccess && result.data != null) {
      final isOnline = result.data!['is_online'] as bool? ?? false;
      _presenceControllers[userId]?.add(isOnline);
    }
  }

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {
    // Send via WebSocket if available
    if (_transportAdapter.isRealtimeConnected) {
      _transportAdapter.sendRealtimeEvent(
        PresenceEvent(userId: userId, isOnline: isOnline),
      );
      return;
    }

    // Fallback to HTTP
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      '/users/$userId/presence',
      body: {'is_online': isOnline},
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
    } else {
      _circuitBreaker.recordSuccess();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDIA SENDING
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) {
    if (!_mediaSendingControllers.containsKey(matchId)) {
      _mediaSendingControllers[matchId] = StreamController<bool>.broadcast();
      _mediaSendingControllers[matchId]!.add(false); // Default to disabled
    }
    return _mediaSendingControllers[matchId]!.stream;
  }

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      '/chat/$matchId/media-settings',
      body: {'enabled': enabled},
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(
        result.error?.message ?? 'Failed to update media settings',
      );
    }

    _circuitBreaker.recordSuccess();

    _mediaSendingControllers[matchId]?.add(enabled);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BLOCKING & MATCHING
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      ApiEndpoints.blockUser,
      body: {'blocked_id': blockedId},
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to block user');
    }

    _circuitBreaker.recordSuccess();
  }

  // CHAT-001: Added circuit breaker to unblockUser
  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      ApiEndpoints.unblockUser,
      body: {'blocked_id': blockedId},
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to unblock user');
    }

    _circuitBreaker.recordSuccess();
  }

  // CHAT-001: Added circuit breaker to unmatch
  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _transportAdapter.post<void>(
      ApiEndpoints.unmatch(matchId),
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to unmatch');
    }

    _circuitBreaker.recordSuccess();
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    final result = await fetchUserMatchesPaginated(userId, limit: 100);
    return result.items;
  }

  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      AppLogger.warning(
        'HttpChatRepository: fetchUserMatchesPaginated blocked by circuit breaker',
      );
      return const PaginatedResult(items: [], total: 0, hasMore: false);
    }

    final result = await _transportAdapter.get<Map<String, dynamic>>(
      ApiEndpoints.matches,
      queryParams: {'offset': offset.toString(), 'limit': limit.toString()},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      AppLogger.error(
        'HttpChatRepository: Failed to fetch matches - ${result.error}',
      );
      return const PaginatedResult(items: [], total: 0, hasMore: false);
    }

    _circuitBreaker.recordSuccess();

    final response = MatchesResponseDto.fromJson(result.data!);
    final matches = response.matches
        .map((dto) => DiscoveryMapper.matchFromDto(dto, currentUserId: userId))
        .toList();

    return PaginatedResult(
      items: matches,
      total: response.totalCount ?? matches.length,
      hasMore: matches.length >= limit,
    );
  }

  @override
  Future<MessageRequest?> sendMessageRequest({
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? toUserName,
    String? toUserPhotoUrl,
  }) async {
    // CHAT-004: Throw user-friendly exception instead of UnsupportedError
    throw Exception('Message requests are not yet available.');
  }

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async {
    return [];
  }

  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) async {
    return false;
  }

  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) async {
    return 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  dto.MessageType _mapMessageType(MessageType type) {
    switch (type) {
      case MessageType.text:
        return dto.MessageType.text;
      case MessageType.image:
        return dto.MessageType.image;
      case MessageType.video:
        return dto.MessageType.video;
      case MessageType.voice:
        return dto.MessageType.audio;
    }
  }

  /// Stop watching a conversation.
  void stopWatchingMessages(String matchId) {
    _pollingTimers.cancel('messages_$matchId');
    _messageControllers[matchId]?.close();
    _messageControllers.remove(matchId);
  }

  /// Stop watching presence for a user.
  void stopWatchingPresence(String userId) {
    _pollingTimers.cancel('presence_$userId');
    _presenceControllers[userId]?.close();
    _presenceControllers.remove(userId);
  }

  // CHAT-005: Handle incoming WebSocket messages
  void _onWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'message_received') {
      final event = MessageReceivedEvent.fromJson(data);
      final matchId = event.conversationId;
      // Refresh messages for this conversation
      _fetchMessages(matchId);
    } else if (type == 'typing') {
      final matchId = data['conversation_id'] as String?;
      final userId = data['user_id'] as String?;
      final isTyping = data['is_typing'] as bool? ?? false;
      if (matchId != null && userId != null) {
        final current = <String>{};
        if (isTyping) {
          current.add(userId);
        }
        _typingControllers[matchId]?.add(current);
      }
    } else if (type == 'presence') {
      final userId = data['user_id'] as String?;
      final isOnline = data['is_online'] as bool? ?? false;
      if (userId != null) {
        _presenceControllers[userId]?.add(isOnline);
      }
    } else if (type == 'read_receipt') {
      // RT-005: Handle read receipt events
      final matchId = data['conversation_id'] as String?;
      if (matchId != null) {
        _fetchMessages(matchId);
      }
    }
  }

  void _onWebSocketStateChanged(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        _pausePollingFallback();
        break;
      case ConnectionState.disconnected:
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
      case ConnectionState.failed:
        _resumePollingFallback();
        break;
    }
  }

  void _pausePollingFallback() {
    _cancelPollingByPrefix('messages_');
    _cancelPollingByPrefix('presence_');
  }

  void _resumePollingFallback() {
    if (_transportAdapter.isRealtimeConnected) {
      return;
    }

    for (final matchId in _messageControllers.keys.toList()) {
      _ensureMessagePolling(matchId);
    }
    for (final userId in _presenceControllers.keys.toList()) {
      _ensurePresencePolling(userId);
    }
  }

  void _cancelPollingByPrefix(String prefix) {
    _pollingTimers.cancelWhere((key) => key.startsWith(prefix));
  }

  @visibleForTesting
  Set<String> get activePollingTimerKeys =>
      Set.unmodifiable(_pollingTimers.keys.toSet());

  /// Dispose all resources.
  void dispose() {
    _webSocketSubscription?.cancel();
    _webSocketStateSubscription?.cancel();
    _lifecycleTimers.cancelAll();
    _pollingTimers.cancelAll();

    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();

    for (final controller in _typingControllers.values) {
      controller.close();
    }
    _typingControllers.clear();

    for (final controller in _presenceControllers.values) {
      controller.close();
    }
    _presenceControllers.clear();

    for (final controller in _mediaSendingControllers.values) {
      controller.close();
    }
    _mediaSendingControllers.clear();
  }

  // ── E2EE stubs (not supported in HTTP implementation) ───────────────

  @override
  bool get isE2eeEnabled => false;

  // CHAT-006: Log warning when E2EE is toggled but unsupported
  @override
  void setE2eeEnabled(bool enabled) {
    if (enabled) {
      AppLogger.warning(
        'HttpChatRepository: E2EE is not supported in HTTP backend',
      );
      throw Exception(
        'End-to-end encryption is not available with the current backend.',
      );
    }
  }

  @override
  bool isEncryptedContent(String content) => false;

  @override
  Future<Message> decryptMessage(Message message) async => message;

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULT-RETURNING METHODS (CR-AUD-035)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Result<void>> sendMessageResult({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) {
    return Result.guard(
      () => sendMessage(
        matchId: matchId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        content: content,
        type: type,
      ),
      logLabel: 'HttpChatRepository.sendMessageResult',
      fallbackError: 'Could not send message. Please try again.',
    );
  }

  Future<Result<void>> markMessagesReadResult(String matchId, String userId) {
    return Result.guard(
      () => markMessagesRead(matchId, userId),
      logLabel: 'HttpChatRepository.markMessagesReadResult',
      fallbackError: 'Could not mark messages as read.',
    );
  }

  Future<Result<void>> unsendMessageResult({
    required String matchId,
    required String messageId,
  }) {
    return Result.guard(
      () => unsendMessage(matchId: matchId, messageId: messageId),
      logLabel: 'HttpChatRepository.unsendMessageResult',
      fallbackError: 'Could not unsend message. Please try again.',
    );
  }

  Future<Result<void>> editMessageResult({
    required String matchId,
    required String messageId,
    required String newContent,
  }) {
    return Result.guard(
      () => editMessage(
        matchId: matchId,
        messageId: messageId,
        newContent: newContent,
      ),
      logLabel: 'HttpChatRepository.editMessageResult',
      fallbackError: 'Could not edit message. Please try again.',
    );
  }

  Future<Result<void>> blockUserResult({
    required String blockerId,
    required String blockedId,
  }) {
    return Result.guard(
      () => blockUser(blockerId: blockerId, blockedId: blockedId),
      logLabel: 'HttpChatRepository.blockUserResult',
      fallbackError: 'Could not block user. Please try again.',
    );
  }

  Future<Result<void>> unmatchResult({
    required String matchId,
    required String userId,
  }) {
    return Result.guard(
      () => unmatch(matchId: matchId, userId: userId),
      logLabel: 'HttpChatRepository.unmatchResult',
      fallbackError: 'Could not unmatch. Please try again.',
    );
  }

  Future<Result<String>> uploadMediaResult({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) {
    return Result.guard(
      () => uploadMedia(matchId: matchId, filePath: filePath, type: type),
      logLabel: 'HttpChatRepository.uploadMediaResult',
      fallbackError: 'Could not upload media. Please try again.',
    );
  }

  Future<Result<List<CrushMatch>>> fetchUserMatchesResult(String userId) {
    return Result.guard(
      () => fetchUserMatches(userId),
      logLabel: 'HttpChatRepository.fetchUserMatchesResult',
      fallbackError: 'Could not load matches. Please try again.',
    );
  }
}
