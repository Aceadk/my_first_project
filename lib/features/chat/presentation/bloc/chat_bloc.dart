import 'dart:async';
import 'package:crushhour/core/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'realtime_state_cubit.dart';
import 'chat_session_cubit.dart';
import 'message_handling_bloc.dart';

/// Facade BLoC that delegates to three focused sub-BLoCs while maintaining
/// the same external [ChatEvent]/[ChatState] API for [ChatScreen].
///
/// Sub-BLoCs:
/// - [RealtimeStateCubit]: typing indicators, presence, media permissions
/// - [ChatSessionCubit]: unmatch, E2EE toggle, other-user photo
/// - [MessageHandlingBloc]: messages, send/receive/edit/unsend/delete,
///   reactions, pagination, retry
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final SubscriptionRepository subscriptionRepository;
  final AuthRepository authRepository;

  // ---- Sub-BLoCs ----
  late final RealtimeStateCubit _realtimeCubit;
  late final ChatSessionCubit _sessionCubit;
  late final MessageHandlingBloc _messageBloc;

  // ---- Stream subscriptions (realtime watchers + sub-BLoC listeners) ----
  StreamSubscription<Set<String>>? _typingSub;
  StreamSubscription<bool>? _presenceSub;
  StreamSubscription<bool>? _mediaSub;
  // ignore: cancel_subscriptions
  StreamSubscription? _authSubscription;

  // ignore: cancel_subscriptions
  StreamSubscription<RealtimeState>? _realtimeStateSub;
  // ignore: cancel_subscriptions
  StreamSubscription<ChatSessionState>? _sessionStateSub;
  // ignore: cancel_subscriptions
  StreamSubscription<MessageHandlingState>? _messageStateSub;

  ChatBloc({
    required this.chatRepository,
    required this.subscriptionRepository,
    required this.authRepository,
  }) : super(const ChatState()) {
    // Create sub-BLoCs
    _realtimeCubit = RealtimeStateCubit();
    _sessionCubit = ChatSessionCubit(chatRepository: chatRepository);
    _messageBloc = MessageHandlingBloc(
      chatRepository: chatRepository,
      subscriptionRepository: subscriptionRepository,
      isE2eeEnabled: () => _sessionCubit.isE2eeEnabled,
    );

    // Listen to sub-BLoC state changes and re-aggregate into ChatState
    // ignore: cancel_subscriptions
    _realtimeStateSub = _realtimeCubit.stream.listen((_) {
      if (!isClosed) add(ChatSubBlocChanged());
    });
    // ignore: cancel_subscriptions
    _sessionStateSub = _sessionCubit.stream.listen((_) {
      if (!isClosed) add(ChatSubBlocChanged());
    });
    // ignore: cancel_subscriptions
    _messageStateSub = _messageBloc.stream.listen((_) {
      if (!isClosed) add(ChatSubBlocChanged());
    });

    // Register all ChatEvent handlers (thin routing layer)
    on<ChatSubBlocChanged>(_onSubBlocChanged);
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
    on<ChatMessageDiscardRequested>(_onMessageDiscardRequested);
    on<ChatResetRequested>(_onResetRequested);
    on<ChatE2eeToggled>(_onE2eeToggled);

    // Subscribe to auth state changes to reset on logout
    // ignore: cancel_subscriptions
    _authSubscription = authRepository.authStateChanges().listen((user) {
      if (user == null) {
        add(ChatResetRequested());
      }
    });
  }

  // =========================================================================
  // Aggregate sub-BLoC states into ChatState
  // =========================================================================

  /// Build a [ChatState] from the current sub-BLoC states.
  ChatState _buildAggregatedState() {
    final rt = _realtimeCubit.state;
    final ss = _sessionCubit.state;
    final mh = _messageBloc.state;

    // Merge error messages: prefer the most recent non-null one.
    final errorMessage = mh.errorMessage ?? ss.errorMessage;

    return ChatState(
      // RealtimeStateCubit fields
      typingUserIds: rt.typingUserIds,
      otherUserOnline: rt.otherUserOnline,
      mediaSendingEnabled: rt.mediaSendingEnabled,
      // ChatSessionCubit fields
      isUnmatching: ss.isUnmatching,
      isUnmatched: ss.isUnmatched,
      otherUserPhotoUrl: ss.otherUserPhotoUrl,
      isE2eeEnabled: ss.isE2eeEnabled,
      // MessageHandlingBloc fields
      messages: mh.messages,
      failedMessages: mh.failedMessages,
      isInitialLoading: mh.isInitialLoading,
      isLoadingMore: mh.isLoadingMore,
      hasMoreMessages: mh.hasMoreMessages,
      sendStatus: mh.sendStatus,
      uploadingAttachmentName: mh.uploadingAttachmentName,
      isUnsendInProgress: mh.isUnsendInProgress,
      isEditInProgress: mh.isEditInProgress,
      canUnsend: mh.canUnsend,
      canEdit: mh.canEdit,
      canSeeReadReceipts: mh.canSeeReadReceipts,
      // Merged
      errorMessage: errorMessage,
    );
  }

  /// Called when any sub-BLoC emits a new state. Re-emits combined ChatState
  /// only if the aggregated result differs (Equatable comparison prevents
  /// redundant widget rebuilds from high-frequency typing/presence updates).
  void _onSubBlocChanged(ChatSubBlocChanged event, Emitter<ChatState> emit) {
    final newState = _buildAggregatedState();
    if (newState != state) {
      emit(newState);
    }
  }

  // =========================================================================
  // Event handlers -- thin routing to sub-BLoCs
  // =========================================================================

  Future<void> _onChatOpened(ChatOpened event, Emitter<ChatState> emit) async {
    // Reset realtime state
    _realtimeCubit.reset();
    _realtimeCubit.updateMediaEnabled(true);

    // Initialize session
    _sessionCubit.openSession(otherUserPhotoUrl: event.otherUserPhotoUrl);

    // Cancel previous realtime subscriptions
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _mediaSub?.cancel();

    // Set own presence
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

    // Delegate message loading to MessageHandlingBloc
    _messageBloc.add(
      MsgInitialLoadRequested(
        matchId: event.matchId,
        currentUserId: event.currentUserId,
      ),
    );

    // Start realtime watchers
    _typingSub = chatRepository.watchTyping(event.matchId).listen((
      typingUsers,
    ) {
      add(ChatTypingUsersUpdated(typingUsers));
    });
    _presenceSub = chatRepository.watchPresence(event.otherUserId).listen((
      isOnline,
    ) {
      add(ChatPresenceUpdated(isOnline));
    });
    _mediaSub = chatRepository.watchMediaSendingEnabled(event.matchId).listen((
      enabled,
    ) {
      add(ChatMediaStatusUpdated(enabled));
    });
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
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _mediaSub?.cancel();
    _messageBloc.cancelSubscriptions();
  }

  // ---- Message events -> MessageHandlingBloc ----

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(
      MsgSendRequested(
        matchId: event.matchId,
        fromUserId: event.fromUserId,
        toUserId: event.toUserId,
        content: event.content,
        type: event.type,
      ),
    );
  }

  Future<void> _onMediaSendRequested(
    ChatMediaSendRequested event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(
      MsgMediaSendRequested(
        matchId: event.matchId,
        fromUserId: event.fromUserId,
        toUserId: event.toUserId,
        filePath: event.filePath,
        type: event.type,
        mediaSendingEnabled: _realtimeCubit.state.mediaSendingEnabled,
      ),
    );
  }

  Future<void> _onUnsendRequested(
    ChatMessageUnsendRequested event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(
      MsgUnsendRequested(matchId: event.matchId, messageId: event.messageId),
    );
  }

  Future<void> _onEditRequested(
    ChatMessageEditRequested event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(
      MsgEditRequested(
        matchId: event.matchId,
        messageId: event.messageId,
        newContent: event.newContent,
      ),
    );
  }

  Future<void> _onDeleteForMeRequested(
    ChatMessageDeleteForMeRequested event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(
      MsgDeleteForMeRequested(
        matchId: event.matchId,
        messageId: event.messageId,
        userId: event.userId,
      ),
    );
  }

  Future<void> _onMessagesUpdated(
    ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(MsgLegacyMessagesUpdated(event.messages, event.plan));
  }

  Future<void> _onReactionAdded(
    ChatReactionAdded event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(
      MsgReactionAdded(
        matchId: event.matchId,
        messageId: event.messageId,
        userId: event.userId,
        emoji: event.emoji,
      ),
    );
  }

  Future<void> _onReactionRemoved(
    ChatReactionRemoved event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(
      MsgReactionRemoved(
        matchId: event.matchId,
        messageId: event.messageId,
        userId: event.userId,
      ),
    );
  }

  Future<void> _onLoadMoreMessages(
    ChatLoadMoreMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(MsgLoadMoreRequested(event.matchId));
  }

  Future<void> _onNewMessagesReceived(
    ChatNewMessagesReceived event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(MsgNewMessagesReceived(event.newMessages));
  }

  Future<void> _onMessageRetryRequested(
    ChatMessageRetryRequested event,
    Emitter<ChatState> emit,
  ) async {
    _messageBloc.add(
      MsgRetryRequested(matchId: event.matchId, messageId: event.messageId),
    );
  }

  void _onMessageDiscardRequested(
    ChatMessageDiscardRequested event,
    Emitter<ChatState> emit,
  ) {
    _messageBloc.add(MsgDiscardFailedRequested(messageId: event.messageId));
  }

  // ---- Typing events -> RealtimeStateCubit (+ repository call) ----

  Future<void> _onTypingChanged(
    ChatTypingStatusChanged event,
    Emitter<ChatState> emit,
  ) async {
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
    ChatTypingUsersUpdated event,
    Emitter<ChatState> emit,
  ) {
    _realtimeCubit.updateTyping(event.typingUserIds);
    emit(_buildAggregatedState());
  }

  // ---- Presence events -> RealtimeStateCubit ----

  void _onPresenceUpdated(ChatPresenceUpdated event, Emitter<ChatState> emit) {
    _realtimeCubit.updatePresence(event.isOnline);
    emit(_buildAggregatedState());
  }

  // ---- Media toggle -> repository + RealtimeStateCubit ----

  Future<void> _onMediaToggleRequested(
    ChatMediaToggleRequested event,
    Emitter<ChatState> emit,
  ) async {
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
    ChatMediaStatusUpdated event,
    Emitter<ChatState> emit,
  ) {
    _realtimeCubit.updateMediaEnabled(event.enabled);
    emit(_buildAggregatedState());
  }

  // ---- Unmatch -> ChatSessionCubit ----

  Future<void> _onUnmatchRequested(
    ChatUnmatchRequested event,
    Emitter<ChatState> emit,
  ) async {
    // Listen to session cubit changes and emit intermediate states
    final sub = _sessionCubit.stream.listen((_) {
      emit(_buildAggregatedState());
    });
    await _sessionCubit.unmatch(matchId: event.matchId, userId: event.userId);
    await sub.cancel();
  }

  // ---- E2EE toggle -> ChatSessionCubit ----

  void _onE2eeToggled(ChatE2eeToggled event, Emitter<ChatState> emit) {
    _sessionCubit.toggleE2ee(event.enabled);
    emit(_buildAggregatedState());
  }

  // ---- Reset ----

  void _onResetRequested(ChatResetRequested event, Emitter<ChatState> emit) {
    AppLogger.debug('ChatBloc: Resetting chat state on logout');
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _mediaSub?.cancel();
    _typingSub = null;
    _presenceSub = null;
    _mediaSub = null;

    _realtimeCubit.reset();
    _sessionCubit.reset();
    _messageBloc.add(MsgResetRequested());

    emit(const ChatState());
  }

  // =========================================================================
  // Cleanup
  // =========================================================================

  @override
  Future<void> close() async {
    // Cancel all stream subscriptions with error isolation so one failure
    // doesn't prevent others from being cleaned up.
    for (final sub in [
      _typingSub,
      _presenceSub,
      _mediaSub,
      _authSubscription,
      _realtimeStateSub,
      _sessionStateSub,
      _messageStateSub,
    ]) {
      try {
        await sub?.cancel();
      } catch (e) {
        AppLogger.error('ChatBloc: Error cancelling subscription: $e');
      }
    }

    // Close sub-BLoCs with error isolation
    for (final bloc in [_realtimeCubit, _sessionCubit, _messageBloc]) {
      try {
        await bloc.close();
      } catch (e) {
        AppLogger.error('ChatBloc: Error closing sub-bloc: $e');
      }
    }

    return super.close();
  }
}
