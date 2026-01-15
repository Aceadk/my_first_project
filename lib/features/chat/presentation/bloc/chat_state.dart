import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/message.dart';

enum SendStatus { idle, sendingText, uploadingAttachment }

class ChatState extends Equatable {
  final List<Message> messages;
  final SendStatus sendStatus;
  final bool isUnsendInProgress;
  final bool isEditInProgress;
  final String? errorMessage;
  final bool canUnsend;
  final bool canEdit;
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
  /// Messages that failed to send (keyed by temp ID).
  final Map<String, Message> failedMessages;

  const ChatState({
    this.messages = const [],
    this.sendStatus = SendStatus.idle,
    this.isUnsendInProgress = false,
    this.isEditInProgress = false,
    this.errorMessage,
    this.canUnsend = false,
    this.canEdit = false,
    this.uploadingAttachmentName,
    this.typingUserIds = const {},
    this.otherUserOnline = false,
    this.mediaSendingEnabled = true,
    this.isUnmatching = false,
    this.isUnmatched = false,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.failedMessages = const {},
  });

  /// Combined list of messages including failed ones for display.
  List<Message> get allMessages {
    if (failedMessages.isEmpty) return messages;
    final combined = [...messages, ...failedMessages.values];
    combined.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return combined;
  }

  ChatState copyWith({
    List<Message>? messages,
    SendStatus? sendStatus,
    bool? isUnsendInProgress,
    bool? isEditInProgress,
    String? errorMessage,
    bool? canUnsend,
    bool? canEdit,
    String? uploadingAttachmentName,
    Set<String>? typingUserIds,
    bool? otherUserOnline,
    bool? mediaSendingEnabled,
    bool? isUnmatching,
    bool? isUnmatched,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    Map<String, Message>? failedMessages,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sendStatus: sendStatus ?? this.sendStatus,
      isUnsendInProgress: isUnsendInProgress ?? this.isUnsendInProgress,
      isEditInProgress: isEditInProgress ?? this.isEditInProgress,
      errorMessage: errorMessage,
      canUnsend: canUnsend ?? this.canUnsend,
      canEdit: canEdit ?? this.canEdit,
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
      failedMessages: failedMessages ?? this.failedMessages,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        sendStatus,
        isUnsendInProgress,
        isEditInProgress,
        errorMessage,
        canUnsend,
        canEdit,
        uploadingAttachmentName,
        typingUserIds,
        otherUserOnline,
        mediaSendingEnabled,
        isUnmatching,
        isUnmatched,
        isInitialLoading,
        isLoadingMore,
        hasMoreMessages,
        failedMessages,
      ];
}
