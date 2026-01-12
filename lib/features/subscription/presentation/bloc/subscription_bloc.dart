import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository subscriptionRepository;
  StreamSubscription<SubscriptionPlan>? _sub;

  SubscriptionBloc({required this.subscriptionRepository})
      : super(const SubscriptionState(plan: SubscriptionPlan.free)) {
    on<SubscriptionWatchStarted>(_onWatchStarted);
    on<PlusCheckoutRequested>(_onPlusCheckoutRequested);
    on<SubscriptionPlanUpdated>(_onPlanUpdated);
    on<SubscriptionRestoreRequested>(_onRestoreRequested);
    on<SubscriptionStatusUpdated>(_onStatusUpdated);
  }

  Future<void> _onWatchStarted(
      SubscriptionWatchStarted event, Emitter<SubscriptionState> emit) async {
    _sub?.cancel();
    _sub = subscriptionRepository.watchPlan().listen((plan) {
      add(SubscriptionPlanUpdated(plan));
    });
  }

  Future<void> _onPlusCheckoutRequested(
      PlusCheckoutRequested event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(
      isCheckoutInProgress: true,
      errorMessage: null,
    ));

    // Track checkout started
    AnalyticsService.instance.logCheckoutStarted(plan: 'plus');

    final startResult = await Result.guard(
      () => subscriptionRepository.startPlusCheckout(),
      logLabel: 'SubscriptionRepository.startPlusCheckout',
      fallbackError: 'Could not start checkout. Please try again.',
    );
    final url = startResult.data;
    if (!startResult.isSuccess || url == null) {
      emit(state.copyWith(
        isCheckoutInProgress: false,
        errorMessage: startResult.errorMessage,
      ));
      return;
    }

    final launchResult = await Result.guard(
      () => subscriptionRepository.launchCheckoutUrl(url),
      logLabel: 'SubscriptionRepository.launchCheckoutUrl',
      fallbackError: 'Could not start checkout. Please try again.',
    );
    emit(state.copyWith(
      isCheckoutInProgress: false,
      errorMessage: launchResult.errorMessage,
    ));
  }

  void _onPlanUpdated(
      SubscriptionPlanUpdated event, Emitter<SubscriptionState> emit) {
    // Track subscription purchase if plan upgraded to plus
    if (state.plan == SubscriptionPlan.free && event.plan == SubscriptionPlan.plus) {
      AnalyticsService.instance.logSubscriptionPurchased(
        plan: 'plus',
        price: 9.99, // Configure based on your pricing
        currency: 'USD',
      );
    }

    emit(state.copyWith(
      plan: event.plan,
      isCheckoutInProgress: false,
      errorMessage: null,
      isRestoring: false,
    ));
  }

  Future<void> _onRestoreRequested(
      SubscriptionRestoreRequested event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(isRestoring: true, errorMessage: null));
    final result = await Result.guard(
      () => subscriptionRepository.refreshStatus(),
      logLabel: 'SubscriptionRepository.refreshStatus',
      fallbackError: 'Could not refresh subscription. Please try again.',
    );
    if (!result.isSuccess || result.data == null) {
      emit(state.copyWith(
        isRestoring: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }
    add(SubscriptionStatusUpdated(result.data!));
  }

  void _onStatusUpdated(
      SubscriptionStatusUpdated event, Emitter<SubscriptionState> emit) {
    emit(state.copyWith(
      plan: event.status.plan,
      isRestoring: false,
      errorMessage: null,
      statusLabel: event.status.status,
      nextRenewal: event.status.nextRenewal,
      cancelAtPeriodEnd: event.status.cancelAtPeriodEnd,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
