import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<SubscriptionBloc, SubscriptionState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            final isPlus = state.plan == SubscriptionPlan.plus;
            final isLoading = state.isCheckoutInProgress;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current plan: ${isPlus ? 'Plus' : 'Free'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (!isPlus)
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
                          : const Text('Upgrade to CrushHour Plus'),
                    ),
                  )
                else
                  const Text(
                    'You have CrushHour Plus. Enjoy unlimited likes and unsend.',
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
