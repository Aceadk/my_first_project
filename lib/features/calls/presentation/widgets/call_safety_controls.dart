import 'dart:ui';

import 'package:crushhour/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

/// In-call safety controls and first-call safety guidance.
class CallSafetyControls extends StatelessWidget {
  const CallSafetyControls({
    super.key,
    required this.showSafetyTip,
    required this.onDismissTip,
    required this.onOpenGuidelines,
    required this.onReportPressed,
    required this.onBlockPressed,
    required this.isBlocked,
    required this.isReportedRecently,
    this.matchName,
  });

  final bool showSafetyTip;
  final VoidCallback onDismissTip;
  final VoidCallback onOpenGuidelines;
  final VoidCallback onReportPressed;
  final VoidCallback onBlockPressed;
  final bool isBlocked;
  final bool isReportedRecently;
  final String? matchName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSafetyTip) _buildSafetyTip(context),
        _buildSafetyActions(context),
      ],
    );
  }

  Widget _buildSafetyTip(BuildContext context) {
    final targetName = (matchName == null || matchName!.trim().isEmpty)
        ? 'this person'
        : matchName!.trim();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: DsColors.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: DsColors.warning.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: DsColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Safety reminder',
                        style: TextStyle(
                          color: DsColors.surfaceLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Dismiss safety tip',
                      onPressed: onDismissTip,
                      icon: const Icon(
                        Icons.close,
                        color: DsColors.surfaceLight,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Text(
                  'On your first call with $targetName, avoid sharing private details. '
                  'If anything feels unsafe, report or block immediately.',
                  style: TextStyle(
                    color: DsColors.surfaceLight.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onOpenGuidelines,
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: Text(
                    AppLocalizations.of(context).viewSafetyGuidelines,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: DsColors.surfaceLight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyActions(BuildContext context) {
    final reportLabel = isReportedRecently ? 'Reported' : 'Report';
    final blockLabel = isBlocked ? 'Blocked' : 'Block';

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 14),
      child: Row(
        children: [
          Expanded(
            child: _SafetyButton(
              icon: Icons.report_outlined,
              label: reportLabel,
              color: DsColors.warning,
              onPressed: isReportedRecently ? null : onReportPressed,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SafetyButton(
              icon: Icons.block_outlined,
              label: blockLabel,
              color: isBlocked ? DsColors.success : DsColors.error,
              onPressed: isBlocked ? null : onBlockPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyButton extends StatelessWidget {
  const _SafetyButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: DsColors.surfaceLight.withValues(alpha: 0.09),
            child: InkWell(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: DsColors.surfaceLight.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
