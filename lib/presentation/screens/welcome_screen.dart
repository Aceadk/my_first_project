import 'package:flutter/material.dart';
import '../../core/router.dart';
import '../widgets/onboarding_progress.dart';
import '../widgets/onboarding_nav_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingProgress(currentStep: 0),
            const SizedBox(height: 24),
            Text(
              'Welcome to CrushHour',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Location-based, double opt-in hookups with verified profiles and strong safety.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OnboardingNavButtons(
              showBack: false,
              nextLabel: 'Continue with phone',
              onNext: () {
                Navigator.pushNamed(context, CrushRoutes.phoneAuth);
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, CrushRoutes.emailAuth);
              },
              child: const Text('Use email instead'),
            ),
          ],
        ),
      ),
    );
  }
}
