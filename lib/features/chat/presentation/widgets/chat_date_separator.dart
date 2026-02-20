import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

/// Date separator widget for chat messages.
class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final label = DateTimeFormatter.formatChatSeparator(
      date,
      l10n: context.l10n,
      locale: locale,
    );

    return Semantics(
      label: 'Messages from $label',
      excludeSemantics: true,
      child: Padding(
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
                      (isDark
                          ? DsColors.surfaceLight.withValues(alpha: 0.24)
                          : DsColors.ink900.withValues(alpha: 0.12)),
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
                  filter: ImageFilter.blur(
                    sigmaX: DsBlur.subtle,
                    sigmaY: DsBlur.subtle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md,
                      vertical: DsSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? DsColors.surfaceLight.withValues(alpha: 0.08)
                          : DsColors.ink900.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(DsRadius.round),
                      border: Border.all(
                        color: DsGlassColors.borderFor(context),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      label,
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
                      (isDark
                          ? DsColors.surfaceLight.withValues(alpha: 0.24)
                          : DsColors.ink900.withValues(alpha: 0.12)),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
