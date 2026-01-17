import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';

/// Screen shown when user is authenticated but email is not verified.
/// User must verify their email before accessing the app.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _checkTimer;
  bool _isSending = false;
  bool _isChecking = false;
  String? _message;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    // Start checking for verification periodically
    _startVerificationCheck();
    // Send initial verification email
    _sendVerificationEmail();
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
      AppLogger.logInfo('[EmailVerificationScreen] App resumed, checking verification...');
      _checkVerification();
    }
  }

  void _startVerificationCheck() {
    // Check every 3 seconds if email is verified
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerification();
    });
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final authRepo = context.read<AuthRepository>();
      final user = await authRepo.checkEmailVerification();

      if (user != null && user.isEmailVerified) {
        AppLogger.logInfo('[EmailVerificationScreen] Email verified! Navigating to home...');
        _checkTimer?.cancel();

        if (mounted) {
          // Show success message
          setState(() {
            _message = 'Email verified successfully! Redirecting...';
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
      AppLogger.logError('[EmailVerificationScreen] Error checking verification', e);
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
    });

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.sendEmailVerification();

      if (mounted) {
        setState(() {
          _message = 'Verification email sent! Check your inbox.';
          _resendCooldown = 60; // 60 second cooldown
        });
        _startCooldownTimer();
      }
    } catch (e) {
      AppLogger.logError('[EmailVerificationScreen] Error sending verification', e);
      if (mounted) {
        setState(() {
          _message = 'Failed to send email. Please try again.';
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
      final authRepo = context.read<AuthRepository>();
      await authRepo.signOut();
      if (mounted) {
        context.go(CrushRoutes.authGateway);
      }
    } catch (e) {
      AppLogger.logError('[EmailVerificationScreen] Error signing out', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.email,
    );

    return Scaffold(
      body: SafeArea(
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
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              DsGap.md,

              // Description
              Text(
                'We\'ve sent a verification link to:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              DsGap.sm,
              Text(
                user ?? 'your email',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              DsGap.md,
              Text(
                'Click the link in the email to verify your account and continue.',
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
                    color: _message!.contains('Failed')
                        ? DsColors.error.withValues(alpha: 0.1)
                        : DsColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _message!.contains('Failed')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _message!.contains('Failed')
                            ? DsColors.error
                            : DsColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _message!.contains('Failed')
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
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Checking verification status...',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                DsGap.lg,
              ],

              // Resend button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_isSending || _resendCooldown > 0)
                      ? null
                      : _sendVerificationEmail,
                  style: FilledButton.styleFrom(
                    backgroundColor: DsColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend Verification Email',
                        ),
                ),
              ),
              DsGap.md,

              // Check now button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isChecking ? null : _checkVerification,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('I\'ve Verified - Check Now'),
                ),
              ),

              const Spacer(),

              // Sign out / Use different email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _signOut,
                    child: const Text('Sign Out'),
                  ),
                  const Text(' • '),
                  TextButton(
                    onPressed: () {
                      _signOut();
                    },
                    child: const Text('Use Different Email'),
                  ),
                ],
              ),
              DsGap.lg,
            ],
          ),
        ),
      ),
    );
  }
}
