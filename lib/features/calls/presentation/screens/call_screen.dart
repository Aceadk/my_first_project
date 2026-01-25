import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/calls/data/models/call.dart';
import 'package:crushhour/features/calls/data/services/call_service.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_bloc.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_event.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_state.dart' as bloc_state;
import 'package:crushhour/design_system/design_system.dart';

class CallScreenArgs {
  final String matchId;
  final bool isVideoCall;
  final String? matchName;
  final String? matchPhotoUrl;

  const CallScreenArgs({
    required this.matchId,
    required this.isVideoCall,
    this.matchName,
    this.matchPhotoUrl,
  });
}

/// Full-featured call screen with CallService integration.
///
/// Features:
/// - Real-time call state management
/// - Glassmorphism UI with modern design patterns
/// - Haptic feedback for all interactions
/// - Animated states for connecting/ringing/connected
/// - Proper caller ID from authenticated user
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
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for avatar during ringing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Ring animation for connecting state
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ringAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );

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

        // Haptic feedback for state changes
        if (state == CallUIState.connected) {
          DsHaptics.success();
        } else if (state == CallUIState.ended) {
          DsHaptics.medium();
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
      // Get the authenticated user's ID from AuthBloc
      final authState = context.read<AuthBloc>().state;
      final currentUserId = authState.user?.id;
      final currentUserName = authState.user?.profile?.name;
      final currentUserPhoto =
          authState.user?.profile?.photoUrls.isNotEmpty == true
              ? authState.user!.profile!.photoUrls.first
              : null;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _callService.initiateCall(
        callerId: currentUserId,
        receiverId: widget.matchId,
        type: widget.isVideoCall ? CallType.video : CallType.audio,
        callerName: currentUserName,
        receiverName: widget.matchName,
        callerPhotoUrl: currentUserPhoto,
        receiverPhotoUrl: widget.matchPhotoUrl,
      );
    } catch (e) {
      if (mounted) {
        DsHaptics.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start call: $e'),
            backgroundColor: DsColors.error,
          ),
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
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocListener<CallBloc, bloc_state.CallState>(
        listener: (context, state) {
          if (state.status == bloc_state.CallStatus.error) {
            DsHaptics.error();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Call error'),
                backgroundColor: DsColors.error,
              ),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background with gradient and blur
            _buildBackground(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Call status and user info
                  _buildCallInfo(),
                  const Spacer(),
                  // Call controls with glass effect
                  _buildCallControls(),
                  const SizedBox(height: 50),
                ],
              ),
            ),

            // Video placeholder (for video calls)
            if (widget.isVideoCall && _uiState == CallUIState.connected)
              _buildVideoPlaceholder(),

            // Connection quality indicator
            if (_uiState == CallUIState.connected)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: _buildConnectionIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DsColors.primary.withValues(alpha: 0.4),
                DsColors.secondary.withValues(alpha: 0.3),
                Colors.black,
                Colors.black,
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
        // Subtle blur overlay for depth
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
        ),
        // Animated gradient orbs
        if (_uiState == CallUIState.outgoing || _uiState == CallUIState.connecting)
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, _) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.15,
                left: MediaQuery.of(context).size.width * 0.2,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DsColors.primary.withValues(
                          alpha: 0.3 * _ringAnimation.value,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCallInfo() {
    final name = widget.matchName ?? 'Unknown';
    final status = _getStatusText();
    final isConnecting =
        _uiState == CallUIState.outgoing || _uiState == CallUIState.connecting;

    return Column(
      children: [
        // Avatar with animated ring effects
        Stack(
          alignment: Alignment.center,
          children: [
            // Animated rings during connecting
            if (isConnecting) ...[
              AnimatedBuilder(
                animation: _ringController,
                builder: (context, _) {
                  return Container(
                    width: 160 * _ringAnimation.value,
                    height: 160 * _ringAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DsColors.primary.withValues(
                          alpha: 0.5 * (1.2 - _ringAnimation.value),
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _ringController,
                builder: (context, _) {
                  final delayed = (_ringController.value + 0.3) % 1.0;
                  final scale = 0.8 + (delayed * 0.4);
                  return Container(
                    width: 160 * scale,
                    height: 160 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DsColors.primary.withValues(
                          alpha: 0.3 * (1.2 - scale),
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
            // Avatar with pulse animation during ringing
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = isConnecting
                    ? 1.0 + (_pulseController.value * 0.05)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: _buildAvatar(),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Name with subtle animation
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Status with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_uiState == CallUIState.connected)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: DsColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              status,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        // Duration (when connected)
        if (_uiState == CallUIState.connected && _currentCall != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isVideoCall ? Icons.videocam : Icons.call,
                  color: DsColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentCall!.durationDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: DsColors.primary.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipOval(
        child: widget.matchPhotoUrl != null
            ? Image.network(
                widget.matchPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
              )
            : _buildAvatarPlaceholder(),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: DsColors.primary.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          widget.matchName?.isNotEmpty == true
              ? widget.matchName![0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    final isMuted = _callService.isMuted;
    final isSpeakerOn = _callService.isSpeakerOn;
    final isVideoEnabled = _callService.isVideoEnabled;

    return Column(
      children: [
        // Glass container for controls
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GlassControlButton(
                    icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: isMuted ? 'Unmute' : 'Mute',
                    onPressed: () {
                      DsHaptics.light();
                      _callService.toggleMute();
                      setState(() {});
                    },
                    isActive: isMuted,
                  ),
                  const SizedBox(width: 20),
                  _GlassControlButton(
                    icon: isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_down_rounded,
                    label: 'Speaker',
                    onPressed: () {
                      DsHaptics.light();
                      _callService.toggleSpeaker();
                      setState(() {});
                    },
                    isActive: isSpeakerOn,
                  ),
                  if (widget.isVideoCall) ...[
                    const SizedBox(width: 20),
                    _GlassControlButton(
                      icon: isVideoEnabled
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: 'Video',
                      onPressed: () {
                        DsHaptics.light();
                        _callService.toggleVideo();
                        setState(() {});
                      },
                      isActive: !isVideoEnabled,
                    ),
                    const SizedBox(width: 20),
                    _GlassControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      onPressed: () {
                        DsHaptics.light();
                        _callService.switchCamera();
                        setState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // End call button
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF5252),
                  Color(0xFFD32F2F),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 110,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_rounded, color: Colors.white54, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'You',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: DsColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'HD',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
    DsHaptics.heavy();
    _callService.endCall();
    context.read<CallBloc>().add(CallEnded());
  }
}

/// Glass-style control button for call actions.
class _GlassControlButton extends StatelessWidget {
  const _GlassControlButton({
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
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
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
