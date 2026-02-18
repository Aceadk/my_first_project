import 'dart:async';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/promo_code.dart';

abstract class SubscriptionRepository {
  Stream<SubscriptionPlan> watchPlan();

  Future<SubscriptionPlan> getCurrentPlan();

  /// Integrate with real payments (Stripe, in-app purchase, etc.).
  Future<void> purchasePlusPlan();

  /// Starts a Plus checkout session and returns the checkout URL.
  Future<String> startPlusCheckout();

  /// Launches the given checkout URL.
  Future<void> launchCheckoutUrl(String url);

  /// Reconciles plan against billing provider and returns latest status.
  Future<SubscriptionStatus> refreshStatus();

  /// Validates a promo code without redeeming it.
  Future<PromoCode?> validatePromoCode(String code);

  /// Redeems a promo code for the current user.
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code);

  /// Gets the user's redemption history.
  Future<List<PromoCode>> getRedeemedCodes();
}
