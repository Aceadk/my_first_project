import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _emailTouched = false;
  bool _emailSent = false;
  bool _isLoading = false;
  String? _sentEmail;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: DsColors.backgroundLight.withValues(alpha: 0),
        elevation: 0,
        leading: GlassIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: DsEdgeInsets.allXxl,
          child: _emailSent
              ? _buildEmailSentView(context, isDark)
              : _buildEmailInputView(context, isDark),
        ),
      ),
    );
  }

  Widget _buildEmailInputView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: DsColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 36,
            color: DsColors.primary,
          ),
        ),
        DsGap.xxl,
        // Title
        Text(
          'Forgot Password?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        DsGap.sm,
        // Subtitle
        Text(
          'No worries! Enter your email and we\'ll send you a link to reset your password.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color:
                    isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              ),
        ),
        DsGap.xxxl,
        // Email field
        GlassTextField(
          controller: _emailController,
          label: 'Email address',
          hintText: 'you@example.com',
          prefixIcon: Icons.email_outlined,
          errorText: _emailErrorText(),
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _markEmailTouched(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _requestPasswordReset(),
        ),
        DsGap.xxl,
        // Send button
        Semantics(
          button: true,
          label: 'Send Reset Link',
          child: SizedBox(
            width: double.infinity,
            child: GlassPrimaryButton(
              onPressed: _isLoading ? null : _requestPasswordReset,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DsColors.backgroundLight,
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        DsGap.xl,
        // Back to login
        Semantics(
          button: true,
          label: 'Back to Sign In',
          child: GlassSmallButton(
            onPressed: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 18),
                SizedBox(width: 8),
                Text('Back to Sign In'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSentView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DsColors.success, DsColors.success],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: DsColors.success.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 40,
            color: DsColors.backgroundLight,
          ),
        ),
        DsGap.xxl,
        // Title
        Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        DsGap.md,
        // Email sent to
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? DsColors.surfaceDark.withValues(alpha: 0.5)
                : DsColors.inputFillLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _sentEmail ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DsColors.primary,
                ),
          ),
        ),
        DsGap.xl,
        // Instructions
        Container(
          padding: DsEdgeInsets.allLg,
          decoration: BoxDecoration(
            color: isDark
                ? DsColors.info.withValues(alpha: 0.1)
                : DsColors.info.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DsColors.info.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: DsColors.info.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: DsColors.info,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Open the email we sent to your inbox',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? DsColors.textPrimaryDark
                                : DsColors.textPrimaryLight,
                          ),
                    ),
                  ),
                ],
              ),
              DsGap.md,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: DsColors.info.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: DsColors.info,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Click the "Reset Password" link in the email',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? DsColors.textPrimaryDark
                                : DsColors.textPrimaryLight,
                          ),
                    ),
                  ),
                ],
              ),
              DsGap.md,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: DsColors.info.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: DsColors.info,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create your new password and sign in',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? DsColors.textPrimaryDark
                                : DsColors.textPrimaryLight,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DsGap.xl,
        // Tip
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Check your spam folder if you don\'t see the email',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
              ),
            ),
          ],
        ),
        DsGap.xxxl,
        // Open email app button
        Semantics(
          button: true,
          label: 'Open Email App',
          child: SizedBox(
            width: double.infinity,
            child: GlassOutlinedButton(
              onPressed: _openEmailApp,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Open Email App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        DsGap.md,
        // Back to login button
        Semantics(
          button: true,
          label: 'Back to Sign In',
          child: SizedBox(
            width: double.infinity,
            child: GlassPrimaryButton(
              onPressed: () => context.go(CrushRoutes.login),
              child: const Text(
                'Back to Sign In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        DsGap.xl,
        // Resend option
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the email? ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
            ),
            Semantics(
              button: true,
              label: _isLoading ? 'Sending email' : 'Resend email',
              child: GlassSmallButton(
                onPressed: _isLoading ? null : _resendEmail,
                child: Text(
                  _isLoading ? 'Sending...' : 'Resend',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _markEmailTouched() {
    if (!_emailTouched) {
      setState(() {
        _emailTouched = true;
      });
    } else {
      setState(() {}); // Trigger rebuild for validation
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

  Future<void> _requestPasswordReset() async {
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
      () => context.read<AuthRepository>().requestPasswordReset(email: email),
      logLabel: 'AuthRepository.requestPasswordReset',
      fallbackError: 'Could not send reset link. Please try again.',
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
      _emailSent = true;
      _sentEmail = email;
    });
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
    });
    final email = _sentEmail ?? normalizeEmail(_emailController.text);
    final result = await Result.guard(
      () => context.read<AuthRepository>().requestPasswordReset(email: email),
      logLabel: 'AuthRepository.requestPasswordReset',
      fallbackError: 'Could not resend reset link. Please try again.',
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? 'Resend failed.');
      return;
    }
    showSuccessSnackBar(context, 'Reset link sent again! Check your email.');
  }

  Future<void> _openEmailApp() async {
    final emailUri = Uri(scheme: 'mailto');
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          showErrorSnackBar(context, 'Could not open email app.');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Could not open email app.');
      }
    }
  }
}
