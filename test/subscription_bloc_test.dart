import 'dart:async';

import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'mock/firebase_mock.dart';
import 'mock/noop_auth_repository.dart';
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
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        expect(bloc.state.tier, SubscriptionTier.free);
        expect(bloc.state.isCheckoutInProgress, false);
        expect(bloc.state.errorMessage, isNull);
        expect(bloc.state.isRestoring, false);

        bloc.close();
      });
    });

    group('SubscriptionWatchStarted', () {
      test('starts watching plan updates', () async {
        final planController = StreamController<SubscriptionTier>.broadcast();
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(
            tierStreamController: planController,
          ),
        );

        bloc.add(SubscriptionWatchStarted());
        await Future.delayed(const Duration(milliseconds: 50));

        // Emit a plan update
        planController.add(SubscriptionTier.plus);

        await expectLater(
          bloc.stream,
          emits(
            isA<SubscriptionState>().having(
              (s) => s.tier,
              'plan',
              SubscriptionTier.plus,
            ),
          ),
        );

        await planController.close();
        await bloc.close();
      });
    });

    group('PlusCheckoutRequested', () {
      test('starts checkout and launches URL', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(SubscriptionCheckoutRequested(SubscriptionTier.plus, BillingPeriod.monthly));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SubscriptionState>().having(
              (s) => s.isCheckoutInProgress,
              'progress',
              true,
            ),
            isA<SubscriptionState>()
                .having((s) => s.isCheckoutInProgress, 'progress', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ]),
        );

        await bloc.close();
      });

      test('handles checkout failure', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(
            shouldFailCheckout: true,
          ),
        );

        bloc.add(SubscriptionCheckoutRequested(SubscriptionTier.plus, BillingPeriod.monthly));

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
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(
            shouldFailLaunch: true,
          ),
        );

        bloc.add(SubscriptionCheckoutRequested(SubscriptionTier.plus, BillingPeriod.monthly));

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

    group('SubscriptionTierUpdated', () {
      test('updates plan in state', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(SubscriptionTierUpdated(SubscriptionTier.plus));

        await expectLater(
          bloc.stream,
          emits(
            isA<SubscriptionState>().having(
              (s) => s.tier,
              'plan',
              SubscriptionTier.plus,
            ),
          ),
        );

        await bloc.close();
      });

      test('clears checkout progress on plan update', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        // Start checkout first
        bloc.add(SubscriptionCheckoutRequested(SubscriptionTier.plus, BillingPeriod.monthly));
        await Future.delayed(const Duration(milliseconds: 50));

        // Plan update should clear checkout state
        bloc.add(SubscriptionTierUpdated(SubscriptionTier.plus));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.tier, 'plan', SubscriptionTier.plus)
                .having((s) => s.isCheckoutInProgress, 'progress', false),
          ),
        );

        await bloc.close();
      });
    });

    group('SubscriptionRestoreRequested', () {
      test('restores subscription status', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(
            statusToRestore: SubscriptionStatus(
              tier: SubscriptionTier.plus,
              status: 'active',
              nextRenewal: DateTime(2025, 12, 31),
            ),
          ),
        );

        bloc.add(SubscriptionRestoreRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SubscriptionState>().having(
              (s) => s.isRestoring,
              'restoring',
              true,
            ),
            isA<SubscriptionState>()
                .having((s) => s.isRestoring, 'restoring', false)
                .having((s) => s.tier, 'plan', SubscriptionTier.plus)
                .having((s) => s.statusLabel, 'status', 'active'),
          ]),
        );

        await bloc.close();
      });

      test('emits no-purchase restore state for free users', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(
            statusToRestore: SubscriptionStatus(
              tier: SubscriptionTier.free,
              status: 'none',
            ),
          ),
        );

        bloc.add(SubscriptionRestoreRequested());

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.isRestoring, 'restoring', false)
                .having((s) => s.tier, 'plan', SubscriptionTier.free)
                .having((s) => s.statusLabel, 'status', 'none')
                .having((s) => s.errorMessage, 'error', isNull),
          ),
        );

        await bloc.close();
      });

      test('handles restore failure', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
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
                .having(
                  (s) => s.errorMessage,
                  'error',
                  ErrorMessages.restorePurchasesFailed,
                ),
          ),
        );

        await bloc.close();
      });
    });

    group('SubscriptionStatusUpdated', () {
      test('updates full subscription status', () async {
        final nextRenewal = DateTime(2025, 12, 31);
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(
          SubscriptionStatusUpdated(
            SubscriptionStatus(
              tier: SubscriptionTier.plus,
              status: 'active',
              nextRenewal: nextRenewal,
              cancelAtPeriodEnd: false,
            ),
          ),
        );

        await expectLater(
          bloc.stream,
          emits(
            isA<SubscriptionState>()
                .having((s) => s.tier, 'plan', SubscriptionTier.plus)
                .having((s) => s.statusLabel, 'status', 'active')
                .having((s) => s.nextRenewal, 'renewal', nextRenewal)
                .having((s) => s.cancelAtPeriodEnd, 'cancel', false),
          ),
        );

        await bloc.close();
      });

      test('handles cancel at period end', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(
          SubscriptionStatusUpdated(
            SubscriptionStatus(
              tier: SubscriptionTier.plus,
              status: 'canceled',
              cancelAtPeriodEnd: true,
            ),
          ),
        );

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
        final planController = StreamController<SubscriptionTier>.broadcast();
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(
            tierStreamController: planController,
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
    this.tierStreamController,
    this.shouldFailCheckout = false,
    this.shouldFailLaunch = false,
    this.shouldFailRestore = false,
    this.statusToRestore,
  });

  final StreamController<SubscriptionTier>? tierStreamController;
  final bool shouldFailCheckout;
  final bool shouldFailLaunch;
  final bool shouldFailRestore;
  final SubscriptionStatus? statusToRestore;

  @override
  Stream<SubscriptionTier> watchPlan() {
    if (tierStreamController != null) {
      return tierStreamController!.stream;
    }
    return Stream.value(SubscriptionTier.free);
  }

  @override
  Future<SubscriptionTier> getCurrentPlan() async => SubscriptionTier.free;

  @override
  Future<String> startCheckout({required SubscriptionTier tier, required BillingPeriod period}) async {
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
  Future<void> purchaseSubscription({required SubscriptionTier tier, required BillingPeriod period}) async {
    if (shouldFailCheckout) {
      throw Exception('Checkout failed');
    }
    if (shouldFailLaunch) {
      throw Exception('Failed to launch URL');
    }
  }

  @override
  Future<SubscriptionStatus> refreshStatus() async {
    if (shouldFailRestore) {
      throw Exception('Failed to restore subscription');
    }
    return statusToRestore ?? SubscriptionStatus(tier: SubscriptionTier.free);
  }

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      PromoCodeRedemptionResult.failure('Not implemented');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => [];
}
