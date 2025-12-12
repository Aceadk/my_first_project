import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../core/router.dart';
import '../widgets/primary_button.dart';
import '../../core/ui/snackbar_utils.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _bioController = TextEditingController();
  final _jobController = TextEditingController();
  final _companyController = TextEditingController();
  final _schoolController = TextEditingController();
  final _interestsController = TextEditingController();
  final _imagePicker = ImagePicker();

  List<String> _photoPaths = [];

  Future<void> _pickPhotos() async {
    try {
      final results = await _imagePicker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1440,
      );
      if (!mounted) return;
      if (results.isNotEmpty) {
        setState(() {
          _photoPaths = results.map((file) => file.path).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to pick photos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.user != null) {
            Navigator.pushReplacementNamed(context, CrushRoutes.home);
          }
          final error = state.errorMessage;
          if (error != null && error.isNotEmpty) {
            showErrorSnackBar(context, error);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final saving = state.isSaving;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                        ),
                      ),
                      TextField(
                        controller: _jobController,
                        decoration:
                            const InputDecoration(labelText: 'Job title'),
                      ),
                      TextField(
                        controller: _companyController,
                        decoration: const InputDecoration(labelText: 'Company'),
                      ),
                      TextField(
                        controller: _schoolController,
                        decoration: const InputDecoration(labelText: 'School'),
                      ),
                      TextField(
                        controller: _interestsController,
                        decoration: const InputDecoration(
                            labelText: 'Interests (comma separated)'),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._photoPaths.map(
                              (path) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(path),
                                  width: 90,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: saving ? null : _pickPhotos,
                              child: Container(
                                width: 90,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.add_a_photo_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Finish',
                        loading: saving,
                        onPressed: () {
                          if (saving) return;
                          final interests = _interestsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          context.read<ProfileBloc>().add(
                                ProfileDetailsSubmitted(
                                  bio: _bioController.text.trim(),
                                  photoUrls: _photoPaths,
                                  jobTitle: _jobController.text.trim(),
                                  company: _companyController.text.trim(),
                                  school: _schoolController.text.trim(),
                                  interests: interests,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (saving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black
                        .withAlpha((0.08 * 255).round()),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
