import 'dart:async';
import '../../models/subscription.dart';
import '../subscription_repository.dart';

/// Stub implementation of SubscriptionRepository.
/// Replace this with your actual payment/subscription backend.
class StubSubscriptionRepository implements SubscriptionRepository {
  final _planController = StreamController<SubscriptionPlan>.broadcast();

  StubSubscriptionRepository() {
    // Emit free plan by default
    _planController.add(SubscriptionPlan.free);
  }

  @override
  Stream<SubscriptionPlan> watchPlan() => _planController.stream;

  @override
  Future<SubscriptionPlan> getCurrentPlan() async {
    // TODO: Fetch current plan from your payment backend
    return SubscriptionPlan.free;
  }

  @override
  Future<void> purchasePlusPlan() async {
    // TODO: Implement in-app purchase or payment flow
    throw UnimplementedError('Purchase not implemented. Connect your payment backend.');
  }

  @override
  Future<String> startPlusCheckout() async {
    // TODO: Implement checkout session creation (e.g., Stripe)
    throw UnimplementedError('Checkout not implemented. Connect your payment backend.');
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    // TODO: Launch checkout URL in browser
    throw UnimplementedError('Checkout launch not implemented.');
  }

  @override
  Future<SubscriptionStatus> refreshStatus() async {
    // TODO: Refresh subscription status from your payment backend
    return SubscriptionStatus(plan: SubscriptionPlan.free);
  }

  void dispose() {
    _planController.close();
  }
}
