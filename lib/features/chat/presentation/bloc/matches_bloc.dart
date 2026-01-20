import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'matches_event.dart';
import 'matches_state.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/core/utils/result.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final ChatRepository chatRepository;
  final AuthRepository authRepository;
  final String userId;

  /// Cache duration - matches are refreshed after this period.
  static const _cacheDuration = Duration(minutes: 5);

  /// Page size for pagination.
  static const _pageSize = 20;

  /// Max auto-retries before showing empty state.
  static const int _maxAutoRetries = 2;

  StreamSubscription? _authSubscription;
  DateTime? _lastFetchTime;
  Timer? _retryTimer;
  int _retryDelayMs = 1000;
  int _retryCount = 0;
  bool _isManualRefresh = false;

  MatchesBloc({
    required this.chatRepository,
    required this.authRepository,
    required this.userId,
  }) : super(const MatchesState()) {
    on<MatchesLoadRequested>(_onLoadRequested);
    on<MatchesRefreshRequested>(_onRefreshRequested);
    on<MatchesLoadMoreRequested>(_onLoadMoreRequested);
    on<MatchesResetRequested>(_onResetRequested);

    // Listen to auth state changes to reset on logout
    _authSubscription = authRepository.authStateChanges().listen((user) {
      if (user == null) {
        // CRITICAL: Reset state on logout to prevent data leakage to next user
        add(const MatchesResetRequested());
      }
    });
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
    // Force refresh - invalidate cache and reset retry state
    _lastFetchTime = null;
    _isManualRefresh = true;
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
    // Track if this is a manual refresh vs auto-retry
    final isManualRefresh = _isManualRefresh || state.status != MatchesStatus.error;

    if (isManualRefresh) {
      _retryCount = 0;
      _retryDelayMs = 1000;
    }
    _isManualRefresh = false;
    _retryTimer?.cancel();

    emit(state.copyWith(
      isLoading: true,
      status: MatchesStatus.loading,
      errorMessage: null,
      nextRetrySeconds: null,
      // Reset pagination on refresh
      hasMore: true,
    ));

    final result = await Result.guard(
      () => chatRepository.fetchUserMatchesPaginated(userId, limit: _pageSize),
      logLabel: 'ChatRepository.fetchUserMatchesPaginated',
      fallbackError: 'Could not load matches.',
    );

    if (result.isSuccess && result.data != null) {
      // Success - reset retry state
      _retryCount = 0;
      _retryDelayMs = 1000;
      _lastFetchTime = DateTime.now();

      final paginated = result.data!;
      final hasMatches = paginated.items.isNotEmpty;

      emit(state.copyWith(
        matches: paginated.items,
        isLoading: false,
        status: hasMatches ? MatchesStatus.loaded : MatchesStatus.empty,
        hasMore: paginated.hasMore,
        total: paginated.total,
        errorMessage: null,
        nextRetrySeconds: null,
      ));
    } else {
      _retryCount++;
      final errorMsg = result.errorMessage;

      // Check if error indicates "no matches" rather than actual failure
      final isNoMatchesError = _isNoMatchesError(errorMsg);

      // If we've retried enough times or error indicates no matches, show empty state
      if (_retryCount > _maxAutoRetries || isNoMatchesError) {
        emit(state.copyWith(
          isLoading: false,
          status: MatchesStatus.empty,
          matches: const [],
          errorMessage: null,
          nextRetrySeconds: null,
        ));
        return;
      }

      // Otherwise show error and schedule retry
      emit(state.copyWith(
        isLoading: false,
        status: MatchesStatus.error,
        errorMessage: errorMsg,
        nextRetrySeconds: (_retryDelayMs / 1000).ceil(),
      ));
      _scheduleRetry();
    }
  }

  /// Check if error message indicates no matches available vs actual error.
  bool _isNoMatchesError(String? errorMsg) {
    if (errorMsg == null) return false;
    final lower = errorMsg.toLowerCase();
    return lower.contains('no matches') ||
        lower.contains('no results') ||
        lower.contains('not found') ||
        lower.contains('empty');
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delay = Duration(milliseconds: _retryDelayMs);
    _retryDelayMs = (_retryDelayMs * 2).clamp(1000, 8000);
    _retryTimer = Timer(delay, () {
      if (!isClosed) add(const MatchesLoadRequested());
    });
  }

  /// Invalidates the cache, forcing a refresh on next load.
  void invalidateCache() {
    _lastFetchTime = null;
  }

  /// Reset matches state on logout.
  /// CRITICAL: Prevents data leakage to next user.
  void _onResetRequested(
    MatchesResetRequested event,
    Emitter<MatchesState> emit,
  ) {
    debugPrint('MatchesBloc: Resetting matches state on logout');
    _retryTimer?.cancel();
    _retryCount = 0;
    _retryDelayMs = 1000;
    _lastFetchTime = null;
    _isManualRefresh = false;
    emit(const MatchesState()); // Reset to initial empty state
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
