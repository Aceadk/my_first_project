import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/discovery_repository.dart';
import '../../data/repositories/subscription_repository.dart';
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
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final deck = await discoveryRepository.fetchDeck(event.userId);
      final plan = await subscriptionRepository.getCurrentPlan();
      _remainingFreeSwipesToday =
          plan.isFree ? CrushConstants.freeDailySwipeLimit : null;
      _retryDelayMs = 1000;
      emit(state.copyWith(
        isLoading: false,
        deck: deck,
        currentIndex: 0,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load people. Please try again.',
      ));
      _scheduleRetry();
    }
  }

  Future<void> _onSwipedRight(
      DiscoverySwipedRight event, Emitter<DiscoveryState> emit) async {
    if (state.deck.isEmpty) return;

    final currentIndex = state.currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, state.deck.length);

    try {
      final plan = await subscriptionRepository.getCurrentPlan();
      final remainingSwipes = plan.isFree
          ? (_remainingFreeSwipesToday ?? CrushConstants.freeDailySwipeLimit)
          : null;

      if (plan.isFree && remainingSwipes != null && remainingSwipes <= 0) {
        emit(state.copyWith(
          errorMessage: 'Daily swipe limit reached.',
        ));
        return;
      }

      emit(state.copyWith(currentIndex: nextIndex, errorMessage: null));

      await discoveryRepository.swipeRight(
        userId: event.userId,
        targetUserId: event.targetUserId,
        attachedMessage: event.attachedMessage,
      );

      if (plan.isFree && remainingSwipes != null) {
        _remainingFreeSwipesToday = remainingSwipes - 1;
      }
    } catch (e) {
      emit(state.copyWith(
        currentIndex: currentIndex,
        errorMessage: 'Could not like this profile. Please try again.',
      ));
    }
  }

  Future<void> _onSwipedLeft(
      DiscoverySwipedLeft event, Emitter<DiscoveryState> emit) async {
    if (state.deck.isEmpty) return;

    final currentIndex = state.currentIndex;
    final nextIndex = (currentIndex + 1).clamp(0, state.deck.length);

    emit(state.copyWith(currentIndex: nextIndex, errorMessage: null));

    try {
      await discoveryRepository.swipeLeft(
        userId: event.userId,
        targetUserId: event.targetUserId,
      );
    } catch (e) {
      emit(state.copyWith(
        currentIndex: currentIndex,
        errorMessage: 'Could not pass on this profile.',
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
