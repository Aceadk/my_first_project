import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../core/router.dart';
import '../widgets/primary_button.dart';
import '../../core/ui/snackbar_utils.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  bool _touched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up with phone')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.otpSent &&
                state.phoneInProgress != null) {
              Navigator.pushNamed(
                context,
                CrushRoutes.otp,
                arguments: state.phoneInProgress!,
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
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone number (with country code)',
                    errorText: _touched && _phoneController.text.trim().isEmpty
                        ? 'Enter your phone number'
                        : null,
                  ),
                  onChanged: (_) {
                    if (!_touched) {
                      setState(() => _touched = true);
                    }
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Send OTP',
                  loading: state.isLoading,
                  onPressed: () {
                    final phone = _phoneController.text.trim();
                    setState(() => _touched = true);
                    if (phone.isEmpty) {
                      showErrorSnackBar(
                        context,
                        'Enter your phone number to continue.',
                      );
                      return;
                    }
                    context.read<AuthBloc>().add(AuthPhoneSubmitted(phone));
                  },
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
