import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool autofocus;
  final int length;

  const OtpInput({
    super.key,
    this.controller,
    this.label,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = false,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Build semantic label
    final List<String> semanticParts = [
      label ?? 'Verification code',
      '$length digit code',
    ];
    if (errorText != null) {
      semanticParts.add('Error: $errorText');
    }

    return Semantics(
      textField: true,
      label: semanticParts.join(', '),
      hint: 'Enter $length digit verification code',
      enabled: enabled,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        enabled: enabled,
        autofocus: autofocus,
        maxLength: length,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(letterSpacing: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          errorText: errorText,
          counterText: '',
        ),
        onChanged: (value) {
          onChanged?.call(value);
          if (value.length == length) {
            onCompleted?.call(value);
          }
        },
      ),
    );
  }
}
