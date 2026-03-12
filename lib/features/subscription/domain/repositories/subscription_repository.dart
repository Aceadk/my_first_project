import 'dart:async';

import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';

typedef SubscriptionProductSelection = ({
  SubscriptionTier tier,
  BillingPeriod period,
});

SubscriptionProductSelection? subscriptionSelectionForProductId(
  String productId,
) {
  final parts = productId.split('_');
  if (parts.length != 2) {
    return null;
  }

  final tier = switch (parts.first) {
    'plus' => SubscriptionTier.plus,
    'platinum' => SubscriptionTier.platinum,
    _ => null,
  };
  final period = switch (parts.last) {
    'monthly' => BillingPeriod.monthly,
    'quarterly' => BillingPeriod.quarterly,
    'yearly' => BillingPeriod.yearly,
    _ => null,
  };
  if (tier == null || period == null) {
    return null;
  }

  return (tier: tier, period: period);
}

abstract class SubscriptionRepository {
  Stream<SubscriptionTier> watchPlan();

  Future<SubscriptionTier> getCurrentPlan();

  /// Integrate with real payments (Stripe, in-app purchase, etc.).
  Future<void> purchaseSubscription({
    required SubscriptionTier tier,
    required BillingPeriod period,
  });

  /// Starts a purchase using the store product identifier.
  Future<void> purchaseProduct({required String productId}) async {
    final selection = subscriptionSelectionForProductId(productId);
    if (selection == null) {
      throw UnsupportedError('Unknown subscription product: $productId');
    }
    await purchaseSubscription(tier: selection.tier, period: selection.period);
  }

  /// Starts a checkout session and returns the checkout URL.
  Future<String> startCheckout({
    required SubscriptionTier tier,
    required BillingPeriod period,
  });

  /// Launches the given checkout URL.
  Future<void> launchCheckoutUrl(String url);

  /// Reconciles plan against billing provider and returns latest status.
  Future<SubscriptionStatus> refreshStatus();

  /// Restores previously purchased subscriptions.
  Future<SubscriptionStatus> restorePurchases() => refreshStatus();

  /// Verifies a purchase receipt through the backend billing provider.
  Future<SubscriptionStatus> verifyPurchaseReceipt({
    required String platform,
    required String receiptData,
    required String productId,
    String? packageName,
  }) async {
    throw UnsupportedError(
      'Purchase receipt verification is not supported by this repository.',
    );
  }

  /// Loads the available subscription products for the current platform.
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async => const [];

  /// Validates a promo code without redeeming it.
  Future<PromoCode?> validatePromoCode(String code);

  /// Redeems a promo code for the current user.
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code);

  /// Gets the user's redemption history.
  Future<List<PromoCode>> getRedeemedCodes();
}
