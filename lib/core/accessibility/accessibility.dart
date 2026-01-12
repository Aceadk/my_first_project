import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for CrushHour app.
/// Provides semantic labels, contrast helpers, and screen reader support.

// ═══════════════════════════════════════════════════════════════════════════
// SEMANTIC LABELS
// ═══════════════════════════════════════════════════════════════════════════

/// Standard semantic labels for common UI elements.
class A11yLabels {
  A11yLabels._();

  // Navigation
  static const String backButton = 'Go back';
  static const String closeButton = 'Close';
  static const String menuButton = 'Open menu';
  static const String settingsButton = 'Open settings';
  static const String searchButton = 'Search';
  static const String filterButton = 'Open filters';

  // Discovery/Deck actions
  static const String passButton = 'Pass on this profile';
  static const String likeButton = 'Like this profile';
  static const String superLikeButton = 'Super like this profile';
  static const String rewindButton = 'Undo last action';
  static const String boostButton = 'Boost your profile';

  // Profile
  static String profileImage(String? name) =>
      name != null ? 'Profile photo of $name' : 'Profile photo';
  static String profileAvatar(String? name) =>
      name != null ? 'Avatar of $name' : 'User avatar';
  static const String editProfile = 'Edit profile';
  static const String viewProfile = 'View profile';
  static const String verifiedBadge = 'Verified profile';
  static String onlineStatus(bool isOnline) =>
      isOnline ? 'Online now' : 'Offline';

  // Chat
  static const String sendMessage = 'Send message';
  static const String attachPhoto = 'Attach photo';
  static const String attachFile = 'Attach file';
  static const String voiceMessage = 'Record voice message';
  static const String videoCall = 'Start video call';
  static const String voiceCall = 'Start voice call';
  static String messageFrom(String sender) => 'Message from $sender';
  static String unreadMessages(int count) =>
      count == 1 ? '1 unread message' : '$count unread messages';

  // Auth
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';
  static const String loginButton = 'Sign in';
  static const String signUpButton = 'Create account';
  static const String forgotPassword = 'Reset password';
  static const String resendCode = 'Resend verification code';

  // Settings
  static const String toggleSwitch = 'Toggle setting';
  static String switchState(bool isOn) => isOn ? 'On' : 'Off';

  // General
  static const String loading = 'Loading';
  static const String refreshing = 'Refreshing';
  static const String errorOccurred = 'An error occurred';
  static const String retry = 'Try again';
  static const String dismiss = 'Dismiss';
  static const String moreOptions = 'More options';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save changes';
}

// ═══════════════════════════════════════════════════════════════════════════
// SEMANTIC HINTS
// ═══════════════════════════════════════════════════════════════════════════

/// Hints that describe what will happen when an action is performed.
class A11yHints {
  A11yHints._();

  static const String tapToView = 'Double tap to view';
  static const String tapToSelect = 'Double tap to select';
  static const String tapToToggle = 'Double tap to toggle';
  static const String tapToEdit = 'Double tap to edit';
  static const String tapToExpand = 'Double tap to expand';
  static const String tapToCollapse = 'Double tap to collapse';
  static const String swipeToDelete = 'Swipe left to delete';
  static const String swipeForActions = 'Swipe left for more actions';
  static const String dragToReorder = 'Long press and drag to reorder';
  static const String pinchToZoom = 'Pinch to zoom';

  static String tapToOpen(String destination) =>
      'Double tap to open $destination';
  static String tapToNavigate(String screen) =>
      'Double tap to navigate to $screen';
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE REGION ANNOUNCEMENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Announce important changes to screen readers.
class A11yAnnounce {
  A11yAnnounce._();

  /// Announce a polite message (waits for current speech to finish).
  static void polite(BuildContext context, String message) {
    final view = View.of(context);
    SemanticsService.sendAnnouncement(
      view,
      message,
      TextDirection.ltr,
    );
  }

  /// Announce an assertive message (interrupts current speech).
  static void assertive(BuildContext context, String message) {
    final view = View.of(context);
    SemanticsService.sendAnnouncement(
      view,
      message,
      TextDirection.ltr,
      assertiveness: Assertiveness.assertive,
    );
  }

  // Common announcements
  static void loading(BuildContext context) =>
      polite(context, 'Loading, please wait');

  static void loadingComplete(BuildContext context) =>
      polite(context, 'Loading complete');

  static void error(BuildContext context, String message) =>
      assertive(context, 'Error: $message');

  static void success(BuildContext context, String message) =>
      polite(context, message);

  static void matchFound(BuildContext context, String name) =>
      assertive(context, 'It\'s a match! You matched with $name');

  static void newMessage(BuildContext context, String sender) =>
      polite(context, 'New message from $sender');

  static void profileLiked(BuildContext context) =>
      polite(context, 'Profile liked');

  static void profilePassed(BuildContext context) =>
      polite(context, 'Profile passed');

  static void profileSuperLiked(BuildContext context) =>
      polite(context, 'Profile super liked');

  static void messageSent(BuildContext context) =>
      polite(context, 'Message sent');

  static void settingSaved(BuildContext context) =>
      polite(context, 'Setting saved');
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTRAST HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// WCAG 2.1 contrast ratio utilities.
class A11yContrast {
  A11yContrast._();

  /// Minimum contrast ratio for normal text (WCAG AA).
  static const double minNormalText = 4.5;

  /// Minimum contrast ratio for large text (WCAG AA).
  static const double minLargeText = 3.0;

  /// Enhanced contrast ratio for normal text (WCAG AAA).
  static const double enhancedNormalText = 7.0;

  /// Enhanced contrast ratio for large text (WCAG AAA).
  static const double enhancedLargeText = 4.5;

  /// Calculate relative luminance of a color.
  static double relativeLuminance(Color color) {
    double r = _linearize(color.r / 255);
    double g = _linearize(color.g / 255);
    double b = _linearize(color.b / 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double value) {
    return value <= 0.03928
        ? value / 12.92
        : ((value + 0.055) / 1.055).clamp(0, 1);
  }

  /// Calculate contrast ratio between two colors.
  static double contrastRatio(Color foreground, Color background) {
    final fgLum = relativeLuminance(foreground) + 0.05;
    final bgLum = relativeLuminance(background) + 0.05;
    return fgLum > bgLum ? fgLum / bgLum : bgLum / fgLum;
  }

  /// Check if contrast meets WCAG AA for normal text.
  static bool meetsAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= minNormalText;
  }

  /// Check if contrast meets WCAG AAA for normal text.
  static bool meetsAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= enhancedNormalText;
  }

  /// Get an accessible text color (black or white) for a given background.
  static Color textColorFor(Color background) {
    return relativeLuminance(background) > 0.179
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }

  /// Ensure a color meets minimum contrast against a background.
  static Color ensureContrast(
    Color foreground,
    Color background, {
    double minRatio = minNormalText,
  }) {
    if (contrastRatio(foreground, background) >= minRatio) {
      return foreground;
    }
    // Return black or white based on background luminance
    return textColorFor(background);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SEMANTIC WRAPPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// A button with proper semantics for screen readers.
class A11yButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String label;
  final String? hint;
  final bool enabled;
  final bool loading;

  const A11yButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.label,
    this.hint,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled && !loading,
      label: loading ? '${A11yLabels.loading}, $label' : label,
      hint: hint,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// An image with proper semantics for screen readers.
class A11yImage extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isDecorative;

  const A11yImage({
    super.key,
    required this.child,
    required this.label,
    this.isDecorative = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDecorative) {
      return ExcludeSemantics(child: child);
    }
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// A toggle/switch with proper semantics.
class A11yToggle extends StatelessWidget {
  final Widget child;
  final String label;
  final bool value;
  final String? hint;

  const A11yToggle({
    super.key,
    required this.child,
    required this.label,
    required this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: '$label, ${A11yLabels.switchState(value)}',
      hint: hint ?? A11yHints.tapToToggle,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// A text field with enhanced semantics.
class A11yTextField extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final String? errorText;
  final bool isRequired;
  final bool isPassword;

  const A11yTextField({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.errorText,
    this.isRequired = false,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    final String semanticLabel = [
      label,
      if (isRequired) 'required',
      if (isPassword) 'password field',
      if (errorText != null) 'error: $errorText',
    ].join(', ');

    return Semantics(
      textField: true,
      label: semanticLabel,
      hint: hint,
      child: child,
    );
  }
}

/// A header/heading with proper semantics.
class A11yHeading extends StatelessWidget {
  final Widget child;
  final String label;

  const A11yHeading({
    super.key,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: label,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// A link with proper semantics.
class A11yLink extends StatelessWidget {
  final Widget child;
  final String label;
  final String? destination;

  const A11yLink({
    super.key,
    required this.child,
    required this.label,
    this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: label,
      hint: destination != null
          ? A11yHints.tapToOpen(destination!)
          : A11yHints.tapToView,
      excludeSemantics: true,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOCUS MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

/// Helper for managing focus order and traversal.
class A11yFocus {
  A11yFocus._();

  /// Request focus on a specific node after the current frame.
  static void requestFocus(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      node.requestFocus();
    });
  }

  /// Move focus to the next focusable element.
  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to the previous focusable element.
  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Unfocus the current element.
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MINIMUM TAP TARGET SIZE
// ═══════════════════════════════════════════════════════════════════════════

/// WCAG minimum touch target size (44x44 logical pixels).
const double kMinTapTargetSize = 44.0;

/// Ensure a widget meets minimum tap target size.
class A11yTapTarget extends StatelessWidget {
  final Widget child;
  final double minSize;

  const A11yTapTarget({
    super.key,
    required this.child,
    this.minSize = kMinTapTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }
}
