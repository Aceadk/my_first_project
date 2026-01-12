import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/subscription.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatOpened extends ChatEvent {
  final String matchId;
  final String currentUserId;
  final String otherUserId;
  ChatOpened(this.matchId, this.currentUserId, this.otherUserId);

  @override
  List<Object?> get props => [matchId, currentUserId, otherUserId];
}

class ChatClosed extends ChatEvent {
  final String matchId;
  final String currentUserId;

  ChatClosed(this.matchId, this.currentUserId);

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

class ChatMediaSendRequested extends ChatEvent {
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String filePath;
  final MessageType type;

  ChatMediaSendRequested({
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.filePath,
    required this.type,
  });

  @override
  List<Object?> get props => [matchId, fromUserId, toUserId, filePath, type];
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

class ChatTypingStatusChanged extends ChatEvent {
  final String matchId;
  final String userId;
  final bool isTyping;

  ChatTypingStatusChanged({
    required this.matchId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [matchId, userId, isTyping];
}

class ChatTypingUsersUpdated extends ChatEvent {
  final Set<String> typingUserIds;
  ChatTypingUsersUpdated(this.typingUserIds);

  @override
  List<Object?> get props => [typingUserIds];
}

class ChatPresenceUpdated extends ChatEvent {
  final bool isOnline;
  ChatPresenceUpdated(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

class ChatReactionAdded extends ChatEvent {
  final String matchId;
  final String messageId;
  final String userId;
  final String emoji;

  ChatReactionAdded({
    required this.matchId,
    required this.messageId,
    required this.userId,
    required this.emoji,
  });

  @override
  List<Object?> get props => [matchId, messageId, userId, emoji];
}

class ChatReactionRemoved extends ChatEvent {
  final String matchId;
  final String messageId;
  final String userId;

  ChatReactionRemoved({
    required this.matchId,
    required this.messageId,
    required this.userId,
  });

  @override
  List<Object?> get props => [matchId, messageId, userId];
}

class ChatMediaToggleRequested extends ChatEvent {
  final String matchId;
  final String requesterId;
  final bool enabled;

  ChatMediaToggleRequested({
    required this.matchId,
    required this.requesterId,
    required this.enabled,
  });

  @override
  List<Object?> get props => [matchId, requesterId, enabled];
}

class ChatMediaStatusUpdated extends ChatEvent {
  final bool enabled;
  ChatMediaStatusUpdated(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ChatUnmatchRequested extends ChatEvent {
  final String matchId;
  final String userId;

  ChatUnmatchRequested({
    required this.matchId,
    required this.userId,
  });

  @override
  List<Object?> get props => [matchId, userId];
}
