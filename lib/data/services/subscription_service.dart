import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

/// Mock implementation of SubscriptionService.
/// Syncs subscription status from local storage for demo purposes.
class SubscriptionService {
  static const _planKey = 'mock_subscription_plan';
  static const _statusKey = 'mock_subscription_status';
  static const _renewalKey = 'mock_subscription_renewal';

  Future<SubscriptionStatus> syncSubscriptionStatus() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    final planName = prefs.getString(_planKey);
    final status = prefs.getString(_statusKey);
    final renewalStr = prefs.getString(_renewalKey);

    final plan = planName == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
    DateTime? renewal;
    if (renewalStr != null) {
      renewal = DateTime.tryParse(renewalStr);
    }

    return SubscriptionStatus(
      plan: plan,
      status: status ?? (plan.isPlus ? 'active' : null),
      nextRenewal: renewal,
      cancelAtPeriodEnd: false,
    );
  }
}
