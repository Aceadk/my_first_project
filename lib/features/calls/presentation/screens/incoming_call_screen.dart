import 'dart:async';

import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/calls/domain/models/call.dart';
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/calls/presentation/screens/call_screen.dart';
import 'package:crushhour/shared/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IncomingCallScreenArgs {
  const IncomingCallScreenArgs({required this.incomingCall});

  final Call incomingCall;
}

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.incomingCall,
    this.ringTimeout = Call.ringTimeout,
    this.onAccepted,
    this.onDeclined,
    this.onTimedOut,
  });

  final Call incomingCall;
  final Duration ringTimeout;
  final Future<void> Function(Call call, CallType selectedType)? onAccepted;
  final Future<void> Function(Call call)? onDeclined;
  final Future<void> Function(Call call)? onTimedOut;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late final _callService = context.read<CallManagerRepository>();

  StreamSubscription<Call>? _callSubscription;
  StreamSubscription<CallUIState>? _stateSubscription;
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  late AnimationController _pulseController;

  Call? _incomingCall;
  int _secondsRemaining = 0;
  double _slideProgress = 0;
  bool _isActionInFlight = false;

  @override
  void initState() {
    super.initState();
    _incomingCall = widget.incomingCall;
    _secondsRemaining = widget.ringTimeout.inSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _subscribeToCallUpdates();
    _startTimeout();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _stateSubscription?.cancel();
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _subscribeToCallUpdates() {
    _callSubscription = _callService.callStream.listen((call) {
      if (!mounted || call.id != _incomingCall?.id) return;
      setState(() => _incomingCall = call);
    });

    _stateSubscription = _callService.callStateStream.listen((state) {
      if (!mounted || _isActionInFlight) return;
      if (state == CallUIState.ended) {
        _dismiss();
      }
    });
  }

  void _startTimeout() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _secondsRemaining <= 0) return;
      setState(() => _secondsRemaining--);
    });

    _timeoutTimer = Timer(widget.ringTimeout, () async {
      if (!mounted || _isActionInFlight) return;
      final call = _incomingCall ?? widget.incomingCall;
      if (widget.onTimedOut != null) {
        await widget.onTimedOut!(call);
      }
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(CrushRoutes.home);
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _accept(CallType selectedType) async {
    if (_isActionInFlight) return;
    setState(() {
      _isActionInFlight = true;
      _slideProgress = 1;
    });
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    DsHaptics.success();

    await _callService.acceptCall(asType: selectedType);
    final acceptedCall =
        _callService.activeCall ??
        (_incomingCall ?? widget.incomingCall).copyWith(
          type: selectedType,
          status: CallStatus.ongoing,
          answeredAt: DateTime.now(),
        );

    if (widget.onAccepted != null) {
      await widget.onAccepted!(acceptedCall, selectedType);
      return;
    }

    final args = CallScreenArgs(
      matchId: acceptedCall.callerId,
      isVideoCall: selectedType == CallType.video,
      matchName: acceptedCall.callerName,
      matchPhotoUrl: acceptedCall.callerPhotoUrl,
      isIncoming: true,
    );
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(CrushRoutes.call, extra: args);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CallScreen(
          matchId: args.matchId,
          isVideoCall: args.isVideoCall,
          matchName: args.matchName,
          matchPhotoUrl: args.matchPhotoUrl,
          isIncoming: args.isIncoming,
        ),
      ),
    );
  }

  Future<void> _decline() async {
    if (_isActionInFlight) return;
    setState(() => _isActionInFlight = true);
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    DsHaptics.medium();
    await _callService.declineCall();
    final declinedCall = _incomingCall ?? widget.incomingCall;
    if (widget.onDeclined != null) {
      await widget.onDeclined!(declinedCall);
    }
    if (mounted) _dismiss();
  }

  void _onSlideUpdate(double delta, double maxOffset) {
    if (_isActionInFlight) return;
    final next = (_slideProgress + (delta / maxOffset)).clamp(0.0, 1.0);
    setState(() => _slideProgress = next);
  }

  void _onSlideEnd(CallType selectedType) {
    if (_slideProgress >= 0.88) {
      _accept(selectedType);
      return;
    }
    setState(() => _slideProgress = 0);
  }

  @override
  Widget build(BuildContext context) {
    final call = _incomingCall ?? widget.incomingCall;
    final isVideoCall = call.type == CallType.video;
    final callerName = call.callerName?.trim().isNotEmpty == true
        ? call.callerName!.trim()
        : 'Unknown caller';
    final callerPhoto = call.callerPhotoUrl;

    return Scaffold(
      backgroundColor: DsColors.ink900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                isVideoCall ? 'Incoming video call' : 'Incoming audio call',
                style: TextStyle(
                  color: DsColors.surfaceLight.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Auto-dismisses in ${_secondsRemaining.clamp(0, 999)}s',
                key: const Key('incoming_timeout_text'),
                style: TextStyle(
                  color: DsColors.surfaceLight.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1 + (_pulseController.value * 0.08);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DsColors.primary.withValues(alpha: 0.42),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DsColors.primary.withValues(alpha: 0.3),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: callerPhoto != null
                        ? CachedImage(imageUrl: callerPhoto, fit: BoxFit.cover)
                        : Container(
                            color: DsColors.primary.withValues(alpha: 0.25),
                            alignment: Alignment.center,
                            child: Text(
                              callerName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: DsColors.surfaceLight,
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                callerName,
                key: const Key('incoming_caller_name'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DsColors.surfaceLight,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isVideoCall
                    ? 'Choose how to answer this call'
                    : 'Swipe to answer or use quick actions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DsColors.surfaceLight.withValues(alpha: 0.72),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              _buildSlideToAnswer(
                isVideoCall ? CallType.video : CallType.audio,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    key: const Key('incoming_decline_button'),
                    label: 'Decline',
                    icon: Icons.call_end_rounded,
                    background: DsColors.error,
                    onPressed: _decline,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    key: const Key('incoming_accept_audio_button'),
                    label: 'Audio',
                    icon: Icons.call_rounded,
                    background: DsColors.success,
                    onPressed: () => _accept(CallType.audio),
                  ),
                  if (isVideoCall) ...[
                    const SizedBox(width: 12),
                    _buildActionButton(
                      key: const Key('incoming_accept_video_button'),
                      label: 'Video',
                      icon: Icons.videocam_rounded,
                      background: DsColors.primary,
                      onPressed: () => _accept(CallType.video),
                    ),
                  ],
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideToAnswer(CallType selectedType) {
    return Container(
      key: const Key('incoming_slide_track'),
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: DsColors.surfaceLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: DsColors.surfaceLight.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const knobSize = 56.0;
          const outerPadding = 4.0;
          final maxOffset =
              constraints.maxWidth - knobSize - (outerPadding * 2);
          final offset = _slideProgress * maxOffset;

          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  'Slide to answer',
                  style: TextStyle(
                    color: DsColors.surfaceLight.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PositionedDirectional(
                start: outerPadding + offset,
                top: outerPadding,
                child: GestureDetector(
                  key: const Key('incoming_slide_knob'),
                  onHorizontalDragUpdate: (details) {
                    _onSlideUpdate(details.delta.dx, maxOffset);
                  },
                  onHorizontalDragEnd: (_) => _onSlideEnd(selectedType),
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: const BoxDecoration(
                      color: DsColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: DsColors.surfaceLight,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required Key key,
    required String label,
    required IconData icon,
    required Color background,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          key: key,
          onPressed: _isActionInFlight ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: DsColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
