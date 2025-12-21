import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
import '../widgets/onboarding_progress.dart';
import '../widgets/onboarding_nav_buttons.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _otpTouched = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhone = context
            .select<AuthBloc, String?>((bloc) => bloc.state.phoneInProgress) ??
        widget.phoneNumber;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              Navigator.pushReplacementNamed(context, CrushRoutes.basicInfo);
            }
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                const OnboardingProgress(
                  currentStep: 2,
                  caption: 'Enter the 6-digit code we sent',
                ),
                const SizedBox(height: 20),
                Text(
                  'OTP sent to $currentPhone',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    helperText: 'Enter the 6-digit code from your SMS.',
                    errorText: _otpErrorText(),
                  ),
                  onTap: () => _markOtpTouched(),
                  onChanged: (_) => _markOtpTouched(),
                ),
                const SizedBox(height: 24),
                OnboardingNavButtons(
                  onBack: state.isLoading ? null : () => Navigator.pop(context),
                  onNext: state.isLoading || !_canSubmitOtp()
                      ? null
                      : () {
                          setState(() {
                            _otpTouched = true;
                          });
                          final otpDigits = _digitsOnly(_otpController.text);
                          if (otpDigits.length != 6) {
                            showErrorSnackBar(
                              context,
                              'Enter the 6-digit code to continue.',
                            );
                            return;
                          }
                          context.read<AuthBloc>().add(AuthOtpSubmitted(
                                currentPhone,
                                otpDigits,
                              ));
                        },
                  nextLoading: state.isLoading,
                ),
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () => context
                          .read<AuthBloc>()
                          .add(AuthOtpResendRequested(currentPhone)),
                  child: const Text('Resend code'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _markOtpTouched() {
    if (!_otpTouched) {
      setState(() {
        _otpTouched = true;
      });
    }
  }

  String? _otpErrorText() {
    if (!_otpTouched) return null;
    final otpDigits = _digitsOnly(_otpController.text);
    if (otpDigits.isEmpty) {
      return 'Enter the code to verify your phone';
    }
    if (otpDigits.length != 6) {
      return 'The code should be 6 digits';
    }
    return null;
  }

  bool _canSubmitOtp() =>
      _digitsOnly(_otpController.text).length == 6;
}

String _digitsOnly(String input) =>
    input.replaceAll(RegExp(r'[^0-9]'), '');
