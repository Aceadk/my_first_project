import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/design_system/widgets/auth_scaffold.dart';
import 'package:crushhour/design_system/widgets/primary_button.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/widgets/auth_utility_layout_constraints.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      title: l10n.authNewDeviceTitle,
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
                l10n.authNewDeviceIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.authEmailOrUsername,
                  helperText: l10n.authCodeWillBeSentToEmailOnFile,
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
                label: _otpSent ? l10n.authVerifyDevice : l10n.authSendCode,
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
    final l10n = AppLocalizations.of(context);
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      return l10n.authEnterUsernameOrEmail;
    }
    if (identifier.contains('@')) {
      if (!looksLikeEmail(identifier)) {
        return l10n.errorInvalidEmail;
      }
      return null;
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(identifier);
    if (!valid) {
      return l10n.onboardingBasicInfoUsernameFormatError;
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
      _identifierTouched = true;
    });
    final identifierError = _identifierErrorText();
    if (identifierError != null) {
      showErrorSnackBar(context, identifierError);
      return;
    }
    final rawIdentifier = _identifierController.text.trim();
    final identifier = rawIdentifier.contains('@')
        ? normalizeEmail(rawIdentifier)
        : rawIdentifier;
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().requestEmailOtp(
        identifier: identifier,
        purpose: EmailOtpPurpose.newDevice,
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
      _sentIdentifier = identifier;
    });
    showSuccessSnackBar(context, l10n.authCodeOnTheWayAccount);
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
    final rawIdentifier = _sentIdentifier ?? _identifierController.text.trim();
    final identifier = rawIdentifier.contains('@')
        ? normalizeEmail(rawIdentifier)
        : rawIdentifier;
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
    showSuccessSnackBar(context, l10n.authDeviceVerified);
  }
}
