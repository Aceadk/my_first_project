import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import '../../core/router.dart';
import 'package:crushhour/core/utils/constants.dart';
import '../../design_system/tokens/colors.dart';

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

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _companyFadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _companyFadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Main content fade in
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutBack,
    ));

    // Pulse animation for the heart
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Company name fade in (delayed)
    _companyFadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _companyFadeAnimation = CurvedAnimation(
      parent: _companyFadeController,
      curve: Curves.easeOut,
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _companyFadeController.forward();
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

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _companyFadeController.dispose();
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
      listenWhen: (prev, current) => prev.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          final user = state.user;
          // User is verified if EITHER email OR phone is verified
          if (user != null && user.isAccountVerified) {
            // Account is verified (email or phone), go directly to home
            _setNavigationTarget(CrushRoutes.home);
          } else if (user?.email != null && user!.email!.isNotEmpty) {
            // Has email but not verified, and phone not verified - show email protection
            _setNavigationTarget(CrushRoutes.emailProtection, arguments: true);
          } else {
            // No verification yet, but authenticated - go to home
            // They can verify from settings or will be prompted when swiping
            _setNavigationTarget(CrushRoutes.home);
          }
        } else if (state.status == AuthStatus.unauthenticated ||
            state.status == AuthStatus.otpSent ||
            state.status == AuthStatus.emailLinkSent ||
            state.status == AuthStatus.emailOtpSent) {
          _setNavigationTarget(CrushRoutes.authGateway);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Main content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated heart logo
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      DsColors.primary,
                                      DsColors.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: DsColors.primary
                                          .withValues(alpha: 0.5),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // App name with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Colors.white,
                              Color(0xFFE8E8E8),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'Crush',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tagline
                        Text(
                          'Find your perfect match',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                // Company branding at bottom
                FadeTransition(
                  opacity: _companyFadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'From',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            DsColors.primary.withValues(alpha: 0.9),
                            DsColors.secondary.withValues(alpha: 0.9),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Ace',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
