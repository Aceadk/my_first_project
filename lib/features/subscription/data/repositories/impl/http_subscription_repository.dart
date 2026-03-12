import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/utils/managed_timer_registry.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:flutter/foundation.dart';
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

  final _planController = StreamController<SubscriptionTier>.broadcast();
  SubscriptionTier _currentPlan = SubscriptionTier.free;
  final ManagedTimerRegistry _timers = ManagedTimerRegistry();

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
      return _currentPlan;
    }

    final planStr = result.data?['plan'] as String? ?? 'free';
    _currentPlan = planStr == 'plus'
        ? SubscriptionTier.plus
        : SubscriptionTier.free;

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
      body: {'tier': tier.name, 'period': period.name},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to start checkout');
    }

    final checkoutUrl = result.data?['checkout_url'] as String?;
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
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/subscription/refresh',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      return SubscriptionStatus(tier: _currentPlan);
    }

    final data = result.data!;
    final planStr = data['plan'] as String? ?? 'free';
    final tier = planStr == 'plus'
        ? SubscriptionTier.plus
        : SubscriptionTier.free;

    _currentPlan = tier;
    _planController.add(tier);

    return SubscriptionStatus(
      tier: tier,
      status: data['status'] as String?,
      nextRenewal: data['next_renewal'] != null
          ? DateTime.tryParse(data['next_renewal'] as String)
          : null,
      cancelAtPeriodEnd: data['cancel_at_period_end'] as bool? ?? false,
    );
  }

  /// Dispose resources.
  void dispose() {
    _timers.cancelAll();
    _planController.close();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMO CODE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<PromoCode?> validatePromoCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    final result = await _apiClient.post<Map<String, dynamic>>(
      '/promo-codes/validate',
      body: {'code': normalizedCode},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure || result.data?['valid'] != true) {
      return null;
    }

    return PromoCode.fromJson(
      result.data!['promoCode'] as Map<String, dynamic>,
    );
  }

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    final result = await _apiClient.post<Map<String, dynamic>>(
      '/promo-codes/redeem',
      body: {'code': normalizedCode},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      return PromoCodeRedemptionResult.failure(
        result.error?.message ?? 'Failed to redeem promo code.',
      );
    }

    final data = result.data!;
    if (data['success'] != true) {
      return PromoCodeRedemptionResult.failure(
        data['error'] as String? ?? 'Failed to redeem promo code.',
      );
    }

    final promoCode = PromoCode.fromJson(
      data['promoCode'] as Map<String, dynamic>,
    );
    final benefits =
        (data['appliedBenefits'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return PromoCodeRedemptionResult.success(
      promoCode: promoCode,
      appliedBenefits: benefits,
    );
  }

  @override
  Future<List<PromoCode>> getRedeemedCodes() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/promo-codes/redeemed',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) return [];

    final codes = result.data?['codes'] as List<dynamic>?;
    if (codes == null) return [];

    return codes
        .map((json) => PromoCode.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
