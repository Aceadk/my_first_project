import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/shared/utils/profile_media_limits.dart';
import 'package:crushhour/features/profile/data/services/profile_media_service.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/shared/utils/profile_field_options.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import '../widgets/profile_media_picker.dart';
import '../widgets/prompt_editor.dart';
import 'package:crushhour/features/profile/presentation/widgets/profile_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _schoolController = TextEditingController();
  final _livingInController = TextEditingController();
  final _favoriteSingerController = TextEditingController();
  final _scrollController = ScrollController();

  String? _lastProfileId;
  final _mediaService = ProfileMediaService();
  List<String> _photos = [];
  List<String> _videos = [];
  int _primaryPhotoIndex = 0;
  bool _uploading = false;
  bool _hasLoadedProfile = false;

  // New profile fields
  int? _heightCm;
  String? _relationshipGoals;
  List<String> _languages = [];
  String? _zodiacSign;
  String? _educationLevel;
  String? _familyPlans;
  String? _personalityType;
  String? _religion;
  String? _workout;
  String? _socialMedia;
  String? _sleepingHabits;
  String? _smoking;
  String? _drinking;
  String? _pets;
  List<String> _favoriteSongs = [];
  List<String> _interests = [];
  DateTime? _dateOfBirth;
  String? _gender;
  String? _sexualOrientation;
  List<ProfilePrompt> _profilePrompts = [];

  Profile _fallbackProfile(ProfileState state) {
    // Use AuthBloc as fallback for user ID when ProfileBloc state doesn't have it
    final authUserId = context.read<AuthBloc>().state.user?.id;
    return Profile(
      id: state.user?.id ?? authUserId ?? 'TEMP',
      name: '',
      age: state.user?.profile?.age ?? 18,
      gender: _gender ?? state.user?.profile?.gender ?? '',
      sexualOrientation: _sexualOrientation ?? state.user?.profile?.sexualOrientation,
      dateOfBirth: _dateOfBirth ?? state.user?.profile?.dateOfBirth,
      bio: '',
      photoUrls: List.of(_photos),
      videoUrls: List.of(_videos),
      primaryPhotoIndex: _primaryPhotoIndex,
      isVerified: state.user?.profile?.isVerified ?? false,
      jobTitle: _jobTitleController.text.isNotEmpty ? _jobTitleController.text : state.user?.profile?.jobTitle,
      company: _companyController.text.isNotEmpty ? _companyController.text : state.user?.profile?.company,
      school: _schoolController.text.isNotEmpty ? _schoolController.text : state.user?.profile?.school,
      interests: _interests.isNotEmpty ? _interests : (state.user?.profile?.interests ?? const []),
      profilePrompts: _profilePrompts.isNotEmpty ? _profilePrompts : (state.user?.profile?.profilePrompts ?? const []),
      // ignore: deprecated_member_use_from_same_package
      prompts: state.user?.profile?.prompts ?? const [], // Keep for backwards compatibility
      heightCm: _heightCm ?? state.user?.profile?.heightCm,
      relationshipGoals: _relationshipGoals ?? state.user?.profile?.relationshipGoals,
      languages: _languages.isNotEmpty ? _languages : (state.user?.profile?.languages ?? const []),
      zodiacSign: _zodiacSign ?? state.user?.profile?.zodiacSign,
      educationLevel: _educationLevel ?? state.user?.profile?.educationLevel,
      familyPlans: _familyPlans ?? state.user?.profile?.familyPlans,
      personalityType: _personalityType ?? state.user?.profile?.personalityType,
      religion: _religion ?? state.user?.profile?.religion,
      workout: _workout ?? state.user?.profile?.workout,
      socialMedia: _socialMedia ?? state.user?.profile?.socialMedia,
      sleepingHabits: _sleepingHabits ?? state.user?.profile?.sleepingHabits,
      smoking: _smoking ?? state.user?.profile?.smoking,
      drinking: _drinking ?? state.user?.profile?.drinking,
      pets: _pets ?? state.user?.profile?.pets,
      livingIn: _livingInController.text.isNotEmpty ? _livingInController.text : state.user?.profile?.livingIn,
      favoriteSongs: _favoriteSongs.isNotEmpty ? _favoriteSongs : (state.user?.profile?.favoriteSongs ?? const []),
      favoriteSinger: _favoriteSingerController.text.isNotEmpty ? _favoriteSingerController.text : state.user?.profile?.favoriteSinger,
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
    // Try ProfileBloc state first, then fall back to AuthBloc for user ID
    final userId = state.user?.id ?? state.profile?.id ?? context.read<AuthBloc>().state.user?.id;
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
    final newName = _nameController.text.trim();
    final nameChanged = newName != base.name;
    final dobChanged = _dateOfBirth != base.dateOfBirth;
    final updated = base.copyWith(
      name: newName,
      bio: _bioController.text.trim(),
      photoUrls: uploads.photoUrls,
      videoUrls: uploads.videoUrls,
      primaryPhotoIndex: _primaryPhotoIndex,
      // Track name change date if name was modified
      lastNameChangeAt: nameChanged ? DateTime.now() : base.lastNameChangeAt,
      // Track DOB change date if DOB was modified
      lastDobChangeAt: dobChanged ? DateTime.now() : base.lastDobChangeAt,
      // New fields
      heightCm: _heightCm,
      relationshipGoals: _relationshipGoals,
      languages: _languages,
      zodiacSign: _zodiacSign,
      educationLevel: _educationLevel,
      familyPlans: _familyPlans,
      personalityType: _personalityType,
      religion: _religion,
      workout: _workout,
      socialMedia: _socialMedia,
      sleepingHabits: _sleepingHabits,
      smoking: _smoking,
      drinking: _drinking,
      pets: _pets,
      interests: _interests,
      profilePrompts: _profilePrompts,
      jobTitle: _jobTitleController.text.trim().isNotEmpty ? _jobTitleController.text.trim() : null,
      company: _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
      school: _schoolController.text.trim().isNotEmpty ? _schoolController.text.trim() : null,
      livingIn: _livingInController.text.trim().isNotEmpty ? _livingInController.text.trim() : null,
      favoriteSongs: _favoriteSongs,
      favoriteSinger: _favoriteSingerController.text.trim().isNotEmpty ? _favoriteSingerController.text.trim() : null,
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      sexualOrientation: _sexualOrientation,
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
    _jobTitleController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    _livingInController.dispose();
    _favoriteSingerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? DsColors.borderDark : DsColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: DsColors.primary, size: 20),
                const SizedBox(width: DsSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? DsColors.dividerDark : DsColors.dividerLight,
          ),
          Padding(
            padding: const EdgeInsets.all(DsSpacing.sm),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PICKER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _showHeightPicker(BuildContext context) async {
    final result = await ProfileHeightPicker.show(
      context: context,
      initialHeightCm: _heightCm,
    );
    if (result != null || _heightCm != null) {
      setState(() => _heightCm = result);
    }
  }

  Future<void> _showRelationshipGoalsPicker(BuildContext context) async {
    const options = ProfileFieldOptions.relationshipGoals;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Relationship Goals',
      options: options.map((e) => e.value).toList(),
      selectedValue: _relationshipGoals,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _relationshipGoals != null) {
      setState(() => _relationshipGoals = result);
    }
  }

  Future<void> _showDateOfBirthPicker(BuildContext context, Profile? profile) async {
    // Check if DOB is locked
    if (profile != null && !profile.canChangeDob) {
      showErrorSnackBar(
        context,
        'You can change your date of birth again in ${profile.daysUntilDobChange} days',
      );
      return;
    }

    // Show confirmation dialog if DOB already exists
    final isFirstTime = profile?.dateOfBirth == null;
    if (!isFirstTime) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Date of Birth'),
          content: const Text(
            'Please make sure you enter your real date of birth.\n\n'
            'After saving, you will need to wait 1 month before you can change it again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;

    final now = DateTime.now();
    const minAge = 18;
    const maxAge = 75;
    final result = await showDatePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - maxAge),
      lastDate: DateTime(now.year - minAge),
      helpText: isFirstTime
          ? 'Select your date of birth (cannot be easily changed later)'
          : 'Select your date of birth',
    );

    if (result == null) return;
    if (!mounted) return;

    // Calculate age from selected date
    final age = now.year - result.year -
        ((now.month < result.month || (now.month == result.month && now.day < result.day)) ? 1 : 0);

    // Reject if under 18
    if (age < 18) {
      showErrorSnackBar(
        // ignore: use_build_context_synchronously
        context,
        'You must be at least 18 years old to use this app.',
      );
      return;
    }

    // Reject if over 75
    if (age > 75) {
      showErrorSnackBar(
        // ignore: use_build_context_synchronously
        context,
        'Sorry, the maximum age allowed is 75 years old.',
      );
      return;
    }

    // Show warning for users aged 70-75
    if (age >= 70) {
      final proceedAnyway = await showDialog<bool>(
        // ignore: use_build_context_synchronously
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
      if (proceedAnyway != true) return;
    }

    if (!mounted) return;

    // Show final confirmation with warning
    final finalConfirm = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
          title: const Text('Confirm Date of Birth'),
          content: Text(
            'You selected: ${result.day}/${result.month}/${result.year}\n\n'
            'Please verify this is your correct date of birth. '
            'You will not be able to change it for 1 month after saving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Go Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    if (finalConfirm == true) {
      setState(() => _dateOfBirth = result);
    }
  }

  Future<void> _showInterestsPicker(BuildContext context) async {
    final result = await ProfileMultiSelectSheet.show<String>(
      context: context,
      title: 'Your Interests',
      options: ProfileFieldOptions.interests,
      selectedValues: _interests,
      labelBuilder: (v) => v,
      maxSelections: 10,
    );
    if (result != null) {
      setState(() => _interests = result);
    }
  }

  Future<void> _showLanguagesPicker(BuildContext context) async {
    final result = await ProfileMultiSelectSheet.show<String>(
      context: context,
      title: 'Languages I Speak',
      options: ProfileFieldOptions.languages,
      selectedValues: _languages,
      labelBuilder: (v) => v,
      maxSelections: 10,
    );
    if (result != null) {
      setState(() => _languages = result);
    }
  }

  Future<void> _showZodiacPicker(BuildContext context) async {
    const options = ProfileFieldOptions.zodiacSigns;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Zodiac Sign',
      options: options.map((e) => e.value).toList(),
      selectedValue: _zodiacSign,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      subtitleBuilder: (v) => options.firstWhere((e) => e.value == v).dateRange,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _zodiacSign != null) {
      setState(() => _zodiacSign = result);
    }
  }

  Future<void> _showEducationPicker(BuildContext context) async {
    const options = ProfileFieldOptions.educationLevels;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Education Level',
      options: options.map((e) => e.value).toList(),
      selectedValue: _educationLevel,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _educationLevel != null) {
      setState(() => _educationLevel = result);
    }
  }

  Future<void> _showFamilyPlansPicker(BuildContext context) async {
    const options = ProfileFieldOptions.familyPlans;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Family Plans',
      options: options.map((e) => e.value).toList(),
      selectedValue: _familyPlans,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _familyPlans != null) {
      setState(() => _familyPlans = result);
    }
  }

  Future<void> _showPersonalityPicker(BuildContext context) async {
    const options = ProfileFieldOptions.personalityTypes;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Personality Type (MBTI)',
      options: options.map((e) => e.value).toList(),
      selectedValue: _personalityType,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      subtitleBuilder: (v) => options.firstWhere((e) => e.value == v).description,
    );
    if (result != null || _personalityType != null) {
      setState(() => _personalityType = result);
    }
  }

  Future<void> _showReligionPicker(BuildContext context) async {
    const options = ProfileFieldOptions.religionOptions;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Religion',
      options: options.map((e) => e.value).toList(),
      selectedValue: _religion,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _religion != null) {
      setState(() => _religion = result);
    }
  }

  Future<void> _showWorkoutPicker(BuildContext context) async {
    const options = ProfileFieldOptions.workoutHabits;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Workout Habits',
      options: options.map((e) => e.value).toList(),
      selectedValue: _workout,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _workout != null) {
      setState(() => _workout = result);
    }
  }

  Future<void> _showSocialMediaPicker(BuildContext context) async {
    const options = ProfileFieldOptions.socialMediaUsage;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Social Media Usage',
      options: options.map((e) => e.value).toList(),
      selectedValue: _socialMedia,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _socialMedia != null) {
      setState(() => _socialMedia = result);
    }
  }

  Future<void> _showSleepingPicker(BuildContext context) async {
    const options = ProfileFieldOptions.sleepingHabits;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Sleeping Habits',
      options: options.map((e) => e.value).toList(),
      selectedValue: _sleepingHabits,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _sleepingHabits != null) {
      setState(() => _sleepingHabits = result);
    }
  }

  Future<void> _showSmokingPicker(BuildContext context) async {
    const options = ProfileFieldOptions.smokingHabits;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Smoking',
      options: options.map((e) => e.value).toList(),
      selectedValue: _smoking,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _smoking != null) {
      setState(() => _smoking = result);
    }
  }

  Future<void> _showDrinkingPicker(BuildContext context) async {
    const options = ProfileFieldOptions.drinkingHabits;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Drinking',
      options: options.map((e) => e.value).toList(),
      selectedValue: _drinking,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _drinking != null) {
      setState(() => _drinking = result);
    }
  }

  Future<void> _showPetsPicker(BuildContext context) async {
    const options = ProfileFieldOptions.petOptions;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Pets',
      options: options.map((e) => e.value).toList(),
      selectedValue: _pets,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
      emojiBuilder: (v) => options.firstWhere((e) => e.value == v).emoji,
    );
    if (result != null || _pets != null) {
      setState(() => _pets = result);
    }
  }

  Future<void> _showFavoriteSongsDialog(BuildContext context) async {
    final controller = TextEditingController();
    final songs = List<String>.from(_favoriteSongs);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDark ? DsColors.textMutedDark : DsColors.textMutedLight)
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(DsSpacing.lg),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Favorite Songs',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _favoriteSongs = songs);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: DsColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                setModalState(() {
                                  songs.add(value.trim());
                                  controller.clear();
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Add a song...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: DsSpacing.md,
                                vertical: DsSpacing.sm,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: DsSpacing.sm),
                        IconButton(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              setModalState(() {
                                songs.add(controller.text.trim());
                                controller.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add_circle, color: DsColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + DsSpacing.lg,
                      ),
                      itemCount: songs.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(songs[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setModalState(() => songs.removeAt(index)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showGenderPicker(BuildContext context) async {
    const options = ProfileFieldOptions.genderOptions;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Gender',
      options: options.map((e) => e.value).toList(),
      selectedValue: _gender,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
    );
    if (result != null || _gender != null) {
      setState(() => _gender = result);
    }
  }

  Future<void> _showOrientationPicker(BuildContext context) async {
    const options = ProfileFieldOptions.sexualOrientationOptions;
    final result = await ProfileSingleSelectSheet.show<String>(
      context: context,
      title: 'Sexual Orientation',
      options: options.map((e) => e.value).toList(),
      selectedValue: _sexualOrientation,
      labelBuilder: (v) => options.firstWhere((e) => e.value == v).label,
    );
    if (result != null || _sexualOrientation != null) {
      setState(() => _sexualOrientation = result);
    }
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
          _primaryPhotoIndex = profile.primaryPhotoIndex;
          // Load new fields
          _jobTitleController.text = profile.jobTitle ?? '';
          _companyController.text = profile.company ?? '';
          _schoolController.text = profile.school ?? '';
          _livingInController.text = profile.livingIn ?? '';
          _favoriteSingerController.text = profile.favoriteSinger ?? '';
          _heightCm = profile.heightCm;
          _relationshipGoals = profile.relationshipGoals;
          _languages = List.of(profile.languages);
          _zodiacSign = profile.zodiacSign;
          _educationLevel = profile.educationLevel;
          _familyPlans = profile.familyPlans;
          _personalityType = profile.personalityType;
          _religion = profile.religion;
          _workout = profile.workout;
          _socialMedia = profile.socialMedia;
          _sleepingHabits = profile.sleepingHabits;
          _smoking = profile.smoking;
          _drinking = profile.drinking;
          _pets = profile.pets;
          _favoriteSongs = List.of(profile.favoriteSongs);
          _interests = List.of(profile.interests);
          _dateOfBirth = profile.dateOfBirth;
          _gender = profile.gender.isNotEmpty ? profile.gender : null;
          _sexualOrientation = profile.sexualOrientation;
          _profilePrompts = List.of(profile.profilePrompts);
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
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      initialPrimaryIndex: _primaryPhotoIndex,
                      enabled: !saving,
                      onError: (msg) => showErrorSnackBar(context, msg),
                      onChanged: (selection) {
                        setState(() {
                          _photos = selection.photos;
                          _videos = selection.videos;
                          _primaryPhotoIndex = selection.primaryPhotoIndex;
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
                      enabled: profile?.canChangeName ?? true,
                      helperText: profile != null && !profile.canChangeName
                          ? 'You can change your name again in ${profile.daysUntilNameChange} days'
                          : 'You can change your name once per month',
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
                    DsGap.xl,

                    // Conversation Starters Section
                    _buildSectionCard(
                      context: context,
                      title: 'Conversation Starters',
                      icon: Icons.chat_bubble_outline,
                      children: [
                        PromptEditor(
                          prompts: _profilePrompts,
                          maxPrompts: PromptQuestions.maxPromptsPerProfile,
                          onPromptsChanged: (prompts) {
                            setState(() => _profilePrompts = prompts);
                          },
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // Physical & Dating Section
                    _buildSectionCard(
                      context: context,
                      title: 'Dating Basics',
                      icon: Icons.favorite_outline,
                      children: [
                        ProfileFieldTile(
                          label: 'Height',
                          value: _heightCm != null
                              ? ProfileFieldOptions.formatHeightDisplay(_heightCm!)
                              : null,
                          leadingIcon: Icons.height,
                          onTap: () => _showHeightPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Relationship Goals',
                          value: ProfileFieldOptions.getRelationshipGoalLabel(_relationshipGoals),
                          leadingIcon: Icons.favorite,
                          onTap: () => _showRelationshipGoalsPicker(context),
                        ),
                        ProfileFieldTile(
                          label: profile != null && !profile.canChangeDob
                              ? 'Date of Birth 🔒'
                              : 'Date of Birth',
                          value: _dateOfBirth != null
                              ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                              : null,
                          placeholder: profile != null && !profile.canChangeDob
                              ? 'Locked (${profile.daysUntilDobChange}d)'
                              : 'Add',
                          leadingIcon: Icons.cake_outlined,
                          onTap: () => _showDateOfBirthPicker(context, profile),
                          showDivider: false,
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // Interests Section
                    _buildSectionCard(
                      context: context,
                      title: 'Interests',
                      icon: Icons.interests_outlined,
                      children: [
                        ProfileFieldTile(
                          label: 'Your Interests',
                          value: _interests.isNotEmpty
                              ? '${_interests.length} selected'
                              : null,
                          leadingIcon: Icons.local_fire_department,
                          onTap: () => _showInterestsPicker(context),
                          showDivider: false,
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // Languages Section
                    _buildSectionCard(
                      context: context,
                      title: 'Languages',
                      icon: Icons.language,
                      children: [
                        ProfileFieldTile(
                          label: 'I speak',
                          value: _languages.isNotEmpty
                              ? _languages.take(3).join(', ') + (_languages.length > 3 ? '...' : '')
                              : null,
                          leadingIcon: Icons.translate,
                          onTap: () => _showLanguagesPicker(context),
                          showDivider: false,
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // More About Me Section
                    _buildSectionCard(
                      context: context,
                      title: 'More About Me',
                      icon: Icons.psychology_outlined,
                      children: [
                        ProfileFieldTile(
                          label: 'Zodiac Sign',
                          value: ProfileFieldOptions.getZodiacLabel(_zodiacSign),
                          leadingIcon: Icons.auto_awesome,
                          onTap: () => _showZodiacPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Education',
                          value: ProfileFieldOptions.getEducationLabel(_educationLevel),
                          leadingIcon: Icons.school_outlined,
                          onTap: () => _showEducationPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Family Plans',
                          value: ProfileFieldOptions.getFamilyPlanLabel(_familyPlans),
                          leadingIcon: Icons.family_restroom,
                          onTap: () => _showFamilyPlansPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Personality Type',
                          value: ProfileFieldOptions.getPersonalityLabel(_personalityType),
                          leadingIcon: Icons.emoji_people,
                          onTap: () => _showPersonalityPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Religion',
                          value: ProfileFieldOptions.getReligionLabel(_religion),
                          leadingIcon: Icons.self_improvement,
                          onTap: () => _showReligionPicker(context),
                          showDivider: false,
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // Lifestyle Section
                    _buildSectionCard(
                      context: context,
                      title: 'Lifestyle',
                      icon: Icons.spa_outlined,
                      children: [
                        ProfileFieldTile(
                          label: 'Workout',
                          value: ProfileFieldOptions.getWorkoutLabel(_workout),
                          leadingIcon: Icons.fitness_center,
                          onTap: () => _showWorkoutPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Social Media',
                          value: ProfileFieldOptions.getSocialMediaLabel(_socialMedia),
                          leadingIcon: Icons.phone_android,
                          onTap: () => _showSocialMediaPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Sleeping Habits',
                          value: ProfileFieldOptions.getSleepingLabel(_sleepingHabits),
                          leadingIcon: Icons.bedtime_outlined,
                          onTap: () => _showSleepingPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Smoking',
                          value: ProfileFieldOptions.getSmokingLabel(_smoking),
                          leadingIcon: Icons.smoking_rooms,
                          onTap: () => _showSmokingPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Drinking',
                          value: ProfileFieldOptions.getDrinkingLabel(_drinking),
                          leadingIcon: Icons.local_bar,
                          onTap: () => _showDrinkingPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Pets',
                          value: ProfileFieldOptions.getPetLabel(_pets),
                          leadingIcon: Icons.pets,
                          onTap: () => _showPetsPicker(context),
                          showDivider: false,
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // Work & Education Section
                    _buildSectionCard(
                      context: context,
                      title: 'Work & Education',
                      icon: Icons.work_outline,
                      children: [
                        _StyledTextField(
                          controller: _jobTitleController,
                          label: 'Job Title',
                          hint: 'What do you do?',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: DsSpacing.md),
                        _StyledTextField(
                          controller: _companyController,
                          label: 'Company',
                          hint: 'Where do you work?',
                          icon: Icons.business,
                        ),
                        const SizedBox(height: DsSpacing.md),
                        _StyledTextField(
                          controller: _schoolController,
                          label: 'School/College',
                          hint: 'Where did you study?',
                          icon: Icons.school,
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // Location Section
                    _buildSectionCard(
                      context: context,
                      title: 'Location',
                      icon: Icons.location_on_outlined,
                      children: [
                        _StyledTextField(
                          controller: _livingInController,
                          label: 'Currently Living In',
                          hint: 'City, Country',
                          icon: Icons.home,
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // Music Section
                    _buildSectionCard(
                      context: context,
                      title: 'Music',
                      icon: Icons.music_note_outlined,
                      children: [
                        _StyledTextField(
                          controller: _favoriteSingerController,
                          label: 'Favorite Singer/Artist',
                          hint: 'Who do you listen to?',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: DsSpacing.md),
                        ProfileFieldTile(
                          label: 'Favorite Songs',
                          value: _favoriteSongs.isNotEmpty
                              ? '${_favoriteSongs.length} songs'
                              : null,
                          leadingIcon: Icons.queue_music,
                          onTap: () => _showFavoriteSongsDialog(context),
                          showDivider: false,
                        ),
                      ],
                    ),
                    DsGap.lg,

                    // Personal Details Section
                    _buildSectionCard(
                      context: context,
                      title: 'Personal Details',
                      icon: Icons.person_pin_outlined,
                      children: [
                        ProfileFieldTile(
                          label: 'Gender',
                          value: ProfileFieldOptions.getGenderLabel(_gender),
                          leadingIcon: Icons.wc,
                          onTap: () => _showGenderPicker(context),
                        ),
                        ProfileFieldTile(
                          label: 'Sexual Orientation',
                          value: ProfileFieldOptions.getSexualOrientationLabel(_sexualOrientation),
                          leadingIcon: Icons.favorite_border,
                          onTap: () => _showOrientationPicker(context),
                          showDivider: false,
                        ),
                      ],
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
    this.enabled = true,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
      onEditingComplete: () => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon, color: enabled ? DsColors.primary : DsColors.textMutedLight),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: DsColors.info, size: 20),
              DsGap.smH,
              Text(
                'Profile Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          DsGap.md,
          _TipItem(text: 'Profiles with 3+ photos get 5x more matches'),
          DsGap.sm,
          _TipItem(text: 'A bio with 50+ characters shows personality'),
          DsGap.sm,
          _TipItem(text: 'Smile in your first photo for best results'),
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
