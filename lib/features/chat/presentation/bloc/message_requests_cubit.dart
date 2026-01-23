import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/core/utils/result.dart';
import 'message_requests_state.dart';

class MessageRequestsCubit extends Cubit<MessageRequestsState> {
  final ChatRepository chatRepository;
  final String userId;

  MessageRequestsCubit({
    required this.chatRepository,
    required this.userId,
  }) : super(const MessageRequestsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await Result.guard(
      () => chatRepository.fetchMessageRequests(userId),
      logLabel: 'ChatRepository.fetchMessageRequests',
      fallbackError: 'Could not load message requests.',
    );
    if (result.isSuccess) {
      emit(state.copyWith(
        isLoading: false,
        requests: result.data ?? const [],
        errorMessage: null,
      ));
    } else {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
    }
  }

  Future<void> refresh() async {
    await load();
  }
}
