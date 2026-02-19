import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:flutter/material.dart';

class VideoCallArgs {
  final String currentUserId;
  final String otherUserId;
  final String otherName;

  const VideoCallArgs({
    required this.currentUserId,
    required this.otherUserId,
    required this.otherName,
  });
}

/// Stub implementation of VideoCallScreen.
/// Video calling requires a backend service (WebRTC, Agora, Twilio, etc.).
/// Replace this with your actual video calling implementation.
class VideoCallScreen extends StatelessWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherName;

  const VideoCallScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video call with $otherName'),
        backgroundColor: DsColors.backgroundDark,
      ),
      backgroundColor: DsColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off,
                  size: 80,
                  color: DsColors.surfaceLight.withValues(alpha: 0.54),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Video Calling',
                  style: TextStyle(
                    color: DsColors.surfaceLight,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Video calling is not yet configured.\n\nConnect your video calling backend (WebRTC, Agora, Twilio, etc.) to enable this feature.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DsColors.surfaceLight.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                FloatingActionButton(
                  backgroundColor: DsColors.error,
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'End call',
                  child: const Icon(Icons.call_end),
                ),
                const SizedBox(height: 16),
                Text(
                  'End Call',
                  style: TextStyle(
                    color: DsColors.surfaceLight.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
