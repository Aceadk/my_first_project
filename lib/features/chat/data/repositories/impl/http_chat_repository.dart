import 'dart:async';
import 'dart:io';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/dto/chat_dto.dart' as dto;
import 'package:crushhour/core/network/dto/discovery_dto.dart';
import 'package:crushhour/core/network/mappers/chat_mapper.dart';
import 'package:crushhour/core/network/mappers/discovery_mapper.dart';
import 'package:crushhour/core/network/realtime/realtime_connection.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/match.dart';
import '../chat_repository.dart';

/// HTTP-based implementation of ChatRepository.
///
/// Uses HTTP for CRUD operations and WebSocket for real-time updates.
/// Polling is used as a fallback when WebSocket is unavailable.
class HttpChatRepository implements ChatRepository {
  HttpChatRepository({
    required ApiClient apiClient,
    WebSocketConnection? webSocket,
  })  : _apiClient = apiClient,
        _webSocket = webSocket;

  final ApiClient _apiClient;
  final WebSocketConnection? _webSocket;

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
  final Map<String, Timer> _pollingTimers = {};

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
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (beforeTimestamp != null) {
      queryParams['before'] = beforeTimestamp.toIso8601String();
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.chatMessages(matchId),
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      return const PaginatedResult(items: [], total: -1, hasMore: false);
    }

    final response = dto.MessagesResponseDto.fromJson(result.data!);
    final messages = response.messages
        .map((m) => ChatMapper.messageFromDto(m, toUserId: ''))
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
    return watchMessages(matchId).map((messages) =>
        messages.where((m) => m.sentAt.isAfter(afterTimestamp)).toList());
  }

  void _startMessagePolling(String matchId) {
    // Initial fetch
    _fetchMessages(matchId);

    // Skip polling if WebSocket is connected (real-time events will be used)
    if (_webSocket?.isConnected == true) {
      AppLogger.debug(
          'HttpChatRepository: WebSocket connected, skipping message polling');
      return;
    }

    // Fallback: Poll at configured interval when WebSocket unavailable
    _pollingTimers['messages_$matchId']?.cancel();
    _pollingTimers['messages_$matchId'] = Timer.periodic(
      _messagePollingInterval,
      (_) => _fetchMessages(matchId),
    );
  }

  Future<void> _fetchMessages(String matchId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.chatMessages(matchId),
      parser: (data) => data as Map<String, dynamic>,
    );

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
    final request = dto.SendMessageRequestDto(
      type: _mapMessageType(type),
      content: type == MessageType.text ? content : null,
      mediaUrl: type != MessageType.text ? content : null,
    );

    final result = await _apiClient.post<void>(
      ApiEndpoints.chatSend(matchId),
      body: request.toJson(),
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to send message');
    }

    // Refresh messages
    await _fetchMessages(matchId);
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // Determine the upload endpoint and field name based on type
    final endpoint = '/chat/$matchId/media';
    final mediaType = switch (type) {
      MessageType.image => 'image',
      MessageType.video => 'video',
      MessageType.voice => 'audio',
      MessageType.text => 'file',
    };

    final result = await _apiClient.uploadFile<Map<String, dynamic>>(
      endpoint: endpoint,
      file: file,
      fieldName: 'media',
      fields: {'type': mediaType},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to upload media');
    }

    // Extract the URL from the response
    final mediaUrl = result.data?['url'] as String?;
    if (mediaUrl == null) {
      throw Exception('No media URL returned from server');
    }

    return mediaUrl;
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    final result = await _apiClient.post<void>(
      ApiEndpoints.chatRead(matchId),
    );

    if (result.isFailure) {
      AppLogger.error(
          'HttpChatRepository: Failed to mark messages read - ${result.error}');
    }
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    final result = await _apiClient.delete<void>(
      '/chat/$matchId/messages/$messageId',
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to unsend message');
    }

    await _fetchMessages(matchId);
  }

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    final result = await _apiClient.patch<void>(
      '/chat/$matchId/messages/$messageId',
      body: {'content': newContent},
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to edit message');
    }

    await _fetchMessages(matchId);
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    final result = await _apiClient.post<void>(
      '/chat/$matchId/messages/$messageId/hide',
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to delete message');
    }

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
    final result = await _apiClient.post<void>(
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
      throw Exception(result.error?.message ?? 'Failed to report user');
    }
  }

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final result = await _apiClient.post<void>(
      '/chat/$matchId/messages/$messageId/reactions',
      body: {'emoji': emoji},
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to add reaction');
    }

    await _fetchMessages(matchId);
  }

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    final result = await _apiClient.delete<void>(
      '/chat/$matchId/messages/$messageId/reactions',
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to remove reaction');
    }

    await _fetchMessages(matchId);
  }

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    final result = await _apiClient.post<void>(
      '/safety/appeal',
      body: {
        'user_id': userId,
        'reason': reason,
        'target_type': ?targetType,
        'target_id': ?targetId,
      },
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to submit appeal');
    }
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
    // Send via WebSocket if available
    if (_webSocket?.isConnected == true) {
      _webSocket!.sendEvent(TypingEvent(
        conversationId: matchId,
        userId: userId,
        isTyping: isTyping,
      ));
      return;
    }

    // Fallback to HTTP
    await _apiClient.post<void>(
      '/chat/$matchId/typing',
      body: {'is_typing': isTyping},
    );
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
    _fetchPresence(userId);

    // Skip polling if WebSocket is connected (real-time events will be used)
    if (_webSocket?.isConnected == true) {
      AppLogger.debug(
          'HttpChatRepository: WebSocket connected, skipping presence polling');
      return;
    }

    // Fallback: Poll at configured interval when WebSocket unavailable
    _pollingTimers['presence_$userId']?.cancel();
    _pollingTimers['presence_$userId'] = Timer.periodic(
      _presencePollingInterval,
      (_) => _fetchPresence(userId),
    );
  }

  Future<void> _fetchPresence(String userId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/users/$userId/presence',
      parser: (data) => data as Map<String, dynamic>,
    );

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
    if (_webSocket?.isConnected == true) {
      _webSocket!.sendEvent(PresenceEvent(
        userId: userId,
        isOnline: isOnline,
      ));
      return;
    }

    // Fallback to HTTP
    await _apiClient.post<void>(
      '/users/$userId/presence',
      body: {'is_online': isOnline},
    );
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
    final result = await _apiClient.post<void>(
      '/chat/$matchId/media-settings',
      body: {'enabled': enabled},
    );

    if (result.isFailure) {
      throw Exception(
          result.error?.message ?? 'Failed to update media settings');
    }

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
    final result = await _apiClient.post<void>(
      ApiEndpoints.blockUser,
      body: {'blocked_id': blockedId},
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to block user');
    }
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final result = await _apiClient.post<void>(
      ApiEndpoints.unblockUser,
      body: {'blocked_id': blockedId},
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to unblock user');
    }
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    final result = await _apiClient.post<void>(
      ApiEndpoints.unmatch(matchId),
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to unmatch');
    }
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
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.matches,
      queryParams: {
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
          'HttpChatRepository: Failed to fetch matches - ${result.error}');
      return const PaginatedResult(items: [], total: 0, hasMore: false);
    }

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
    throw UnsupportedError(
        'Message requests are not supported in HTTP backend.');
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
    _pollingTimers['messages_$matchId']?.cancel();
    _pollingTimers.remove('messages_$matchId');
    _messageControllers[matchId]?.close();
    _messageControllers.remove(matchId);
  }

  /// Stop watching presence for a user.
  void stopWatchingPresence(String userId) {
    _pollingTimers['presence_$userId']?.cancel();
    _pollingTimers.remove('presence_$userId');
    _presenceControllers[userId]?.close();
    _presenceControllers.remove(userId);
  }

  /// Dispose all resources.
  void dispose() {
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();

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

  @override
  void setE2eeEnabled(bool enabled) {}

  @override
  bool isEncryptedContent(String content) => false;

  @override
  Future<Message> decryptMessage(Message message) async => message;
}
