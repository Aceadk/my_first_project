import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/firebase_subscription_repository.dart';
import 'package:crushhour/features/subscription/data/services/native_billing_service.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
      String? verifiedPlatform;
      String? verifiedReceiptData;
      String? verifiedProductId;
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
        purchaseReceiptVerifier:
            ({
              required String platform,
              required String receiptData,
              required String productId,
              String? packageName,
            }) async {
              verifiedPlatform = platform;
              verifiedReceiptData = receiptData;
              verifiedProductId = productId;
              return {
                'plan': 'plus',
                'status': 'active',
                'currentPeriodEnd': 1767225600,
                'cancelAtPeriodEnd': false,
              };
            },
      );

      await repository.purchaseSubscription(
        tier: SubscriptionTier.plus,
        period: BillingPeriod.monthly,
      );

      expect(billing.callCount, 1);
      expect(billing.purchasedProductId, 'plus_monthly');
      expect(verifiedPlatform, 'ios');
      expect(verifiedReceiptData, '2000000123456789');
      expect(verifiedProductId, 'plus_monthly');
    });

    test('fetchAvailableProducts maps native product details', () async {
      final billing = _FakeNativeBillingService(
        productDetails: [
          ProductDetails(
            id: 'plus_yearly',
            title: 'Crush+ Yearly',
            description: 'Yearly premium access',
            price: '\$71.49',
            rawPrice: 71.49,
            currencyCode: 'USD',
            currencySymbol: '\$',
          ),
          ProductDetails(
            id: 'platinum_quarterly',
            title: 'Crush Platinum Quarterly',
            description: 'Quarterly platinum access',
            price: '\$44.99',
            rawPrice: 44.99,
            currencyCode: 'USD',
            currencySymbol: '\$',
          ),
        ],
      );
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
      );

      final products = await repository.fetchAvailableProducts();

      expect(
        billing.queriedProductIds,
        containsAll(const ['plus_yearly', 'platinum_quarterly']),
      );
      expect(
        products,
        contains(
          const SubscriptionProduct(
            productId: 'plus_yearly',
            tier: SubscriptionTier.plus,
            period: BillingPeriod.yearly,
            title: 'Crush+ Yearly',
            description: 'Yearly premium access',
            priceLabel: '\$71.49',
            price: 71.49,
            currencyCode: 'USD',
            currencySymbol: '\$',
          ),
        ),
      );
    });

    test('startPlusCheckout is disabled on iOS', () async {
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: _FakeNativeBillingService(),
      );

      await expectLater(
        repository.startCheckout(
          tier: SubscriptionTier.plus,
          period: BillingPeriod.monthly,
        ),
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
        repository.purchaseSubscription(
          tier: SubscriptionTier.plus,
          period: BillingPeriod.monthly,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('restorePurchases verifies restored purchases on iOS', () async {
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
        purchaseReceiptVerifier:
            ({
              required String platform,
              required String receiptData,
              required String productId,
              String? packageName,
            }) async {
              expect(platform, 'ios');
              verifiedProductId = productId;
              verifiedTransactionId = receiptData;
              return {
                'plan': 'plus',
                'status': 'active',
                'currentPeriodEnd': 1767225600,
                'cancelAtPeriodEnd': false,
              };
            },
      );

      final status = await repository.restorePurchases();

      expect(billing.restoreCallCount, 1);
      expect(verifiedProductId, 'plus_monthly');
      expect(verifiedTransactionId, '2000000123456789');
      expect(status.tier, SubscriptionTier.plus);
      expect(status.status, 'active');
      expect(status.cancelAtPeriodEnd, isFalse);
      expect(
        status.nextRenewal,
        DateTime.fromMillisecondsSinceEpoch(1767225600 * 1000),
      );
    });

    test(
      'restorePurchases returns none when no purchases are restored',
      () async {
        final billing = _FakeNativeBillingService(restoredPurchases: const []);
        final repository = FirebaseSubscriptionRepository(
          nativeBillingService: billing,
          purchaseReceiptVerifier:
              ({
                required String platform,
                required String receiptData,
                required String productId,
                String? packageName,
              }) async {
                fail(
                  'Verifier should not be called when restore has no purchases.',
                );
              },
        );

        final status = await repository.restorePurchases();

        expect(billing.restoreCallCount, 1);
        expect(status.tier, SubscriptionTier.free);
        expect(status.status, 'none');
      },
    );

    test(
      'restorePurchases fails when restored purchase has no transaction ID',
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
          purchaseReceiptVerifier:
              ({
                required String platform,
                required String receiptData,
                required String productId,
                String? packageName,
              }) async {
                fail('Verifier should not be called without transaction ID.');
              },
        );

        await expectLater(
          repository.restorePurchases(),
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
    this.productDetails = const [],
    NativeSubscriptionPurchase? purchasedPurchase,
  }) : purchasedPurchase =
           purchasedPurchase ??
           const NativeSubscriptionPurchase(
             productId: 'plus_monthly',
             serverVerificationData: 'ios-receipt-data',
             isRestored: false,
             transactionId: '2000000123456789',
           );

  final bool shouldFail;
  final NativeSubscriptionPurchase purchasedPurchase;
  final List<NativeSubscriptionPurchase> restoredPurchases;
  final List<ProductDetails> productDetails;
  final bool shouldFailRestore = false;
  int callCount = 0;
  int restoreCallCount = 0;
  String? purchasedProductId;
  Set<String>? queriedProductIds;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async {
    queriedProductIds = productIds;
    return productDetails;
  }

  @override
  void dispose() {}

  @override
  Future<NativeSubscriptionPurchase> purchaseProduct({
    required String productId,
  }) async {
    callCount++;
    purchasedProductId = productId;
    if (shouldFail) {
      throw StateError('Native purchase failed.');
    }
    return purchasedPurchase;
  }

  @override
  Future<NativeSubscriptionPurchase> purchaseSubscription({
    required String productId,
  }) => purchaseProduct(productId: productId);

  @override
  Future<List<NativeSubscriptionPurchase>> restorePurchases() async {
    restoreCallCount++;
    if (shouldFailRestore) {
      throw StateError('Restore failed.');
    }
    return restoredPurchases;
  }

  @override
  Future<List<NativeSubscriptionPurchase>> restoreSubscriptionPurchases() =>
      restorePurchases();

  @override
  Future<NativeSubscriptionPurchase> verifyPurchase(
    PurchaseDetails purchase,
  ) async {
    throw UnimplementedError();
  }
}
