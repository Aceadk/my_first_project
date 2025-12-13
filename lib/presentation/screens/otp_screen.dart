import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../core/router.dart';
import '../widgets/primary_button.dart';
import '../../core/ui/snackbar_utils.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentPhone =
        context.select<AuthBloc, String?>((bloc) => bloc.state.phoneInProgress) ??
            widget.phoneNumber;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              Navigator.pushReplacementNamed(context, CrushRoutes.basicInfo);
            }
            final error = state.errorMessage;
            if (error != null && error.isNotEmpty) {
              showErrorSnackBar(context, error);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Text('OTP sent to $currentPhone'),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Enter OTP'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Verify',
                  loading: state.isLoading,
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthOtpSubmitted(
                          currentPhone,
                          _otpController.text.trim(),
                        ));
                  },
                ),
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () => context
                          .read<AuthBloc>()
                          .add(AuthOtpResendRequested(currentPhone)),
                  child: const Text('Resend code'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
