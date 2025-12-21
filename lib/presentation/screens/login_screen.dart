import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/result.dart';
import '../../core/router.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../data/repositories/auth_repository.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ListView(
        padding: const EdgeInsets.all(24),
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
                : () => Navigator.pushNamed(
                      context,
                      CrushRoutes.forgotPassword,
                    ),
            child: const Text('Forgot password?'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamed(
                      context,
                      CrushRoutes.signUp,
                    ),
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
      if (!_looksLikeEmail(identifier)) {
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

  bool _looksLikeEmail(String email) =>
      RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$').hasMatch(email);

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
    setState(() {
      _isLoading = true;
    });
    final result = await Result.guard(
      () => context.read<AuthRepository>().loginWithPassword(
            identifier: _identifierController.text.trim(),
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
      Navigator.pushReplacementNamed(
        context,
        CrushRoutes.emailProtection,
        arguments: true,
      );
      return;
    }
    Navigator.pushReplacementNamed(context, CrushRoutes.home);
  }
}
