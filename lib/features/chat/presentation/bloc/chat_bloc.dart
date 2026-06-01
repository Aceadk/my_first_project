import 'dart:async';
import 'package:crushhour/core/app_logger.dart';
import 'package:flutter/widgets.dart';
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

enum _ChatSubscriptionKey {
  typing,
  presence,
  media,
  auth,
  realtimeState,
  sessionState,
  messageState,
}

/// Facade BLoC that delegates to three focused sub-BLoCs while maintaining
/// the same external [ChatEvent]/[ChatState] API for [ChatScreen].
///
/// Sub-BLoCs:
/// - [RealtimeStateCubit]: typing indicators, presence, media permissions
/// - [ChatSessionCubit]: unmatch, E2EE toggle, other-user photo
/// - [MessageHandlingBloc]: messages, send/receive/edit/unsend/delete,
///   reactions, pagination, retry
class ChatBloc extends Bloc<ChatEvent, ChatState> with WidgetsBindingObserver {
  final ChatRepository chatRepository;
  final SubscriptionRepository subscriptionRepository;
  final AuthRepository authRepository;

  // ---- Sub-BLoCs ----
  late final RealtimeStateCubit _realtimeCubit;
  late final ChatSessionCubit _sessionCubit;
  late final MessageHandlingBloc _messageBloc;

  // ---- Managed stream subscriptions ----
  final Map<_ChatSubscriptionKey, StreamSubscription<dynamic>>
  _managedSubscriptions = <_ChatSubscriptionKey, StreamSubscription<dynamic>>{};

  // ---- Active conversation (for lifecycle-driven typing/presence) ----
  String? _activeMatchId;
  String? _activeUserId;
  bool _lifecycleObserverRegistered = false;

  ChatBloc({
    required this.chatRepository,
    required this.subscriptionRepository,
    required this.authRepository,
  }) : super(ChatState()) {
    // Create sub-BLoCs
    _realtimeCubit = RealtimeStateCubit();
    _sessionCubit = ChatSessionCubit(chatRepository: chatRepository);
    _messageBloc = MessageHandlingBloc(
      chatRepository: chatRepository,
      subscriptionRepository: subscriptionRepository,
      isE2eeEnabled: () => _sessionCubit.isE2eeEnabled,
    );

    // Listen to sub-BLoC state changes and re-aggregate into ChatState.
    _setManagedSubscription<RealtimeState>(
      _ChatSubscriptionKey.realtimeState,
      _realtimeCubit.stream,
      (_) => _notifySubBlocStateChanged(),
    );
    _setManagedSubscription<ChatSessionState>(
      _ChatSubscriptionKey.sessionState,
      _sessionCubit.stream,
      (_) => _notifySubBlocStateChanged(),
    );
    _setManagedSubscription<MessageHandlingState>(
      _ChatSubscriptionKey.messageState,
      _messageBloc.stream,
      (_) => _notifySubBlocStateChanged(),
    );

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
    on<ChatAppLifecycleChanged>(_onAppLifecycleChanged);

    // Subscribe to auth state changes to reset on logout.
    _setManagedSubscription<Object?>(
      _ChatSubscriptionKey.auth,
      authRepository.authStateChanges(),
      _onAuthUserChanged,
    );

    // CHAT-RT-002: observe app lifecycle so backgrounding clears the outgoing
    // typing indicator and presence. Guarded so the BLoC can still be built in
    // environments without an initialized binding (e.g. isolated unit tests).
    try {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
    } catch (e) {
      AppLogger.debug('ChatBloc: lifecycle observer unavailable: $e');
    }
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
    if (event.aggregatedState != state) {
      emit(event.aggregatedState);
    }
  }

  // =========================================================================
  // Event handlers -- thin routing to sub-BLoCs
  // =========================================================================

  Future<void> _onChatOpened(ChatOpened event, Emitter<ChatState> emit) async {
    // Record the active conversation for lifecycle-driven typing/presence.
    _activeMatchId = event.matchId;
    _activeUserId = event.currentUserId;

    // Reset realtime state
    _realtimeCubit.reset();
    _realtimeCubit.updateMediaEnabled(true);

    // Initialize session
    _sessionCubit.openSession(otherUserPhotoUrl: event.otherUserPhotoUrl);

    // Cancel previous realtime subscriptions before opening new watchers.
    await _cancelRealtimeSubscriptions();

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

    _startRealtimeSubscriptions(event);
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
    await _cancelRealtimeSubscriptions();
    _messageBloc.cancelSubscriptions();

    _activeMatchId = null;
    _activeUserId = null;
  }

  // ---- App lifecycle -> clear outgoing typing + toggle presence ----

  Future<void> _onAppLifecycleChanged(
    ChatAppLifecycleChanged event,
    Emitter<ChatState> emit,
  ) async {
    final matchId = _activeMatchId;
    final userId = _activeUserId;
    // No active conversation: nothing to clean up.
    if (matchId == null || userId == null) return;

    switch (event.lifecycleState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // Clear our own typing indicator so the peer doesn't see a stale
        // "typing…" once the OS freezes the debounce timer, and go offline.
        await Result.guard(
          () => chatRepository.setTyping(
            matchId: matchId,
            userId: userId,
            isTyping: false,
          ),
          logLabel: 'ChatRepository.setTyping (background)',
          fallbackError: 'Could not update typing status.',
        );
        await Result.guard(
          () => chatRepository.setPresence(userId: userId, isOnline: false),
          logLabel: 'ChatRepository.setPresence (background)',
          fallbackError: 'Could not update presence.',
        );
        break;
      case AppLifecycleState.resumed:
        // Coming back to the foreground: mark online again.
        await Result.guard(
          () => chatRepository.setPresence(userId: userId, isOnline: true),
          logLabel: 'ChatRepository.setPresence (foreground)',
          fallbackError: 'Could not update presence.',
        );
        break;
      case AppLifecycleState.inactive:
        // Transient (e.g. notification shade / app switcher peek). Ignore to
        // avoid flapping presence/typing on momentary interruptions.
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isClosed) {
      add(ChatAppLifecycleChanged(state));
    }
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
    _messageBloc.add(MsgLegacyMessagesUpdated(event.messages, event.tier));
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

  void _onUnmatchRequested(
    ChatUnmatchRequested event,
    Emitter<ChatState> emit,
  ) {
    unawaited(
      _sessionCubit.unmatch(matchId: event.matchId, userId: event.userId),
    );
  }

  // ---- E2EE toggle -> ChatSessionCubit ----

  void _onE2eeToggled(ChatE2eeToggled event, Emitter<ChatState> emit) {
    _sessionCubit.toggleE2ee(event.enabled);
    emit(_buildAggregatedState());
  }

  // ---- Reset ----

  Future<void> _onResetRequested(
    ChatResetRequested event,
    Emitter<ChatState> emit,
  ) async {
    AppLogger.debug('ChatBloc: Resetting chat state on logout');
    await _cancelRealtimeSubscriptions();

    _activeMatchId = null;
    _activeUserId = null;
    _realtimeCubit.reset();
    _sessionCubit.reset();
    _messageBloc.add(MsgResetRequested());

    emit(ChatState());
  }

  // =========================================================================
  // Subscription management helpers
  // =========================================================================

  void _notifySubBlocStateChanged() {
    if (!isClosed) {
      add(ChatSubBlocChanged(_buildAggregatedState()));
    }
  }

  void _onAuthUserChanged(Object? user) {
    if (user == null && !isClosed) {
      add(ChatResetRequested());
    }
  }

  void _startRealtimeSubscriptions(ChatOpened event) {
    _setManagedSubscription<Set<String>>(
      _ChatSubscriptionKey.typing,
      chatRepository.watchTyping(event.matchId),
      (typingUsers) {
        if (!isClosed) {
          add(ChatTypingUsersUpdated(typingUsers));
        }
      },
    );
    _setManagedSubscription<bool>(
      _ChatSubscriptionKey.presence,
      chatRepository.watchPresence(event.otherUserId),
      (isOnline) {
        if (!isClosed) {
          add(ChatPresenceUpdated(isOnline));
        }
      },
    );
    _setManagedSubscription<bool>(
      _ChatSubscriptionKey.media,
      chatRepository.watchMediaSendingEnabled(event.matchId),
      (enabled) {
        if (!isClosed) {
          add(ChatMediaStatusUpdated(enabled));
        }
      },
    );
  }

  void _setManagedSubscription<T>(
    _ChatSubscriptionKey key,
    Stream<T> stream,
    void Function(T value) onData,
  ) {
    final previous = _managedSubscriptions[key];
    if (previous != null) {
      unawaited(
        previous.cancel().catchError((Object error, StackTrace _) {
          AppLogger.error(
            'ChatBloc: Error cancelling previous subscription ($key): $error',
          );
        }),
      );
    }

    _managedSubscriptions[key] = stream.listen(
      onData,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('ChatBloc: Stream error ($key): $error');
      },
    );
  }

  Future<void> _cancelRealtimeSubscriptions() async {
    await _cancelManagedSubscriptions(const [
      _ChatSubscriptionKey.typing,
      _ChatSubscriptionKey.presence,
      _ChatSubscriptionKey.media,
    ]);
  }

  Future<void> _cancelAllManagedSubscriptions() async {
    await _cancelManagedSubscriptions(
      _managedSubscriptions.keys.toList(growable: false),
    );
  }

  Future<void> _cancelManagedSubscriptions(
    Iterable<_ChatSubscriptionKey> keys,
  ) async {
    for (final key in keys) {
      await _cancelManagedSubscription(key);
    }
  }

  Future<void> _cancelManagedSubscription(_ChatSubscriptionKey key) async {
    final subscription = _managedSubscriptions.remove(key);
    if (subscription == null) return;
    try {
      await subscription.cancel();
    } catch (e) {
      AppLogger.error('ChatBloc: Error cancelling subscription ($key): $e');
    }
  }

  // =========================================================================
  // Cleanup
  // =========================================================================

  @override
  Future<void> close() async {
    if (_lifecycleObserverRegistered) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (e) {
        AppLogger.error('ChatBloc: Error removing lifecycle observer: $e');
      }
      _lifecycleObserverRegistered = false;
    }

    await _cancelAllManagedSubscriptions();

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
