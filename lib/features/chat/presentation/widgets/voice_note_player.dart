import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

/// A player widget for voice notes in chat messages.
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.audioUrl,
    this.isFromCurrentUser = false,
    this.isLocal = false,
    this.compact = false,
  });

  /// URL or file path of the audio.
  final String audioUrl;

  /// Whether this message is from the current user.
  final bool isFromCurrentUser;

  /// Whether the audio is a local file path.
  final bool isLocal;

  /// Compact mode for smaller display.
  final bool compact;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      if (widget.isLocal) {
        await _player.setFilePath(widget.audioUrl);
      } else {
        await _player.setUrl(widget.audioUrl);
      }

      _durationSub = _player.durationStream.listen((duration) {
        if (duration != null && mounted) {
          setState(() => _duration = duration);
        }
      });

      _positionSub = _player.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      _stateSub = _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _position = Duration.zero;
              _player.seek(Duration.zero);
              _player.pause();
            }
          });
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isSent = widget.isFromCurrentUser;
    final primaryColor = isSent ? DsColors.surfaceLight : DsColors.primary;
    final bgColor = isSent
        ? DsColors.surfaceLight.withValues(alpha: 0.15)
        : DsColors.primary.withValues(alpha: 0.1);
    final sliderActiveColor = isSent ? DsColors.surfaceLight : DsColors.primary;
    final sliderInactiveColor = isSent
        ? DsColors.surfaceLight.withValues(alpha: 0.3)
        : DsColors.primary.withValues(alpha: 0.3);

    if (_hasError) {
      return Container(
        padding: EdgeInsets.all(widget.compact ? DsSpacing.sm : DsSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(DsRadius.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: primaryColor.withValues(alpha: 0.7),
              size: widget.compact ? 20 : 24,
            ),
            const SizedBox(width: DsSpacing.sm),
            Text(
              'Unable to load audio',
              style: TextStyle(
                color: primaryColor.withValues(alpha: 0.7),
                fontSize: widget.compact ? 12 : 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        minWidth: widget.compact ? 140 : 180,
        maxWidth: widget.compact ? 200 : 260,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? DsSpacing.sm : DsSpacing.md,
        vertical: widget.compact ? DsSpacing.xs : DsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DsRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: widget.compact ? 32 : 40,
              height: widget.compact ? 32 : 40,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: widget.compact ? 14 : 18,
                        height: widget.compact ? 14 : 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isSent ? DsColors.primary : DsColors.surfaceLight,
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: isSent ? DsColors.primary : DsColors.surfaceLight,
                        size: widget.compact ? 18 : 22,
                      ),
              ),
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          // Waveform/Progress bar and duration
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar (simplified waveform)
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: widget.compact ? 3 : 4,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: widget.compact ? 5 : 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: sliderActiveColor,
                    inactiveTrackColor: sliderInactiveColor,
                    thumbColor: sliderActiveColor,
                    overlayColor: sliderActiveColor.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds:
                            (value * _duration.inMilliseconds).toInt(),
                      );
                      _player.seek(newPosition);
                    },
                  ),
                ),
                // Duration text
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          color: primaryColor.withValues(alpha: 0.8),
                          fontSize: widget.compact ? 10 : 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          color: primaryColor.withValues(alpha: 0.6),
                          fontSize: widget.compact ? 10 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple waveform visualization for voice notes.
class VoiceNoteWaveform extends StatelessWidget {
  const VoiceNoteWaveform({
    super.key,
    required this.progress,
    this.barCount = 20,
    this.activeColor = DsColors.primary,
    this.inactiveColor,
    this.height = 24,
    this.barWidth = 3,
    this.gap = 2,
  });

  final double progress;
  final int barCount;
  final Color activeColor;
  final Color? inactiveColor;
  final double height;
  final double barWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final inactive = inactiveColor ?? activeColor.withValues(alpha: 0.3);

    // Generate pseudo-random bar heights for visual interest
    final barHeights = List.generate(barCount, (i) {
      // Use a simple pattern to create variation
      final seed = (i * 7 + 3) % 10;
      return 0.3 + (seed / 10) * 0.7;
    });

    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final isActive = i / barCount <= progress;
          final barHeight = barHeights[i] * height;

          return Padding(
            padding: EdgeInsets.only(right: i < barCount - 1 ? gap : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactive,
                borderRadius: BorderRadius.circular(barWidth / 2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
