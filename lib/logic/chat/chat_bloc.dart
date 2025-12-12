import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/message.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/subscription_repository.dart';
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
    on<ChatMessageUnsendRequested>(_onUnsendRequested);
    on<ChatMessageDeleteForMeRequested>(_onDeleteForMeRequested);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onChatOpened(ChatOpened event, Emitter<ChatState> emit) async {
    emit(state.copyWith(errorMessage: null));
    _sub?.cancel();
    try {
      final plan = await subscriptionRepository.getCurrentPlan();
      _sub = chatRepository.watchMessages(event.matchId).listen((messages) {
        add(ChatMessagesUpdated(messages, plan));
      });
      emit(state.copyWith(canUnsend: plan.isPlus));
      await chatRepository.markMessagesRead(event.matchId, event.currentUserId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not load chat.'));
    }
  }

  Future<void> _onMessageSent(
      ChatMessageSent event, Emitter<ChatState> emit) async {
    final content = event.content.trim();
    if (content.isEmpty) return;

    emit(state.copyWith(isSending: true, errorMessage: null));
    try {
      await chatRepository.sendMessage(
        matchId: event.matchId,
        fromUserId: event.fromUserId,
        toUserId: event.toUserId,
        content: content,
        type: event.type,
      );
      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        errorMessage: 'Could not send message. Please try again.',
      ));
    }
  }

  Future<void> _onUnsendRequested(
      ChatMessageUnsendRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isUnsendInProgress: true, errorMessage: null));

    try {
      final plan = await subscriptionRepository.getCurrentPlan();
      if (!plan.isPlus) {
        emit(state.copyWith(
          isUnsendInProgress: false,
          errorMessage: 'Upgrade to Plus to unsend messages.',
        ));
        return;
      }

      await chatRepository.unsendMessage(
        matchId: event.matchId,
        messageId: event.messageId,
      );
      emit(state.copyWith(isUnsendInProgress: false));
    } catch (e) {
      emit(state.copyWith(
        isUnsendInProgress: false,
        errorMessage: 'Could not unsend message.',
      ));
    }
  }

  Future<void> _onDeleteForMeRequested(
      ChatMessageDeleteForMeRequested event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.deleteForMe(
        matchId: event.matchId,
        messageId: event.messageId,
        userId: event.userId,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not delete message.'));
    }
  }

  void _onMessagesUpdated(ChatMessagesUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      messages: event.messages,
      canUnsend: event.plan.isPlus,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
