import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/theme/theme_extensions.dart';

class AuthGatewayScreen extends StatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  State<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends State<AuthGatewayScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandGradient =
        Theme.of(context).extension<CrushThemeEffects>()?.primaryGradient ??
            DsGradients.primaryHorizontal;

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
                        final maxWidth =
                            math.min(constraints.maxWidth * 0.8, 320.0);
                        final fontSize = maxWidth * 0.23;
                        final wordmarkStyle =
                            Theme.of(context).textTheme.titleLarge?.copyWith(
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
                    onPressed: () => context.push(CrushRoutes.signUp),
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
          child: Icon(
            icon,
            color: DsColors.primary,
            size: 20,
          ),
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
