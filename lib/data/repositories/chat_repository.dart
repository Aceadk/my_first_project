import '../models/message.dart';
import '../models/match.dart';

abstract class ChatRepository {
  Stream<List<Message>> watchMessages(String matchId);

  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
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
  });

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<void> unmatch({
    required String matchId,
    required String userId,
  });

  Future<List<CrushMatch>> fetchUserMatches(String userId);
}
