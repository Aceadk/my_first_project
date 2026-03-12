import 'package:crushhour/data/models/subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum SubscriptionManagementLaunchResult { launched, unsupported, failed }

class SubscriptionManagementLinks {
  SubscriptionManagementLinks._();

  static final Uri _iosManageSubscriptionsUri = Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  );

  static const String _androidManageSubscriptionsPath =
      '/store/account/subscriptions';

  static Future<Uri?> managementUri({
    required SubscriptionTier tier,
    TargetPlatform? platform,
    String? packageName,
  }) async {
    final targetPlatform = platform ?? defaultTargetPlatform;

    switch (targetPlatform) {
      case TargetPlatform.iOS:
        return _iosManageSubscriptionsUri;
      case TargetPlatform.android:
        final resolvedPackageName =
            packageName ??
            (await PackageInfo.fromPlatform()).packageName.trim();
        final queryParameters = <String, String>{
          'sku': _defaultSkuForTier(tier),
          if (resolvedPackageName.isNotEmpty) 'package': resolvedPackageName,
        };
        return Uri.https(
          'play.google.com',
          _androidManageSubscriptionsPath,
          queryParameters,
        );
      default:
        return null;
    }
  }

  static Future<SubscriptionManagementLaunchResult> openManagementPortal(
    SubscriptionTier tier,
  ) async {
    final uri = await managementUri(tier: tier);
    if (uri == null) {
      return SubscriptionManagementLaunchResult.unsupported;
    }

    final didLaunch = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return didLaunch
        ? SubscriptionManagementLaunchResult.launched
        : SubscriptionManagementLaunchResult.failed;
  }

  static String _defaultSkuForTier(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.platinum => 'platinum_monthly',
      SubscriptionTier.plus => 'plus_monthly',
      SubscriptionTier.free => 'plus_monthly',
    };
  }
}
