import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/data/models/subscription.dart';

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
        final isPlus = state.plan == SubscriptionPlan.plus;

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
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          final isLoading = state.isCheckoutInProgress;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Crush Plus',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock premium features:\n'
                    '• Unsend messages\n'
                    '• Unlimited Likes\n'
                    '• Passport to swipe anywhere\n'
                    '• See who liked you and more.',
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context
                                  .read<SubscriptionBloc>()
                                  .add(PlusCheckoutRequested());
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Upgrade to Plus'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Maybe later'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
