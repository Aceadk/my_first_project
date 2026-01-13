import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/calls/data/models/call.dart';
import 'package:crushhour/features/calls/data/services/call_service.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_bloc.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_event.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_state.dart' as bloc_state;
import 'package:crushhour/design_system/design_system.dart';

/// Full-featured call screen with CallService integration.
class CallScreen extends StatefulWidget {
  final String matchId;
  final bool isVideoCall;
  final String? matchName;
  final String? matchPhotoUrl;

  const CallScreen({
    super.key,
    required this.matchId,
    required this.isVideoCall,
    this.matchName,
    this.matchPhotoUrl,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  final _callService = CallService.instance;
  StreamSubscription<Call>? _callSubscription;
  StreamSubscription<CallUIState>? _stateSubscription;

  Call? _currentCall;
  CallUIState _uiState = CallUIState.idle;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _subscribeToCallUpdates();
    _initiateCall();
  }

  void _subscribeToCallUpdates() {
    _callSubscription = _callService.callStream.listen((call) {
      if (mounted) {
        setState(() => _currentCall = call);
      }
    });

    _stateSubscription = _callService.callStateStream.listen((state) {
      if (mounted) {
        setState(() => _uiState = state);
        if (state == CallUIState.ended) {
          // Auto-close after showing end state
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    });
  }

  Future<void> _initiateCall() async {
    try {
      // In a real app, you'd get the current user ID from auth
      await _callService.initiateCall(
        callerId: 'current_user',
        receiverId: widget.matchId,
        type: widget.isVideoCall ? CallType.video : CallType.audio,
        receiverName: widget.matchName,
        receiverPhotoUrl: widget.matchPhotoUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _stateSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocListener<CallBloc, bloc_state.CallState>(
          listener: (context, state) {
            if (state.status == bloc_state.CallStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'Call error')),
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient
              _buildBackground(),

              // Main content
              Column(
                children: [
                  const SizedBox(height: 60),
                  // Call status and user info
                  _buildCallInfo(),
                  const Spacer(),
                  // Call controls
                  _buildCallControls(),
                  const SizedBox(height: 40),
                ],
              ),

              // Video placeholder (for video calls)
              if (widget.isVideoCall && _uiState == CallUIState.connected)
                _buildVideoPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DsColors.primary.withValues(alpha: 0.3),
            Colors.black,
            Colors.black,
          ],
        ),
      ),
    );
  }

  Widget _buildCallInfo() {
    final name = widget.matchName ?? 'Unknown';
    final status = _getStatusText();

    return Column(
      children: [
        // Avatar with pulse animation during ringing
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = _uiState == CallUIState.outgoing
                ? 1.0 + (_pulseController.value * 0.1)
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: _buildAvatar(),
        ),
        const SizedBox(height: 24),
        // Name
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Status
        Text(
          status,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        // Duration (when connected)
        if (_uiState == CallUIState.connected && _currentCall != null) ...[
          const SizedBox(height: 8),
          Text(
            _currentCall!.durationDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: DsColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 57,
        backgroundColor: DsColors.primary.withValues(alpha: 0.3),
        backgroundImage: widget.matchPhotoUrl != null
            ? NetworkImage(widget.matchPhotoUrl!)
            : null,
        child: widget.matchPhotoUrl == null
            ? Text(
                widget.matchName?.isNotEmpty == true
                    ? widget.matchName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCallControls() {
    final isMuted = _callService.isMuted;
    final isSpeakerOn = _callService.isSpeakerOn;
    final isVideoEnabled = _callService.isVideoEnabled;

    return Column(
      children: [
        // Secondary controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: isMuted ? Icons.mic_off : Icons.mic,
              label: isMuted ? 'Unmute' : 'Mute',
              onPressed: () {
                _callService.toggleMute();
                setState(() {});
              },
              isActive: isMuted,
            ),
            const SizedBox(width: 24),
            _ControlButton(
              icon: isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              label: 'Speaker',
              onPressed: () {
                _callService.toggleSpeaker();
                setState(() {});
              },
              isActive: isSpeakerOn,
            ),
            if (widget.isVideoCall) ...[
              const SizedBox(width: 24),
              _ControlButton(
                icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                label: isVideoEnabled ? 'Video' : 'Video Off',
                onPressed: () {
                  _callService.toggleVideo();
                  setState(() {});
                },
                isActive: !isVideoEnabled,
              ),
              const SizedBox(width: 24),
              _ControlButton(
                icon: Icons.flip_camera_ios,
                label: 'Flip',
                onPressed: () {
                  _callService.switchCamera();
                  setState(() {});
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 40),
        // End call button
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'End Call',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
    // In a real implementation, this would show the video streams
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, color: Colors.white54, size: 32),
              SizedBox(height: 4),
              Text(
                'You',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_uiState) {
      case CallUIState.idle:
        return 'Initiating...';
      case CallUIState.outgoing:
        return 'Ringing...';
      case CallUIState.incoming:
        return 'Incoming call...';
      case CallUIState.connecting:
        return 'Connecting...';
      case CallUIState.connected:
        return widget.isVideoCall ? 'Video Call' : 'Voice Call';
      case CallUIState.ended:
        final reason = _currentCall?.endReason;
        return reason?.displayText ?? 'Call ended';
    }
  }

  void _endCall() {
    _callService.endCall();
    context.read<CallBloc>().add(CallEnded());
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
