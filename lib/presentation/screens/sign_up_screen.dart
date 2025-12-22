import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/result.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../design_system/widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _usernameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _otpTouched = false;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _registeredEmail;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fieldsDisabled = _otpSent || _isLoading;
    return AuthScaffold(
      title: 'Sign Up',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _usernameController,
            enabled: !fieldsDisabled,
            decoration: InputDecoration(
              labelText: 'Username',
              helperText: 'Use 3-20 letters, numbers, or underscore.',
              errorText: _usernameErrorText(),
            ),
            onTap: () => _markUsernameTouched(),
            onChanged: (_) => _markUsernameTouched(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            enabled: !fieldsDisabled,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email address',
              helperText: 'We will send a verification code after sign up.',
              errorText: _emailErrorText(),
            ),
            onTap: () => _markEmailTouched(),
            onChanged: (_) => _markEmailTouched(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            enabled: !fieldsDisabled,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'Use at least 8 characters.',
              errorText: _passwordErrorText(),
            ),
            onTap: () => _markPasswordTouched(),
            onChanged: (_) => _markPasswordTouched(),
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
          const SizedBox(height: 20),
          PrimaryButton(
            label: _otpSent ? 'Verify email' : 'Create account',
            loading: _isLoading,
            onPressed: _isLoading
                ? null
                : () {
                    if (_otpSent) {
                      _verifyOtp();
                    } else {
                      _createAccount();
                    }
                  },
          ),
          if (_otpSent) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: const Text('Resend code'),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => context.go(CrushRoutes.login),
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }

  void _markUsernameTouched() {
    if (!_usernameTouched) {
      setState(() {
        _usernameTouched = true;
      });
    }
  }

  void _markEmailTouched() {
    if (!_emailTouched) {
      setState(() {
        _emailTouched = true;
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

  void _markOtpTouched() {
    if (!_otpTouched) {
      setState(() {
        _otpTouched = true;
      });
    }
  }

  String? _usernameErrorText() {
    if (!_usernameTouched) return null;
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      return 'Choose a username';
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
    if (!valid) {
      return 'Use 3-20 letters, numbers, or underscore';
    }
    return null;
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

  String? _passwordErrorText() {
    if (!_passwordTouched) return null;
    final password = _passwordController.text;
    if (password.isEmpty) {
      return 'Enter a password';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters';
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

  Future<void> _createAccount() async {
    setState(() {
      _usernameTouched = true;
      _emailTouched = true;
      _passwordTouched = true;
    });
    final usernameError = _usernameErrorText();
    final emailError = _emailErrorText();
    final passwordError = _passwordErrorText();
    if (usernameError != null || emailError != null || passwordError != null) {
      showErrorSnackBar(
        context,
        usernameError ?? emailError ?? passwordError!,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final email = normalizeEmail(_emailController.text);
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().signUpWithPassword(
            username: _usernameController.text.trim(),
            email: email,
            password: _passwordController.text,
          ),
      logLabel: 'AuthRepository.signUpWithPassword',
      fallbackError: 'Could not create account. Check your details and try again.',
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? 'Sign up failed.');
      return;
    }
    _registeredEmail = email;
    setState(() {
      _otpSent = true;
    });
    showSuccessSnackBar(
      context,
      'Check your email for a 6-digit code to verify your account.',
    );
  }

  Future<void> _sendOtp() async {
    final email = normalizeEmail(_registeredEmail ?? _emailController.text);
    if (email.isEmpty) {
      showErrorSnackBar(context, 'Enter your email address.');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().requestEmailOtp(
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
    final email = normalizeEmail(_registeredEmail ?? _emailController.text);
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().verifyEmailOtp(
            identifier: email,
            otp: _otpController.text.trim(),
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
    context.go(CrushRoutes.home);
  }
}
