import 'package:crushhour/core/routing/premium_cta_helper.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef PremiumAction = void Function();

class PlusFeatureGate extends StatelessWidget {
  final Widget child;
  final PremiumAction onAllowed;

  const PlusFeatureGate({
    super.key,
    required this.child,
    required this.onAllowed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        final isPlus = state.tier == SubscriptionTier.plus;

        return InkWell(
          onTap: () {
            if (isPlus) {
              onAllowed();
            } else {
              _showPlusPaywall(context);
            }
          },
          child: child,
        );
      },
    );
  }

  void _showPlusPaywall(BuildContext context) {
    PremiumCtaHelper.showPaywall(context, source: 'feature_gate');
  }
}
