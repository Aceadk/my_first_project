import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/shared/utils/profile_field_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'female';
  String? _orientation;
  bool _usernameTouched = false;
  bool _birthdateTouched = false;
  bool _hasShownAgeWarning = false;
  bool _isSubmitting = false; // Track if we initiated a save
  bool _hasPrefilledUsername = false; // Track if username was pre-filled
  bool _isCheckingUsernameAvailability = false;
  bool? _isUsernameAvailable;
  String? _lastCheckedUsername;
  Timer? _usernameDebounceTimer;

  /// Calculate age from date of birth
  int? get _calculatedAge {
    if (_dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - _dateOfBirth!.year;
    if (today.month < _dateOfBirth!.month ||
        (today.month == _dateOfBirth!.month && today.day < _dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();

    // Log onboarding step 3: basic_info
    AnalyticsService.instance.logOnboardingStep(
      step: 'basic_info',
      stepNumber: 3,
      totalSteps: 6,
    );
  }

  @override
  void dispose() {
    _usernameDebounceTimer?.cancel();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
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
          child: BlocConsumer<ProfileBloc, ProfileState>(
            listenWhen: (previous, current) =>
                (previous.isSaving && !current.isSaving) ||
                previous.errorMessage != current.errorMessage,
            listener: (context, state) {
              // Debug logging
              AppLogger.debug(
                '[BasicInfo] Listener triggered: isSaving=${state.isSaving}, _isSubmitting=$_isSubmitting, hasUser=${state.user != null}, hasCompletedBasicInfo=${state.user?.hasCompletedBasicInfo}, error=${state.errorMessage}',
              );

              // Navigate when our save completes successfully (no error)
              if (_isSubmitting && !state.isSaving) {
                _isSubmitting = false; // Reset the flag

                if (state.errorMessage == null) {
                  AppLogger.debug(
                    '[BasicInfo] Save successful, navigating to idVerification',
                  );
                  context.read<AuthBloc>().add(AuthUserRefreshRequested());
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(CrushRoutes.idVerification);
                  return;
                }
              }

              // Show error if any
              final error = state.errorMessage;
              if (error != null && error.isNotEmpty) {
                AppLogger.debug('[BasicInfo] Showing error: $error');
                showErrorSnackBar(context, error);
              }
            },
            builder: (context, state) {
              // Pre-fill username from signup if available and not yet pre-filled
              if (!_hasPrefilledUsername) {
                final existingUsername = state.user?.username;
                if (existingUsername != null && existingUsername.isNotEmpty) {
                  // Use addPostFrameCallback to avoid setting state during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_hasPrefilledUsername) {
                      _usernameController.text = existingUsername;
                      _hasPrefilledUsername = true;
                    }
                  });
                }
              }

              final isBusy = state.isSaving;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = DsBreakpoints.responsiveValue<double>(
                    constraints.maxWidth,
                    mobile: double.infinity,
                    tablet: 480,
                    desktop: 480,
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(),
                        child: Stack(
                          children: [
                            AbsorbPointer(
                              absorbing: isBusy,
                              child: Column(
                                children: [
                                  // Custom App Bar
                                  Padding(
                                    padding: DsEdgeInsets.horizontalXxl
                                        .copyWith(top: DsSpacing.md),
                                    child: Row(
                                      children: [
                                        GlassIconButton(
                                          icon:
                                              Icons.arrow_back_ios_new_rounded,
                                          onPressed: isBusy ? null : _goBack,
                                          size: 40,
                                        ),
                                        DsGap.mdH,
                                        Expanded(
                                          child: Text(
                                            l10n.onboardingBasicInfoTitle,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? DsColors.textPrimaryDark
                                                      : DsColors
                                                            .textPrimaryLight,
                                                ),
                                          ),
                                        ),
                                        // Spacer for layout balance
                                        const SizedBox(width: 40),
                                      ],
                                    ),
                                  ),
                                  DsGap.lg,
                                  // Progress Indicator
                                  Padding(
                                    padding: DsEdgeInsets.horizontalXxl,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                l10n.onboardingStep(3, 6),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: DsColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Text(
                                                l10n.onboardingBasicInfoSubtitle,
                                                textAlign: TextAlign.end,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: isDark
                                                          ? DsColors
                                                                .textMutedDark
                                                          : DsColors
                                                                .textMutedLight,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        DsGap.sm,
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: 0.6,
                                            minHeight: 6,
                                            backgroundColor: isDark
                                                ? DsColors.surfaceDark
                                                : DsColors.skeletonLight,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(DsColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DsGap.xl,
                                  // Form Content
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: DsEdgeInsets.horizontalXxl,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Username Field
                                          _buildSectionLabel(
                                            context,
                                            l10n.onboardingBasicInfoUsernameLabel,
                                            isDark,
                                            true,
                                          ),
                                          DsGap.sm,
                                          Semantics(
                                            textField: true,
                                            label: l10n
                                                .onboardingBasicInfoUsernameLabel,
                                            hint: l10n
                                                .onboardingBasicInfoUsernameHint,
                                            child: GlassTextField(
                                              controller: _usernameController,
                                              hintText: l10n
                                                  .onboardingBasicInfoUsernameHint,
                                              prefixIcon:
                                                  Icons.alternate_email_rounded,
                                              errorText: _usernameErrorText(),
                                              helperText: _usernameHelperText(),
                                              onChanged: _onUsernameChanged,
                                            ),
                                          ),
                                          DsGap.lg,
                                          // First Name Field
                                          _buildSectionLabel(
                                            context,
                                            l10n.onboardingBasicInfoFirstNameLabel,
                                            isDark,
                                            false,
                                          ),
                                          DsGap.sm,
                                          Semantics(
                                            textField: true,
                                            label: l10n
                                                .onboardingBasicInfoFirstNameLabel,
                                            hint: l10n
                                                .onboardingBasicInfoFirstNameHint,
                                            child: GlassTextField(
                                              controller: _firstNameController,
                                              hintText: l10n
                                                  .onboardingBasicInfoFirstNameHint,
                                              prefixIcon:
                                                  Icons.person_outline_rounded,
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                          DsGap.lg,
                                          // Last Name Field
                                          _buildSectionLabel(
                                            context,
                                            l10n.onboardingBasicInfoLastNameLabel,
                                            isDark,
                                            false,
                                          ),
                                          DsGap.sm,
                                          Semantics(
                                            textField: true,
                                            label: l10n
                                                .onboardingBasicInfoLastNameLabel,
                                            hint: l10n
                                                .onboardingBasicInfoLastNameHint,
                                            child: GlassTextField(
                                              controller: _lastNameController,
                                              hintText: l10n
                                                  .onboardingBasicInfoLastNameHint,
                                              prefixIcon: Icons.badge_outlined,
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                          DsGap.lg,
                                          // Birthdate Field
                                          _buildSectionLabel(
                                            context,
                                            l10n.onboardingBasicInfoBirthdateLabel,
                                            isDark,
                                            true,
                                          ),
                                          DsGap.sm,
                                          _buildBirthdatePicker(
                                            context,
                                            isDark,
                                          ),
                                          DsGap.xl,
                                          // Gender Selection
                                          _buildSectionLabel(
                                            context,
                                            l10n.onboardingSelectGender,
                                            isDark,
                                            true,
                                          ),
                                          DsGap.sm,
                                          Row(
                                            children: ProfileFieldOptions
                                                .onboardingGenderValues
                                                .map(
                                                  (genderValue) => Expanded(
                                                    child: Padding(
                                                      padding: EdgeInsetsDirectional.only(
                                                        end:
                                                            genderValue !=
                                                                ProfileFieldOptions
                                                                    .onboardingGenderValues
                                                                    .last
                                                            ? 10
                                                            : 0,
                                                      ),
                                                      child: _buildGenderTile(
                                                        context,
                                                        genderValue,
                                                        _localizedGenderLabel(
                                                          l10n,
                                                          genderValue,
                                                        ),
                                                        _genderIcon(
                                                          genderValue,
                                                        ),
                                                        isDark,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                          DsGap.xl,
                                          // Sexual Orientation
                                          _buildSectionLabel(
                                            context,
                                            l10n.profileSexualOrientation,
                                            isDark,
                                            false,
                                          ),
                                          DsGap.sm,
                                          _buildOrientationSelector(
                                            context,
                                            isDark,
                                          ),
                                          DsGap.xs,
                                          Semantics(
                                            label: l10n
                                                .onboardingBasicInfoOrientationOptionalSemantics,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional.only(
                                                    start: 4,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline_rounded,
                                                    size: 14,
                                                    color: isDark
                                                        ? DsColors.textMutedDark
                                                        : DsColors
                                                              .textMutedLight,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      l10n.onboardingBasicInfoOrientationOptionalHelper,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: isDark
                                                                ? DsColors
                                                                      .textMutedDark
                                                                : DsColors
                                                                      .textMutedLight,
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DsGap.xxl,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Bottom Button Area
                                  Container(
                                    padding: DsEdgeInsets.allXxl.copyWith(
                                      bottom: DsSpacing.xl,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          (isDark
                                                  ? DsColors.backgroundDark
                                                  : DsColors.backgroundLight)
                                              .withValues(alpha: 0),
                                          isDark
                                              ? DsColors.backgroundDark
                                              : DsColors.backgroundLight,
                                        ],
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Semantics(
                                        button: true,
                                        label: l10n.commonContinue,
                                        child: GlassPrimaryButton(
                                          onPressed: isBusy
                                              ? null
                                              : _handleNext,
                                          child: isBusy
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: DsColors
                                                            .surfaceLight,
                                                      ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      l10n.commonContinue,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isBusy)
                              Positioned.fill(
                                child: Container(
                                  color: DsColors.ink900.withValues(alpha: 0.3),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: DsColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String label,
    bool isDark,
    bool isRequired,
  ) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: label, style: labelStyle),
          if (isRequired)
            TextSpan(
              text: ' *',
              style: labelStyle?.copyWith(color: DsColors.error),
            ),
        ],
      ),
    );
  }

  String _humanizeOptionValue(String value) {
    return value
        .split('_')
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _localizedGenderLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'female':
        return l10n.wordFemale;
      case 'male':
        return l10n.wordMale;
      case 'non_binary':
        return l10n.wordNonBinary;
      default:
        return _humanizeOptionValue(value);
    }
  }

  IconData _genderIcon(String value) {
    switch (value) {
      case 'female':
        return Icons.female;
      case 'male':
        return Icons.male;
      case 'non_binary':
        return Icons.transgender;
      default:
        return Icons.person_outline_rounded;
    }
  }

  String _localizedOrientationLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'straight':
        return l10n.orientationStraight;
      case 'gay':
        return l10n.orientationGay;
      case 'lesbian':
        return l10n.orientationLesbian;
      case 'bisexual':
        return l10n.orientationBisexual;
      case 'pansexual':
        return l10n.orientationPansexual;
      case 'asexual':
        return l10n.orientationAsexual;
      case 'queer':
        return l10n.orientationQueer;
      case 'questioning':
        return l10n.orientationQuestioning;
      case 'prefer_not_say':
        return l10n.orientationPreferNotToSay;
      default:
        return _humanizeOptionValue(value);
    }
  }

  Widget _buildGenderTile(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _gender == value;

    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? DsColors.primary.withValues(alpha: 0.15)
                : (isDark
                      ? DsColors.surfaceDark.withValues(alpha: 0.5)
                      : DsColors.inputFillLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? DsColors.primary
                  : (isDark ? DsColors.borderDark : DsColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? DsColors.primary
                    : (isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? DsColors.primary
                      : (isDark
                            ? DsColors.textPrimaryDark
                            : DsColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthdatePicker(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final errorText = _birthdateErrorText();
    final hasError = errorText != null;

    String displayText;
    if (_dateOfBirth != null) {
      final age = _calculatedAge;
      displayText = MaterialLocalizations.of(
        context,
      ).formatMediumDate(_dateOfBirth!);
      if (age != null) {
        displayText += ' (${l10n.onboardingBasicInfoYearsOld(age)})';
      }
    } else {
      displayText = l10n.onboardingBasicInfoSelectBirthdate;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: l10n.onboardingBasicInfoBirthdateLabel,
          value: displayText,
          child: GestureDetector(
            onTap: () => _showBirthdatePicker(context, isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? DsColors.surfaceDark.withValues(alpha: 0.5)
                    : DsColors.inputFillLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasError
                      ? DsColors.error
                      : (_dateOfBirth != null
                            ? DsColors.primary
                            : (isDark
                                  ? DsColors.borderDark
                                  : DsColors.borderLight)),
                  width: (_dateOfBirth != null || hasError) ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    size: 22,
                    color: hasError
                        ? DsColors.error
                        : (_dateOfBirth != null
                              ? DsColors.primary
                              : (isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _dateOfBirth != null
                            ? (isDark
                                  ? DsColors.textPrimaryDark
                                  : DsColors.textPrimaryLight)
                            : (isDark
                                  ? DsColors.textMutedDark
                                  : DsColors.textMutedLight),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, start: 12),
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DsColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showBirthdatePicker(BuildContext context, bool isDark) async {
    _markBirthdateTouched();
    final l10n = AppLocalizations.of(context);

    final now = DateTime.now();
    final minDate = DateTime(now.year - 75, now.month, now.day);
    final maxDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: l10n.onboardingBasicInfoBirthdateHelpText,
      cancelText: l10n.commonCancel,
      confirmText: l10n.commonConfirm,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: DsColors.primary,
                    onPrimary: DsColors.surfaceLight,
                    surface: DsColors.surfaceDark,
                    onSurface: DsColors.textPrimaryDark,
                  )
                : const ColorScheme.light(
                    primary: DsColors.primary,
                    onPrimary: DsColors.surfaceLight,
                    surface: DsColors.backgroundLight,
                    onSurface: DsColors.textPrimaryLight,
                  ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Widget _buildOrientationSelector(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.profileSexualOrientation,
      value: _orientation != null
          ? _localizedOrientationLabel(l10n, _orientation!)
          : l10n.onboardingOrientationOptionalPrompt,
      child: GestureDetector(
        onTap: () => _showOrientationBottomSheet(context, isDark),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? DsColors.surfaceDark.withValues(alpha: 0.5)
                : DsColors.inputFillLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _orientation != null
                  ? DsColors.primary
                  : (isDark ? DsColors.borderDark : DsColors.borderLight),
              width: _orientation != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 22,
                color: _orientation != null
                    ? DsColors.primary
                    : (isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _orientation != null
                      ? _localizedOrientationLabel(l10n, _orientation!)
                      : l10n.onboardingOrientationOptionalPrompt,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _orientation != null
                        ? (isDark
                              ? DsColors.textPrimaryDark
                              : DsColors.textPrimaryLight)
                        : (isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight),
                  ),
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
    );
  }

  void _showOrientationBottomSheet(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? DsColors.surfaceDark : DsColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsetsDirectional.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? DsColors.borderDark : DsColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.profileSexualOrientation,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? DsColors.textPrimaryDark
                          : DsColors.textPrimaryLight,
                    ),
                  ),
                  if (_orientation != null)
                    Semantics(
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _orientation = null);
                          Navigator.pop(context);
                        },
                        child: Text(
                          l10n.clear,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: ProfileFieldOptions
                    .onboardingSexualOrientationValues
                    .length,
                itemBuilder: (context, index) {
                  final option = ProfileFieldOptions
                      .onboardingSexualOrientationValues[index];
                  final isSelected = _orientation == option;

                  return ListTile(
                    onTap: () {
                      setState(() => _orientation = option);
                      Navigator.pop(context);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
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
                      _localizedOrientationLabel(l10n, option),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isDark
                            ? DsColors.textPrimaryDark
                            : DsColors.textPrimaryLight,
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
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    // Determine fallback based on sign-up method actually used
    final authState = context.read<AuthBloc>().state;
    final phone = authState.phoneInProgress;
    final email = authState.emailInProgress ?? authState.emailOtpIdentifier;
    if (phone != null && phone.isNotEmpty) {
      final encoded = Uri.encodeComponent(phone);
      context.go('${CrushRoutes.otp}?phone=$encoded');
    } else if (email != null && email.isNotEmpty) {
      context.go(CrushRoutes.emailAuth);
    } else {
      context.go(CrushRoutes.authGateway);
    }
  }

  void _onUsernameChanged(String value) {
    _markUsernameTouched();

    setState(() {
      _isCheckingUsernameAvailability = false;
      _isUsernameAvailable = null;
      _lastCheckedUsername = null;
    });

    _queueUsernameAvailabilityCheck();
  }

  String? _usernameHelperText() {
    final l10n = AppLocalizations.of(context);
    if (_usernameErrorText() != null) return null;
    if (_isCheckingUsernameAvailability) {
      return l10n.onboardingBasicInfoUsernameCheckingAvailability;
    }
    if (_isUsernameAvailable == true) {
      return l10n.onboardingBasicInfoUsernameAvailable;
    }
    return l10n.onboardingBasicInfoUsernameRules;
  }

  void _markUsernameTouched() {
    if (!_usernameTouched) {
      setState(() {
        _usernameTouched = true;
      });
    }
  }

  bool _isUsernameFormatValid(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  void _queueUsernameAvailabilityCheck({bool immediate = false}) {
    final username = _usernameController.text.trim();
    final profileRepo = context.read<ProfileRepository>();
    _usernameDebounceTimer?.cancel();
    if (!_isUsernameFormatValid(username) ||
        profileRepo is! UsernameAvailabilityProfileRepository) {
      return;
    }
    final availabilityRepo =
        profileRepo as UsernameAvailabilityProfileRepository;
    _usernameDebounceTimer = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 450),
      () => _checkUsernameAvailability(
        username: username,
        repo: availabilityRepo,
      ),
    );
  }

  Future<bool?> _checkUsernameAvailability({
    required String username,
    required UsernameAvailabilityProfileRepository repo,
  }) async {
    if (!mounted) return null;

    setState(() {
      _isCheckingUsernameAvailability = true;
    });

    try {
      final available = await repo.isUsernameAvailable(username: username);
      if (!mounted) {
        return available;
      }

      if (_usernameController.text.trim() != username) {
        setState(() {
          _isCheckingUsernameAvailability = false;
        });
        return available;
      }

      setState(() {
        _isCheckingUsernameAvailability = false;
        _isUsernameAvailable = available;
        _lastCheckedUsername = username;
      });
      return available;
    } catch (e) {
      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _isCheckingUsernameAvailability = false;
          _isUsernameAvailable = null;
          _lastCheckedUsername = null;
        });
      }
      AppLogger.error(
        '[BasicInfo] Username availability check failed',
        error: e,
      );
      return null;
    }
  }

  Future<bool> _ensureUsernameAvailable() async {
    final username = _usernameController.text.trim();
    final profileRepo = context.read<ProfileRepository>();
    if (profileRepo is! UsernameAvailabilityProfileRepository) {
      return true;
    }
    final availabilityRepo =
        profileRepo as UsernameAvailabilityProfileRepository;

    if (_lastCheckedUsername == username && _isUsernameAvailable != null) {
      return _isUsernameAvailable!;
    }

    final available = await _checkUsernameAvailability(
      username: username,
      repo: availabilityRepo,
    );
    return available ?? true;
  }

  String? _usernameErrorText() {
    final l10n = AppLocalizations.of(context);
    if (!_usernameTouched) return null;
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      return l10n.onboardingBasicInfoUsernameRequired;
    }
    if (!_isUsernameFormatValid(username)) {
      return l10n.onboardingBasicInfoUsernameFormatError;
    }
    if (_lastCheckedUsername == username && _isUsernameAvailable == false) {
      return l10n.onboardingBasicInfoUsernameTaken;
    }
    return null;
  }

  void _markBirthdateTouched() {
    if (!_birthdateTouched) {
      setState(() {
        _birthdateTouched = true;
      });
    }
  }

  String? _birthdateErrorText() {
    final l10n = AppLocalizations.of(context);
    if (!_birthdateTouched) return null;
    if (_dateOfBirth == null) {
      return l10n.onboardingBasicInfoBirthdateRequired;
    }
    final age = _calculatedAge;
    if (age == null) {
      return l10n.onboardingBasicInfoBirthdateInvalid;
    }
    if (age < 18) {
      return l10n.onboardingBasicInfoBirthdateTooYoung;
    }
    if (age > 75) {
      return l10n.onboardingBasicInfoBirthdateTooOld;
    }
    return null;
  }

  Future<void> _handleNext() async {
    setState(() {
      _usernameTouched = true;
      _birthdateTouched = true;
    });
    final usernameError = _usernameErrorText();
    if (usernameError != null) {
      showErrorSnackBar(context, usernameError);
      return;
    }

    final isUsernameAvailable = await _ensureUsernameAvailable();
    if (!mounted) return;
    if (!isUsernameAvailable) {
      setState(() {
        _usernameTouched = true;
      });
      showErrorSnackBar(
        context,
        AppLocalizations.of(context).onboardingBasicInfoUsernameTaken,
      );
      return;
    }

    final birthdateError = _birthdateErrorText();
    if (birthdateError != null) {
      showErrorSnackBar(context, birthdateError);
      return;
    }
    final age = _calculatedAge ?? 0;
    final profileBloc = context.read<ProfileBloc>();
    // Show warning for users aged 70-75
    final proceed = await _showAgeWarningIfNeeded(age);
    if (!proceed) return;
    if (!mounted) return;

    // Set flag so listener knows to navigate on success
    setState(() => _isSubmitting = true);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    profileBloc.add(
      ProfileBasicInfoSubmitted(
        username: _usernameController.text.trim(),
        name: firstName,
        lastName: lastName.isEmpty ? null : lastName,
        age: age,
        gender: _gender,
        sexualOrientation: _orientation,
        dateOfBirth: _dateOfBirth,
      ),
    );
  }

  Future<bool> _showAgeWarningIfNeeded(int age) async {
    if (age >= 70 && age <= 75 && !_hasShownAgeWarning) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark
              ? DsColors.surfaceDark
              : DsColors.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DsColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.elderly, color: DsColors.warning, size: 40),
          ),
          title: Text(
            AppLocalizations.of(context).ageNotice,
            style: TextStyle(
              color: isDark
                  ? DsColors.textPrimaryDark
                  : DsColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppLocalizations.of(context).onboardingBasicInfoAgeWarningBody,
            style: TextStyle(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? DsColors.textMutedDark
                    : DsColors.textMutedLight,
              ),
              child: Text(AppLocalizations.of(context).goBack),
            ),
            const SizedBox(width: 8),
            GlassPrimaryButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context).continueAnyway),
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
