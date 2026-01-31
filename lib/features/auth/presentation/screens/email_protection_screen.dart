import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/widgets/auth_scaffold.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/presentation/widgets/primary_button.dart';

class EmailProtectionScreen extends StatefulWidget {
  final bool redirectOnSuccess;

  const EmailProtectionScreen({
    super.key,
    this.redirectOnSuccess = false,
  });

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
    final user = context.select<AuthBloc, CrushUser?>(
      (bloc) => bloc.state.user,
    );
    final currentEmail = user?.email;
    final emailVerified = user?.isEmailVerified ?? false;

    // If email is already verified, show locked state
    if (emailVerified && currentEmail != null && currentEmail.isNotEmpty) {
      return AuthScaffold(
        title: 'Email protection',
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
                    'Email Verified',
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      'Your email is already verified. You cannot make any changes to this email address.',
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
                        'Want to use a different email?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DsColors.warning,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To use a different email address, you will need to delete this account and create a new one with the new email.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DsColors.warning,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push(CrushRoutes.accountSettings),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Go to Account Settings',
                      style: TextStyle(
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
      );
    }

    // Normal flow for unverified or no email
    return AuthScaffold(
      title: 'Email protection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add and verify an email to protect your account and enable recovery.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (currentEmail != null && currentEmail.isNotEmpty) ...[
            Text(
              'Current email: $currentEmail',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Status: not verified',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email address',
              helperText: 'We will send a 6-digit code to this email.',
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
                labelText: 'Verification code',
                helperText: 'Enter the 6-digit code from your email.',
                errorText: _otpErrorText(),
              ),
              onTap: () => _markOtpTouched(),
              onChanged: (_) => _markOtpTouched(),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: _otpSent ? 'Verify code' : 'Send code',
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
              child: const Text('Resend code'),
            ),
          ],
        ],
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
    final email = normalizeEmail(_emailController.text);
    if (email.isEmpty) {
      return 'Enter your email address';
    }
    if (!looksLikeEmail(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _otpErrorText() {
    if (!_otpTouched) return null;
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      return 'Enter the 6-digit code';
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return 'Use the 6-digit code from your email';
    }
    return null;
  }

  Future<void> _requestOtp() async {
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
      showErrorSnackBar(
        context,
        'This email is already registered to another account. Please use a different email address.',
      );
      return;
    }

    final result = await Result.guard(
      () => authRepo.requestEmailOtp(
        identifier: email,
        purpose: EmailOtpPurpose.addEmail,
        email: email,
      ),
      logLabel: 'AuthRepository.requestEmailOtp',
      fallbackError: 'Could not send code. Please try again.',
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? 'Request failed.');
      return;
    }
    setState(() {
      _otpSent = true;
      _sentEmail = email;
    });
    showSuccessSnackBar(
      context,
      'If that email is reachable, a 6-digit code is on the way.',
    );
  }

  Future<void> _verifyOtp() async {
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
      fallbackError: 'Invalid or expired code. Please try again.',
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? 'Verification failed.');
      return;
    }
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
    showSuccessSnackBar(context, 'Email verified.');
    if (widget.redirectOnSuccess && mounted) {
      context.go(CrushRoutes.home);
    }
  }
}
