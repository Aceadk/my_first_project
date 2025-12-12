import 'package:equatable/equatable.dart';
import '../../data/models/message.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final bool isSending;
  final bool isUnsendInProgress;
  final String? errorMessage;
  final bool canUnsend;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.isUnsendInProgress = false,
    this.errorMessage,
    this.canUnsend = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isSending,
    bool? isUnsendInProgress,
    String? errorMessage,
    bool? canUnsend,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isUnsendInProgress: isUnsendInProgress ?? this.isUnsendInProgress,
      errorMessage: errorMessage,
      canUnsend: canUnsend ?? this.canUnsend,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isSending,
        isUnsendInProgress,
        errorMessage,
        canUnsend,
      ];
}
