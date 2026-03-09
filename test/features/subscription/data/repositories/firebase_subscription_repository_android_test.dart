import 'package:crushhour/features/subscription/data/repositories/impl/firebase_subscription_repository.dart';
import 'package:crushhour/features/subscription/data/services/native_billing_service.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseSubscriptionRepository Android checkout path', () {
    late TargetPlatform? previousPlatform;

    setUp(() {
      previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
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

    test('refreshStatus verifies restored purchases on Android', () async {
      final billing = _FakeNativeBillingService(
        restoredPurchases: const [
          NativeSubscriptionPurchase(
            productId: 'plus_monthly',
            serverVerificationData: 'purchase-token-1',
            isRestored: true,
          ),
        ],
      );
      String? verifiedProductId;
      String? verifiedPurchaseToken;
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
        googlePurchaseTokenVerifier:
            ({required String productId, required String purchaseToken}) async {
              verifiedProductId = productId;
              verifiedPurchaseToken = purchaseToken;
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
      expect(verifiedPurchaseToken, 'purchase-token-1');
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
        googlePurchaseTokenVerifier:
            ({required String productId, required String purchaseToken}) async {
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

    test('refreshStatus propagates native restore failures', () async {
      final billing = _FakeNativeBillingService(shouldFailRestore: true);
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
      );

      await expectLater(repository.refreshStatus(), throwsA(isA<StateError>()));
      expect(billing.restoreCallCount, 1);
    });

    test('startPlusCheckout is disabled on Android', () async {
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: _FakeNativeBillingService(),
      );

      await expectLater(
        repository.startPlusCheckout(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('launchCheckoutUrl is disabled on Android', () async {
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: _FakeNativeBillingService(),
      );

      await expectLater(
        repository.launchCheckoutUrl('https://checkout.example.com'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

class _FakeNativeBillingService implements NativeBillingService {
  _FakeNativeBillingService({
    this.restoredPurchases = const [],
    this.shouldFailRestore = false,
  });

  final List<NativeSubscriptionPurchase> restoredPurchases;
  final bool shouldFailRestore;
  int callCount = 0;
  int restoreCallCount = 0;
  String? purchasedProductId;

  @override
  Future<void> purchaseSubscription({required String productId}) async {
    callCount++;
    purchasedProductId = productId;
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
