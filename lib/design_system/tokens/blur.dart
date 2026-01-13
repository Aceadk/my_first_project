/// Blur amount tokens for glassmorphism effects.
///
/// These values define the sigma (spread) for BackdropFilter blur effects.
/// Higher values create stronger frosted glass appearance.
class DsBlur {
  DsBlur._();

  /// Subtle frosting effect - barely noticeable blur
  static const double subtle = 4.0;

  /// Light blur - suitable for cards and buttons
  static const double light = 8.0;

  /// Medium blur - standard glassmorphism effect
  static const double medium = 12.0;

  /// Heavy blur - strong frosted effect for nav bars, app bars
  static const double heavy = 20.0;

  /// Extreme blur - maximum frosting for modals and overlays
  static const double extreme = 32.0;
}
