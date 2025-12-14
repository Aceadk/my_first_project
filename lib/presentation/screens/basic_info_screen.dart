import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../core/router.dart';
import '../widgets/primary_button.dart';
import '../../core/ui/snackbar_utils.dart';
import '../widgets/onboarding_progress.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'female';
  String? _orientation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic info')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) =>
              previous.user != current.user ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.user != null) {
              Navigator.pushReplacementNamed(
                  context, CrushRoutes.idVerification);
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
                    children: [
                      const OnboardingProgress(
                        currentStep: 3,
                        caption: 'Tell us about you to personalize matches',
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: _ageController,
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        value: _gender,
                        items: const [
                          DropdownMenuItem(
                              value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'nonbinary', child: Text('Non-binary')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gender = value ?? 'female';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                            labelText: 'Sexual orientation (optional)'),
                        onChanged: (value) => _orientation = value,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Continue',
                        loading: isBusy,
                        onPressed: () {
                          final age = int.tryParse(_ageController.text) ?? 0;
                          context.read<ProfileBloc>().add(
                                ProfileBasicInfoSubmitted(
                                  name: _nameController.text.trim(),
                                  age: age,
                                  gender: _gender,
                                  sexualOrientation: _orientation,
                                ),
                              );
                        },
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
