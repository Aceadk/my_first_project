import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

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
  Future<void> purchaseSubscription({required String productId});

  Future<List<NativeSubscriptionPurchase>> restoreSubscriptionPurchases();
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

  @override
  Future<void> purchaseSubscription({required String productId}) async {
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      throw StateError('In-app purchase is not available on this device.');
    }

    final productResponse = await _inAppPurchase.queryProductDetails({
      productId,
    });
    if (productResponse.error != null) {
      throw StateError(
        'Unable to query in-app purchase products: '
        '${productResponse.error!.message}',
      );
    }

    if (productResponse.productDetails.isEmpty) {
      throw StateError('Product not found for "$productId".');
    }

    final product = productResponse.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    final purchaseStarted = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    if (!purchaseStarted) {
      throw StateError('Could not start native purchase flow.');
    }

    await _waitForPurchaseResult(productId);
  }

  @override
  Future<List<NativeSubscriptionPurchase>>
  restoreSubscriptionPurchases() async {
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      throw StateError('In-app purchase is not available on this device.');
    }

    final completer = Completer<List<NativeSubscriptionPurchase>>();
    final restored = <NativeSubscriptionPurchase>[];
    final dedupe = <String>{};
    Timer? settleTimer;
    Timer? timeoutTimer;
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    void completeWithResults() {
      if (!completer.isCompleted) {
        completer.complete(
          List<NativeSubscriptionPurchase>.unmodifiable(restored),
        );
      }
    }

    subscription = _inAppPurchase.purchaseStream.listen(
      (purchases) async {
        try {
          for (final purchase in purchases) {
            switch (purchase.status) {
              case PurchaseStatus.purchased:
              case PurchaseStatus.restored:
                await _completePendingPurchaseIfNeeded(purchase);
                final parsed = _toNativePurchase(purchase);
                final key =
                    '${parsed.productId}:${parsed.serverVerificationData}:${parsed.isRestored}';
                if (dedupe.add(key)) {
                  restored.add(parsed);
                }
                break;
              case PurchaseStatus.error:
                final message =
                    purchase.error?.message ?? 'Failed to restore purchases.';
                if (!completer.isCompleted) {
                  completer.completeError(StateError(message));
                }
                break;
              case PurchaseStatus.pending:
              case PurchaseStatus.canceled:
                break;
            }
          }
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }

        settleTimer?.cancel();
        settleTimer = Timer(_restoreSettleDelay, completeWithResults);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    timeoutTimer = Timer(_restoreTimeout, completeWithResults);

    try {
      await _inAppPurchase.restorePurchases();
      settleTimer = Timer(_restoreSettleDelay, completeWithResults);
      return await completer.future;
    } finally {
      settleTimer?.cancel();
      timeoutTimer.cancel();
      await subscription.cancel();
    }
  }

  Future<void> _waitForPurchaseResult(String productId) async {
    final completer = Completer<NativeSubscriptionPurchase>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    subscription = _inAppPurchase.purchaseStream.listen(
      (purchases) async {
        try {
          for (final purchase in purchases) {
            if (purchase.productID != productId) continue;

            switch (purchase.status) {
              case PurchaseStatus.purchased:
              case PurchaseStatus.restored:
                await _completePendingPurchaseIfNeeded(purchase);
                if (!completer.isCompleted) {
                  completer.complete(_toNativePurchase(purchase));
                }
                break;
              case PurchaseStatus.error:
                final message = purchase.error?.message ?? 'Purchase failed.';
                if (!completer.isCompleted) {
                  completer.completeError(StateError(message));
                }
                break;
              case PurchaseStatus.canceled:
                if (!completer.isCompleted) {
                  completer.completeError(StateError('Purchase canceled.'));
                }
                break;
              case PurchaseStatus.pending:
                break;
            }
          }
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
    );

    try {
      await completer.future.timeout(_purchaseTimeout);
    } finally {
      await subscription.cancel();
    }
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
}
