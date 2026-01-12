import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final DiscoveryRepository discoveryRepository;
  final SubscriptionRepository subscriptionRepository;
  int? _remainingFreeSwipesToday;
  Timer? _retryTimer;
  int _retryDelayMs = 1000;
  int _retryCount = 0;
  static const int _maxAutoRetries = 2;
  String? _lastRequestedUserId;
  bool _isManualRefresh = false;

  DiscoveryBloc({
    required this.discoveryRepository,
    required this.subscriptionRepository,
  }) : super(const DiscoveryState()) {
    on<DiscoveryDeckRequested>(_onDeckRequested);
    on<DiscoverySwipedRight>(_onSwipedRight);
    on<DiscoverySwipedLeft>(_onSwipedLeft);
    on<DiscoveryLoadMoreRequested>(_onLoadMoreRequested);
    on<DiscoveryMatchCelebrationShown>(_onMatchCelebrationShown);
  }

  void _onMatchCelebrationShown(
    DiscoveryMatchCelebrationShown event,
    Emitter<DiscoveryState> emit,
  ) {
    emit(state.copyWith(newMatch: null));
  }

  Future<void> _onDeckRequested(
      DiscoveryDeckRequested event, Emitter<DiscoveryState> emit) async {
    // Track if this is a manual refresh (user-triggered) vs auto-retry
    final isManualRefresh = _lastRequestedUserId != event.userId ||
        _isManualRefresh ||
        state.status != DeckStatus.error;

    if (isManualRefresh) {
      _retryCount = 0;
      _retryDelayMs = 1000;
    }
    _isManualRefresh = false;

    _lastRequestedUserId = event.userId;
    _retryTimer?.cancel();
    emit(state.copyWith(
      isLoading: true,
      status: DeckStatus.loading,
      errorMessage: null,
      nextRetrySeconds: null,
    ));
    final deckResult = await Result.guard(
      () => discoveryRepository.fetchDeck(event.userId),
      logLabel: 'DiscoveryRepository.fetchDeck',
      fallbackError: 'Could not load people. Please try again.',
    );
    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not load people. Please try again.',
    );

    if (!deckResult.isSuccess || !planResult.isSuccess) {
      _retryCount++;
      final errorMsg = deckResult.errorMessage ?? planResult.errorMessage;

      // Check if error indicates "no people" rather than actual failure
      final isNoPeopleError = _isNoPeopleError(errorMsg);

      // If we've retried enough times or error indicates no people, show empty state
      if (_retryCount > _maxAutoRetries || isNoPeopleError) {
        emit(state.copyWith(
          isLoading: false,
          status: DeckStatus.empty,
          deck: const [],
          currentIndex: 0,
          errorMessage: null,
          nextRetrySeconds: null,
        ));
        AnalyticsService.instance.logDeckEmpty();
        return;
      }

      // Otherwise show error and schedule retry
      emit(state.copyWith(
        isLoading: false,
        status: DeckStatus.error,
        errorMessage: errorMsg,
        nextRetrySeconds: (_retryDelayMs / 1000).ceil(),
      ));
      _scheduleRetry();
      return;
    }

    // Success - reset retry state
    _retryCount = 0;
    _retryDelayMs = 1000;

    final deck = deckResult.data ?? const [];
    final plan = planResult.data ?? SubscriptionPlan.free;
    _remainingFreeSwipesToday =
        plan.isFree ? CrushConstants.freeDailySwipeLimit : null;

    // Track deck loaded or empty
    if (deck.isEmpty) {
      AnalyticsService.instance.logDeckEmpty();
    } else {
      AnalyticsService.instance.logDeckLoaded(cardCount: deck.length);
    }

    emit(state.copyWith(
      isLoading: false,
      deck: deck,
      currentIndex: 0,
      status: deck.isEmpty ? DeckStatus.empty : DeckStatus.ready,
      errorMessage: null,
      nextRetrySeconds: null,
    ));
  }

  /// Check if error message indicates no people available vs actual error.
  bool _isNoPeopleError(String? errorMsg) {
    if (errorMsg == null) return false;
    final lower = errorMsg.toLowerCase();
    return lower.contains('no people') ||
        lower.contains('no profiles') ||
        lower.contains('no candidates') ||
        lower.contains('no users') ||
        lower.contains('empty') ||
        lower.contains('not found') ||
        lower.contains('no results');
  }

  Future<void> _onSwipedRight(
      DiscoverySwipedRight event, Emitter<DiscoveryState> emit) async {
    if (state.deck.isEmpty) return;

    final currentIndex = state.currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, state.deck.length);

    // Get the profile being swiped on for match celebration
    final swipedProfile = currentIndex < state.deck.length
        ? state.deck[currentIndex]
        : null;

    final planResult = await Result.guard(
      () => subscriptionRepository.getCurrentPlan(),
      logLabel: 'SubscriptionRepository.getCurrentPlan',
      fallbackError: 'Could not like this profile. Please try again.',
    );
    if (!planResult.isSuccess) {
      emit(state.copyWith(
        currentIndex: currentIndex,
        status: DeckStatus.ready,
        errorMessage: planResult.errorMessage,
      ));
      return;
    }
    final plan = planResult.data ?? SubscriptionPlan.free;
    final remainingSwipes = plan.isFree
        ? (_remainingFreeSwipesToday ?? CrushConstants.freeDailySwipeLimit)
        : null;

    if (plan.isFree && remainingSwipes != null && remainingSwipes <= 0) {
      emit(state.copyWith(
        status: DeckStatus.ready,
        errorMessage: 'Daily swipe limit reached.',
      ));
      return;
    }

    emit(state.copyWith(
      currentIndex: nextIndex,
      status: DeckStatus.ready,
      errorMessage: planResult.errorMessage,
    ));

    final swipeResult = await Result.guard(
      () => discoveryRepository.swipeRight(
        userId: event.userId,
        targetUserId: event.targetUserId,
        attachedMessage: event.attachedMessage,
      ),
      logLabel: 'DiscoveryRepository.swipeRight',
      fallbackError: 'Could not like this profile. Please try again.',
    );

    if (swipeResult.isSuccess) {
      // Track swipe right
      AnalyticsService.instance.logSwipeRight(
        targetUserId: event.targetUserId,
        withMessage: event.attachedMessage != null,
      );

      // Track match if one was created and emit for celebration
      final match = swipeResult.data;
      if (match != null && swipedProfile != null) {
        AnalyticsService.instance.logMatch(matchId: match.id);
        // Emit the match result for celebration modal
        emit(state.copyWith(
          newMatch: MatchResult(
            matchId: match.id,
            matchedProfile: swipedProfile,
          ),
        ));
      }

      if (plan.isFree && remainingSwipes != null) {
        _remainingFreeSwipesToday = remainingSwipes - 1;
      }
    } else {
      emit(state.copyWith(
        currentIndex: currentIndex,
        status: DeckStatus.ready,
        errorMessage: swipeResult.errorMessage,
      ));
    }

    // Preload more profiles if running low
    _maybeLoadMore(event.userId);
  }

  Future<void> _onSwipedLeft(
      DiscoverySwipedLeft event, Emitter<DiscoveryState> emit) async {
    if (state.deck.isEmpty) return;

    final currentIndex = state.currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, state.deck.length);

    emit(state.copyWith(
      currentIndex: nextIndex,
      status: DeckStatus.ready,
      errorMessage: null,
    ));

    final result = await Result.guard(
      () => discoveryRepository.swipeLeft(
        userId: event.userId,
        targetUserId: event.targetUserId,
      ),
      logLabel: 'DiscoveryRepository.swipeLeft',
      fallbackError: 'Could not pass on this profile.',
    );

    if (result.isSuccess) {
      // Track swipe left
      AnalyticsService.instance.logSwipeLeft(targetUserId: event.targetUserId);
    }

    if (!result.isSuccess) {
      emit(state.copyWith(
        currentIndex: currentIndex,
        status: DeckStatus.ready,
        errorMessage: result.errorMessage,
      ));
    }

    // Preload more profiles if running low
    _maybeLoadMore(event.userId);
  }

  /// Load more profiles when approaching end of deck.
  Future<void> _onLoadMoreRequested(
      DiscoveryLoadMoreRequested event, Emitter<DiscoveryState> emit) async {
    // Don't load if already loading or no more profiles
    if (state.isLoadingMore || !state.hasMoreProfiles) return;

    emit(state.copyWith(isLoadingMore: true));

    final deckResult = await Result.guard(
      () => discoveryRepository.fetchDeck(event.userId),
      logLabel: 'DiscoveryRepository.fetchDeck (pagination)',
      fallbackError: 'Could not load more people.',
    );

    if (!deckResult.isSuccess) {
      emit(state.copyWith(isLoadingMore: false));
      return;
    }

    final newProfiles = deckResult.data ?? const [];

    // Filter out profiles already in the deck
    final existingIds = state.deck.map((p) => p.id).toSet();
    final uniqueNewProfiles = newProfiles
        .where((p) => !existingIds.contains(p.id))
        .toList();

    emit(state.copyWith(
      isLoadingMore: false,
      deck: [...state.deck, ...uniqueNewProfiles],
      hasMoreProfiles: uniqueNewProfiles.isNotEmpty,
    ));
  }

  /// Check if we should preload more and trigger loading if needed.
  void _maybeLoadMore(String userId) {
    if (state.shouldLoadMore) {
      add(DiscoveryLoadMoreRequested(userId));
    }
  }

  void _scheduleRetry() {
    final userId = _lastRequestedUserId;
    if (userId == null) return;
    _retryTimer?.cancel();
    final delay = Duration(milliseconds: _retryDelayMs);
    _retryDelayMs = (_retryDelayMs * 2).clamp(1000, 8000);
    _retryTimer = Timer(delay, () {
      if (!isClosed) add(DiscoveryDeckRequested(userId));
    });
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    return super.close();
  }
}
