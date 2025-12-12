import 'package:equatable/equatable.dart';
import '../../data/models/message.dart';
import '../../data/models/subscription.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatOpened extends ChatEvent {
  final String matchId;
  final String currentUserId;
  ChatOpened(this.matchId, this.currentUserId);

  @override
  List<Object?> get props => [matchId, currentUserId];
}

class ChatMessageSent extends ChatEvent {
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String content;
  final MessageType type;

  ChatMessageSent({
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    this.type = MessageType.text,
  });

  @override
  List<Object?> get props => [matchId, fromUserId, toUserId, content, type];
}

class ChatMessageUnsendRequested extends ChatEvent {
  final String matchId;
  final String messageId;

  ChatMessageUnsendRequested(
    this.matchId,
    this.messageId,
  );

  @override
  List<Object?> get props => [matchId, messageId];
}

class ChatMessageDeleteForMeRequested extends ChatEvent {
  final String matchId;
  final String messageId;
  final String userId;

  ChatMessageDeleteForMeRequested(
    this.matchId,
    this.messageId,
    this.userId,
  );

  @override
  List<Object?> get props => [matchId, messageId, userId];
}

class ChatMessagesUpdated extends ChatEvent {
  final List<Message> messages;
  final SubscriptionPlan plan;
  ChatMessagesUpdated(this.messages, this.plan);

  @override
  List<Object?> get props => [messages, plan];
}
