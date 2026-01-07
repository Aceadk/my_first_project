import 'package:flutter/material.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';

/// Displays a list of items as chips.
class ProfileChipDisplay extends StatelessWidget {
  final List<String> items;
  final int maxVisible;
  final VoidCallback? onTap;
  final String? emptyText;

  const ProfileChipDisplay({
    super.key,
    required this.items,
    this.maxVisible = 5,
    this.onTap,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? DsColors.inputFillDark : DsColors.inputFillLight;
    final textPrimary = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;
    final textMuted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    if (items.isEmpty) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
          child: Text(
            emptyText ?? 'Add',
            style: TextStyle(
              color: DsColors.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final visibleItems = items.take(maxVisible).toList();
    final remaining = items.length - maxVisible;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
        child: Wrap(
          spacing: DsSpacing.xs,
          runSpacing: DsSpacing.xs,
          children: [
            ...visibleItems.map((item) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.sm,
                vertical: DsSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  color: textPrimary,
                ),
              ),
            )),
            if (remaining > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.sm,
                  vertical: DsSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: DsColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+$remaining more',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DsColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact field display for profile view showing label and value.
class ProfileFieldDisplay extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? icon;
  final bool showIfEmpty;

  const ProfileFieldDisplay({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.showIfEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showIfEmpty && (value == null || value!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;
    final textMuted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: textMuted,
            ),
            const SizedBox(width: DsSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? '-',
                  style: TextStyle(
                    fontSize: 15,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
