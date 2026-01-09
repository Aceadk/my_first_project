import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/call/call_bloc.dart';
import '../../logic/call/call_event.dart';
import '../../logic/call/call_state.dart';

/// Stub implementation of CallScreen.
/// Video calling requires a backend service (e.g., Agora, Twilio, WebRTC).
/// Replace this with your actual video calling implementation.
class CallScreen extends StatelessWidget {
  final String matchId;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.matchId,
    required this.isVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isVideoCall ? Icons.videocam_off : Icons.phone_disabled,
                      size: 80,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isVideoCall ? 'Video Calling' : 'Voice Calling',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Video/voice calling is not yet configured.\n\nConnect your video calling backend (Agora, Twilio, WebRTC, etc.) to enable this feature.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    FloatingActionButton(
                      backgroundColor: Colors.red,
                      onPressed: () {
                        context.read<CallBloc>().add(CallEnded());
                        Navigator.pop(context);
                      },
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
            );
          },
        ),
      ),
    );
  }
}
