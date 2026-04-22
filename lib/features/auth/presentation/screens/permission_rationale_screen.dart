import 'package:flutter/material.dart';
import 'package:crushhour/design_system/design_system.dart';

/// Permission types that Crush may request from the user.
enum PermissionType { location, notifications, camera, photos }

/// A reusable pre-permission rationale screen shown BEFORE requesting a
/// system permission dialog. Explains to the user why the permission is
/// needed, giving them the choice to allow or skip.
///
/// Usage:
/// ```dart
/// await showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => PermissionRationaleScreen(
///     permissionType: PermissionType.location,
///     title: 'Find matches near you',
///     description: 'Crush uses your location to show you people nearby. '
///         'Your exact location is never shared with other users.',
///     icon: Icons.location_on_rounded,
///     onAllow: () { /* request system permission */ },
///     onSkip: () { Navigator.pop(context); },
///   ),
/// );
/// ```
class PermissionRationaleScreen extends StatelessWidget {
  const PermissionRationaleScreen({
    super.key,
    required this.permissionType,
    required this.title,
    required this.description,
    required this.icon,
    required this.onAllow,
    required this.onSkip,
  });

  /// The type of permission being requested.
  final PermissionType permissionType;

  /// Headline shown to the user (e.g. "Find matches near you").
  final String title;

  /// Detailed explanation of why the permission is needed and how data is used.
  final String description;

  /// Large icon displayed at the top of the rationale screen.
  final IconData icon;

  /// Called when the user taps "Allow" — should trigger the actual system
  /// permission request.
  final VoidCallback onAllow;

  /// Called when the user taps "Not Now" — dismisses without requesting.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compressedLayout = textScale > 1.3 || constraints.maxHeight < 760;
        final maxWidth = DsBreakpoints.responsiveValue<double>(
          constraints.maxWidth,
          mobile: double.infinity,
          tablet: 480,
          desktop: 480,
        );
        final contentPadding = compressedLayout
            ? const EdgeInsets.fromLTRB(
                DsSpacing.lg,
                DsSpacing.md,
                DsSpacing.lg,
                DsSpacing.lg,
              )
            : DsEdgeInsets.allXxl;
        final heroSize = compressedLayout ? 72.0 : 120.0;
        final heroIconSize = compressedLayout ? 34.0 : 56.0;
        final sectionGap = compressedLayout ? DsSpacing.md : DsSpacing.xxxl;
        final bodyGap = compressedLayout ? DsSpacing.sm : DsSpacing.lg;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Semantics(
              label: 'Permission request: $title',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            DsColors.backgroundDark,
                            DsColors.secondary.withValues(alpha: 0.18),
                            DsColors.backgroundDark,
                          ]
                        : [
                            DsColors.backgroundLight,
                            DsColors.secondary.withValues(alpha: 0.06),
                            DsColors.backgroundLight,
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: contentPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: sectionGap),

                                // Icon circle
                                Semantics(
                                  image: true,
                                  label: _permissionTypeLabel,
                                  excludeSemantics: true,
                                  child: Container(
                                    width: heroSize,
                                    height: heroSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: AlignmentDirectional.topStart,
                                        end: AlignmentDirectional.bottomEnd,
                                        colors: [
                                          DsColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          DsColors.secondary.withValues(
                                            alpha: 0.15,
                                          ),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: DsColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: heroIconSize,
                                      color: DsColors.primary,
                                    ),
                                  ),
                                ),

                                SizedBox(height: sectionGap),

                                // Title
                                Semantics(
                                  header: true,
                                  child: Text(
                                    title,
                                    style:
                                        (compressedLayout
                                                ? Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge
                                                : Theme.of(
                                                    context,
                                                  ).textTheme.headlineSmall)
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? DsColors.textPrimaryDark
                                                  : DsColors.textPrimaryLight,
                                            ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                SizedBox(height: bodyGap),

                                // Description
                                Text(
                                  description,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: isDark
                                            ? DsColors.textMutedDark
                                            : DsColors.textMutedLight,
                                        height: 1.5,
                                      ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: bodyGap),

                                // Privacy assurance chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: DsSpacing.lg,
                                    vertical: DsSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DsColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      DsRadius.round,
                                    ),
                                    border: Border.all(
                                      color: DsColors.success.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shield_rounded,
                                        size: 16,
                                        color: DsColors.success,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _privacyAssuranceText,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: DsColors.success,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: sectionGap),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: bodyGap),

                        // Allow button
                        SizedBox(
                          width: double.infinity,
                          child: GlassPrimaryButton(
                            semanticLabel: 'Allow $title',
                            onPressed: onAllow,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Allow',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: bodyGap),

                        // Not Now button
                        SizedBox(
                          width: double.infinity,
                          child: GlassOutlinedButton(
                            semanticLabel: 'Skip this permission for now',
                            onPressed: onSkip,
                            child: const Text(
                              'Not Now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: bodyGap),

                        // Settings reminder
                        Semantics(
                          label: 'You can enable this later in Settings',
                          child: Text(
                            'You can change this anytime in Settings',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? DsColors.textMutedDark
                                      : DsColors.textMutedLight,
                                  fontSize: 12,
                                ),
                            textAlign: TextAlign.center,
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
      },
    );
  }

  /// Returns a human-readable label for the permission type.
  String get _permissionTypeLabel {
    switch (permissionType) {
      case PermissionType.location:
        return 'Location permission';
      case PermissionType.notifications:
        return 'Notification permission';
      case PermissionType.camera:
        return 'Camera permission';
      case PermissionType.photos:
        return 'Photo library permission';
    }
  }

  /// Returns a privacy assurance message specific to the permission type.
  String get _privacyAssuranceText {
    switch (permissionType) {
      case PermissionType.location:
        return 'Your exact location is never shared';
      case PermissionType.notifications:
        return 'You control which notifications you receive';
      case PermissionType.camera:
        return 'Photos are only shared when you choose';
      case PermissionType.photos:
        return 'We only access photos you select';
    }
  }
}
