import 'package:flutter/widgets.dart';
import 'spacing.dart';

/// Pre-built vertical SizedBox widgets for consistent spacing.
class DsGap {
  DsGap._();

  /// 4px vertical gap
  static const Widget xs = SizedBox(height: DsSpacing.xs);

  /// 8px vertical gap
  static const Widget sm = SizedBox(height: DsSpacing.sm);

  /// 12px vertical gap
  static const Widget md = SizedBox(height: DsSpacing.md);

  /// 16px vertical gap
  static const Widget lg = SizedBox(height: DsSpacing.lg);

  /// 20px vertical gap
  static const Widget xl = SizedBox(height: DsSpacing.xl);

  /// 24px vertical gap
  static const Widget xxl = SizedBox(height: DsSpacing.xxl);

  /// 32px vertical gap
  static const Widget xxxl = SizedBox(height: DsSpacing.xxxl);

  /// 40px vertical gap
  static const Widget huge = SizedBox(height: DsSpacing.huge);

  // Horizontal variants

  /// 4px horizontal gap
  static const Widget xsH = SizedBox(width: DsSpacing.xs);

  /// 8px horizontal gap
  static const Widget smH = SizedBox(width: DsSpacing.sm);

  /// 12px horizontal gap
  static const Widget mdH = SizedBox(width: DsSpacing.md);

  /// 16px horizontal gap
  static const Widget lgH = SizedBox(width: DsSpacing.lg);

  /// 20px horizontal gap
  static const Widget xlH = SizedBox(width: DsSpacing.xl);

  /// 24px horizontal gap
  static const Widget xxlH = SizedBox(width: DsSpacing.xxl);

  /// 32px horizontal gap
  static const Widget xxxlH = SizedBox(width: DsSpacing.xxxl);

  /// 40px horizontal gap
  static const Widget hugeH = SizedBox(width: DsSpacing.huge);
}

/// Pre-built EdgeInsets for consistent padding/margin.
class DsEdgeInsets {
  DsEdgeInsets._();

  // All sides
  static const EdgeInsets allXs = EdgeInsets.all(DsSpacing.xs);
  static const EdgeInsets allSm = EdgeInsets.all(DsSpacing.sm);
  static const EdgeInsets allMd = EdgeInsets.all(DsSpacing.md);
  static const EdgeInsets allLg = EdgeInsets.all(DsSpacing.lg);
  static const EdgeInsets allXl = EdgeInsets.all(DsSpacing.xl);
  static const EdgeInsets allXxl = EdgeInsets.all(DsSpacing.xxl);
  static const EdgeInsets allXxxl = EdgeInsets.all(DsSpacing.xxxl);

  // Horizontal only
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(
    horizontal: DsSpacing.xs,
  );
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(
    horizontal: DsSpacing.sm,
  );
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(
    horizontal: DsSpacing.md,
  );
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(
    horizontal: DsSpacing.lg,
  );
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(
    horizontal: DsSpacing.xl,
  );
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(
    horizontal: DsSpacing.xxl,
  );

  // Vertical only
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(
    vertical: DsSpacing.xs,
  );
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(
    vertical: DsSpacing.sm,
  );
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(
    vertical: DsSpacing.md,
  );
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(
    vertical: DsSpacing.lg,
  );
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(
    vertical: DsSpacing.xl,
  );
  static const EdgeInsets verticalXxl = EdgeInsets.symmetric(
    vertical: DsSpacing.xxl,
  );

  // Common combinations
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: DsSpacing.lg,
    vertical: DsSpacing.lg,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(DsSpacing.lg);

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: DsSpacing.lg,
    vertical: DsSpacing.md,
  );

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: DsSpacing.lg,
    vertical: DsSpacing.md,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: DsSpacing.xl,
    vertical: DsSpacing.md,
  );

  static const EdgeInsets dialogPadding = EdgeInsets.all(DsSpacing.xxl);

  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: DsSpacing.md,
    vertical: DsSpacing.xs,
  );
}
