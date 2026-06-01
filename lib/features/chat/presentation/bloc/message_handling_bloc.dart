import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/performance/performance_monitor.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/domain/usecases/message_reconciler.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chat_state.dart' show SendStatus;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// State for message handling: send/receive/edit/unsend/delete, reactions,
/// pagination, retry.
class MessageHandlingState extends Equatable {
  final List<Message> messages;
  final Map<String, Message> failedMessages;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final SendStatus sendStatus;
  final String? uploadingAttachmentName;
  final bool isUnsendInProgress;
  final bool isEditInProgress;
  final bool canUnsend;
  final bool canEdit;
  final bool canSeeReadReceipts;
  final String? errorMessage;

  const MessageHandlingState({
    this.messages = const [],
    this.failedMessages = const {},
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.sendStatus = SendStatus.idle,
    this.uploadingAttachmentName,
    this.isUnsendInProgress = false,
    this.isEditInProgress = false,
    this.canUnsend = false,
    this.canEdit = false,
    this.canSeeReadReceipts = false,
    this.errorMessage,
  });

  /// Combined list of messages including optimistic/failed ones for display,
  /// de-duplicated against their confirmed server copies and deterministically
  /// ordered (CHAT-RT-001).
  List<Message> get allMessages => MessageReconciler.combineForDisplay(
    confirmed: messages,
    pending: failedMessages,
  );

  MessageHandlingState copyWith({
    List<Message>? messages,
    Map<String, Message>? failedMessages,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    SendStatus? sendStatus,
    Object? uploadingAttachmentName = _unset,
    bool? isUnsendInProgress,
    bool? isEditInProgress,
    bool? canUnsend,
    bool? canEdit,
    bool? canSeeReadReceipts,
    String? errorMessage,
  }) {
    return MessageHandlingState(
      messages: messages ?? this.messages,
      failedMessages: failedMessages ?? this.failedMessages,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      sendStatus: sendStatus ?? this.sendStatus,
      uploadingAttachmentName: identical(uploadingAttachmentName, _unset)
          ? this.uploadingAttachmentName
          : uploadingAttachmentName as String?,
      isUnsendInProgress: isUnsendInProgress ?? this.isUnsendInProgress,
      isEditInProgress: isEditInProgress ?? this.isEditInProgress,
      canUnsend: canUnsend ?? this.canUnsend,
      canEdit: canEdit ?? this.canEdit,
      canSeeReadReceipts: canSeeReadReceipts ?? this.canSeeReadReceipts,
      // errorMessage intentionally uses direct value (null clears it)
      errorMessage: errorMessage,
    );
  }

  static const _unset = Object();

  @override
  List<Object?> get props => [
    messages,
    failedMessages,
    isInitialLoading,
    isLoadingMore,
    hasMoreMessages,
    sendStatus,
    uploadingAttachmentName,
    isUnsendInProgress,
    isEditInProgress,
    canUnsend,
    canEdit,
    canSeeReadReceipts,
    errorMessage,
  ];
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class MessageHandlingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MsgInitialLoadRequested extends MessageHandlingEvent {
  final String matchId;
  final String currentUserId;
  MsgInitialLoadRequested({required this.matchId, required this.currentUserId});

  @override
  List<Object?> get props => [matchId, currentUserId];
}

class MsgSendRequested extends MessageHandlingEvent {
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String content;
  final MessageType type;

  MsgSendRequested({
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    this.type = MessageType.text,
  });

  @override
  List<Object?> get props => [matchId, fromUserId, toUserId, content, type];
}

class MsgMediaSendRequested extends MessageHandlingEvent {
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final String filePath;
  final MessageType type;
  final bool mediaSendingEnabled;

  MsgMediaSendRequested({
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.filePath,
    required this.type,
    required this.mediaSendingEnabled,
  });

  @override
  List<Object?> get props => [
    matchId,
    fromUserId,
    toUserId,
    filePath,
    type,
    mediaSendingEnabled,
  ];
}

class MsgUnsendRequested extends MessageHandlingEvent {
  final String matchId;
  final String messageId;
  MsgUnsendRequested({required this.matchId, required this.messageId});

  @override
  List<Object?> get props => [matchId, messageId];
}

class MsgEditRequested extends MessageHandlingEvent {
  final String matchId;
  final String messageId;
  final String newContent;
  MsgEditRequested({
    required this.matchId,
    required this.messageId,
    required this.newContent,
  });

  @override
  List<Object?> get props => [matchId, messageId, newContent];
}

class MsgDeleteForMeRequested extends MessageHandlingEvent {
  final String matchId;
  final String messageId;
  final String userId;
  MsgDeleteForMeRequested({
    required this.matchId,
    required this.messageId,
    required this.userId,
  });

  @override
  List<Object?> get props => [matchId, messageId, userId];
}

class MsgReactionAdded extends MessageHandlingEvent {
  final String matchId;
  final String messageId;
  final String userId;
  final String emoji;
  MsgReactionAdded({
    required this.matchId,
    required this.messageId,
    required this.userId,
    required this.emoji,
  });

  @override
  List<Object?> get props => [matchId, messageId, userId, emoji];
}

class MsgReactionRemoved extends MessageHandlingEvent {
  final String matchId;
  final String messageId;
  final String userId;
  MsgReactionRemoved({
    required this.matchId,
    required this.messageId,
    required this.userId,
  });

  @override
  List<Object?> get props => [matchId, messageId, userId];
}

class MsgLoadMoreRequested extends MessageHandlingEvent {
  final String matchId;
  MsgLoadMoreRequested(this.matchId);

  @override
  List<Object?> get props => [matchId];
}

class MsgNewMessagesReceived extends MessageHandlingEvent {
  final List<Message> newMessages;
  MsgNewMessagesReceived(this.newMessages);

  @override
  List<Object?> get props => [newMessages];
}

class MsgLegacyMessagesUpdated extends MessageHandlingEvent {
  final List<Message> messages;
  final SubscriptionTier tier;
  MsgLegacyMessagesUpdated(this.messages, this.tier);

  @override
  List<Object?> get props => [messages, tier];
}

class MsgRetryRequested extends MessageHandlingEvent {
  final String matchId;
  final String messageId;
  MsgRetryRequested({required this.matchId, required this.messageId});

  @override
  List<Object?> get props => [matchId, messageId];
}

class MsgDiscardFailedRequested extends MessageHandlingEvent {
  final String messageId;
  MsgDiscardFailedRequested({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class MsgResetRequested extends MessageHandlingEvent {}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

/// BLoC managing all message operations: send, receive, edit, unsend,
/// delete, reactions, pagination, and retry.
class MessageHandlingBloc
    extends Bloc<MessageHandlingEvent, MessageHandlingState> {
  final ChatRepository chatRepository;
  final SubscriptionRepository subscriptionRepository;

  /// Callback to check whether E2EE is enabled (provided by ChatBloc facade).
  final bool Function() isE2eeEnabled;

  StreamSubscription<List<Message>>? _sub;
  StreamSubscription<List<Message>>? _newMessagesSub;

  static const int _pageSize = 50;

  /// Maximum messages kept in memory to prevent unbounded growth.
  /// When exceeded, oldest messages are trimmed (they can be re-fetched via pagination).
  static const int _maxMessagesInMemory = 100;

  MessageHandlingBloc({
    required this.chatRepository,
    required this.subscriptionRepository,
    required this.isE2eeEnabled,
  }) : super(const MessageHandlingState()) {
    on<MsgInitialLoadRequested>(_onInitialLoad);
    on<MsgSendRequested>(_onSend);
    on<MsgMediaSendRequested>(_onMediaSend);
    on<MsgUnsendRequested>(_onUnsend);
    on<MsgEditRequested>(_onEdit);
    on<MsgDeleteForMeRequested>(_onDeleteForMe);
    on<MsgReactionAdded>(_onReactionAdded);
    on<MsgReactionRemoved>(_onReactionRemoved);
    on<MsgLoadMoreRequested>(_onLoadMore);
    on<MsgNewMessagesReceived>(_onNewMessages);
    on<MsgLegacyMessagesUpdated>(_onLegacyMessages);
    on<MsgRetryRequested>(_onRetry);
    on<MsgDiscardFailedRequested>(_onDiscardFailed);
    on<MsgResetRequested>(_onReset);
  }

  // ---- Initial Load ----

  Future<void> _onInitialLoad(
    MsgInitialLoadRequested event,
    Emitter<MessageHandlingState> emit,
  ) async {
    emit(
      state.copyWith(
        isInitialLoading: true,
        messages: const [],
        hasMoreMessages: true,
        errorMessage: null,
      ),
    );

    _sub?.cancel();
    _newMessagesSub?.cancel();

    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not load chat.',
    );
    if (!planResult.isSuccess) {
      emit(
        state.copyWith(
          errorMessage: planResult.errorMessage,
          isInitialLoading: false,
        ),
      );
      return;
    }
    final tier = planResult.data ?? SubscriptionTier.free;

    // PAGINATION: Load initial batch of messages (newest first)
    final initialResult = await Result.guard(
      () => chatRepository.fetchMessagesPaginated(
        event.matchId,
        limit: _pageSize,
      ),
      logLabel: 'ChatRepository.fetchMessagesPaginated',
      fallbackError: 'Could not load messages.',
    );

    if (initialResult.isSuccess && initialResult.data != null) {
      final paginated = initialResult.data!;
      final decrypted = await _maybeDecryptMessages(paginated.items);
      emit(
        state.copyWith(
          messages: decrypted,
          hasMoreMessages: paginated.hasMore,
          isInitialLoading: false,
          canUnsend: tier.hasPremium,
          canEdit: tier.hasPremium,
          canSeeReadReceipts: tier.hasPremium,
        ),
      );

      // Watch for NEW messages only (after initial load)
      final latestTimestamp = decrypted.isNotEmpty
          ? decrypted.last.sentAt
          : DateTime.now();
      _newMessagesSub = chatRepository
          .watchNewMessages(event.matchId, afterTimestamp: latestTimestamp)
          .listen((newMessages) {
            if (newMessages.isNotEmpty) {
              add(MsgNewMessagesReceived(newMessages));
            }
          });
    } else {
      // Fallback to legacy stream if pagination fails
      AppLogger.debug(
        'MessageHandlingBloc: Pagination failed, falling back to legacy watchMessages',
      );
      _sub = chatRepository.watchMessages(event.matchId).listen((messages) {
        add(MsgLegacyMessagesUpdated(messages, tier));
      });
      emit(
        state.copyWith(
          isInitialLoading: false,
          hasMoreMessages: false,
          canUnsend: tier.hasPremium,
          canEdit: tier.hasPremium,
          canSeeReadReceipts: tier.hasPremium,
          errorMessage: initialResult.errorMessage,
        ),
      );
    }

    // Track conversation opened
    AnalyticsService.instance.logConversationOpened(matchId: event.matchId);

    final readResult = await Result.guard(
      () => chatRepository.markMessagesRead(event.matchId, event.currentUserId),
      logLabel: 'ChatRepository.markMessagesRead',
      fallbackError: 'Could not load chat.',
    );
    if (!readResult.isSuccess) {
      emit(state.copyWith(errorMessage: readResult.errorMessage));
    }
  }

  // ---- Send ----

  Future<void> _onSend(
    MsgSendRequested event,
    Emitter<MessageHandlingState> emit,
  ) async {
    final content = event.content.trim();
    if (content.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final optimisticMessage = Message(
      id: tempId,
      matchId: event.matchId,
      fromUserId: event.fromUserId,
      toUserId: event.toUserId,
      content: content,
      type: event.type,
      sentAt: DateTime.now(),
      isRead: false,
      isDeletedForSender: false,
      sendStatus: MessageSendStatus.sending,
    );
    final pendingMessages = Map<String, Message>.from(state.failedMessages);
    pendingMessages[tempId] = optimisticMessage;

    emit(
      state.copyWith(
        sendStatus: SendStatus.sendingText,
        errorMessage: null,
        failedMessages: pendingMessages,
      ),
    );

    await PerformanceMonitor.instance.startTrace('message_send');
    final result = await Result.guard(
      () => chatRepository.sendMessage(
        matchId: event.matchId,
        fromUserId: event.fromUserId,
        toUserId: event.toUserId,
        content: content,
        type: event.type,
      ),
      logLabel: 'ChatRepository.sendMessage',
      fallbackError: 'Message failed to send. Check your connection and retry.',
    );
    await Result.guard(
      () => chatRepository.setTyping(
        matchId: event.matchId,
        userId: event.fromUserId,
        isTyping: false,
      ),
      logLabel: 'ChatRepository.setTyping',
      fallbackError: 'Could not update typing status.',
    );

    if (result.isSuccess) {
      await PerformanceMonitor.instance.stopTrace(
        'message_send',
        metrics: {'success': 1},
      );
      AnalyticsService.instance.logMessageSent(
        matchId: event.matchId,
        messageType: event.type.name,
      );
      final newPending = Map<String, Message>.from(state.failedMessages);
      newPending.remove(tempId);
      emit(
        state.copyWith(sendStatus: SendStatus.idle, failedMessages: newPending),
      );
    } else {
      await PerformanceMonitor.instance.stopTrace(
        'message_send',
        metrics: {'success': 0},
      );
      final newFailed = Map<String, Message>.from(state.failedMessages);
      newFailed[tempId] = optimisticMessage.copyWith(
        sendStatus: MessageSendStatus.failed,
      );
      emit(
        state.copyWith(
          sendStatus: SendStatus.idle,
          errorMessage: result.errorMessage,
          failedMessages: newFailed,
        ),
      );
    }
  }

  // ---- Media Send ----

  Future<void> _onMediaSend(
    MsgMediaSendRequested event,
    Emitter<MessageHandlingState> emit,
  ) async {
    if (!event.mediaSendingEnabled) {
      emit(
        state.copyWith(
          sendStatus: SendStatus.idle,
          uploadingAttachmentName: null,
          errorMessage: 'Media sending is disabled for this match.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        sendStatus: SendStatus.uploadingAttachment,
        uploadingAttachmentName: _filename(event.filePath),
        errorMessage: null,
      ),
    );
    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not send media. Please try again.',
    );
    final tier = planResult.data ?? SubscriptionTier.free;
    if (!planResult.isSuccess) {
      emit(
        state.copyWith(
          sendStatus: SendStatus.idle,
          uploadingAttachmentName: null,
          errorMessage: planResult.errorMessage,
        ),
      );
      return;
    }
    if (!tier.hasPremium && _mediaCountForUser(event.fromUserId) >= 8) {
      emit(
        state.copyWith(
          sendStatus: SendStatus.idle,
          uploadingAttachmentName: null,
          errorMessage:
              'Media limit reached. Upgrade to Plus for unlimited media.',
        ),
      );
      return;
    }

    final uploadResult = await Result.guard(
      () => chatRepository.uploadMedia(
        matchId: event.matchId,
        filePath: event.filePath,
        type: event.type,
      ),
      logLabel: 'ChatRepository.uploadMedia',
      fallbackError:
          'Media message failed to send. Check your connection and try again.',
    );
    final url = uploadResult.data;
    if (!uploadResult.isSuccess || url == null) {
      emit(
        state.copyWith(
          sendStatus: SendStatus.idle,
          uploadingAttachmentName: null,
          errorMessage: uploadResult.errorMessage,
        ),
      );
      return;
    }

    final sendResult = await Result.guard(
      () => chatRepository.sendMessage(
        matchId: event.matchId,
        fromUserId: event.fromUserId,
        toUserId: event.toUserId,
        content: url,
        type: event.type,
      ),
      logLabel: 'ChatRepository.sendMessage',
      fallbackError:
          'Media message failed to send. Check your connection and try again.',
    );

    if (sendResult.isSuccess) {
      AnalyticsService.instance.logMediaSent(
        matchId: event.matchId,
        mediaType: event.type.name,
      );
    }

    emit(
      state.copyWith(
        sendStatus: SendStatus.idle,
        uploadingAttachmentName: null,
        errorMessage: sendResult.errorMessage,
      ),
    );
  }

  // ---- Unsend ----

  Future<void> _onUnsend(
    MsgUnsendRequested event,
    Emitter<MessageHandlingState> emit,
  ) async {
    emit(state.copyWith(isUnsendInProgress: true, errorMessage: null));

    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not unsend message.',
    );
    final tier = planResult.data ?? SubscriptionTier.free;
    if (!planResult.isSuccess) {
      emit(
        state.copyWith(
          isUnsendInProgress: false,
          errorMessage: planResult.errorMessage,
        ),
      );
      return;
    }
    if (!tier.hasPremium) {
      emit(
        state.copyWith(
          isUnsendInProgress: false,
          errorMessage: 'Upgrade to Plus to unsend messages.',
        ),
      );
      return;
    }

    final result = await Result.guard(
      () => chatRepository.unsendMessage(
        matchId: event.matchId,
        messageId: event.messageId,
      ),
      logLabel: 'ChatRepository.unsendMessage',
      fallbackError: 'Could not unsend message.',
    );
    emit(
      state.copyWith(
        isUnsendInProgress: false,
        errorMessage: result.errorMessage,
      ),
    );
  }

  // ---- Edit ----

  Future<void> _onEdit(
    MsgEditRequested event,
    Emitter<MessageHandlingState> emit,
  ) async {
    emit(state.copyWith(isEditInProgress: true, errorMessage: null));

    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not edit message.',
    );
    final tier = planResult.data ?? SubscriptionTier.free;
    if (!planResult.isSuccess) {
      emit(
        state.copyWith(
          isEditInProgress: false,
          errorMessage: planResult.errorMessage,
        ),
      );
      return;
    }
    if (!tier.hasPremium) {
      emit(
        state.copyWith(
          isEditInProgress: false,
          errorMessage: 'Upgrade to Plus to edit messages.',
        ),
      );
      return;
    }

    final result = await Result.guard(
      () => chatRepository.editMessage(
        matchId: event.matchId,
        messageId: event.messageId,
        newContent: event.newContent,
      ),
      logLabel: 'ChatRepository.editMessage',
      fallbackError: 'Could not edit message.',
    );

    if (result.isSuccess) {
      AppLogger.debug(
        'MessageHandlingBloc: Message edited in match ${event.matchId}',
      );
    }

    emit(
      state.copyWith(
        isEditInProgress: false,
        errorMessage: result.errorMessage,
      ),
    );
  }

  // ---- Delete For Me ----

  Future<void> _onDeleteForMe(
    MsgDeleteForMeRequested event,
    Emitter<MessageHandlingState> emit,
  ) async {
    final result = await Result.guard(
      () => chatRepository.deleteForMe(
        matchId: event.matchId,
        messageId: event.messageId,
        userId: event.userId,
      ),
      logLabel: 'ChatRepository.deleteForMe',
      fallbackError: 'Could not delete message.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(errorMessage: result.errorMessage));
    }
  }

  // ---- Reactions ----

  Future<void> _onReactionAdded(
    MsgReactionAdded event,
    Emitter<MessageHandlingState> emit,
  ) async {
    final result = await Result.guard(
      () => chatRepository.addReaction(
        matchId: event.matchId,
        messageId: event.messageId,
        userId: event.userId,
        emoji: event.emoji,
      ),
      logLabel: 'ChatRepository.addReaction',
      fallbackError: 'Could not add reaction.',
    );
    if (result.isSuccess) {
      AnalyticsService.instance.logReactionAdded(emoji: event.emoji);
    } else {
      emit(state.copyWith(errorMessage: result.errorMessage));
    }
  }

  Future<void> _onReactionRemoved(
    MsgReactionRemoved event,
    Emitter<MessageHandlingState> emit,
  ) async {
    final result = await Result.guard(
      () => chatRepository.removeReaction(
        matchId: event.matchId,
        messageId: event.messageId,
        userId: event.userId,
      ),
      logLabel: 'ChatRepository.removeReaction',
      fallbackError: 'Could not remove reaction.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(errorMessage: result.errorMessage));
    }
  }

  // ---- Load More ----

  Future<void> _onLoadMore(
    MsgLoadMoreRequested event,
    Emitter<MessageHandlingState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMoreMessages) return;

    emit(state.copyWith(isLoadingMore: true));

    final oldestMessage = state.messages.isNotEmpty
        ? state.messages.first
        : null;
    final beforeTimestamp = oldestMessage?.sentAt;

    final result = await Result.guard(
      () => chatRepository.fetchMessagesPaginated(
        event.matchId,
        limit: _pageSize,
        beforeTimestamp: beforeTimestamp,
      ),
      logLabel: 'ChatRepository.fetchMessagesPaginated',
      fallbackError: 'Could not load more messages.',
    );

    if (result.isSuccess && result.data != null) {
      final paginated = result.data!;
      final decrypted = await _maybeDecryptMessages(paginated.items);
      // Merge older history into the existing window (dedupe + order), then
      // evict the newest beyond the cap: the user is scrolling up, so the
      // freshly-loaded older context is what must stay resident.
      final merged = MessageReconciler.capKeepingOldest(
        MessageReconciler.mergeServerMessages(
          existing: state.messages,
          incoming: decrypted,
        ),
        _maxMessagesInMemory,
      );

      emit(
        state.copyWith(
          messages: merged,
          isLoadingMore: false,
          hasMoreMessages: paginated.hasMore,
        ),
      );
    } else {
      emit(
        state.copyWith(isLoadingMore: false, errorMessage: result.errorMessage),
      );
    }
  }

  // ---- New Messages ----

  Future<void> _onNewMessages(
    MsgNewMessagesReceived event,
    Emitter<MessageHandlingState> emit,
  ) async {
    if (event.newMessages.isEmpty) return;

    final existingIds = state.messages.map((m) => m.id).toSet();
    final uniqueNewMessages = event.newMessages
        .where((m) => !existingIds.contains(m.id))
        .toList();

    if (uniqueNewMessages.isEmpty) return;

    final decryptedNewMessages = await _maybeDecryptMessages(uniqueNewMessages);
    // Merge (dedupe by id + restore chronological order even when a late
    // message arrives out of sequence), then evict the oldest beyond the cap
    // since the user is anchored at the newest end of the conversation.
    final merged = MessageReconciler.capKeepingNewest(
      MessageReconciler.mergeServerMessages(
        existing: state.messages,
        incoming: decryptedNewMessages,
      ),
      _maxMessagesInMemory,
    );

    emit(state.copyWith(messages: merged));
  }

  // ---- Legacy Messages Updated ----

  Future<void> _onLegacyMessages(
    MsgLegacyMessagesUpdated event,
    Emitter<MessageHandlingState> emit,
  ) async {
    final decryptedMessages = await _maybeDecryptMessages(event.messages);

    // The legacy stream delivers the full authoritative snapshot; order it
    // deterministically and drop any optimistic message whose server copy has
    // now landed (matched by id or content signature within the window).
    final ordered = MessageReconciler.mergeServerMessages(
      existing: const [],
      incoming: decryptedMessages,
    );
    final updatedFailedMessages = MessageReconciler.prunePending(
      pending: state.failedMessages,
      confirmed: ordered,
    );

    emit(
      state.copyWith(
        messages: ordered,
        canUnsend: event.tier.hasPremium,
        canEdit: event.tier.hasPremium,
        canSeeReadReceipts: event.tier.hasPremium,
        failedMessages: updatedFailedMessages,
      ),
    );
  }

  // ---- Retry ----

  Future<void> _onRetry(
    MsgRetryRequested event,
    Emitter<MessageHandlingState> emit,
  ) async {
    final failedMessage = state.failedMessages[event.messageId];
    if (failedMessage == null) {
      emit(
        state.copyWith(
          errorMessage: 'Message not found. It may have already been sent.',
        ),
      );
      return;
    }

    final updatedFailed = Map<String, Message>.from(state.failedMessages);
    updatedFailed[event.messageId] = failedMessage.copyWith(
      sendStatus: MessageSendStatus.sending,
    );
    emit(
      state.copyWith(
        failedMessages: updatedFailed,
        sendStatus: SendStatus.sendingText,
        errorMessage: null,
      ),
    );

    final result = await Result.guard(
      () => chatRepository.sendMessage(
        matchId: failedMessage.matchId,
        fromUserId: failedMessage.fromUserId,
        toUserId: failedMessage.toUserId,
        content: failedMessage.content,
        type: failedMessage.type,
      ),
      logLabel: 'ChatRepository.sendMessage (retry)',
      fallbackError: 'Message failed to send. Please try again.',
    );

    if (result.isSuccess) {
      final newFailed = Map<String, Message>.from(state.failedMessages);
      newFailed.remove(event.messageId);
      emit(
        state.copyWith(failedMessages: newFailed, sendStatus: SendStatus.idle),
      );

      AnalyticsService.instance.logMessageSent(
        matchId: failedMessage.matchId,
        messageType: failedMessage.type.name,
      );
    } else {
      final newFailed = Map<String, Message>.from(state.failedMessages);
      newFailed[event.messageId] = failedMessage.copyWith(
        sendStatus: MessageSendStatus.failed,
      );
      emit(
        state.copyWith(
          failedMessages: newFailed,
          sendStatus: SendStatus.idle,
          errorMessage: result.errorMessage,
        ),
      );
    }
  }

  // ---- Discard failed message ----

  void _onDiscardFailed(
    MsgDiscardFailedRequested event,
    Emitter<MessageHandlingState> emit,
  ) {
    final newFailed = Map<String, Message>.from(state.failedMessages);
    newFailed.remove(event.messageId);
    emit(state.copyWith(failedMessages: newFailed));
  }

  // ---- Reset ----

  void _onReset(MsgResetRequested event, Emitter<MessageHandlingState> emit) {
    AppLogger.debug('MessageHandlingBloc: Resetting state');
    _sub?.cancel();
    _newMessagesSub?.cancel();
    _sub = null;
    _newMessagesSub = null;
    emit(const MessageHandlingState());
  }

  // ---- Helpers ----

  int _mediaCountForUser(String userId) {
    return state.messages
        .where(
          (m) =>
              m.fromUserId == userId &&
              (m.type == MessageType.image || m.type == MessageType.video),
        )
        .length;
  }

  Future<List<Message>> _maybeDecryptMessages(List<Message> messages) async {
    if (messages.isEmpty) return messages;
    final shouldAttemptDecrypt =
        chatRepository.isE2eeEnabled ||
        messages.any((m) => chatRepository.isEncryptedContent(m.content));
    if (!shouldAttemptDecrypt) return messages;
    return Future.wait(messages.map(chatRepository.decryptMessage));
  }

  String _filename(String path) {
    final parts = path.split('/');
    if (parts.isNotEmpty) return parts.last;
    return path;
  }

  /// Cancel all active message stream subscriptions.
  void cancelSubscriptions() {
    _sub?.cancel();
    _newMessagesSub?.cancel();
    _sub = null;
    _newMessagesSub = null;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _newMessagesSub?.cancel();
    return super.close();
  }
}
