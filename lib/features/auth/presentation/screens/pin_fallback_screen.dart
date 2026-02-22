import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/features/auth/presentation/bloc/biometric_cubit.dart';

/// PIN entry screen used as fallback when biometric authentication fails.
///
/// Supports two modes:
/// - **Setup mode**: User creates a new PIN (enters twice to confirm).
/// - **Verify mode**: User enters existing PIN to unlock.
class PinFallbackScreen extends StatefulWidget {
  const PinFallbackScreen({
    super.key,
    required this.isSetup,
    this.onAuthenticated,
    this.onLocked,
  });

  /// Whether this is a PIN setup flow (true) or verification flow (false).
  final bool isSetup;

  /// Called when authentication succeeds.
  final VoidCallback? onAuthenticated;

  /// Called when too many failed attempts lock the user out.
  final VoidCallback? onLocked;

  @override
  State<PinFallbackScreen> createState() => _PinFallbackScreenState();
}

class _PinFallbackScreenState extends State<PinFallbackScreen> {
  static const int _pinLength = 6;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _firstPin; // Used during setup to hold first entry
  String? _errorMessage;
  bool _isConfirming = false; // Setup: confirming second entry

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.isSetup) {
      return _isConfirming ? 'Confirm your PIN' : 'Create a PIN';
    }
    return 'Enter your PIN';
  }

  String get _subtitle {
    if (widget.isSetup) {
      return _isConfirming
          ? 'Enter the same PIN again to confirm'
          : 'This PIN will be used as a backup to unlock the app';
    }
    return 'Enter your PIN to unlock Crush';
  }

  void _onPinComplete(String pin) {
    if (widget.isSetup) {
      _handleSetup(pin);
    } else {
      _handleVerify(pin);
    }
  }

  void _handleSetup(String pin) {
    if (!_isConfirming) {
      setState(() {
        _firstPin = pin;
        _isConfirming = true;
        _errorMessage = null;
        _controller.clear();
      });
      _focusNode.requestFocus();
      return;
    }

    if (pin == _firstPin) {
      context.read<BiometricCubit>().setupPin(pin);
      widget.onAuthenticated?.call();
    } else {
      setState(() {
        _firstPin = null;
        _isConfirming = false;
        _errorMessage = 'PINs do not match. Please try again.';
        _controller.clear();
      });
      _focusNode.requestFocus();
    }
  }

  void _handleVerify(String pin) {
    final cubit = context.read<BiometricCubit>();
    cubit.verifyPin(pin);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<BiometricCubit, BiometricState>(
      listener: (context, state) {
        if (state.status == BiometricStatus.authenticated) {
          widget.onAuthenticated?.call();
        } else if (state.status == BiometricStatus.locked) {
          widget.onLocked?.call();
        } else if (state.errorMessage != null) {
          setState(() => _errorMessage = state.errorMessage);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DsSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isSetup ? Icons.lock_outline : Icons.lock,
                  size: 64,
                  color: DsColors.primary,
                ),
                const SizedBox(height: DsSpacing.lg),
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? DsColors.textPrimaryDark
                        : DsColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                Text(
                  _subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DsSpacing.xxl),
                // PIN dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final filled = index < _controller.text.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? DsColors.primary
                            : (isDark
                                  ? DsColors.surfaceLight.withValues(
                                      alpha: 0.15,
                                    )
                                  : DsColors.ink900.withValues(alpha: 0.1)),
                        border: Border.all(
                          color: DsColors.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: DsSpacing.lg),
                // Hidden text field for keyboard input
                SizedBox(
                  width: 0,
                  height: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: _pinLength,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      if (value.length == _pinLength) {
                        _onPinComplete(value);
                      }
                    },
                  ),
                ),
                // Tap to focus the keyboard
                Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    child: Text(
                      'Tap here to show keyboard',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: DsSpacing.lg),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 14, color: DsColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
