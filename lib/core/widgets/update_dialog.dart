import 'package:flutter/material.dart';
import 'package:crushhour/core/services/app_update_service.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

/// A dialog that prompts users to update the app.
///
/// Can be configured for:
/// - Forced updates (non-dismissible)
/// - Optional updates (dismissible)
/// - Maintenance mode
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.title,
    required this.message,
    this.updateButtonText = 'Update Now',
    this.laterButtonText = 'Later',
    this.isDismissible = true,
    this.onUpdate,
    this.onLater,
  });

  final String title;
  final String message;
  final String updateButtonText;
  final String laterButtonText;
  final bool isDismissible;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  /// Show an update dialog based on the check result.
  static Future<void> show(
    BuildContext context, {
    required UpdateCheckResult result,
    VoidCallback? onUpdate,
    VoidCallback? onLater,
  }) async {
    if (result.status == UpdateStatus.upToDate) return;

    final isDismissible = result.status != UpdateStatus.forceUpdate;

    await showDialog<void>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => PopScope(
        canPop: isDismissible,
        child: UpdateDialog(
          title: _getTitleForStatus(result.status),
          message: result.message ?? _getMessageForStatus(result.status),
          isDismissible: isDismissible,
          onUpdate: onUpdate ?? () => _defaultOnUpdate(context),
          onLater: isDismissible ? (onLater ?? () => Navigator.pop(context)) : null,
        ),
      ),
    );
  }

  /// Show a maintenance mode dialog.
  static Future<void> showMaintenance(
    BuildContext context, {
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: MaintenanceDialog(message: message),
      ),
    );
  }

  static String _getTitleForStatus(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.forceUpdate:
        return 'Update Required';
      case UpdateStatus.updateRequired:
        return 'Update Available';
      case UpdateStatus.updateAvailable:
        return 'New Version Available';
      case UpdateStatus.upToDate:
        return 'Up to Date';
    }
  }

  static String _getMessageForStatus(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.forceUpdate:
        return 'Please update the app to continue using Crush. This update includes important improvements and bug fixes.';
      case UpdateStatus.updateRequired:
        return 'A new version of Crush is available. Please update for the best experience.';
      case UpdateStatus.updateAvailable:
        return 'A new version of Crush is available with new features and improvements.';
      case UpdateStatus.upToDate:
        return 'You have the latest version.';
    }
  }

  static Future<void> _defaultOnUpdate(BuildContext context) async {
    await AppUpdateService.instance.openStore();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DsColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.system_update,
              color: DsColors.primary,
              size: 24,
            ),
          ),
          DsGap.md,
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!isDismissible) ...[
            DsGap.lg,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DsColors.warning.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: DsColors.warning,
                    size: 20,
                  ),
                  DsGap.sm,
                  Expanded(
                    child: Text(
                      'This update is required to continue using the app.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DsColors.warning,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (isDismissible && onLater != null)
          TextButton(
            onPressed: onLater,
            child: Text(laterButtonText),
          ),
        ElevatedButton(
          onPressed: onUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: DsColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(updateButtonText),
        ),
      ],
    );
  }
}

/// A dialog shown when the app is in maintenance mode.
class MaintenanceDialog extends StatelessWidget {
  const MaintenanceDialog({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DsColors.warning.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.construction,
              color: DsColors.warning,
              size: 24,
            ),
          ),
          DsGap.md,
          Expanded(
            child: Text(
              'Maintenance Mode',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.engineering,
            size: 64,
            color: DsColors.warning,
          ),
          DsGap.lg,
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          DsGap.md,
          Text(
            'Please check back later.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha((0.7 * 255).round()),
                ),
          ),
        ],
      ),
    );
  }
}

/// A widget that checks for updates on initialization and shows dialogs as needed.
class UpdateChecker extends StatefulWidget {
  const UpdateChecker({
    super.key,
    required this.child,
    required this.minAppVersion,
    required this.forceUpdate,
    this.forceUpdateMessage,
    this.maintenanceMode = false,
    this.maintenanceMessage,
  });

  final Widget child;
  final String minAppVersion;
  final bool forceUpdate;
  final String? forceUpdateMessage;
  final bool maintenanceMode;
  final String? maintenanceMessage;

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  @override
  void didUpdateWidget(UpdateChecker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-check if maintenance mode or force update status changed
    if (widget.maintenanceMode != oldWidget.maintenanceMode ||
        widget.forceUpdate != oldWidget.forceUpdate ||
        widget.minAppVersion != oldWidget.minAppVersion) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    // Wait for the widget to be mounted
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // Check maintenance mode first
    if (widget.maintenanceMode) {
      await UpdateDialog.showMaintenance(
        context,
        message: widget.maintenanceMessage ?? 'We are performing maintenance. Please try again later.',
      );
      return;
    }

    // Check for updates
    final result = AppUpdateService.instance.checkVersion(
      minVersion: widget.minAppVersion,
      forceUpdate: widget.forceUpdate,
      updateMessage: widget.forceUpdateMessage,
    );

    if (result.requiresUpdate && mounted) {
      await UpdateDialog.show(context, result: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
