import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/firebase_subscription_repository.dart';
import 'package:crushhour/features/subscription/data/services/native_billing_service.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
      final billing = _FakeNativeBillingService(
        purchasedPurchase: const NativeSubscriptionPurchase(
          productId: 'plus_monthly',
          serverVerificationData: 'purchase-token-1',
          isRestored: false,
        ),
      );
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
      expect(verifiedPlatform, 'android');
      expect(verifiedReceiptData, 'purchase-token-1');
      expect(verifiedProductId, 'plus_monthly');
    });

    test('fetchAvailableProducts maps native product details', () async {
      final billing = _FakeNativeBillingService(
        productDetails: [
          ProductDetails(
            id: 'plus_monthly',
            title: 'Crush+ Monthly',
            description: 'Monthly premium access',
            price: '\$10.99',
            rawPrice: 10.99,
            currencyCode: 'USD',
            currencySymbol: '\$',
          ),
          ProductDetails(
            id: 'platinum_yearly',
            title: 'Crush Platinum Yearly',
            description: 'Yearly platinum access',
            price: '\$149.99',
            rawPrice: 149.99,
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
        containsAll(const ['plus_monthly', 'platinum_yearly']),
      );
      expect(
        products,
        contains(
          const SubscriptionProduct(
            productId: 'plus_monthly',
            tier: SubscriptionTier.plus,
            period: BillingPeriod.monthly,
            title: 'Crush+ Monthly',
            description: 'Monthly premium access',
            priceLabel: '\$10.99',
            price: 10.99,
            currencyCode: 'USD',
            currencySymbol: '\$',
          ),
        ),
      );
    });

    test('restorePurchases verifies restored purchases on Android', () async {
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
        purchaseReceiptVerifier:
            ({
              required String platform,
              required String receiptData,
              required String productId,
              String? packageName,
            }) async {
              expect(platform, 'android');
              verifiedProductId = productId;
              verifiedPurchaseToken = receiptData;
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
      expect(verifiedPurchaseToken, 'purchase-token-1');
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

    test('restorePurchases propagates native restore failures', () async {
      final billing = _FakeNativeBillingService(shouldFailRestore: true);
      final repository = FirebaseSubscriptionRepository(
        nativeBillingService: billing,
      );

      await expectLater(
        repository.restorePurchases(),
        throwsA(isA<StateError>()),
      );
      expect(billing.restoreCallCount, 1);
    });

    test('startPlusCheckout is disabled on Android', () async {
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
    this.productDetails = const [],
    NativeSubscriptionPurchase? purchasedPurchase,
  }) : purchasedPurchase =
           purchasedPurchase ??
           const NativeSubscriptionPurchase(
             productId: 'plus_monthly',
             serverVerificationData: 'purchase-token',
             isRestored: false,
           );

  final NativeSubscriptionPurchase purchasedPurchase;

  final List<NativeSubscriptionPurchase> restoredPurchases;
  final bool shouldFailRestore;
  final List<ProductDetails> productDetails;
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
