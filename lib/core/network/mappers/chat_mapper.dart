import 'package:crushhour/core/network/dto/chat_dto.dart' as dto;
import 'package:crushhour/data/models/message.dart' as domain;

/// Mapper for chat-related DTOs to domain models.
class ChatMapper {
  ChatMapper._();

  /// Convert MessageDto to Message domain model.
  static domain.Message messageFromDto(dto.MessageDto messageDto, {required String toUserId}) {
    return domain.Message(
      id: messageDto.id,
      matchId: messageDto.conversationId,
      fromUserId: messageDto.senderId,
      toUserId: toUserId,
      content: messageDto.content ?? messageDto.mediaUrl ?? '',
      type: _messageTypeFromDto(messageDto.type),
      sentAt: messageDto.createdAt ?? DateTime.now(),
      isRead: messageDto.readBy?.isNotEmpty ?? false,
      isDeletedForSender: messageDto.deletedAt != null,
      reactions: _reactionsFromDto(messageDto.reactions),
      isFlagged: false,
    );
  }

  /// Convert Message to MessageDto.
  static dto.MessageDto messageToDto(domain.Message message) {
    return dto.MessageDto(
      id: message.id,
      conversationId: message.matchId,
      senderId: message.fromUserId,
      type: _messageTypeToDto(message.type),
      content: message.type == domain.MessageType.text ? message.content : null,
      mediaUrl: message.type != domain.MessageType.text ? message.content : null,
      status: message.isRead ? dto.MessageStatus.read : dto.MessageStatus.sent,
      createdAt: message.sentAt,
      deletedAt: message.isDeletedForSender ? DateTime.now() : null,
      reactions: message.reactions.entries
          .map((e) => dto.MessageReactionDto(userId: e.key, emoji: e.value))
          .toList(),
    );
  }

  /// Convert Message to SendMessageRequestDto.
  static dto.SendMessageRequestDto messageToSendRequest(domain.Message message, {String? clientId}) {
    return dto.SendMessageRequestDto(
      type: _messageTypeToDto(message.type),
      content: message.type == domain.MessageType.text ? message.content : null,
      mediaUrl: message.type != domain.MessageType.text ? message.content : null,
      clientId: clientId,
    );
  }

  /// Create a text message request.
  static dto.SendMessageRequestDto textMessageRequest(String content, {String? replyToId}) {
    return dto.SendMessageRequestDto.text(content, replyToId: replyToId);
  }

  /// Create an image message request.
  static dto.SendMessageRequestDto imageMessageRequest(String mediaUrl, {String? thumbnailUrl}) {
    return dto.SendMessageRequestDto.image(mediaUrl, thumbnailUrl: thumbnailUrl);
  }

  static domain.MessageType _messageTypeFromDto(dto.MessageType dtoType) {
    switch (dtoType) {
      case dto.MessageType.text:
        return domain.MessageType.text;
      case dto.MessageType.image:
        return domain.MessageType.image;
      case dto.MessageType.video:
        return domain.MessageType.video;
      case dto.MessageType.audio:
        return domain.MessageType.voice;
      default:
        return domain.MessageType.text;
    }
  }

  static dto.MessageType _messageTypeToDto(domain.MessageType type) {
    switch (type) {
      case domain.MessageType.text:
        return dto.MessageType.text;
      case domain.MessageType.image:
        return dto.MessageType.image;
      case domain.MessageType.video:
        return dto.MessageType.video;
      case domain.MessageType.voice:
        return dto.MessageType.audio;
    }
  }

  static Map<String, String> _reactionsFromDto(List<dto.MessageReactionDto>? reactions) {
    if (reactions == null || reactions.isEmpty) return const {};
    return {for (final r in reactions) r.userId: r.emoji};
  }
}
