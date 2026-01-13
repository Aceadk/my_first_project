import 'package:flutter/services.dart';

/// Haptic feedback utilities for micro-interactions.
class DsHaptics {
  DsHaptics._();

  /// Light tap feedback - for button taps, selections.
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium tap feedback - for toggles, confirmations.
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap feedback - for important actions, destructive ops.
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback - for picker changes, list selections.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibration feedback - for errors, warnings.
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Success feedback - pattern for positive outcomes.
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Error feedback - pattern for negative outcomes.
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Like/match feedback - pattern for dating app interactions.
  static Future<void> like() async {
    await HapticFeedback.mediumImpact();
  }

  /// Super like feedback - stronger pattern.
  static Future<void> superLike() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Match celebration feedback.
  static Future<void> match() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Swipe feedback - for card swiping.
  static Future<void> swipe() async {
    await HapticFeedback.selectionClick();
  }
}
