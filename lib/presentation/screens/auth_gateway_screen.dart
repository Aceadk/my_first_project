import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../design_system/widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';

class AuthGatewayScreen extends StatelessWidget {
  const AuthGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      centerContent: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to CrushHour',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Log in to your account or create a new one to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Login',
            onPressed: () => context.push(CrushRoutes.login),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Sign Up',
            onPressed: () => context.push(CrushRoutes.signUp),
          ),
        ],
      ),
    );
  }
}
