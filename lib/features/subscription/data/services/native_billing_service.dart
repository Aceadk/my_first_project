import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class NativeSubscriptionPurchase {
  const NativeSubscriptionPurchase({
    required this.productId,
    required this.serverVerificationData,
    required this.isRestored,
    this.transactionId,
  });

  final String productId;
  final String serverVerificationData;
  final bool isRestored;
  final String? transactionId;
}

/// Native billing abstraction used by repository implementations.
abstract class NativeBillingService {
  Future<void> initialize();
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds);
  Future<void> purchaseSubscription({required String productId});
  Future<List<NativeSubscriptionPurchase>> restoreSubscriptionPurchases();
  void dispose();
}

/// In-app purchase implementation backed by Flutter's IAP plugin.
class InAppPurchaseNativeBillingService implements NativeBillingService {
  InAppPurchaseNativeBillingService({
    InAppPurchase? inAppPurchase,
    Duration purchaseTimeout = const Duration(minutes: 2),
    Duration restoreTimeout = const Duration(seconds: 20),
    Duration restoreSettleDelay = const Duration(milliseconds: 1500),
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
       _purchaseTimeout = purchaseTimeout,
       _restoreTimeout = restoreTimeout,
       _restoreSettleDelay = restoreSettleDelay;

  final InAppPurchase _inAppPurchase;
  final Duration _purchaseTimeout;
  final Duration _restoreTimeout;
  final Duration _restoreSettleDelay;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Completer<void>? _activePurchaseCompleter;
  String? _activePurchaseProductId;

  Completer<List<NativeSubscriptionPurchase>>? _activeRestoreCompleter;
  List<NativeSubscriptionPurchase> _restoredPurchases = [];
  Timer? _restoreSettleTimer;
  Timer? _restoreTimeoutTimer;

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(_CrushPaymentQueueDelegate());
    }

    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        _failActivePurchase(error);
        _failActiveRestore(error);
      },
    );

    _isInitialized = true;
  }

  @override
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async {
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      throw StateError('In-app purchase is not available on this device.');
    }

    final response = await _inAppPurchase.queryProductDetails(productIds);
    if (response.error != null) {
      throw StateError(
        'Unable to query in-app purchase products: ${response.error!.message}',
      );
    }

    return response.productDetails;
  }

  @override
  Future<void> purchaseSubscription({required String productId}) async {
    if (!_isInitialized) await initialize();

    if (_activePurchaseCompleter != null &&
        !_activePurchaseCompleter!.isCompleted) {
      throw StateError('A purchase is already in progress.');
    }

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      throw StateError('In-app purchase is not available on this device.');
    }

    final productResponse = await _inAppPurchase.queryProductDetails({
      productId,
    });
    if (productResponse.error != null) {
      throw StateError(
        'Unable to query in-app purchase products: ${productResponse.error!.message}',
      );
    }

    if (productResponse.productDetails.isEmpty) {
      throw StateError('Product not found for "$productId".');
    }

    _activePurchaseCompleter = Completer<void>();
    _activePurchaseProductId = productId;

    final product = productResponse.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    final purchaseStarted = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!purchaseStarted) {
      _activePurchaseCompleter = null;
      _activePurchaseProductId = null;
      throw StateError('Could not start native purchase flow.');
    }

    return _activePurchaseCompleter!.future.timeout(
      _purchaseTimeout,
      onTimeout: () {
        _activePurchaseCompleter = null;
        _activePurchaseProductId = null;
        throw TimeoutException('Purchase timed out.');
      },
    );
  }

  @override
  Future<List<NativeSubscriptionPurchase>>
  restoreSubscriptionPurchases() async {
    if (!_isInitialized) await initialize();

    if (_activeRestoreCompleter != null &&
        !_activeRestoreCompleter!.isCompleted) {
      throw StateError('A restore is already in progress.');
    }

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      throw StateError('In-app purchase is not available on this device.');
    }

    _activeRestoreCompleter = Completer<List<NativeSubscriptionPurchase>>();
    _restoredPurchases = [];

    _restoreTimeoutTimer = Timer(_restoreTimeout, _completeRestore);

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _failActiveRestore(e);
      rethrow;
    }

    _restoreSettleTimer?.cancel();
    _restoreSettleTimer = Timer(_restoreSettleDelay, _completeRestore);

    return _activeRestoreCompleter!.future;
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      try {
        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _completePendingPurchaseIfNeeded(purchase);
            final nativePurchase = _toNativePurchase(purchase);

            if (purchase.status == PurchaseStatus.restored &&
                _activeRestoreCompleter != null) {
              if (!_restoredPurchases.any(
                (p) => p.transactionId == nativePurchase.transactionId,
              )) {
                _restoredPurchases.add(nativePurchase);
              }
            } else if (purchase.status == PurchaseStatus.purchased) {
              if (_activePurchaseCompleter != null &&
                  purchase.productID == _activePurchaseProductId) {
                if (!_activePurchaseCompleter!.isCompleted) {
                  _activePurchaseCompleter!.complete();
                }
              }
            }
            break;

          case PurchaseStatus.error:
            final errorMsg = purchase.error?.message ?? 'Purchase failed.';
            _failActivePurchase(StateError(errorMsg));
            break;

          case PurchaseStatus.canceled:
            _failActivePurchase(StateError('Purchase canceled.'));
            break;

          case PurchaseStatus.pending:
            break;
        }
      } catch (error) {
        if (purchase.status == PurchaseStatus.purchased) {
          _failActivePurchase(error);
        }
      }
    }

    if (_activeRestoreCompleter != null) {
      _restoreSettleTimer?.cancel();
      _restoreSettleTimer = Timer(_restoreSettleDelay, _completeRestore);
    }
  }

  void _completeRestore() {
    _restoreTimeoutTimer?.cancel();
    _restoreSettleTimer?.cancel();

    if (_activeRestoreCompleter != null &&
        !_activeRestoreCompleter!.isCompleted) {
      _activeRestoreCompleter!.complete(List.unmodifiable(_restoredPurchases));
    }
    _activeRestoreCompleter = null;
  }

  void _failActivePurchase(Object error) {
    if (_activePurchaseCompleter != null &&
        !_activePurchaseCompleter!.isCompleted) {
      _activePurchaseCompleter!.completeError(error);
    }
    _activePurchaseCompleter = null;
    _activePurchaseProductId = null;
  }

  void _failActiveRestore(Object error) {
    if (_activeRestoreCompleter != null &&
        !_activeRestoreCompleter!.isCompleted) {
      _activeRestoreCompleter!.completeError(error);
    }
    _activeRestoreCompleter = null;
  }

  Future<void> _completePendingPurchaseIfNeeded(
    PurchaseDetails purchase,
  ) async {
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  NativeSubscriptionPurchase _toNativePurchase(PurchaseDetails purchase) {
    final serverVerificationData = purchase
        .verificationData
        .serverVerificationData
        .trim();
    if (serverVerificationData.isEmpty) {
      throw StateError(
        'Missing purchase verification data for "${purchase.productID}".',
      );
    }

    return NativeSubscriptionPurchase(
      productId: purchase.productID,
      serverVerificationData: serverVerificationData,
      isRestored: purchase.status == PurchaseStatus.restored,
      transactionId: _normalizeTransactionId(purchase.purchaseID),
    );
  }

  String? _normalizeTransactionId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  @override
  void dispose() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // It's safe to clear the delegate when disposing, though generally
      // this service should live for the app lifecycle.
      try {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        iosPlatformAddition.setDelegate(null);
      } catch (_) {
        // Platform addition might not be ready or could throw on test environments
      }
    }
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
  }
}

class _CrushPaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
