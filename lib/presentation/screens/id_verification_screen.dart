import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../core/router.dart';
import '../widgets/primary_button.dart';
import '../../core/ui/snackbar_utils.dart';
import '../widgets/onboarding_progress.dart';
import '../widgets/onboarding_nav_buttons.dart';

class IdVerificationScreen extends StatelessWidget {
  const IdVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your ID')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) =>
              previous.user != current.user ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.user != null && state.user!.isIdVerified) {
              context.go(CrushRoutes.profileSetup);
            }
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            final isBusy = state.isSaving;
            return Stack(
              children: [
                AbsorbPointer(
                  absorbing: isBusy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OnboardingProgress(
                        currentStep: 4,
                        caption: 'Secure your account to unlock chat',
                      ),
                      const SizedBox(height: 20),
                      const Text(
                          'Upload your national ID card/passport for verification. '
                          'Only verified accounts can chat after matching.'),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Upload ID (mock)',
                        loading: isBusy,
                        onPressed: () {
                          context
                              .read<ProfileBloc>()
                              .add(ProfileIdDocumentUploaded());
                        },
                      ),
                      const SizedBox(height: 12),
                      if (state.user != null && state.user!.isIdVerified)
                        const Text(
                          'Verified ✓',
                          style: TextStyle(color: Colors.greenAccent),
                        ),
                      const Spacer(),
                      OnboardingNavButtons(
                        onBack: isBusy
                            ? null
                            : () => context.go(CrushRoutes.basicInfo),
                        onNext: isBusy
                            ? null
                            : () => context.go(CrushRoutes.profileSetup),
                        nextLoading: isBusy,
                      ),
                    ],
                  ),
                ),
                if (isBusy)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
