import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/features/auth/presentation/bloc/biometric_cubit.dart';
import 'package:crushhour/features/auth/presentation/screens/pin_fallback_screen.dart';

/// A full-screen overlay that handles biometric authentication flow.
///
/// Shows biometric prompt → on failure shows PIN → on PIN failure locks out.
/// Wraps around the main app content and blocks access until authenticated.
class BiometricGate extends StatelessWidget {
  const BiometricGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BiometricCubit, BiometricState>(
      builder: (context, state) {
        switch (state.status) {
          // States where the app is accessible
          case BiometricStatus.initial:
          case BiometricStatus.checking:
          case BiometricStatus.disabled:
          case BiometricStatus.unavailable:
          case BiometricStatus.authenticated:
            return child;

          // Biometric prompt needed
          case BiometricStatus.enabled:
          case BiometricStatus.authenticating:
          case BiometricStatus.failed:
            return _BiometricPromptScreen(
              biometricTypeName: state.biometricTypeName,
              errorMessage: state.errorMessage,
            );

          // PIN fallback
          case BiometricStatus.pinRequired:
            return PinFallbackScreen(
              isSetup: false,
              onAuthenticated: () {},
              onLocked: () {},
            );

          // PIN setup needed
          case BiometricStatus.pinSetupRequired:
            return PinFallbackScreen(isSetup: true, onAuthenticated: () {});

          // Locked out — require full password login
          case BiometricStatus.locked:
            return _LockedScreen(errorMessage: state.errorMessage);
        }
      },
    );
  }
}

/// Prompt screen shown when biometric authentication is needed.
class _BiometricPromptScreen extends StatelessWidget {
  const _BiometricPromptScreen({
    required this.biometricTypeName,
    this.errorMessage,
  });

  final String biometricTypeName;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DsSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  biometricTypeName == 'Face ID'
                      ? Icons.face
                      : Icons.fingerprint,
                  size: 80,
                  color: DsColors.primary,
                ),
                const SizedBox(height: DsSpacing.lg),
                Text(
                  'Unlock Crush',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? DsColors.textPrimaryDark
                        : DsColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                Text(
                  'Use $biometricTypeName to unlock',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: DsSpacing.lg),
                  Text(
                    errorMessage!,
                    style: const TextStyle(fontSize: 14, color: DsColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: DsSpacing.xxl),
                ElevatedButton(
                  onPressed: () {
                    context.read<BiometricCubit>().authenticateWithBiometric();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DsColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.xl,
                      vertical: DsSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Unlock with $biometricTypeName'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen shown when the user is locked out after too many failed attempts.
class _LockedScreen extends StatelessWidget {
  const _LockedScreen({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DsSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: DsColors.error),
                const SizedBox(height: DsSpacing.lg),
                Text(
                  'Account Locked',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? DsColors.textPrimaryDark
                        : DsColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                Text(
                  errorMessage ??
                      'Too many failed attempts. Please sign in with your password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
