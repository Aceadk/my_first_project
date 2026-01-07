import 'package:flutter_bloc/flutter_bloc.dart';
import 'matches_event.dart';
import 'matches_state.dart';
import '../../data/repositories/chat_repository.dart';
import '../../core/result.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final ChatRepository chatRepository;
  final String userId;

  /// Cache duration - matches are refreshed after this period.
  static const _cacheDuration = Duration(minutes: 5);

  DateTime? _lastFetchTime;

  MatchesBloc({
    required this.chatRepository,
    required this.userId,
  }) : super(const MatchesState()) {
    on<MatchesLoadRequested>(_onLoadRequested);
    on<MatchesRefreshRequested>(_onRefreshRequested);
  }

  /// Returns true if cache is valid and fresh.
  bool get _isCacheValid {
    if (_lastFetchTime == null || state.matches.isEmpty) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  Future<void> _onLoadRequested(
    MatchesLoadRequested event,
    Emitter<MatchesState> emit,
  ) async {
    // Use cached data if available and fresh
    if (_isCacheValid) {
      return;
    }

    await _fetchMatches(emit);
  }

  Future<void> _onRefreshRequested(
    MatchesRefreshRequested event,
    Emitter<MatchesState> emit,
  ) async {
    // Force refresh - invalidate cache
    _lastFetchTime = null;
    await _fetchMatches(emit);
  }

  Future<void> _fetchMatches(Emitter<MatchesState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await Result.guard(
      () => chatRepository.fetchUserMatches(userId),
      logLabel: 'ChatRepository.fetchUserMatches',
      fallbackError: 'Could not load matches.',
    );

    if (result.isSuccess) {
      _lastFetchTime = DateTime.now();
    }

    emit(state.copyWith(
      matches: result.data ?? state.matches,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }

  /// Invalidates the cache, forcing a refresh on next load.
  void invalidateCache() {
    _lastFetchTime = null;
  }
}
