import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

/// Date separator widget for chat messages.
class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.date});

  final DateTime date;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.white24 : Colors.black12),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DsRadius.round),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: DsBlur.subtle, sigmaY: DsBlur.subtle),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.md,
                    vertical: DsSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(DsRadius.round),
                    border: Border.all(
                      color: isDark
                          ? DsGlassColors.borderDark
                          : DsGlassColors.borderLight,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? Colors.white24 : Colors.black12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
