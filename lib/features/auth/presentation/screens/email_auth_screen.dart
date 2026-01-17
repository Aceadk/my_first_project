import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/validators.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Email OTP tab controllers
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  bool _identifierTouched = false;
  bool _otpTouched = false;

  // Email Link tab controller
  final _emailLinkController = TextEditingController();
  bool _emailLinkTouched = false;

  // Email + Password tab controllers
  final _emailPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _emailPasswordTouched = false;
  bool _passwordTouched = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _identifierController.dispose();
    _otpController.dispose();
    _emailLinkController.dispose();
    _emailPasswordController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with email'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: DsColors.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: DsColors.primary,
          tabs: const [
            Tab(text: 'Email OTP'),
            Tab(text: 'Email link'),
            Tab(text: 'Password'),
          ],
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go(CrushRoutes.termsConditions);
          } else if (state.status == AuthStatus.emailLinkSent &&
              state.emailInProgress != null) {
            showSuccessSnackBar(
              context,
              'Check your email! We sent a sign-in link to ${state.emailInProgress}',
            );
          } else if (state.status == AuthStatus.emailOtpSent &&
              state.emailOtpIdentifier != null) {
            showSuccessSnackBar(
              context,
              'Verification code sent! Check your email inbox.',
            );
          }
          final error = state.errorMessage;
          if (error != null && error.isNotEmpty) {
            showErrorSnackBar(context, error);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _EmailOtpTab(
                      identifierController: _identifierController,
                      otpController: _otpController,
                      identifierTouched: _identifierTouched,
                      otpTouched: _otpTouched,
                      onIdentifierTouched: () =>
                          setState(() => _identifierTouched = true),
                      onOtpTouched: () => setState(() => _otpTouched = true),
                      state: state,
                    ),
                    _EmailLinkTab(
                      emailController: _emailLinkController,
                      emailTouched: _emailLinkTouched,
                      onEmailTouched: () =>
                          setState(() => _emailLinkTouched = true),
                      state: state,
                    ),
                    _EmailPasswordTab(
                      emailController: _emailPasswordController,
                      passwordController: _passwordController,
                      emailTouched: _emailPasswordTouched,
                      passwordTouched: _passwordTouched,
                      obscurePassword: _obscurePassword,
                      onEmailTouched: () =>
                          setState(() => _emailPasswordTouched = true),
                      onPasswordTouched: () =>
                          setState(() => _passwordTouched = true),
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      state: state,
                    ),
                  ],
                ),
              ),
              // Bottom navigation to phone auth
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TextButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => context.go(CrushRoutes.phoneAuth),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('Use phone number instead'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMAIL OTP TAB
// ═══════════════════════════════════════════════════════════════════════════

class _EmailOtpTab extends StatelessWidget {
  const _EmailOtpTab({
    required this.identifierController,
    required this.otpController,
    required this.identifierTouched,
    required this.otpTouched,
    required this.onIdentifierTouched,
    required this.onOtpTouched,
    required this.state,
  });

  final TextEditingController identifierController;
  final TextEditingController otpController;
  final bool identifierTouched;
  final bool otpTouched;
  final VoidCallback onIdentifierTouched;
  final VoidCallback onOtpTouched;
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otpSent = state.status == AuthStatus.emailOtpSent;
    final isLoading = state.isLoading;

    final rawIdentifier = identifierController.text.trim();
    final identifier =
        rawIdentifier.contains('@') ? normalizeEmail(rawIdentifier) : rawIdentifier;
    final storedIdentifier = state.emailOtpIdentifier;
    final effectiveIdentifier =
        (storedIdentifier != null && storedIdentifier.isNotEmpty)
            ? storedIdentifier
            : identifier;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Icon(
            otpSent ? Icons.mark_email_read_outlined : Icons.email_outlined,
            size: 48,
            color: DsColors.primary,
          ),
          DsGap.lg,
          Text(
            otpSent ? 'Enter verification code' : 'Sign in with email code',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.sm,
          Text(
            otpSent
                ? 'We sent a 6-digit code to your email'
                : 'Enter your email address and we\'ll send you a verification code',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.xl,

          // Email input
          TextField(
            controller: identifierController,
            keyboardType: TextInputType.emailAddress,
            enabled: !otpSent && !isLoading,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Email address',
              hintText: 'you@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _getIdentifierError(identifierTouched),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onTap: onIdentifierTouched,
            onChanged: (_) => onIdentifierTouched(),
            onSubmitted: (_) {
              if (!otpSent && !isLoading) {
                _sendCode(context, identifier);
              }
            },
          ),

          // OTP input (shown after code sent)
          if (otpSent) ...[
            DsGap.lg,
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              enabled: !isLoading,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Verification code',
                hintText: '000000',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _getOtpError(otpTouched),
                counterText: '',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: onOtpTouched,
              onChanged: (_) => onOtpTouched(),
              onSubmitted: (_) {
                if (!isLoading) {
                  _verifyCode(context, effectiveIdentifier);
                }
              },
            ),
          ],

          DsGap.xl,

          // Action button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (otpSent) {
                        _verifyCode(context, effectiveIdentifier);
                      } else {
                        _sendCode(context, identifier);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: DsColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      otpSent ? 'Verify code' : 'Send code',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          // Secondary actions (when OTP sent)
          if (otpSent) ...[
            DsGap.lg,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.read<AuthBloc>().add(
                            AuthEmailOtpResendRequested(effectiveIdentifier),
                          ),
                  child: const Text('Resend code'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          otpController.clear();
                          context.read<AuthBloc>().add(AuthEmailOtpCancelled());
                        },
                  child: const Text('Change email'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _getIdentifierError(bool touched) {
    if (!touched) return null;
    final text = identifierController.text.trim();
    if (text.isEmpty) return 'Please enter your email address';
    if (!looksLikeEmail(text)) return 'Please enter a valid email address';
    return null;
  }

  String? _getOtpError(bool touched) {
    if (!touched) return null;
    final otp = otpController.text.trim();
    if (otp.isEmpty) return 'Please enter the verification code';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) return 'Code must be 6 digits';
    return null;
  }

  void _sendCode(BuildContext context, String identifier) {
    final error = _getIdentifierError(true);
    if (error != null) {
      showErrorSnackBar(context, error);
      return;
    }
    context.read<AuthBloc>().add(AuthEmailOtpRequested(identifier));
  }

  void _verifyCode(BuildContext context, String identifier) {
    final otpError = _getOtpError(true);
    if (otpError != null) {
      showErrorSnackBar(context, otpError);
      return;
    }
    context.read<AuthBloc>().add(
          AuthEmailOtpSubmitted(identifier, otpController.text.trim()),
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMAIL LINK TAB
// ═══════════════════════════════════════════════════════════════════════════

class _EmailLinkTab extends StatelessWidget {
  const _EmailLinkTab({
    required this.emailController,
    required this.emailTouched,
    required this.onEmailTouched,
    required this.state,
  });

  final TextEditingController emailController;
  final bool emailTouched;
  final VoidCallback onEmailTouched;
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkSent = state.status == AuthStatus.emailLinkSent &&
        (state.emailInProgress?.isNotEmpty ?? false);
    final isLoading = state.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Icon(
            linkSent ? Icons.mark_email_read_outlined : Icons.link,
            size: 48,
            color: DsColors.primary,
          ),
          DsGap.lg,
          Text(
            linkSent ? 'Check your email' : 'Sign in with magic link',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.sm,
          Text(
            linkSent
                ? 'We sent a sign-in link to your email. Click the link to continue.'
                : 'Enter your email and we\'ll send you a magic link to sign in instantly',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.xl,

          // Email input
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Email address',
              hintText: 'you@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _getEmailError(emailTouched),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onTap: onEmailTouched,
            onChanged: (_) => onEmailTouched(),
            onSubmitted: (_) {
              if (!isLoading) {
                _sendLink(context);
              }
            },
          ),
          DsGap.xl,

          // Action button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : () => _sendLink(context),
              style: FilledButton.styleFrom(
                backgroundColor: DsColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      linkSent ? 'Resend link' : 'Send magic link',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          // Success message
          if (linkSent) ...[
            DsGap.xl,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Link sent! Check your inbox and spam folder.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _getEmailError(bool touched) {
    if (!touched) return null;
    final email = normalizeEmail(emailController.text);
    if (email.isEmpty) return 'Please enter your email address';
    if (!looksLikeEmail(email)) return 'Please enter a valid email address';
    return null;
  }

  void _sendLink(BuildContext context) {
    final error = _getEmailError(true);
    if (error != null) {
      showErrorSnackBar(context, error);
      return;
    }
    final email = normalizeEmail(emailController.text);
    context.read<AuthBloc>().add(AuthEmailLinkRequested(email));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMAIL + PASSWORD TAB
// ═══════════════════════════════════════════════════════════════════════════

class _EmailPasswordTab extends StatelessWidget {
  const _EmailPasswordTab({
    required this.emailController,
    required this.passwordController,
    required this.emailTouched,
    required this.passwordTouched,
    required this.obscurePassword,
    required this.onEmailTouched,
    required this.onPasswordTouched,
    required this.onToggleObscure,
    required this.state,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool emailTouched;
  final bool passwordTouched;
  final bool obscurePassword;
  final VoidCallback onEmailTouched;
  final VoidCallback onPasswordTouched;
  final VoidCallback onToggleObscure;
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = state.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Icon(
            Icons.lock_outline,
            size: 48,
            color: DsColors.primary,
          ),
          DsGap.lg,
          Text(
            'Sign in with password',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.sm,
          Text(
            'Enter your email and password to continue. New users will be registered automatically.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.xl,

          // Email input
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email address',
              hintText: 'you@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _getEmailError(emailTouched),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onTap: onEmailTouched,
            onChanged: (_) => onEmailTouched(),
          ),
          DsGap.md,

          // Password input
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: _getPasswordError(passwordTouched),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            onTap: onPasswordTouched,
            onChanged: (_) => onPasswordTouched(),
            onSubmitted: (_) {
              if (!isLoading) {
                _signIn(context);
              }
            },
          ),
          DsGap.xl,

          // Sign in button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : () => _signIn(context),
              style: FilledButton.styleFrom(
                backgroundColor: DsColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          DsGap.lg,

          // Forgot password
          Center(
            child: TextButton(
              onPressed:
                  isLoading ? null : () => context.push(CrushRoutes.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ),

          // Info text
          DsGap.lg,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'New to Crush? We\'ll create your account automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

  String? _getEmailError(bool touched) {
    if (!touched) return null;
    final email = normalizeEmail(emailController.text);
    if (email.isEmpty) return 'Please enter your email address';
    if (!looksLikeEmail(email)) return 'Please enter a valid email address';
    return null;
  }

  String? _getPasswordError(bool touched) {
    if (!touched) return null;
    final password = passwordController.text;
    if (password.isEmpty) return 'Please enter your password';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  void _signIn(BuildContext context) {
    final emailError = _getEmailError(true);
    final passwordError = _getPasswordError(true);
    if (emailError != null) {
      showErrorSnackBar(context, emailError);
      return;
    }
    if (passwordError != null) {
      showErrorSnackBar(context, passwordError);
      return;
    }
    final email = normalizeEmail(emailController.text);
    context.read<AuthBloc>().add(
          AuthEmailPasswordSubmitted(email, passwordController.text),
        );
  }
}
