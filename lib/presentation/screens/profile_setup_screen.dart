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
  List<String> _videoPaths = [];

  Future<void> _pickPhotos() async {
    try {
      final results = await _imagePicker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1440,
      );
      if (!mounted) return;
      if (results.isNotEmpty) {
        final remainingPhotos = 9 - _photoPaths.length;
        if (remainingPhotos <= 0) {
          showErrorSnackBar(
              context, 'You can add up to 9 photos (and 3 videos).');
          return;
        }
        final selected = results.take(remainingPhotos).toList();
        setState(() {
          _photoPaths = [
            ..._photoPaths,
            ...selected.map((file) => file.path),
          ];
        });
        if (results.length > selected.length) {
          showErrorSnackBar(
            context,
            'Only $remainingPhotos more photo slots available (max 9).',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to pick photos: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final remainingVideos = 3 - _videoPaths.length;
      if (remainingVideos <= 0) {
        showErrorSnackBar(
          context,
          'You can add up to 3 videos (and 9 photos).',
        );
        return;
      }
      final result = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );
      if (!mounted || result == null) return;
      setState(() {
        _videoPaths = [..._videoPaths, result.path];
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to pick video: $e');
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
                            ..._videoPaths.map(
                              (path) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 120,
                                      color: Colors.black12,
                                      child: const Center(
                                        child: Icon(Icons.videocam),
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Video',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                            GestureDetector(
                              onTap: saving ? null : _pickVideo,
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
                                child: const Icon(Icons.videocam_outlined),
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
                          if (_photoPaths.isEmpty) {
                            showErrorSnackBar(
                              context,
                              'Add at least one photo to finish your profile.',
                            );
                            return;
                          }
                          final interests = _interestsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          context.read<ProfileBloc>().add(
                                ProfileDetailsSubmitted(
                                  bio: _bioController.text.trim(),
                                  photoUrls: _photoPaths,
                                  videoUrls: _videoPaths,
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
