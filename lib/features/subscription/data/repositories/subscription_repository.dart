import 'dart:async';
import 'package:crushhour/data/models/subscription.dart';

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
}
