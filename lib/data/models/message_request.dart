import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/message.dart';

/// Represents a pre-match message request between two users.
class MessageRequest extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final DateTime expiresAt;
  final String? fromUserName;
  final String? fromUserPhotoUrl;
  final String? toUserName;
  final String? toUserPhotoUrl;

  const MessageRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.type,
    required this.sentAt,
    required this.expiresAt,
    this.fromUserName,
    this.fromUserPhotoUrl,
    this.toUserName,
    this.toUserPhotoUrl,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool isInboundFor(String userId) => userId == toUserId;

  String otherUserIdFor(String userId) =>
      userId == fromUserId ? toUserId : fromUserId;

  String? otherUserNameFor(String userId) =>
      userId == fromUserId ? toUserName : fromUserName;

  String? otherUserPhotoUrlFor(String userId) =>
      userId == fromUserId ? toUserPhotoUrl : fromUserPhotoUrl;

  @override
  List<Object?> get props => [
    id,
    fromUserId,
    toUserId,
    content,
    type,
    sentAt,
    expiresAt,
    fromUserName,
    fromUserPhotoUrl,
    toUserName,
    toUserPhotoUrl,
  ];
}
