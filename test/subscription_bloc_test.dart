import 'dart:async';

import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'mock/firebase_mock.dart';
import 'mock/noop_auth_repository.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  setupFirebaseAnalyticsMocks();
  late StubAnalyticsService analytics;

  setUpAll(() {
    analytics = StubAnalyticsService();
    AnalyticsService.setInstance(analytics);
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  setUp(() {
    analytics.loggedEvents.clear();
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

        bloc.add(
          SubscriptionCheckoutRequested(
            SubscriptionTier.plus,
            BillingPeriod.monthly,
          ),
        );

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
                .having((s) => s.errorMessage, 'error', isNull)
                .having(
                  (s) => s.transactionStatus,
                  'transactionStatus',
                  SubscriptionTransactionStatus.pending,
                ),
          ]),
        );

        expect(analytics.loggedEvents, contains('logCheckoutStarted:plus'));

        await bloc.close();
      });

      test('handles checkout failure', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(
            shouldFailCheckout: true,
          ),
        );

        bloc.add(
          SubscriptionCheckoutRequested(
            SubscriptionTier.plus,
            BillingPeriod.monthly,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.isCheckoutInProgress, 'progress', false)
                .having((s) => s.errorMessage, 'error', isNotNull)
                .having(
                  (s) => s.transactionStatus,
                  'transactionStatus',
                  SubscriptionTransactionStatus.failed,
                ),
          ),
        );

        expect(
          analytics.loggedEvents,
          contains(
            'logSubscriptionPurchaseFailed:plus:${ErrorMessages.checkoutFailed}:plus_monthly',
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

        bloc.add(
          SubscriptionCheckoutRequested(
            SubscriptionTier.plus,
            BillingPeriod.monthly,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.isCheckoutInProgress, 'progress', false)
                .having((s) => s.errorMessage, 'error', isNotNull)
                .having(
                  (s) => s.transactionStatus,
                  'transactionStatus',
                  SubscriptionTransactionStatus.failed,
                ),
          ),
        );

        await bloc.close();
      });
    });

    group('SubscriptionPurchaseInitiated', () {
      test('accepts product ID checkout requests', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(SubscriptionPurchaseInitiated('plus_monthly'));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>().having(
              (s) => s.transactionStatus,
              'transactionStatus',
              SubscriptionTransactionStatus.pending,
            ),
          ),
        );

        expect(analytics.loggedEvents, contains('logCheckoutStarted:plus'));

        await bloc.close();
      });

      test('marks completed purchases only after a tier upgrade', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(SubscriptionPurchaseInitiated('plus_monthly'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(SubscriptionTierUpdated(SubscriptionTier.plus));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SubscriptionState>()
                .having((s) => s.tier, 'tier', SubscriptionTier.plus)
                .having(
                  (s) => s.transactionStatus,
                  'transactionStatus',
                  SubscriptionTransactionStatus.purchased,
                ),
          ),
        );

        expect(
          analytics.loggedEvents,
          contains(
            'logSubscriptionPurchaseCompleted:plus:9.99:USD:plus_monthly',
          ),
        );

        await bloc.close();
      });
    });

    group('SubscriptionProductsRequested', () {
      test('loads available products into state', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(
            availableProducts: const [
              SubscriptionProduct(
                productId: 'plus_monthly',
                tier: SubscriptionTier.plus,
                period: BillingPeriod.monthly,
                title: 'Crush+',
                description: 'Monthly premium access',
                priceLabel: '\$9.99',
                price: 9.99,
                currencyCode: 'USD',
                currencySymbol: '\$',
              ),
            ],
          ),
        );

        bloc.add(SubscriptionProductsRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SubscriptionState>().having(
              (s) => s.isLoadingProducts,
              'loading',
              true,
            ),
            isA<SubscriptionState>()
                .having((s) => s.isLoadingProducts, 'loading', false)
                .having((s) => s.availableProducts.length, 'count', 1)
                .having(
                  (s) => s.availableProducts.first.priceLabel,
                  'priceLabel',
                  '\$9.99',
                ),
          ]),
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
        bloc.add(
          SubscriptionCheckoutRequested(
            SubscriptionTier.plus,
            BillingPeriod.monthly,
          ),
        );
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
                .having((s) => s.statusLabel, 'status', 'active')
                .having(
                  (s) => s.transactionStatus,
                  'transactionStatus',
                  SubscriptionTransactionStatus.restored,
                ),
          ]),
        );

        expect(
          analytics.loggedEvents,
          contains('logSubscriptionRestored:plus:'),
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
                .having((s) => s.errorMessage, 'error', isNull)
                .having(
                  (s) => s.transactionStatus,
                  'transactionStatus',
                  SubscriptionTransactionStatus.noPurchases,
                ),
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
                )
                .having(
                  (s) => s.transactionStatus,
                  'transactionStatus',
                  SubscriptionTransactionStatus.failed,
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

      test('allows explicit transaction status updates', () async {
        final bloc = SubscriptionBloc(
          authRepository: NoopAuthRepository(),
          subscriptionRepository: _StubSubscriptionRepository(),
        );

        bloc.add(
          SubscriptionTransactionUpdated(
            SubscriptionTransactionStatus.failed,
            errorMessage: 'purchase failed',
          ),
        );

        await expectLater(
          bloc.stream,
          emits(
            isA<SubscriptionState>()
                .having(
                  (s) => s.transactionStatus,
                  'transactionStatus',
                  SubscriptionTransactionStatus.failed,
                )
                .having((s) => s.errorMessage, 'error', 'purchase failed'),
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
    this.availableProducts = const [],
  });

  final StreamController<SubscriptionTier>? tierStreamController;
  final bool shouldFailCheckout;
  final bool shouldFailLaunch;
  final bool shouldFailRestore;
  final SubscriptionStatus? statusToRestore;
  final List<SubscriptionProduct> availableProducts;

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
  Future<String> startCheckout({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {
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
  Future<void> purchaseSubscription({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {
    if (shouldFailCheckout) {
      throw Exception('Checkout failed');
    }
    if (shouldFailLaunch) {
      throw Exception('Failed to launch URL');
    }
  }

  @override
  Future<void> purchaseProduct({required String productId}) async {
    final selection = subscriptionSelectionForProductId(productId);
    if (selection == null) {
      throw UnsupportedError('Unknown subscription product: $productId');
    }
    await purchaseSubscription(tier: selection.tier, period: selection.period);
  }

  @override
  Future<SubscriptionStatus> refreshStatus() async {
    if (shouldFailRestore) {
      throw Exception('Failed to restore subscription');
    }
    return statusToRestore ?? SubscriptionStatus(tier: SubscriptionTier.free);
  }

  @override
  Future<SubscriptionStatus> restorePurchases() => refreshStatus();

  @override
  Future<SubscriptionStatus> verifyPurchaseReceipt({
    required String platform,
    required String receiptData,
    required String productId,
    String? packageName,
  }) => refreshStatus();

  @override
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async {
    return availableProducts;
  }

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      PromoCodeRedemptionResult.failure('Not implemented');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => [];
}
