import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/features/subscription/presentation/subscription_restore_feedback.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('describes restored Plus access with renewal details', () {
    final feedback = buildSubscriptionRestoreFeedback(
      const SubscriptionState(
        tier: SubscriptionTier.plus,
        statusLabel: 'active',
        nextRenewal: null,
      ).copyWith(nextRenewal: DateTime(2026, 4, 1), cancelAtPeriodEnd: false),
      locale: 'en',
    );

    expect(feedback.tone, SubscriptionRestoreFeedbackTone.success);
    expect(feedback.message, contains('Plus restored.'));
    expect(feedback.message, contains('Renews on'));
  });

  test('describes missing purchases as informational feedback', () {
    final feedback = buildSubscriptionRestoreFeedback(
      const SubscriptionState(tier: SubscriptionTier.free, statusLabel: 'none'),
      locale: 'en',
    );

    expect(feedback.tone, SubscriptionRestoreFeedbackTone.info);
    expect(feedback.message, 'No purchases found to restore.');
  });

  test('describes expired subscriptions gracefully', () {
    final feedback = buildSubscriptionRestoreFeedback(
      const SubscriptionState(
        tier: SubscriptionTier.free,
        statusLabel: 'expired',
      ).copyWith(nextRenewal: DateTime(2026, 2, 1)),
      locale: 'en',
    );

    expect(feedback.tone, SubscriptionRestoreFeedbackTone.info);
    expect(feedback.message, contains('expired on'));
  });
}
