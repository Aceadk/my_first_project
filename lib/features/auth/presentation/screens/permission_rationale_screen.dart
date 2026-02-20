import 'package:flutter/material.dart';
import 'package:crushhour/design_system/design_system.dart';

/// Permission types that CRUSH may request from the user.
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
///     description: 'CRUSH uses your location to show you people nearby. '
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
        final maxWidth = DsBreakpoints.responsiveValue<double>(
          constraints.maxWidth,
          mobile: double.infinity,
          tablet: 480,
          desktop: 480,
        );

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
                    padding: DsEdgeInsets.allXxl,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DsGap.xxxl,

                          // Icon circle
                          Semantics(
                            image: true,
                            label: _permissionTypeLabel,
                            excludeSemantics: true,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    DsColors.primary.withValues(alpha: 0.2),
                                    DsColors.secondary.withValues(alpha: 0.15),
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
                                size: 56,
                                color: DsColors.primary,
                              ),
                            ),
                          ),

                          DsGap.xxxl,

                          // Title
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? DsColors.textPrimaryDark
                                        : DsColors.textPrimaryLight,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          DsGap.lg,

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

                          DsGap.lg,

                          // Privacy assurance chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.lg,
                              vertical: DsSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: DsColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                DsRadius.round,
                              ),
                              border: Border.all(
                                color: DsColors.success.withValues(alpha: 0.3),
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
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: DsColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          DsGap.xxxl,

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

                          DsGap.md,

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

                          DsGap.md,

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

                          DsGap.xxxl,
                        ],
                      ),
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
