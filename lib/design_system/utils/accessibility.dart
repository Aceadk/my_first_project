import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for improving screen reader support.
class DsAccessibility {
  DsAccessibility._();

  // ==========================================================================
  // WCAG CONTRAST RATIOS
  // ==========================================================================

  /// WCAG AA minimum contrast for normal text (4.5:1)
  static const double contrastAA = 4.5;

  /// WCAG AA minimum contrast for large text (3.0:1)
  static const double contrastAALarge = 3.0;

  /// WCAG AAA minimum contrast for normal text (7.0:1)
  static const double contrastAAA = 7.0;

  /// WCAG AAA minimum contrast for large text (4.5:1)
  static const double contrastAAALarge = 4.5;

  /// Calculate contrast ratio between two colors.
  /// Returns a value between 1 and 21.
  static double contrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast meets WCAG AA for normal text.
  static bool meetsContrastAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= contrastAA;
  }

  /// Check if contrast meets WCAG AAA for normal text.
  static bool meetsContrastAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= contrastAAA;
  }

  /// Get an accessible text color (black or white) for a given background.
  static Color accessibleTextColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  // ==========================================================================
  // REDUCED MOTION
  // ==========================================================================

  /// Check if user prefers reduced motion.
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get animation duration respecting reduced motion preference.
  static Duration animationDuration(
    BuildContext context, {
    Duration normal = const Duration(milliseconds: 300),
    Duration reduced = Duration.zero,
  }) {
    return prefersReducedMotion(context) ? reduced : normal;
  }

  // ==========================================================================
  // SCREEN READER ANNOUNCEMENTS
  // ==========================================================================

  /// Announces a message to screen readers.
  static void announce(BuildContext context, String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Announces a message after a brief delay (useful after navigation).
  static void announceDelayed(BuildContext context, String message,
      {Duration delay = const Duration(milliseconds: 500)}) {
    Future.delayed(delay, () {
      // ignore: deprecated_member_use
      SemanticsService.announce(message, TextDirection.ltr);
    });
  }

  /// Common semantic labels for dating app actions.
  static const String likeProfile = 'Like this profile';
  static const String passProfile = 'Pass on this profile';
  static const String superLikeProfile = 'Super like this profile';
  static const String sendMessage = 'Send a message';
  static const String viewProfile = 'View full profile';
  static const String goBack = 'Go back';
  static const String openSettings = 'Open settings';
  static const String openMenu = 'Open menu';
  static const String refresh = 'Refresh';
  static const String search = 'Search';
  static const String filter = 'Filter options';
  static const String startCall = 'Start voice call';
  static const String startVideoCall = 'Start video call';
  static const String unmatch = 'Unmatch with this person';
  static const String block = 'Block this person';
  static const String report = 'Report this person';
}

/// Widget that excludes its child from semantics tree.
/// Useful for decorative elements.
class ExcludeSemantics extends StatelessWidget {
  const ExcludeSemantics({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: child,
    );
  }
}

/// Widget that merges multiple semantic nodes into one.
/// Useful for complex widgets that should be read as a single unit.
class MergeSemantics extends StatelessWidget {
  const MergeSemantics({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: child,
    );
  }
}

/// Adds semantic label to any widget.
class SemanticLabel extends StatelessWidget {
  const SemanticLabel({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.isButton = false,
    this.isHeader = false,
    this.isImage = false,
    this.isLiveRegion = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final bool isButton;
  final bool isHeader;
  final bool isImage;
  final bool isLiveRegion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      image: isImage,
      liveRegion: isLiveRegion,
      child: child,
    );
  }
}

/// Extension to easily add accessibility labels to widgets.
extension AccessibilityExtension on Widget {
  /// Wrap with semantic label.
  Widget withSemantics({
    required String label,
    String? hint,
    bool isButton = false,
    bool isHeader = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      child: this,
    );
  }

  /// Exclude from semantics tree (for decorative elements).
  Widget excludeSemantics() {
    return Semantics(
      excludeSemantics: true,
      child: this,
    );
  }

  /// Mark as a live region for dynamic updates.
  Widget asLiveRegion({required String label}) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: this,
    );
  }
}

/// Semantic wrapper for profile cards in the deck.
class SemanticProfileCard extends StatelessWidget {
  const SemanticProfileCard({
    super.key,
    required this.name,
    required this.age,
    required this.child,
    this.distance,
    this.bio,
  });

  final String name;
  final int age;
  final Widget child;
  final String? distance;
  final String? bio;

  @override
  Widget build(BuildContext context) {
    final label = StringBuffer('Profile of $name, $age years old');
    if (distance != null) {
      label.write(', $distance away');
    }
    if (bio != null && bio!.isNotEmpty) {
      label.write('. Bio: $bio');
    }

    return Semantics(
      label: label.toString(),
      hint: 'Swipe right to like, swipe left to pass, or tap for more details',
      child: child,
    );
  }
}

/// Semantic wrapper for match tiles.
class SemanticMatchTile extends StatelessWidget {
  const SemanticMatchTile({
    super.key,
    required this.name,
    required this.child,
    this.lastMessage,
    this.isOnline = false,
    this.unreadCount = 0,
  });

  final String name;
  final Widget child;
  final String? lastMessage;
  final bool isOnline;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final label = StringBuffer('Chat with $name');
    if (isOnline) {
      label.write(', online');
    }
    if (unreadCount > 0) {
      label.write(', $unreadCount unread messages');
    }
    if (lastMessage != null) {
      label.write('. Last message: $lastMessage');
    }

    return Semantics(
      label: label.toString(),
      hint: 'Double tap to open chat',
      button: true,
      child: child,
    );
  }
}

/// Accessible progress indicator with label.
class SemanticProgress extends StatelessWidget {
  const SemanticProgress({
    super.key,
    required this.value,
    required this.label,
    this.child,
  });

  final double value;
  final String label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final percentLabel = '${(value * 100).round()}% $label';

    return Semantics(
      label: percentLabel,
      value: '${(value * 100).round()}%',
      child: child ??
          LinearProgressIndicator(
            value: value,
          ),
    );
  }
}

/// Semantic wrapper for loading states with proper announcements.
class SemanticLoading extends StatelessWidget {
  const SemanticLoading({
    super.key,
    required this.label,
    required this.child,
    this.isLoading = true,
  });

  final String label;
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isLoading ? label : null,
      liveRegion: isLoading,
      enabled: !isLoading,
      child: child,
    );
  }
}

/// Semantic wrapper for dialogs and modals.
class SemanticDialog extends StatelessWidget {
  const SemanticDialog({
    super.key,
    required this.title,
    required this.child,
    this.isAlert = false,
  });

  final String title;
  final Widget child;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      namesRoute: true,
      scopesRoute: true,
      explicitChildNodes: true,
      child: child,
    );
  }
}

/// Semantic wrapper for buttons ensuring proper tap target.
class SemanticButton extends StatelessWidget {
  const SemanticButton({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.onTap,
    this.enabled = true,
    this.minSize = 44.0,
  });

  final String label;
  final Widget child;
  final String? hint;
  final VoidCallback? onTap;
  final bool enabled;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minSize,
          minHeight: minSize,
        ),
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      ),
    );
  }
}

/// Semantic wrapper for images.
class SemanticImage extends StatelessWidget {
  const SemanticImage({
    super.key,
    required this.label,
    required this.child,
    this.isDecorative = false,
  });

  final String label;
  final Widget child;
  final bool isDecorative;

  @override
  Widget build(BuildContext context) {
    if (isDecorative) {
      return Semantics(
        excludeSemantics: true,
        child: child,
      );
    }

    return Semantics(
      label: label,
      image: true,
      child: child,
    );
  }
}

/// Focus traversal group for managing keyboard navigation order.
class AccessibleFocusGroup extends StatelessWidget {
  const AccessibleFocusGroup({
    super.key,
    required this.children,
    this.policy,
  });

  final List<Widget> children;
  final FocusTraversalPolicy? policy;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// A widget that provides a visible focus indicator.
class FocusIndicator extends StatelessWidget {
  const FocusIndicator({
    super.key,
    required this.child,
    this.focusColor,
    this.borderRadius = 8.0,
    this.borderWidth = 2.0,
  });

  final Widget child;
  final Color? focusColor;
  final double borderRadius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          final color =
              focusColor ?? Theme.of(context).colorScheme.primary;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: hasFocus
                  ? Border.all(color: color, width: borderWidth)
                  : null,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// Skip link for keyboard navigation (commonly at top of page).
class SkipToContentLink extends StatelessWidget {
  const SkipToContentLink({
    super.key,
    required this.targetKey,
    this.label = 'Skip to main content',
  });

  final GlobalKey targetKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Focus(
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;

            // Only visible when focused (via keyboard)
            if (!hasFocus) {
              return const SizedBox.shrink();
            }

            return Material(
              color: Theme.of(context).colorScheme.primary,
              child: InkWell(
                onTap: () {
                  // Scroll to target and focus it
                  final targetContext = targetKey.currentContext;
                  if (targetContext != null) {
                    Scrollable.ensureVisible(
                      targetContext,
                      duration: const Duration(milliseconds: 300),
                    );
                    FocusScope.of(context).requestFocus(FocusNode());
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
