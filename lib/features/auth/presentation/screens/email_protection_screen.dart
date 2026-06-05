import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/widgets/auth_scaffold.dart';
import 'package:crushhour/design_system/widgets/primary_button.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/widgets/auth_utility_layout_constraints.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class EmailProtectionScreen extends StatefulWidget {
  final bool redirectOnSuccess;

  const EmailProtectionScreen({super.key, this.redirectOnSuccess = false});

  @override
  State<EmailProtectionScreen> createState() => _EmailProtectionScreenState();
}

class _EmailProtectionScreenState extends State<EmailProtectionScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _emailTouched = false;
  bool _otpTouched = false;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _sentEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.select<AuthBloc, CrushUser?>(
      (bloc) => bloc.state.user,
    );
    final currentEmail = user?.email;
    final emailVerified = user?.isEmailVerified ?? false;

    // If email is already verified, show locked state
    if (emailVerified && currentEmail != null && currentEmail.isNotEmpty) {
      return AuthScaffold(
        title: l10n.authEmailProtectionTitle,
        child: Center(
          child: ConstrainedBox(
            key: authUtilityContentConstraintKey,
            constraints: BoxConstraints(
              maxWidth: authUtilityMaxWidthFor(MediaQuery.sizeOf(context).width),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Verified badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DsColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DsColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DsColors.success.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: DsColors.success,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.authEmailVerifiedBadge,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DsColors.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentEmail,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Lock icon and message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.authEmailAlreadyVerifiedLocked,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Info about changing email
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DsColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DsColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: DsColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.authWantDifferentEmail,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: DsColors.warning,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.authDifferentEmailInstructions,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DsColors.warning,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            context.push(CrushRoutes.accountSettings),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.authGoToAccountSettings,
                          style: const TextStyle(
                            color: DsColors.warning,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal flow for unverified or no email
    return AuthScaffold(
      title: l10n.authEmailProtectionTitle,
      child: Center(
        child: ConstrainedBox(
          key: authUtilityContentConstraintKey,
          constraints: BoxConstraints(
            maxWidth: authUtilityMaxWidthFor(MediaQuery.sizeOf(context).width),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authEmailProtectionIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (currentEmail != null && currentEmail.isNotEmpty) ...[
                Text(
                  l10n.authCurrentEmailLabel(currentEmail),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.authStatusNotVerified,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.authEmailAddress,
                  helperText: l10n.authCodeWillBeSentToEmail,
                  errorText: _emailErrorText(),
                ),
                onTap: () => _markEmailTouched(),
                onChanged: (_) => _markEmailTouched(),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.authVerificationCode,
                    helperText: l10n.authEnterCodeFromEmail,
                    errorText: _otpErrorText(),
                  ),
                  onTap: () => _markOtpTouched(),
                  onChanged: (_) => _markOtpTouched(),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: _otpSent ? l10n.authVerifyCode : l10n.authSendCode,
                loading: _isLoading,
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_otpSent) {
                          _verifyOtp();
                        } else {
                          _requestOtp();
                        }
                      },
              ),
              if (_otpSent) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : _requestOtp,
                  child: Text(AppLocalizations.of(context).resendCode),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _markEmailTouched() {
    if (!_emailTouched) {
      setState(() {
        _emailTouched = true;
      });
    }
  }

  void _markOtpTouched() {
    if (!_otpTouched) {
      setState(() {
        _otpTouched = true;
      });
    }
  }

  String? _emailErrorText() {
    if (!_emailTouched) return null;
    final l10n = AppLocalizations.of(context);
    final email = normalizeEmail(_emailController.text);
    if (email.isEmpty) {
      return l10n.authEnterEmailAddress;
    }
    if (!looksLikeEmail(email)) {
      return l10n.errorInvalidEmail;
    }
    return null;
  }

  String? _otpErrorText() {
    if (!_otpTouched) return null;
    final l10n = AppLocalizations.of(context);
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      return l10n.authEnterCodeHint;
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return l10n.authUseCodeFromEmail;
    }
    return null;
  }

  Future<void> _requestOtp() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _emailTouched = true;
    });
    final emailError = _emailErrorText();
    if (emailError != null) {
      showErrorSnackBar(context, emailError);
      return;
    }

    final email = normalizeEmail(_emailController.text);
    setState(() {
      _isLoading = true;
    });

    // Check if email is already registered to another account
    final authRepo = context.read<AuthRepository>();
    final emailExists = await authRepo.isEmailRegistered(email);
    if (emailExists) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showErrorSnackBar(context, l10n.authEmailAlreadyRegistered);
      return;
    }

    final result = await Result.guard(
      () => authRepo.requestEmailOtp(
        identifier: email,
        purpose: EmailOtpPurpose.addEmail,
        email: email,
      ),
      logLabel: 'AuthRepository.requestEmailOtp',
      fallbackError: l10n.authCouldNotSendCode,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? l10n.authRequestFailed);
      return;
    }
    setState(() {
      _otpSent = true;
      _sentEmail = email;
    });
    showSuccessSnackBar(context, l10n.authCodeOnTheWayEmail);
  }

  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _otpTouched = true;
    });
    final otpError = _otpErrorText();
    if (otpError != null) {
      showErrorSnackBar(context, otpError);
      return;
    }
    final email = normalizeEmail(_sentEmail ?? _emailController.text);
    final otp = _otpController.text.trim();
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().verifyEmailOtp(
        identifier: email,
        otp: otp,
        purpose: EmailOtpPurpose.addEmail,
        newEmail: email,
      ),
      logLabel: 'AuthRepository.verifyEmailOtp',
      fallbackError: l10n.authInvalidOrExpiredCode,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? l10n.authVerificationFailed);
      return;
    }
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
    showSuccessSnackBar(context, l10n.authEmailVerified);
    if (widget.redirectOnSuccess && mounted) {
      context.go(CrushRoutes.home);
    }
  }
}
