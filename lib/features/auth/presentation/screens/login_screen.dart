import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/utils/validators.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: DsEdgeInsets.allXxl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DsColors.primary, DsColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: DsColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              DsGap.xxl,
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              DsGap.sm,
              Text(
                'Sign in to continue to Crush',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ),
              DsGap.xxxl,
              // Email/Username field
              GlassTextField(
                controller: _identifierController,
                label: 'Email or username',
                hintText: 'you@example.com',
                prefixIcon: Icons.person_outline,
                errorText: _identifierError,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _identifierError = null),
                textInputAction: TextInputAction.next,
              ),
              DsGap.lg,
              // Password field
              GlassTextField(
                controller: _passwordController,
                label: 'Password',
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
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: DsColors.primary),
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
                      : const Text(
                          'Sign In',
                          style: TextStyle(
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
              // Create account button
              SizedBox(
                width: double.infinity,
                child: GlassOutlinedButton(
                  onPressed: _isLoading ? null : () => context.push(CrushRoutes.signUp),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DsGap.lg,
              // Alternative login methods
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading ? null : () => context.push(CrushRoutes.phoneAuth),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('Phone'),
                  ),
                  Text(
                    '  |  ',
                    style: TextStyle(
                      color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLoading ? null : () => context.push(CrushRoutes.emailAuth),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Email OTP'),
                  ),
                ],
              ),
              DsGap.xl,
              // Dev mode indicator (credentials not shown for security)
              if (!kReleaseMode)
                Container(
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
                        child: Text(
                          'Development build',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DsColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateIdentifier() {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      return 'Please enter your email or username';
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
    final identifierError = _validateIdentifier();
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
    final identifier = rawIdentifier.contains('@')
        ? normalizeEmail(rawIdentifier)
        : rawIdentifier;

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
