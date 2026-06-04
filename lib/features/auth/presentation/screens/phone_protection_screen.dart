import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/widgets/auth_scaffold.dart';
import 'package:crushhour/design_system/widgets/primary_button.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PhoneProtectionScreen extends StatefulWidget {
  const PhoneProtectionScreen({super.key});

  @override
  State<PhoneProtectionScreen> createState() => _PhoneProtectionScreenState();
}

class _PhoneProtectionScreenState extends State<PhoneProtectionScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _phoneTouched = false;
  bool _otpTouched = false;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _isDeleting = false;
  String? _sentPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, CrushUser?>(
      (bloc) => bloc.state.user,
    );
    final currentPhone = user?.phoneNumber;
    final phoneVerified = user?.isPhoneVerified ?? false;
    final hasPhone = currentPhone != null && currentPhone.isNotEmpty;

    // If phone is already verified, show locked state with delete option
    if (phoneVerified && hasPhone) {
      return AuthScaffold(
        title: 'Phone protection',
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
                    'Phone Verified',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DsColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _maskPhoneNumber(currentPhone),
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
                      'Your phone number is verified and linked to your account.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Delete phone number option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DsColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DsColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        color: DsColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remove phone number',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DsColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Removing your phone number will:\n'
                    '- Unlink it from your account in ~3 days\n'
                    '- Make it available for new accounts after 3 days\n'
                    '- Remove phone-based security features',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: DsColors.error),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isDeleting
                          ? null
                          : () =>
                                _showDeleteConfirmation(context, currentPhone),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DsColors.error,
                        side: const BorderSide(color: DsColors.error),
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DsColors.error,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context).removePhoneNumber1,
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

    // Normal flow for adding/verifying phone
    return AuthScaffold(
      title: 'Phone protection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add and verify a phone number to protect your account and enable SMS-based features.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (hasPhone && !phoneVerified) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DsColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DsColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: DsColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current number: ${_maskPhoneNumber(currentPhone)} (not verified)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone number',
              hintText: '1 234 567 8900',
              helperText: 'Enter country code and number (e.g., 1 for US)',
              errorText: _phoneErrorText(),
              prefixIcon: const Icon(Icons.phone_outlined),
              // Pre-filled + prefix that users don't need to type
              prefixText: '+ ',
              prefixStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onTap: () => _markPhoneTouched(),
            onChanged: (_) => _markPhoneTouched(),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Verification code',
                helperText: 'Enter the 6-digit code sent to your phone.',
                errorText: _otpErrorText(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              onTap: () => _markOtpTouched(),
              onChanged: (_) => _markOtpTouched(),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _otpSent ? 'Verify code' : 'Send verification code',
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
    );
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length <= 4) return phone;
    final visibleStart = phone.substring(0, phone.length > 6 ? 4 : 2);
    final visibleEnd = phone.substring(phone.length - 2);
    final maskedLength = phone.length - visibleStart.length - visibleEnd.length;
    return '$visibleStart${'*' * maskedLength}$visibleEnd';
  }

  void _markPhoneTouched() {
    if (!_phoneTouched) {
      setState(() {
        _phoneTouched = true;
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

  String? _phoneErrorText() {
    if (!_phoneTouched) return null;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      return 'Enter your phone number';
    }
    // Remove any + if user typed it (we add it automatically)
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10) {
      return 'Enter a valid phone number with country code';
    }
    return null;
  }

  /// Returns the full phone number with + prefix
  String _getFullPhoneNumber() {
    final phone = _phoneController.text.trim();
    // Remove any existing + and add our own
    final cleaned = phone.startsWith('+') ? phone : '+$phone';
    return cleaned;
  }

  String? _otpErrorText() {
    if (!_otpTouched) return null;
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      return 'Enter the 6-digit code';
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return 'Use the 6-digit code from SMS';
    }
    return null;
  }

  Future<void> _requestOtp() async {
    setState(() {
      _phoneTouched = true;
    });
    final phoneError = _phoneErrorText();
    if (phoneError != null) {
      showErrorSnackBar(context, phoneError);
      return;
    }

    // Require current password before allowing phone change/linking
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
                const Text('Please enter your current password to continue.'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
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

    final phone = _getFullPhoneNumber();
    setState(() {
      _isLoading = true;
    });

    final result = await Result.guard(
      () => context.read<AuthRepository>().sendOtp(phone),
      logLabel: 'AuthRepository.sendOtp',
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
      _sentPhone = phone;
    });
    showSuccessSnackBar(context, 'Verification code sent to your phone.');
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

    final phone = _sentPhone ?? _getFullPhoneNumber();
    final otp = _otpController.text.trim();
    setState(() {
      _isLoading = true;
    });

    final result = await Result.guard(
      () => context.read<AuthRepository>().verifyOtp(
        phoneNumber: phone,
        otp: otp,
      ),
      logLabel: 'AuthRepository.verifyOtp',
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
      _phoneController.clear();
    });
    showSuccessSnackBar(context, 'Phone number verified successfully!');
  }

  void _showDeleteConfirmation(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: DsColors.error,
          size: 48,
        ),
        title: Text(AppLocalizations.of(context).removePhoneNumber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to remove:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _maskPhoneNumber(phoneNumber),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This action will:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '- Schedule permanent removal in ~3 days\n'
              '- Disable phone-based verification\n'
              '- Allow the number to be used for new accounts after 3 days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deletePhoneNumber();
            },
            style: FilledButton.styleFrom(backgroundColor: DsColors.error),
            child: Text(AppLocalizations.of(context).remove),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoneNumber() async {
    // Require current password before allowing phone deletion
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
                const Text('Please enter your current password to continue.'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
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

    setState(() {
      _isDeleting = true;
    });

    final result = await Result.guard(
      () => context.read<AuthRepository>().schedulePhoneDeletion(),
      logLabel: 'AuthRepository.schedulePhoneDeletion',
      fallbackError: 'Could not remove phone number. Please try again.',
    );

    if (!mounted) return;
    setState(() {
      _isDeleting = false;
    });

    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? 'Removal failed.');
      return;
    }

    showSuccessSnackBar(
      context,
      'Phone number scheduled for removal. It will be fully unlinked in ~3 days.',
    );

    // Go back to settings
    if (mounted) {
      context.pop();
    }
  }
}
