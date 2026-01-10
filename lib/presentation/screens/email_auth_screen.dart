import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../core/validators.dart';
import '../widgets/onboarding_progress.dart';
import '../widgets/onboarding_nav_buttons.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _submitted = false;
  bool _identifierTouched = false;
  bool _otpTouched = false;
  bool _otpSubmitted = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _identifierController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign in with email'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Email OTP'),
              Tab(text: 'Email link'),
              Tab(text: 'Email + password'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.errorMessage != current.errorMessage,
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
                context.go(CrushRoutes.basicInfo);
              } else if (state.status == AuthStatus.emailLinkSent &&
                  state.emailInProgress != null) {
                showSuccessSnackBar(
                  context,
                  'Email link sent to ${state.emailInProgress}.',
                );
              } else if (state.status == AuthStatus.emailOtpSent &&
                  state.emailOtpIdentifier != null) {
                showSuccessSnackBar(
                  context,
                  'If an account exists, we sent a code to the email on file.',
                );
              }
              final error = state.errorMessage;
              if (error != null && error.isNotEmpty) {
                showErrorSnackBar(context, error);
              }
            },
            builder: (context, state) {
              final isLoading = state.isLoading;
              return AbsorbPointer(
                absorbing: isLoading,
                child: Column(
                  children: [
                    const OnboardingProgress(
                      currentStep: 1,
                      caption: 'Choose an email sign-in method',
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildEmailOtpTab(state),
                          _buildEmailLinkTab(state),
                          _buildEmailPasswordTab(state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go(CrushRoutes.phoneAuth),
                      child: const Text('Use phone instead'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmailOtpTab(AuthState state) {
    final rawIdentifier = _identifierController.text.trim();
    final identifier = rawIdentifier.contains('@')
        ? normalizeEmail(rawIdentifier)
        : rawIdentifier;
    final storedIdentifier = state.emailOtpIdentifier;
    final effectiveIdentifier =
        (storedIdentifier != null && storedIdentifier.isNotEmpty)
            ? storedIdentifier
            : identifier;
    final otpSent = state.status == AuthStatus.emailOtpSent;

    return Column(
      children: [
        TextField(
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Username or email',
            helperText: 'We will send a 6-digit code to the email on file.',
            errorText: _identifierErrorText(),
          ),
          onTap: () => _markIdentifierTouched(),
          onChanged: (_) => _markIdentifierTouched(),
        ),
        if (otpSent) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter code',
              helperText: 'Enter the 6-digit code from your email.',
              errorText: _otpErrorText(),
            ),
            onTap: () => _markOtpTouched(),
            onChanged: (_) => _markOtpTouched(),
          ),
        ],
        const SizedBox(height: 16),
        OnboardingNavButtons(
          showBack: false,
          nextLabel: otpSent ? 'Verify code' : 'Send code',
          onNext: () {
            setState(() {
              _identifierTouched = true;
              _otpSubmitted = otpSent;
              if (otpSent) {
                _otpTouched = true;
              }
            });
            final identifierError = _identifierErrorText();
            if (identifierError != null) {
              showErrorSnackBar(context, identifierError);
              return;
            }
            if (otpSent) {
              final otpError = _otpErrorText();
              if (otpError != null) {
                showErrorSnackBar(context, otpError);
                return;
              }
              context.read<AuthBloc>().add(
                    AuthEmailOtpSubmitted(
                      effectiveIdentifier,
                      _otpController.text.trim(),
                    ),
                  );
              return;
            }
            context
                .read<AuthBloc>()
                .add(AuthEmailOtpRequested(identifier));
          },
          nextLoading: state.isLoading,
        ),
        if (otpSent) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () => context.read<AuthBloc>().add(
                          AuthEmailOtpResendRequested(effectiveIdentifier),
                        ),
                child: const Text('Resend code'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        _otpController.clear();
                        setState(() {
                          _otpTouched = false;
                          _otpSubmitted = false;
                        });
                        context.read<AuthBloc>().add(AuthEmailOtpCancelled());
                      },
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.isLoading
                ? null
                : () => context.go(CrushRoutes.home),
            child: const Text('Skip for now'),
          ),
        ],
      ],
    );
  }

  Widget _buildEmailLinkTab(AuthState state) {
    final email = normalizeEmail(_emailController.text);
    final linkSent = state.status == AuthStatus.emailLinkSent &&
        (state.emailInProgress?.isNotEmpty ?? false);

    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email address',
            helperText: 'We will email you a sign-in link.',
            errorText: _emailErrorText(),
          ),
          onTap: () => _markEmailTouched(),
          onChanged: (_) => _markEmailTouched(),
        ),
        const SizedBox(height: 16),
        OnboardingNavButtons(
          showBack: false,
          nextLabel: 'Send link',
          onNext: () {
            setState(() {
              _submitted = true;
              _emailTouched = true;
            });
            final emailError = _emailErrorText();
            if (emailError != null) {
              showErrorSnackBar(context, emailError);
              return;
            }
            context
                .read<AuthBloc>()
                .add(AuthEmailLinkRequested(email));
          },
          nextLoading: state.isLoading,
        ),
        if (linkSent) ...[
          const SizedBox(height: 12),
          Text(
            'Check your inbox and open the link to finish signing in.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildEmailPasswordTab(AuthState state) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email address',
            errorText: _emailErrorText(),
          ),
          onTap: () => _markEmailTouched(),
          onChanged: (_) => _markEmailTouched(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            helperText: 'We will create an account if you are new.',
            errorText: _passwordErrorText(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          onTap: () => _markPasswordTouched(),
          onChanged: (_) => _markPasswordTouched(),
        ),
        const SizedBox(height: 16),
        OnboardingNavButtons(
          showBack: false,
          nextLabel: 'Continue',
          onNext: () {
            setState(() {
              _submitted = true;
              _emailTouched = true;
              _passwordTouched = true;
            });
            final emailError = _emailErrorText();
            final passwordError = _passwordErrorText();
            if (emailError != null || passwordError != null) {
              showErrorSnackBar(context, emailError ?? passwordError!);
              return;
            }
            context.read<AuthBloc>().add(
                  AuthEmailPasswordSubmitted(
                    normalizeEmail(_emailController.text),
                    _passwordController.text,
                  ),
                );
          },
          nextLoading: state.isLoading,
        ),
        const SizedBox(height: 8),
        TextButton(
            onPressed: state.isLoading
                ? null
                : () => context.push(CrushRoutes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
      ],
    );
  }

  void _markEmailTouched() {
    if (!_emailTouched) {
      setState(() {
        _emailTouched = true;
      });
    }
  }

  void _markPasswordTouched() {
    if (!_passwordTouched) {
      setState(() {
        _passwordTouched = true;
      });
    }
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
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      return 'Enter your username or email';
    }
    if (identifier.contains('@')) {
      if (!looksLikeEmail(identifier)) {
        return 'Enter a valid email address';
      }
      return null;
    }
    final valid =
        RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(identifier);
    if (!valid) {
      return 'Use 3-20 letters, numbers, or underscore';
    }
    return null;
  }

  String? _otpErrorText() {
    if (!_otpTouched && !_otpSubmitted) return null;
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      return 'Enter the 6-digit code';
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return 'Use the 6-digit code from your email';
    }
    return null;
  }

  String? _emailErrorText() {
    if (!_emailTouched && !_submitted) return null;
    final email = normalizeEmail(_emailController.text);
    if (email.isEmpty) {
      return 'Enter your email address';
    }
    if (!looksLikeEmail(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _passwordErrorText() {
    if (!_passwordTouched && !_submitted) return null;
    final password = _passwordController.text;
    if (password.isEmpty) {
      return 'Enter your password';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

}
