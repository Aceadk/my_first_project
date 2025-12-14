import 'package:flutter_bloc/flutter_bloc.dart';
import 'matches_event.dart';
import 'matches_state.dart';
import '../../data/repositories/chat_repository.dart';
import '../../core/result.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final ChatRepository chatRepository;
  final String userId;

  MatchesBloc({
    required this.chatRepository,
    required this.userId,
  }) : super(const MatchesState()) {
    on<MatchesLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    MatchesLoadRequested event,
    Emitter<MatchesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await Result.guard(
      () => chatRepository.fetchUserMatches(userId),
      logLabel: 'ChatRepository.fetchUserMatches',
      fallbackError: 'Could not load matches.',
    );
    emit(state.copyWith(
      matches: result.data ?? state.matches,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }
}
