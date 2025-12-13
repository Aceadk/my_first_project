import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../logic/profile/profile_bloc.dart';
import '../../logic/profile/profile_event.dart';
import '../../logic/profile/profile_state.dart';
import '../../data/models/profile.dart';
import '../../data/models/preferences.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../core/profile_media_limits.dart';
import '../../data/services/profile_media_service.dart';
import '../widgets/profile_media_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _lastProfileId;
  final _mediaService = ProfileMediaService();
  List<String> _photos = [];
  List<String> _videos = [];
  bool _uploading = false;
  bool _hasLoadedProfile = false;

  Profile _fallbackProfile(ProfileState state) {
    return Profile(
      id: state.user?.id ?? 'TEMP',
      name: '',
      age: state.user?.profile?.age ?? 18,
      gender: state.user?.profile?.gender ?? '',
      sexualOrientation: state.user?.profile?.sexualOrientation,
      bio: '',
      photoUrls: List.of(_photos),
      videoUrls: List.of(_videos),
      isVerified: state.user?.profile?.isVerified ?? false,
      jobTitle: state.user?.profile?.jobTitle,
      company: state.user?.profile?.company,
      school: state.user?.profile?.school,
      interests: state.user?.profile?.interests ?? const [],
      country: state.user?.profile?.country ?? 'Unknown',
      city: state.user?.profile?.city ?? 'Unknown',
      latitude: state.user?.profile?.latitude,
      longitude: state.user?.profile?.longitude,
      preferences: state.user?.profile?.preferences ??
          const DiscoveryPreferences(
            minAge: 18,
            maxAge: 45,
            maxDistanceKm: 50,
            showMeGenders: ['women', 'men'],
            showMyDistance: true,
            showMyAge: true,
            hideFromDiscovery: false,
            incognitoMode: false,
            country: 'Unknown',
            city: 'Unknown',
          ),
    );
  }

  Future<void> _save(ProfileState state) async {
    if (_uploading || state.isSaving) return;
    if (_photos.length < ProfileMediaLimits.minPhotos) {
      showErrorSnackBar(
        context,
        'Add at least one photo to keep your profile visible.',
      );
      return;
    }

    final base = state.profile ?? _fallbackProfile(state);
    final userId = state.user?.id ??
        state.profile?.id ??
        fb.FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      showErrorSnackBar(context, 'You need to be signed in to save changes.');
      return;
    }

    setState(() => _uploading = true);
    try {
      final uploads = await _mediaService.ensureRemoteUrls(
        userId: userId,
        photoPaths: _photos,
        videoPaths: _videos,
      );
      if (!mounted) return;

      final updated = base.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrls: uploads.photoUrls,
        videoUrls: uploads.videoUrls,
      );

      context
          .read<ProfileBloc>()
          .add(ProfileSaveRequested(profile: updated));
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Could not save profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage ||
          prev.profile != curr.profile,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          showErrorSnackBar(context, error);
          return;
        }
        if (state.profile != null && _hasLoadedProfile) {
          showSuccessSnackBar(context, 'Profile saved');
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = state.profile;
        if (profile != null && profile.id != _lastProfileId) {
          _hasLoadedProfile = true;
          _lastProfileId = profile.id;
          _nameController.text = profile.name;
          _bioController.text = profile.bio;
          _photos = List.of(profile.photoUrls);
          _videos = List.of(profile.videoUrls);
        }

        final saving = state.isSaving || _uploading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your profile'),
          ),
          body: Stack(
            children: [
              AbsorbPointer(
                absorbing: saving,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Display name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bioController,
                        decoration:
                            const InputDecoration(labelText: 'About you'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ProfileMediaPicker(
                        initialPhotos: _photos,
                        initialVideos: _videos,
                        enabled: !saving,
                        onError: (msg) => showErrorSnackBar(context, msg),
                        onChanged: (selection) {
                          setState(() {
                            _photos = selection.photos;
                            _videos = selection.videos;
                          });
                        },
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : () => _save(state),
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (saving)
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
          ),
        );
      },
    );
  }
}
