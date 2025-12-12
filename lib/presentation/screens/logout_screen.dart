import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../core/router.dart';
import '../widgets/primary_button.dart';
import '../../core/ui/snackbar_utils.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log out')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.unauthenticated ||
                state.status == AuthStatus.unknown) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                CrushRoutes.phoneAuth,
                (route) => false,
              );
            }
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            final phoneNumber = state.user?.phoneNumber;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to log out?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  phoneNumber != null
                      ? 'You are signed in as $phoneNumber.'
                      : 'You are signed in.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'You can sign back in with your phone number anytime. '
                  'Logging out will pause new matches and messages until you return.',
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Log out',
                  loading: state.isLoading,
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthSignedOut());
                  },
                ),
                TextButton(
                  onPressed:
                      state.isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
