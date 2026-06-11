import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).logOut)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: Padding(
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
                  final l10n = AppLocalizations.of(context);
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final email = state.user?.email;
                  final username = state.user?.username;
                  final identifier =
                      username ?? email ?? l10n.logoutYourAccountFallback;

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
                        l10n.logoutReadyTitle,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      DsGap.md,
                      Text(
                        l10n.logoutSignedInAs(identifier),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
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
                                l10n.logoutPauseWarning,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: DsColors.warning),
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
                              : () => context.read<AuthBloc>().add(
                                  AuthSignedOut(),
                                ),
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
                              : Text(AppLocalizations.of(context).logOut),
                        ),
                      ),
                      DsGap.md,
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          // /logout is directly addressable (deep link / URL),
                          // so there may be nothing on the stack to pop.
                          onPressed: state.isLoading
                              ? null
                              : () => context.canPop()
                                    ? context.pop()
                                    : context.go(CrushRoutes.home),
                          style: OutlinedButton.styleFrom(
                            padding: DsEdgeInsets.buttonPadding,
                          ),
                          child: Text(AppLocalizations.of(context).cancel),
                        ),
                      ),
                      DsGap.lg,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
