import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';

void main() {
  group('SubscriptionEvent', () {
    test('empty events support equatable defaults', () {
      expect(SubscriptionWatchStarted().props, isEmpty);
      expect(PlusCheckoutRequested().props, isEmpty);
      expect(SubscriptionRestoreRequested().props, isEmpty);
      expect(SubscriptionResetRequested().props, isEmpty);

      expect(SubscriptionWatchStarted(), SubscriptionWatchStarted());
      expect(SubscriptionResetRequested(), SubscriptionResetRequested());
    });

    test('SubscriptionPlanUpdated stores plan in props', () {
      final event = SubscriptionPlanUpdated(SubscriptionPlan.plus);

      expect(event.props, [SubscriptionPlan.plus]);
      expect(event, SubscriptionPlanUpdated(SubscriptionPlan.plus));
    });

    test('SubscriptionStatusUpdated stores status in props', () {
      final status = SubscriptionStatus(
        plan: SubscriptionPlan.plus,
        status: 'active',
        cancelAtPeriodEnd: false,
      );
      final event = SubscriptionStatusUpdated(status);

      expect(event.props, [status]);
      expect(event, SubscriptionStatusUpdated(status));
    });
  });
}
