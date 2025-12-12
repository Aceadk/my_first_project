import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../core/router.dart';
import '../../core/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (CrushConstants.skipAuthInDev) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, CrushRoutes.home);
      });
    }

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, current) => prev.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.pushReplacementNamed(context, CrushRoutes.home);
        } else if (state.status == AuthStatus.unauthenticated ||
            state.status == AuthStatus.otpSent ||
            state.status == AuthStatus.unknown) {
          Navigator.pushReplacementNamed(context, CrushRoutes.welcome);
        }
      },
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
