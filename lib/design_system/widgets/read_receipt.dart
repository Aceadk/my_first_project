import 'package:flutter/material.dart';
import 'package:crushhour/core/utils/date_time_formatter.dart';
import '../tokens/colors.dart';

/// Status of a message delivery.
enum MessageStatus {
  /// Message is being sent.
  sending,

  /// Message has been sent to server.
  sent,

  /// Message has been delivered to recipient's device.
  delivered,

  /// Message has been read by recipient.
  read,

  /// Message failed to send.
  failed,
}

/// A read receipt indicator showing message status.
class ReadReceipt extends StatelessWidget {
  const ReadReceipt({
    super.key,
    required this.status,
    this.size = 16.0,
    this.color,
    this.readColor,
    this.showLabel = false,
    this.timestamp,
  });

  /// The status of the message.
  final MessageStatus status;

  /// Size of the icon.
  final double size;

  /// Color for unread status (sent, delivered).
  final Color? color;

  /// Color for read status.
  final Color? readColor;

  /// Whether to show a text label.
  final bool showLabel;

  /// Optional timestamp to display.
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? DsColors.textMutedDark
        : DsColors.textMutedLight;
    final readStatusColor = readColor ?? DsColors.secondary;
    final iconColor = status == MessageStatus.read
        ? readStatusColor
        : (color ?? defaultColor);

    Widget icon;

    switch (status) {
      case MessageStatus.sending:
        icon = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(iconColor),
          ),
        );
        break;

      case MessageStatus.sent:
        icon = Icon(Icons.check, size: size, color: iconColor);
        break;

      case MessageStatus.delivered:
        icon = Stack(
          children: [
            Icon(Icons.check, size: size, color: iconColor),
            Padding(
              padding: EdgeInsetsDirectional.only(start: size * 0.4),
              child: Icon(Icons.check, size: size, color: iconColor),
            ),
          ],
        );
        break;

      case MessageStatus.read:
        icon = Stack(
          children: [
            Icon(Icons.check, size: size, color: iconColor),
            Padding(
              padding: EdgeInsetsDirectional.only(start: size * 0.4),
              child: Icon(Icons.check, size: size, color: iconColor),
            ),
          ],
        );
        break;

      case MessageStatus.failed:
        icon = Icon(Icons.error_outline, size: size, color: DsColors.error);
        break;
    }

    if (!showLabel && timestamp == null) {
      return SizedBox(
        width: status == MessageStatus.delivered || status == MessageStatus.read
            ? size * 1.4
            : size,
        height: size,
        child: icon,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (timestamp != null) ...[
          Text(
            DateTimeFormatter.formatTime(
              timestamp!,
              locale: Localizations.localeOf(context).toString(),
            ),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
          const SizedBox(width: 4),
        ],
        SizedBox(
          width:
              status == MessageStatus.delivered || status == MessageStatus.read
              ? size * 1.4
              : size,
          height: size,
          child: icon,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            _getLabel(),
            style: TextStyle(
              fontSize: 11,
              color: status == MessageStatus.read
                  ? readStatusColor
                  : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight),
            ),
          ),
        ],
      ],
    );
  }

  String _getLabel() {
    switch (status) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }
}

/// An animated read receipt that transitions between states.
class AnimatedReadReceipt extends StatelessWidget {
  const AnimatedReadReceipt({
    super.key,
    required this.status,
    this.size = 16.0,
    this.color,
    this.readColor,
    this.timestamp,
  });

  final MessageStatus status;
  final double size;
  final Color? color;
  final Color? readColor;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: ReadReceipt(
        key: ValueKey(status),
        status: status,
        size: size,
        color: color,
        readColor: readColor,
        timestamp: timestamp,
      ),
    );
  }
}

/// "Seen" text indicator (alternative to checkmarks).
class SeenIndicator extends StatelessWidget {
  const SeenIndicator({super.key, this.seenAt, this.color});

  /// When the message was seen.
  final DateTime? seenAt;

  /// Color of the text.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? DsColors.secondary;

    if (seenAt == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility, size: 12, color: textColor),
        const SizedBox(width: 4),
        Text(
          'Seen',
          style: TextStyle(
            fontSize: 11,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
