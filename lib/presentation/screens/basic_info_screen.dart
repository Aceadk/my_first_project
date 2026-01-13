import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
import '../widgets/onboarding_progress.dart';
import '../widgets/onboarding_nav_buttons.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'female';
  String? _orientation;
  bool _usernameTouched = false;
  bool _ageTouched = false;
  bool _hasShownAgeWarning = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

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
              context.go(CrushRoutes.idVerification);
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
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          helperText: '3-20 characters, letters, numbers, or underscore.',
                          errorText: _usernameErrorText(),
                        ),
                        onTap: () => _markUsernameTouched(),
                        onChanged: (_) => _markUsernameTouched(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          helperText: 'Must be between 18 and 75',
                          errorText: _ageErrorText(),
                        ),
                        keyboardType: TextInputType.number,
                        onTap: () => _markAgeTouched(),
                        onChanged: (_) => _markAgeTouched(),
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
                      OnboardingNavButtons(
                        onBack: isBusy ? null : _goBack,
                        onNext: isBusy
                            ? null
                            : () async {
                                setState(() {
                                  _usernameTouched = true;
                                  _ageTouched = true;
                                });
                                final usernameError = _usernameErrorText();
                                if (usernameError != null) {
                                  showErrorSnackBar(context, usernameError);
                                  return;
                                }
                                final ageError = _ageErrorText();
                                if (ageError != null) {
                                  showErrorSnackBar(context, ageError);
                                  return;
                                }
                                final age =
                                    int.tryParse(_ageController.text) ?? 0;
                                final profileBloc = context.read<ProfileBloc>();
                                // Show warning for users aged 70-75
                                final proceed = await _showAgeWarningIfNeeded(age);
                                if (!proceed) return;
                                if (!mounted) return;
                                profileBloc.add(
                                      ProfileBasicInfoSubmitted(
                                        username:
                                            _usernameController.text.trim(),
                                        name: _nameController.text.trim(),
                                        age: age,
                                        gender: _gender,
                                        sexualOrientation: _orientation,
                                      ),
                                    );
                              },
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

  void _goBack() {
    final phone = context.read<AuthBloc>().state.phoneInProgress;
    if (phone != null && phone.isNotEmpty) {
      final encoded = Uri.encodeComponent(phone);
      context.go('${CrushRoutes.otp}?phone=$encoded');
    } else {
      context.go(CrushRoutes.phoneAuth);
    }
  }

  void _markUsernameTouched() {
    if (!_usernameTouched) {
      setState(() {
        _usernameTouched = true;
      });
    }
  }

  String? _usernameErrorText() {
    if (!_usernameTouched) return null;
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      return 'Choose a username to continue';
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
    if (!valid) {
      return 'Use 3-20 letters, numbers, or underscore';
    }
    return null;
  }

  void _markAgeTouched() {
    if (!_ageTouched) {
      setState(() {
        _ageTouched = true;
      });
    }
  }

  String? _ageErrorText() {
    if (!_ageTouched) return null;
    final ageText = _ageController.text.trim();
    if (ageText.isEmpty) {
      return 'Enter your age';
    }
    final age = int.tryParse(ageText);
    if (age == null) {
      return 'Enter a valid number';
    }
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    if (age > 75) {
      return 'Maximum age allowed is 75';
    }
    return null;
  }

  Future<bool> _showAgeWarningIfNeeded(int age) async {
    if (age >= 70 && age <= 75 && !_hasShownAgeWarning) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.elderly, color: Colors.orange, size: 48),
          title: const Text('Age Notice'),
          content: const Text(
            'You\'re a bit too old to be using a dating app, don\'t you think?\n\n'
            'Just kidding! Love has no age limit. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Go Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );
      if (proceed == true) {
        _hasShownAgeWarning = true;
        return true;
      }
      return false;
    }
    return true;
  }
}
