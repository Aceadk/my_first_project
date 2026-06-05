import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/design_system/widgets/auth_scaffold.dart';
import 'package:crushhour/design_system/widgets/primary_button.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/widgets/auth_utility_layout_constraints.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final l10n = AppLocalizations.of(context);
    final user = context.select<AuthBloc, CrushUser?>(
      (bloc) => bloc.state.user,
    );
    final currentEmail = user?.email;

    return AuthScaffold(
      title: l10n.authChangeEmailTitle,
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
                l10n.authChangeEmailIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (currentEmail != null && currentEmail.isNotEmpty) ...[
                Text(
                  l10n.authCurrentEmailLabel(currentEmail),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.authNewEmailAddress,
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
    setState(() {
      _emailTouched = true;
    });
    final emailError = _emailErrorText();
    if (emailError != null) {
      showErrorSnackBar(context, emailError);
      return;
    }

    // Security requirement: Require current password before allowing email change
    final passwordController = TextEditingController();
    bool isVerifying = false;

    final isPasswordVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context).authVerifyPasswordTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).authEnterCurrentPasswordPrompt),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).authCurrentPassword,
                    border: const OutlineInputBorder(),
                  ),
                  enabled: !isVerifying,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying
                    ? null
                    : () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        final password = passwordController.text;
                        if (password.isEmpty) return;

                        setDialogState(() => isVerifying = true);
                        try {
                          await dialogContext
                              .read<AuthRepository>()
                              .verifyPassword(password);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          setDialogState(() => isVerifying = false);
                          if (dialogContext.mounted) {
                            showErrorSnackBar(
                              dialogContext,
                              e.toString().replaceAll('Exception: ', ''),
                            );
                          }
                        }
                      },
                child: isVerifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context).authVerify),
              ),
            ],
          );
        },
      ),
    );

    if (isPasswordVerified != true || !mounted) return;

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
      fallbackError: AppLocalizations.of(context).authCouldNotSendCode,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!result.isSuccess) {
      showErrorSnackBar(
        context,
        result.errorMessage ?? AppLocalizations.of(context).authRequestFailed,
      );
      return;
    }
    setState(() {
      _otpSent = true;
      _sentEmail = email;
    });
    showSuccessSnackBar(
      context,
      AppLocalizations.of(context).authCodeOnTheWayEmail,
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
      fallbackError: AppLocalizations.of(context).authInvalidOrExpiredCode,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!result.isSuccess) {
      showErrorSnackBar(
        context,
        result.errorMessage ??
            AppLocalizations.of(context).authVerificationFailed,
      );
      return;
    }
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
    showSuccessSnackBar(context, AppLocalizations.of(context).authEmailUpdated);
  }
}
