import 'dart:async';
import '../../models/message.dart';
import '../../models/match.dart';
import '../chat_repository.dart';

/// Stub implementation of ChatRepository.
/// Replace this with your actual backend implementation.
class StubChatRepository implements ChatRepository {
  @override
  Stream<List<Message>> watchMessages(String matchId) {
    // TODO: Implement real-time message streaming from your backend
    return Stream.value([]);
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    // TODO: Implement message sending via your backend
    throw UnimplementedError('Send message not implemented. Connect your backend.');
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    // TODO: Implement media upload to your backend
    throw UnimplementedError('Media upload not implemented. Connect your backend.');
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    // TODO: Implement marking messages as read
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    // TODO: Implement message unsend
    throw UnimplementedError('Unsend message not implemented. Connect your backend.');
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    // TODO: Implement delete for me
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
    // TODO: Implement user reporting via your backend
    throw UnimplementedError('Report user not implemented. Connect your backend.');
  }

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    // TODO: Implement adding reactions
  }

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    // TODO: Implement removing reactions
  }

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    // TODO: Implement safety appeal submission
  }

  @override
  Stream<Set<String>> watchTyping(String matchId) {
    return Stream.value({});
  }

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    // TODO: Implement typing indicator
  }

  @override
  Stream<bool> watchPresence(String userId) {
    return Stream.value(false);
  }

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {
    // TODO: Implement presence
  }

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) {
    return Stream.value(true);
  }

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {
    // TODO: Implement media sending toggle
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    // TODO: Implement user blocking
    throw UnimplementedError('Block user not implemented. Connect your backend.');
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    // TODO: Implement user unblocking
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    // TODO: Implement unmatch
    throw UnimplementedError('Unmatch not implemented. Connect your backend.');
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    // TODO: Implement fetching user matches
    return [];
  }
}
