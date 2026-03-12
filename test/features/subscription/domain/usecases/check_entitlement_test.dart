import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/domain/usecases/check_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CheckEntitlementUseCase', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('caches subscription plan within the configured TTL', () async {
      final prefs = await SharedPreferences.getInstance();
      final clock = _MutableClock(DateTime(2026, 3, 12, 10));
      final repository = _StubSubscriptionRepository(SubscriptionTier.free);
      final useCase = CheckEntitlementUseCase(
        repository,
        preferences: prefs,
        clock: clock.call,
        cacheTtl: const Duration(minutes: 5),
      );

      await useCase(
        const CheckEntitlementParams(
          feature: SubscriptionEntitlementFeature.rewind,
        ),
      );
      clock.value = clock.value.add(const Duration(minutes: 4));
      await useCase(
        const CheckEntitlementParams(
          feature: SubscriptionEntitlementFeature.rewind,
        ),
      );

      expect(repository.getCurrentPlanCalls, 1);
    });

    test('reloads the subscription plan after the TTL expires', () async {
      final prefs = await SharedPreferences.getInstance();
      final clock = _MutableClock(DateTime(2026, 3, 12, 10));
      final repository = _StubSubscriptionRepository(SubscriptionTier.free);
      final useCase = CheckEntitlementUseCase(
        repository,
        preferences: prefs,
        clock: clock.call,
        cacheTtl: const Duration(minutes: 5),
      );

      await useCase(
        const CheckEntitlementParams(
          feature: SubscriptionEntitlementFeature.rewind,
        ),
      );
      clock.value = clock.value.add(const Duration(minutes: 6));
      await useCase(
        const CheckEntitlementParams(
          feature: SubscriptionEntitlementFeature.rewind,
        ),
      );

      expect(repository.getCurrentPlanCalls, 2);
    });

    test('enforces the free like limit and returns a paywall source', () async {
      SharedPreferences.setMockInitialValues({
        'discovery_free_swipes_date_user-1': '2026-03-12',
        'discovery_free_swipes_remaining_user-1': 0,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = _StubSubscriptionRepository(SubscriptionTier.free);
      final useCase = CheckEntitlementUseCase(
        repository,
        preferences: prefs,
        clock: () => DateTime(2026, 3, 12, 11),
      );

      final result = await useCase(
        const CheckEntitlementParams(
          feature: SubscriptionEntitlementFeature.likes,
          userId: 'user-1',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.isAllowed, isFalse);
      expect(result.data?.remainingFreeUses, 0);
      expect(result.data?.paywallSource, 'likes_limit');
    });

    test('recordSuccessfulLike decrements the remaining free likes', () async {
      SharedPreferences.setMockInitialValues({
        'discovery_free_swipes_date_user-1': '2026-03-12',
        'discovery_free_swipes_remaining_user-1': 3,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = _StubSubscriptionRepository(SubscriptionTier.free);
      final useCase = CheckEntitlementUseCase(
        repository,
        preferences: prefs,
        clock: () => DateTime(2026, 3, 12, 11),
      );

      await useCase.recordSuccessfulLike('user-1');

      expect(await useCase.remainingFreeLikes('user-1'), 2);
    });

    test('premium tiers unlock likes you, rewind, and passport', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = _StubSubscriptionRepository(SubscriptionTier.platinum);
      final useCase = CheckEntitlementUseCase(
        repository,
        preferences: prefs,
        clock: () => DateTime(2026, 3, 12, 11),
      );

      final likesYou = await useCase(
        const CheckEntitlementParams(
          feature: SubscriptionEntitlementFeature.likesYou,
        ),
      );
      final rewind = await useCase(
        const CheckEntitlementParams(
          feature: SubscriptionEntitlementFeature.rewind,
        ),
      );
      final passport = await useCase(
        const CheckEntitlementParams(
          feature: SubscriptionEntitlementFeature.passport,
        ),
      );

      expect(likesYou.data?.isAllowed, isTrue);
      expect(rewind.data?.isAllowed, isTrue);
      expect(passport.data?.isAllowed, isTrue);
    });
  });
}

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  DateTime call() => value;
}

class _StubSubscriptionRepository implements SubscriptionRepository {
  _StubSubscriptionRepository(this.tier);

  final SubscriptionTier tier;
  int getCurrentPlanCalls = 0;

  @override
  Stream<SubscriptionTier> watchPlan() => Stream.value(tier);

  @override
  Future<SubscriptionTier> getCurrentPlan() async {
    getCurrentPlanCalls += 1;
    return tier;
  }

  @override
  Future<void> purchaseSubscription({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {}

  @override
  Future<void> purchaseProduct({required String productId}) async {
    final selection = subscriptionSelectionForProductId(productId);
    if (selection == null) {
      throw UnsupportedError('Unknown subscription product: $productId');
    }
    await purchaseSubscription(tier: selection.tier, period: selection.period);
  }

  @override
  Future<String> startCheckout({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async => 'https://example.com';

  @override
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async =>
      SubscriptionStatus(tier: tier);

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
      const PromoCodeRedemptionResult(success: false, errorMessage: 'unused');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => const [];
}
