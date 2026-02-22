import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        title: Text(AppLocalizations.of(context).signInWithEmail),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: DsColors.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
          indicatorColor: DsColors.primary,
          tabs: const [
            Tab(text: 'Email link'),
            Tab(text: 'Password'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: BlocConsumer<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.errorMessage != current.errorMessage,
              listener: (context, state) {
                if (state.status == AuthStatus.authenticated) {
                  _routeAfterAuth(context, state);
                } else if (state.status == AuthStatus.emailLinkSent &&
                    state.emailInProgress != null) {
                  showSuccessSnackBar(
                    context,
                    'Check your email! We sent a sign-in link to ${state.emailInProgress}',
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
                            onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            state: state,
                          ),
                        ],
                      ),
                    ),
                    // Bottom navigation to phone auth
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Semantics(
                          button: true,
                          label: 'Use phone number instead',
                          child: GlassSmallButton(
                            onPressed: state.isLoading
                                ? null
                                : () => context.go(CrushRoutes.phoneAuth),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).usePhoneNumberInstead,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _routeAfterAuth(BuildContext context, AuthState state) {
    final user = state.user;
    if (user == null) {
      context.go(CrushRoutes.home);
      return;
    }

    if (!user.hasAcceptedTerms) {
      context.go(CrushRoutes.termsConditions);
      return;
    }

    if (!user.hasCompletedBasicInfo) {
      context.go(CrushRoutes.basicInfo);
      return;
    }

    if (!user.hasCompletedProfileSetup) {
      context.go(CrushRoutes.profileSetup);
      return;
    }

    if (!user.isAccountVerified) {
      context.go(CrushRoutes.emailVerification);
      return;
    }

    context.go(CrushRoutes.home);
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
    final linkSent =
        state.status == AuthStatus.emailLinkSent &&
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
          Semantics(
            button: true,
            label: linkSent ? 'Resend link' : 'Send magic link',
            child: SizedBox(
              width: double.infinity,
              child: GlassPrimaryButton(
                onPressed: isLoading ? null : () => _sendLink(context),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DsColors.backgroundLight,
                          ),
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
          ),

          // Success message
          if (linkSent) ...[
            DsGap.xl,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DsColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DsColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: DsColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Link sent! Check your inbox and spam folder.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DsColors.success,
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
          const Icon(Icons.lock_outline, size: 48, color: DsColors.primary),
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
              suffixIcon: Semantics(
                button: true,
                label: obscurePassword ? 'Show password' : 'Hide password',
                child: Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: onToggleObscure,
                    child: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
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
          Semantics(
            button: true,
            label: 'Sign in',
            child: SizedBox(
              width: double.infinity,
              child: GlassPrimaryButton(
                onPressed: isLoading ? null : () => _signIn(context),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DsColors.backgroundLight,
                          ),
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
          ),
          DsGap.lg,

          // Forgot password
          Center(
            child: Semantics(
              button: true,
              label: 'Forgot password',
              child: GlassSmallButton(
                onPressed: isLoading
                    ? null
                    : () => context.push(CrushRoutes.forgotPassword),
                child: Text(AppLocalizations.of(context).forgotPassword),
              ),
            ),
          ),

          // Info text
          DsGap.lg,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
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
