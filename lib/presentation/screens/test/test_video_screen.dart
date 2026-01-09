import 'package:flutter/material.dart';

/// Stub implementation of TestVideoScreen.
/// Video calling requires a backend service to be configured.
class TestVideoScreen extends StatelessWidget {
  const TestVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Test')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 24),
              Text(
                'Video Calling Not Configured',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'To enable video calling, connect a video calling backend:\n\n'
                '• Agora RTC\n'
                '• Twilio Video\n'
                '• WebRTC\n'
                '• Daily.co\n\n'
                'See the documentation for setup instructions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
