import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/theme/theme_extensions.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';

class AuthGatewayScreen extends StatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  State<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends State<AuthGatewayScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isAppleLoading = false;

  @override
  void initState() {
    super.initState();

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Start animations
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Shows the age gate dialog before allowing signup
  Future<void> _showAgeGate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AgeGateDialog(),
    );

    if (confirmed == true && mounted) {
      context.push(CrushRoutes.signUp);
    }
  }

  Future<void> _signInWithApple() async {
    if (_isAppleLoading) return;

    setState(() => _isAppleLoading = true);
    final authRepo = context.read<AuthRepository>();
    final result = await Result.guard(
      () => authRepo.signInWithApple(),
      logLabel: 'AuthRepository.signInWithApple',
      fallbackError: 'Apple Sign-In failed. Please try again.',
    );

    if (!mounted) return;
    setState(() => _isAppleLoading = false);

    if (!result.isSuccess) {
      showErrorSnackBar(
        context,
        result.errorMessage ?? 'Apple Sign-In failed. Please try again.',
      );
      return;
    }

    final user = result.data;
    if (user?.email != null &&
        user!.email!.isNotEmpty &&
        !user.isEmailVerified) {
      context.go('${CrushRoutes.emailProtection}?redirect=1');
      return;
    }
    context.go(CrushRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandGradient =
        Theme.of(context).extension<CrushThemeEffects>()?.primaryGradient ??
        DsGradients.primaryHorizontal;
    final authRepo = context.read<AuthRepository>();
    final showAppleButton =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        authRepo.supportsAppleSignIn;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: DsEdgeInsets.allXxl,
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Brand header (matches splash wordmark)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = math.min(
                          constraints.maxWidth * 0.8,
                          320.0,
                        );
                        final fontSize = maxWidth * 0.23;
                        final wordmarkStyle = Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.0,
                              color: Colors.white,
                            );

                        return SizedBox(
                          width: maxWidth,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                brandGradient.createShader(bounds),
                            child: Text(
                              'Crush',
                              textAlign: TextAlign.center,
                              style: wordmarkStyle,
                            ),
                          ),
                        );
                      },
                    ),
                    DsGap.sm,
                    Text(
                      'Find your Perfect Match',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              // Features highlights
              _FeatureRow(
                icon: Icons.verified_user_outlined,
                text: 'Verified profiles for safety',
                isDark: isDark,
              ),
              DsGap.md,
              _FeatureRow(
                icon: Icons.chat_bubble_outline,
                text: 'Send messages before matching',
                isDark: isDark,
              ),
              DsGap.md,
              _FeatureRow(
                icon: Icons.location_on_outlined,
                text: 'Meet people near you',
                isDark: isDark,
              ),
              const Spacer(flex: 2),
              // Auth buttons
              Semantics(
                button: true,
                label: context.l10n.authCreateAccount,
                child: SizedBox(
                  width: double.infinity,
                  child: GlassPrimaryButton(
                    onPressed: _showAgeGate,
                    isExpanded: true,
                    child: Text(
                      context.l10n.authCreateAccount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              DsGap.md,
              Semantics(
                button: true,
                label: context.l10n.authSignIn,
                child: SizedBox(
                  width: double.infinity,
                  child: GlassOutlinedButton(
                    onPressed: () => context.push(CrushRoutes.login),
                    isExpanded: true,
                    child: Text(
                      context.l10n.authSignIn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (showAppleButton) ...[
                DsGap.md,
                Semantics(
                  button: true,
                  label: 'Continue with Apple',
                  child: SizedBox(
                    width: double.infinity,
                    child: GlassOutlinedButton(
                      onPressed: _isAppleLoading ? null : _signInWithApple,
                      backgroundColor: Colors.black,
                      borderColor: Colors.black,
                      isExpanded: true,
                      isLoading: _isAppleLoading,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Continue with Apple',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              DsGap.xxl,
              // Terms text
              Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
              ),
              DsGap.lg,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DsColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: DsColors.primary, size: 20),
        ),
        DsGap.mdH,
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? DsColors.textPrimaryDark
                  : DsColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

/// Age Gate Dialog - Required for dating app store compliance
/// Shows before signup to confirm user is 18 or older
class _AgeGateDialog extends StatelessWidget {
  const _AgeGateDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: DsEdgeInsets.allXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DsColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 36,
                color: DsColors.primary,
              ),
            ),
            DsGap.xl,
            // Title
            Text(
              'Age Verification',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            DsGap.md,
            // Description
            Text(
              'Crush is a dating app for adults only. You must be at least 18 years old to create an account.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            DsGap.xxl,
            // Question
            Text(
              'Are you 18 years or older?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            DsGap.xl,
            // Buttons
            Row(
              children: [
                Expanded(
                  child: GlassOutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: isDark
                            ? DsColors.textPrimaryDark
                            : DsColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
                DsGap.mdH,
                Expanded(
                  child: GlassPrimaryButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes, I am 18+'),
                  ),
                ),
              ],
            ),
            DsGap.lg,
            // Legal notice
            Text(
              'By continuing, you confirm that you are at least 18 years old and agree to our Terms of Service.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
