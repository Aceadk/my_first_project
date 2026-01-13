import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/blur.dart';

/// A video player widget for profile videos in the discovery feed.
/// Supports both network URLs and local file paths.
class ProfileVideoPlayer extends StatefulWidget {
  const ProfileVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = true,
    this.showControls = true,
    this.aspectRatio,
    this.onTap,
    this.borderRadius,
  });

  /// URL or path to the video.
  final String videoUrl;

  /// Whether to auto-play when initialized.
  final bool autoPlay;

  /// Whether to loop the video.
  final bool looping;

  /// Whether to show play/pause controls.
  final bool showControls;

  /// Aspect ratio override.
  final double? aspectRatio;

  /// Callback when video is tapped.
  final VoidCallback? onTap;

  /// Border radius for the video container.
  final BorderRadius? borderRadius;

  @override
  State<ProfileVideoPlayer> createState() => _ProfileVideoPlayerState();
}

class _ProfileVideoPlayerState extends State<ProfileVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _showPlayButton = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final uri = Uri.tryParse(widget.videoUrl);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        _controller = VideoPlayerController.networkUrl(uri);
      } else {
        // Local file
        _controller = VideoPlayerController.networkUrl(
          Uri.file(widget.videoUrl),
        );
      }

      await _controller.initialize();
      _controller.setLooping(widget.looping);

      _controller.addListener(_onVideoStateChanged);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.autoPlay) {
          _controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _onVideoStateChanged() {
    if (!mounted) return;
    final playing = _controller.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() {
        _isPlaying = playing;
        if (playing) {
          _showPlayButton = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _controller.pause();
      setState(() => _showPlayButton = true);
    } else {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(DsRadius.lg);

    if (_hasError) {
      return _buildErrorState(borderRadius);
    }

    if (!_isInitialized) {
      return _buildLoadingState(borderRadius);
    }

    final aspectRatio = widget.aspectRatio ??
        (_controller.value.aspectRatio > 0
            ? _controller.value.aspectRatio
            : 9 / 16);

    return GestureDetector(
      onTap: widget.onTap ?? _togglePlayPause,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video
              VideoPlayer(_controller),

              // Progress indicator at bottom
              if (widget.showControls)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _VideoProgressBar(controller: _controller),
                ),

              // Play/pause button overlay
              if (widget.showControls && _showPlayButton)
                Center(
                  child: _GlassPlayButton(
                    isPlaying: _isPlaying,
                    onTap: _togglePlayPause,
                  ),
                ),

              // Video duration badge (top right)
              if (widget.showControls && _isInitialized)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _VideoDurationBadge(controller: _controller),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BorderRadius borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: DsColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BorderRadius borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: Colors.grey.shade900,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                color: Colors.white.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Video unavailable',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
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

/// Glassmorphism-styled play button overlay.
class _GlassPlayButton extends StatelessWidget {
  const _GlassPlayButton({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DsBlur.light,
            sigmaY: DsBlur.light,
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DsGlassColors.surfaceMediumLight,
                  DsGlassColors.surfaceLight,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

/// Video progress bar with glass styling.
class _VideoProgressBar extends StatefulWidget {
  const _VideoProgressBar({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<_VideoProgressBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final duration = value.duration.inMilliseconds;
    final position = value.position.inMilliseconds;
    final progress = duration > 0 ? position / duration : 0.0;

    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.white.withValues(alpha: 0.3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [DsColors.primary, DsColors.secondary],
            ),
          ),
        ),
      ),
    );
  }
}

/// Video duration badge with glass styling.
class _VideoDurationBadge extends StatefulWidget {
  const _VideoDurationBadge({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoDurationBadge> createState() => _VideoDurationBadgeState();
}

class _VideoDurationBadgeState extends State<_VideoDurationBadge> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final remaining = value.duration - value.position;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DsRadius.sm),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(remaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small video indicator badge for profile cards.
class VideoIndicatorBadge extends StatelessWidget {
  const VideoIndicatorBadge({
    super.key,
    required this.videoCount,
    this.compact = false,
  });

  final int videoCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (videoCount <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.round),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DsBlur.light,
          sigmaY: DsBlur.light,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DsColors.secondary.withValues(alpha: 0.6),
                DsColors.primary.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(DsRadius.round),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: compact ? 12 : 14,
              ),
              const SizedBox(width: 4),
              Text(
                '$videoCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
