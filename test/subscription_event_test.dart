import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';

void main() {
  group('SubscriptionEvent', () {
    test('empty events support equatable defaults', () {
      expect(SubscriptionWatchStarted().props, isEmpty);
      expect(SubscriptionProductsRequested().props, isEmpty);
      expect(SubscriptionPurchaseInitiated('plus_monthly').props, [
        'plus_monthly',
      ]);
      expect(
        SubscriptionCheckoutRequested(
          SubscriptionTier.plus,
          BillingPeriod.monthly,
        ).props,
        [SubscriptionTier.plus, BillingPeriod.monthly],
      );
      expect(SubscriptionRestoreRequested().props, isEmpty);
      expect(SubscriptionResetRequested().props, isEmpty);
      expect(
        SubscriptionTransactionUpdated(
          SubscriptionTransactionStatus.purchased,
        ).props,
        [SubscriptionTransactionStatus.purchased, null],
      );

      expect(SubscriptionWatchStarted(), SubscriptionWatchStarted());
      expect(SubscriptionProductsRequested(), SubscriptionProductsRequested());
      expect(
        SubscriptionPurchaseInitiated('plus_monthly'),
        SubscriptionPurchaseInitiated('plus_monthly'),
      );
      expect(SubscriptionResetRequested(), SubscriptionResetRequested());
      expect(
        SubscriptionTransactionUpdated(SubscriptionTransactionStatus.failed),
        SubscriptionTransactionUpdated(SubscriptionTransactionStatus.failed),
      );
    });

    test('SubscriptionTierUpdated stores plan in props', () {
      final event = SubscriptionTierUpdated(SubscriptionTier.plus);

      expect(event.props, [SubscriptionTier.plus]);
      expect(event, SubscriptionTierUpdated(SubscriptionTier.plus));
    });

    test('SubscriptionStatusUpdated stores status in props', () {
      final status = SubscriptionStatus(
        tier: SubscriptionTier.plus,
        status: 'active',
        cancelAtPeriodEnd: false,
      );
      final event = SubscriptionStatusUpdated(status);

      expect(event.props, [status]);
      expect(event, SubscriptionStatusUpdated(status));
    });
  });
}
