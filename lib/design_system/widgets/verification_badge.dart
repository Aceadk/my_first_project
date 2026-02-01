import 'package:flutter/material.dart';
import '../../core/services/photo_verification_service.dart';
import '../tokens/colors.dart';
import '../tokens/sizes.dart';

/// A badge widget displaying user verification status.
class DsVerificationBadge extends StatelessWidget {
  const DsVerificationBadge({
    super.key,
    required this.level,
    this.size = DsVerificationBadgeSize.small,
    this.showLabel = false,
    this.showTooltip = true,
  });

  final VerificationLevel level;
  final DsVerificationBadgeSize size;
  final bool showLabel;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    if (level == VerificationLevel.none) {
      return const SizedBox.shrink();
    }

    final badge = PhotoVerificationService.getBadgeInfo(level);
    final iconSize = _getIconSize();
    final color = Color(badge.color);

    Widget icon = Icon(
      _getIconData(badge.iconName),
      size: iconSize,
      color: color,
      semanticLabel: badge.label,
    );

    if (showLabel) {
      icon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            badge.label,
            style: TextStyle(
              fontSize: _getLabelFontSize(),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
    }

    if (showTooltip) {
      icon = Tooltip(
        message: badge.description,
        child: icon,
      );
    }

    return Semantics(
      label: '${badge.label}: ${badge.description}',
      child: icon,
    );
  }

  double _getIconSize() {
    return switch (size) {
      DsVerificationBadgeSize.tiny => DsSizes.iconXs,
      DsVerificationBadgeSize.small => DsSizes.iconSm,
      DsVerificationBadgeSize.medium => DsSizes.iconMd,
      DsVerificationBadgeSize.large => DsSizes.iconLg,
    };
  }

  double _getLabelFontSize() {
    return switch (size) {
      DsVerificationBadgeSize.tiny => 10,
      DsVerificationBadgeSize.small => 12,
      DsVerificationBadgeSize.medium => 14,
      DsVerificationBadgeSize.large => 16,
    };
  }

  IconData _getIconData(String iconName) {
    return switch (iconName) {
      'shield_outlined' => Icons.shield_outlined,
      'verified_outlined' => Icons.verified_outlined,
      'verified' => Icons.verified,
      'verified_user' => Icons.verified_user,
      'workspace_premium' => Icons.workspace_premium,
      'badge' => Icons.badge,
      _ => Icons.verified,
    };
  }
}

/// Sizes for verification badge.
enum DsVerificationBadgeSize {
  tiny,
  small,
  medium,
  large,
}

/// A row showing verification status with text.
class DsVerificationStatus extends StatelessWidget {
  const DsVerificationStatus({
    super.key,
    required this.level,
    this.compact = false,
  });

  final VerificationLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badge = PhotoVerificationService.getBadgeInfo(level);
    final color = Color(badge.color);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsVerificationBadge(
            level: level,
            size: compact
                ? DsVerificationBadgeSize.tiny
                : DsVerificationBadgeSize.small,
            showTooltip: false,
          ),
          const SizedBox(width: 6),
          Text(
            badge.label,
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card prompting the user to verify their profile.
class DsVerificationPrompt extends StatelessWidget {
  const DsVerificationPrompt({
    super.key,
    required this.currentLevel,
    required this.onStartVerification,
    this.targetLevel,
  });

  final VerificationLevel currentLevel;
  final VerificationLevel? targetLevel;
  final VoidCallback onStartVerification;

  @override
  Widget build(BuildContext context) {
    final target = targetLevel ?? _getNextLevel(currentLevel);
    final targetBadge = PhotoVerificationService.getBadgeInfo(target);
    final color = Color(targetBadge.color);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Verify your profile to unlock ${targetBadge.label}',
      button: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isDark ? 0.15 : 0.08),
              DsColors.primary.withValues(alpha: isDark ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    color: color,
                    size: DsSizes.iconLg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get ${targetBadge.label}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? DsColors.textPrimaryDark
                              : DsColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        targetBadge.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getPromptText(target),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStartVerification,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start Verification'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, DsSizes.tapTargetPreferred),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  VerificationLevel _getNextLevel(VerificationLevel current) {
    return switch (current) {
      VerificationLevel.none => VerificationLevel.basic,
      VerificationLevel.basic => VerificationLevel.photo,
      VerificationLevel.photo => VerificationLevel.id,
      VerificationLevel.id => VerificationLevel.premium,
      VerificationLevel.premium => VerificationLevel.premium,
    };
  }

  String _getPromptText(VerificationLevel target) {
    return switch (target) {
      VerificationLevel.basic =>
        'Verify your email or phone to build trust with potential matches.',
      VerificationLevel.photo =>
        'Take a quick selfie to prove your photos are really you. Get more matches!',
      VerificationLevel.id =>
        'Upload a government ID for our highest trust level. Your info stays private.',
      VerificationLevel.premium =>
        'Complete a quick video call to get the exclusive premium badge.',
      VerificationLevel.none => '',
    };
  }
}
