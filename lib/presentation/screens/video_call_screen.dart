import 'package:flutter/material.dart';

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
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_off,
                  size: 80,
                  color: Colors.white54,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Video Calling',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Video calling is not yet configured.\n\nConnect your video calling backend (WebRTC, Agora, Twilio, etc.) to enable this feature.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.call_end),
                ),
                const SizedBox(height: 16),
                const Text(
                  'End Call',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
