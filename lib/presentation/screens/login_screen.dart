import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/result.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../core/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../design_system/widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _identifierTouched = false;
  bool _passwordTouched = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Login',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Username or email',
              errorText: _identifierErrorText(),
            ),
            onTap: () => _markIdentifierTouched(),
            onChanged: (_) => _markIdentifierTouched(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _passwordErrorText(),
            ),
            onTap: () => _markPasswordTouched(),
            onChanged: (_) => _markPasswordTouched(),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Login',
            loading: _isLoading,
            onPressed: _isLoading ? null : _submit,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => context.push(CrushRoutes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => context.push(CrushRoutes.signUp),
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }

  void _markIdentifierTouched() {
    if (!_identifierTouched) {
      setState(() {
        _identifierTouched = true;
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
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(identifier);
    if (!valid) {
      return 'Use 3-20 letters, numbers, or underscore';
    }
    return null;
  }

  String? _passwordErrorText() {
    if (!_passwordTouched) return null;
    final password = _passwordController.text;
    if (password.isEmpty) {
      return 'Enter your password';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _identifierTouched = true;
      _passwordTouched = true;
    });
    final identifierError = _identifierErrorText();
    final passwordError = _passwordErrorText();
    if (identifierError != null || passwordError != null) {
      showErrorSnackBar(context, identifierError ?? passwordError!);
      return;
    }
    FocusScope.of(context).unfocus();
    final rawIdentifier = _identifierController.text.trim();
    final identifier = rawIdentifier.contains('@')
        ? normalizeEmail(rawIdentifier)
        : rawIdentifier;
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().loginWithPassword(
            identifier: identifier,
            password: _passwordController.text,
          ),
      logLabel: 'AuthRepository.loginWithPassword',
      fallbackError: 'Invalid credentials. Please try again.',
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
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
