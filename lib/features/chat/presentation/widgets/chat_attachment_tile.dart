import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

/// A tile for displaying chat attachments (video, audio, etc.).
class ChatAttachmentTile extends StatelessWidget {
  const ChatAttachmentTile({
    super.key,
    required this.label,
    required this.url,
    required this.icon,
    this.isLocal = false,
  });

  final String label;
  final String url;
  final IconData icon;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launch(context, url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DsColors.ink900.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: DsColors.surfaceLight.withValues(alpha: 0.7)),
            DsGap.xsH,
            Text(
              label,
              style: const TextStyle(
                decoration: TextDecoration.underline,
                color: DsColors.surfaceLight,
              ),
            ),
            if (isLocal) ...[
              DsGap.xsH,
              const Icon(Icons.check_circle, size: 14, color: DsColors.success),
            ],
          ],
        ),
      ),
    );
  }

  void _launch(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);

    // For local files, show a message that it's stored locally
    if (isLocal) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Media saved locally on your device.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    final can = await canLaunchUrl(uri);
    if (can) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open attachment.')),
      );
    }
  }
}
