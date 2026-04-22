import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/utils/managed_timer_registry.dart';
import 'package:crushhour/config/billing_config.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// HTTP-based implementation of SubscriptionRepository.
///
/// Uses HTTP polling to check for subscription status changes.
/// This is acceptable because subscription changes are infrequent
/// (user-initiated purchases) and 60s latency is fine.
class HttpSubscriptionRepository implements SubscriptionRepository {
  HttpSubscriptionRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  bool get _requiresNativeMobilePurchase =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// Subscription polling interval.
  /// 60 seconds is sufficient since subscription changes are user-initiated
  /// and immediate accuracy isn't critical.
  static const _subscriptionPollingInterval = Duration(seconds: 60);
  static const _subscriptionPollingTimerKey = 'subscription_plan_polling';
  static const _redeemedCodesKey = 'redeemed_promo_codes_http';
  static const _localPlanKey = 'http_subscription_plan';
  static const _localStatusKey = 'http_subscription_status';
  static const _localRenewalKey = 'http_subscription_renewal';

  final _planController = StreamController<SubscriptionTier>.broadcast();
  SubscriptionTier _currentPlan = SubscriptionTier.free;
  final ManagedTimerRegistry _timers = ManagedTimerRegistry();

  static const Map<String, PromoCode> _demoCodes = {
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

  @override
  Stream<SubscriptionTier> watchPlan() {
    _startPolling();
    return _planController.stream;
  }

  void _startPolling() {
    _timers.cancel(_subscriptionPollingTimerKey);
    _fetchCurrentPlan();

    // Poll at configured interval to check for subscription changes
    _timers.startPeriodic(
      _subscriptionPollingTimerKey,
      _subscriptionPollingInterval,
      (_) => _fetchCurrentPlan(),
    );
  }

  Future<void> _fetchCurrentPlan() async {
    try {
      final tier = await getCurrentPlan();
      if (tier != _currentPlan) {
        _currentPlan = tier;
        _planController.add(tier);
      }
    } catch (e) {
      AppLogger.error('HttpSubscriptionRepository: Failed to fetch plan - $e');
    }
  }

  @override
  Future<SubscriptionTier> getCurrentPlan() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.subscriptionStatus,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpSubscriptionRepository: Failed to get plan - ${result.error}',
      );
      final localPlan = await _loadLocalPlan();
      if (localPlan != null) {
        _currentPlan = localPlan;
      }
      return _currentPlan;
    }

    final remotePlan = _tierFromPlan(result.data?['plan'] as String?);
    final localPlan = await _loadLocalPlan();
    _currentPlan = remotePlan == SubscriptionTier.free && localPlan != null
        ? localPlan
        : remotePlan;

    return _currentPlan;
  }

  @override
  Future<void> purchaseSubscription({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {
    if (_requiresNativeMobilePurchase) {
      throw UnsupportedError(
        'Mobile checkout must use native in-app purchase flow.',
      );
    }

    // Start checkout and launch URL
    final checkoutUrl = await startCheckout(tier: tier, period: period);
    await launchCheckoutUrl(checkoutUrl);
  }

  @override
  Future<void> purchaseProduct({required String productId}) async {
    final selection = subscriptionSelectionForProductId(productId);
    if (selection == null) {
      throw UnsupportedError('Unknown subscription product: $productId');
    }
    await purchaseSubscription(tier: selection.tier, period: selection.period);
  }

  @override
  Future<String> startCheckout({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {
    if (_requiresNativeMobilePurchase) {
      throw UnsupportedError(
        'Mobile checkout must use native in-app purchase flow.',
      );
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.subscriptionPurchase,
      body: {
        'price_id': 'price_${tier.name}_${period.name}',
        'success_url': 'https://crushhour.app/checkout/success',
        'cancel_url': 'https://crushhour.app/checkout/cancel',
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to start checkout');
    }

    final checkoutUrl =
        result.data?['url'] as String? ??
        result.data?['checkout_url'] as String?;
    if (checkoutUrl == null) {
      throw Exception('Checkout URL not received');
    }

    return checkoutUrl;
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    if (_requiresNativeMobilePurchase) {
      throw UnsupportedError(
        'Mobile checkout must use native in-app purchase flow.',
      );
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch checkout URL');
    }
  }

  @override
  Future<SubscriptionStatus> refreshStatus() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.subscriptionStatus,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      final localSnapshot = await _loadLocalStatusSnapshot();
      if (localSnapshot != null) {
        _currentPlan = localSnapshot.tier;
        _planController.add(localSnapshot.tier);
        return localSnapshot;
      }
      return SubscriptionStatus(tier: _currentPlan);
    }

    final data = result.data!;
    final remoteTier = _tierFromPlan(data['plan'] as String?);
    final localSnapshot = await _loadLocalStatusSnapshot();
    final tier = remoteTier == SubscriptionTier.free && localSnapshot != null
        ? localSnapshot.tier
        : remoteTier;
    final nextRenewal = data['expires_at'] != null
        ? DateTime.tryParse(data['expires_at'] as String)
        : localSnapshot?.nextRenewal;

    _currentPlan = tier;
    _planController.add(tier);

    return SubscriptionStatus(
      tier: tier,
      status:
          data['status'] as String? ??
          (data['is_active'] == true ? 'active' : localSnapshot?.status),
      nextRenewal: nextRenewal,
      cancelAtPeriodEnd:
          data['cancel_at_period_end'] as bool? ??
          localSnapshot?.cancelAtPeriodEnd ??
          false,
    );
  }

  @override
  Future<SubscriptionStatus> restorePurchases() => refreshStatus();

  @override
  Future<SubscriptionStatus> verifyPurchaseReceipt({
    required String platform,
    required String receiptData,
    required String productId,
    String? packageName,
  }) => refreshStatus();

  @override
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async {
    return BillingConfig.tiers
        .where((plan) => plan.tier != SubscriptionTier.free)
        .expand(
          (plan) => [
            _productFor(plan, BillingPeriod.monthly),
            _productFor(plan, BillingPeriod.quarterly),
            _productFor(plan, BillingPeriod.yearly),
          ],
        )
        .toList(growable: false);
  }

  /// Dispose resources.
  void dispose() {
    _timers.cancelAll();
    _planController.close();
  }

  SubscriptionProduct _productFor(
    BillingPlanConfig plan,
    BillingPeriod period,
  ) {
    final price = plan.getPriceForPeriod(period);
    return SubscriptionProduct(
      productId: '${plan.tier.name}_${period.name}',
      tier: plan.tier,
      period: period,
      title: plan.name,
      description: plan.description,
      priceLabel: '\$${price.toStringAsFixed(2)}',
      price: price,
      currencyCode: 'USD',
      currencySymbol: '\$',
    );
  }

  SubscriptionTier _tierFromPlan(String? planValue) {
    return switch (planValue) {
      'plus' => SubscriptionTier.plus,
      'platinum' => SubscriptionTier.platinum,
      _ => SubscriptionTier.free,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMO CODE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<PromoCode?> validatePromoCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    return _validateLocalPromoCode(normalizedCode);
  }

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    return _redeemLocalPromoCode(normalizedCode);
  }

  @override
  Future<List<PromoCode>> getRedeemedCodes() async {
    final redeemedCodes = await _getLocalRedeemedCodes();
    return redeemedCodes
        .map((code) => _demoCodes[code])
        .whereType<PromoCode>()
        .toList(growable: false);
  }

  Future<PromoCode?> _validateLocalPromoCode(String normalizedCode) async {
    final promoCode = _demoCodes[normalizedCode];
    if (promoCode == null) {
      return null;
    }

    final redeemedCodes = await _getLocalRedeemedCodes();
    if (redeemedCodes.contains(normalizedCode) || !promoCode.isValid) {
      return null;
    }

    return promoCode;
  }

  Future<PromoCodeRedemptionResult> _redeemLocalPromoCode(
    String normalizedCode,
  ) async {
    final promoCode = _demoCodes[normalizedCode];
    if (promoCode == null) {
      return PromoCodeRedemptionResult.failure(
        'Invalid promo code. Please check and try again.',
      );
    }
    if (promoCode.isExpired) {
      return PromoCodeRedemptionResult.failure('This promo code has expired.');
    }

    final redeemedCodes = await _getLocalRedeemedCodes();
    if (redeemedCodes.contains(normalizedCode)) {
      return PromoCodeRedemptionResult.failure(
        'You have already redeemed this promo code.',
      );
    }

    final benefits = <String>[];
    if (promoCode.discountPercent != null) {
      benefits.add('${promoCode.discountPercent}% discount applied');
      if (promoCode.discountPercent == 100) {
        await _saveLocalSubscription(
          tier: SubscriptionTier.plus,
          status: 'active',
          nextRenewal: DateTime.now().add(const Duration(days: 365)),
        );
        benefits.add('Plus membership activated!');
      }
    }

    if (promoCode.freeTrialDays != null) {
      benefits.add('${promoCode.freeTrialDays} day free trial activated');
      await _saveLocalSubscription(
        tier: SubscriptionTier.plus,
        status: 'trialing',
        nextRenewal: DateTime.now().add(
          Duration(days: promoCode.freeTrialDays!),
        ),
      );
    }

    if (promoCode.bonusLikes != null) {
      benefits.add('${promoCode.bonusLikes} bonus likes added');
    }

    if (promoCode.bonusSuperLikes != null) {
      benefits.add('${promoCode.bonusSuperLikes} bonus Super Likes added');
    }

    await _saveRedeemedCode(normalizedCode);
    return PromoCodeRedemptionResult.success(
      promoCode: promoCode,
      appliedBenefits: benefits,
    );
  }

  Future<SubscriptionTier?> _loadLocalPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPlan = prefs.getString(_localPlanKey);
    if (storedPlan == null || storedPlan.isEmpty) {
      return null;
    }
    return _tierFromPlan(storedPlan);
  }

  Future<SubscriptionStatus?> _loadLocalStatusSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPlan = prefs.getString(_localPlanKey);
    if (storedPlan == null || storedPlan.isEmpty) {
      return null;
    }

    final renewalRaw = prefs.getString(_localRenewalKey);
    return SubscriptionStatus(
      tier: _tierFromPlan(storedPlan),
      status: prefs.getString(_localStatusKey),
      nextRenewal: renewalRaw != null ? DateTime.tryParse(renewalRaw) : null,
    );
  }

  Future<void> _saveLocalSubscription({
    required SubscriptionTier tier,
    required String status,
    DateTime? nextRenewal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localPlanKey, tier.name);
    await prefs.setString(_localStatusKey, status);
    if (nextRenewal != null) {
      await prefs.setString(_localRenewalKey, nextRenewal.toIso8601String());
    } else {
      await prefs.remove(_localRenewalKey);
    }
    _currentPlan = tier;
    _planController.add(tier);
  }

  Future<Set<String>> _getLocalRedeemedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codes = prefs.getStringList(_redeemedCodesKey) ?? const <String>[];
    return codes.toSet();
  }

  Future<void> _saveRedeemedCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final redeemedCodes = prefs.getStringList(_redeemedCodesKey) ?? <String>[];
    if (!redeemedCodes.contains(code)) {
      redeemedCodes.add(code);
      await prefs.setStringList(_redeemedCodesKey, redeemedCodes);
    }
  }
}
