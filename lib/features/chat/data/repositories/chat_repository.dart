import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/match.dart';

abstract class ChatRepository {
  Stream<List<Message>> watchMessages(String matchId);

  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  });

  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  });

  Future<void> markMessagesRead(String matchId, String userId);

  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  });

  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  });

  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  });

  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  });

  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  });

  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  });

  Stream<Set<String>> watchTyping(String matchId);

  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  });

  Stream<bool> watchPresence(String userId);

  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  });

  Stream<bool> watchMediaSendingEnabled(String matchId);

  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  });

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<void> unmatch({
    required String matchId,
    required String userId,
  });

  Future<List<CrushMatch>> fetchUserMatches(String userId);

  /// Fetch paginated matches for a user.
  ///
  /// [offset] - Number of matches to skip.
  /// [limit] - Maximum number of matches to return.
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  });
}

/// Result wrapper for paginated data.
class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    required this.total,
    required this.hasMore,
  });
}
