import 'dart:math' as math;

import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/design_system/design_system.dart'
    hide ExcludeSemantics, MergeSemantics;
import 'package:crushhour/design_system/theme/theme_extensions.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';
import 'package:crushhour/features/auth/presentation/widgets/google_logo_icon.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthGatewayScreen extends StatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  State<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends State<AuthGatewayScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  AuthFlowUseCases _authFlowUseCases() {
    return AuthFlowUseCases(context.read<AuthRepository>());
  }

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

    if (!mounted) return;

    if (confirmed == true) {
      context.push(CrushRoutes.signUp);
      return;
    }

    if (confirmed == false) {
      showErrorSnackBar(context, context.l10n.authGatewayAgeUnderageError);
    }
  }

  Future<void> _signInWithApple() async {
    if (_isAppleLoading) return;

    setState(() => _isAppleLoading = true);
    final result = await _authFlowUseCases().signInWithApple();

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

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);
    final result = await _authFlowUseCases().signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (!result.isSuccess) {
      showErrorSnackBar(
        context,
        result.errorMessage ?? 'Google Sign-In failed. Please try again.',
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
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final brandGradient =
        Theme.of(context).extension<CrushThemeEffects>()?.primaryGradient ??
        DsGradients.primaryHorizontal;
    final fadeOpacity = reduceMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : _fadeAnimation;
    final authFlowUseCases = _authFlowUseCases();
    final showGoogleButton = authFlowUseCases.supportsGoogleSignIn;
    final showAppleButton =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        authFlowUseCases.supportsAppleSignIn;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final compactLayout =
                textScale > 1.3 || constraints.maxHeight < 760;
            final headerGap = compactLayout
                ? DsSpacing.lg
                : math.max(DsSpacing.xl, constraints.maxHeight * 0.08);
            final sectionGap = compactLayout ? DsSpacing.xl : DsSpacing.xxxl;
            final footerGap = compactLayout ? DsSpacing.xl : DsSpacing.xxl;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: DsEdgeInsets.allXxl,
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Column(
                  children: [
                    SizedBox(height: headerGap),
                    // Brand header (matches splash wordmark)
                    FadeTransition(
                      opacity: fadeOpacity,
                      child: Semantics(
                        header: true,
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
                                      color: DsColors.surfaceLight,
                                    );

                                return SizedBox(
                                  width: maxWidth,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        brandGradient.createShader(
                                          bounds,
                                          textDirection: Directionality.of(
                                            context,
                                          ),
                                        ),
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
                              l10n.authGatewayTagline,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    // Features highlights
                    _FeatureRow(
                      icon: Icons.verified_user_outlined,
                      text: l10n.authGatewayFeatureVerifiedProfiles,
                      isDark: isDark,
                    ),
                    DsGap.md,
                    _FeatureRow(
                      icon: Icons.chat_bubble_outline,
                      text: l10n.authGatewayFeatureSendMessages,
                      isDark: isDark,
                    ),
                    DsGap.md,
                    _FeatureRow(
                      icon: Icons.location_on_outlined,
                      text: l10n.authGatewayFeatureMeetNearby,
                      isDark: isDark,
                    ),
                    SizedBox(height: sectionGap),
                    // Auth buttons
                    Semantics(
                      button: true,
                      label: context.l10n.authCreateAccount,
                      child: SizedBox(
                        width: double.infinity,
                        child: GlassPrimaryButton(
                          semanticLabel: context.l10n.a11ySignUpButton,
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
                          semanticLabel: context.l10n.a11yLoginButton,
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
                    if (showGoogleButton) ...[
                      DsGap.md,
                      Semantics(
                        button: true,
                        label: l10n.authContinueWithGoogle,
                        child: SizedBox(
                          width: double.infinity,
                          child: GlassOutlinedButton(
                            semanticLabel: l10n.authContinueWithGoogle,
                            onPressed: _isGoogleLoading
                                ? null
                                : _signInWithGoogle,
                            backgroundColor: Colors.white,
                            borderColor: const Color(0xFFDADCE0),
                            isExpanded: true,
                            isLoading: _isGoogleLoading,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const GoogleLogoIcon(size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.authContinueWithGoogle,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1F1F1F),
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
                    if (showAppleButton) ...[
                      DsGap.md,
                      Semantics(
                        button: true,
                        label: l10n.authContinueWithApple,
                        child: SizedBox(
                          width: double.infinity,
                          child: GlassOutlinedButton(
                            semanticLabel: l10n.authContinueWithApple,
                            onPressed: _isAppleLoading
                                ? null
                                : _signInWithApple,
                            backgroundColor: Colors.black,
                            borderColor: Colors.black,
                            isExpanded: true,
                            isLoading: _isAppleLoading,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.apple,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.authContinueWithApple,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
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
                    SizedBox(height: footerGap),
                    // Terms text
                    Semantics(
                      container: true,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                          children: [
                            const TextSpan(
                              text: 'By continuing, you agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: DsColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => launchUrl(
                                  Uri.parse('https://crushhour.app/terms'),
                                  mode: LaunchMode.externalApplication,
                                ),
                            ),
                            const TextSpan(text: '\nand '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: DsColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => launchUrl(
                                  Uri.parse('https://crushhour.app/privacy'),
                                  mode: LaunchMode.externalApplication,
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DsGap.lg,
                  ],
                ),
              ),
            );
          },
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
        ExcludeSemantics(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DsColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DsColors.primary, size: 20),
          ),
        ),
        DsGap.mdH,
        Expanded(
          child: MergeSemantics(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? DsColors.textPrimaryDark
                    : DsColors.textPrimaryLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Age Gate Dialog - Required for dating app store compliance
/// Shows before signup to confirm user is 18 or older
class _AgeGateDialog extends StatefulWidget {
  const _AgeGateDialog();

  @override
  State<_AgeGateDialog> createState() => _AgeGateDialogState();
}

class _AgeGateDialogState extends State<_AgeGateDialog> {
  bool _isSubmitting = false;

  void _submitChoice(bool isEligible) {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    Navigator.of(context).pop(isEligible);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final stackButtons =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: DsEdgeInsets.allXxl,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                ExcludeSemantics(
                  child: Container(
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
                ),
                DsGap.xl,
                // Title
                Semantics(
                  header: true,
                  child: Text(
                    l10n.authGatewayAgeVerificationTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                DsGap.md,
                // Description
                Text(
                  l10n.authGatewayAgeVerificationDescription,
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
                  l10n.authGatewayAgeVerificationQuestion,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                DsGap.xl,
                // Buttons
                if (stackButtons)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: GlassOutlinedButton(
                          semanticLabel: l10n.commonNo,
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitChoice(false),
                          child: Text(
                            l10n.commonNo,
                            style: TextStyle(
                              color: isDark
                                  ? DsColors.textPrimaryDark
                                  : DsColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ),
                      DsGap.md,
                      SizedBox(
                        width: double.infinity,
                        child: GlassPrimaryButton(
                          semanticLabel: l10n.yesIAm18,
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitChoice(true),
                          child: Text(l10n.yesIAm18),
                        ),
                      ),
                    ],
                  ),
                if (!stackButtons)
                  Row(
                    children: [
                      Expanded(
                        child: GlassOutlinedButton(
                          semanticLabel: l10n.commonNo,
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitChoice(false),
                          child: Text(
                            l10n.commonNo,
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
                          semanticLabel: l10n.yesIAm18,
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitChoice(true),
                          child: Text(l10n.yesIAm18),
                        ),
                      ),
                    ],
                  ),
                DsGap.lg,
                // Legal notice
                Text(
                  l10n.authGatewayAgeVerificationLegalNotice,
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
        ),
      ),
    );
  }
}
