import 'package:flutter/material.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

/// Status bar showing upload/sending progress.
class ChatSendStatusBar extends StatelessWidget {
  const ChatSendStatusBar({super.key, required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    switch (state.sendStatus) {
      case SendStatus.uploadingAttachment:
        return Container(
          width: double.infinity,
          color: Colors.blueGrey.withAlpha((0.08 * 255).round()),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              DsGap.smH,
              Expanded(
                child: Text(
                  'Uploading ${state.uploadingAttachmentName ?? 'attachment'}...',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      case SendStatus.sendingText:
        return const SizedBox(height: 4);
      case SendStatus.idle:
        return const SizedBox.shrink();
    }
  }
}
