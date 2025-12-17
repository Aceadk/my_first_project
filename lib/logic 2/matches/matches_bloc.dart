import 'package:flutter_bloc/flutter_bloc.dart';
import 'matches_event.dart';
import 'matches_state.dart';
import '../../data/repositories/chat_repository.dart';

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
    try {
      final matches = await chatRepository.fetchUserMatches(userId);
      emit(state.copyWith(
        matches: matches,
        isLoading: false,
        errorMessage: null,
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load matches.',
      ));
    }
  }
}
