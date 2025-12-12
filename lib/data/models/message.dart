import 'package:equatable/equatable.dart';

enum MessageType { text, image, voice }

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
  });

  Message copyWith({
    bool? isRead,
    bool? isDeletedForSender,
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
    );
  }

  @override
  List<Object?> get props =>
      [id, matchId, fromUserId, toUserId, content, type, sentAt, isRead, isDeletedForSender];
}
