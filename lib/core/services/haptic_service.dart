import 'package:flutter/services.dart';

/// Service for providing consistent haptic feedback across the app.
/// Adds tactile responses to swipe actions, button presses, and celebrations.
class HapticService {
  HapticService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT FEEDBACK - Subtle taps for selections and toggles
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light tap for button presses, toggles, and selections.
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Selection changed feedback.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDIUM FEEDBACK - Standard interactions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Medium impact for standard button presses.
  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  /// Feedback for nav item selection.
  static Future<void> navTap() async {
    await HapticFeedback.selectionClick();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEAVY FEEDBACK - Significant actions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Heavy impact for important actions.
  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SWIPE ACTIONS - Deck swiping feedback
  // ═══════════════════════════════════════════════════════════════════════════

  /// Feedback when starting a swipe drag.
  static Future<void> swipeStart() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback when swipe threshold is crossed (card will be actioned).
  static Future<void> swipeThreshold() async {
    await HapticFeedback.mediumImpact();
  }

  /// Feedback for like action.
  static Future<void> like() async {
    await HapticFeedback.mediumImpact();
  }

  /// Feedback for nope/pass action.
  static Future<void> nope() async {
    await HapticFeedback.lightImpact();
  }

  /// Feedback for super like action - more intense.
  static Future<void> superLike() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Feedback for rewind action.
  static Future<void> rewind() async {
    await HapticFeedback.mediumImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CELEBRATIONS - Match and achievement feedback
  // ═══════════════════════════════════════════════════════════════════════════

  /// Celebration feedback for matches - multiple vibrations.
  static Future<void> matchCelebration() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.lightImpact();
  }

  /// Success feedback for completing actions.
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error feedback.
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }

  /// Warning feedback.
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Feedback for sending a message.
  static Future<void> messageSent() async {
    await HapticFeedback.lightImpact();
  }

  /// Feedback for receiving a message.
  static Future<void> messageReceived() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback for long press on message.
  static Future<void> messageLongPress() async {
    await HapticFeedback.mediumImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO/MEDIA ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Feedback for photo navigation.
  static Future<void> photoNavigation() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback for photo zoom.
  static Future<void> photoZoom() async {
    await HapticFeedback.lightImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PULL TO REFRESH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Feedback when pull-to-refresh threshold is reached.
  static Future<void> refreshThreshold() async {
    await HapticFeedback.mediumImpact();
  }

  /// Feedback when refresh completes.
  static Future<void> refreshComplete() async {
    await HapticFeedback.lightImpact();
  }
}
