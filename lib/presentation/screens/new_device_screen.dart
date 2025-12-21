import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/result.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/primary_button.dart';

class NewDeviceScreen extends StatefulWidget {
  const NewDeviceScreen({super.key});

  @override
  State<NewDeviceScreen> createState() => _NewDeviceScreenState();
}

class _NewDeviceScreenState extends State<NewDeviceScreen> {
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  bool _identifierTouched = false;
  bool _otpTouched = false;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _sentIdentifier;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New device check')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Verify a new device before continuing.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Username or email',
              helperText: 'We will send a 6-digit code to the email on file.',
              errorText: _identifierErrorText(),
            ),
            onTap: () => _markIdentifierTouched(),
            onChanged: (_) => _markIdentifierTouched(),
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
            label: _otpSent ? 'Verify device' : 'Send code',
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

  void _markIdentifierTouched() {
    if (!_identifierTouched) {
      setState(() {
        _identifierTouched = true;
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

  String? _identifierErrorText() {
    if (!_identifierTouched) return null;
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      return 'Enter your username or email';
    }
    if (identifier.contains('@')) {
      if (!_looksLikeEmail(identifier)) {
        return 'Enter a valid email address';
      }
      return null;
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(identifier);
    if (!valid) {
      return 'Use 3-20 letters, numbers, or underscore';
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

  bool _looksLikeEmail(String email) =>
      RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$').hasMatch(email);

  Future<void> _requestOtp() async {
    setState(() {
      _identifierTouched = true;
    });
    final identifierError = _identifierErrorText();
    if (identifierError != null) {
      showErrorSnackBar(context, identifierError);
      return;
    }
    final identifier = _identifierController.text.trim();
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().requestEmailOtp(
            identifier: identifier,
            purpose: EmailOtpPurpose.newDevice,
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
      _sentIdentifier = identifier;
    });
    showSuccessSnackBar(
      context,
      'If an account exists, a 6-digit code is on the way.',
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
    final identifier = _sentIdentifier ?? _identifierController.text.trim();
    final otp = _otpController.text.trim();
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().verifyEmailOtp(
            identifier: identifier,
            otp: otp,
            purpose: EmailOtpPurpose.newDevice,
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
    showSuccessSnackBar(context, 'Device verified.');
  }
}
