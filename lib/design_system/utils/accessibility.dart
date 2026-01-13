import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for improving screen reader support.
class DsAccessibility {
  DsAccessibility._();

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
