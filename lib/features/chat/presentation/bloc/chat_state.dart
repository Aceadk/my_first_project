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
  /// Whether initial messages are loading.
  final bool isInitialLoading;
  /// Whether older messages are being loaded (load more).
  final bool isLoadingMore;
  /// Whether there are more older messages to load.
  final bool hasMoreMessages;

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
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
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
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMoreMessages,
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
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
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
        isInitialLoading,
        isLoadingMore,
        hasMoreMessages,
      ];
}
