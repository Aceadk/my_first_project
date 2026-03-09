import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Screen shown when user is authenticated but email is not verified.
/// User must verify their email before accessing the app.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  static const int _resendCooldownSeconds = 30;

  /// Max number of automatic polls before requiring manual check.
  static const int _maxAutoCheckAttempts = 200;

  /// Tracks when we last auto-sent a verification email so re-mounting
  /// this screen (e.g. via router redirect) doesn't spam Firebase.
  static DateTime? _lastAutoSendTime;

  Timer? _checkTimer;
  int _autoCheckCount = 0;
  bool _isSending = false;
  bool _isChecking = false;
  String? _message;
  bool _isErrorMessage = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  AuthFlowUseCases _authFlowUseCases() {
    return AuthFlowUseCases(context.read<AuthRepository>());
  }

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    // Start checking for verification periodically
    _startVerificationCheck();
    // Only auto-send if we haven't sent one recently (prevents spam on re-mount)
    final now = DateTime.now();
    if (_lastAutoSendTime == null ||
        now.difference(_lastAutoSendTime!).inSeconds > _resendCooldownSeconds) {
      _lastAutoSendTime = now;
      _sendVerificationEmail();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - immediately check verification
      AppLogger.info(
        '[EmailVerificationScreen] App resumed, checking verification...',
      );
      _checkVerification();
    }
  }

  void _startVerificationCheck() {
    // Check every 3 seconds if email is verified, capped at _maxAutoCheckAttempts
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _autoCheckCount++;
      if (_autoCheckCount >= _maxAutoCheckAttempts) {
        _checkTimer?.cancel();
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _message = l10n.onboardingEmailVerificationAutoCheckStopped(
              _maxAutoCheckAttempts ~/ 20,
            );
            _isErrorMessage = false;
          });
        }
        return;
      }
      _checkVerification();
    });
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final verificationResult = await _authFlowUseCases()
          .checkEmailVerification();
      final user = verificationResult.data;

      if (user != null && user.isEmailVerified) {
        AppLogger.info(
          '[EmailVerificationScreen] Email verified! Navigating to home...',
        );
        _checkTimer?.cancel();

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          // Show success message
          setState(() {
            _message = l10n.onboardingEmailVerificationSuccessRedirecting;
            _isErrorMessage = false;
          });

          // Give a brief moment for user to see success message, then navigate
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            // Navigate to home - the router should handle this via auth state,
            // but we also trigger it explicitly for reliability
            context.go(CrushRoutes.home);
          }
        }
      }
    } catch (e) {
      AppLogger.error(
        '[EmailVerificationScreen] Error checking verification',
        error: e,
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSending || _resendCooldown > 0) return;

    setState(() {
      _isSending = true;
      _message = null;
      _isErrorMessage = false;
    });

    try {
      final result = await _authFlowUseCases().sendEmailVerification();
      if (!result.isSuccess) {
        throw Exception(result.errorMessage);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _message = l10n.onboardingEmailVerificationSent;
          _resendCooldown = _resendCooldownSeconds;
          _isErrorMessage = false;
        });
        _startCooldownTimer();
      }
    } catch (e) {
      AppLogger.error(
        '[EmailVerificationScreen] Error sending verification',
        error: e,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final message = e.toString().toLowerCase();
        final errorMessage =
            message.contains('too-many-requests') ||
                message.contains('too many requests')
            ? l10n.onboardingEmailVerificationTooManyAttempts
            : l10n.onboardingEmailVerificationSendFailed;
        setState(() {
          _message = errorMessage;
          _isErrorMessage = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  Future<void> _signOut() async {
    try {
      await _authFlowUseCases().signOut();
      if (mounted) {
        context.go(CrushRoutes.authGateway);
      }
    } catch (e) {
      AppLogger.error('[EmailVerificationScreen] Error signing out', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.email,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: SafeArea(
              child: Padding(
                padding: DsEdgeInsets.screenPadding,
                child: Column(
                  children: [
                    const Spacer(),

                    // Email icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: DsColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 64,
                        color: DsColors.primary,
                      ),
                    ),
                    DsGap.xl,

                    // Title
                    Text(
                      l10n.onboardingEmailVerificationTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    DsGap.md,

                    // Description
                    Text(
                      l10n.onboardingEmailVerificationSentTo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    DsGap.sm,
                    Text(
                      user ?? l10n.onboardingEmailVerificationFallbackEmail,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    DsGap.md,
                    Text(
                      l10n.onboardingEmailVerificationInstruction,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    DsGap.xl,

                    // Status message
                    if (_message != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DsSpacing.lg,
                          vertical: DsSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: _isErrorMessage
                              ? DsColors.error.withValues(alpha: 0.1)
                              : DsColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isErrorMessage
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: _isErrorMessage
                                  ? DsColors.error
                                  : DsColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: _isErrorMessage
                                      ? DsColors.error
                                      : DsColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DsGap.lg,
                    ],

                    // Checking indicator
                    if (_isChecking) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.onboardingEmailVerificationCheckingStatus,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      DsGap.lg,
                    ],

                    // Resend button
                    Semantics(
                      button: true,
                      label: l10n.onboardingEmailVerificationResendSemantics,
                      child: SizedBox(
                        width: double.infinity,
                        child: GlassPrimaryButton(
                          onPressed: (_isSending || _resendCooldown > 0)
                              ? null
                              : _sendVerificationEmail,
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: DsColors.backgroundLight,
                                  ),
                                )
                              : Text(
                                  _resendCooldown > 0
                                      ? l10n.onboardingEmailVerificationResendIn(
                                          _resendCooldown,
                                        )
                                      : l10n.onboardingEmailVerificationResendButton,
                                ),
                        ),
                      ),
                    ),
                    DsGap.md,

                    // Check now button
                    Semantics(
                      button: true,
                      label: l10n.onboardingEmailVerificationCheckNowSemantics,
                      child: SizedBox(
                        width: double.infinity,
                        child: GlassOutlinedButton(
                          onPressed: _isChecking ? null : _checkVerification,
                          child: Text(
                            l10n.onboardingEmailVerificationCheckNowButton,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Sign out / Use different email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlassSmallButton(
                          onPressed: _signOut,
                          child: Text(l10n.signOut),
                        ),
                        Text(l10n.emptyString),
                        GlassSmallButton(
                          onPressed: () {
                            _checkTimer?.cancel();
                            context.go(CrushRoutes.changeEmail);
                          },
                          child: Text(l10n.useDifferentEmail),
                        ),
                      ],
                    ),
                    DsGap.lg,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
