import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/discovery_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../core/result.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final DiscoveryRepository discoveryRepository;
  final SubscriptionRepository subscriptionRepository;
  int? _remainingFreeSwipesToday;
  Timer? _retryTimer;
  int _retryDelayMs = 1000;
  String? _lastRequestedUserId;

  DiscoveryBloc({
    required this.discoveryRepository,
    required this.subscriptionRepository,
  }) : super(const DiscoveryState()) {
    on<DiscoveryDeckRequested>(_onDeckRequested);
    on<DiscoverySwipedRight>(_onSwipedRight);
    on<DiscoverySwipedLeft>(_onSwipedLeft);
  }

  Future<void> _onDeckRequested(
      DiscoveryDeckRequested event, Emitter<DiscoveryState> emit) async {
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
      emit(state.copyWith(
        isLoading: false,
        status: DeckStatus.error,
        errorMessage:
            deckResult.errorMessage ?? planResult.errorMessage,
        nextRetrySeconds: (_retryDelayMs / 1000).ceil(),
      ));
      _scheduleRetry();
      return;
    }

    final deck = deckResult.data ?? const [];
    final plan = planResult.data ?? SubscriptionPlan.free;
    _remainingFreeSwipesToday =
        plan.isFree ? CrushConstants.freeDailySwipeLimit : null;
    _retryDelayMs = 1000;
    emit(state.copyWith(
      isLoading: false,
      deck: deck,
      currentIndex: 0,
      status: deck.isEmpty ? DeckStatus.empty : DeckStatus.ready,
      errorMessage: null,
      nextRetrySeconds: null,
    ));
  }

  Future<void> _onSwipedRight(
      DiscoverySwipedRight event, Emitter<DiscoveryState> emit) async {
    if (state.deck.isEmpty) return;

    final currentIndex = state.currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, state.deck.length);

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

    if (swipeResult.isSuccess &&
        plan.isFree &&
        remainingSwipes != null) {
      _remainingFreeSwipesToday = remainingSwipes - 1;
    } else if (!swipeResult.isSuccess) {
      emit(state.copyWith(
        currentIndex: currentIndex,
        status: DeckStatus.ready,
        errorMessage: swipeResult.errorMessage,
      ));
    }
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
    if (!result.isSuccess) {
      emit(state.copyWith(
        currentIndex: currentIndex,
        status: DeckStatus.ready,
        errorMessage: result.errorMessage,
      ));
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
