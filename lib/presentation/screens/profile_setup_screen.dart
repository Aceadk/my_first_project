import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../core/profile_media_limits.dart';
import '../../data/services/profile_media_service.dart';
import 'package:crushhour/core/utils/result.dart';
import '../widgets/profile_media_picker.dart';
import '../widgets/onboarding_progress.dart';
import '../widgets/onboarding_nav_buttons.dart';

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
  final _mediaService = ProfileMediaService();

  List<String> _photoPaths = [];
  List<String> _videoPaths = [];
  bool _uploading = false;

  Future<void> _submit(ProfileState state) async {
    if (_uploading || state.isSaving) return;
    if (_photoPaths.length < ProfileMediaLimits.minPhotos) {
      showErrorSnackBar(
        context,
        'Add at least one photo to finish your profile.',
      );
      return;
    }

    final userId = state.user?.id;
    if (userId == null) {
      showErrorSnackBar(context, 'You need to be signed in to continue.');
      return;
    }

    setState(() => _uploading = true);
    final uploadResult = await Result.guard(
      () => _mediaService.ensureRemoteUrls(
        userId: userId,
        photoPaths: _photoPaths,
        videoPaths: _videoPaths,
      ),
      logLabel: 'ProfileMediaService.ensureRemoteUrls',
      fallbackError: 'Could not upload media.',
    );
    if (!mounted) return;
    if (!uploadResult.isSuccess || uploadResult.data == null) {
      showErrorSnackBar(
        context,
        uploadResult.errorMessage ?? 'Could not upload media.',
      );
      setState(() => _uploading = false);
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
            photoUrls: uploadResult.data!.photoUrls,
            videoUrls: uploadResult.data!.videoUrls,
            jobTitle: _jobController.text.trim(),
            company: _companyController.text.trim(),
            school: _schoolController.text.trim(),
            interests: interests,
          ),
        );
    if (mounted) {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            previous.user != current.user ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.user != null) {
            context.go(CrushRoutes.home);
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

          final saving = state.isSaving || _uploading;

          return Stack(
            children: [
              AbsorbPointer(
                absorbing: saving,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const OnboardingProgress(
                          currentStep: 5,
                          caption: 'Add photos, interests, and a short bio',
                        ),
                        const SizedBox(height: 20),
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
                          decoration:
                              const InputDecoration(labelText: 'Company'),
                        ),
                        TextField(
                          controller: _schoolController,
                          decoration:
                              const InputDecoration(labelText: 'School'),
                        ),
                        TextField(
                          controller: _interestsController,
                          decoration: const InputDecoration(
                              labelText: 'Interests (comma separated)'),
                        ),
                        const SizedBox(height: 24),
                        ProfileMediaPicker(
                          initialPhotos: _photoPaths,
                          initialVideos: _videoPaths,
                          enabled: !saving,
                          onError: (msg) => showErrorSnackBar(context, msg),
                          onChanged: (selection) {
                            setState(() {
                              _photoPaths = selection.photos;
                              _videoPaths = selection.videos;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        OnboardingNavButtons(
                          onBack: saving
                              ? null
                              : () => context.go(CrushRoutes.idVerification),
                          onNext: saving ? null : () => _submit(state),
                          nextLabel: 'Finish',
                          nextLoading: saving,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (saving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withAlpha((0.08 * 255).round()),
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
