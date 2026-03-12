import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';

enum SubscriptionRestoreFeedbackTone { success, info }

class SubscriptionRestoreFeedback {
  const SubscriptionRestoreFeedback({
    required this.message,
    required this.tone,
  });

  final String message;
  final SubscriptionRestoreFeedbackTone tone;
}

bool didFinishRestore(SubscriptionState previous, SubscriptionState current) {
  return previous.isRestoring && !current.isRestoring;
}

SubscriptionRestoreFeedback buildSubscriptionRestoreFeedback(
  SubscriptionState state, {
  required String locale,
}) {
  final normalizedStatus = state.statusLabel?.trim().toLowerCase();

  if (normalizedStatus == 'expired') {
    final expiredOn = state.nextRenewal;
    if (expiredOn != null) {
      final formattedDate = DateTimeFormatter.formatDate(
        expiredOn,
        locale: locale,
      );
      return SubscriptionRestoreFeedback(
        message:
            'A previous subscription was found, but it expired on $formattedDate.',
        tone: SubscriptionRestoreFeedbackTone.info,
      );
    }

    return const SubscriptionRestoreFeedback(
      message: 'A previous subscription was found, but it has expired.',
      tone: SubscriptionRestoreFeedbackTone.info,
    );
  }

  if (state.tier.hasPremium) {
    final tierName = switch (state.tier) {
      SubscriptionTier.plus => 'Plus',
      SubscriptionTier.platinum => 'Platinum',
      SubscriptionTier.free => 'Premium',
    };

    if (state.nextRenewal != null) {
      final formattedDate = DateTimeFormatter.formatDate(
        state.nextRenewal!,
        locale: locale,
      );
      final suffix = state.cancelAtPeriodEnd == true
          ? 'Access ends on $formattedDate.'
          : 'Renews on $formattedDate.';

      return SubscriptionRestoreFeedback(
        message: '$tierName restored. $suffix',
        tone: SubscriptionRestoreFeedbackTone.success,
      );
    }

    return SubscriptionRestoreFeedback(
      message: '$tierName access restored.',
      tone: SubscriptionRestoreFeedbackTone.success,
    );
  }

  if (normalizedStatus == null || normalizedStatus.isEmpty) {
    return const SubscriptionRestoreFeedback(
      message: 'Subscription status refreshed.',
      tone: SubscriptionRestoreFeedbackTone.info,
    );
  }

  if (normalizedStatus == 'none') {
    return const SubscriptionRestoreFeedback(
      message: 'No purchases found to restore.',
      tone: SubscriptionRestoreFeedbackTone.info,
    );
  }

  return SubscriptionRestoreFeedback(
    message: 'Subscription status updated: ${state.statusLabel}.',
    tone: SubscriptionRestoreFeedbackTone.info,
  );
}
