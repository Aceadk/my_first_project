import 'dart:async';

import 'package:crushhour/features/subscription/data/services/native_billing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InAppPurchaseNativeBillingService', () {
    late TargetPlatform? previousPlatform;

    setUp(() {
      previousPlatform = debugDefaultTargetPlatformOverride;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = previousPlatform;
    });

    test('initialize installs the StoreKit delegate on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final client = _FakeNativeBillingClient();
      final delegateConfigurer = _FakeIosDelegateConfigurer();
      final service = InAppPurchaseNativeBillingService(
        billingClient: client,
        iosDelegateConfigurer: delegateConfigurer,
      );
      addTearDown(service.dispose);

      await service.initialize();
      await service.initialize();

      expect(delegateConfigurer.setCalls, 1);
      expect(
        delegateConfigurer.lastDelegate,
        isA<SKPaymentQueueDelegateWrapper>(),
      );
    });

    test('fetchProducts surfaces billing unavailable errors', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final service = InAppPurchaseNativeBillingService(
        billingClient: _FakeNativeBillingClient(available: false),
        iosDelegateConfigurer: _FakeIosDelegateConfigurer(),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.fetchProducts({'plus_monthly'}),
        throwsA(
          isA<NativeBillingException>().having(
            (error) => error.code,
            'code',
            NativeBillingFailureCode.billingUnavailable,
          ),
        ),
      );
    });

    test('fetchProducts maps network query failures', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final service = InAppPurchaseNativeBillingService(
        billingClient: _FakeNativeBillingClient(
          productResponse: ProductDetailsResponse(
            productDetails: const [],
            notFoundIDs: const [],
            error: IAPError(
              source: 'play',
              code: 'network_error',
              message: 'Network unavailable.',
            ),
          ),
        ),
        iosDelegateConfigurer: _FakeIosDelegateConfigurer(),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.fetchProducts({'plus_monthly'}),
        throwsA(
          isA<NativeBillingException>().having(
            (error) => error.code,
            'code',
            NativeBillingFailureCode.networkError,
          ),
        ),
      );
    });

    test('purchaseProduct completes after purchased stream update', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final client = _FakeNativeBillingClient(
        buyNonConsumableResult: true,
        productResponse: ProductDetailsResponse(
          productDetails: [_plusMonthlyProduct],
          notFoundIDs: const [],
        ),
      );
      final service = InAppPurchaseNativeBillingService(
        billingClient: client,
        iosDelegateConfigurer: _FakeIosDelegateConfigurer(),
      );
      addTearDown(service.dispose);

      final purchaseFuture = service.purchaseProduct(productId: 'plus_monthly');
      await Future<void>.delayed(Duration.zero);

      expect(client.lastPurchaseParam?.productDetails.id, 'plus_monthly');

      client.emitPurchases([
        _purchaseDetails(
          status: PurchaseStatus.purchased,
          pendingCompletePurchase: true,
        ),
      ]);

      await purchaseFuture;

      expect(client.completedPurchases, hasLength(1));
      expect(client.completedPurchases.single.productID, 'plus_monthly');
    });

    test('purchaseProduct maps already-owned purchase failures', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final client = _FakeNativeBillingClient(
        productResponse: ProductDetailsResponse(
          productDetails: [_plusMonthlyProduct],
          notFoundIDs: const [],
        ),
      );
      final service = InAppPurchaseNativeBillingService(
        billingClient: client,
        iosDelegateConfigurer: _FakeIosDelegateConfigurer(),
      );
      addTearDown(service.dispose);

      final purchaseFuture = service.purchaseProduct(productId: 'plus_monthly');
      await Future<void>.delayed(Duration.zero);

      client.emitPurchases([
        _purchaseDetails(
          status: PurchaseStatus.error,
          error: IAPError(
            source: 'play',
            code: 'item_already_owned',
            message: 'Item already owned.',
          ),
        ),
      ]);

      await expectLater(
        purchaseFuture,
        throwsA(
          isA<NativeBillingException>()
              .having(
                (error) => error.code,
                'code',
                NativeBillingFailureCode.itemAlreadyOwned,
              )
              .having(
                (error) => error.message,
                'message',
                'Item already owned.',
              ),
        ),
      );
    });

    test('purchaseProduct maps canceled purchases', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final client = _FakeNativeBillingClient(
        productResponse: ProductDetailsResponse(
          productDetails: [_plusMonthlyProduct],
          notFoundIDs: const [],
        ),
      );
      final service = InAppPurchaseNativeBillingService(
        billingClient: client,
        iosDelegateConfigurer: _FakeIosDelegateConfigurer(),
      );
      addTearDown(service.dispose);

      final purchaseFuture = service.purchaseProduct(productId: 'plus_monthly');
      await Future<void>.delayed(Duration.zero);

      client.emitPurchases([_purchaseDetails(status: PurchaseStatus.canceled)]);

      await expectLater(
        purchaseFuture,
        throwsA(
          isA<NativeBillingException>().having(
            (error) => error.code,
            'code',
            NativeBillingFailureCode.purchaseCanceled,
          ),
        ),
      );
    });

    test('restorePurchases returns verified restored purchases', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final client = _FakeNativeBillingClient();
      final service = InAppPurchaseNativeBillingService(
        billingClient: client,
        iosDelegateConfigurer: _FakeIosDelegateConfigurer(),
        restoreSettleDelay: const Duration(milliseconds: 25),
      );
      addTearDown(service.dispose);

      final restoreFuture = service.restorePurchases();
      await Future<void>.delayed(Duration.zero);

      client.emitPurchases([
        _purchaseDetails(
          status: PurchaseStatus.restored,
          purchaseId: 'restored-1',
          pendingCompletePurchase: true,
        ),
      ]);

      final restoredPurchases = await restoreFuture;

      expect(restoredPurchases, hasLength(1));
      expect(restoredPurchases.single.productId, 'plus_monthly');
      expect(restoredPurchases.single.transactionId, 'restored-1');
      expect(restoredPurchases.single.isRestored, isTrue);
      expect(client.completedPurchases, hasLength(1));
    });

    test('verifyPurchase rejects missing server verification data', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final service = InAppPurchaseNativeBillingService(
        billingClient: _FakeNativeBillingClient(),
        iosDelegateConfigurer: _FakeIosDelegateConfigurer(),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.verifyPurchase(
          _purchaseDetails(
            status: PurchaseStatus.purchased,
            serverVerificationData: '   ',
          ),
        ),
        throwsA(
          isA<NativeBillingException>().having(
            (error) => error.code,
            'code',
            NativeBillingFailureCode.verificationDataMissing,
          ),
        ),
      );
    });
  });
}

final ProductDetails _plusMonthlyProduct = ProductDetails(
  id: 'plus_monthly',
  title: 'Crush+ Monthly',
  description: 'Monthly premium access',
  price: '\$10.99',
  rawPrice: 10.99,
  currencyCode: 'USD',
  currencySymbol: '\$',
);

PurchaseDetails _purchaseDetails({
  required PurchaseStatus status,
  String productId = 'plus_monthly',
  String serverVerificationData = 'server-token',
  String? purchaseId = 'purchase-1',
  bool pendingCompletePurchase = false,
  IAPError? error,
}) {
  final purchase = PurchaseDetails(
    purchaseID: purchaseId,
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local-token',
      serverVerificationData: serverVerificationData,
      source: 'test',
    ),
    transactionDate: '1700000000000',
    status: status,
  );
  purchase.pendingCompletePurchase = pendingCompletePurchase;
  purchase.error = error;
  return purchase;
}

class _FakeNativeBillingClient implements NativeBillingClient {
  _FakeNativeBillingClient({
    this.available = true,
    ProductDetailsResponse? productResponse,
    this.buyNonConsumableResult = true,
  }) : productResponse =
           productResponse ??
           ProductDetailsResponse(
             productDetails: const [],
             notFoundIDs: const [],
           );

  final bool available;
  final ProductDetailsResponse productResponse;
  final bool buyNonConsumableResult;
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();
  final List<PurchaseDetails> completedPurchases = [];
  PurchaseParam? lastPurchaseParam;
  bool restoreInvoked = false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  void emitPurchases(List<PurchaseDetails> purchases) {
    _purchaseController.add(purchases);
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> productIds,
  ) async {
    return productResponse;
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastPurchaseParam = purchaseParam;
    return buyNonConsumableResult;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  @override
  Future<void> restorePurchases() async {
    restoreInvoked = true;
  }
}

class _FakeIosDelegateConfigurer implements NativeBillingIosDelegateConfigurer {
  int setCalls = 0;
  SKPaymentQueueDelegateWrapper? lastDelegate;

  @override
  Future<void> setDelegate(SKPaymentQueueDelegateWrapper? delegate) async {
    setCalls++;
    lastDelegate = delegate;
  }
}
