import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/data/models/subscription.dart';
import '../subscription_repository.dart';

/// HTTP-based implementation of SubscriptionRepository.
class HttpSubscriptionRepository implements SubscriptionRepository {
  HttpSubscriptionRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final _planController = StreamController<SubscriptionPlan>.broadcast();
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  Timer? _pollingTimer;

  @override
  Stream<SubscriptionPlan> watchPlan() {
    _startPolling();
    return _planController.stream;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _fetchCurrentPlan();

    // Poll every 60 seconds to check for subscription changes
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetchCurrentPlan(),
    );
  }

  Future<void> _fetchCurrentPlan() async {
    try {
      final plan = await getCurrentPlan();
      if (plan != _currentPlan) {
        _currentPlan = plan;
        _planController.add(plan);
      }
    } catch (e) {
      debugPrint('HttpSubscriptionRepository: Failed to fetch plan - $e');
    }
  }

  @override
  Future<SubscriptionPlan> getCurrentPlan() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.subscriptionStatus,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      debugPrint('HttpSubscriptionRepository: Failed to get plan - ${result.error}');
      return _currentPlan;
    }

    final planStr = result.data?['plan'] as String? ?? 'free';
    _currentPlan = planStr == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;

    return _currentPlan;
  }

  @override
  Future<void> purchasePlusPlan() async {
    // Start checkout and launch URL
    final checkoutUrl = await startPlusCheckout();
    await launchCheckoutUrl(checkoutUrl);
  }

  @override
  Future<String> startPlusCheckout() async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.subscriptionPurchase,
      body: {'plan': 'plus'},
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
      return SubscriptionStatus(plan: _currentPlan);
    }

    final data = result.data!;
    final planStr = data['plan'] as String? ?? 'free';
    final plan = planStr == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;

    _currentPlan = plan;
    _planController.add(plan);

    return SubscriptionStatus(
      plan: plan,
      status: data['status'] as String?,
      nextRenewal: data['next_renewal'] != null
          ? DateTime.tryParse(data['next_renewal'] as String)
          : null,
      cancelAtPeriodEnd: data['cancel_at_period_end'] as bool? ?? false,
    );
  }

  /// Dispose resources.
  void dispose() {
    _pollingTimer?.cancel();
    _planController.close();
  }
}
