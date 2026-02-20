import 'package:flutter/material.dart';

import '../tokens/breakpoints.dart';

/// Tablet-aware dialog wrapper for settings and account flows.
class AdaptiveDialog {
  const AdaptiveDialog._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    double tabletMaxWidth = 540,
    EdgeInsetsGeometry tabletPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 24,
    ),
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        final width = MediaQuery.of(dialogContext).size.width;
        final isTablet = width >= DsBreakpoints.mobileMax;
        final content = builder(dialogContext);
        if (!isTablet) return content;

        return Padding(
          padding: tabletPadding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: tabletMaxWidth),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

/// Tablet-aware bottom sheet wrapper for settings/action sheets.
class AdaptiveBottomSheet {
  const AdaptiveBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool useSafeArea = true,
    double tabletMaxWidth = 640,
    EdgeInsetsGeometry tabletMargin = const EdgeInsets.symmetric(
      horizontal: 24,
    ),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      builder: (sheetContext) {
        final width = MediaQuery.of(sheetContext).size.width;
        final isTablet = width >= DsBreakpoints.mobileMax;
        final content = builder(sheetContext);
        if (!isTablet) return content;

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: tabletMargin,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: tabletMaxWidth),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
