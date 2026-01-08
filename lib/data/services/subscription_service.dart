import '../models/subscription.dart';

/// Stub implementation of SubscriptionService.
/// Replace with your actual payment backend integration.
class SubscriptionService {
  Future<SubscriptionStatus> syncSubscriptionStatus() async {
    // TODO: Implement subscription status sync with your payment backend
    return SubscriptionStatus(plan: SubscriptionPlan.free);
  }
}
