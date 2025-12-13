import 'package:equatable/equatable.dart';
import '../../data/models/message.dart';

enum SendStatus { idle, sendingText, uploadingAttachment }

class ChatState extends Equatable {
  final List<Message> messages;
  final SendStatus sendStatus;
  final bool isUnsendInProgress;
  final String? errorMessage;
  final bool canUnsend;
  final String? uploadingAttachmentName;

  const ChatState({
    this.messages = const [],
    this.sendStatus = SendStatus.idle,
    this.isUnsendInProgress = false,
    this.errorMessage,
    this.canUnsend = false,
    this.uploadingAttachmentName,
  });

  ChatState copyWith({
    List<Message>? messages,
    SendStatus? sendStatus,
    bool? isUnsendInProgress,
    String? errorMessage,
    bool? canUnsend,
    String? uploadingAttachmentName,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sendStatus: sendStatus ?? this.sendStatus,
      isUnsendInProgress: isUnsendInProgress ?? this.isUnsendInProgress,
      errorMessage: errorMessage,
      canUnsend: canUnsend ?? this.canUnsend,
      uploadingAttachmentName:
          uploadingAttachmentName ?? this.uploadingAttachmentName,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        sendStatus,
        isUnsendInProgress,
        errorMessage,
        canUnsend,
        uploadingAttachmentName,
      ];
}
