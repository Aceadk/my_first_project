import 'dart:async';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/widgets/google_logo_icon.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const int _emailResendCooldownDurationSeconds = 30;
  static const int _phoneOtpResendCooldownDurationSeconds = 30;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dialCodeController = TextEditingController();

  // Auth method: 'email' or 'phone'
  String _authMethod = 'email';
  _CountryCode _selectedCountry = _countries.firstWhere(
    (c) => c.name == 'United States',
    orElse: () => _countries.first,
  );

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _registeredEmail;
  String? _phoneInProgress;
  Timer? _emailResendCooldownTimer;
  Timer? _phoneOtpResendCooldownTimer;
  int _emailResendCooldownSeconds = 0;

  AuthFlowUseCases _authFlowUseCases() {
    return AuthFlowUseCases(context.read<AuthRepository>());
  }

  int _phoneOtpResendCooldownSeconds = 0;

  // Field errors
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _otpError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _dialCodeController.text = _selectedCountry.dialCode;

    // Track onboarding start time for duration calculation
    AnalyticsService.instance.onboardingStartTime = DateTime.now();

    // Log onboarding step 1: signup
    AnalyticsService.instance.logOnboardingStep(
      step: 'signup',
      stepNumber: 1,
      totalSteps: 6,
    );
  }

  @override
  void dispose() {
    _emailResendCooldownTimer?.cancel();
    _phoneOtpResendCooldownTimer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _phoneController.dispose();
    _dialCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authFlowUseCases = _authFlowUseCases();
    final bypassVerification = authFlowUseCases.isVerificationBypassEnabled;
    final supportsGoogleSignIn = authFlowUseCases.supportsGoogleSignIn;

    // Calculate total steps based on auth method
    final totalSteps = _authMethod == 'phone'
        ? 2 // Phone number → OTP
        : (bypassVerification ? 3 : 4); // Username → Email → Password → (OTP)

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        // Handle phone auth state changes
        if (_authMethod == 'phone') {
          if (state.status == AuthStatus.otpSent &&
              state.phoneInProgress != null) {
            setState(() {
              _phoneInProgress = state.phoneInProgress;
              _currentStep = 1; // Move to OTP step
              _isLoading = false;
            });
            _startPhoneOtpResendCooldown();
            showSuccessSnackBar(context, l10n.onboardingSignUpPhoneCodeSent);
          } else if (state.status == AuthStatus.authenticated) {
            setState(() => _isLoading = false);
            context.go(CrushRoutes.termsConditions);
          }
          final error = state.errorMessage;
          if (error != null && error.isNotEmpty) {
            setState(() => _isLoading = false);
            showErrorSnackBar(context, error);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GlassIconButton(
            icon: Icons.arrow_back,
            tooltip: l10n.commonBack,
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
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
                  child: Padding(
                    padding: DsEdgeInsets.allXxl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress indicator
                        _StepProgress(
                          currentStep: _currentStep,
                          totalSteps: totalSteps,
                        ),
                        DsGap.xxl,
                        if (_authMethod == 'email' &&
                            _currentStep == 0 &&
                            supportsGoogleSignIn) ...[
                          Semantics(
                            button: true,
                            label: l10n.authContinueWithGoogle,
                            child: SizedBox(
                              width: double.infinity,
                              child: GlassOutlinedButton(
                                onPressed: _isLoading || _isGoogleLoading
                                    ? null
                                    : _continueWithGoogle,
                                backgroundColor: Colors.white,
                                borderColor: const Color(0xFFDADCE0),
                                isExpanded: true,
                                isLoading: _isGoogleLoading,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const GoogleLogoIcon(size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.authContinueWithGoogle,
                                      style: const TextStyle(
                                        color: Color(0xFF1F1F1F),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          DsGap.lg,
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: DsEdgeInsets.horizontalLg,
                                child: Text(
                                  l10n.onboardingSignUpOrSignUpWithEmail,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? DsColors.textMutedDark
                                            : DsColors.textMutedLight,
                                      ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          DsGap.xl,
                        ],
                        // Step content
                        Expanded(
                          child: SingleChildScrollView(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildCurrentStep(
                                isDark,
                                bypassVerification,
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
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else if (_authMethod == 'phone') {
      // Go back to email auth method
      setState(() {
        _authMethod = 'email';
        _currentStep = 0;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildCurrentStep(bool isDark, bool bypassVerification) {
    // Phone auth flow
    if (_authMethod == 'phone') {
      switch (_currentStep) {
        case 0:
          return _PhoneStep(
            key: const ValueKey('phone'),
            phoneController: _phoneController,
            dialCodeController: _dialCodeController,
            selectedCountry: _selectedCountry,
            error: _phoneError,
            isLoading: _isLoading,
            isDark: isDark,
            onCountryChanged: (country) {
              setState(() {
                _selectedCountry = country;
                _dialCodeController.text = country.dialCode;
              });
            },
            onNext: _submitPhone,
            onChanged: () => setState(() => _phoneError = null),
            onSwitchToEmail: () {
              setState(() {
                _authMethod = 'email';
                _currentStep = 0;
              });
            },
          );
        case 1:
          return _PhoneOtpStep(
            key: const ValueKey('phone-otp'),
            controller: _otpController,
            error: _otpError,
            isLoading: _isLoading,
            isDark: isDark,
            phoneNumber: _phoneInProgress ?? _getFullPhoneNumber(),
            onVerify: _verifyPhoneOtp,
            onResend: _resendPhoneOtp,
            resendCooldownSeconds: _phoneOtpResendCooldownSeconds,
            onChanged: () => setState(() => _otpError = null),
          );
        default:
          return const SizedBox.shrink();
      }
    }

    // Email auth flow
    switch (_currentStep) {
      case 0:
        return _UsernameStep(
          key: const ValueKey('username'),
          controller: _usernameController,
          error: _usernameError,
          isLoading: _isLoading,
          isDark: isDark,
          onNext: _validateUsername,
          onChanged: () => setState(() => _usernameError = null),
          onSwitchToPhone: () {
            setState(() {
              _authMethod = 'phone';
              _currentStep = 0;
            });
          },
        );
      case 1:
        return _EmailStep(
          key: const ValueKey('email'),
          controller: _emailController,
          error: _emailError,
          isLoading: _isLoading,
          isDark: isDark,
          bypassVerification: bypassVerification,
          onNext: _validateEmail,
          onChanged: () => setState(() => _emailError = null),
        );
      case 2:
        return _PasswordStep(
          key: const ValueKey('password'),
          controller: _passwordController,
          error: _passwordError,
          isLoading: _isLoading,
          isDark: isDark,
          obscurePassword: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onNext: _createAccount,
          onChanged: () => setState(() => _passwordError = null),
          hasUsername: _usernameController.text.trim().isNotEmpty,
          hasEmail: _emailController.text.trim().isNotEmpty,
        );
      case 3:
        return _EmailLinkStep(
          key: const ValueKey('email-link'),
          isLoading: _isLoading,
          isDark: isDark,
          email: _registeredEmail ?? _emailController.text,
          onResend: _resendEmailVerification,
          resendCooldownSeconds: _emailResendCooldownSeconds,
          onOpenEmail: _openEmailApp,
          onCheckVerification: () => _checkEmailVerification(silent: true),
          onManualCheck: () => _checkEmailVerification(silent: false),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getFullPhoneNumber() {
    final dialCode = _dialCodeController.text.trim();
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final normalizedDialCode = dialCode.startsWith('+')
        ? dialCode.replaceAll(RegExp(r'[^0-9]'), '')
        : dialCode.replaceAll(RegExp(r'[^0-9]'), '');
    return '+$normalizedDialCode$phone';
  }

  void _submitPhone() {
    final l10n = AppLocalizations.of(context);
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      setState(() => _phoneError = l10n.onboardingSignUpPhoneErrorRequired);
      return;
    }
    if (phone.length < 6) {
      setState(() => _phoneError = l10n.onboardingSignUpPhoneErrorMinDigits);
      return;
    }

    final fullNumber = _getFullPhoneNumber();
    setState(() {
      _phoneError = null;
      _isLoading = true;
    });

    context.read<AuthBloc>().add(AuthPhoneSubmitted(fullNumber));
  }

  void _verifyPhoneOtp() {
    final l10n = AppLocalizations.of(context);
    final otp = _otpController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (otp.isEmpty) {
      setState(() => _otpError = l10n.onboardingSignUpOtpErrorRequired);
      return;
    }
    if (otp.length != 6) {
      setState(() => _otpError = l10n.onboardingSignUpOtpErrorInvalidLength);
      return;
    }

    final phoneNumber = _phoneInProgress ?? _getFullPhoneNumber();
    setState(() {
      _otpError = null;
      _isLoading = true;
    });

    context.read<AuthBloc>().add(AuthOtpSubmitted(phoneNumber, otp));
  }

  void _resendPhoneOtp() {
    final l10n = AppLocalizations.of(context);
    if (_phoneOtpResendCooldownSeconds > 0) {
      showErrorSnackBar(
        context,
        l10n.onboardingSignUpWaitBeforeRequestingCode(
          _phoneOtpResendCooldownSeconds,
        ),
      );
      return;
    }
    final phoneNumber = _phoneInProgress ?? _getFullPhoneNumber();
    if (phoneNumber.trim().isEmpty || phoneNumber.trim() == '+') {
      showErrorSnackBar(context, l10n.onboardingSignUpPhoneInvalid);
      return;
    }
    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(AuthOtpResendRequested(phoneNumber));
  }

  Future<void> _resendEmailVerification() async {
    final l10n = AppLocalizations.of(context);
    if (_emailResendCooldownSeconds > 0) {
      showErrorSnackBar(
        context,
        l10n.onboardingSignUpWaitBeforeResendingEmail(
          _emailResendCooldownSeconds,
        ),
      );
      return;
    }
    await _sendEmailVerification(isResend: true);
  }

  /// Validates username - required for account creation.
  void _validateUsername() {
    final l10n = AppLocalizations.of(context);
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() => _usernameError = l10n.onboardingSignUpUsernameRequired);
      return;
    }

    // Must be valid
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
    if (!valid) {
      setState(
        () => _usernameError = l10n.onboardingBasicInfoUsernameFormatError,
      );
      return;
    }
    setState(() {
      _usernameError = null;
      _currentStep = 1;
    });
  }

  /// Validates email - required for account creation.
  void _validateEmail() {
    final l10n = AppLocalizations.of(context);
    final email = normalizeEmail(_emailController.text);

    if (email.isEmpty) {
      setState(() => _emailError = l10n.onboardingSignUpEmailRequired);
      return;
    }

    // Must be valid
    if (!looksLikeEmail(email)) {
      setState(() => _emailError = l10n.errorInvalidEmail);
      return;
    }
    setState(() {
      _emailError = null;
      _currentStep = 2;
    });
  }

  Future<void> _continueWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    if (_isGoogleLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    final result = await _authFlowUseCases().signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (!result.isSuccess) {
      showErrorSnackBar(
        context,
        result.errorMessage ?? l10n.onboardingSignUpGoogleSignInFailed,
      );
      return;
    }

    final user = result.data;
    if (user?.email != null &&
        user!.email!.isNotEmpty &&
        !user.isEmailVerified) {
      context.go('${CrushRoutes.emailProtection}?redirect=1');
      return;
    }
    context.go(CrushRoutes.home);
  }

  Future<void> _createAccount() async {
    final l10n = AppLocalizations.of(context);
    final username = _usernameController.text.trim();
    final email = normalizeEmail(_emailController.text);
    final password = _passwordController.text;

    // Collect all validation errors
    final errors = <String>[];

    // Validate username (required for account creation)
    if (username.isEmpty) {
      errors.add(l10n.onboardingSignUpUsernameRequired);
    } else if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
      errors.add(l10n.onboardingSignUpInvalidUsernameFormat);
    }

    // Validate email (required for account creation)
    if (email.isEmpty) {
      errors.add(l10n.onboardingSignUpEmailRequired);
    } else if (!looksLikeEmail(email)) {
      errors.add(l10n.onboardingSignUpInvalidEmailFormat);
    }

    // Validate password (required for account creation)
    if (password.isEmpty) {
      setState(() => _passwordError = l10n.onboardingSignUpPasswordRequired);
      if (errors.isNotEmpty) {
        showErrorSnackBar(
          context,
          l10n.onboardingSignUpCompleteRequiredFields(errors.join(', ')),
        );
      }
      return;
    }
    if (password.length < 8) {
      setState(() => _passwordError = l10n.onboardingSignUpPasswordMinLength);
      if (errors.isNotEmpty) {
        showErrorSnackBar(
          context,
          l10n.onboardingSignUpCompleteRequiredFields(errors.join(', ')),
        );
      }
      return;
    }

    // If there are missing required fields, show error and let user go back
    if (errors.isNotEmpty) {
      showErrorSnackBar(
        context,
        l10n.onboardingSignUpCompleteRequiredFields(errors.join(', ')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _passwordError = null;
      _isLoading = true;
    });

    // Check if email is already registered
    final authFlowUseCases = _authFlowUseCases();
    final emailExistsResult = await authFlowUseCases.isEmailRegistered(email);
    if (!emailExistsResult.isSuccess) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(
        context,
        emailExistsResult.errorMessage ?? l10n.onboardingSignUpRequestFailed,
      );
      return;
    }
    if (emailExistsResult.data == true) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, l10n.onboardingSignUpEmailAlreadyExists);
      return;
    }

    final signUpResult = await authFlowUseCases.signUpWithPassword(
      username: username,
      email: email,
      password: password,
    );
    if (!signUpResult.isSuccess) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(
        context,
        signUpResult.errorMessage ?? l10n.onboardingSignUpRequestFailed,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (authFlowUseCases.isVerificationBypassEnabled) {
      showSuccessSnackBar(context, l10n.onboardingSignUpAccountCreated);
      context.go(CrushRoutes.termsConditions);
      return;
    }

    _registeredEmail = email;

    // Send email verification email
    await _sendEmailVerification();

    if (!mounted) return;

    setState(() => _currentStep = 3);
  }

  Future<void> _sendEmailVerification({bool isResend = false}) async {
    final l10n = AppLocalizations.of(context);
    if (isResend && _emailResendCooldownSeconds > 0) {
      showErrorSnackBar(
        context,
        l10n.onboardingSignUpWaitBeforeResendingEmail(
          _emailResendCooldownSeconds,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authFlowUseCases().sendEmailVerification();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      final error = (result.errorMessage ?? l10n.onboardingSignUpRequestFailed)
          .toLowerCase();
      if (error.contains('too-many-requests') ||
          error.contains('too many requests')) {
        showErrorSnackBar(
          context,
          l10n.onboardingEmailVerificationTooManyAttempts,
        );
      } else {
        showErrorSnackBar(
          context,
          result.errorMessage ?? l10n.onboardingSignUpRequestFailed,
        );
      }
      return;
    }

    _startEmailResendCooldown();

    showSuccessSnackBar(
      context,
      isResend
          ? l10n.onboardingSignUpVerificationEmailResent
          : l10n.onboardingSignUpVerificationEmailSent,
    );
  }

  void _startEmailResendCooldown() {
    _emailResendCooldownTimer?.cancel();
    if (!mounted) return;
    setState(
      () => _emailResendCooldownSeconds = _emailResendCooldownDurationSeconds,
    );
    _emailResendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_emailResendCooldownSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _emailResendCooldownSeconds--);
    });
  }

  void _startPhoneOtpResendCooldown() {
    _phoneOtpResendCooldownTimer?.cancel();
    if (!mounted) return;
    setState(
      () => _phoneOtpResendCooldownSeconds =
          _phoneOtpResendCooldownDurationSeconds,
    );
    _phoneOtpResendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_phoneOtpResendCooldownSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _phoneOtpResendCooldownSeconds--);
    });
  }

  Future<void> _openEmailApp() async {
    final l10n = AppLocalizations.of(context);
    // Try to open the default email app
    final emailUri = Uri(scheme: 'mailto');
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback: try to open Gmail app on Android
        final gmailUri = Uri.parse('googlegmail://');
        if (await canLaunchUrl(gmailUri)) {
          await launchUrl(gmailUri);
        } else {
          if (mounted) {
            showErrorSnackBar(context, l10n.onboardingSignUpOpenEmailAppFailed);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, l10n.onboardingSignUpOpenEmailAppFailed);
      }
    }
  }

  Future<bool> _checkEmailVerification({bool silent = false}) async {
    final l10n = AppLocalizations.of(context);
    if (!silent) {
      setState(() => _isLoading = true);
    }

    final result = await _authFlowUseCases().checkEmailVerification();

    if (!mounted) return false;

    if (!silent) {
      setState(() => _isLoading = false);
    }

    if (result.isSuccess &&
        result.data != null &&
        result.data!.isEmailVerified) {
      if (mounted) {
        showSuccessSnackBar(context, l10n.onboardingSignUpEmailVerifiedWelcome);
        context.go(CrushRoutes.termsConditions);
      }
      return true;
    } else if (!silent) {
      showErrorSnackBar(context, l10n.onboardingSignUpEmailNotVerified);
    }
    return false;
  }
}

// Progress indicator widget
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.onboardingStep(currentStep + 1, totalSteps),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DsColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              l10n.onboardingSignUpPercent(
                ((currentStep + 1) / totalSteps * 100).round(),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: DsColors.textMutedLight),
            ),
          ],
        ),
        DsGap.sm,
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            minHeight: 6,
            backgroundColor: DsColors.skeletonLight,
            valueColor: const AlwaysStoppedAnimation<Color>(DsColors.primary),
          ),
        ),
      ],
    );
  }
}

// Step 1: Username
class _UsernameStep extends StatelessWidget {
  const _UsernameStep({
    super.key,
    required this.controller,
    required this.error,
    required this.isLoading,
    required this.isDark,
    required this.onNext,
    required this.onChanged,
    this.onSwitchToPhone,
  });

  final TextEditingController controller;
  final String? error;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onNext;
  final VoidCallback onChanged;
  final VoidCallback? onSwitchToPhone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome header
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [DsColors.primary, DsColors.secondary],
          ).createShader(bounds),
          child: Text(
            l10n.onboardingWelcome,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: DsColors.backgroundLight,
            ),
          ),
        ),
        DsGap.xs,
        Text(
          l10n.onboardingSignUpStepOne,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DsColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        DsGap.lg,
        Text(
          l10n.onboardingSignUpChooseUsername,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        DsGap.xs,
        Text(
          l10n.onboardingSignUpUsernameDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
        DsGap.xxl,
        GlassTextField(
          controller: controller,
          label: l10n.onboardingBasicInfoUsernameLabel,
          hintText: l10n.onboardingSignUpUsernameHint,
          prefixIcon: Icons.person_outline,
          errorText: error,
          enabled: !isLoading,
          onChanged: (_) => onChanged(),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => onNext(),
        ),
        DsGap.sm,
        Text(
          l10n.onboardingSignUpUsernameRules,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
        DsGap.xxl,
        GlassPrimaryButton(
          onPressed: isLoading ? null : onNext,
          isLoading: isLoading,
          isExpanded: true,
          child: Text(AppLocalizations.of(context).continueLabel),
        ),
        DsGap.lg,
        _LoginLink(),
        // Alternative sign up methods
        if (onSwitchToPhone != null) ...[
          DsGap.xl,
          // Divider with "or sign up with"
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.onboardingSignUpOrSignUpWith,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          DsGap.lg,
          // Phone sign up button
          Row(
            children: [
              Expanded(
                child: _AltSignUpOption(
                  icon: Icons.phone_outlined,
                  label: l10n.authPhone,
                  onTap: isLoading ? null : onSwitchToPhone,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Alternative sign up option button
class _AltSignUpOption extends StatelessWidget {
  const _AltSignUpOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GlassOutlinedButton(
        onPressed: onTap,
        isExpanded: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: DsColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? DsColors.textPrimaryDark
                    : DsColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 2: Email
class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.controller,
    required this.error,
    required this.isLoading,
    required this.isDark,
    required this.bypassVerification,
    required this.onNext,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final bool isLoading;
  final bool isDark;
  final bool bypassVerification;
  final VoidCallback onNext;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingSignUpEmailTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        DsGap.sm,
        Text(
          bypassVerification
              ? l10n.onboardingSignUpBypassHint
              : l10n.onboardingSignUpEmailHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
        DsGap.xxl,
        GlassTextField(
          controller: controller,
          label: l10n.onboardingSignUpEmailAddressLabel,
          hintText: l10n.onboardingSignUpEmailAddressHint,
          prefixIcon: Icons.email_outlined,
          errorText: error,
          enabled: !isLoading,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => onChanged(),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => onNext(),
        ),
        DsGap.xxl,
        GlassPrimaryButton(
          onPressed: isLoading ? null : onNext,
          isLoading: isLoading,
          isExpanded: true,
          child: Text(AppLocalizations.of(context).continueLabel),
        ),
      ],
    );
  }
}

// Step 3: Password
class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    super.key,
    required this.controller,
    required this.error,
    required this.isLoading,
    required this.isDark,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onNext,
    required this.onChanged,
    required this.hasUsername,
    required this.hasEmail,
  });

  final TextEditingController controller;
  final String? error;
  final bool isLoading;
  final bool isDark;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onNext;
  final VoidCallback onChanged;
  final bool hasUsername;
  final bool hasEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final missingFields = <String>[];
    if (!hasUsername) missingFields.add(l10n.onboardingBasicInfoUsernameLabel);
    if (!hasEmail) missingFields.add(l10n.authEmail);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingSignUpPasswordTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        DsGap.sm,
        Text(
          l10n.onboardingSignUpPasswordDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
        if (missingFields.isNotEmpty) ...[
          DsGap.md,
          Container(
            padding: DsEdgeInsets.allMd,
            decoration: BoxDecoration(
              color: DsColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DsColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: DsColors.warning,
                  size: 20,
                ),
                DsGap.smH,
                Expanded(
                  child: Text(
                    l10n.onboardingSignUpMissingRequiredFields(
                      missingFields.join(', '),
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: DsColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
        DsGap.xxl,
        GlassTextField(
          controller: controller,
          label: l10n.authPassword,
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          errorText: error,
          enabled: !isLoading,
          obscureText: obscurePassword,
          suffixIcon: obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: onToggleObscure,
          onChanged: (_) => onChanged(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onNext(),
        ),
        DsGap.md,
        _PasswordStrength(password: controller.text),
        DsGap.xxl,
        GlassPrimaryButton(
          onPressed: isLoading ? null : onNext,
          isLoading: isLoading,
          isExpanded: true,
          child: Text(AppLocalizations.of(context).createAccount),
        ),
      ],
    );
  }
}

// Step 4: Email Link Verification (Magic Link)
class _EmailLinkStep extends StatefulWidget {
  const _EmailLinkStep({
    super.key,
    required this.isLoading,
    required this.isDark,
    required this.email,
    required this.onResend,
    required this.resendCooldownSeconds,
    required this.onOpenEmail,
    required this.onCheckVerification,
    required this.onManualCheck,
  });

  final bool isLoading;
  final bool isDark;
  final String email;
  final VoidCallback onResend;
  final int resendCooldownSeconds;
  final VoidCallback onOpenEmail;
  final Future<bool> Function() onCheckVerification;
  final Future<bool> Function() onManualCheck;

  @override
  State<_EmailLinkStep> createState() => _EmailLinkStepState();
}

class _EmailLinkStepState extends State<_EmailLinkStep>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _pollingTimer;
  bool _isPolling = false;
  int _pollCount = 0;
  static const _pollInterval = Duration(seconds: 3);
  static const _maxPollCount = 60; // Stop polling after 3 minutes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Start auto-polling after a short delay
    Future.delayed(const Duration(seconds: 2), _startPolling);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause polling when app is backgrounded, resume when foregrounded
    if (state == AppLifecycleState.paused) {
      _stopPolling();
    } else if (state == AppLifecycleState.resumed) {
      // Immediately check verification when app comes back to foreground
      // User may have just clicked the verification link
      _pollVerification();
      _startPolling();
    }
  }

  void _startPolling() {
    if (_isPolling || _pollCount >= _maxPollCount) return;
    _isPolling = true;
    _pollingTimer = Timer.periodic(_pollInterval, (_) => _pollVerification());
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  Future<void> _pollVerification() async {
    if (!mounted || widget.isLoading) return;
    _pollCount++;

    if (_pollCount >= _maxPollCount) {
      _stopPolling();
      return;
    }

    final verified = await widget.onCheckVerification();
    if (verified) {
      _stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final warningBackgroundColor = widget.isDark
        ? DsColors.warning.withValues(alpha: 0.18)
        : DsColors.warning.withValues(alpha: 0.12);
    final warningBorderColor = widget.isDark
        ? DsColors.warning.withValues(alpha: 0.45)
        : DsColors.warning.withValues(alpha: 0.3);
    final warningTextColor = widget.isDark
        ? DsColors.textPrimaryDark
        : DsColors.textPrimaryLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated email icon
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DsColors.primary.withValues(alpha: 0.2),
                        DsColors.secondary.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 48,
                    color: DsColors.primary,
                  ),
                ),
              );
            },
          ),
        ),
        DsGap.xxl,
        Center(
          child: Text(
            l10n.authCheckYourEmail,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        DsGap.md,
        Center(
          child: Text(
            l10n.onboardingEmailVerificationSentTo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: widget.isDark
                  ? DsColors.textMutedDark
                  : DsColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        DsGap.xs,
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: DsColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: DsColors.primary,
              ),
            ),
          ),
        ),
        DsGap.xxl,
        // Instructions
        Container(
          padding: DsEdgeInsets.allMd,
          decoration: BoxDecoration(
            color: widget.isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? DsColors.borderDark : DsColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InstructionRow(
                number: '1',
                text: l10n.onboardingSignUpEmailInstructionOpenInbox,
                isDark: widget.isDark,
              ),
              DsGap.sm,
              _InstructionRow(
                number: '2',
                text: l10n.onboardingSignUpEmailInstructionFindEmail,
                isDark: widget.isDark,
              ),
              DsGap.sm,
              _InstructionRow(
                number: '3',
                text: l10n.onboardingSignUpEmailInstructionClickLink,
                isDark: widget.isDark,
              ),
              DsGap.md,
              Container(
                padding: DsEdgeInsets.allSm,
                decoration: BoxDecoration(
                  color: warningBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: warningBorderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      size: 16,
                      color: DsColors.warning,
                    ),
                    DsGap.smH,
                    Expanded(
                      child: Text(
                        l10n.onboardingSignUpEmailIgnoreNotice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: warningTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DsGap.xxl,
        // Auto-checking status indicator
        if (_isPolling)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DsColors.success.withValues(alpha: 0.7),
                  ),
                ),
                DsGap.smH,
                Text(
                  l10n.authAutoCheckingStatus,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: DsColors.success),
                ),
              ],
            ),
          ),
        // Open email app button
        GlassPrimaryButton(
          onPressed: widget.isLoading ? null : widget.onOpenEmail,
          isLoading: widget.isLoading,
          isExpanded: true,
          child: Text(AppLocalizations.of(context).openEmailApp),
        ),
        DsGap.md,
        // Check verification button
        GlassOutlinedButton(
          onPressed: widget.isLoading ? null : widget.onManualCheck,
          isLoading: widget.isLoading,
          isExpanded: true,
          borderColor: DsColors.primary,
          child: Text(
            l10n.authIveVerified,
            style: const TextStyle(color: DsColors.primary),
          ),
        ),
        DsGap.lg,
        // Resend link
        Center(
          child: Semantics(
            button: true,
            label: l10n.onboardingEmailVerificationResendSemantics,
            child: GlassSmallButton(
              onPressed: widget.isLoading || widget.resendCooldownSeconds > 0
                  ? null
                  : widget.onResend,
              child: Text(
                widget.resendCooldownSeconds > 0
                    ? l10n.onboardingEmailVerificationResendIn(
                        widget.resendCooldownSeconds,
                      )
                    : l10n.onboardingSignUpDidntReceiveEmailResend,
              ),
            ),
          ),
        ),
        DsGap.md,
        // Check spam notice
        Center(
          child: Text(
            l10n.onboardingSignUpCheckSpam,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.isDark
                  ? DsColors.textMutedDark
                  : DsColors.textMutedLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({
    required this.number,
    required this.text,
    required this.isDark,
  });

  final String number;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: DsColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: DsColors.primary,
              ),
            ),
          ),
        ),
        DsGap.smH,
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? DsColors.textPrimaryDark
                  : DsColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

// Password strength indicator
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strength = _calculateStrength(password);
    final color = _getColor(strength);
    final label = _getLabel(context, strength);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 4,
              backgroundColor: isDark
                  ? DsColors.skeletonDark
                  : DsColors.skeletonLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        DsGap.mdH,
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.1;
    return strength.clamp(0.0, 1.0);
  }

  Color _getColor(double strength) {
    if (strength < 0.3) return DsColors.error;
    if (strength < 0.6) return DsColors.warning;
    return DsColors.success;
  }

  String _getLabel(BuildContext context, double strength) {
    final l10n = AppLocalizations.of(context);
    if (strength == 0) return '';
    if (strength < 0.3) return l10n.onboardingSignUpPasswordStrengthWeak;
    if (strength < 0.6) return l10n.onboardingSignUpPasswordStrengthFair;
    if (strength < 0.8) return l10n.onboardingSignUpPasswordStrengthGood;
    return l10n.onboardingSignUpPasswordStrengthStrong;
  }
}

// Login link
class _LoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Semantics(
        button: true,
        label: l10n.authSignIn,
        child: GlassSmallButton(
          onPressed: () => context.go(CrushRoutes.login),
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '${l10n.authAlreadyHaveAccount} ',
                  style: const TextStyle(color: DsColors.textMutedLight),
                ),
                TextSpan(
                  text: l10n.authSignIn,
                  style: const TextStyle(
                    color: DsColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Phone Step
class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.phoneController,
    required this.dialCodeController,
    required this.selectedCountry,
    required this.error,
    required this.isLoading,
    required this.isDark,
    required this.onCountryChanged,
    required this.onNext,
    required this.onChanged,
    required this.onSwitchToEmail,
  });

  final TextEditingController phoneController;
  final TextEditingController dialCodeController;
  final _CountryCode selectedCountry;
  final String? error;
  final bool isLoading;
  final bool isDark;
  final ValueChanged<_CountryCode> onCountryChanged;
  final VoidCallback onNext;
  final VoidCallback onChanged;
  final VoidCallback onSwitchToEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingSignUpPhoneTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        DsGap.sm,
        Text(
          l10n.onboardingSignUpPhoneSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
        DsGap.xxl,
        // Country picker
        DropdownButtonFormField<_CountryCode>(
          initialValue: selectedCountry,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.profileCountry,
            prefixIcon: const Icon(Icons.flag_outlined),
            filled: true,
            fillColor: isDark
                ? DsColors.inputFillDark
                : DsColors.inputFillLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: _countries
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    '${c.flag} ${c.name} (${c.dialCode})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => _countries
              .map(
                (c) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${c.flag} ${c.name} (${c.dialCode})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: isLoading
              ? null
              : (value) {
                  if (value != null) {
                    onCountryChanged(value);
                  }
                },
        ),
        DsGap.lg,
        // Phone number input
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: GlassTextField(
                controller: dialCodeController,
                label: l10n.onboardingSignUpCodeLabel,
                hintText: '+1',
                prefixIcon: Icons.dialpad,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
              ),
            ),
            DsGap.mdH,
            Expanded(
              child: GlassTextField(
                controller: phoneController,
                label: l10n.authPhoneNumber,
                hintText: l10n.onboardingSignUpPhoneHint,
                prefixIcon: Icons.phone_outlined,
                errorText: error,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
                onChanged: (_) => onChanged(),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onNext(),
              ),
            ),
          ],
        ),
        DsGap.sm,
        Text(
          l10n.onboardingSignUpSmsRates,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ),
        DsGap.xxl,
        GlassPrimaryButton(
          onPressed: isLoading ? null : onNext,
          isLoading: isLoading,
          isExpanded: true,
          child: Text(AppLocalizations.of(context).sendCode),
        ),
        DsGap.lg,
        _LoginLink(),
        DsGap.md,
        Center(
          child: Semantics(
            button: true,
            label: l10n.signUpWithEmailInstead,
            child: GlassSmallButton(
              onPressed: isLoading ? null : onSwitchToEmail,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.email_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).signUpWithEmailInstead),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Phone OTP Step
class _PhoneOtpStep extends StatelessWidget {
  const _PhoneOtpStep({
    super.key,
    required this.controller,
    required this.error,
    required this.isLoading,
    required this.isDark,
    required this.phoneNumber,
    required this.onVerify,
    required this.onResend,
    required this.resendCooldownSeconds,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final bool isLoading;
  final bool isDark;
  final String phoneNumber;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final int resendCooldownSeconds;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: DsColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.sms_outlined,
            size: 32,
            color: DsColors.success,
          ),
        ),
        DsGap.xl,
        Text(
          l10n.onboardingSignUpOtpTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        DsGap.sm,
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
            children: [
              TextSpan(text: l10n.onboardingSignUpOtpSentTo(phoneNumber)),
            ],
          ),
        ),
        DsGap.xxl,
        GlassTextField(
          controller: controller,
          label: l10n.authVerificationCode,
          hintText: l10n.onboardingSignUpVerificationCodeHint,
          prefixIcon: Icons.pin_outlined,
          errorText: error,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (_) => onChanged(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onVerify(),
        ),
        DsGap.xxl,
        GlassPrimaryButton(
          onPressed: isLoading ? null : onVerify,
          isLoading: isLoading,
          isExpanded: true,
          child: Text(AppLocalizations.of(context).verify),
        ),
        DsGap.md,
        Center(
          child: Semantics(
            button: true,
            label: l10n.authResendCode,
            child: GlassSmallButton(
              onPressed: isLoading || resendCooldownSeconds > 0
                  ? null
                  : onResend,
              child: Text(
                resendCooldownSeconds > 0
                    ? l10n.onboardingEmailVerificationResendIn(
                        resendCooldownSeconds,
                      )
                    : l10n.onboardingSignUpDidntReceiveCodeResend,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Country code model
class _CountryCode {
  const _CountryCode({
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String dialCode;
  final String flag;
}

// Full country list sorted alphabetically
const _countries = <_CountryCode>[
  _CountryCode(name: 'Afghanistan', dialCode: '+93', flag: '🇦🇫'),
  _CountryCode(name: 'Albania', dialCode: '+355', flag: '🇦🇱'),
  _CountryCode(name: 'Algeria', dialCode: '+213', flag: '🇩🇿'),
  _CountryCode(name: 'American Samoa', dialCode: '+1684', flag: '🇦🇸'),
  _CountryCode(name: 'Andorra', dialCode: '+376', flag: '🇦🇩'),
  _CountryCode(name: 'Angola', dialCode: '+244', flag: '🇦🇴'),
  _CountryCode(name: 'Anguilla', dialCode: '+1264', flag: '🇦🇮'),
  _CountryCode(name: 'Antarctica', dialCode: '+672', flag: '🇦🇶'),
  _CountryCode(name: 'Antigua and Barbuda', dialCode: '+1268', flag: '🇦🇬'),
  _CountryCode(name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
  _CountryCode(name: 'Armenia', dialCode: '+374', flag: '🇦🇲'),
  _CountryCode(name: 'Aruba', dialCode: '+297', flag: '🇦🇼'),
  _CountryCode(name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  _CountryCode(name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
  _CountryCode(name: 'Azerbaijan', dialCode: '+994', flag: '🇦🇿'),
  _CountryCode(name: 'Bahamas', dialCode: '+1242', flag: '🇧🇸'),
  _CountryCode(name: 'Bahrain', dialCode: '+973', flag: '🇧🇭'),
  _CountryCode(name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  _CountryCode(name: 'Barbados', dialCode: '+1246', flag: '🇧🇧'),
  _CountryCode(name: 'Belarus', dialCode: '+375', flag: '🇧🇾'),
  _CountryCode(name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
  _CountryCode(name: 'Belize', dialCode: '+501', flag: '🇧🇿'),
  _CountryCode(name: 'Benin', dialCode: '+229', flag: '🇧🇯'),
  _CountryCode(name: 'Bermuda', dialCode: '+1441', flag: '🇧🇲'),
  _CountryCode(name: 'Bhutan', dialCode: '+975', flag: '🇧🇹'),
  _CountryCode(name: 'Bolivia', dialCode: '+591', flag: '🇧🇴'),
  _CountryCode(name: 'Bosnia and Herzegovina', dialCode: '+387', flag: '🇧🇦'),
  _CountryCode(name: 'Botswana', dialCode: '+267', flag: '🇧🇼'),
  _CountryCode(name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  _CountryCode(
    name: 'British Indian Ocean Territory',
    dialCode: '+246',
    flag: '🇮🇴',
  ),
  _CountryCode(name: 'British Virgin Islands', dialCode: '+1284', flag: '🇻🇬'),
  _CountryCode(name: 'Brunei', dialCode: '+673', flag: '🇧🇳'),
  _CountryCode(name: 'Bulgaria', dialCode: '+359', flag: '🇧🇬'),
  _CountryCode(name: 'Burkina Faso', dialCode: '+226', flag: '🇧🇫'),
  _CountryCode(name: 'Burundi', dialCode: '+257', flag: '🇧🇮'),
  _CountryCode(name: 'Cambodia', dialCode: '+855', flag: '🇰🇭'),
  _CountryCode(name: 'Cameroon', dialCode: '+237', flag: '🇨🇲'),
  _CountryCode(name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  _CountryCode(name: 'Cape Verde', dialCode: '+238', flag: '🇨🇻'),
  _CountryCode(name: 'Cayman Islands', dialCode: '+1345', flag: '🇰🇾'),
  _CountryCode(
    name: 'Central African Republic',
    dialCode: '+236',
    flag: '🇨🇫',
  ),
  _CountryCode(name: 'Chad', dialCode: '+235', flag: '🇹🇩'),
  _CountryCode(name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
  _CountryCode(name: 'China', dialCode: '+86', flag: '🇨🇳'),
  _CountryCode(name: 'Christmas Island', dialCode: '+61', flag: '🇨🇽'),
  _CountryCode(name: 'Cocos (Keeling) Islands', dialCode: '+61', flag: '🇨🇨'),
  _CountryCode(name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
  _CountryCode(name: 'Comoros', dialCode: '+269', flag: '🇰🇲'),
  _CountryCode(name: 'Cook Islands', dialCode: '+682', flag: '🇨🇰'),
  _CountryCode(name: 'Costa Rica', dialCode: '+506', flag: '🇨🇷'),
  _CountryCode(name: "Cote d'Ivoire", dialCode: '+225', flag: '🇨🇮'),
  _CountryCode(name: 'Croatia', dialCode: '+385', flag: '🇭🇷'),
  _CountryCode(name: 'Cuba', dialCode: '+53', flag: '🇨🇺'),
  _CountryCode(name: 'Curacao', dialCode: '+599', flag: '🇨🇼'),
  _CountryCode(name: 'Cyprus', dialCode: '+357', flag: '🇨🇾'),
  _CountryCode(name: 'Czech Republic', dialCode: '+420', flag: '🇨🇿'),
  _CountryCode(
    name: 'Democratic Republic of the Congo',
    dialCode: '+243',
    flag: '🇨🇩',
  ),
  _CountryCode(name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
  _CountryCode(name: 'Djibouti', dialCode: '+253', flag: '🇩🇯'),
  _CountryCode(name: 'Dominica', dialCode: '+1767', flag: '🇩🇲'),
  _CountryCode(name: 'Dominican Republic', dialCode: '+1809', flag: '🇩🇴'),
  _CountryCode(name: 'Ecuador', dialCode: '+593', flag: '🇪🇨'),
  _CountryCode(name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  _CountryCode(name: 'El Salvador', dialCode: '+503', flag: '🇸🇻'),
  _CountryCode(name: 'Equatorial Guinea', dialCode: '+240', flag: '🇬🇶'),
  _CountryCode(name: 'Eritrea', dialCode: '+291', flag: '🇪🇷'),
  _CountryCode(name: 'Estonia', dialCode: '+372', flag: '🇪🇪'),
  _CountryCode(name: 'Ethiopia', dialCode: '+251', flag: '🇪🇹'),
  _CountryCode(name: 'Falkland Islands', dialCode: '+500', flag: '🇫🇰'),
  _CountryCode(name: 'Faroe Islands', dialCode: '+298', flag: '🇫🇴'),
  _CountryCode(name: 'Fiji', dialCode: '+679', flag: '🇫🇯'),
  _CountryCode(name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
  _CountryCode(name: 'France', dialCode: '+33', flag: '🇫🇷'),
  _CountryCode(name: 'French Guiana', dialCode: '+594', flag: '🇬🇫'),
  _CountryCode(name: 'French Polynesia', dialCode: '+689', flag: '🇵🇫'),
  _CountryCode(name: 'Gabon', dialCode: '+241', flag: '🇬🇦'),
  _CountryCode(name: 'Gambia', dialCode: '+220', flag: '🇬🇲'),
  _CountryCode(name: 'Georgia', dialCode: '+995', flag: '🇬🇪'),
  _CountryCode(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  _CountryCode(name: 'Ghana', dialCode: '+233', flag: '🇬🇭'),
  _CountryCode(name: 'Gibraltar', dialCode: '+350', flag: '🇬🇮'),
  _CountryCode(name: 'Greece', dialCode: '+30', flag: '🇬🇷'),
  _CountryCode(name: 'Greenland', dialCode: '+299', flag: '🇬🇱'),
  _CountryCode(name: 'Grenada', dialCode: '+1473', flag: '🇬🇩'),
  _CountryCode(name: 'Guadeloupe', dialCode: '+590', flag: '🇬🇵'),
  _CountryCode(name: 'Guam', dialCode: '+1671', flag: '🇬🇺'),
  _CountryCode(name: 'Guatemala', dialCode: '+502', flag: '🇬🇹'),
  _CountryCode(name: 'Guernsey', dialCode: '+44', flag: '🇬🇬'),
  _CountryCode(name: 'Guinea', dialCode: '+224', flag: '🇬🇳'),
  _CountryCode(name: 'Guinea-Bissau', dialCode: '+245', flag: '🇬🇼'),
  _CountryCode(name: 'Guyana', dialCode: '+592', flag: '🇬🇾'),
  _CountryCode(name: 'Haiti', dialCode: '+509', flag: '🇭🇹'),
  _CountryCode(name: 'Honduras', dialCode: '+504', flag: '🇭🇳'),
  _CountryCode(name: 'Hong Kong', dialCode: '+852', flag: '🇭🇰'),
  _CountryCode(name: 'Hungary', dialCode: '+36', flag: '🇭🇺'),
  _CountryCode(name: 'Iceland', dialCode: '+354', flag: '🇮🇸'),
  _CountryCode(name: 'India', dialCode: '+91', flag: '🇮🇳'),
  _CountryCode(name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  _CountryCode(name: 'Iran', dialCode: '+98', flag: '🇮🇷'),
  _CountryCode(name: 'Iraq', dialCode: '+964', flag: '🇮🇶'),
  _CountryCode(name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
  _CountryCode(name: 'Isle of Man', dialCode: '+44', flag: '🇮🇲'),
  _CountryCode(name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
  _CountryCode(name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  _CountryCode(name: 'Jamaica', dialCode: '+1876', flag: '🇯🇲'),
  _CountryCode(name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  _CountryCode(name: 'Jersey', dialCode: '+44', flag: '🇯🇪'),
  _CountryCode(name: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
  _CountryCode(name: 'Kazakhstan', dialCode: '+7', flag: '🇰🇿'),
  _CountryCode(name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
  _CountryCode(name: 'Kiribati', dialCode: '+686', flag: '🇰🇮'),
  _CountryCode(name: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
  _CountryCode(name: 'Kyrgyzstan', dialCode: '+996', flag: '🇰🇬'),
  _CountryCode(name: 'Laos', dialCode: '+856', flag: '🇱🇦'),
  _CountryCode(name: 'Latvia', dialCode: '+371', flag: '🇱🇻'),
  _CountryCode(name: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
  _CountryCode(name: 'Lesotho', dialCode: '+266', flag: '🇱🇸'),
  _CountryCode(name: 'Liberia', dialCode: '+231', flag: '🇱🇷'),
  _CountryCode(name: 'Libya', dialCode: '+218', flag: '🇱🇾'),
  _CountryCode(name: 'Liechtenstein', dialCode: '+423', flag: '🇱🇮'),
  _CountryCode(name: 'Lithuania', dialCode: '+370', flag: '🇱🇹'),
  _CountryCode(name: 'Luxembourg', dialCode: '+352', flag: '🇱🇺'),
  _CountryCode(name: 'Macao', dialCode: '+853', flag: '🇲🇴'),
  _CountryCode(name: 'Madagascar', dialCode: '+261', flag: '🇲🇬'),
  _CountryCode(name: 'Malawi', dialCode: '+265', flag: '🇲🇼'),
  _CountryCode(name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
  _CountryCode(name: 'Maldives', dialCode: '+960', flag: '🇲🇻'),
  _CountryCode(name: 'Mali', dialCode: '+223', flag: '🇲🇱'),
  _CountryCode(name: 'Malta', dialCode: '+356', flag: '🇲🇹'),
  _CountryCode(name: 'Marshall Islands', dialCode: '+692', flag: '🇲🇭'),
  _CountryCode(name: 'Martinique', dialCode: '+596', flag: '🇲🇶'),
  _CountryCode(name: 'Mauritania', dialCode: '+222', flag: '🇲🇷'),
  _CountryCode(name: 'Mauritius', dialCode: '+230', flag: '🇲🇺'),
  _CountryCode(name: 'Mayotte', dialCode: '+262', flag: '🇾🇹'),
  _CountryCode(name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  _CountryCode(name: 'Micronesia', dialCode: '+691', flag: '🇫🇲'),
  _CountryCode(name: 'Moldova', dialCode: '+373', flag: '🇲🇩'),
  _CountryCode(name: 'Monaco', dialCode: '+377', flag: '🇲🇨'),
  _CountryCode(name: 'Mongolia', dialCode: '+976', flag: '🇲🇳'),
  _CountryCode(name: 'Montenegro', dialCode: '+382', flag: '🇲🇪'),
  _CountryCode(name: 'Montserrat', dialCode: '+1664', flag: '🇲🇸'),
  _CountryCode(name: 'Morocco', dialCode: '+212', flag: '🇲🇦'),
  _CountryCode(name: 'Mozambique', dialCode: '+258', flag: '🇲🇿'),
  _CountryCode(name: 'Myanmar', dialCode: '+95', flag: '🇲🇲'),
  _CountryCode(name: 'Namibia', dialCode: '+264', flag: '🇳🇦'),
  _CountryCode(name: 'Nauru', dialCode: '+674', flag: '🇳🇷'),
  _CountryCode(name: 'Nepal', dialCode: '+977', flag: '🇳🇵'),
  _CountryCode(name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
  _CountryCode(name: 'New Caledonia', dialCode: '+687', flag: '🇳🇨'),
  _CountryCode(name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
  _CountryCode(name: 'Nicaragua', dialCode: '+505', flag: '🇳🇮'),
  _CountryCode(name: 'Niger', dialCode: '+227', flag: '🇳🇪'),
  _CountryCode(name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
  _CountryCode(name: 'Niue', dialCode: '+683', flag: '🇳🇺'),
  _CountryCode(name: 'Norfolk Island', dialCode: '+672', flag: '🇳🇫'),
  _CountryCode(name: 'North Korea', dialCode: '+850', flag: '🇰🇵'),
  _CountryCode(name: 'North Macedonia', dialCode: '+389', flag: '🇲🇰'),
  _CountryCode(
    name: 'Northern Mariana Islands',
    dialCode: '+1670',
    flag: '🇲🇵',
  ),
  _CountryCode(name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
  _CountryCode(name: 'Oman', dialCode: '+968', flag: '🇴🇲'),
  _CountryCode(name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  _CountryCode(name: 'Palau', dialCode: '+680', flag: '🇵🇼'),
  _CountryCode(name: 'Palestine', dialCode: '+970', flag: '🇵🇸'),
  _CountryCode(name: 'Panama', dialCode: '+507', flag: '🇵🇦'),
  _CountryCode(name: 'Papua New Guinea', dialCode: '+675', flag: '🇵🇬'),
  _CountryCode(name: 'Paraguay', dialCode: '+595', flag: '🇵🇾'),
  _CountryCode(name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
  _CountryCode(name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
  _CountryCode(name: 'Poland', dialCode: '+48', flag: '🇵🇱'),
  _CountryCode(name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  _CountryCode(name: 'Puerto Rico', dialCode: '+1787', flag: '🇵🇷'),
  _CountryCode(name: 'Qatar', dialCode: '+974', flag: '🇶🇦'),
  _CountryCode(name: 'Republic of the Congo', dialCode: '+242', flag: '🇨🇬'),
  _CountryCode(name: 'Reunion', dialCode: '+262', flag: '🇷🇪'),
  _CountryCode(name: 'Romania', dialCode: '+40', flag: '🇷🇴'),
  _CountryCode(name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
  _CountryCode(name: 'Rwanda', dialCode: '+250', flag: '🇷🇼'),
  _CountryCode(name: 'Saint Barthelemy', dialCode: '+590', flag: '🇧🇱'),
  _CountryCode(name: 'Saint Helena', dialCode: '+290', flag: '🇸🇭'),
  _CountryCode(name: 'Saint Kitts and Nevis', dialCode: '+1869', flag: '🇰🇳'),
  _CountryCode(name: 'Saint Lucia', dialCode: '+1758', flag: '🇱🇨'),
  _CountryCode(name: 'Saint Martin', dialCode: '+590', flag: '🇲🇫'),
  _CountryCode(
    name: 'Saint Pierre and Miquelon',
    dialCode: '+508',
    flag: '🇵🇲',
  ),
  _CountryCode(
    name: 'Saint Vincent and the Grenadines',
    dialCode: '+1784',
    flag: '🇻🇨',
  ),
  _CountryCode(name: 'Samoa', dialCode: '+685', flag: '🇼🇸'),
  _CountryCode(name: 'San Marino', dialCode: '+378', flag: '🇸🇲'),
  _CountryCode(name: 'Sao Tome and Principe', dialCode: '+239', flag: '🇸🇹'),
  _CountryCode(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  _CountryCode(name: 'Senegal', dialCode: '+221', flag: '🇸🇳'),
  _CountryCode(name: 'Serbia', dialCode: '+381', flag: '🇷🇸'),
  _CountryCode(name: 'Seychelles', dialCode: '+248', flag: '🇸🇨'),
  _CountryCode(name: 'Sierra Leone', dialCode: '+232', flag: '🇸🇱'),
  _CountryCode(name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  _CountryCode(name: 'Sint Maarten', dialCode: '+1721', flag: '🇸🇽'),
  _CountryCode(name: 'Slovakia', dialCode: '+421', flag: '🇸🇰'),
  _CountryCode(name: 'Slovenia', dialCode: '+386', flag: '🇸🇮'),
  _CountryCode(name: 'Solomon Islands', dialCode: '+677', flag: '🇸🇧'),
  _CountryCode(name: 'Somalia', dialCode: '+252', flag: '🇸🇴'),
  _CountryCode(name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  _CountryCode(name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  _CountryCode(name: 'South Sudan', dialCode: '+211', flag: '🇸🇸'),
  _CountryCode(name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  _CountryCode(name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
  _CountryCode(name: 'Sudan', dialCode: '+249', flag: '🇸🇩'),
  _CountryCode(name: 'Suriname', dialCode: '+597', flag: '🇸🇷'),
  _CountryCode(name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
  _CountryCode(name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
  _CountryCode(name: 'Syria', dialCode: '+963', flag: '🇸🇾'),
  _CountryCode(name: 'Taiwan', dialCode: '+886', flag: '🇹🇼'),
  _CountryCode(name: 'Tajikistan', dialCode: '+992', flag: '🇹🇯'),
  _CountryCode(name: 'Tanzania', dialCode: '+255', flag: '🇹🇿'),
  _CountryCode(name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
  _CountryCode(name: 'Timor-Leste', dialCode: '+670', flag: '🇹🇱'),
  _CountryCode(name: 'Togo', dialCode: '+228', flag: '🇹🇬'),
  _CountryCode(name: 'Tokelau', dialCode: '+690', flag: '🇹🇰'),
  _CountryCode(name: 'Tonga', dialCode: '+676', flag: '🇹🇴'),
  _CountryCode(name: 'Trinidad and Tobago', dialCode: '+1868', flag: '🇹🇹'),
  _CountryCode(name: 'Tunisia', dialCode: '+216', flag: '🇹🇳'),
  _CountryCode(name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  _CountryCode(name: 'Turkmenistan', dialCode: '+993', flag: '🇹🇲'),
  _CountryCode(
    name: 'Turks and Caicos Islands',
    dialCode: '+1649',
    flag: '🇹🇨',
  ),
  _CountryCode(name: 'Tuvalu', dialCode: '+688', flag: '🇹🇻'),
  _CountryCode(name: 'Uganda', dialCode: '+256', flag: '🇺🇬'),
  _CountryCode(name: 'Ukraine', dialCode: '+380', flag: '🇺🇦'),
  _CountryCode(name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪'),
  _CountryCode(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  _CountryCode(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  _CountryCode(name: 'Uruguay', dialCode: '+598', flag: '🇺🇾'),
  _CountryCode(name: 'Uzbekistan', dialCode: '+998', flag: '🇺🇿'),
  _CountryCode(name: 'Vanuatu', dialCode: '+678', flag: '🇻🇺'),
  _CountryCode(name: 'Vatican City', dialCode: '+379', flag: '🇻🇦'),
  _CountryCode(name: 'Venezuela', dialCode: '+58', flag: '🇻🇪'),
  _CountryCode(name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
  _CountryCode(name: 'Wallis and Futuna', dialCode: '+681', flag: '🇼🇫'),
  _CountryCode(name: 'Yemen', dialCode: '+967', flag: '🇾🇪'),
  _CountryCode(name: 'Zambia', dialCode: '+260', flag: '🇿🇲'),
  _CountryCode(name: 'Zimbabwe', dialCode: '+263', flag: '🇿🇼'),
];
