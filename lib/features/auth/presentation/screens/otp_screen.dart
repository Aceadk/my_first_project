import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/presentation/widgets/onboarding_progress.dart';
import 'package:crushhour/presentation/widgets/onboarding_nav_buttons.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

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
  void initState() {
    super.initState();

    // Log onboarding step 2: verify_otp
    AnalyticsService.instance.logOnboardingStep(
      step: 'verify_otp',
      stepNumber: 2,
      totalSteps: 6,
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentPhone =
        context.select<AuthBloc, String?>(
          (bloc) => bloc.state.phoneInProgress,
        ) ??
        widget.phoneNumber;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyOtp)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.status == AuthStatus.authenticated) {
                    context.go(CrushRoutes.home);
                  }
                  final error = state.errorMessage;
                  if (error != null && error.isNotEmpty) {
                    showErrorSnackBar(context, error);
                  }
                },
                builder: (context, state) {
                  return Column(
                    children: [
                      OnboardingProgress(
                        currentStep: 2,
                        caption: l10n.authOtpCaption,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.authOtpSentTo(currentPhone),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.authEnterOtp,
                          helperText: l10n.authEnterCodeFromSms,
                          errorText: _otpErrorText(),
                        ),
                        onTap: () => _markOtpTouched(),
                        onChanged: (_) => _markOtpTouched(),
                      ),
                      const SizedBox(height: 24),
                      OnboardingNavButtons(
                        onBack: state.isLoading
                            ? null
                            : () => Navigator.pop(context),
                        onNext: state.isLoading || !_canSubmitOtp()
                            ? null
                            : () {
                                setState(() {
                                  _otpTouched = true;
                                });
                                final otpDigits = _digitsOnly(
                                  _otpController.text,
                                );
                                if (otpDigits.length != 6) {
                                  showErrorSnackBar(
                                    context,
                                    l10n.authEnterCodeToContinue,
                                  );
                                  return;
                                }
                                context.read<AuthBloc>().add(
                                  AuthOtpSubmitted(currentPhone, otpDigits),
                                );
                              },
                        nextLoading: state.isLoading,
                      ),
                      Semantics(
                        button: true,
                        label: l10n.resendCode,
                        child: GlassSmallButton(
                          onPressed: state.isLoading
                              ? null
                              : () => context.read<AuthBloc>().add(
                                  AuthOtpResendRequested(currentPhone),
                                ),
                          child: Text(AppLocalizations.of(context).resendCode),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
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
    final l10n = AppLocalizations.of(context);
    final otpDigits = _digitsOnly(_otpController.text);
    if (otpDigits.isEmpty) {
      return l10n.authEnterCodeVerifyPhone;
    }
    if (otpDigits.length != 6) {
      return l10n.authCodeShouldBe6Digits;
    }
    return null;
  }

  bool _canSubmitOtp() => _digitsOnly(_otpController.text).length == 6;
}

String _digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');
