import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/validators.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supportsUsernameLogin =
        context.read<AuthRepository>().supportsUsernameLogin;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        // Handle dev bypass errors
        if (state.status == AuthStatus.unauthenticated &&
            state.errorMessage != null &&
            state.errorMessage!.isNotEmpty) {
          setState(() => _isLoading = false);
          showErrorSnackBar(context, state.errorMessage!);
        }
        // Handle successful authentication (router will redirect)
        if (state.status == AuthStatus.authenticated) {
          setState(() => _isLoading = false);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: DsEdgeInsets.allXxl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header - centered
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DsColors.primary, DsColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: DsColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              DsGap.xxl,
              Text(
                context.l10n.authWelcomeBack,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              DsGap.sm,
              Text(
                context.l10n.authSignInToContinue,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ),
              DsGap.xxxl,
              // Email/Username field
              GlassTextField(
                controller: _identifierController,
                label: supportsUsernameLogin
                    ? context.l10n.authEmailOrUsername
                    : context.l10n.authEmail,
                hintText: 'you@example.com',
                prefixIcon: supportsUsernameLogin
                    ? Icons.person_outline
                    : Icons.email_outlined,
                errorText: _identifierError,
                enabled: !_isLoading,
                keyboardType: supportsUsernameLogin
                    ? TextInputType.text
                    : TextInputType.emailAddress,
                onChanged: (_) => setState(() => _identifierError = null),
                textInputAction: TextInputAction.next,
              ),
              DsGap.lg,
              // Password field
              GlassTextField(
                controller: _passwordController,
                label: context.l10n.authPassword,
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
                errorText: _passwordError,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                suffixIcon: _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                onChanged: (_) => setState(() => _passwordError = null),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              DsGap.md,
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.push(CrushRoutes.forgotPassword),
                  child: Text(
                    context.l10n.authForgotPassword,
                    style: const TextStyle(color: DsColors.primary),
                  ),
                ),
              ),
              DsGap.xl,
              // Login button
              SizedBox(
                width: double.infinity,
                child: GlassPrimaryButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.authSignIn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              DsGap.xxl,
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: DsEdgeInsets.horizontalLg,
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              DsGap.xxl,
              // Create account button with gradient border
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DsColors.primary, DsColors.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(2),
                child: Material(
                  color: isDark ? DsColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _isLoading ? null : () => context.push(CrushRoutes.signUp),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [DsColors.primary, DsColors.secondary],
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.person_add_alt_1_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [DsColors.primary, DsColors.secondary],
                            ).createShader(bounds),
                            child: Text(
                              context.l10n.authCreateAccount,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              DsGap.xl,
              // Dev mode indicator - tap to auto-fill admin123 credentials
              if (!kReleaseMode)
                GestureDetector(
                  onTap: () {
                    _identifierController.text = 'admin123';
                    _passwordController.text = 'admin123';
                    setState(() {
                      _identifierError = null;
                      _passwordError = null;
                    });
                  },
                  child: Container(
                    padding: DsEdgeInsets.allMd,
                    decoration: BoxDecoration(
                      color: DsColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DsColors.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.developer_mode,
                          color: DsColors.info,
                          size: 20,
                        ),
                        DsGap.mdH,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Development Build',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: DsColors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Tap to fill test credentials',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: DsColors.info.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.touch_app_outlined,
                          color: DsColors.info.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  String? _validateIdentifier({required bool supportsUsernameLogin}) {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      return supportsUsernameLogin
          ? 'Please enter your email or username'
          : 'Please enter your email address';
    }
    if (!supportsUsernameLogin) {
      if (!looksLikeEmail(identifier)) {
        return 'Please enter a valid email address';
      }
      return null;
    }
    if (identifier.contains('@')) {
      if (!looksLikeEmail(identifier)) {
        return 'Please enter a valid email address';
      }
      return null;
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(identifier);
    if (!valid) {
      return 'Username must be 3-20 characters';
    }
    return null;
  }

  String? _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> _submit() async {
    final supportsUsernameLogin =
        context.read<AuthRepository>().supportsUsernameLogin;
    final identifierError =
        _validateIdentifier(supportsUsernameLogin: supportsUsernameLogin);
    final passwordError = _validatePassword();

    setState(() {
      _identifierError = identifierError;
      _passwordError = passwordError;
    });

    if (identifierError != null || passwordError != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    final rawIdentifier = _identifierController.text.trim();
    final identifier = supportsUsernameLogin
        ? (rawIdentifier.contains('@')
            ? normalizeEmail(rawIdentifier)
            : rawIdentifier)
        : normalizeEmail(rawIdentifier);

    setState(() => _isLoading = true);

    // Try dev admin bypass first (only in debug mode with admin123 credentials)
    if (!kReleaseMode &&
        identifier == 'admin123' &&
        _passwordController.text == 'admin123') {
      context.read<AuthBloc>().add(
            AuthDevBypassRequested(identifier, _passwordController.text),
          );
      // The router will handle navigation when auth state changes
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final authRepo = context.read<AuthRepository>();
    final result = await Result.guard(
      () => authRepo.loginWithPassword(
            identifier: identifier,
            password: _passwordController.text,
          ),
      logLabel: 'AuthRepository.loginWithPassword',
      fallbackError: 'Invalid credentials. Please try again.',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? 'Login failed.');
      return;
    }

    final user = result.data;
    if (user?.email != null &&
        user!.email!.isNotEmpty &&
        !user.isEmailVerified) {
      context.go('${CrushRoutes.emailProtection}?redirect=1');
      return;
    }
    context.go(CrushRoutes.home);
  }
}
