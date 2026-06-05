import 'dart:async';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
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
          return Scaffold(
            backgroundColor: const Color(0xFF0D0E12),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final viewportAspect =
                    constraints.maxWidth / constraints.maxHeight;
                final fit = viewportAspect > 0.95
                    ? BoxFit.contain
                    : BoxFit.cover;

                return Semantics(
                  label: 'Crush',
                  image: true,
                  child: FadeTransition(
                    opacity: _screenFadeAnimation,
                    child: Image.asset(
                      'assets/icons/splash_screen.png',
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: fit,
                      alignment: Alignment.center,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
