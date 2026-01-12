import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/message.dart';

enum SendStatus { idle, sendingText, uploadingAttachment }

class ChatState extends Equatable {
  final List<Message> messages;
  final SendStatus sendStatus;
  final bool isUnsendInProgress;
  final String? errorMessage;
  final bool canUnsend;
  final String? uploadingAttachmentName;
  final Set<String> typingUserIds;
  final bool otherUserOnline;
  final bool mediaSendingEnabled;
  final bool isUnmatching;
  final bool isUnmatched;

  const ChatState({
    this.messages = const [],
    this.sendStatus = SendStatus.idle,
    this.isUnsendInProgress = false,
    this.errorMessage,
    this.canUnsend = false,
    this.uploadingAttachmentName,
    this.typingUserIds = const {},
    this.otherUserOnline = false,
    this.mediaSendingEnabled = true,
    this.isUnmatching = false,
    this.isUnmatched = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    SendStatus? sendStatus,
    bool? isUnsendInProgress,
    String? errorMessage,
    bool? canUnsend,
    String? uploadingAttachmentName,
    Set<String>? typingUserIds,
    bool? otherUserOnline,
    bool? mediaSendingEnabled,
    bool? isUnmatching,
    bool? isUnmatched,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sendStatus: sendStatus ?? this.sendStatus,
      isUnsendInProgress: isUnsendInProgress ?? this.isUnsendInProgress,
      errorMessage: errorMessage,
      canUnsend: canUnsend ?? this.canUnsend,
      uploadingAttachmentName:
          uploadingAttachmentName ?? this.uploadingAttachmentName,
      typingUserIds: typingUserIds ?? this.typingUserIds,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      mediaSendingEnabled: mediaSendingEnabled ?? this.mediaSendingEnabled,
      isUnmatching: isUnmatching ?? this.isUnmatching,
      isUnmatched: isUnmatched ?? this.isUnmatched,
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
        typingUserIds,
        otherUserOnline,
        mediaSendingEnabled,
        isUnmatching,
        isUnmatched,
      ];
}
