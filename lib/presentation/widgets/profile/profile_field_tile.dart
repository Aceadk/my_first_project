import 'package:flutter/material.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';

/// A tappable row for profile fields that displays label, current value, and arrow.
class ProfileFieldTile extends StatelessWidget {
  final String label;
  final String? value;
  final String? placeholder;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final bool showDivider;

  const ProfileFieldTile({
    super.key,
    required this.label,
    this.value,
    this.placeholder,
    this.leadingIcon,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null && value!.isNotEmpty;
    final displayValue = hasValue ? value! : (placeholder ?? 'Add');

    final textPrimary = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;
    final textMuted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    final dividerColor = isDark ? DsColors.dividerDark : DsColors.dividerLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DsSpacing.md,
              horizontal: DsSpacing.sm,
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 22,
                    color: textMuted,
                  ),
                  const SizedBox(width: DsSpacing.md),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 15,
                      color: hasValue
                          ? textMuted
                          : DsColors.primary.withValues(alpha: 0.7),
                      fontWeight: hasValue ? FontWeight.w400 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
            indent: leadingIcon != null ? 46 : 0,
          ),
      ],
    );
  }
}

/// A section header for profile edit screen.
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const ProfileSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.padding = const EdgeInsets.only(
      left: 16,
      right: 16,
      top: 24,
      bottom: 8,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: DsColors.primary,
            ),
            const SizedBox(width: DsSpacing.sm),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
