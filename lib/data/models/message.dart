import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, voice }

class Message extends Equatable {
  final String id;
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isRead;
  final bool isDeletedForSender;
  final Map<String, String> reactions; // userId -> emoji
  final String? moderationStatus;
  final String? moderationReason;
  final String? moderationAction;
  final bool isFlagged;

  const Message({
    required this.id,
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.type,
    required this.sentAt,
    required this.isRead,
    required this.isDeletedForSender,
    this.moderationStatus,
    this.moderationReason,
    this.moderationAction,
    this.isFlagged = false,
    this.reactions = const {},
  });

  Message copyWith({
    bool? isRead,
    bool? isDeletedForSender,
    Map<String, String>? reactions,
    String? moderationStatus,
    String? moderationReason,
    String? moderationAction,
    bool? isFlagged,
  }) {
    return Message(
      id: id,
      matchId: matchId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: content,
      type: type,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
      isDeletedForSender: isDeletedForSender ?? this.isDeletedForSender,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationReason: moderationReason ?? this.moderationReason,
      moderationAction: moderationAction ?? this.moderationAction,
      isFlagged: isFlagged ?? this.isFlagged,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  List<Object?> get props =>
      [
        id,
        matchId,
        fromUserId,
        toUserId,
        content,
        type,
        sentAt,
        isRead,
        isDeletedForSender,
        reactions,
        moderationStatus,
        moderationReason,
        moderationAction,
        isFlagged,
      ];
}
