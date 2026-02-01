import 'package:flutter/widgets.dart';

/// Design system size tokens for consistent sizing across the app.
/// All interactive elements should use these tokens to ensure accessibility.
class DsSizes {
  DsSizes._();

  // ==========================================================================
  // TAP TARGET SIZES (WCAG 2.1 AAA: 44x44 minimum)
  // ==========================================================================

  /// Minimum touch target size for accessibility (44x44)
  static const double tapTargetMin = 44;

  /// Preferred touch target size (48x48)
  static const double tapTargetPreferred = 48;

  /// Large touch target for primary actions (56x56)
  static const double tapTargetLarge = 56;

  /// Extra large touch target for FABs (64x64)
  static const double tapTargetXl = 64;

  // ==========================================================================
  // ICON SIZES
  // ==========================================================================

  /// Extra small icon (12px) - badges, indicators
  static const double iconXs = 12;

  /// Small icon (16px) - inline icons, list trailing
  static const double iconSm = 16;

  /// Medium icon (20px) - buttons, form fields
  static const double iconMd = 20;

  /// Default icon (24px) - standard icon size
  static const double iconDefault = 24;

  /// Large icon (28px) - navigation, prominent actions
  static const double iconLg = 28;

  /// Extra large icon (32px) - featured actions
  static const double iconXl = 32;

  /// Huge icon (40px) - hero icons, empty states
  static const double iconXxl = 40;

  /// Display icon (48px) - splash, onboarding
  static const double iconDisplay = 48;

  // ==========================================================================
  // AVATAR SIZES
  // ==========================================================================

  /// Tiny avatar (24px) - inline mentions
  static const double avatarTiny = 24;

  /// Small avatar (32px) - list items, chips
  static const double avatarSm = 32;

  /// Medium avatar (40px) - chat bubbles, comments
  static const double avatarMd = 40;

  /// Default avatar (48px) - list tiles, cards
  static const double avatarDefault = 48;

  /// Large avatar (56px) - profile headers
  static const double avatarLg = 56;

  /// Extra large avatar (72px) - profile cards
  static const double avatarXl = 72;

  /// Huge avatar (96px) - profile detail view
  static const double avatarXxl = 96;

  /// Display avatar (120px) - profile hero
  static const double avatarDisplay = 120;

  // ==========================================================================
  // BUTTON SIZES
  // ==========================================================================

  /// Small button height (36px)
  static const double buttonHeightSm = 36;

  /// Medium button height (44px) - meets tap target
  static const double buttonHeightMd = 44;

  /// Default button height (48px)
  static const double buttonHeightDefault = 48;

  /// Large button height (56px)
  static const double buttonHeightLg = 56;

  // ==========================================================================
  // ACTION BUTTON SIZES (Discovery deck)
  // ==========================================================================

  /// Secondary action button (48px) - rewind
  static const double actionButtonSm = 48;

  /// Default action button (56px) - dislike/like
  static const double actionButtonMd = 56;

  /// Primary action button (64px) - super like
  static const double actionButtonLg = 64;

  // ==========================================================================
  // INPUT FIELD SIZES
  // ==========================================================================

  /// Small input height (40px)
  static const double inputHeightSm = 40;

  /// Default input height (48px)
  static const double inputHeightDefault = 48;

  /// Large input height (56px) - emphasized inputs
  static const double inputHeightLg = 56;

  // ==========================================================================
  // CARD & CONTAINER SIZES
  // ==========================================================================

  /// Minimum card width (280px)
  static const double cardMinWidth = 280;

  /// Maximum card width on mobile (400px)
  static const double cardMaxWidthMobile = 400;

  /// Maximum card width on tablet (480px)
  static const double cardMaxWidthTablet = 480;

  /// Dialog max width (400px)
  static const double dialogMaxWidth = 400;

  /// Bottom sheet max width (600px)
  static const double bottomSheetMaxWidth = 600;

  // ==========================================================================
  // SAFE AREA / INSETS
  // ==========================================================================

  /// Bottom nav bar height (64px)
  static const double bottomNavHeight = 64;

  /// App bar height (56px)
  static const double appBarHeight = 56;

  /// Expanded app bar height (300px)
  static const double appBarExpandedHeight = 300;

  /// Keyboard toolbar height (48px)
  static const double keyboardToolbarHeight = 48;
}

/// Pre-built size constraints for common use cases.
class DsConstraints {
  DsConstraints._();

  /// Button constraints ensuring minimum tap target
  static const BoxConstraints button = BoxConstraints(
    minWidth: DsSizes.tapTargetMin,
    minHeight: DsSizes.tapTargetMin,
  );

  /// Icon button constraints
  static const BoxConstraints iconButton = BoxConstraints(
    minWidth: DsSizes.tapTargetPreferred,
    minHeight: DsSizes.tapTargetPreferred,
  );

  /// Large action button constraints
  static const BoxConstraints actionButton = BoxConstraints(
    minWidth: DsSizes.actionButtonMd,
    minHeight: DsSizes.actionButtonMd,
  );

  /// Input field constraints
  static const BoxConstraints input = BoxConstraints(
    minHeight: DsSizes.inputHeightDefault,
  );

  /// Card constraints for mobile
  static const BoxConstraints cardMobile = BoxConstraints(
    minWidth: DsSizes.cardMinWidth,
    maxWidth: DsSizes.cardMaxWidthMobile,
  );

  /// Card constraints for tablet
  static const BoxConstraints cardTablet = BoxConstraints(
    minWidth: DsSizes.cardMinWidth,
    maxWidth: DsSizes.cardMaxWidthTablet,
  );

  /// Dialog constraints
  static const BoxConstraints dialog = BoxConstraints(
    minWidth: 280,
    maxWidth: DsSizes.dialogMaxWidth,
  );

  /// Bottom sheet constraints
  static const BoxConstraints bottomSheet = BoxConstraints(
    maxWidth: DsSizes.bottomSheetMaxWidth,
  );
}

/// Extension to easily check if a size meets accessibility requirements.
extension SizeAccessibility on double {
  /// Whether this size meets minimum tap target (44px)
  bool get meetsMinTapTarget => this >= DsSizes.tapTargetMin;

  /// Whether this size meets preferred tap target (48px)
  bool get meetsPreferredTapTarget => this >= DsSizes.tapTargetPreferred;
}
