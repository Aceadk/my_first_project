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
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'female';
  String? _orientation;
  bool _usernameTouched = false;
  bool _birthdateTouched = false;
  bool _hasShownAgeWarning = false;

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

  final List<Map<String, dynamic>> _genderOptions = [
    {'value': 'female', 'label': 'Female', 'icon': Icons.female},
    {'value': 'male', 'label': 'Male', 'icon': Icons.male},
    {'value': 'nonbinary', 'label': 'Non-binary', 'icon': Icons.transgender},
  ];

  final List<String> _orientationOptions = [
    'Straight',
    'Gay',
    'Lesbian',
    'Bisexual',
    'Pansexual',
    'Asexual',
    'Queer',
    'Questioning',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
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
                ? [
                    DsColors.backgroundDark,
                    const Color(0xFF1A1A2E),
                    DsColors.backgroundDark,
                  ]
                : [
                    DsColors.backgroundLight,
                    const Color(0xFFF8F0FF),
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
              // Navigate when save completes successfully
              if (!state.isSaving && state.user?.hasCompletedBasicInfo == true && state.errorMessage == null) {
                // Refresh auth state so router has updated user data
                context.read<AuthBloc>().add(AuthUserRefreshRequested());
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
                        // Custom App Bar
                        Padding(
                          padding: DsEdgeInsets.horizontalXxl.copyWith(
                            top: DsSpacing.md,
                          ),
                          child: Row(
                            children: [
                              GlassIconButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onPressed: isBusy ? null : _goBack,
                                size: 40,
                              ),
                              const Spacer(),
                              Text(
                                'Basic Info',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? DsColors.textPrimaryDark
                                          : DsColors.textPrimaryLight,
                                    ),
                              ),
                              const Spacer(),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Step 3 of 5',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: DsColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    'Tell us about you',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? DsColors.textMutedDark
                                              : DsColors.textMutedLight,
                                        ),
                                  ),
                                ],
                              ),
                              DsGap.sm,
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.6,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? DsColors.surfaceDark
                                      : DsColors.skeletonLight,
                                  valueColor: const AlwaysStoppedAnimation<
                                      Color>(DsColors.primary),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username Field
                                _buildSectionLabel(
                                    context, 'Username', isDark, true),
                                DsGap.sm,
                                GlassTextField(
                                  controller: _usernameController,
                                  hintText: 'Choose a unique username',
                                  prefixIcon: Icons.alternate_email_rounded,
                                  errorText: _usernameErrorText(),
                                  onChanged: (value) {
                                    _markUsernameTouched();
                                    setState(() {});
                                  },
                                ),
                                if (_usernameErrorText() == null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 6, left: 12),
                                    child: Text(
                                      '3-20 characters, letters, numbers, or underscore',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? DsColors.textMutedDark
                                                : DsColors.textMutedLight,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ),
                                DsGap.lg,
                                // Display Name Field
                                _buildSectionLabel(
                                    context, 'Display Name', isDark, false),
                                DsGap.sm,
                                GlassTextField(
                                  controller: _nameController,
                                  hintText: 'What should we call you?',
                                  prefixIcon: Icons.person_outline_rounded,
                                  onChanged: (_) => setState(() {}),
                                ),
                                DsGap.lg,
                                // Birthdate Field
                                _buildSectionLabel(
                                    context, 'Date of Birth', isDark, true),
                                DsGap.sm,
                                _buildBirthdatePicker(context, isDark),
                                DsGap.xl,
                                // Gender Selection
                                _buildSectionLabel(
                                    context, 'Gender', isDark, true),
                                DsGap.sm,
                                Row(
                                  children: _genderOptions
                                      .map((option) => Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: option !=
                                                        _genderOptions.last
                                                    ? 10
                                                    : 0,
                                              ),
                                              child: _buildGenderTile(
                                                context,
                                                option['value'] as String,
                                                option['label'] as String,
                                                option['icon'] as IconData,
                                                isDark,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                                DsGap.xl,
                                // Sexual Orientation
                                _buildSectionLabel(context,
                                    'Sexual Orientation', isDark, false),
                                DsGap.sm,
                                _buildOrientationSelector(context, isDark),
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
                            child: GlassPrimaryButton(
                              onPressed: isBusy ? null : () => _handleNext(context),
                              child: isBusy
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Continue',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
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
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: DsColors.primary,
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

  Widget _buildSectionLabel(
      BuildContext context, String label, bool isDark, bool isRequired) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? DsColors.textPrimaryDark
                    : DsColors.textPrimaryLight,
              ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DsColors.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
      ],
    );
  }

  Widget _buildGenderTile(BuildContext context, String value, String label,
      IconData icon, bool isDark) {
    final isSelected = _gender == value;

    return GestureDetector(
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
    );
  }

  Widget _buildBirthdatePicker(BuildContext context, bool isDark) {
    final errorText = _birthdateErrorText();
    final hasError = errorText != null;

    String displayText;
    if (_dateOfBirth != null) {
      final age = _calculatedAge;
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      displayText = '${months[_dateOfBirth!.month - 1]} ${_dateOfBirth!.day}, ${_dateOfBirth!.year}';
      if (age != null) {
        displayText += ' ($age years old)';
      }
    } else {
      displayText = 'Select your birthdate';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
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
                        : (isDark ? DsColors.borderDark : DsColors.borderLight)),
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
                          : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight)),
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
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
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

    final now = DateTime.now();
    final minDate = DateTime(now.year - 75, now.month, now.day);
    final maxDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'SELECT YOUR BIRTHDATE',
      cancelText: 'CANCEL',
      confirmText: 'CONFIRM',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: DsColors.primary,
              onPrimary: Colors.white,
              surface: isDark ? DsColors.surfaceDark : DsColors.backgroundLight,
              onSurface: isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
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
    return GestureDetector(
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
                  : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _orientation ?? 'Select orientation (optional)',
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
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showOrientationBottomSheet(BuildContext context, bool isDark) {
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
              margin: const EdgeInsets.only(top: 12),
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
                    'Sexual Orientation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? DsColors.textPrimaryDark
                              : DsColors.textPrimaryLight,
                        ),
                  ),
                  if (_orientation != null)
                    GestureDetector(
                      onTap: () {
                        setState(() => _orientation = null);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DsColors.primary,
                              fontWeight: FontWeight.w600,
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
                itemCount: _orientationOptions.length,
                itemBuilder: (context, index) {
                  final option = _orientationOptions[index];
                  final isSelected = _orientation == option;

                  return ListTile(
                    onTap: () {
                      setState(() => _orientation = option);
                      Navigator.pop(context);
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                              color: Colors.white,
                            )
                          : null,
                    ),
                    title: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
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

  void _markBirthdateTouched() {
    if (!_birthdateTouched) {
      setState(() {
        _birthdateTouched = true;
      });
    }
  }

  String? _birthdateErrorText() {
    if (!_birthdateTouched) return null;
    if (_dateOfBirth == null) {
      return 'Select your date of birth';
    }
    final age = _calculatedAge;
    if (age == null) {
      return 'Select a valid date';
    }
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    if (age > 75) {
      return 'Maximum age allowed is 75';
    }
    return null;
  }

  Future<void> _handleNext(BuildContext context) async {
    setState(() {
      _usernameTouched = true;
      _birthdateTouched = true;
    });
    final usernameError = _usernameErrorText();
    if (usernameError != null) {
      showErrorSnackBar(context, usernameError);
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
    profileBloc.add(
      ProfileBasicInfoSubmitted(
        username: _usernameController.text.trim(),
        name: _nameController.text.trim(),
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
          backgroundColor:
              isDark ? DsColors.surfaceDark : DsColors.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.elderly, color: Colors.orange, size: 40),
          ),
          title: Text(
            'Age Notice',
            style: TextStyle(
              color:
                  isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You\'re a bit too old to be using a dating app, don\'t you think?\n\n'
            'Just kidding! Love has no age limit. Are you sure you want to continue?',
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
              child: const Text('Go Back'),
            ),
            const SizedBox(width: 8),
            GlassPrimaryButton(
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
