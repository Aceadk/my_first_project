import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/utils/result.dart';
import '../../core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../design_system/widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _emailTouched = false;
  bool _otpTouched = false;
  bool _passwordTouched = false;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _sentEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your email to reset your password.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email address',
              helperText: 'We will send a 6-digit code to the email on file.',
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
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New password',
                helperText: 'Use at least 8 characters.',
                errorText: _passwordErrorText(),
              ),
              onTap: () => _markPasswordTouched(),
              onChanged: (_) => _markPasswordTouched(),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: _otpSent ? 'Reset password' : 'Send code',
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

  void _markPasswordTouched() {
    if (!_passwordTouched) {
      setState(() {
        _passwordTouched = true;
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

  String? _passwordErrorText() {
    if (!_passwordTouched) return null;
    final password = _passwordController.text;
    if (password.isEmpty) {
      return 'Enter a new password';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters';
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
    final result = await Result.guard(
      () => context
          .read<AuthRepository>()
          .requestPasswordReset(email: email),
      logLabel: 'AuthRepository.requestPasswordReset',
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
      'If an account exists, a 6-digit code is on the way.',
    );
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _otpTouched = true;
      _passwordTouched = true;
    });
    final otpError = _otpErrorText();
    final passwordError = _passwordErrorText();
    if (otpError != null) {
      showErrorSnackBar(context, otpError);
      return;
    }
    if (passwordError != null) {
      showErrorSnackBar(context, passwordError);
      return;
    }
    final email = normalizeEmail(_sentEmail ?? _emailController.text);
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text;
    setState(() {
      _isLoading = true;
    });
    final tokenResult = await Result.guard(
      () => context
          .read<AuthRepository>()
          .verifyPasswordResetOtp(email: email, otp: otp),
      logLabel: 'AuthRepository.verifyPasswordResetOtp',
      fallbackError: 'Invalid or expired code. Please try again.',
    );

    if (!mounted) return;
    if (!tokenResult.isSuccess || tokenResult.data == null) {
      setState(() {
        _isLoading = false;
      });
      showErrorSnackBar(
        context,
        tokenResult.errorMessage ?? 'Invalid or expired code.',
      );
      return;
    }

    final resetResult = await Result.guard(
      () => context.read<AuthRepository>().resetPasswordWithToken(
            email: email,
            resetToken: tokenResult.data!,
            newPassword: newPassword,
          ),
      logLabel: 'AuthRepository.resetPasswordWithToken',
      fallbackError: 'Could not reset password. Please try again.',
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!resetResult.isSuccess) {
      showErrorSnackBar(
        context,
        resetResult.errorMessage ?? 'Reset failed.',
      );
      return;
    }
    setState(() {
      _otpSent = false;
      _sentEmail = null;
      _otpController.clear();
      _passwordController.clear();
    });
    showSuccessSnackBar(context, 'Password reset. Please log in again.');
    Navigator.pop(context);
  }
}
