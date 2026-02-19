import 'dart:async';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'mock/firebase_mock.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  group('SubscriptionBloc', () {
    group('Initial State', () {
      test('has free plan by default', () {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        expect(bloc.state.plan, SubscriptionPlan.free);
        expect(bloc.state.isCheckoutInProgress, false);
        expect(bloc.state.errorMessage, isNull);
        expect(bloc.state.isRestoring, false);

        bloc.close();
      });
    });

    group('SubscriptionWatchStarted', () {
      test('starts watching plan updates', () async {
        final planController = StreamController<SubscriptionPlan>.broadcast();
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(
            planStreamController: planController,
          ),
        );

        bloc.add(SubscriptionWatchStarted());
        await Future.delayed(const Duration(milliseconds: 50));

        // Emit a plan update
        planController.add(SubscriptionPlan.plus);

        await expectLater(
          bloc.stream,
          emits(
            isA<SubscriptionState>()
                .having((s) => s.plan, 'plan', SubscriptionPlan.plus),
          ),
        );

        await planController.close();
        await bloc.close();
      });
    });

    group('PlusCheckoutRequested', () {
      test('starts checkout and launches URL', () async {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(PlusCheckoutRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SubscriptionState>()
                .having((s) => s.isCheckoutInProgress, 'progress', true),
            isA<SubscriptionState>()
                .having((s) => s.isCheckoutInProgress, 'progress', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ]),
        );

        await bloc.close();
      });

      test('handles checkout failure', () async {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(
            shouldFailCheckout: true,
          ),
        );

        bloc.add(PlusCheckoutRequested());

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.isCheckoutInProgress, 'progress', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );

        await bloc.close();
      });

      test('handles launch URL failure', () async {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(
            shouldFailLaunch: true,
          ),
        );

        bloc.add(PlusCheckoutRequested());

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.isCheckoutInProgress, 'progress', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );

        await bloc.close();
      });
    });

    group('SubscriptionPlanUpdated', () {
      test('updates plan in state', () async {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(SubscriptionPlanUpdated(SubscriptionPlan.plus));

        await expectLater(
          bloc.stream,
          emits(
            isA<SubscriptionState>()
                .having((s) => s.plan, 'plan', SubscriptionPlan.plus),
          ),
        );

        await bloc.close();
      });

      test('clears checkout progress on plan update', () async {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        // Start checkout first
        bloc.add(PlusCheckoutRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        // Plan update should clear checkout state
        bloc.add(SubscriptionPlanUpdated(SubscriptionPlan.plus));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.plan, 'plan', SubscriptionPlan.plus)
                .having((s) => s.isCheckoutInProgress, 'progress', false),
          ),
        );

        await bloc.close();
      });
    });

    group('SubscriptionRestoreRequested', () {
      test('restores subscription status', () async {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(
            statusToRestore: SubscriptionStatus(
              plan: SubscriptionPlan.plus,
              status: 'active',
              nextRenewal: DateTime(2025, 12, 31),
            ),
          ),
        );

        bloc.add(SubscriptionRestoreRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SubscriptionState>()
                .having((s) => s.isRestoring, 'restoring', true),
            isA<SubscriptionState>()
                .having((s) => s.isRestoring, 'restoring', false)
                .having((s) => s.plan, 'plan', SubscriptionPlan.plus)
                .having((s) => s.statusLabel, 'status', 'active'),
          ]),
        );

        await bloc.close();
      });

      test('handles restore failure', () async {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(
            shouldFailRestore: true,
          ),
        );

        bloc.add(SubscriptionRestoreRequested());

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.isRestoring, 'restoring', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );

        await bloc.close();
      });
    });

    group('SubscriptionStatusUpdated', () {
      test('updates full subscription status', () async {
        final nextRenewal = DateTime(2025, 12, 31);
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(SubscriptionStatusUpdated(SubscriptionStatus(
          plan: SubscriptionPlan.plus,
          status: 'active',
          nextRenewal: nextRenewal,
          cancelAtPeriodEnd: false,
        )));

        await expectLater(
          bloc.stream,
          emits(
            isA<SubscriptionState>()
                .having((s) => s.plan, 'plan', SubscriptionPlan.plus)
                .having((s) => s.statusLabel, 'status', 'active')
                .having((s) => s.nextRenewal, 'renewal', nextRenewal)
                .having((s) => s.cancelAtPeriodEnd, 'cancel', false),
          ),
        );

        await bloc.close();
      });

      test('handles cancel at period end', () async {
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(SubscriptionStatusUpdated(SubscriptionStatus(
          plan: SubscriptionPlan.plus,
          status: 'canceled',
          cancelAtPeriodEnd: true,
        )));

        await expectLater(
          bloc.stream,
          emits(
            isA<SubscriptionState>()
                .having((s) => s.statusLabel, 'status', 'canceled')
                .having((s) => s.cancelAtPeriodEnd, 'cancel', true),
          ),
        );

        await bloc.close();
      });
    });

    group('Cleanup', () {
      test('cancels subscription on close', () async {
        final planController = StreamController<SubscriptionPlan>.broadcast();
        final bloc = SubscriptionBloc(
          subscriptionRepository: _StubSubscriptionRepository(
            planStreamController: planController,
          ),
        );

        bloc.add(SubscriptionWatchStarted());
        await Future.delayed(const Duration(milliseconds: 50));

        await bloc.close();

        // Stream should be canceled, adding to it shouldn't affect bloc
        expect(bloc.isClosed, true);
        await planController.close();
      });
    });
  });
}

// =============================================================================
// Stub Repository
// =============================================================================

class _StubSubscriptionRepository implements SubscriptionRepository {
  _StubSubscriptionRepository({
    this.planStreamController,
    this.shouldFailCheckout = false,
    this.shouldFailLaunch = false,
    this.shouldFailRestore = false,
    this.statusToRestore,
  });

  final StreamController<SubscriptionPlan>? planStreamController;
  final bool shouldFailCheckout;
  final bool shouldFailLaunch;
  final bool shouldFailRestore;
  final SubscriptionStatus? statusToRestore;

  @override
  Stream<SubscriptionPlan> watchPlan() {
    if (planStreamController != null) {
      return planStreamController!.stream;
    }
    return Stream.value(SubscriptionPlan.free);
  }

  @override
  Future<SubscriptionPlan> getCurrentPlan() async => SubscriptionPlan.free;

  @override
  Future<String> startPlusCheckout() async {
    if (shouldFailCheckout) {
      throw Exception('Checkout failed');
    }
    return 'https://checkout.stripe.com/test';
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    if (shouldFailLaunch) {
      throw Exception('Failed to launch URL');
    }
  }

  @override
  Future<void> purchasePlusPlan() async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async {
    if (shouldFailRestore) {
      throw Exception('Failed to restore subscription');
    }
    return statusToRestore ?? SubscriptionStatus(plan: SubscriptionPlan.free);
  }

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      PromoCodeRedemptionResult.failure('Not implemented');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => [];
}
