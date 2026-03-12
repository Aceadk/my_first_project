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

enum NativeBillingFailureCode {
  billingUnavailable,
  productQueryFailed,
  productNotFound,
  purchaseInProgress,
  restoreInProgress,
  purchaseCanceled,
  itemAlreadyOwned,
  networkError,
  verificationDataMissing,
  purchaseFailed,
  restoreFailed,
  timeout,
  unknown,
}

class NativeBillingException implements Exception {
  const NativeBillingException({
    required this.code,
    required this.message,
    this.details,
  });

  final NativeBillingFailureCode code;
  final String message;
  final Object? details;

  @override
  String toString() => 'NativeBillingException($code): $message';
}

abstract class NativeBillingClient {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> productIds);

  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});

  Future<void> completePurchase(PurchaseDetails purchase);

  Future<void> restorePurchases();
}

class InAppPurchaseBillingClient implements NativeBillingClient {
  InAppPurchaseBillingClient({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  InAppPurchase get inAppPurchase => _inAppPurchase;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _inAppPurchase.purchaseStream;

  @override
  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> productIds) =>
      _inAppPurchase.queryProductDetails(productIds);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _inAppPurchase.completePurchase(purchase);

  @override
  Future<void> restorePurchases() => _inAppPurchase.restorePurchases();
}

abstract class NativeBillingIosDelegateConfigurer {
  Future<void> setDelegate(SKPaymentQueueDelegateWrapper? delegate);
}

class StoreKitDelegateConfigurer implements NativeBillingIosDelegateConfigurer {
  StoreKitDelegateConfigurer({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  Future<void> setDelegate(SKPaymentQueueDelegateWrapper? delegate) async {
    final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
        _inAppPurchase
            .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    await iosPlatformAddition.setDelegate(delegate);
  }
}

/// Native billing abstraction used by repository implementations.
abstract class NativeBillingService {
  Future<void> initialize();
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds);
  Future<NativeSubscriptionPurchase> purchaseProduct({
    required String productId,
  });
  Future<List<NativeSubscriptionPurchase>> restorePurchases();
  Future<NativeSubscriptionPurchase> verifyPurchase(
    PurchaseDetails purchase,
  ) async {
    throw UnimplementedError('verifyPurchase must be implemented.');
  }

  Future<NativeSubscriptionPurchase> purchaseSubscription({
    required String productId,
  }) => purchaseProduct(productId: productId);
  Future<List<NativeSubscriptionPurchase>> restoreSubscriptionPurchases() =>
      restorePurchases();
  void dispose();
}

/// In-app purchase implementation backed by Flutter's IAP plugin.
class InAppPurchaseNativeBillingService implements NativeBillingService {
  InAppPurchaseNativeBillingService({
    NativeBillingClient? billingClient,
    NativeBillingIosDelegateConfigurer? iosDelegateConfigurer,
    InAppPurchase? inAppPurchase,
    Duration purchaseTimeout = const Duration(minutes: 2),
    Duration restoreTimeout = const Duration(seconds: 20),
    Duration restoreSettleDelay = const Duration(milliseconds: 1500),
  }) : _billingClient =
           billingClient ??
           InAppPurchaseBillingClient(inAppPurchase: inAppPurchase),
       _iosDelegateConfigurer =
           iosDelegateConfigurer ??
           StoreKitDelegateConfigurer(inAppPurchase: inAppPurchase),
       _purchaseTimeout = purchaseTimeout,
       _restoreTimeout = restoreTimeout,
       _restoreSettleDelay = restoreSettleDelay;

  final NativeBillingClient _billingClient;
  final NativeBillingIosDelegateConfigurer _iosDelegateConfigurer;
  final Duration _purchaseTimeout;
  final Duration _restoreTimeout;
  final Duration _restoreSettleDelay;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Completer<NativeSubscriptionPurchase>? _activePurchaseCompleter;
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
      await _iosDelegateConfigurer.setDelegate(_CrushPaymentQueueDelegate());
    }

    _subscription = _billingClient.purchaseStream.listen(
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
    await _ensureBillingAvailable();

    final response = await _billingClient.queryProductDetails(productIds);
    if (response.error != null) {
      throw _fromIapError(
        response.error!,
        fallbackCode: NativeBillingFailureCode.productQueryFailed,
        fallbackMessage: 'Unable to query in-app purchase products.',
      );
    }

    return response.productDetails;
  }

  @override
  Future<NativeSubscriptionPurchase> purchaseProduct({
    required String productId,
  }) async {
    if (!_isInitialized) await initialize();

    if (_activePurchaseCompleter != null &&
        !_activePurchaseCompleter!.isCompleted) {
      throw const NativeBillingException(
        code: NativeBillingFailureCode.purchaseInProgress,
        message: 'A purchase is already in progress.',
      );
    }

    await _ensureBillingAvailable();

    final productResponse = await _billingClient.queryProductDetails({
      productId,
    });
    if (productResponse.error != null) {
      throw _fromIapError(
        productResponse.error!,
        fallbackCode: NativeBillingFailureCode.productQueryFailed,
        fallbackMessage: 'Unable to query in-app purchase products.',
      );
    }

    if (productResponse.productDetails.isEmpty) {
      throw NativeBillingException(
        code: NativeBillingFailureCode.productNotFound,
        message: 'Product not found for "$productId".',
      );
    }

    _activePurchaseCompleter = Completer<NativeSubscriptionPurchase>();
    _activePurchaseProductId = productId;

    final product = productResponse.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    final purchaseStarted = await _billingClient.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!purchaseStarted) {
      _activePurchaseCompleter = null;
      _activePurchaseProductId = null;
      throw const NativeBillingException(
        code: NativeBillingFailureCode.purchaseFailed,
        message: 'Could not start native purchase flow.',
      );
    }

    return _activePurchaseCompleter!.future.timeout(
      _purchaseTimeout,
      onTimeout: () {
        _activePurchaseCompleter = null;
        _activePurchaseProductId = null;
        throw const NativeBillingException(
          code: NativeBillingFailureCode.timeout,
          message: 'Purchase timed out.',
        );
      },
    );
  }

  @override
  Future<NativeSubscriptionPurchase> purchaseSubscription({
    required String productId,
  }) => purchaseProduct(productId: productId);

  @override
  Future<List<NativeSubscriptionPurchase>> restorePurchases() async {
    if (!_isInitialized) await initialize();

    if (_activeRestoreCompleter != null &&
        !_activeRestoreCompleter!.isCompleted) {
      throw const NativeBillingException(
        code: NativeBillingFailureCode.restoreInProgress,
        message: 'A restore is already in progress.',
      );
    }

    await _ensureBillingAvailable();

    _activeRestoreCompleter = Completer<List<NativeSubscriptionPurchase>>();
    _restoredPurchases = [];

    _restoreTimeoutTimer = Timer(_restoreTimeout, _completeRestore);

    try {
      await _billingClient.restorePurchases();
    } catch (e) {
      final mappedError = _mapError(
        e,
        fallbackCode: NativeBillingFailureCode.restoreFailed,
        fallbackMessage: 'Could not restore purchases.',
      );
      _failActiveRestore(mappedError);
      throw mappedError;
    }

    _restoreSettleTimer?.cancel();
    _restoreSettleTimer = Timer(_restoreSettleDelay, _completeRestore);

    return _activeRestoreCompleter!.future;
  }

  @override
  Future<List<NativeSubscriptionPurchase>> restoreSubscriptionPurchases() =>
      restorePurchases();

  @override
  Future<NativeSubscriptionPurchase> verifyPurchase(
    PurchaseDetails purchase,
  ) async {
    await _completePendingPurchaseIfNeeded(purchase);
    return _toNativePurchase(purchase);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      try {
        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final nativePurchase = await verifyPurchase(purchase);

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
                  _activePurchaseCompleter!.complete(nativePurchase);
                }
              }
            }
            break;

          case PurchaseStatus.error:
            final mappedError = _mapError(
              purchase.error ??
                  const NativeBillingException(
                    code: NativeBillingFailureCode.purchaseFailed,
                    message: 'Purchase failed.',
                  ),
              fallbackCode: NativeBillingFailureCode.purchaseFailed,
              fallbackMessage: 'Purchase failed.',
            );
            _failActivePurchase(mappedError);
            if (_activeRestoreCompleter != null) {
              _failActiveRestore(mappedError);
            }
            break;

          case PurchaseStatus.canceled:
            const canceledError = NativeBillingException(
              code: NativeBillingFailureCode.purchaseCanceled,
              message: 'Purchase canceled.',
            );
            _failActivePurchase(canceledError);
            break;

          case PurchaseStatus.pending:
            break;
        }
      } catch (error) {
        final mappedError = _mapError(
          error,
          fallbackCode: purchase.status == PurchaseStatus.restored
              ? NativeBillingFailureCode.restoreFailed
              : NativeBillingFailureCode.purchaseFailed,
          fallbackMessage: purchase.status == PurchaseStatus.restored
              ? 'Could not restore purchases.'
              : 'Purchase failed.',
        );
        if (purchase.status == PurchaseStatus.purchased) {
          _failActivePurchase(mappedError);
        }
        if (purchase.status == PurchaseStatus.restored) {
          _failActiveRestore(mappedError);
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
    _restoreTimeoutTimer?.cancel();
    _restoreSettleTimer?.cancel();
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
      await _billingClient.completePurchase(purchase);
    }
  }

  NativeSubscriptionPurchase _toNativePurchase(PurchaseDetails purchase) {
    final serverVerificationData = purchase
        .verificationData
        .serverVerificationData
        .trim();
    if (serverVerificationData.isEmpty) {
      throw NativeBillingException(
        code: NativeBillingFailureCode.verificationDataMissing,
        message:
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
    _restoreTimeoutTimer?.cancel();
    _restoreSettleTimer?.cancel();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // It's safe to clear the delegate when disposing, though generally
      // this service should live for the app lifecycle.
      try {
        _iosDelegateConfigurer.setDelegate(null);
      } catch (_) {
        // Platform addition might not be ready or could throw on test environments
      }
    }
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
  }

  Future<void> _ensureBillingAvailable() async {
    final isAvailable = await _billingClient.isAvailable();
    if (!isAvailable) {
      throw const NativeBillingException(
        code: NativeBillingFailureCode.billingUnavailable,
        message: 'In-app purchase is not available on this device.',
      );
    }
  }

  NativeBillingException _mapError(
    Object error, {
    required NativeBillingFailureCode fallbackCode,
    required String fallbackMessage,
  }) {
    if (error is NativeBillingException) {
      return error;
    }
    if (error is IAPError) {
      return _fromIapError(
        error,
        fallbackCode: fallbackCode,
        fallbackMessage: fallbackMessage,
      );
    }
    if (error is TimeoutException) {
      return const NativeBillingException(
        code: NativeBillingFailureCode.timeout,
        message: 'Purchase timed out.',
      );
    }
    if (error is StateError) {
      return NativeBillingException(
        code: fallbackCode,
        message: error.message,
        details: error,
      );
    }
    return NativeBillingException(
      code: fallbackCode,
      message: fallbackMessage,
      details: error,
    );
  }

  NativeBillingException _fromIapError(
    IAPError error, {
    required NativeBillingFailureCode fallbackCode,
    required String fallbackMessage,
  }) {
    final normalizedCode = error.code.trim().toLowerCase();
    final mappedCode = switch (normalizedCode) {
      'billing_unavailable' => NativeBillingFailureCode.billingUnavailable,
      'item_already_owned' => NativeBillingFailureCode.itemAlreadyOwned,
      'purchase_cancelled' ||
      'purchase_canceled' ||
      'user_canceled' ||
      'user_cancelled' => NativeBillingFailureCode.purchaseCanceled,
      'network_error' => NativeBillingFailureCode.networkError,
      _ =>
        normalizedCode.contains('already_owned')
            ? NativeBillingFailureCode.itemAlreadyOwned
            : (normalizedCode.contains('cancel')
                  ? NativeBillingFailureCode.purchaseCanceled
                  : (normalizedCode.contains('network')
                        ? NativeBillingFailureCode.networkError
                        : fallbackCode)),
    };
    final message = error.message.trim().isEmpty
        ? fallbackMessage
        : error.message.trim();
    return NativeBillingException(
      code: mappedCode,
      message: message,
      details: error.details,
    );
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
