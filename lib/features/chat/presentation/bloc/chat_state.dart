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

  /// Whether the user can see read receipts (Plus feature).
  final bool canSeeReadReceipts;
  final String? uploadingAttachmentName;
  final Set<String> typingUserIds;
  final bool otherUserOnline;
  final String? otherUserPhotoUrl;
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

  /// Whether end-to-end encryption is enabled for this chat.
  /// When enabled, text messages are encrypted before sending and
  /// decrypted when received. Media URLs are not encrypted.
  final bool isE2eeEnabled;

  const ChatState({
    this.messages = const [],
    this.sendStatus = SendStatus.idle,
    this.isUnsendInProgress = false,
    this.isEditInProgress = false,
    this.errorMessage,
    this.canUnsend = false,
    this.canEdit = false,
    this.canSeeReadReceipts = false,
    this.uploadingAttachmentName,
    this.typingUserIds = const {},
    this.otherUserOnline = false,
    this.otherUserPhotoUrl,
    this.mediaSendingEnabled = true,
    this.isUnmatching = false,
    this.isUnmatched = false,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.failedMessages = const {},
    this.isE2eeEnabled = true,
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
    bool? canSeeReadReceipts,
    String? uploadingAttachmentName,
    Set<String>? typingUserIds,
    bool? otherUserOnline,
    String? otherUserPhotoUrl,
    bool? mediaSendingEnabled,
    bool? isUnmatching,
    bool? isUnmatched,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    Map<String, Message>? failedMessages,
    bool? isE2eeEnabled,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sendStatus: sendStatus ?? this.sendStatus,
      isUnsendInProgress: isUnsendInProgress ?? this.isUnsendInProgress,
      isEditInProgress: isEditInProgress ?? this.isEditInProgress,
      errorMessage: errorMessage,
      canUnsend: canUnsend ?? this.canUnsend,
      canEdit: canEdit ?? this.canEdit,
      canSeeReadReceipts: canSeeReadReceipts ?? this.canSeeReadReceipts,
      uploadingAttachmentName:
          uploadingAttachmentName ?? this.uploadingAttachmentName,
      typingUserIds: typingUserIds ?? this.typingUserIds,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      mediaSendingEnabled: mediaSendingEnabled ?? this.mediaSendingEnabled,
      isUnmatching: isUnmatching ?? this.isUnmatching,
      isUnmatched: isUnmatched ?? this.isUnmatched,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      failedMessages: failedMessages ?? this.failedMessages,
      isE2eeEnabled: isE2eeEnabled ?? this.isE2eeEnabled,
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
    canSeeReadReceipts,
    uploadingAttachmentName,
    typingUserIds,
    otherUserOnline,
    otherUserPhotoUrl,
    mediaSendingEnabled,
    isUnmatching,
    isUnmatched,
    isInitialLoading,
    isLoadingMore,
    hasMoreMessages,
    failedMessages,
    isE2eeEnabled,
  ];
}
