import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isRequired;
  final String? semanticLabel;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.prefixIcon,
    this.suffixIcon,
    this.isRequired = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Build semantic description
    final List<String> semanticParts = [];
    if (semanticLabel != null) {
      semanticParts.add(semanticLabel!);
    } else if (label != null) {
      semanticParts.add(label!);
    }
    if (isRequired) {
      semanticParts.add('required');
    }
    if (obscureText) {
      semanticParts.add('password field');
    }
    if (errorText != null) {
      semanticParts.add('Error: $errorText');
    }

    return Semantics(
      textField: true,
      label: semanticParts.isNotEmpty ? semanticParts.join(', ') : null,
      enabled: enabled,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        enabled: enabled,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofillHints: autofillHints,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
