import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/features/profile/data/services/profile_media_service.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/features/discovery/data/services/passport_locations_service.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import '../widgets/profile_media_picker.dart';

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
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _usernameController = TextEditingController();
  final _mediaService = ProfileMediaService();
  final _passportService = PassportLocationsService.instance;

  List<String> _photoPaths = [];
  List<String> _videoPaths = [];
  final List<String> _selectedInterests = [];
  bool _uploading = false;
  bool _usernameTouched = false;
  bool _usernameInitialized = false;
  bool _isEditingUsername = false;

  // Favourites
  String? _favouriteAthlete;
  String? _favouriteFood;
  String? _favouriteSport;
  String? _favouriteTvShow;
  String? _favouriteActor;
  String? _favouriteSinger;
  String? _favouriteMovie;
  String? _favouriteHobby;

  @override
  void initState() {
    super.initState();
    // Default athlete (not shown to user that it's default)
    _favouriteAthlete = 'Cristiano Ronaldo';
  }

  @override
  void dispose() {
    _bioController.dispose();
    _jobController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String? _usernameErrorText() {
    if (!_usernameTouched) return null;
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      return 'Username is required';
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
    if (!valid) {
      return 'Use 3-20 letters, numbers, or underscore';
    }
    return null;
  }

  /// Calculate current form completion percentage based on filled fields
  /// Returns a map with 'percentage', 'filledCount', 'totalCount', and 'missingFields'
  Map<String, dynamic> _calculateFormCompleteness(ProfileState state) {
    final profile = state.user?.profile;
    final hasBasicInfo = profile != null &&
        profile.name.isNotEmpty &&
        profile.age > 0 &&
        profile.gender.isNotEmpty;

    // Total optional fields that enhance the profile
    // Photos, Bio, Location (city+country), Job, Company, School, Interests, 8 favourites = 16 fields
    const totalOptionalFields = 16;
    int filledCount = 0;
    final missingFields = <String>[];

    // Photos (counts as filled if at least 1)
    if (_photoPaths.isNotEmpty) {
      filledCount++;
    } else {
      missingFields.add('Photos');
    }

    // Bio
    if (_bioController.text.trim().length >= kMinBioLength) {
      filledCount++;
    } else {
      missingFields.add('Bio');
    }

    // Location (city)
    if (_cityController.text.trim().isNotEmpty) {
      filledCount++;
    } else {
      missingFields.add('City');
    }

    // Location (country)
    if (_countryController.text.trim().isNotEmpty) {
      filledCount++;
    } else {
      missingFields.add('Country');
    }

    // Job title
    if (_jobController.text.trim().isNotEmpty) {
      filledCount++;
    } else {
      missingFields.add('Job title');
    }

    // Company
    if (_companyController.text.trim().isNotEmpty) {
      filledCount++;
    } else {
      missingFields.add('Company');
    }

    // School
    if (_schoolController.text.trim().isNotEmpty) {
      filledCount++;
    } else {
      missingFields.add('School');
    }

    // Interests (counts as filled if at least 3)
    if (_selectedInterests.length >= kMinInterests) {
      filledCount++;
    } else {
      missingFields.add('Interests (${kMinInterests - _selectedInterests.length} more needed)');
    }

    // Favourites (8 fields)
    if (_favouriteAthlete != null && _favouriteAthlete != 'Cristiano Ronaldo') {
      filledCount++;
    } else {
      missingFields.add('Favourite Athlete');
    }

    if (_favouriteFood != null) {
      filledCount++;
    } else {
      missingFields.add('Favourite Food');
    }

    if (_favouriteSport != null) {
      filledCount++;
    } else {
      missingFields.add('Favourite Sport');
    }

    if (_favouriteTvShow != null) {
      filledCount++;
    } else {
      missingFields.add('Favourite TV Show');
    }

    if (_favouriteActor != null) {
      filledCount++;
    } else {
      missingFields.add('Favourite Actor');
    }

    if (_favouriteSinger != null) {
      filledCount++;
    } else {
      missingFields.add('Favourite Singer');
    }

    if (_favouriteMovie != null) {
      filledCount++;
    } else {
      missingFields.add('Favourite Movie');
    }

    if (_favouriteHobby != null) {
      filledCount++;
    } else {
      missingFields.add('Favourite Hobby');
    }

    final percentage = filledCount / totalOptionalFields;

    return {
      'percentage': percentage,
      'filledCount': filledCount,
      'totalCount': totalOptionalFields,
      'missingFields': missingFields,
      'hasBasicInfo': hasBasicInfo,
      'isEligibleToSwipe': hasBasicInfo, // Basic info is enough to start swiping
      'isFullyComplete': filledCount == totalOptionalFields,
    };
  }

  final List<String> _interestOptions = [
    'Travel', 'Music', 'Movies', 'Gaming', 'Fitness', 'Food', 'Art',
    'Photography', 'Reading', 'Dancing', 'Cooking', 'Sports', 'Fashion',
    'Technology', 'Nature', 'Pets', 'Yoga', 'Coffee', 'Wine', 'Hiking',
  ];

  Future<void> _submit(ProfileState state) async {
    if (_uploading || state.isSaving) return;

    final userId = state.user?.id;
    if (userId == null) {
      showErrorSnackBar(context, 'You need to be signed in to continue.');
      return;
    }

    // Check if user is skipping (no photos added)
    final isSkipping = _photoPaths.isEmpty;

    if (isSkipping) {
      // User is skipping - mark profile setup as skipped
      context.read<ProfileBloc>().add(ProfileSetupSkipped());
      return;
    }

    setState(() => _uploading = true);

    // Record location for passport mode tracking if provided
    if (_cityController.text.trim().isNotEmpty && _countryController.text.trim().isNotEmpty) {
      await _passportService.recordLocation(
        _cityController.text.trim(),
        _countryController.text.trim(),
      );
    }

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
      showErrorSnackBar(context, uploadResult.errorMessage ?? 'Could not upload media.');
      setState(() => _uploading = false);
      return;
    }

    context.read<ProfileBloc>().add(
      ProfileDetailsSubmitted(
        bio: _bioController.text.trim(),
        photoUrls: uploadResult.data!.photoUrls,
        videoUrls: uploadResult.data!.videoUrls,
        jobTitle: _jobController.text.trim(),
        company: _companyController.text.trim(),
        school: _schoolController.text.trim(),
        interests: _selectedInterests,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        favourites: ProfileFavourites(
          athlete: _favouriteAthlete,
          food: _favouriteFood,
          sport: _favouriteSport,
          tvShow: _favouriteTvShow,
          actor: _favouriteActor,
          singer: _favouriteSinger,
          movie: _favouriteMovie,
          hobby: _favouriteHobby,
        ),
      ),
    );

    if (mounted) {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [DsColors.backgroundDark, const Color(0xFF1A1A2E), DsColors.backgroundDark]
                : [DsColors.backgroundLight, const Color(0xFFF8F0FF), DsColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<ProfileBloc, ProfileState>(
            listenWhen: (previous, current) =>
                (previous.isSaving && !current.isSaving) || previous.errorMessage != current.errorMessage,
            listener: (context, state) {
              // Only navigate when save just completed successfully (was saving, now not saving)
              if (!state.isSaving && state.user?.hasCompletedProfileSetup == true && state.errorMessage == null) {
                // Refresh auth state so router has updated user data
                context.read<AuthBloc>().add(AuthUserRefreshRequested());

                if (context.canPop()) {
                  context.pop();
                  return;
                }

                // Check if we need email verification first
                final user = state.user;
                if (user != null &&
                    user.email != null &&
                    user.email!.isNotEmpty &&
                    !user.isEmailVerified) {
                  context.go(CrushRoutes.emailVerification);
                  return;
                }
                context.go(CrushRoutes.home);
              }
              final error = state.errorMessage;
              if (error != null && error.isNotEmpty) {
                showErrorSnackBar(context, error);
              }
            },
            builder: (context, state) {
              if (state.isLoading && state.user == null) {
                return const Center(child: CircularProgressIndicator(color: DsColors.primary));
              }

              final saving = state.isSaving || _uploading;

              return Stack(
                children: [
                  AbsorbPointer(
                    absorbing: saving,
                    child: Column(
                      children: [
                        _buildAppBar(context, isDark),
                        DsGap.lg,
                        _buildProgressIndicator(context, isDark, state),
                        DsGap.lg,
                        Expanded(
                          child: SingleChildScrollView(
                            padding: DsEdgeInsets.horizontalXxl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Optional notice
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: DsColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: DsColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, color: DsColors.primary, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'All fields are optional. You can complete your profile later in Settings.',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: DsColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DsGap.lg,
                                // Basic Info Summary (from previous step)
                                _buildBasicInfoSummary(context, isDark, state),
                                DsGap.xl,
                                // Username Section
                                _buildUsernameSection(context, isDark, state),
                                DsGap.xl,
                                // Photos Section
                                _buildSectionHeader(context, isDark, 'Your Photos', 'Optional - helps you get more matches', Icons.photo_library_rounded),
                                DsGap.md,
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
                                DsGap.xl,
                                // Bio Section
                                _buildSectionHeader(context, isDark, 'About You', 'Tell others about yourself', Icons.edit_note_rounded),
                                DsGap.md,
                                GlassTextField(
                                  controller: _bioController,
                                  hintText: 'Write something interesting about yourself...',
                                  maxLines: 4,
                                  maxLength: 500,
                                ),
                                DsGap.xl,
                                // Location Section
                                _buildSectionHeader(context, isDark, 'Location', 'Where are you based?', Icons.location_on_rounded),
                                DsGap.md,
                                Row(
                                  children: [
                                    Expanded(
                                      child: GlassTextField(
                                        controller: _cityController,
                                        hintText: 'City',
                                        prefixIcon: Icons.location_city_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GlassTextField(
                                        controller: _countryController,
                                        hintText: 'Country',
                                        prefixIcon: Icons.public_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                DsGap.xl,
                                // Work & Education
                                _buildSectionHeader(context, isDark, 'Work & Education', 'Optional', Icons.work_outline_rounded),
                                DsGap.md,
                                GlassTextField(
                                  controller: _jobController,
                                  hintText: 'Job Title',
                                  prefixIcon: Icons.badge_outlined,
                                ),
                                DsGap.md,
                                GlassTextField(
                                  controller: _companyController,
                                  hintText: 'Company',
                                  prefixIcon: Icons.business_rounded,
                                ),
                                DsGap.md,
                                GlassTextField(
                                  controller: _schoolController,
                                  hintText: 'School / University',
                                  prefixIcon: Icons.school_rounded,
                                ),
                                DsGap.xl,
                                // Interests
                                _buildSectionHeader(context, isDark, 'Interests', 'Select up to 5', Icons.interests_rounded),
                                DsGap.md,
                                _buildInterestsGrid(context, isDark),
                                DsGap.xl,
                                // Favourites
                                _buildSectionHeader(context, isDark, 'Favourites', 'Share what you love', Icons.favorite_rounded),
                                DsGap.md,
                                _buildFavouritesSection(context, isDark),
                                DsGap.xxl,
                              ],
                            ),
                          ),
                        ),
                        _buildBottomButton(context, isDark, saving, state),
                      ],
                    ),
                  ),
                  if (saving)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: DsColors.primary),
                              DsGap.md,
                              Text('Setting up your profile...', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: DsEdgeInsets.horizontalXxl.copyWith(top: DsSpacing.md),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(CrushRoutes.idVerification);
            },
            size: 40,
          ),
          const Spacer(),
          Text(
            'Complete Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, bool isDark, ProfileState state) {
    final completeness = _calculateFormCompleteness(state);
    final percentage = completeness['percentage'] as double;
    final filledCount = completeness['filledCount'] as int;
    final totalCount = completeness['totalCount'] as int;
    final isEligible = completeness['isEligibleToSwipe'] as bool;
    final isFullyComplete = completeness['isFullyComplete'] as bool;
    final percentDisplay = (percentage * 100).round();

    return Padding(
      padding: DsEdgeInsets.horizontalXxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eligibility Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEligible
                    ? [DsColors.success.withValues(alpha: 0.15), DsColors.success.withValues(alpha: 0.05)]
                    : [DsColors.warning.withValues(alpha: 0.15), DsColors.warning.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEligible ? DsColors.success.withValues(alpha: 0.3) : DsColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEligible ? DsColors.success.withValues(alpha: 0.2) : DsColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEligible ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: isEligible ? DsColors.success : DsColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFullyComplete ? 'Profile Complete!' : 'Basic Profile Complete',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isEligible ? DsColors.success : DsColors.warning,
                            ),
                          ),
                          if (isEligible)
                            Text(
                              "You're eligible to start matching!",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DsColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isFullyComplete) ...[
                  DsGap.md,
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tips_and_updates_rounded, color: DsColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'We recommend completing all fields to get more matches and build trust with other users.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          DsGap.lg,
          // Progress bar section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$filledCount/$totalCount fields ($percentDisplay%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isFullyComplete ? DsColors.success : DsColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          DsGap.sm,
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: isDark ? DsColors.surfaceDark : DsColors.skeletonLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFullyComplete ? DsColors.success : DsColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isDark, String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DsColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DsColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSummary(BuildContext context, bool isDark, ProfileState state) {
    final profile = state.user?.profile;
    final username = state.user?.username ?? '';
    final name = profile?.name ?? '';
    final age = profile?.age ?? 0;
    final gender = profile?.gender ?? '';

    // Format gender for display
    String genderDisplay = '';
    if (gender.isNotEmpty) {
      genderDisplay = gender[0].toUpperCase() + gender.substring(1);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? DsColors.surfaceDark.withValues(alpha: 0.5)
            : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? DsColors.borderDark : DsColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DsColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded, color: DsColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Info',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'From your profile setup',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              GlassSmallButton(
                onPressed: () => context.push(CrushRoutes.basicInfo),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 14),
                    SizedBox(width: 4),
                    Text('Edit'),
                  ],
                ),
              ),
            ],
          ),
          DsGap.md,
          // Username row
          if (username.isNotEmpty) ...[
            _buildInfoRow(
              context,
              isDark,
              icon: Icons.alternate_email_rounded,
              label: 'Username',
              value: '@$username',
              isPrimary: true,
            ),
            DsGap.sm,
          ],
          // Name row
          if (name.isNotEmpty) ...[
            _buildInfoRow(
              context,
              isDark,
              icon: Icons.badge_outlined,
              label: 'Name',
              value: name,
            ),
            DsGap.sm,
          ],
          // Age and Gender row
          Row(
            children: [
              if (age > 0)
                Expanded(
                  child: _buildInfoRow(
                    context,
                    isDark,
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: '$age years',
                  ),
                ),
              if (age > 0 && genderDisplay.isNotEmpty)
                const SizedBox(width: 16),
              if (genderDisplay.isNotEmpty)
                Expanded(
                  child: _buildInfoRow(
                    context,
                    isDark,
                    icon: Icons.wc_rounded,
                    label: 'Gender',
                    value: genderDisplay,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    bool isPrimary = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isPrimary ? DsColors.primary : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isPrimary ? DsColors.primary : (isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight),
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsernameSection(BuildContext context, bool isDark, ProfileState state) {
    // Initialize username from user profile if not done yet
    if (!_usernameInitialized) {
      final currentUsername = state.user?.username ??
          context.read<AuthBloc>().state.user?.username ?? '';
      _usernameController.text = currentUsername;
      _usernameInitialized = true;
    }

    // Use CrushUser's username cooldown helpers (28-day restriction)
    final user = state.user;
    final canChangeUsername = user?.canChangeUsername ?? true;
    final daysUntilChange = user?.daysUntilUsernameChange ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          isDark,
          'Your Username',
          canChangeUsername ? 'You can change this once every 28 days' : 'Locked for $daysUntilChange more days',
          Icons.alternate_email_rounded,
        ),
        DsGap.md,
        if (_isEditingUsername) ...[
          GlassTextField(
            controller: _usernameController,
            hintText: 'Enter username',
            prefixIcon: Icons.alternate_email_rounded,
            errorText: _usernameErrorText(),
            enabled: canChangeUsername,
            onChanged: (value) {
              setState(() => _usernameTouched = true);
            },
          ),
          if (_usernameErrorText() == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                '3-20 characters, letters, numbers, or underscore',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                  fontSize: 11,
                ),
              ),
            ),
          DsGap.sm,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditingUsername = false;
                    _usernameTouched = false;
                    // Reset to original
                    final currentUsername = state.user?.username ??
                        context.read<AuthBloc>().state.user?.username ?? '';
                    _usernameController.text = currentUsername;
                  });
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassPrimaryButton(
                onPressed: _usernameErrorText() == null ? () {
                  setState(() => _isEditingUsername = false);
                } : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ] else ...[
          GestureDetector(
            onTap: () {
              if (canChangeUsername) {
                setState(() => _isEditingUsername = true);
              } else {
                // Show message that username is locked
                showErrorSnackBar(
                  context,
                  'You can change your username again in $daysUntilChange days',
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? DsColors.surfaceDark.withValues(alpha: 0.5)
                    : DsColors.inputFillLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: canChangeUsername ? DsColors.primary : Colors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canChangeUsername ? Icons.alternate_email_rounded : Icons.lock_rounded,
                    size: 22,
                    color: canChangeUsername ? DsColors.primary : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Username',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _usernameController.text.isNotEmpty
                              ? '@${_usernameController.text}'
                              : 'Not set',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canChangeUsername)
                    const Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: DsColors.primary,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '$daysUntilChange days',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!canChangeUsername)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Username changes are limited to once every 28 days. You can change it again in $daysUntilChange days.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildInterestsGrid(BuildContext context, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interestOptions.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        final canSelect = _selectedInterests.length < 5 || isSelected;

        return GestureDetector(
          onTap: canSelect
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? DsColors.primary.withValues(alpha: 0.15)
                  : (isDark ? DsColors.surfaceDark.withValues(alpha: 0.5) : DsColors.inputFillLight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? DsColors.primary : (isDark ? DsColors.borderDark : DsColors.borderLight),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              interest,
              style: TextStyle(
                color: isSelected
                    ? DsColors.primary
                    : (canSelect
                        ? (isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight)
                        : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight)),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavouritesSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildFavouriteSelector(context, isDark, label: 'Favourite Athlete', icon: Icons.sports_soccer_rounded, value: _favouriteAthlete, options: FavouritesOptions.athletes, onSelected: (val) => setState(() => _favouriteAthlete = val)),
        DsGap.md,
        _buildFavouriteSelector(context, isDark, label: 'Favourite Food', icon: Icons.restaurant_rounded, value: _favouriteFood, options: FavouritesOptions.foods, onSelected: (val) => setState(() => _favouriteFood = val)),
        DsGap.md,
        _buildFavouriteSelector(context, isDark, label: 'Favourite Sport', icon: Icons.sports_rounded, value: _favouriteSport, options: FavouritesOptions.sports, onSelected: (val) => setState(() => _favouriteSport = val)),
        DsGap.md,
        _buildFavouriteSelector(context, isDark, label: 'Favourite TV Show', icon: Icons.tv_rounded, value: _favouriteTvShow, options: FavouritesOptions.tvShows, onSelected: (val) => setState(() => _favouriteTvShow = val)),
        DsGap.md,
        _buildFavouriteSelector(context, isDark, label: 'Favourite Actor', icon: Icons.movie_rounded, value: _favouriteActor, options: FavouritesOptions.actors, onSelected: (val) => setState(() => _favouriteActor = val)),
        DsGap.md,
        _buildFavouriteSelector(context, isDark, label: 'Favourite Singer', icon: Icons.music_note_rounded, value: _favouriteSinger, options: FavouritesOptions.singers, onSelected: (val) => setState(() => _favouriteSinger = val)),
        DsGap.md,
        _buildFavouriteSelector(context, isDark, label: 'Favourite Movie', icon: Icons.local_movies_rounded, value: _favouriteMovie, options: FavouritesOptions.movies, onSelected: (val) => setState(() => _favouriteMovie = val)),
        DsGap.md,
        _buildFavouriteSelector(context, isDark, label: 'Favourite Hobby', icon: Icons.palette_rounded, value: _favouriteHobby, options: FavouritesOptions.hobbies, onSelected: (val) => setState(() => _favouriteHobby = val)),
      ],
    );
  }

  Widget _buildFavouriteSelector(BuildContext context, bool isDark, {required String label, required IconData icon, required String? value, required List<String> options, required ValueChanged<String?> onSelected}) {
    return GestureDetector(
      onTap: () => _showFavouriteBottomSheet(context, isDark, label, options, value, onSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value != null ? DsColors.primary.withValues(alpha: 0.1) : (isDark ? DsColors.surfaceDark.withValues(alpha: 0.5) : DsColors.inputFillLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value != null ? DsColors.primary : (isDark ? DsColors.borderDark : DsColors.borderLight), width: value != null ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: value != null ? DsColors.primary : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight, fontSize: 11)),
                  Text(value ?? 'Select...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: value != null ? (isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight) : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight), fontWeight: value != null ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight),
          ],
        ),
      ),
    );
  }

  void _showFavouriteBottomSheet(BuildContext context, bool isDark, String title, List<String> options, String? currentValue, ValueChanged<String?> onSelected) {
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        decoration: BoxDecoration(
          color: isDark ? DsColors.surfaceDark : DsColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: isDark ? DsColors.borderDark : DsColors.borderLight, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight)),
                  if (currentValue != null)
                    GestureDetector(
                      onTap: () { onSelected(null); Navigator.pop(ctx); },
                      child: Text('Clear', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: DsColors.primary, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? DsColors.borderDark : DsColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customController,
                      decoration: InputDecoration(
                        hintText: 'Or type your own...',
                        hintStyle: TextStyle(color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? DsColors.borderDark : DsColors.borderLight)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlassPrimaryButton(
                    onPressed: () { if (customController.text.trim().isNotEmpty) { onSelected(customController.text.trim()); Navigator.pop(ctx); } },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? DsColors.borderDark : DsColors.borderLight),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: options.length,
                itemBuilder: (ctx2, index) {
                  final option = options[index];
                  final isSelected = currentValue == option;
                  return ListTile(
                    onTap: () { onSelected(option); Navigator.pop(ctx); },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? DsColors.primary : Colors.transparent, border: Border.all(color: isSelected ? DsColors.primary : (isDark ? DsColors.borderDark : DsColors.borderLight), width: 2)),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                    title: Text(option, style: Theme.of(ctx2).textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight)),
                  );
                },
              ),
            ),
            DsGap.lg,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isDark, bool saving, ProfileState state) {
    final completeness = _calculateFormCompleteness(state);
    final isFullyComplete = completeness['isFullyComplete'] as bool;
    final percentDisplay = ((completeness['percentage'] as double) * 100).round();

    // Button text based on completion
    final buttonText = isFullyComplete
        ? 'Start Matching'
        : 'Start Matching ($percentDisplay% complete)';

    return Container(
      padding: DsEdgeInsets.allXxl.copyWith(bottom: DsSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [(isDark ? DsColors.backgroundDark : DsColors.backgroundLight).withValues(alpha: 0), isDark ? DsColors.backgroundDark : DsColors.backgroundLight],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFullyComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'You can always complete your profile later in Settings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: GlassPrimaryButton(
              onPressed: saving ? null : () => _submit(state),
              child: saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isFullyComplete ? Icons.favorite_rounded : Icons.play_arrow_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
