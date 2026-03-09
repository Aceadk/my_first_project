import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/firebase_subscription_repository.dart';
import 'package:crushhour/features/subscription/data/services/native_billing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseSubscriptionRepository iOS checkout path', () {
    late TargetPlatform? previousPlatform;

    setUp(() {
      previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = previousPlatform;
    });

    test('purchasePlusPlan routes through native billing service', () async {
      final billing = _FakeNativeBillingService();
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
      );

      await repository.purchasePlusPlan();

      expect(billing.callCount, 1);
      expect(billing.purchasedProductId, 'plus_monthly');
    });

    test('startPlusCheckout is disabled on iOS', () async {
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: _FakeNativeBillingService(),
      );

      await expectLater(
        repository.startPlusCheckout(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('launchCheckoutUrl is disabled on iOS', () async {
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: _FakeNativeBillingService(),
      );

      await expectLater(
        repository.launchCheckoutUrl('https://checkout.example.com'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('native billing purchase errors are propagated', () async {
      final billing = _FakeNativeBillingService(shouldFail: true);
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
      );

      await expectLater(
        repository.purchasePlusPlan(),
        throwsA(isA<StateError>()),
      );
    });

    test('refreshStatus verifies restored purchases on iOS', () async {
      final billing = _FakeNativeBillingService(
        restoredPurchases: const [
          NativeSubscriptionPurchase(
            productId: 'plus_monthly',
            serverVerificationData: 'ios-receipt-data',
            isRestored: true,
            transactionId: '2000000123456789',
          ),
        ],
      );
      String? verifiedProductId;
      String? verifiedTransactionId;
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
        appleTransactionVerifier:
            ({required String productId, required String transactionId}) async {
              verifiedProductId = productId;
              verifiedTransactionId = transactionId;
              return {
                'plan': 'plus',
                'status': 'active',
                'currentPeriodEnd': 1767225600,
                'cancelAtPeriodEnd': false,
              };
            },
      );

      final status = await repository.refreshStatus();

      expect(billing.restoreCallCount, 1);
      expect(verifiedProductId, 'plus_monthly');
      expect(verifiedTransactionId, '2000000123456789');
      expect(status.plan, SubscriptionPlan.plus);
      expect(status.status, 'active');
      expect(status.cancelAtPeriodEnd, isFalse);
      expect(
        status.nextRenewal,
        DateTime.fromMillisecondsSinceEpoch(1767225600 * 1000),
      );
    });

    test('refreshStatus returns none when no purchases are restored', () async {
      final billing = _FakeNativeBillingService(restoredPurchases: const []);
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
        appleTransactionVerifier:
            ({required String productId, required String transactionId}) async {
              fail(
                'Verifier should not be called when restore has no purchases.',
              );
            },
      );

      final status = await repository.refreshStatus();

      expect(billing.restoreCallCount, 1);
      expect(status.plan, SubscriptionPlan.free);
      expect(status.status, 'none');
    });

    test(
      'refreshStatus fails when restored purchase has no transaction ID',
      () async {
        final billing = _FakeNativeBillingService(
          restoredPurchases: const [
            NativeSubscriptionPurchase(
              productId: 'plus_monthly',
              serverVerificationData: 'ios-receipt-data',
              isRestored: true,
            ),
          ],
        );
        final repository = FirebaseSubscriptionRepository(
          nativeBillingService: billing,
          appleTransactionVerifier:
              ({
                required String productId,
                required String transactionId,
              }) async {
                fail('Verifier should not be called without transaction ID.');
              },
        );

        await expectLater(
          repository.refreshStatus(),
          throwsA(isA<StateError>()),
        );
        expect(billing.restoreCallCount, 1);
      },
    );
  });
}

class _FakeNativeBillingService implements NativeBillingService {
  _FakeNativeBillingService({
    this.shouldFail = false,
    this.restoredPurchases = const [],
  });

  final bool shouldFail;
  final List<NativeSubscriptionPurchase> restoredPurchases;
  final bool shouldFailRestore = false;
  int callCount = 0;
  int restoreCallCount = 0;
  String? purchasedProductId;

  @override
  Future<void> purchaseSubscription({required String productId}) async {
    callCount++;
    purchasedProductId = productId;
    if (shouldFail) {
      throw StateError('Native purchase failed.');
    }
  }

  @override
  Future<List<NativeSubscriptionPurchase>>
  restoreSubscriptionPurchases() async {
    restoreCallCount++;
    if (shouldFailRestore) {
      throw StateError('Restore failed.');
    }
    return restoredPurchases;
  }
}
