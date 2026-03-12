import 'dart:async';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:flutter_test/flutter_test.dart';

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

  // ===========================================================================
  // SUBSCRIPTION PLAN ENUM + EXTENSIONS
  // ===========================================================================

  group('SubscriptionTier', () {
    test('free plan isFree returns true', () {
      expect(SubscriptionTier.free.isFree, isTrue);
    });

    test('free plan isPlus returns false', () {
      expect(SubscriptionTier.free.isPlus, isFalse);
    });

    test('plus plan isPlus returns true', () {
      expect(SubscriptionTier.plus.isPlus, isTrue);
    });

    test('plus plan isFree returns false', () {
      expect(SubscriptionTier.plus.isFree, isFalse);
    });

    test('enum includes free, plus, and platinum values', () {
      expect(SubscriptionTier.values.length, 3);
      expect(SubscriptionTier.values, contains(SubscriptionTier.free));
      expect(SubscriptionTier.values, contains(SubscriptionTier.plus));
      expect(SubscriptionTier.values, contains(SubscriptionTier.platinum));
    });
  });

  // ===========================================================================
  // SUBSCRIPTION STATUS MODEL
  // ===========================================================================

  group('SubscriptionStatus', () {
    test('creates with required plan only', () {
      final status = SubscriptionStatus(tier: SubscriptionTier.free);
      expect(status.tier, SubscriptionTier.free);
      expect(status.status, isNull);
      expect(status.nextRenewal, isNull);
      expect(status.cancelAtPeriodEnd, isFalse);
    });

    test('creates with all fields', () {
      final renewal = DateTime(2026, 12, 31);
      final status = SubscriptionStatus(
        tier: SubscriptionTier.plus,
        status: 'active',
        nextRenewal: renewal,
        cancelAtPeriodEnd: false,
      );

      expect(status.tier, SubscriptionTier.plus);
      expect(status.status, 'active');
      expect(status.nextRenewal, renewal);
      expect(status.cancelAtPeriodEnd, isFalse);
    });

    test('cancelAtPeriodEnd defaults to false', () {
      final status = SubscriptionStatus(tier: SubscriptionTier.plus);
      expect(status.cancelAtPeriodEnd, isFalse);
    });

    test('canceled status with cancelAtPeriodEnd', () {
      final status = SubscriptionStatus(
        tier: SubscriptionTier.plus,
        status: 'canceled',
        cancelAtPeriodEnd: true,
      );

      expect(status.status, 'canceled');
      expect(status.cancelAtPeriodEnd, isTrue);
    });
  });

  // ===========================================================================
  // SUBSCRIPTION STATE (Equatable + copyWith)
  // ===========================================================================

  group('SubscriptionState', () {
    test('default state has free plan', () {
      const state = SubscriptionState(tier: SubscriptionTier.free);
      expect(state.tier, SubscriptionTier.free);
      expect(state.purchaseInProgress, isFalse);
      expect(state.isCheckoutInProgress, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isRestoring, isFalse);
      expect(state.statusLabel, isNull);
      expect(state.nextRenewal, isNull);
      expect(state.cancelAtPeriodEnd, isNull);
      expect(state.availableProducts, isEmpty);
      expect(state.isLoadingProducts, isFalse);
      expect(state.productsErrorMessage, isNull);
      expect(state.transactionStatus, SubscriptionTransactionStatus.idle);
    });

    test('copyWith changes plan only', () {
      const state = SubscriptionState(tier: SubscriptionTier.free);
      final updated = state.copyWith(tier: SubscriptionTier.plus);

      expect(updated.tier, SubscriptionTier.plus);
      expect(updated.isCheckoutInProgress, isFalse);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith preserves existing values when not specified', () {
      const state = SubscriptionState(
        tier: SubscriptionTier.plus,
        statusLabel: 'active',
        purchaseInProgress: true,
      );
      final updated = state.copyWith(isCheckoutInProgress: false);

      expect(updated.tier, SubscriptionTier.plus);
      expect(updated.statusLabel, 'active');
      expect(updated.isCheckoutInProgress, isFalse);
    });

    test('copyWith can set errorMessage to null', () {
      const state = SubscriptionState(
        tier: SubscriptionTier.free,
        errorMessage: 'some error',
      );
      final updated = state.copyWith(errorMessage: null);

      expect(updated.errorMessage, isNull);
    });

    test('copyWith can set nextRenewal to null', () {
      final state = SubscriptionState(
        tier: SubscriptionTier.plus,
        nextRenewal: DateTime(2026, 12, 31),
      );
      final updated = state.copyWith(nextRenewal: null);

      expect(updated.nextRenewal, isNull);
    });

    test('equatable comparison works for same values', () {
      const state1 = SubscriptionState(tier: SubscriptionTier.free);
      const state2 = SubscriptionState(tier: SubscriptionTier.free);

      expect(state1, equals(state2));
    });

    test('equatable comparison detects different tiers', () {
      const state1 = SubscriptionState(tier: SubscriptionTier.free);
      const state2 = SubscriptionState(tier: SubscriptionTier.plus);

      expect(state1, isNot(equals(state2)));
    });

    test('copyWith updates available products and loading state', () {
      const product = SubscriptionProduct(
        productId: 'plus_monthly',
        tier: SubscriptionTier.plus,
        period: BillingPeriod.monthly,
        title: 'Crush+',
        description: 'Monthly premium access',
        priceLabel: '\$9.99',
        price: 9.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      );
      const state = SubscriptionState(tier: SubscriptionTier.free);
      final updated = state.copyWith(
        availableProducts: const [product],
        isLoadingProducts: true,
        productsErrorMessage: 'load failed',
        transactionStatus: SubscriptionTransactionStatus.pending,
      );

      expect(updated.availableProducts, const [product]);
      expect(updated.isLoadingProducts, isTrue);
      expect(updated.productsErrorMessage, 'load failed');
      expect(updated.transactionStatus, SubscriptionTransactionStatus.pending);
    });
  });

  // ===========================================================================
  // FEATURE GATING — Constants-based tier limits
  // ===========================================================================

  group('Feature Gating (CrushConstants)', () {
    test('free daily swipe limit is 30', () {
      expect(CrushConstants.freeDailySwipeLimit, 30);
    });

    test('free users get 1 super like per day', () {
      expect(CrushConstants.freeDailySuperLikes, 1);
    });

    test('plus users get 7 super likes per day', () {
      expect(CrushConstants.premiumDailySuperLikes, 7);
    });

    test('plus users get more super likes than free users', () {
      expect(
        CrushConstants.premiumDailySuperLikes,
        greaterThan(CrushConstants.freeDailySuperLikes),
      );
    });

    test('free boost is 30 minutes', () {
      expect(CrushConstants.freeBoostDurationMinutes, 30);
    });

    test('plus boost is 60 minutes', () {
      expect(CrushConstants.premiumBoostDurationMinutes, 60);
    });

    test('plus boost lasts longer than free boost', () {
      expect(
        CrushConstants.premiumBoostDurationMinutes,
        greaterThan(CrushConstants.freeBoostDurationMinutes),
      );
    });

    test('free boost cooldown is 72 hours (3 days)', () {
      expect(CrushConstants.freeBoostCooldownHours, 72);
    });

    test('plus boost cooldown is 24 hours (1 day)', () {
      expect(CrushConstants.premiumBoostCooldownHours, 24);
    });

    test('plus boost cooldown is shorter than free cooldown', () {
      expect(
        CrushConstants.premiumBoostCooldownHours,
        lessThan(CrushConstants.freeBoostCooldownHours),
      );
    });

    test('default max distance is 220 km', () {
      expect(CrushConstants.defaultMaxDistanceKm, 220.0);
    });

    test('extended max distance is 500 km', () {
      expect(CrushConstants.extendedMaxDistanceKm, 500.0);
    });

    test('passport mode has infinite distance', () {
      expect(CrushConstants.globalDistanceKm, double.infinity);
    });

    test('minimum age is 18', () {
      expect(CrushConstants.minAge, 18);
    });
  });

  // ===========================================================================
  // CRUSHUSER — Premium state properties
  // ===========================================================================

  group('CrushUser Premium State', () {
    test('free user has free plan', () {
      const user = CrushUser(
        id: 'u1',
        phoneNumber: '+1',
        isEmailVerified: false,
        isPhoneVerified: true,
        isIdVerified: false,
        tier: SubscriptionTier.free,
      );
      expect(user.tier.isFree, isTrue);
      expect(user.tier.isPlus, isFalse);
    });

    test('plus user has plus plan', () {
      const user = CrushUser(
        id: 'u1',
        phoneNumber: '+1',
        isEmailVerified: true,
        isPhoneVerified: true,
        isIdVerified: true,
        tier: SubscriptionTier.plus,
      );
      expect(user.tier.isPlus, isTrue);
      expect(user.tier.isFree, isFalse);
    });

    test('copyWith can upgrade from free to plus', () {
      const freeUser = CrushUser(
        id: 'u1',
        phoneNumber: '+1',
        isEmailVerified: true,
        isPhoneVerified: true,
        isIdVerified: false,
        tier: SubscriptionTier.free,
      );

      final plusUser = freeUser.copyWith(tier: SubscriptionTier.plus);
      expect(plusUser.tier.isPlus, isTrue);
      expect(plusUser.id, 'u1');
      expect(plusUser.phoneNumber, '+1');
    });

    test('copyWith can downgrade from plus to free', () {
      const plusUser = CrushUser(
        id: 'u1',
        phoneNumber: '+1',
        isEmailVerified: true,
        isPhoneVerified: true,
        isIdVerified: true,
        tier: SubscriptionTier.plus,
      );

      final freeUser = plusUser.copyWith(tier: SubscriptionTier.free);
      expect(freeUser.tier.isFree, isTrue);
    });
  });

  // ===========================================================================
  // BLOC — Premium state transitions (additional to existing subscription_bloc_test)
  // ===========================================================================

  group('SubscriptionBloc Premium Transitions', () {
    test('upgrade from free to plus emits correct state', () async {
      final bloc = SubscriptionBloc(
        authRepository: NoopAuthRepository(),
        subscriptionRepository: _StubSubscriptionRepository(),
      );

      expect(bloc.state.tier, SubscriptionTier.free);

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

    test('downgrade from plus to free emits correct state', () async {
      final planController = StreamController<SubscriptionTier>.broadcast();
      final bloc = SubscriptionBloc(
        authRepository: NoopAuthRepository(),
        subscriptionRepository: _StubSubscriptionRepository(
          tierStreamController: planController,
        ),
      );

      // Upgrade first
      bloc.add(SubscriptionTierUpdated(SubscriptionTier.plus));
      await Future.delayed(const Duration(milliseconds: 50));

      // Then downgrade
      bloc.add(SubscriptionTierUpdated(SubscriptionTier.free));

      await expectLater(
        bloc.stream,
        emits(
          isA<SubscriptionState>().having(
            (s) => s.tier,
            'plan',
            SubscriptionTier.free,
          ),
        ),
      );

      await planController.close();
      await bloc.close();
    });

    test('full subscription status update sets all fields', () async {
      final renewal = DateTime(2026, 6, 15);
      final bloc = SubscriptionBloc(
        authRepository: NoopAuthRepository(),
        subscriptionRepository: _StubSubscriptionRepository(),
      );

      bloc.add(
        SubscriptionStatusUpdated(
          SubscriptionStatus(
            tier: SubscriptionTier.plus,
            status: 'active',
            nextRenewal: renewal,
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
              .having((s) => s.nextRenewal, 'renewal', renewal)
              .having((s) => s.cancelAtPeriodEnd, 'cancel', false)
              .having((s) => s.isRestoring, 'restoring', false),
        ),
      );

      await bloc.close();
    });

    test('expired subscription transitions back to free', () async {
      final bloc = SubscriptionBloc(
        authRepository: NoopAuthRepository(),
        subscriptionRepository: _StubSubscriptionRepository(),
      );

      // First upgrade
      bloc.add(
        SubscriptionStatusUpdated(
          SubscriptionStatus(tier: SubscriptionTier.plus, status: 'active'),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Then expire
      bloc.add(
        SubscriptionStatusUpdated(
          SubscriptionStatus(tier: SubscriptionTier.free, status: 'expired'),
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          isA<SubscriptionState>()
              .having((s) => s.tier, 'plan', SubscriptionTier.free)
              .having((s) => s.statusLabel, 'status', 'expired'),
        ),
      );

      await bloc.close();
    });

    test('plan watch stream delivers updates to bloc', () async {
      final planController = StreamController<SubscriptionTier>.broadcast();
      final bloc = SubscriptionBloc(
        authRepository: NoopAuthRepository(),
        subscriptionRepository: _StubSubscriptionRepository(
          tierStreamController: planController,
        ),
      );

      bloc.add(SubscriptionWatchStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      // Simulate server-side plan change
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

      // Simulate cancellation
      planController.add(SubscriptionTier.free);

      await expectLater(
        bloc.stream,
        emits(
          isA<SubscriptionState>().having(
            (s) => s.tier,
            'plan',
            SubscriptionTier.free,
          ),
        ),
      );

      await planController.close();
      await bloc.close();
    });

    test('checkout failure does not change plan', () async {
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
              .having((s) => s.tier, 'plan', SubscriptionTier.free)
              .having((s) => s.isCheckoutInProgress, 'progress', false)
              .having((s) => s.errorMessage, 'error', isNotNull),
        ),
      );

      await bloc.close();
    });

    test('restore failure does not change plan', () async {
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
              .having((s) => s.tier, 'plan', SubscriptionTier.free)
              .having((s) => s.isRestoring, 'restoring', false)
              .having((s) => s.errorMessage, 'error', isNotNull),
        ),
      );

      await bloc.close();
    });

    test('successful restore updates plan to restored status', () async {
      final bloc = SubscriptionBloc(
        authRepository: NoopAuthRepository(),
        subscriptionRepository: _StubSubscriptionRepository(
          statusToRestore: SubscriptionStatus(
            tier: SubscriptionTier.plus,
            status: 'active',
            nextRenewal: DateTime(2026, 12, 31),
          ),
        ),
      );

      bloc.add(SubscriptionRestoreRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<SubscriptionState>()
              .having((s) => s.tier, 'plan', SubscriptionTier.plus)
              .having((s) => s.statusLabel, 'status', 'active')
              .having((s) => s.isRestoring, 'restoring', false),
        ),
      );

      await bloc.close();
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
    this.shouldFailRestore = false,
    this.statusToRestore,
  });

  final StreamController<SubscriptionTier>? tierStreamController;
  final bool shouldFailCheckout;
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
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<void> purchaseSubscription({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {
    if (shouldFailCheckout) {
      throw Exception('Checkout failed');
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
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async => const [];

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      PromoCodeRedemptionResult.failure('Not implemented');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => [];
}
