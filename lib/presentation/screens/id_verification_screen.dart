import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../core/router.dart';
import '../widgets/primary_button.dart';
import '../../core/ui/snackbar_utils.dart';

class IdVerificationScreen extends StatelessWidget {
  const IdVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your ID')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.user != null && state.user!.isIdVerified) {
              Navigator.pushReplacementNamed(context, CrushRoutes.profileSetup);
            }
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Upload your national ID card/passport for verification. '
                    'Only verified accounts can chat after matching.'),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Upload ID (mock)',
                  loading: state.isSaving,
                  onPressed: () {
                    if (state.isSaving) return;
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
                PrimaryButton(
                  label: 'Skip for now (not recommended)',
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, CrushRoutes.profileSetup);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
