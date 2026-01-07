import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing_widgets.dart';

class AuthGatewayScreen extends StatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  State<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends State<AuthGatewayScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

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

    // Continuous pulse/glow animation (heartbeat effect)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: DsEdgeInsets.allXxl,
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo/Brand section
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DsColors.primary, DsColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: DsColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              DsGap.xxl,
              // Glowing pulse animated text
              AnimatedBuilder(
                animation: Listenable.merge([_fadeAnimation, _pulseAnimation]),
                builder: (context, child) {
                  // Calculate glow intensity based on pulse
                  final glowIntensity = 8.0 + (_pulseAnimation.value * 16.0);
                  final glowOpacity = 0.4 + (_pulseAnimation.value * 0.3);
                  final scale = 1.0 + (_pulseAnimation.value * 0.03);

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: scale,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            DsColors.primary,
                            Color.lerp(
                              DsColors.primary,
                              DsColors.secondary,
                              _pulseAnimation.value,
                            )!,
                            DsColors.secondary,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Crush',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: DsColors.primary
                                    .withValues(alpha: glowOpacity),
                                blurRadius: glowIntensity,
                              ),
                              Shadow(
                                color: DsColors.secondary
                                    .withValues(alpha: glowOpacity * 0.7),
                                blurRadius: glowIntensity * 1.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              DsGap.sm,
              Text(
                'Find your perfect match',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => context.push(CrushRoutes.signUp),
                  style: FilledButton.styleFrom(
                    backgroundColor: DsColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DsGap.md,
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => context.push(CrushRoutes.login),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          isDark ? DsColors.borderDark : DsColors.borderLight,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? DsColors.textPrimaryDark
                          : DsColors.textPrimaryLight,
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
