import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/design_system/theme/theme_extensions.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Minimum time to show splash before navigating
  static const _minimumSplashDuration = Duration(seconds: 3);
  // Max time to wait for auth before forcing navigation
  static const _fallbackDelay = Duration(seconds: 8);

  Timer? _fallbackTimer;
  bool _didNavigate = false;
  bool _minimumTimeElapsed = false;
  String? _pendingRoute;
  Object? _pendingArguments;

  // Animation timeline controller
  late AnimationController _timelineController;

  late Animation<double> _screenFadeAnimation;
  late Animation<double> _strokeAnimation;
  late Animation<double> _fillFadeAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<Offset> _taglineSlideAnimation;
  late Animation<double> _companyFadeAnimation;

  Timer? _animationFallbackTimer;

  @override
  void initState() {
    super.initState();

    _timelineController = AnimationController(
      duration: const Duration(milliseconds: 1900),
      vsync: this,
    );

    // Subtle screen fade-in (0.0s -> 0.15s)
    _screenFadeAnimation = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    );

    // Main stroke reveal (0.1s -> 1.6s)
    _strokeAnimation = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.05, 0.85, curve: Curves.easeInOutCubic),
    );

    // Fill fade-in at the end of the stroke (1.5s -> 1.8s)
    _fillFadeAnimation = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.78, 0.95, curve: Curves.easeOut),
    );

    // Tagline fade + slide (1.2s -> 1.9s)
    _taglineFadeAnimation = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.63, 1.0, curve: Curves.easeOut),
    );
    _taglineSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _timelineController,
            curve: const Interval(0.63, 1.0, curve: Curves.easeOut),
          ),
        );

    // "From Ace" fade (1.3s -> 1.8s)
    _companyFadeAnimation = CurvedAnimation(
      parent: _timelineController,
      curve: const Interval(0.7, 0.95, curve: Curves.easeOut),
    );

    // Fallback: ensure static logo shows after 3 seconds
    _animationFallbackTimer = Timer(_minimumSplashDuration, () {
      if (mounted && !_timelineController.isCompleted) {
        _timelineController.value = 1.0;
      }
    });

    // Start minimum time timer
    Future.delayed(_minimumSplashDuration, () {
      if (mounted) {
        setState(() => _minimumTimeElapsed = true);
        _tryNavigate();
      }
    });

    if (CrushConstants.skipAuthInDev) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _pendingRoute = CrushRoutes.home;
        _tryNavigate();
      });
      return;
    }

    _fallbackTimer = Timer(_fallbackDelay, () {
      _pendingRoute = CrushRoutes.authGateway;
      _tryNavigate();
    });
  }

  bool _animationsStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationsStarted) {
      _animationsStarted = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _timelineController.value = 1.0;
      } else {
        _timelineController.forward();
      }
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _animationFallbackTimer?.cancel();
    _timelineController.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    if (_didNavigate || !mounted) return;
    if (!_minimumTimeElapsed) return;
    if (_pendingRoute == null) return;

    _didNavigate = true;
    _fallbackTimer?.cancel();

    if (_pendingRoute == CrushRoutes.emailProtection &&
        _pendingArguments is bool) {
      final suffix = (_pendingArguments as bool) ? '?redirect=1' : '';
      context.go('$_pendingRoute$suffix');
      return;
    }
    context.go(_pendingRoute!);
  }

  void _setNavigationTarget(String route, {Object? arguments}) {
    _pendingRoute = route;
    _pendingArguments = arguments;
    _tryNavigate();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, current) =>
          prev.status != current.status || prev.user != current.user,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          final user = state.user;

          // Check onboarding steps in order (same as router)
          // 1. Check if user needs to accept terms and conditions
          if (user != null && !user.hasAcceptedTerms) {
            _setNavigationTarget(CrushRoutes.termsConditions);
            return;
          }

          // 2. Check if user needs to complete basic info
          if (user != null &&
              user.hasAcceptedTerms &&
              !user.hasCompletedBasicInfo) {
            _setNavigationTarget(CrushRoutes.basicInfo);
            return;
          }

          // 3. Check if user needs to complete profile setup
          if (user != null &&
              user.hasAcceptedTerms &&
              user.hasCompletedBasicInfo &&
              !user.hasCompletedProfileSetup) {
            _setNavigationTarget(CrushRoutes.profileSetup);
            return;
          }

          // 4. Check if email verification is needed (after completing onboarding)
          if (user != null &&
              user.email != null &&
              user.email!.isNotEmpty &&
              !user.isEmailVerified &&
              user.hasAcceptedTerms &&
              user.hasCompletedBasicInfo &&
              user.hasCompletedProfileSetup) {
            _setNavigationTarget(CrushRoutes.emailVerification);
            return;
          }

          // All onboarding complete - go to home
          _setNavigationTarget(CrushRoutes.home);
        } else if (state.status == AuthStatus.unauthenticated ||
            state.status == AuthStatus.otpSent ||
            state.status == AuthStatus.emailLinkSent ||
            state.status == AuthStatus.emailOtpSent) {
          _setNavigationTarget(CrushRoutes.authGateway);
        }
      },
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final backgroundColor = theme.scaffoldBackgroundColor;
          final mutedColor = theme.colorScheme.onSurface.withValues(
            alpha: 0.55,
          );
          final brandGradient =
              theme.extension<CrushThemeEffects>()?.primaryGradient ??
              DsGradients.primaryHorizontal;

          return Scaffold(
            backgroundColor: backgroundColor,
            body: SafeArea(
              child: FadeTransition(
                opacity: _screenFadeAnimation,
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    // Animated "Crush" wordmark with stroke reveal
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = math.min(
                          constraints.maxWidth * 0.8,
                          320.0,
                        );
                        final fontSize = maxWidth * 0.23;
                        final wordmarkHeight = fontSize * 1.3;

                        final baseStyle =
                            theme.textTheme.titleLarge ??
                            const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            );

                        final wordmarkStyle = baseStyle.copyWith(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                          color: Colors.white,
                        );

                        // Resolve localized text here, NOT in paint()
                        final crushText = AppLocalizations.of(context).crush;

                        return SizedBox(
                          width: maxWidth,
                          height: wordmarkHeight,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                brandGradient.createShader(
                                  bounds,
                                  textDirection: Directionality.of(context),
                                ),
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _strokeAnimation,
                                _fillFadeAnimation,
                              ]),
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _CrushTextStrokePainter(
                                    progress: _strokeAnimation.value,
                                    fillOpacity: _fillFadeAnimation.value,
                                    textStyle: wordmarkStyle,
                                    text: crushText,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Tagline
                    SlideTransition(
                      position: _taglineSlideAnimation,
                      child: FadeTransition(
                        opacity: _taglineFadeAnimation,
                        child: Text(
                          'Find your Perfect Match',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                    // Company branding at bottom
                    FadeTransition(
                      opacity: _companyFadeAnimation,
                      child: Text(
                        'From Ace',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter that draws "Crush" with a flowing stroke reveal animation
class _CrushTextStrokePainter extends CustomPainter {
  final double progress;
  final double fillOpacity;
  final TextStyle textStyle;
  final String text;

  _CrushTextStrokePainter({
    required this.progress,
    required this.fillOpacity,
    required this.textStyle,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(textStyle.getTextStyle())
          ..addText(text);

    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: size.width));

    // Calculate center position
    final textWidth = paragraph.maxIntrinsicWidth;
    final textHeight = paragraph.height;
    final offsetX = (size.width - textWidth) / 2;
    final offsetY = (size.height - textHeight) / 2;

    canvas.save();

    // Stroke reveal effect using clip
    if (progress > 0) {
      // Calculate the reveal width based on progress
      final revealWidth = textWidth * progress;

      // Create clip rect for the stroke reveal
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(offsetX, offsetY - 10, revealWidth, textHeight + 20),
      );

      // Draw stroke outline effect
      final strokePaint = Paint()
        ..color = textStyle.color ?? Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (textStyle.fontSize ?? 56) * 0.045
        ..strokeCap = StrokeCap.round;

      // Create a paragraph with stroke style
      final strokeStyle = textStyle
          .copyWith(foreground: strokePaint)
          .getTextStyle();

      final strokeBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
            ..pushStyle(strokeStyle)
            ..addText(text);

      final strokeParagraph = strokeBuilder.build();
      strokeParagraph.layout(ui.ParagraphConstraints(width: size.width));

      canvas.drawParagraph(strokeParagraph, Offset(offsetX, offsetY));
      canvas.restore();
    }

    // Filled text (fades in after stroke completes)
    if (fillOpacity > 0) {
      final fillStyle = textStyle
          .copyWith(
            color: (textStyle.color ?? Colors.white).withValues(
              alpha: fillOpacity,
            ),
          )
          .getTextStyle();

      final fillBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
            ..pushStyle(fillStyle)
            ..addText(text);

      final fillParagraph = fillBuilder.build();
      fillParagraph.layout(ui.ParagraphConstraints(width: size.width));

      canvas.drawParagraph(fillParagraph, Offset(offsetX, offsetY));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CrushTextStrokePainter oldDelegate) {
    return progress != oldDelegate.progress ||
        fillOpacity != oldDelegate.fillOpacity ||
        textStyle != oldDelegate.textStyle ||
        text != oldDelegate.text;
  }
}
