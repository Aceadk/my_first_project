import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/presentation/subscription_management_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the App Store subscription management URL for iOS', () async {
    final uri = await SubscriptionManagementLinks.managementUri(
      tier: SubscriptionTier.plus,
      platform: TargetPlatform.iOS,
    );

    expect(uri.toString(), 'https://apps.apple.com/account/subscriptions');
  });

  test('builds the Play Store subscription management URL for Android', () async {
    final uri = await SubscriptionManagementLinks.managementUri(
      tier: SubscriptionTier.platinum,
      platform: TargetPlatform.android,
      packageName: 'com.crushhour.app',
    );

    expect(
      uri.toString(),
      'https://play.google.com/store/account/subscriptions?sku=platinum_monthly&package=com.crushhour.app',
    );
  });
}
