import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log out')),
      body: Padding(
        padding: DsEdgeInsets.allXxl,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.unauthenticated ||
                state.status == AuthStatus.unknown) {
              // Redirect to auth gateway (login/signup choice) instead of phone auth
              context.go(CrushRoutes.authGateway);
            }
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            final email = state.user?.email;
            final username = state.user?.username;
            final identifier = username ?? email ?? 'your account';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DsColors.primary.withValues(alpha: 0.1),
                        DsColors.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 36,
                    color: DsColors.primary,
                  ),
                ),
                DsGap.xxl,
                Text(
                  'Ready to log out?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DsGap.md,
                Text(
                  'You are signed in as $identifier.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DsColors.textMutedLight,
                  ),
                ),
                DsGap.md,
                Container(
                  padding: DsEdgeInsets.allLg,
                  decoration: BoxDecoration(
                    color: DsColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DsColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: DsColors.warning,
                      ),
                      DsGap.mdH,
                      Expanded(
                        child: Text(
                          'Logging out will pause new matches and messages until you return.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DsColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isLoading
                        ? null
                        : () => context.read<AuthBloc>().add(AuthSignedOut()),
                    style: FilledButton.styleFrom(
                      backgroundColor: DsColors.error,
                      padding: DsEdgeInsets.buttonPadding,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DsColors.surfaceLight,
                            ),
                          )
                        : const Text('Log out'),
                  ),
                ),
                DsGap.md,
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: state.isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: DsEdgeInsets.buttonPadding,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                DsGap.lg,
              ],
            );
          },
        ),
      ),
    );
  }
}
