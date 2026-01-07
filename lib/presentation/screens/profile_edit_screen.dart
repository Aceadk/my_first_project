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
import '../../core/result.dart';
import '../../core/profile_completeness.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing_widgets.dart';
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
      prompts: state.user?.profile?.prompts ?? const [],
      country: state.user?.profile?.country ?? 'Unknown',
      city: state.user?.profile?.city ?? 'Unknown',
      latitude: state.user?.profile?.latitude,
      longitude: state.user?.profile?.longitude,
      preferences: state.user?.profile?.preferences ??
          const DiscoveryPreferences(
            minAge: 18,
            maxAge: 45,
            maxDistanceKm: 50,
            showMeGenders: ['female', 'male'],
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
    final uploadResult = await Result.guard(
      () => _mediaService.ensureRemoteUrls(
        userId: userId,
        photoPaths: _photos,
        videoPaths: _videos,
      ),
      logLabel: 'ProfileMediaService.ensureRemoteUrls',
      fallbackError: 'Could not save profile. Please try again.',
    );
    if (!mounted) return;
    if (!uploadResult.isSuccess || uploadResult.data == null) {
      showErrorSnackBar(
        context,
        uploadResult.errorMessage ?? 'Could not save profile. Please try again.',
      );
      setState(() => _uploading = false);
      return;
    }

    final uploads = uploadResult.data!;
    final updated = base.copyWith(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      photoUrls: uploads.photoUrls,
      videoUrls: uploads.videoUrls,
    );

    context.read<ProfileBloc>().add(ProfileSaveRequested(profile: updated));

    if (mounted) {
      setState(() => _uploading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
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
          return Scaffold(
            appBar: AppBar(title: const Text('Complete Your Profile')),
            body: const Center(child: CircularProgressIndicator()),
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
        final completenessProfile = profile ?? _fallbackProfile(state);
        final summary = evaluateProfileCompleteness(completenessProfile);
        final percent = (summary.score * 100).round();
        final missing = summary.missing.take(3).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Your Profile'),
            centerTitle: true,
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: AbsorbPointer(
              absorbing: saving,
              child: SingleChildScrollView(
                padding: DsEdgeInsets.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Card
                    _ProgressCard(
                      percent: percent,
                      score: summary.score,
                      missing: missing,
                    ),
                    DsGap.xl,

                    // Photos Section
                    const _SectionHeader(
                      icon: Icons.photo_library_outlined,
                      title: 'Your Photos & Videos',
                      subtitle: 'Add at least 1 photo to be visible',
                    ),
                    DsGap.md,
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
                    DsGap.xl,

                    // Basic Info Section
                    const _SectionHeader(
                      icon: Icons.person_outline,
                      title: 'Basic Info',
                      subtitle: 'Help others get to know you',
                    ),
                    DsGap.md,
                    _StyledTextField(
                      controller: _nameController,
                      label: 'Display Name',
                      hint: 'What should we call you?',
                      icon: Icons.badge_outlined,
                    ),
                    DsGap.md,
                    _StyledTextField(
                      controller: _bioController,
                      label: 'About You',
                      hint: 'Share something interesting about yourself...',
                      icon: Icons.edit_note,
                      maxLines: 4,
                      minLines: 3,
                    ),
                    DsGap.xxl,

                    // Tips Card
                    const _TipsCard(),
                    DsGap.xl,
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _SaveButton(
            saving: saving,
            onSave: () => _save(state),
          ),
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.percent,
    required this.score,
    required this.missing,
  });

  final int percent;
  final double score;
  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    final isComplete = missing.isEmpty;
    final progressColor = isComplete ? DsColors.success : DsColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [DsColors.success.withAlpha(30), DsColors.success.withAlpha(10)]
              : [DsColors.primary.withAlpha(30), DsColors.primary.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: progressColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: progressColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete ? Icons.check_circle : Icons.trending_up,
                  color: progressColor,
                  size: 28,
                ),
              ),
              DsGap.mdH,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? 'Profile Complete!' : 'Almost There!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DsGap.xs,
                    Text(
                      isComplete
                          ? 'You\'re ready to start matching'
                          : 'Complete your profile to unlock swiping',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          DsGap.lg,
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 8,
              backgroundColor: progressColor.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          if (!isComplete) ...[
            DsGap.lg,
            Text(
              'Still needed:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            DsGap.sm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missing
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DsColors.warning.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: DsColors.warning.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            size: 14,
                            color: DsColors.warning,
                          ),
                          DsGap.xsH,
                          Text(
                            m,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: DsColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DsColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: DsColors.primary,
            size: 20,
          ),
        ),
        DsGap.mdH,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: DsColors.primary),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? DsColors.inputFillDark
            : DsColors.inputFillLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? DsColors.borderDark
                : DsColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DsColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DsColors.info.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DsColors.info.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: DsColors.info, size: 20),
              DsGap.smH,
              const Text(
                'Profile Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          DsGap.md,
          const _TipItem(text: 'Profiles with 3+ photos get 5x more matches'),
          DsGap.sm,
          const _TipItem(text: 'A bio with 50+ characters shows personality'),
          DsGap.sm,
          const _TipItem(text: 'Smile in your first photo for best results'),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          color: DsColors.success,
          size: 16,
        ),
        DsGap.smH,
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: saving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: DsColors.primary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined),
                    SizedBox(width: 8),
                    Text(
                      'Save Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
