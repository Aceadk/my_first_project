import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/services/location_service.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/design_system/design_system.dart'
    hide ExcludeSemantics, MergeSemantics;
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/screens/permission_rationale_screen.dart';
import 'package:crushhour/features/discovery/domain/repositories/passport_locations_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';
import 'package:crushhour/shared/utils/profile_field_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  late final _mediaService = context.read<ProfileMediaRepository>();
  late final _passportService = context.read<PassportLocationsRepository>();

  List<String> _photoPaths = [];
  List<String> _videoPaths = [];
  final List<String> _selectedInterests = [];
  bool _uploading = false;
  bool _setupSaveInProgress = false;
  bool _usernameTouched = false;
  bool _usernameInitialized = false;
  bool _isEditingUsername = false;

  /// Flag to track when profile setup is complete and waiting for auth refresh
  bool _awaitingAuthRefresh = false;

  // Favourites
  String? _favouriteAthlete;
  String? _favouriteFood;
  String? _favouriteSport;
  String? _favouriteTvShow;
  String? _favouriteActor;
  String? _favouriteSinger;
  String? _favouriteMovie;
  String? _favouriteHobby;

  // Preferences
  String? _lookingFor; // Who to show in deck (male, female, everyone)
  bool _lookingForInitialized = false;

  // Location - CRITICAL for discovery to work
  double? _latitude;
  double? _longitude;
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    // No default favourites — user must actively choose
    _favouriteAthlete = null;

    // Show location permission rationale after the first frame so that
    // context is available for showing a dialog/bottom sheet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showLocationRationale();
      }
    });

    // Log onboarding step 5: profile_setup
    AnalyticsService.instance.logOnboardingStep(
      step: 'profile_setup',
      stepNumber: 5,
      totalSteps: 6,
    );
  }

  /// Show the location permission rationale screen before requesting the
  /// system permission. If the user taps "Allow", the system permission
  /// dialog is shown. If "Not Now", location is skipped.
  Future<void> _showLocationRationale() async {
    final l10n = AppLocalizations.of(context);
    if (_locationRequested) return;
    _locationRequested = true;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final textScale = mediaQuery.textScaler.scale(1);
        final sheetHeightFactor = textScale > 1.3 ? 1.0 : 0.85;
        return SizedBox(
          height: mediaQuery.size.height * sheetHeightFactor,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DsRadius.xxl),
            ),
            child: PermissionRationaleScreen(
              permissionType: PermissionType.location,
              title: l10n.onboardingProfileLocationRationaleTitle,
              description: l10n.onboardingProfileLocationRationaleDescription,
              icon: Icons.location_on_rounded,
              onAllow: () {
                Navigator.of(sheetContext).pop();
                _requestLocationForDiscovery();
              },
              onSkip: () {
                Navigator.of(sheetContext).pop();
                // User skipped — they can enable location later in Settings
                AppLogger.info(
                  'User skipped location permission during onboarding',
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Request location permission and capture coordinates.
  /// This is CRITICAL for the user to appear in other users' discovery decks.
  /// Without latitude/longitude, the Cloud Function cannot calculate distance
  /// and the user will not be shown to others.
  Future<void> _requestLocationForDiscovery() async {
    try {
      final locationService = LocationService.instance;

      // Request system permission
      final hasPermission = await locationService.requestPermission();
      if (!hasPermission) {
        // User denied permission at OS level - they can still complete
        // profile but won't appear in distance-based discovery
        return;
      }

      // Get current location with geocoding
      final location = await locationService.getCurrentLocation(
        includeGeocoding: true,
        timeout: const Duration(seconds: 20),
      );

      if (location != null && mounted) {
        setState(() {
          _latitude = location.latitude;
          _longitude = location.longitude;
          // Auto-fill city/country if empty
          if (_cityController.text.isEmpty && location.city != null) {
            _cityController.text = location.city!;
          }
          if (_countryController.text.isEmpty && location.country != null) {
            _countryController.text = location.country!;
          }
        });
      }
    } catch (e) {
      // Location capture failed - user can still complete profile
      // They just won't appear in distance-based discovery
      AppLogger.error('Location capture failed: $e');
    }
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
    final l10n = AppLocalizations.of(context);
    if (!_usernameTouched) return null;
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      return l10n.onboardingSignUpUsernameRequired;
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
    if (!valid) {
      return l10n.onboardingBasicInfoUsernameFormatError;
    }
    return null;
  }

  /// Calculate current form completion percentage based on filled fields
  /// Returns a map with 'percentage', 'filledCount', 'totalCount', and 'missingFields'
  Map<String, dynamic> _calculateFormCompleteness(ProfileState state) {
    final profile = state.user?.profile;
    final hasBasicInfo =
        profile != null &&
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
      missingFields.add(
        'Interests (${kMinInterests - _selectedInterests.length} more needed)',
      );
    }

    // Favourites (8 fields)
    if (_favouriteAthlete != null) {
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
      'isEligibleToSwipe':
          hasBasicInfo, // Basic info is enough to start swiping
      'isFullyComplete': filledCount == totalOptionalFields,
    };
  }

  final List<String> _interestOptions = [
    'Travel',
    'Music',
    'Movies',
    'Gaming',
    'Fitness',
    'Food',
    'Art',
    'Photography',
    'Reading',
    'Dancing',
    'Cooking',
    'Sports',
    'Fashion',
    'Technology',
    'Nature',
    'Pets',
    'Yoga',
    'Coffee',
    'Wine',
    'Hiking',
  ];

  Future<void> _submit(ProfileState state) async {
    final l10n = AppLocalizations.of(context);
    if (_uploading || _setupSaveInProgress || state.isSaving) return;

    final userId = state.user?.id;
    if (userId == null) {
      showErrorSnackBar(context, l10n.onboardingProfileSignInRequired);
      return;
    }

    // Check if user is skipping (no photos added)
    final isSkipping = _photoPaths.isEmpty;

    if (isSkipping) {
      // User is skipping - mark profile setup as skipped
      setState(() => _setupSaveInProgress = true);
      context.read<ProfileBloc>().add(ProfileSetupSkipped());
      return;
    }

    setState(() => _uploading = true);

    // Record location for passport mode tracking if provided
    if (_cityController.text.trim().isNotEmpty &&
        _countryController.text.trim().isNotEmpty) {
      await _passportService.recordLocation(
        _cityController.text.trim(),
        _countryController.text.trim(),
      );
    }

    final uploadResult = await _mediaService.ensureRemoteUrls(
      userId: userId,
      photoPaths: _photoPaths,
      videoPaths: _videoPaths,
    );

    if (!mounted) return;
    if (uploadResult.photoUrls.isEmpty) {
      showErrorSnackBar(context, l10n.errorMediaUploadFailed);
      setState(() => _uploading = false);
      return;
    }

    setState(() => _setupSaveInProgress = true);
    context.read<ProfileBloc>().add(
      ProfileDetailsSubmitted(
        bio: _bioController.text.trim(),
        photoUrls: uploadResult.photoUrls,
        videoUrls: uploadResult.videoUrls,
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
        showMeGenders: _lookingFor != null
            ? ProfileFieldOptions.lookingForToShowMeGenders(_lookingFor!)
            : null,
        // CRITICAL: Pass location for discovery distance filtering
        // Without these, the user won't appear in other users' discovery decks
        latitude: _latitude,
        longitude: _longitude,
      ),
    );

    if (mounted) {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardVisible = _isKeyboardVisible(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: isDark
                        ? [
                            DsColors.backgroundDark,
                            DsColors.secondary.withValues(alpha: 0.22),
                            DsColors.backgroundDark,
                          ]
                        : [
                            DsColors.backgroundLight,
                            DsColors.secondary.withValues(alpha: 0.08),
                            DsColors.backgroundLight,
                          ],
                  ),
                ),
                child: SafeArea(
                  child: MultiBlocListener(
                    listeners: [
                      // Listen for auth state changes to navigate after refresh
                      BlocListener<AuthBloc, AuthState>(
                        listenWhen: (previous, current) =>
                            _awaitingAuthRefresh &&
                            current.user?.hasCompletedProfileSetup == true,
                        listener: (context, authState) {
                          if (!_awaitingAuthRefresh) return;
                          _awaitingAuthRefresh = false;

                          // Check if coming from settings (can pop back)
                          if (context.canPop()) {
                            context.pop();
                            return;
                          }

                          // Check if we need email verification first
                          final user = authState.user;
                          if (user != null &&
                              user.email != null &&
                              user.email!.isNotEmpty &&
                              !user.isEmailVerified) {
                            context.go(CrushRoutes.emailVerification);
                            return;
                          }

                          // Log onboarding completion with total duration
                          final startTime =
                              AnalyticsService.instance.onboardingStartTime;
                          if (startTime != null) {
                            final durationSeconds = DateTime.now()
                                .difference(startTime)
                                .inSeconds;
                            AnalyticsService.instance.logOnboardingCompleted(
                              durationSeconds: durationSeconds,
                            );
                            AnalyticsService.instance.onboardingStartTime =
                                null; // Reset for next session
                          }

                          // Navigate to home - onboarding complete!
                          context.go(CrushRoutes.home);
                        },
                      ),
                      // Listen for profile save completion
                      BlocListener<ProfileBloc, ProfileState>(
                        listenWhen: (previous, current) =>
                            (previous.isSaving && !current.isSaving) ||
                            previous.errorMessage != current.errorMessage,
                        listener: (context, state) {
                          final setupSaveFinished =
                              _setupSaveInProgress && !state.isSaving;

                          if (setupSaveFinished) {
                            setState(() => _setupSaveInProgress = false);
                          }

                          // Profile save completed successfully
                          if (setupSaveFinished &&
                              state.user?.hasCompletedProfileSetup == true &&
                              state.errorMessage == null) {
                            // Set flag and trigger auth refresh
                            // Navigation will happen in AuthBloc listener after refresh
                            setState(() => _awaitingAuthRefresh = true);
                            context.read<AuthBloc>().add(
                              AuthUserRefreshRequested(),
                            );
                          }

                          // Show error if any
                          final error = state.errorMessage;
                          if (error != null && error.isNotEmpty) {
                            showErrorSnackBar(context, error);
                          }
                        },
                      ),
                    ],
                    child: BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        if (state.isLoading && state.user == null) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: DsColors.primary,
                            ),
                          );
                        }

                        final saving = _uploading || _setupSaveInProgress;
                        final textScale = MediaQuery.textScalerOf(
                          context,
                        ).scale(1);
                        final stableViewportHeight = MediaQuery.sizeOf(
                          context,
                        ).height;
                        final useWholePageScroll =
                            textScale > 1.3 || stableViewportHeight < 760;

                        return Stack(
                          children: [
                            AbsorbPointer(
                              absorbing: saving,
                              child: useWholePageScroll
                                  ? SingleChildScrollView(
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: const EdgeInsets.only(
                                        bottom: DsSpacing.xl,
                                      ),
                                      child: Column(
                                        children: [
                                          _buildAppBar(context, isDark),
                                          _buildProgressSlot(
                                            context,
                                            isDark,
                                            state,
                                            keyboardVisible,
                                          ),
                                          Padding(
                                            padding: DsEdgeInsets.horizontalXxl,
                                            child: _buildFormSections(
                                              context,
                                              isDark,
                                              state,
                                              saving,
                                            ),
                                          ),
                                          _buildBottomButton(
                                            context,
                                            isDark,
                                            saving,
                                            state,
                                            keyboardVisible,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        _buildAppBar(context, isDark),
                                        _buildProgressSlot(
                                          context,
                                          isDark,
                                          state,
                                          keyboardVisible,
                                        ),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            keyboardDismissBehavior:
                                                ScrollViewKeyboardDismissBehavior
                                                    .onDrag,
                                            padding: DsEdgeInsets.horizontalXxl,
                                            child: _buildFormSections(
                                              context,
                                              isDark,
                                              state,
                                              saving,
                                            ),
                                          ),
                                        ),
                                        _buildBottomButton(
                                          context,
                                          isDark,
                                          saving,
                                          state,
                                          keyboardVisible,
                                        ),
                                      ],
                                    ),
                            ),
                            if (saving)
                              Positioned.fill(
                                child: Container(
                                  color: DsColors.ink900.withValues(alpha: 0.3),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(
                                          color: DsColors.primary,
                                        ),
                                        DsGap.md,
                                        Text(
                                          l10n.onboardingProfileSettingUpProfile,
                                          style: const TextStyle(
                                            color: DsColors.surfaceLight,
                                          ),
                                        ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSections(
    BuildContext context,
    bool isDark,
    ProfileState state,
    bool saving,
  ) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional notice
        Semantics(
          container: true,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DsColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DsColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: DsColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.onboardingProfileAllFieldsOptional,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DsColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
        _buildSectionHeader(
          context,
          isDark,
          l10n.onboardingProfileYourPhotosTitle,
          l10n.onboardingProfileYourPhotosSubtitle,
          Icons.photo_library_rounded,
        ),
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
        _buildSectionHeader(
          context,
          isDark,
          l10n.profileAboutMe,
          l10n.onboardingProfileAboutYouSubtitle,
          Icons.edit_note_rounded,
        ),
        DsGap.md,
        GlassTextField(
          controller: _bioController,
          hintText: l10n.profileBioHint,
          maxLines: 4,
          maxLength: 500,
        ),
        DsGap.xl,
        // Looking For Section
        _buildSectionHeader(
          context,
          isDark,
          l10n.onboardingProfileLookingForTitle,
          l10n.onboardingProfileLookingForSubtitle,
          Icons.search_rounded,
        ),
        DsGap.md,
        _buildLookingForPicker(context, isDark, state),
        DsGap.xl,
        // Location Section
        _buildSectionHeader(
          context,
          isDark,
          l10n.profileLocation,
          l10n.onboardingProfileLocationSubtitle,
          Icons.location_on_rounded,
        ),
        DsGap.md,
        Row(
          children: [
            Expanded(
              child: GlassTextField(
                controller: _cityController,
                hintText: l10n.profileCity,
                prefixIcon: Icons.location_city_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassTextField(
                controller: _countryController,
                hintText: l10n.profileCountry,
                prefixIcon: Icons.public_rounded,
              ),
            ),
          ],
        ),
        DsGap.xl,
        // Work & Education
        _buildSectionHeader(
          context,
          isDark,
          l10n.onboardingProfileWorkEducationTitle,
          l10n.onboardingProfileOptionalSubtitle,
          Icons.work_outline_rounded,
        ),
        DsGap.md,
        GlassTextField(
          controller: _jobController,
          hintText: l10n.profileJobTitle,
          prefixIcon: Icons.badge_outlined,
        ),
        DsGap.md,
        GlassTextField(
          controller: _companyController,
          hintText: l10n.profileCompany,
          prefixIcon: Icons.business_rounded,
        ),
        DsGap.md,
        GlassTextField(
          controller: _schoolController,
          hintText: l10n.onboardingProfileSchoolUniversity,
          prefixIcon: Icons.school_rounded,
        ),
        DsGap.xl,
        // Interests
        _buildSectionHeader(
          context,
          isDark,
          l10n.profileInterests,
          l10n.onboardingProfileSelectUpToFive,
          Icons.interests_rounded,
        ),
        DsGap.md,
        _buildInterestsGrid(context, isDark),
        DsGap.xl,
        // Favourites
        _buildSectionHeader(
          context,
          isDark,
          l10n.onboardingProfileFavouritesTitle,
          l10n.onboardingProfileFavouritesSubtitle,
          Icons.favorite_rounded,
        ),
        DsGap.md,
        _buildFavouritesSection(context, isDark),
        DsGap.xxl,
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: DsEdgeInsets.horizontalXxl.copyWith(top: DsSpacing.md),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            semanticLabel: l10n.a11yBackButton,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(CrushRoutes.idVerification);
            },
            size: 40,
          ),
          DsGap.mdH,
          Expanded(
            child: Text(
              l10n.profileComplete,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? DsColors.textPrimaryDark
                    : DsColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    bool isDark,
    ProfileState state,
  ) {
    final l10n = AppLocalizations.of(context);
    final completeness = _calculateFormCompleteness(state);
    final percentage = completeness['percentage'] as double;
    final filledCount = completeness['filledCount'] as int;
    final totalCount = completeness['totalCount'] as int;
    final isEligible = completeness['isEligibleToSwipe'] as bool;
    final isFullyComplete = completeness['isFullyComplete'] as bool;
    final percentDisplay = (percentage * 100).round();
    final progressSemantics =
        StringBuffer(
            isFullyComplete
                ? l10n.onboardingProfileCompleteTitle
                : l10n.onboardingProfileBasicCompleteTitle,
          )
          ..write('. ')
          ..write(
            l10n.onboardingProfileCompletionCount(
              filledCount,
              totalCount,
              percentDisplay,
            ),
          );
    if (isEligible) {
      progressSemantics
        ..write('. ')
        ..write(l10n.onboardingProfileEligibleToStartMatching);
    } else {
      progressSemantics
        ..write('. ')
        ..write(l10n.onboardingProfileRecommendCompleteAll);
    }

    return Padding(
      padding: DsEdgeInsets.horizontalXxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eligibility Status Card
          Semantics(
            container: true,
            liveRegion: true,
            label: progressSemantics.toString(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEligible
                      ? [
                          DsColors.success.withValues(alpha: 0.15),
                          DsColors.success.withValues(alpha: 0.05),
                        ]
                      : [
                          DsColors.warning.withValues(alpha: 0.15),
                          DsColors.warning.withValues(alpha: 0.05),
                        ],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEligible
                      ? DsColors.success.withValues(alpha: 0.3)
                      : DsColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isEligible
                                ? DsColors.success.withValues(alpha: 0.2)
                                : DsColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEligible
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            color: isEligible
                                ? DsColors.success
                                : DsColors.warning,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFullyComplete
                                  ? l10n.onboardingProfileCompleteTitle
                                  : l10n.onboardingProfileBasicCompleteTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isEligible
                                        ? DsColors.success
                                        : DsColors.warning,
                                  ),
                            ),
                            if (isEligible)
                              Text(
                                l10n.onboardingProfileEligibleToStartMatching,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
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
                        color: isDark
                            ? DsColors.surfaceLight.withValues(alpha: 0.05)
                            : DsColors.ink900.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const ExcludeSemantics(
                            child: Icon(
                              Icons.tips_and_updates_rounded,
                              color: DsColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.onboardingProfileRecommendCompleteAll,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
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
          ),
          DsGap.lg,
          // Progress bar section
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.onboardingProfileCompletionLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  l10n.onboardingProfileCompletionCount(
                    filledCount,
                    totalCount,
                    percentDisplay,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isFullyComplete
                        ? DsColors.success
                        : DsColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
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
              backgroundColor: isDark
                  ? DsColors.surfaceDark
                  : DsColors.skeletonLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFullyComplete ? DsColors.success : DsColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DsColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: DsColors.primary, size: 20),
            ),
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
                    color: isDark
                        ? DsColors.textPrimaryDark
                        : DsColors.textPrimaryLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookingForPicker(
    BuildContext context,
    bool isDark,
    ProfileState state,
  ) {
    final l10n = AppLocalizations.of(context);
    // Initialize looking for based on gender if not already set
    if (!_lookingForInitialized) {
      final profile = state.user?.profile;
      final gender = profile?.gender;
      // Check if there's existing preference
      final existingPref = profile?.preferences.showMeGenders;
      if (existingPref != null && existingPref.isNotEmpty) {
        _lookingFor = ProfileFieldOptions.showMeGendersToLookingFor(
          existingPref,
        );
      } else {
        // Set default based on gender
        _lookingFor = ProfileFieldOptions.getDefaultLookingFor(gender);
      }
      _lookingForInitialized = true;
    }

    const options = ProfileFieldOptions.lookingForOptions;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = _lookingFor == option.value;
        void onSelect() => setState(() => _lookingFor = option.value);
        return Semantics(
          button: true,
          selected: isSelected,
          label: option.label,
          hint: isSelected ? null : l10n.a11yTapToSelect,
          onTap: onSelect,
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: onSelect,
              child: AnimatedContainer(
                duration: _a11yAnimationDuration(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DsColors.primary.withValues(alpha: 0.15)
                      : (isDark ? DsColors.surfaceDark : DsColors.surfaceLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? DsColors.primary
                        : (isDark ? DsColors.borderDark : DsColors.borderLight),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? DsColors.primary
                            : (isDark
                                  ? DsColors.textPrimaryDark
                                  : DsColors.textPrimaryLight),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: DsColors.primary,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBasicInfoSummary(
    BuildContext context,
    bool isDark,
    ProfileState state,
  ) {
    final l10n = AppLocalizations.of(context);
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
                child: const Icon(
                  Icons.person_rounded,
                  color: DsColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileBasicInfo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? DsColors.textPrimaryDark
                            : DsColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      l10n.onboardingProfileFromBasicInfoStep,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              GlassSmallButton(
                onPressed: () => context.push(CrushRoutes.basicInfo),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_rounded, size: 14),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context).edit),
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
              label: l10n.onboardingBasicInfoUsernameLabel,
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
              label: l10n.profileName,
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
                    label: l10n.profileAge,
                    value: l10n.onboardingBasicInfoYearsOld(age),
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
                    label: l10n.profileGender,
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
    return MergeSemantics(
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? DsColors.primary
                  : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isPrimary
                        ? DsColors.primary
                        : (isDark
                              ? DsColors.textPrimaryDark
                              : DsColors.textPrimaryLight),
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlot(
    BuildContext context,
    bool isDark,
    ProfileState state,
    bool keyboardVisible,
  ) {
    return AnimatedSize(
      duration: _a11yAnimationDuration(context),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: keyboardVisible
          ? const SizedBox(height: DsSpacing.sm)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsGap.lg,
                _buildProgressIndicator(context, isDark, state),
                DsGap.lg,
              ],
            ),
    );
  }

  Widget _buildUsernameSection(
    BuildContext context,
    bool isDark,
    ProfileState state,
  ) {
    final l10n = AppLocalizations.of(context);
    // Initialize username from user profile if not done yet
    if (!_usernameInitialized) {
      final currentUsername =
          state.user?.username ??
          context.read<AuthBloc>().state.user?.username ??
          '';
      _usernameController.text = currentUsername;
      _usernameInitialized = true;
    }

    // Use CrushUser's username cooldown helpers (28-day restriction)
    final user = state.user;
    final canChangeUsername = user?.canChangeUsername ?? true;
    final daysUntilChange = user?.daysUntilUsernameChange ?? 0;
    void editUsername() {
      if (canChangeUsername) {
        setState(() => _isEditingUsername = true);
      } else {
        // Show message that username is locked
        showErrorSnackBar(
          context,
          l10n.onboardingProfileUsernameChangeAgainInDays(daysUntilChange),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          isDark,
          l10n.onboardingProfileYourUsernameTitle,
          canChangeUsername
              ? l10n.onboardingProfileUsernameChangeEvery28Days
              : l10n.onboardingProfileUsernameLockedForDays(daysUntilChange),
          Icons.alternate_email_rounded,
        ),
        DsGap.md,
        if (_isEditingUsername) ...[
          Semantics(
            textField: true,
            label: l10n.onboardingBasicInfoUsernameLabel,
            hint: l10n.onboardingProfileEnterUsername,
            child: GlassTextField(
              controller: _usernameController,
              hintText: l10n.onboardingProfileEnterUsername,
              prefixIcon: Icons.alternate_email_rounded,
              errorText: _usernameErrorText(),
              enabled: canChangeUsername,
              onChanged: (value) {
                setState(() => _usernameTouched = true);
              },
            ),
          ),
          if (_usernameErrorText() == null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 6, start: 12),
              child: Text(
                l10n.onboardingBasicInfoUsernameRules,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
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
                    final currentUsername =
                        state.user?.username ??
                        context.read<AuthBloc>().state.user?.username ??
                        '';
                    _usernameController.text = currentUsername;
                  });
                },
                child: Text(
                  l10n.commonCancel,
                  style: TextStyle(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassPrimaryButton(
                onPressed: _usernameErrorText() == null
                    ? () {
                        setState(() => _isEditingUsername = false);
                      }
                    : null,
                child: Text(AppLocalizations.of(context).save),
              ),
            ],
          ),
        ] else ...[
          Semantics(
            button: true,
            label: l10n.onboardingBasicInfoUsernameLabel,
            value: _usernameController.text.isNotEmpty
                ? '@${_usernameController.text}'
                : l10n.onboardingProfileNotSet,
            hint: canChangeUsername
                ? l10n.a11yTapToEdit
                : l10n.onboardingProfileUsernameChangeAgainInDays(
                    daysUntilChange,
                  ),
            onTap: editUsername,
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: editUsername,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DsColors.surfaceDark.withValues(alpha: 0.5)
                        : DsColors.inputFillLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: canChangeUsername
                          ? DsColors.primary
                          : DsColors.warning,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        canChangeUsername
                            ? Icons.alternate_email_rounded
                            : Icons.lock_rounded,
                        size: 22,
                        color: canChangeUsername
                            ? DsColors.primary
                            : DsColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.onboardingBasicInfoUsernameLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                    fontSize: 11,
                                  ),
                            ),
                            Text(
                              _usernameController.text.isNotEmpty
                                  ? '@${_usernameController.text}'
                                  : l10n.onboardingProfileNotSet,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textPrimaryDark
                                        : DsColors.textPrimaryLight,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DsColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: DsColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.onboardingProfileDaysRemaining(
                                  daysUntilChange,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: DsColors.warning,
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
            ),
          ),
          if (!canChangeUsername)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
              child: Row(
                children: [
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.info_outline,
                      size: 14,
                      color: DsColors.warning,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.onboardingProfileUsernameChangesLimited(
                        daysUntilChange,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DsColors.warning,
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
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interestOptions.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        final canSelect = _selectedInterests.length < 5 || isSelected;
        void toggleInterest() {
          setState(() {
            if (isSelected) {
              _selectedInterests.remove(interest);
            } else {
              _selectedInterests.add(interest);
            }
          });
        }

        final onToggle = canSelect ? toggleInterest : null;

        return Semantics(
          button: true,
          enabled: canSelect,
          selected: isSelected,
          label: interest,
          hint: canSelect ? l10n.a11yTapToToggle : null,
          onTap: onToggle,
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: _a11yAnimationDuration(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DsColors.primary.withValues(alpha: 0.15)
                      : (isDark
                            ? DsColors.surfaceDark.withValues(alpha: 0.5)
                            : DsColors.inputFillLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? DsColors.primary
                        : (isDark ? DsColors.borderDark : DsColors.borderLight),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: isSelected
                        ? DsColors.primary
                        : (canSelect
                              ? (isDark
                                    ? DsColors.textPrimaryDark
                                    : DsColors.textPrimaryLight)
                              : (isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight)),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavouritesSection(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _buildFavouriteSelector(
          context,
          isDark,
          label: l10n.onboardingProfileFavouriteAthlete,
          icon: Icons.sports_soccer_rounded,
          value: _favouriteAthlete,
          options: FavouritesOptions.athletes,
          onSelected: (val) => setState(() => _favouriteAthlete = val),
        ),
        DsGap.md,
        _buildFavouriteSelector(
          context,
          isDark,
          label: l10n.onboardingProfileFavouriteFood,
          icon: Icons.restaurant_rounded,
          value: _favouriteFood,
          options: FavouritesOptions.foods,
          onSelected: (val) => setState(() => _favouriteFood = val),
        ),
        DsGap.md,
        _buildFavouriteSelector(
          context,
          isDark,
          label: l10n.onboardingProfileFavouriteSport,
          icon: Icons.sports_rounded,
          value: _favouriteSport,
          options: FavouritesOptions.sports,
          onSelected: (val) => setState(() => _favouriteSport = val),
        ),
        DsGap.md,
        _buildFavouriteSelector(
          context,
          isDark,
          label: l10n.onboardingProfileFavouriteTvShow,
          icon: Icons.tv_rounded,
          value: _favouriteTvShow,
          options: FavouritesOptions.tvShows,
          onSelected: (val) => setState(() => _favouriteTvShow = val),
        ),
        DsGap.md,
        _buildFavouriteSelector(
          context,
          isDark,
          label: l10n.onboardingProfileFavouriteActor,
          icon: Icons.movie_rounded,
          value: _favouriteActor,
          options: FavouritesOptions.actors,
          onSelected: (val) => setState(() => _favouriteActor = val),
        ),
        DsGap.md,
        _buildFavouriteSelector(
          context,
          isDark,
          label: l10n.onboardingProfileFavouriteSinger,
          icon: Icons.music_note_rounded,
          value: _favouriteSinger,
          options: FavouritesOptions.singers,
          onSelected: (val) => setState(() => _favouriteSinger = val),
        ),
        DsGap.md,
        _buildFavouriteSelector(
          context,
          isDark,
          label: l10n.onboardingProfileFavouriteMovie,
          icon: Icons.local_movies_rounded,
          value: _favouriteMovie,
          options: FavouritesOptions.movies,
          onSelected: (val) => setState(() => _favouriteMovie = val),
        ),
        DsGap.md,
        _buildFavouriteSelector(
          context,
          isDark,
          label: l10n.onboardingProfileFavouriteHobby,
          icon: Icons.palette_rounded,
          value: _favouriteHobby,
          options: FavouritesOptions.hobbies,
          onSelected: (val) => setState(() => _favouriteHobby = val),
        ),
      ],
    );
  }

  Widget _buildFavouriteSelector(
    BuildContext context,
    bool isDark, {
    required String label,
    required IconData icon,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    void openSelector() => _showFavouriteBottomSheet(
      context,
      isDark,
      label,
      options,
      value,
      onSelected,
    );
    return Semantics(
      button: true,
      label: label,
      value: value ?? l10n.onboardingProfileSelectPlaceholder,
      hint: value != null ? l10n.a11yTapToEdit : l10n.a11yTapToSelect,
      onTap: openSelector,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: openSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: value != null
                  ? DsColors.primary.withValues(alpha: 0.1)
                  : (isDark
                        ? DsColors.surfaceDark.withValues(alpha: 0.5)
                        : DsColors.inputFillLight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: value != null
                    ? DsColors.primary
                    : (isDark ? DsColors.borderDark : DsColors.borderLight),
                width: value != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: value != null
                      ? DsColors.primary
                      : (isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        value ?? l10n.onboardingProfileSelectPlaceholder,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: value != null
                              ? (isDark
                                    ? DsColors.textPrimaryDark
                                    : DsColors.textPrimaryLight)
                              : (isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight),
                          fontWeight: value != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFavouriteBottomSheet(
    BuildContext context,
    bool isDark,
    String title,
    List<String> options,
    String? currentValue,
    ValueChanged<String?> onSelected,
  ) {
    final l10n = AppLocalizations.of(context);
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark ? DsColors.surfaceDark : DsColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  margin: const EdgeInsetsDirectional.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? DsColors.borderDark : DsColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? DsColors.textPrimaryDark
                                : DsColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ),
                    if (currentValue != null)
                      Semantics(
                        button: true,
                        label: '${l10n.commonClear} $title',
                        onTap: () {
                          onSelected(null);
                          Navigator.pop(ctx);
                        },
                        child: GestureDetector(
                          onTap: () {
                            onSelected(null);
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            l10n.commonClear,
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: DsColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? DsColors.borderDark : DsColors.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        textField: true,
                        label: title,
                        hint: l10n.onboardingProfileOrTypeYourOwn,
                        child: TextField(
                          controller: customController,
                          decoration: InputDecoration(
                            hintText: l10n.onboardingProfileOrTypeYourOwn,
                            hintStyle: TextStyle(
                              color: isDark
                                  ? DsColors.textMutedDark
                                  : DsColors.textMutedLight,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? DsColors.borderDark
                                    : DsColors.borderLight,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassPrimaryButton(
                      semanticLabel:
                          '${AppLocalizations.of(context).add} $title',
                      onPressed: () {
                        if (customController.text.trim().isNotEmpty) {
                          onSelected(customController.text.trim());
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(AppLocalizations.of(context).add),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? DsColors.borderDark : DsColors.borderLight,
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: options.length,
                  itemBuilder: (ctx2, index) {
                    final option = options[index];
                    final isSelected = currentValue == option;
                    void selectOption() {
                      onSelected(option);
                      Navigator.pop(ctx);
                    }

                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: option,
                      hint: isSelected ? null : l10n.a11yTapToSelect,
                      onTap: selectOption,
                      child: ExcludeSemantics(
                        child: ListTile(
                          onTap: selectOption,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? DsColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? DsColors.primary
                                    : (isDark
                                          ? DsColors.borderDark
                                          : DsColors.borderLight),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: DsColors.surfaceLight,
                                  )
                                : null,
                          ),
                          title: Text(
                            option,
                            style: Theme.of(ctx2).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isDark
                                      ? DsColors.textPrimaryDark
                                      : DsColors.textPrimaryLight,
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              DsGap.lg,
            ],
          ),
        ),
      ),
    );
  }

  /// Handle "Skip for now" — requires at least 1 photo (Apple App Store requirement).
  void _handleSkip(ProfileState state) {
    final l10n = AppLocalizations.of(context);
    if (_photoPaths.isEmpty) {
      showErrorSnackBar(context, l10n.onboardingProfileAddPhotoBeforeSkip);
      return;
    }

    // Submit with whatever data the user has filled in so far
    _submit(state);
  }

  Widget _buildBottomButton(
    BuildContext context,
    bool isDark,
    bool saving,
    ProfileState state,
    bool keyboardVisible,
  ) {
    final l10n = AppLocalizations.of(context);
    final completeness = _calculateFormCompleteness(state);
    final isFullyComplete = completeness['isFullyComplete'] as bool;
    final percentDisplay = ((completeness['percentage'] as double) * 100)
        .round();

    // Button text based on completion
    final buttonText = isFullyComplete
        ? l10n.onboardingProfileStartMatching
        : l10n.onboardingProfileStartMatchingWithPercent(percentDisplay);

    if (keyboardVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: DsEdgeInsets.allXxl.copyWith(bottom: DsSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? DsColors.backgroundDark : DsColors.backgroundLight)
                .withValues(alpha: 0),
            isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFullyComplete)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 12),
              child: Text(
                l10n.onboardingProfileCompleteLaterInSettings,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: GlassPrimaryButton(
              semanticLabel:
                  l10n.onboardingProfileSaveAndStartMatchingSemantics,
              onPressed: saving ? null : () => _submit(state),
              child: saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DsColors.surfaceLight,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFullyComplete
                              ? Icons.favorite_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          buttonText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // Skip for now button — only shown when profile is not fully complete
          if (!isFullyComplete && !saving) ...[
            DsGap.sm,
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: l10n.onboardingProfileSkipSemantics,
                child: GlassOutlinedButton(
                  semanticLabel: l10n.authSkipForNow,
                  onPressed: () => _handleSkip(state),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.skip_next_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.authSkipForNow,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isKeyboardVisible(BuildContext context) {
    final mediaQueryInsetBottom =
        MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0;
    final view = View.maybeOf(context);
    final viewInsetBottom = view == null
        ? 0.0
        : view.viewInsets.bottom / view.devicePixelRatio;
    return mediaQueryInsetBottom > 0 || viewInsetBottom > 0;
  }

  Duration _a11yAnimationDuration(
    BuildContext context, {
    int milliseconds = 200,
  }) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: milliseconds);
  }
}
