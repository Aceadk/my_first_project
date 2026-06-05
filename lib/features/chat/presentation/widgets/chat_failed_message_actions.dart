import 'package:flutter/material.dart';

import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

/// Accessible "failed to send" row with Retry / Delete actions (CHAT-UI-003).
///
/// The failure is communicated with an icon **and** a text label (never colour
/// alone), and each action is a real button with a ≥48dp (`kMinInteractiveDimension`)
/// tap target and an explicit screen-reader label, so a failed send is clearly
/// visible and recoverable for all users.
class ChatFailedMessageActions extends StatelessWidget {
  const ChatFailedMessageActions({
    super.key,
    required this.onRetry,
    required this.onDiscard,
  });

  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, end: 8, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 14, color: DsColors.error),
          DsGap.xsH,
          const Flexible(
            child: Text(
              'Failed to send',
              style: TextStyle(fontSize: 11, color: DsColors.error),
            ),
          ),
          DsGap.xsH,
          _FailedActionButton(
            label: 'Retry',
            semanticLabel: 'Retry sending message',
            color: DsColors.info,
            onTap: onRetry,
          ),
          _FailedActionButton(
            label: 'Delete',
            semanticLabel: 'Delete failed message',
            color: DsColors.error,
            onTap: onDiscard,
          ),
        ],
      ),
    );
  }
}

class _FailedActionButton extends StatelessWidget {
  const _FailedActionButton({
    required this.label,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
            minWidth: kMinInteractiveDimension,
          ),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
