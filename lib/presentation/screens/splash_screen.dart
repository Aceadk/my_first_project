import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  static const _fallbackDelay = Duration(seconds: 2);
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
            state.status == AuthStatus.emailOtpSent ||
            state.status == AuthStatus.unknown) {
          _navigateTo(CrushRoutes.authGateway);
        }
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
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }
}
