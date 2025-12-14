import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/message.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../core/result.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final SubscriptionRepository subscriptionRepository;
  StreamSubscription<List<Message>>? _sub;

  ChatBloc({
    required this.chatRepository,
    required this.subscriptionRepository,
  }) : super(const ChatState()) {
    on<ChatOpened>(_onChatOpened);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMediaSendRequested>(_onMediaSendRequested);
    on<ChatMessageUnsendRequested>(_onUnsendRequested);
    on<ChatMessageDeleteForMeRequested>(_onDeleteForMeRequested);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onChatOpened(ChatOpened event, Emitter<ChatState> emit) async {
    emit(state.copyWith(errorMessage: null));
    _sub?.cancel();
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
      fallbackError: 'Could not send message. Please try again.',
    );
    emit(state.copyWith(
      sendStatus: SendStatus.idle,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onMediaSendRequested(
      ChatMediaSendRequested event, Emitter<ChatState> emit) async {
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
      fallbackError: 'Could not send media. Please try again.',
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
      fallbackError: 'Could not send media. Please try again.',
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
    return super.close();
  }
}
