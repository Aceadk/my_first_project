import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../core/router.dart';
import '../../core/constants.dart';
import '../widgets/onboarding_progress.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Give enough time for Firebase to restore session from secure storage
  static const _fallbackDelay = Duration(seconds: 5);
  Timer? _fallbackTimer;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    if (CrushConstants.skipAuthInDev) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _navigateTo(CrushRoutes.home);
      });
      return;
    }

    _fallbackTimer = Timer(_fallbackDelay, () {
      _navigateTo(CrushRoutes.authGateway);
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, current) => prev.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          final user = state.user;
          if (user?.email != null &&
              user!.email!.isNotEmpty &&
              !user.isEmailVerified) {
            _navigateTo(CrushRoutes.emailProtection, arguments: true);
          } else {
            _navigateTo(CrushRoutes.home);
          }
        } else if (state.status == AuthStatus.unauthenticated ||
            state.status == AuthStatus.otpSent ||
            state.status == AuthStatus.emailLinkSent ||
            state.status == AuthStatus.emailOtpSent) {
          // Only navigate when we know the user is NOT authenticated.
          // Don't navigate on 'unknown' - that means auth is still loading.
          _navigateTo(CrushRoutes.authGateway);
        }
        // When status is 'unknown', stay on splash and wait for auth to resolve.
      },
      child: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                OnboardingProgress(
                  currentStep: 0,
                  caption: 'Loading your session…',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(String route, {Object? arguments}) {
    if (_didNavigate || !mounted) return;
    _didNavigate = true;
    _fallbackTimer?.cancel();
    if (route == CrushRoutes.emailProtection && arguments is bool) {
      final suffix = arguments ? '?redirect=1' : '';
      context.go('$route$suffix');
      return;
    }
    context.go(route);
  }
}
