import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../theme/theme_extensions.dart';

/// A glassmorphism-styled text field with frosted background.
///
/// Features:
/// - Frosted glass background
/// - Gradient border on focus
/// - Floating label animation
/// - Theme-aware styling
///
/// Example:
/// ```dart
/// GlassTextField(
///   controller: _controller,
///   label: 'Email',
///   hintText: 'Enter your email',
///   prefixIcon: Icons.email_outlined,
/// )
/// ```
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.blur = DsBlur.light,
    this.borderRadius = DsRadius.input,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final double blur;
  final double borderRadius;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final theme = Theme.of(context);
    final effects = theme.extension<CrushThemeEffects>();
    final motionScale = effects?.motionScale ?? 1.0;
    final glowColor = effects?.glowColor ?? DsColors.primary;
    final shadowOpacity = effects?.shadowOpacity ?? 0.15;

    final bgColor = DsGlassColors.surfaceFor(context);

    final borderColor = widget.errorText != null
        ? DsColors.error
        : _isFocused
            ? DsColors.primary
            : DsGlassColors.borderFor(context);

    final textColor =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    final hintColor =
        isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    final labelColor = _isFocused
        ? DsColors.primary
        : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: (200 * motionScale).round()),
            style: theme.textTheme.labelMedium!.copyWith(
              color: labelColor,
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(widget.label!),
          ),
          const SizedBox(height: DsSpacing.xs),
        ],

        // Input field with glass effect
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blur,
              sigmaY: widget.blur,
            ),
            child: AnimatedContainer(
              duration: Duration(milliseconds: (200 * motionScale).round()),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 2 : 1.5,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: shadowOpacity),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onSubmitted: widget.onSubmitted,
                onChanged: widget.onChanged,
                autofillHints: widget.autofillHints,
                inputFormatters: widget.inputFormatters,
                textCapitalization: widget.textCapitalization,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                autofocus: widget.autofocus,
                style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
                cursorColor: DsColors.primary,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle:
                      theme.textTheme.bodyLarge?.copyWith(color: hintColor),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(widget.prefixIcon, color: hintColor, size: 22)
                      : null,
                  suffixIcon: widget.suffixIcon != null
                      ? GestureDetector(
                          onTap: widget.onSuffixTap,
                          child:
                              Icon(widget.suffixIcon, color: hintColor, size: 22),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.lg,
                    vertical: DsSpacing.md,
                  ),
                  counterText: '',
                ),
              ),
            ),
          ),
        ),

        // Error or helper text
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: DsSpacing.xs),
          Text(
            widget.errorText ?? widget.helperText ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: widget.errorText != null ? DsColors.error : hintColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// A search input with glass styling.
class GlassSearchField extends StatelessWidget {
  const GlassSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.blur = DsBlur.light,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor = DsGlassColors.surfaceFor(context);

    final borderColor = DsGlassColors.borderFor(context);

    final textColor =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    final hintColor =
        isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.round),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(DsRadius.round),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            autofocus: autofocus,
            style: TextStyle(color: textColor),
            cursorColor: DsColors.primary,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(Icons.search, color: hintColor, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.lg,
                vertical: DsSpacing.md,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
