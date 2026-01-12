import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/message.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import 'package:crushhour/core/utils/result.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final SubscriptionRepository subscriptionRepository;
  StreamSubscription<List<Message>>? _sub;
  StreamSubscription<Set<String>>? _typingSub;
  StreamSubscription<bool>? _presenceSub;
  StreamSubscription<bool>? _mediaSub;

  ChatBloc({
    required this.chatRepository,
    required this.subscriptionRepository,
  }) : super(const ChatState()) {
    on<ChatOpened>(_onChatOpened);
    on<ChatClosed>(_onChatClosed);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMediaSendRequested>(_onMediaSendRequested);
    on<ChatMessageUnsendRequested>(_onUnsendRequested);
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
  }

  Future<void> _onChatOpened(ChatOpened event, Emitter<ChatState> emit) async {
    emit(state.copyWith(
      errorMessage: null,
      typingUserIds: const {},
      otherUserOnline: false,
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
    emit(state.copyWith(canUnsend: plan.isPlus, errorMessage: null));
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

    emit(state.copyWith(
      sendStatus: SendStatus.sendingText,
      errorMessage: null,
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
    emit(state.copyWith(
      sendStatus: SendStatus.idle,
      errorMessage: result.errorMessage,
    ));
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
    if (!result.isSuccess) {
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
    emit(state.copyWith(
      isUnmatching: false,
      isUnmatched: result.isSuccess ? true : state.isUnmatched,
      errorMessage: result.errorMessage,
    ));
  }

  void _onMessagesUpdated(ChatMessagesUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      messages: event.messages,
      canUnsend: event.plan.isPlus,
    ));
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

  @override
  Future<void> close() {
    _sub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _mediaSub?.cancel();
    return super.close();
  }
}
