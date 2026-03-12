import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A canonical helper to route users to the PaywallScreen.
/// Ensures that analytics are fired consistently and handles potential
/// business logic around showing the paywall (e.g. if already platinum, don't show).
class PremiumCtaHelper {
  /// Navigates to the PaywallScreen and logs the paywall_viewed event.
  ///
  /// Provide a [source] string to track where the user clicked the CTA from
  /// (e.g. 'likes_limit', 'settings_upgrade', 'feature_gate').
  static Future<void> showPaywall(
    BuildContext context, {
    required String source,
  }) async {
    // 1. Log analytics
    AnalyticsService.instance.logPaywallViewed(source: source);

    // 2. Navigate to paywall with source parameter
    final uri = Uri(
      path: CrushRoutes.paywall,
      queryParameters: {'source': source},
    );

    context.push(uri.toString());
  }
}
