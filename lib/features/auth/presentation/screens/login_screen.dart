import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:crushhour/features/auth/presentation/widgets/google_logo_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _obscurePassword = true;
  String? _identifierError;
  String? _passwordError;

  AuthFlowUseCases _authFlowUseCases() {
    return AuthFlowUseCases(context.read<AuthRepository>());
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authFlowUseCases = _authFlowUseCases();
    final supportsUsernameLogin = authFlowUseCases.supportsUsernameLogin;
    final showGoogleButton = authFlowUseCases.supportsGoogleSignIn;
    final showAppleButton =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        authFlowUseCases.supportsAppleSignIn;

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
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
              ),
              child: SafeArea(
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
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
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
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
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        DsGap.sm,
                        Text(
                          context.l10n.authSignInToContinue,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
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
                          onChanged: (_) =>
                              setState(() => _identifierError = null),
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
                          suffixSemanticLabel: _obscurePassword
                              ? context.l10n.a11yShowPassword
                              : context.l10n.a11yHidePassword,
                          onSuffixTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onChanged: (_) =>
                              setState(() => _passwordError = null),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        DsGap.md,
                        // Forgot password link
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Semantics(
                            button: true,
                            label: context.l10n.authForgotPassword,
                            child: GlassSmallButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.push(
                                      CrushRoutes.forgotPassword,
                                    ),
                              child: Text(context.l10n.authForgotPassword),
                            ),
                          ),
                        ),
                        DsGap.xl,
                        // Login button
                        Semantics(
                          button: true,
                          label: context.l10n.authSignIn,
                          child: SizedBox(
                            width: double.infinity,
                            child: GlassPrimaryButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: DsColors.backgroundLight,
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
                        ),
                        DsGap.xxl,
                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: DsEdgeInsets.horizontalLg,
                              child: Text(
                                context.l10n.wordOr,
                                style: TextStyle(
                                  color: isDark
                                      ? DsColors.textMutedDark
                                      : DsColors.textMutedLight,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        DsGap.xxl,
                        if (showGoogleButton) ...[
                          Semantics(
                            button: true,
                            label: context.l10n.authContinueWithGoogle,
                            child: SizedBox(
                              width: double.infinity,
                              child: GlassOutlinedButton(
                                onPressed: _isGoogleLoading
                                    ? null
                                    : _signInWithGoogle,
                                backgroundColor: Colors.white,
                                borderColor: const Color(0xFFDADCE0),
                                isExpanded: true,
                                isLoading: _isGoogleLoading,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const GoogleLogoIcon(size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.l10n.authContinueWithGoogle,
                                      style: const TextStyle(
                                        color: Color(0xFF1F1F1F),
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
                        ],
                        if (showAppleButton) ...[
                          Semantics(
                            button: true,
                            label: context.l10n.authContinueWithApple,
                            child: SizedBox(
                              width: double.infinity,
                              child: GlassOutlinedButton(
                                onPressed: _isAppleLoading
                                    ? null
                                    : _signInWithApple,
                                backgroundColor: Colors.black,
                                borderColor: Colors.black,
                                isExpanded: true,
                                isLoading: _isAppleLoading,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.apple,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      context.l10n.authContinueWithApple,
                                      style: const TextStyle(
                                        color: Colors.white,
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
                        ],
                        // Create account button with gradient border
                        Semantics(
                          button: true,
                          label: context.l10n.authCreateAccount,
                          child: SizedBox(
                            width: double.infinity,
                            child: GlassOutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.push(CrushRoutes.signUp),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.person_add_alt_1_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.l10n.authCreateAccount,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DsGap.xl,
                        // Dev mode indicator - tap to auto-fill admin123 credentials
                        if (!kReleaseMode)
                          Semantics(
                            button: true,
                            label: 'Fill test credentials',
                            child: GestureDetector(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Development Build',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: DsColors.info,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            'Tap to fill test credentials',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: DsColors.info
                                                      .withValues(alpha: 0.7),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.touch_app_outlined,
                                      color: DsColors.info.withValues(
                                        alpha: 0.6,
                                      ),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateIdentifier({required bool supportsUsernameLogin}) {
    final l10n = context.l10n;
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      return supportsUsernameLogin
          ? l10n.authEnterEmailOrUsername
          : l10n.authEnterEmailAddress;
    }
    if (!supportsUsernameLogin) {
      if (!looksLikeEmail(identifier)) {
        return l10n.errorInvalidEmail;
      }
      return null;
    }
    if (identifier.contains('@')) {
      if (!looksLikeEmail(identifier)) {
        return l10n.errorInvalidEmail;
      }
      return null;
    }
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(identifier);
    if (!valid) {
      return l10n.authUsernameMustBe320;
    }
    return null;
  }

  String? _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return context.l10n.authEnterYourPassword;
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final authFlowUseCases = _authFlowUseCases();
    final supportsUsernameLogin = authFlowUseCases.supportsUsernameLogin;
    final identifierError = _validateIdentifier(
      supportsUsernameLogin: supportsUsernameLogin,
    );
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

    final result = await authFlowUseCases.loginWithPassword(
      identifier: identifier,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      showErrorSnackBar(context, result.errorMessage ?? l10n.errorLoginFailed);
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

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;

    final l10n = context.l10n;
    setState(() => _isGoogleLoading = true);
    final result = await _authFlowUseCases().signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (!result.isSuccess) {
      showErrorSnackBar(
        context,
        result.errorMessage ?? l10n.onboardingSignUpGoogleSignInFailed,
      );
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

  Future<void> _signInWithApple() async {
    if (_isAppleLoading) return;

    final l10n = context.l10n;
    setState(() => _isAppleLoading = true);
    final result = await _authFlowUseCases().signInWithApple();

    if (!mounted) return;
    setState(() => _isAppleLoading = false);

    if (!result.isSuccess) {
      showErrorSnackBar(
        context,
        result.errorMessage ?? l10n.authAppleSignInFailed,
      );
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
