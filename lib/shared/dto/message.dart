import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, voice }

/// Status of message delivery.
enum MessageSendStatus {
  /// Message sent successfully.
  sent,

  /// Message is currently being sent.
  sending,

  /// Message failed to send.
  failed,
}

class Message extends Equatable {
  final String id;
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeletedForSender;
  final Map<String, String> reactions; // userId -> emoji
  final String? moderationStatus;
  final String? moderationReason;
  final String? moderationAction;
  final bool isFlagged;
  final MessageSendStatus sendStatus;

  const Message({
    required this.id,
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.type,
    required this.sentAt,
    required this.isRead,
    this.readAt,
    required this.isDeletedForSender,
    this.moderationStatus,
    this.moderationReason,
    this.moderationAction,
    this.isFlagged = false,
    this.reactions = const {},
    this.sendStatus = MessageSendStatus.sent,
  });

  Message copyWith({
    bool? isRead,
    DateTime? readAt,
    bool? isDeletedForSender,
    Map<String, String>? reactions,
    String? moderationStatus,
    String? moderationReason,
    String? moderationAction,
    bool? isFlagged,
    MessageSendStatus? sendStatus,
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
      readAt: readAt ?? this.readAt,
      isDeletedForSender: isDeletedForSender ?? this.isDeletedForSender,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationReason: moderationReason ?? this.moderationReason,
      moderationAction: moderationAction ?? this.moderationAction,
      isFlagged: isFlagged ?? this.isFlagged,
      reactions: reactions ?? this.reactions,
      sendStatus: sendStatus ?? this.sendStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    matchId,
    fromUserId,
    toUserId,
    content,
    type,
    sentAt,
    isRead,
    readAt,
    isDeletedForSender,
    reactions,
    moderationStatus,
    moderationReason,
    moderationAction,
    isFlagged,
    sendStatus,
  ];
}
