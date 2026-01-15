/// Blur amount tokens for glassmorphism effects.
///
/// These values define the sigma (spread) for BackdropFilter blur effects.
/// Higher values create stronger frosted glass appearance but are more
/// expensive to render. Values are optimized for 60fps performance.
///
/// Performance note: BackdropFilter is GPU-intensive. Keep sigma values
/// low (< 10) for smooth scrolling and animations.
class DsBlur {
  DsBlur._();

  /// Subtle frosting effect - barely noticeable blur
  /// Use for lightweight overlays and hints
  static const double subtle = 2.0;

  /// Light blur - suitable for cards and buttons
  /// Best balance of effect vs performance
  static const double light = 4.0;

  /// Medium blur - standard glassmorphism effect
  /// Use sparingly on static elements
  static const double medium = 6.0;

  /// Heavy blur - strong frosted effect for nav bars, app bars
  /// Avoid during animations/scrolling
  static const double heavy = 10.0;

  /// Extreme blur - maximum frosting for modals and overlays
  /// Only use on full-screen overlays
  static const double extreme = 16.0;
}
