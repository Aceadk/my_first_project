import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/features/chat/data/services/voice_recorder_service.dart';

/// A widget for recording voice notes in chat.
class VoiceNoteRecorder extends StatefulWidget {
  const VoiceNoteRecorder({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
    this.maxDuration = const Duration(seconds: 60),
  });

  /// Called when recording is complete with the file path.
  final ValueChanged<String> onRecordingComplete;

  /// Called when recording is cancelled.
  final VoidCallback onCancel;

  /// Maximum recording duration.
  final Duration maxDuration;

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder>
    with TickerProviderStateMixin {
  final _recorderService = VoiceRecorderService();
  bool _isRecording = false;
  bool _hasPermission = false;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription? _durationSub;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _checkPermission();
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _recorderService.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _recorderService.hasPermission();
    if (mounted) {
      setState(() => _hasPermission = hasPermission);
      if (hasPermission) {
        _startRecording();
      } else {
        _requestPermission();
      }
    }
  }

  Future<void> _requestPermission() async {
    final granted = await _recorderService.requestPermission();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (granted) {
        _startRecording();
      } else {
        widget.onCancel();
      }
    }
  }

  Future<void> _startRecording() async {
    HapticFeedback.lightImpact();

    final path = await _recorderService.startRecording();
    if (path == null) {
      if (mounted) widget.onCancel();
      return;
    }

    _durationSub = _recorderService.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _recordingDuration = duration);
      }
    });

    if (mounted) {
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    HapticFeedback.mediumImpact();

    final path = await _recorderService.stopRecording();
    if (path != null && mounted) {
      widget.onRecordingComplete(path);
    } else if (mounted) {
      // Recording was too short
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording too short (minimum 1 second)'),
          duration: Duration(seconds: 2),
        ),
      );
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    HapticFeedback.lightImpact();
    await _recorderService.cancelRecording();
    widget.onCancel();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission && !_isRecording) {
      return _buildPermissionRequest();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DsColors.primary.withValues(alpha: 0.1),
            DsColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(DsRadius.xl),
        border: Border.all(
          color: DsColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            tooltip: 'Cancel',
          ),
          const SizedBox(width: DsSpacing.sm),
          // Recording indicator and waveform
          Expanded(
            child: Row(
              children: [
                // Pulsing record indicator
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withValues(
                          alpha: 0.5 + _pulseController.value * 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(
                              alpha: 0.3 + _pulseController.value * 0.3,
                            ),
                            blurRadius: 8 + _pulseController.value * 4,
                            spreadRadius: _pulseController.value * 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: DsSpacing.sm),
                // Animated waveform
                Expanded(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return _RecordingWaveform(
                        animation: _waveController.value,
                        isRecording: _isRecording,
                      );
                    },
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                // Duration
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          // Send button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DsColors.primary, DsColors.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DsColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Container(
      padding: const EdgeInsets.all(DsSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.mic_off, color: Colors.orange),
          const SizedBox(width: DsSpacing.sm),
          const Expanded(
            child: Text('Microphone permission required'),
          ),
          TextButton(
            onPressed: _requestPermission,
            child: const Text('Grant'),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

/// Animated waveform visualization during recording.
class _RecordingWaveform extends StatelessWidget {
  const _RecordingWaveform({
    required this.animation,
    required this.isRecording,
  });

  final double animation;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    const barCount = 24;
    const barWidth = 3.0;
    const gap = 2.0;
    const maxHeight = 28.0;
    const minHeight = 4.0;

    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          // Create wave effect based on animation
          final phase = (i / barCount + animation) % 1.0;
          final sineValue = (phase * 3.14159 * 2).abs();
          final heightFactor = isRecording
              ? 0.3 + (sineValue.abs() % 1) * 0.7
              : 0.3;
          final barHeight = minHeight + (maxHeight - minHeight) * heightFactor;

          return Padding(
            padding: EdgeInsets.only(right: i < barCount - 1 ? gap : 0),
            child: Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DsColors.primary,
                    DsColors.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(barWidth / 2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
