import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/chat/domain/repositories/voice_recorder_repository.dart';

/// A widget for recording voice notes in chat with preview functionality.
class VoiceNoteRecorder extends StatefulWidget {
  const VoiceNoteRecorder({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
    this.maxDuration = const Duration(seconds: 60),
  });

  /// Called when recording is complete and user confirms sending.
  final ValueChanged<String> onRecordingComplete;

  /// Called when recording is cancelled.
  final VoidCallback onCancel;

  /// Maximum recording duration.
  final Duration maxDuration;

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

enum _RecorderState { requestingPermission, recording, previewing }

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder>
    with TickerProviderStateMixin {
  late final _recorderService = context.read<VoiceRecorderRepository>();

  _RecorderState _state = _RecorderState.requestingPermission;
  bool _hasPermission = false;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription? _durationSub;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  // Preview state
  String? _recordedFilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playbackDurationSub;

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
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _playbackDurationSub?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _recorderService.cancelRecording();
    _audioPlayer.dispose();
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
      setState(() => _state = _RecorderState.recording);
    }
  }

  Future<void> _stopRecordingAndPreview() async {
    HapticFeedback.mediumImpact();

    final path = await _recorderService.stopRecording();
    if (path != null && mounted) {
      setState(() {
        _recordedFilePath = path;
        _state = _RecorderState.previewing;
      });
      await _initializePreviewPlayer(path);
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

  Future<void> _initializePreviewPlayer(String filePath) async {
    try {
      await _audioPlayer.setFilePath(filePath);

      _playbackDurationSub = _audioPlayer.durationStream.listen((duration) {
        if (duration != null && mounted) {
          setState(() => _playbackDuration = duration);
        }
      });

      _positionSub = _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _playbackPosition = position);
        }
      });

      _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _playbackPosition = Duration.zero;
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
            }
          });
        }
      });
    } catch (e) {
      AppLogger.error('Error initializing preview player: $e');
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  Future<void> _reRecord() async {
    HapticFeedback.lightImpact();
    await _audioPlayer.stop();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _playbackDurationSub?.cancel();
    setState(() {
      _recordedFilePath = null;
      _playbackPosition = Duration.zero;
      _playbackDuration = Duration.zero;
      _recordingDuration = Duration.zero;
      _isPlaying = false;
    });
    _startRecording();
  }

  Future<void> _sendRecording() async {
    HapticFeedback.mediumImpact();
    await _audioPlayer.stop();
    if (_recordedFilePath != null) {
      widget.onRecordingComplete(_recordedFilePath!);
    }
  }

  Future<void> _cancelRecording() async {
    HapticFeedback.lightImpact();
    if (_state == _RecorderState.recording) {
      await _recorderService.cancelRecording();
    } else if (_state == _RecorderState.previewing) {
      await _audioPlayer.stop();
    }
    widget.onCancel();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission && _state == _RecorderState.requestingPermission) {
      return _buildPermissionRequest();
    }

    if (_state == _RecorderState.previewing) {
      return _buildPreviewUI();
    }

    return _buildRecordingUI();
  }

  Widget _buildRecordingUI() {
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
            color: DsColors.error,
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
                        color: DsColors.error.withValues(
                          alpha: 0.5 + _pulseController.value * 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DsColors.error.withValues(
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
                        isRecording: _state == _RecorderState.recording,
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
          // Stop button (to preview)
          Semantics(
            button: true,
            label: 'Stop recording and preview',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _state == _RecorderState.recording
                  ? _stopRecordingAndPreview
                  : null,
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
                  Icons.stop_rounded,
                  color: DsColors.surfaceLight,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _playbackDuration.inMilliseconds > 0
        ? _playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DsColors.success.withValues(alpha: 0.1),
            DsColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(DsRadius.xl),
        border: Border.all(
          color: DsColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview label
          Row(
            children: [
              Icon(
                Icons.headphones_rounded,
                size: 16,
                color: isDark
                    ? DsColors.surfaceLight.withValues(alpha: 0.7)
                    : DsColors.ink900.withValues(alpha: 0.54),
              ),
              const SizedBox(width: 6),
              Text(
                'Preview your voice message',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? DsColors.surfaceLight.withValues(alpha: 0.7)
                      : DsColors.ink900.withValues(alpha: 0.54),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          // Playback controls
          Row(
            children: [
              // Re-record button
              IconButton(
                onPressed: _reRecord,
                icon: const Icon(Icons.refresh_rounded),
                color: DsColors.warning,
                tooltip: 'Re-record',
              ),
              // Play/Pause button
              Semantics(
                button: true,
                label: _isPlaying ? 'Pause preview' : 'Play preview',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: DsColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DsColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: DsColors.surfaceLight,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              // Progress slider
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: DsColors.primary,
                        inactiveTrackColor: DsColors.primary.withValues(
                          alpha: 0.3,
                        ),
                        thumbColor: DsColors.primary,
                        overlayColor: DsColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (value) {
                          final newPosition = Duration(
                            milliseconds:
                                (value * _playbackDuration.inMilliseconds)
                                    .toInt(),
                          );
                          _audioPlayer.seek(newPosition);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.xs,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_playbackPosition),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? DsColors.surfaceLight.withValues(alpha: 0.7)
                                  : DsColors.ink900.withValues(alpha: 0.54),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            _formatDuration(_playbackDuration),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? DsColors.surfaceLight.withValues(
                                      alpha: 0.54,
                                    )
                                  : DsColors.ink900.withValues(alpha: 0.38),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              // Cancel button
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.close_rounded),
                color: DsColors.error.withValues(alpha: 0.8),
                tooltip: 'Cancel',
              ),
              // Send button
              Semantics(
                button: true,
                label: 'Send voice message',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: _sendRecording,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DsColors.success, DsColors.primary],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DsColors.success.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: DsColors.surfaceLight,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
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
          const Icon(Icons.mic_off, color: DsColors.warning),
          const SizedBox(width: DsSpacing.sm),
          const Expanded(child: Text('Microphone permission required')),
          TextButton(onPressed: _requestPermission, child: const Text('Grant')),
          IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.close)),
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
            padding: EdgeInsetsDirectional.only(
              end: i < barCount - 1 ? gap : 0,
            ),
            child: Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [DsColors.primary, DsColors.secondary],
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
