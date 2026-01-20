import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final SubscriptionRepository subscriptionRepository;
  final AuthRepository authRepository;
  StreamSubscription<List<Message>>? _sub;
  StreamSubscription<List<Message>>? _newMessagesSub;
  StreamSubscription<Set<String>>? _typingSub;
  StreamSubscription<bool>? _presenceSub;
  StreamSubscription<bool>? _mediaSub;
  StreamSubscription? _authSubscription;

  static const int _pageSize = 30;

  ChatBloc({
    required this.chatRepository,
    required this.subscriptionRepository,
    required this.authRepository,
  }) : super(const ChatState()) {
    on<ChatOpened>(_onChatOpened);
    on<ChatClosed>(_onChatClosed);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMediaSendRequested>(_onMediaSendRequested);
    on<ChatMessageUnsendRequested>(_onUnsendRequested);
    on<ChatMessageEditRequested>(_onEditRequested);
    on<ChatMessageDeleteForMeRequested>(_onDeleteForMeRequested);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
    on<ChatTypingStatusChanged>(_onTypingChanged);
    on<ChatTypingUsersUpdated>(_onTypingUsersUpdated);
    on<ChatPresenceUpdated>(_onPresenceUpdated);
    on<ChatReactionAdded>(_onReactionAdded);
    on<ChatReactionRemoved>(_onReactionRemoved);
    on<ChatMediaToggleRequested>(_onMediaToggleRequested);
    on<ChatMediaStatusUpdated>(_onMediaStatusUpdated);
    on<ChatUnmatchRequested>(_onUnmatchRequested);
    on<ChatLoadMoreMessagesRequested>(_onLoadMoreMessages);
    on<ChatNewMessagesReceived>(_onNewMessagesReceived);
    on<ChatMessageRetryRequested>(_onMessageRetryRequested);
    on<ChatResetRequested>(_onResetRequested);

    // Subscribe to auth state changes to reset on logout
    _authSubscription = authRepository.authStateChanges().listen((user) {
      if (user == null) {
        // CRITICAL: Reset state on logout to prevent data leakage
        add(ChatResetRequested());
      }
    });
  }

  Future<void> _onChatOpened(ChatOpened event, Emitter<ChatState> emit) async {
    emit(state.copyWith(
      errorMessage: null,
      typingUserIds: const {},
      otherUserOnline: false,
      otherUserPhotoUrl: event.otherUserPhotoUrl,
      mediaSendingEnabled: true,
      isUnmatching: false,
      isUnmatched: false,
    ));
    _sub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _mediaSub?.cancel();

    final presenceResult = await Result.guard(
      () => chatRepository.setPresence(
        userId: event.currentUserId,
        isOnline: true,
      ),
      logLabel: 'ChatRepository.setPresence',
      fallbackError: 'Could not join chat right now.',
    );
    if (!presenceResult.isSuccess) {
      emit(state.copyWith(errorMessage: presenceResult.errorMessage));
    }

    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not load chat.',
    );
    if (!planResult.isSuccess) {
      emit(state.copyWith(errorMessage: planResult.errorMessage));
      return;
    }
    final plan = planResult.data ?? SubscriptionPlan.free;
    _sub = chatRepository.watchMessages(event.matchId).listen((messages) {
      add(ChatMessagesUpdated(messages, plan));
    });
    _typingSub =
        chatRepository.watchTyping(event.matchId).listen((typingUsers) {
      add(ChatTypingUsersUpdated(typingUsers));
    });
    _presenceSub =
        chatRepository.watchPresence(event.otherUserId).listen((isOnline) {
      add(ChatPresenceUpdated(isOnline));
    });
    _mediaSub = chatRepository
        .watchMediaSendingEnabled(event.matchId)
        .listen((enabled) {
      add(ChatMediaStatusUpdated(enabled));
    });
    emit(state.copyWith(canUnsend: plan.isPlus, canEdit: plan.isPlus, errorMessage: null));

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

  Future<void> _onChatClosed(ChatClosed event, Emitter<ChatState> emit) async {
    await Result.guard(
      () => chatRepository.setTyping(
        matchId: event.matchId,
        userId: event.currentUserId,
        isTyping: false,
      ),
      logLabel: 'ChatRepository.setTyping',
      fallbackError: 'Could not update typing status.',
    );
    await Result.guard(
      () => chatRepository.setPresence(
        userId: event.currentUserId,
        isOnline: false,
      ),
      logLabel: 'ChatRepository.setPresence',
      fallbackError: 'Could not update presence.',
    );
    _sub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _mediaSub?.cancel();
  }

  Future<void> _onMessageSent(
      ChatMessageSent event, Emitter<ChatState> emit) async {
    final content = event.content.trim();
    if (content.isEmpty) return;

    // Create a temp ID for tracking this message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic update: show message immediately with "sending" status
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

    emit(state.copyWith(
      sendStatus: SendStatus.sendingText,
      errorMessage: null,
      failedMessages: pendingMessages,
    ));

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

    // Track message sent
    if (result.isSuccess) {
      AnalyticsService.instance.logMessageSent(
        matchId: event.matchId,
        messageType: event.type.name,
      );
      // Remove optimistic message (real message will come through stream)
      final newPending = Map<String, Message>.from(state.failedMessages);
      newPending.remove(tempId);
      emit(state.copyWith(
        sendStatus: SendStatus.idle,
        failedMessages: newPending,
      ));
    } else {
      // Update to failed status for retry
      final newFailed = Map<String, Message>.from(state.failedMessages);
      newFailed[tempId] = optimisticMessage.copyWith(
        sendStatus: MessageSendStatus.failed,
      );
      emit(state.copyWith(
        sendStatus: SendStatus.idle,
        errorMessage: result.errorMessage,
        failedMessages: newFailed,
      ));
    }
  }

  Future<void> _onMediaSendRequested(
      ChatMediaSendRequested event, Emitter<ChatState> emit) async {
    if (!state.mediaSendingEnabled) {
      emit(state.copyWith(
        sendStatus: SendStatus.idle,
        uploadingAttachmentName: null,
        errorMessage: 'Media sending is disabled for this match.',
      ));
      return;
    }
    emit(state.copyWith(
      sendStatus: SendStatus.uploadingAttachment,
      uploadingAttachmentName: _filename(event.filePath),
      errorMessage: null,
    ));
    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not send media. Please try again.',
    );
    final plan = planResult.data ?? SubscriptionPlan.free;
    if (!planResult.isSuccess) {
      emit(state.copyWith(
        sendStatus: SendStatus.idle,
        uploadingAttachmentName: null,
        errorMessage: planResult.errorMessage,
      ));
      return;
    }
    if (!plan.isPlus && _mediaCountForUser(event.fromUserId) >= 8) {
      emit(state.copyWith(
        sendStatus: SendStatus.idle,
        uploadingAttachmentName: null,
        errorMessage:
            'Media limit reached. Upgrade to Plus for unlimited media.',
      ));
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
      emit(state.copyWith(
        sendStatus: SendStatus.idle,
        uploadingAttachmentName: null,
        errorMessage: uploadResult.errorMessage,
      ));
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

    // Track media sent
    if (sendResult.isSuccess) {
      AnalyticsService.instance.logMediaSent(
        matchId: event.matchId,
        mediaType: event.type.name,
      );
    }

    emit(state.copyWith(
      sendStatus: SendStatus.idle,
      uploadingAttachmentName: null,
      errorMessage: sendResult.errorMessage,
    ));
  }

  Future<void> _onUnsendRequested(
      ChatMessageUnsendRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isUnsendInProgress: true, errorMessage: null));

    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not unsend message.',
    );
    final plan = planResult.data ?? SubscriptionPlan.free;
    if (!planResult.isSuccess) {
      emit(state.copyWith(
        isUnsendInProgress: false,
        errorMessage: planResult.errorMessage,
      ));
      return;
    }
    if (!plan.isPlus) {
      emit(state.copyWith(
        isUnsendInProgress: false,
        errorMessage: 'Upgrade to Plus to unsend messages.',
      ));
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
    emit(state.copyWith(
      isUnsendInProgress: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onEditRequested(
      ChatMessageEditRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isEditInProgress: true, errorMessage: null));

    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not edit message.',
    );
    final plan = planResult.data ?? SubscriptionPlan.free;
    if (!planResult.isSuccess) {
      emit(state.copyWith(
        isEditInProgress: false,
        errorMessage: planResult.errorMessage,
      ));
      return;
    }
    if (!plan.isPlus) {
      emit(state.copyWith(
        isEditInProgress: false,
        errorMessage: 'Upgrade to Plus to edit messages.',
      ));
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
      debugPrint('ChatBloc: Message edited in match ${event.matchId}');
    }

    emit(state.copyWith(
      isEditInProgress: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onDeleteForMeRequested(
      ChatMessageDeleteForMeRequested event, Emitter<ChatState> emit) async {
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

  Future<void> _onReactionAdded(
      ChatReactionAdded event, Emitter<ChatState> emit) async {
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
      ChatReactionRemoved event, Emitter<ChatState> emit) async {
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

  Future<void> _onTypingChanged(
      ChatTypingStatusChanged event, Emitter<ChatState> emit) async {
    await Result.guard(
      () => chatRepository.setTyping(
        matchId: event.matchId,
        userId: event.userId,
        isTyping: event.isTyping,
      ),
      logLabel: 'ChatRepository.setTyping',
      fallbackError: 'Could not update typing status.',
    );
  }

  void _onTypingUsersUpdated(
      ChatTypingUsersUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(typingUserIds: event.typingUserIds));
  }

  void _onPresenceUpdated(ChatPresenceUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(otherUserOnline: event.isOnline));
  }

  Future<void> _onMediaToggleRequested(
      ChatMediaToggleRequested event, Emitter<ChatState> emit) async {
    final result = await Result.guard(
      () => chatRepository.setMediaSendingEnabled(
        matchId: event.matchId,
        enabled: event.enabled,
        requesterId: event.requesterId,
      ),
      logLabel: 'ChatRepository.setMediaSendingEnabled',
      fallbackError: 'Could not update media permissions.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(errorMessage: result.errorMessage));
    }
  }

  void _onMediaStatusUpdated(
      ChatMediaStatusUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(mediaSendingEnabled: event.enabled));
  }

  Future<void> _onUnmatchRequested(
      ChatUnmatchRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isUnmatching: true, errorMessage: null));
    final result = await Result.guard(
      () => chatRepository.unmatch(
        matchId: event.matchId,
        userId: event.userId,
      ),
      logLabel: 'ChatRepository.unmatch',
      fallbackError: 'Could not unmatch right now.',
    );

    // Track unmatch
    if (result.isSuccess) {
      AnalyticsService.instance.logUnmatch(matchId: event.matchId);
    }

    emit(state.copyWith(
      isUnmatching: false,
      isUnmatched: result.isSuccess ? true : state.isUnmatched,
      errorMessage: result.errorMessage,
    ));
  }

  void _onMessagesUpdated(ChatMessagesUpdated event, Emitter<ChatState> emit) {
    // Remove optimistic messages that now have real counterparts from server
    // Match by content, sender, and approximate timestamp (within 30 seconds)
    final updatedFailedMessages = Map<String, Message>.from(state.failedMessages);
    final serverMessageSignatures = event.messages.map((m) =>
      '${m.fromUserId}_${m.content}_${m.type.name}'
    ).toSet();

    updatedFailedMessages.removeWhere((tempId, optimisticMsg) {
      final signature = '${optimisticMsg.fromUserId}_${optimisticMsg.content}_${optimisticMsg.type.name}';
      // If a server message matches this optimistic message, remove it
      if (serverMessageSignatures.contains(signature)) {
        // Find the matching server message and check timestamp
        final matchingServerMsg = event.messages.firstWhere(
          (m) => '${m.fromUserId}_${m.content}_${m.type.name}' == signature,
          orElse: () => optimisticMsg,
        );
        // Only remove if within 30 seconds of each other
        final timeDiff = matchingServerMsg.sentAt.difference(optimisticMsg.sentAt).inSeconds.abs();
        return timeDiff < 30;
      }
      return false;
    });

    emit(state.copyWith(
      messages: event.messages,
      canUnsend: event.plan.isPlus,
      canEdit: event.plan.isPlus,
      failedMessages: updatedFailedMessages,
    ));
  }

  /// Load more (older) messages when user scrolls to the top.
  Future<void> _onLoadMoreMessages(
    ChatLoadMoreMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMoreMessages) return;

    emit(state.copyWith(isLoadingMore: true));

    // Get the oldest message timestamp for cursor
    final oldestMessage = state.messages.isNotEmpty ? state.messages.first : null;
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
      // Prepend older messages to the existing list
      final allMessages = [...paginated.items, ...state.messages];
      emit(state.copyWith(
        messages: allMessages,
        isLoadingMore: false,
        hasMoreMessages: paginated.hasMore,
      ));
    } else {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: result.errorMessage,
      ));
    }
  }

  /// Handle new messages received in real-time.
  void _onNewMessagesReceived(
    ChatNewMessagesReceived event,
    Emitter<ChatState> emit,
  ) {
    if (event.newMessages.isEmpty) return;

    // Filter out duplicates
    final existingIds = state.messages.map((m) => m.id).toSet();
    final uniqueNewMessages = event.newMessages
        .where((m) => !existingIds.contains(m.id))
        .toList();

    if (uniqueNewMessages.isEmpty) return;

    // Append new messages to the end
    final allMessages = [...state.messages, ...uniqueNewMessages];

    emit(state.copyWith(messages: allMessages));
  }

  /// Retry sending a failed message.
  Future<void> _onMessageRetryRequested(
    ChatMessageRetryRequested event,
    Emitter<ChatState> emit,
  ) async {
    final failedMessage = state.failedMessages[event.messageId];
    if (failedMessage == null) {
      emit(state.copyWith(
        errorMessage: 'Message not found. It may have already been sent.',
      ));
      return;
    }

    // Update the failed message to "sending" status
    final updatedFailed = Map<String, Message>.from(state.failedMessages);
    updatedFailed[event.messageId] = failedMessage.copyWith(
      sendStatus: MessageSendStatus.sending,
    );
    emit(state.copyWith(
      failedMessages: updatedFailed,
      sendStatus: SendStatus.sendingText,
      errorMessage: null,
    ));

    // Attempt to resend
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
      // Remove from failed messages on success
      final newFailed = Map<String, Message>.from(state.failedMessages);
      newFailed.remove(event.messageId);
      emit(state.copyWith(
        failedMessages: newFailed,
        sendStatus: SendStatus.idle,
      ));

      // Track retry success
      AnalyticsService.instance.logMessageSent(
        matchId: failedMessage.matchId,
        messageType: failedMessage.type.name,
      );
    } else {
      // Mark as failed again
      final newFailed = Map<String, Message>.from(state.failedMessages);
      newFailed[event.messageId] = failedMessage.copyWith(
        sendStatus: MessageSendStatus.failed,
      );
      emit(state.copyWith(
        failedMessages: newFailed,
        sendStatus: SendStatus.idle,
        errorMessage: result.errorMessage,
      ));
    }
  }

  int _mediaCountForUser(String userId) {
    return state.messages
        .where((m) =>
            m.fromUserId == userId &&
            (m.type == MessageType.image || m.type == MessageType.video))
        .length;
  }

  String _filename(String path) {
    final parts = path.split('/');
    if (parts.isNotEmpty) return parts.last;
    return path;
  }

  /// Reset chat state on logout.
  /// CRITICAL: This prevents the next user from seeing the previous user's chat history.
  void _onResetRequested(ChatResetRequested event, Emitter<ChatState> emit) {
    debugPrint('ChatBloc: Resetting chat state on logout');
    _sub?.cancel();
    _newMessagesSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _mediaSub?.cancel();
    _sub = null;
    _newMessagesSub = null;
    _typingSub = null;
    _presenceSub = null;
    _mediaSub = null;
    emit(const ChatState()); // Reset to initial empty state
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _newMessagesSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _mediaSub?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
