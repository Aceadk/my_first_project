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

  /// Page size for pagination.
  static const _pageSize = 20;

  DateTime? _lastFetchTime;

  MatchesBloc({
    required this.chatRepository,
    required this.userId,
  }) : super(const MatchesState()) {
    on<MatchesLoadRequested>(_onLoadRequested);
    on<MatchesRefreshRequested>(_onRefreshRequested);
    on<MatchesLoadMoreRequested>(_onLoadMoreRequested);
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

    await _fetchMatches(emit, refresh: false);
  }

  Future<void> _onRefreshRequested(
    MatchesRefreshRequested event,
    Emitter<MatchesState> emit,
  ) async {
    // Force refresh - invalidate cache
    _lastFetchTime = null;
    await _fetchMatches(emit, refresh: true);
  }

  Future<void> _onLoadMoreRequested(
    MatchesLoadMoreRequested event,
    Emitter<MatchesState> emit,
  ) async {
    // Don't load more if already loading or no more data
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final result = await Result.guard(
      () => chatRepository.fetchUserMatchesPaginated(
        userId,
        offset: state.matches.length,
        limit: _pageSize,
      ),
      logLabel: 'ChatRepository.fetchUserMatchesPaginated',
      fallbackError: 'Could not load more matches.',
    );

    if (result.isSuccess && result.data != null) {
      final paginated = result.data!;
      emit(state.copyWith(
        matches: [...state.matches, ...paginated.items],
        isLoadingMore: false,
        hasMore: paginated.hasMore,
        total: paginated.total,
        errorMessage: null,
      ));
    } else {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: result.errorMessage,
      ));
    }
  }

  Future<void> _fetchMatches(Emitter<MatchesState> emit, {required bool refresh}) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
      // Reset pagination on refresh
      hasMore: true,
    ));

    final result = await Result.guard(
      () => chatRepository.fetchUserMatchesPaginated(userId, limit: _pageSize),
      logLabel: 'ChatRepository.fetchUserMatchesPaginated',
      fallbackError: 'Could not load matches.',
    );

    if (result.isSuccess && result.data != null) {
      _lastFetchTime = DateTime.now();
      final paginated = result.data!;
      emit(state.copyWith(
        matches: paginated.items,
        isLoading: false,
        hasMore: paginated.hasMore,
        total: paginated.total,
        errorMessage: null,
      ));
    } else {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
    }
  }

  /// Invalidates the cache, forcing a refresh on next load.
  void invalidateCache() {
    _lastFetchTime = null;
  }
}
