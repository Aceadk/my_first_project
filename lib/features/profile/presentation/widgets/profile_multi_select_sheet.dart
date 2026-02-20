import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

/// A modal bottom sheet for multi-selection with chips.
class ProfileMultiSelectSheet<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final List<T> selectedValues;
  final String Function(T) labelBuilder;
  final String Function(T)? emojiBuilder;
  final int? maxSelections;
  final ValueChanged<List<T>> onSelected;

  const ProfileMultiSelectSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.labelBuilder,
    this.emojiBuilder,
    this.maxSelections,
    required this.onSelected,
  });

  static Future<List<T>?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required List<T> selectedValues,
    required String Function(T) labelBuilder,
    String Function(T)? emojiBuilder,
    int? maxSelections,
  }) async {
    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileMultiSelectSheet<T>(
        title: title,
        options: options,
        selectedValues: selectedValues,
        labelBuilder: labelBuilder,
        emojiBuilder: emojiBuilder,
        maxSelections: maxSelections,
        onSelected: (values) => Navigator.of(context).pop(values),
      ),
    );
  }

  @override
  State<ProfileMultiSelectSheet<T>> createState() =>
      _ProfileMultiSelectSheetState<T>();
}

class _ProfileMultiSelectSheetState<T>
    extends State<ProfileMultiSelectSheet<T>> {
  late List<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedValues);
  }

  void _toggleOption(T option) {
    setState(() {
      if (_selected.contains(option)) {
        _selected.remove(option);
      } else {
        if (widget.maxSelections != null &&
            _selected.length >= widget.maxSelections!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${widget.maxSelections} selections allowed',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _selected.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? DsColors.surfaceDark
        : DsColors.surfaceLight;
    final textPrimary = isDark
        ? DsColors.textPrimaryDark
        : DsColors.textPrimaryLight;
    final textMuted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    final dividerColor = isDark ? DsColors.dividerDark : DsColors.dividerLight;
    final chipBg = isDark ? DsColors.inputFillDark : DsColors.inputFillLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
            margin: const EdgeInsetsDirectional.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title and Done button
          Padding(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      if (widget.maxSelections != null)
                        Text(
                          '${_selected.length}/${widget.maxSelections} selected',
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selected.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _selected.clear()),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () => widget.onSelected(_selected),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: DsColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),
          // Chips grid
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DsSpacing.lg).copyWith(
                bottom: MediaQuery.of(context).padding.bottom + DsSpacing.lg,
              ),
              child: Wrap(
                spacing: DsSpacing.sm,
                runSpacing: DsSpacing.sm,
                children: widget.options.map((option) {
                  final isSelected = _selected.contains(option);
                  final emoji = widget.emojiBuilder?.call(option);
                  final label = widget.labelBuilder(option);

                  return FilterChip(
                    selected: isSelected,
                    onSelected: (_) => _toggleOption(option),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (emoji != null) ...[
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                        ],
                        Text(label),
                      ],
                    ),
                    selectedColor: DsColors.primary.withValues(alpha: 0.2),
                    backgroundColor: chipBg,
                    checkmarkColor: DsColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? DsColors.primary : textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? DsColors.primary : dividerColor,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.sm,
                      vertical: DsSpacing.xs,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
