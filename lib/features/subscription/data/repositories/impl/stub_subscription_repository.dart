import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';

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

    final plan =
        planName == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMO CODE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  static const _redeemedCodesKey = 'redeemed_promo_codes';

  /// Demo promo codes for testing.
  static const Map<String, PromoCode> _baseCodes = {
    'WELCOME50': PromoCode(
      code: 'WELCOME50',
      type: PromoCodeType.discount,
      description: '50% off your first month of Plus',
      discountPercent: 50,
    ),
    'FREEWEEK': PromoCode(
      code: 'FREEWEEK',
      type: PromoCodeType.freeTrial,
      description: '7 days free trial of Plus',
      freeTrialDays: 7,
    ),
    'CRUSH2024': PromoCode(
      code: 'CRUSH2024',
      type: PromoCodeType.combined,
      description: 'Special launch offer: 30% off + 10 bonus likes',
      discountPercent: 30,
      bonusLikes: 10,
    ),
    'SUPERLOVE': PromoCode(
      code: 'SUPERLOVE',
      type: PromoCodeType.bonusSuperLikes,
      description: '5 bonus Super Likes',
      bonusSuperLikes: 5,
    ),
    'CRUSHFREE': PromoCode(
      code: 'CRUSHFREE',
      type: PromoCodeType.discount,
      description: '100% off - Completely free Plus membership!',
      discountPercent: 100,
    ),
  };

  static final Map<String, PromoCode> _demoCodes = {
    ..._baseCodes,
    'EXPIRED': PromoCode(
      code: 'EXPIRED',
      type: PromoCodeType.discount,
      description: 'Expired code for testing',
      discountPercent: 20,
      expiresAt: DateTime(2023, 1, 1), // Already expired
    ),
  };

  @override
  Future<PromoCode?> validatePromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedCode = code.trim().toUpperCase();
    final promoCode = _demoCodes[normalizedCode];

    if (promoCode == null) {
      return null;
    }

    // Check if already redeemed
    final redeemed = await getRedeemedCodes();
    if (redeemed.any((c) => c.code == normalizedCode)) {
      return null; // Already redeemed
    }

    return promoCode.isValid ? promoCode : null;
  }

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final normalizedCode = code.trim().toUpperCase();
    final promoCode = _demoCodes[normalizedCode];

    if (promoCode == null) {
      return PromoCodeRedemptionResult.failure(
        'Invalid promo code. Please check and try again.',
      );
    }

    if (promoCode.isExpired) {
      return PromoCodeRedemptionResult.failure(
        'This promo code has expired.',
      );
    }

    if (promoCode.isMaxedOut) {
      return PromoCodeRedemptionResult.failure(
        'This promo code has reached its maximum redemptions.',
      );
    }

    // Check if already redeemed by this user
    final redeemed = await getRedeemedCodes();
    if (redeemed.any((c) => c.code == normalizedCode)) {
      return PromoCodeRedemptionResult.failure(
        'You have already redeemed this promo code.',
      );
    }

    // Apply benefits
    final benefits = <String>[];

    if (promoCode.discountPercent != null) {
      benefits.add('${promoCode.discountPercent}% discount applied');
      // For 100% discount, upgrade to Plus immediately
      if (promoCode.discountPercent == 100) {
        await _savePlan(SubscriptionPlan.plus);
        final prefs = await SharedPreferences.getInstance();
        // Set renewal 1 year from now for 100% discount
        final renewalDate = DateTime.now().add(const Duration(days: 365));
        await prefs.setString(_renewalKey, renewalDate.toIso8601String());
        await prefs.setString(_statusKey, 'active');
        benefits.add('Plus membership activated!');
      }
    }

    if (promoCode.freeTrialDays != null) {
      benefits.add('${promoCode.freeTrialDays} day free trial activated');
      // For demo: upgrade to Plus immediately
      await _savePlan(SubscriptionPlan.plus);
      final prefs = await SharedPreferences.getInstance();
      final trialEnd = DateTime.now().add(
        Duration(days: promoCode.freeTrialDays!),
      );
      await prefs.setString(_renewalKey, trialEnd.toIso8601String());
      await prefs.setString(_statusKey, 'trialing');
    }

    if (promoCode.bonusLikes != null) {
      benefits.add('${promoCode.bonusLikes} bonus likes added');
    }

    if (promoCode.bonusSuperLikes != null) {
      benefits.add('${promoCode.bonusSuperLikes} bonus Super Likes added');
    }

    // Save redemption
    await _saveRedeemedCode(promoCode);

    return PromoCodeRedemptionResult.success(
      promoCode: promoCode,
      appliedBenefits: benefits,
    );
  }

  @override
  Future<List<PromoCode>> getRedeemedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codesJson = prefs.getStringList(_redeemedCodesKey) ?? [];

    return codesJson
        .map((json) {
          try {
            return PromoCode.fromJson(
              jsonDecode(json) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<PromoCode>()
        .toList();
  }

  Future<void> _saveRedeemedCode(PromoCode code) async {
    final prefs = await SharedPreferences.getInstance();
    final codesJson = prefs.getStringList(_redeemedCodesKey) ?? [];
    codesJson.add(jsonEncode(code.toJson()));
    await prefs.setStringList(_redeemedCodesKey, codesJson);
  }
}
