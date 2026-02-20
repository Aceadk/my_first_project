import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart' as intl;

/// Helper utilities for accessibility and screen reader support.
class SemanticsHelper {
  SemanticsHelper._();

  /// Wraps a widget with semantic label for screen readers.
  static Widget label({
    required Widget child,
    required String label,
    String? hint,
    bool button = false,
    bool header = false,
    bool image = false,
    bool link = false,
    VoidCallback? onTap,
    bool excludeSemantics = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      image: image,
      link: link,
      onTap: onTap,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }

  /// Creates a semantic container for a group of related elements.
  static Widget group({
    required Widget child,
    required String label,
    bool container = true,
    bool explicitChildNodes = false,
  }) {
    return Semantics(
      label: label,
      container: container,
      explicitChildNodes: explicitChildNodes,
      child: child,
    );
  }

  /// Announces a message to screen readers.
  static void announce(BuildContext context, String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Creates semantic properties for a profile card.
  static String profileCardLabel({
    required String name,
    required int age,
    String? location,
    String? bio,
    bool isVerified = false,
  }) {
    final buffer = StringBuffer('$name, $age years old');
    if (isVerified) buffer.write(', verified profile');
    if (location != null) buffer.write(', from $location');
    if (bio != null && bio.isNotEmpty) buffer.write('. Bio: $bio');
    return buffer.toString();
  }

  /// Creates semantic properties for a chat message.
  static String messageLabel({
    required String senderName,
    required String content,
    required DateTime sentAt,
    required bool isFromMe,
    bool isRead = false,
  }) {
    final time = _formatTime(sentAt);
    final readStatus = isFromMe ? (isRead ? ', read' : ', sent') : '';
    final sender = isFromMe ? 'You' : senderName;
    return '$sender said: $content, $time$readStatus';
  }

  /// Creates semantic properties for a match tile.
  static String matchTileLabel({
    required String name,
    String? lastMessage,
    DateTime? lastMessageTime,
    int unreadCount = 0,
    bool isOnline = false,
  }) {
    final buffer = StringBuffer('Chat with $name');
    if (isOnline) buffer.write(', online now');
    if (unreadCount > 0) buffer.write(', $unreadCount unread messages');
    if (lastMessage != null) {
      buffer.write('. Last message: $lastMessage');
      if (lastMessageTime != null) {
        buffer.write(', ${_formatTime(lastMessageTime)}');
      }
    }
    return buffer.toString();
  }

  /// Creates semantic label for swipe actions.
  static String swipeActionLabel(SwipeAction action) {
    switch (action) {
      case SwipeAction.like:
        return 'Like this profile';
      case SwipeAction.nope:
        return 'Pass on this profile';
      case SwipeAction.superLike:
        return 'Super like this profile';
      case SwipeAction.rewind:
        return 'Undo last swipe';
    }
  }

  /// Creates semantic label for navigation items.
  static String navItemLabel({
    required String title,
    int badgeCount = 0,
    bool isSelected = false,
  }) {
    final buffer = StringBuffer(title);
    if (badgeCount > 0) {
      buffer.write(', $badgeCount new');
    }
    if (isSelected) {
      buffer.write(', selected');
    }
    return buffer.toString();
  }

  static String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final locale = intl.Intl.getCurrentLocale();

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return intl.DateFormat.yMd(locale).format(dateTime);
  }
}

/// Swipe actions for accessibility labels.
enum SwipeAction { like, nope, superLike, rewind }

/// Extension to add semantic labels easily.
extension SemanticWidgetExtension on Widget {
  /// Wraps this widget with a semantic label.
  Widget withSemantics({
    required String label,
    String? hint,
    bool button = false,
    bool header = false,
    bool image = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      image: image,
      onTap: onTap,
      excludeSemantics: true,
      child: this,
    );
  }

  /// Excludes this widget from semantics tree.
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }
}
