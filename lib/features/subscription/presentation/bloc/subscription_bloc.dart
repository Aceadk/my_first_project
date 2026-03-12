import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository subscriptionRepository;
  StreamSubscription<SubscriptionTier>? _sub;
  StreamSubscription? _authSubscription;

  SubscriptionBloc({
    required this.subscriptionRepository,
    required AuthRepository authRepository,
  }) : super(const SubscriptionState(tier: SubscriptionTier.free)) {
    on<SubscriptionWatchStarted>(_onWatchStarted);
    on<SubscriptionCheckoutRequested>(_onSubscriptionCheckoutRequested);
    on<SubscriptionTierUpdated>(_onPlanUpdated);
    on<SubscriptionRestoreRequested>(_onRestoreRequested);
    on<SubscriptionStatusUpdated>(_onStatusUpdated);
    on<SubscriptionResetRequested>(_onResetRequested);

    // Reset subscription state on logout to prevent data leakage
    _authSubscription = authRepository.authStateChanges().listen((user) {
      if (user == null) add(SubscriptionResetRequested());
    });
  }

  Future<void> _onWatchStarted(
    SubscriptionWatchStarted event,
    Emitter<SubscriptionState> emit,
  ) async {
    _sub?.cancel();
    _sub = subscriptionRepository.watchPlan().listen((plan) {
      add(SubscriptionTierUpdated(plan));
    });
  }

  Future<void> _onSubscriptionCheckoutRequested(
    SubscriptionCheckoutRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(isCheckoutInProgress: true, errorMessage: null));

    // Track checkout started
    AnalyticsService.instance.logCheckoutStarted(tier: event.tier.name);

    final purchaseResult = await Result.guard(
      () => subscriptionRepository.purchaseSubscription(
        tier: event.tier,
        period: event.period,
      ),
      logLabel: 'SubscriptionRepository.purchaseSubscription',
      fallbackError: ErrorMessages.checkoutFailed,
    );

    if (!purchaseResult.isSuccess) {
      emit(
        state.copyWith(
          isCheckoutInProgress: false,
          errorMessage: purchaseResult.errorMessage,
        ),
      );
      return;
    }

    emit(state.copyWith(isCheckoutInProgress: false, errorMessage: null));
  }

  void _onPlanUpdated(
    SubscriptionTierUpdated event,
    Emitter<SubscriptionState> emit,
  ) {
    // Track subscription purchase if plan upgraded to plus
    // Track subscription purchase if plan upgraded
    if (state.tier == SubscriptionTier.free &&
        event.tier != SubscriptionTier.free) {
      AnalyticsService.instance.logSubscriptionPurchased(
        tier: event.tier.name,
        price: 0.0, // Placeholder, analytics should get real price or skip
        currency: 'USD',
      );
    }

    emit(
      state.copyWith(
        tier: event.tier,
        isCheckoutInProgress: false,
        errorMessage: null,
        isRestoring: false,
      ),
    );
  }

  Future<void> _onRestoreRequested(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(isRestoring: true, errorMessage: null));
    final result = await Result.guard(
      () => subscriptionRepository.refreshStatus(),
      logLabel: 'SubscriptionRepository.refreshStatus',
      fallbackError: ErrorMessages.restorePurchasesFailed,
    );
    if (!result.isSuccess || result.data == null) {
      emit(
        state.copyWith(isRestoring: false, errorMessage: result.errorMessage),
      );
      return;
    }
    add(SubscriptionStatusUpdated(result.data!));
  }

  void _onStatusUpdated(
    SubscriptionStatusUpdated event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(
      state.copyWith(
        tier: event.status.tier,
        isRestoring: false,
        errorMessage: null,
        statusLabel: event.status.status,
        nextRenewal: event.status.nextRenewal,
        cancelAtPeriodEnd: event.status.cancelAtPeriodEnd,
      ),
    );
  }

  void _onResetRequested(
    SubscriptionResetRequested event,
    Emitter<SubscriptionState> emit,
  ) {
    AppLogger.debug('SubscriptionBloc: Resetting state on logout');
    _sub?.cancel();
    _sub = null;
    emit(const SubscriptionState(tier: SubscriptionTier.free));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
