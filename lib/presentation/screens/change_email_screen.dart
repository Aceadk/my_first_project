import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/result.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../core/validators.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../design_system/widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
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

    return AuthScaffold(
      title: 'Change email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Use a new email to keep your account recoverable.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (currentEmail != null && currentEmail.isNotEmpty) ...[
            Text(
              'Current email: $currentEmail',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'New email address',
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
    final result = await Result.guard(
      () => context.read<AuthRepository>().requestEmailOtp(
            identifier: email,
            purpose: EmailOtpPurpose.changeEmail,
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
            purpose: EmailOtpPurpose.changeEmail,
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
    showSuccessSnackBar(context, 'Email updated.');
  }
}
