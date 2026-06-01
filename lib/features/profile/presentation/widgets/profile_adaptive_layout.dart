import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

class ProfileAdaptiveLayoutMetrics {
  const ProfileAdaptiveLayoutMetrics({
    required this.screenWidth,
    required this.textScale,
    required this.contentMaxWidth,
    required this.useTwoColumnSetup,
    required this.useTwoColumnEdit,
    required this.useTwoColumnView,
    required this.sidePanelWidth,
    required this.columnGap,
    required this.mediaTileWidth,
    required this.mediaTileHeight,
  });

  final double screenWidth;
  final double textScale;
  final double contentMaxWidth;
  final bool useTwoColumnSetup;
  final bool useTwoColumnEdit;
  final bool useTwoColumnView;
  final double sidePanelWidth;
  final double columnGap;
  final double mediaTileWidth;
  final double mediaTileHeight;

  static ProfileAdaptiveLayoutMetrics fromWidth({
    required double width,
    double textScale = 1,
  }) {
    final contentMaxWidth = _profileContentMaxWidthFor(width);
    final effectiveContentWidth = contentMaxWidth.isFinite
        ? math.min(width, contentMaxWidth)
        : width;
    final largeText = textScale > 1.3;
    final canUseColumns = effectiveContentWidth >= 760 && !largeText;
    final viewCanUseColumns = effectiveContentWidth >= 880 && !largeText;
    final sidePanelWidth = effectiveContentWidth >= 1040 ? 360.0 : 320.0;
    final tileWidth = _mediaTileWidthFor(effectiveContentWidth);

    return ProfileAdaptiveLayoutMetrics(
      screenWidth: width,
      textScale: textScale,
      contentMaxWidth: contentMaxWidth,
      useTwoColumnSetup: canUseColumns,
      useTwoColumnEdit: canUseColumns,
      useTwoColumnView: viewCanUseColumns,
      sidePanelWidth: sidePanelWidth,
      columnGap: effectiveContentWidth >= 1040 ? DsSpacing.xl : DsSpacing.lg,
      mediaTileWidth: tileWidth,
      mediaTileHeight: tileWidth * 4 / 3,
    );
  }

  static ProfileAdaptiveLayoutMetrics of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return fromWidth(
      width: mediaQuery.size.width,
      textScale: mediaQuery.textScaler.scale(1),
    );
  }

  static double _mediaTileWidthFor(double width) {
    if (width >= 1040) return 116;
    if (width >= 760) return 108;
    return 96;
  }

  static double _profileContentMaxWidthFor(double width) {
    if (width >= 1180) return math.min(width, 1120);
    if (width >= 760) return math.min(width, 920);
    return DsBreakpoints.contentMaxWidth(width);
  }
}

class ProfileResponsiveRow extends StatelessWidget {
  const ProfileResponsiveRow({
    super.key,
    required this.metrics,
    required this.leading,
    required this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final ProfileAdaptiveLayoutMetrics metrics;
  final Widget leading;
  final Widget trailing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (!metrics.useTwoColumnSetup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leading,
          const SizedBox(height: DsSpacing.xl),
          trailing,
        ],
      );
    }

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        SizedBox(width: metrics.sidePanelWidth, child: leading),
        SizedBox(width: metrics.columnGap),
        Expanded(child: trailing),
      ],
    );
  }
}
