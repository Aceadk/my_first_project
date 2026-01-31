import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

/// A modal bottom sheet for single selection from a list of options.
class ProfileSingleSelectSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T? selectedValue;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final String Function(T)? emojiBuilder;
  final ValueChanged<T?> onSelected;
  final bool allowClear;

  const ProfileSingleSelectSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.labelBuilder,
    this.subtitleBuilder,
    this.emojiBuilder,
    required this.onSelected,
    this.allowClear = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required T? selectedValue,
    required String Function(T) labelBuilder,
    String Function(T)? subtitleBuilder,
    String Function(T)? emojiBuilder,
    bool allowClear = true,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileSingleSelectSheet<T>(
        title: title,
        options: options,
        selectedValue: selectedValue,
        labelBuilder: labelBuilder,
        subtitleBuilder: subtitleBuilder,
        emojiBuilder: emojiBuilder,
        onSelected: (value) => Navigator.of(context).pop(value),
        allowClear: allowClear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? DsColors.surfaceDark : DsColors.surfaceLight;
    final textPrimary =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;
    final textMuted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    final dividerColor = isDark ? DsColors.dividerDark : DsColors.dividerLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (allowClear && selectedValue != null)
                  TextButton(
                    onPressed: () => onSelected(null),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: DsColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),
          // Options list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + DsSpacing.lg,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selectedValue;
                final emoji = emojiBuilder?.call(option);
                final subtitle = subtitleBuilder?.call(option);

                return InkWell(
                  onTap: () => onSelected(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.lg,
                      vertical: DsSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DsColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        if (emoji != null) ...[
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: DsSpacing.md),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                labelBuilder(option),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: DsColors.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
