import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/data/models/subscription.dart';
import '../subscription_repository.dart';

/// Mock implementation of SubscriptionRepository with local storage.
/// Allows upgrading to Plus plan for demo/development purposes.
/// The plan persists across app restarts.
class StubSubscriptionRepository implements SubscriptionRepository {
  static const _planKey = 'mock_subscription_plan';
  static const _statusKey = 'mock_subscription_status';
  static const _renewalKey = 'mock_subscription_renewal';

  final _planController = StreamController<SubscriptionPlan>.broadcast();
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;

  StubSubscriptionRepository() {
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planName = prefs.getString(_planKey);
    if (planName == 'plus') {
      _currentPlan = SubscriptionPlan.plus;
    } else {
      _currentPlan = SubscriptionPlan.free;
    }
    _planController.add(_currentPlan);
  }

  Future<void> _savePlan(SubscriptionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, plan.name);
    _currentPlan = plan;
    _planController.add(plan);
  }

  @override
  Stream<SubscriptionPlan> watchPlan() {
    // Emit current plan immediately for new subscribers
    Future.microtask(() => _planController.add(_currentPlan));
    return _planController.stream;
  }

  @override
  Future<SubscriptionPlan> getCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planName = prefs.getString(_planKey);
    if (planName == 'plus') {
      return SubscriptionPlan.plus;
    }
    return SubscriptionPlan.free;
  }

  @override
  Future<void> purchasePlusPlan() async {
    // Simulate purchase delay
    await Future.delayed(const Duration(milliseconds: 800));

    // For demo: always succeed and upgrade to Plus
    await _savePlan(SubscriptionPlan.plus);

    // Store renewal date (1 month from now for demo)
    final prefs = await SharedPreferences.getInstance();
    final renewalDate = DateTime.now().add(const Duration(days: 30));
    await prefs.setString(_renewalKey, renewalDate.toIso8601String());
    await prefs.setString(_statusKey, 'active');
  }

  @override
  Future<String> startPlusCheckout() async {
    // Simulate checkout session creation
    await Future.delayed(const Duration(milliseconds: 300));

    // For demo: return a fake checkout URL
    // In real app, this would be a Stripe checkout session URL
    return 'https://checkout.example.com/session_demo_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    // For demo: simulate launching checkout and auto-completing purchase
    await Future.delayed(const Duration(milliseconds: 500));

    // Auto-upgrade to Plus for demo purposes
    await purchasePlusPlan();
  }

  @override
  Future<SubscriptionStatus> refreshStatus() async {
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

  /// Downgrade to free plan (for testing)
  Future<void> downgradeToFree() async {
    await _savePlan(SubscriptionPlan.free);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statusKey);
    await prefs.remove(_renewalKey);
  }

  /// Toggle between free and plus (for quick testing)
  Future<void> togglePlan() async {
    if (_currentPlan == SubscriptionPlan.free) {
      await purchasePlusPlan();
    } else {
      await downgradeToFree();
    }
  }

  void dispose() {
    _planController.close();
  }
}
