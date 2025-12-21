import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
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
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign in with email'),
          bottom: const TabBar(
            tabs: [
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
                Navigator.pushReplacementNamed(
                  context,
                  CrushRoutes.basicInfo,
                );
              } else if (state.status == AuthStatus.emailLinkSent &&
                  state.emailInProgress != null) {
                showSuccessSnackBar(
                  context,
                  'Email link sent to ${state.emailInProgress}.',
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
                          _buildEmailLinkTab(state),
                          _buildEmailPasswordTab(state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                                context,
                                CrushRoutes.phoneAuth,
                              ),
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

  Widget _buildEmailLinkTab(AuthState state) {
    final email = _emailController.text.trim();
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
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            helperText: 'We will create an account if you are new.',
            errorText: _passwordErrorText(),
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
                    _emailController.text.trim(),
                    _passwordController.text,
                  ),
                );
          },
          nextLoading: state.isLoading,
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

  String? _emailErrorText() {
    if (!_emailTouched && !_submitted) return null;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      return 'Enter your email address';
    }
    if (!_looksLikeEmail(email)) {
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
    if (password.length < 6) {
      return 'Use at least 6 characters';
    }
    return null;
  }

  bool _looksLikeEmail(String email) =>
      RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$').hasMatch(email);
}
