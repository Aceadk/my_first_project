import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/stub_subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StubSubscriptionRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to free plan', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      final plan = await repo.getCurrentPlan();
      expect(plan, SubscriptionPlan.free);
    });

    test('watchPlan emits plus after purchase', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      final expected = expectLater(
        repo.watchPlan(),
        emitsThrough(SubscriptionPlan.plus),
      );

      await repo.purchasePlusPlan();
      await expected;
    });

    test('purchasePlusPlan persists active status with renewal', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      await repo.purchasePlusPlan();
      final status = await repo.refreshStatus();

      expect(status.plan, SubscriptionPlan.plus);
      expect(status.status, 'active');
      expect(status.nextRenewal, isNotNull);
      expect(status.cancelAtPeriodEnd, isFalse);
    });

    test('launchCheckoutUrl upgrades plan through purchase flow', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      final checkoutUrl = await repo.startPlusCheckout();
      expect(checkoutUrl, startsWith('https://checkout.example.com/'));

      await repo.launchCheckoutUrl(checkoutUrl);
      final plan = await repo.getCurrentPlan();
      expect(plan, SubscriptionPlan.plus);
    });

    test('togglePlan switches from free to plus and back', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      await repo.togglePlan();
      expect(await repo.getCurrentPlan(), SubscriptionPlan.plus);

      await repo.togglePlan();
      expect(await repo.getCurrentPlan(), SubscriptionPlan.free);
    });

    test('validatePromoCode returns null for unknown code', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      final promo = await repo.validatePromoCode('not-a-real-code');
      expect(promo, isNull);
    });

    test(
      'validatePromoCode normalizes input and returns known promo',
      () async {
        final repo = StubSubscriptionRepository();
        addTearDown(repo.dispose);

        final promo = await repo.validatePromoCode('  welcome50  ');
        expect(promo, isNotNull);
        expect(promo!.code, 'WELCOME50');
      },
    );

    test('redeemPromoCode rejects invalid and expired codes', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      final invalid = await repo.redeemPromoCode('INVALID');
      expect(invalid.success, isFalse);
      expect(invalid.errorMessage, contains('Invalid promo code'));

      final expired = await repo.redeemPromoCode('EXPIRED');
      expect(expired.success, isFalse);
      expect(expired.errorMessage, contains('expired'));
    });

    test(
      'redeemPromoCode FREEWEEK activates trial and stores redemption',
      () async {
        final repo = StubSubscriptionRepository();
        addTearDown(repo.dispose);

        final result = await repo.redeemPromoCode('FREEWEEK');
        expect(result.success, isTrue);
        expect(result.appliedBenefits, contains('7 day free trial activated'));

        final status = await repo.refreshStatus();
        expect(status.plan, SubscriptionPlan.plus);
        expect(status.status, 'trialing');

        final redeemed = await repo.getRedeemedCodes();
        expect(redeemed.map((c) => c.code), contains('FREEWEEK'));
      },
    );

    test('redeemPromoCode CRUSHFREE upgrades to active plus', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      final result = await repo.redeemPromoCode('CRUSHFREE');
      expect(result.success, isTrue);
      expect(result.appliedBenefits, contains('100% discount applied'));
      expect(result.appliedBenefits, contains('Plus membership activated!'));

      final status = await repo.refreshStatus();
      expect(status.plan, SubscriptionPlan.plus);
      expect(status.status, 'active');
      expect(status.nextRenewal, isNotNull);
    });

    test('validatePromoCode returns null when already redeemed', () async {
      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      final first = await repo.redeemPromoCode('WELCOME50');
      expect(first.success, isTrue);

      final secondValidation = await repo.validatePromoCode('WELCOME50');
      expect(secondValidation, isNull);
    });

    test('getRedeemedCodes skips malformed persisted entries', () async {
      SharedPreferences.setMockInitialValues({
        'redeemed_promo_codes': [
          '{not-json',
          '{"code":"WELCOME50","type":"discount","currentRedemptions":0}',
        ],
      });

      final repo = StubSubscriptionRepository();
      addTearDown(repo.dispose);

      final redeemed = await repo.getRedeemedCodes();
      expect(redeemed.length, 1);
      expect(redeemed.first.code, 'WELCOME50');
    });
  });
}
