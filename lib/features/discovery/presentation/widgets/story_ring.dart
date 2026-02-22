import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/blur.dart';

/// A ring around an avatar indicating the user has active stories.
/// Multiple segments show multiple stories.
class StoryRing extends StatelessWidget {
  const StoryRing({
    super.key,
    required this.child,
    this.stories = const [],
    this.size = 60,
    this.strokeWidth = 3,
    this.gap = 4,
    this.hasUnseenStories = false,
    this.onTap,
  });

  /// The avatar or content to display inside the ring.
  final Widget child;

  /// List of active stories.
  final List<ProfileStory> stories;

  /// Size of the ring.
  final double size;

  /// Stroke width of the ring.
  final double strokeWidth;

  /// Gap between the ring and the child.
  final double gap;

  /// Whether there are unseen stories.
  final bool hasUnseenStories;

  /// Callback when the ring is tapped.
  final VoidCallback? onTap;

  /// Get active (non-expired) stories.
  List<ProfileStory> get activeStories => stories.active;

  /// Check if there are any active stories.
  bool get hasStories => activeStories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasStories) {
      return SizedBox(width: size, height: size, child: child);
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Story ring
              CustomPaint(
                size: Size(size, size),
                painter: _StoryRingPainter(
                  storyCount: activeStories.length,
                  hasUnseenStories: hasUnseenStories,
                  strokeWidth: strokeWidth,
                ),
              ),
              // Avatar with gap
              Padding(padding: EdgeInsets.all(strokeWidth + gap), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the segmented story ring.
class _StoryRingPainter extends CustomPainter {
  _StoryRingPainter({
    required this.storyCount,
    required this.hasUnseenStories,
    this.strokeWidth = 3,
  });

  final int storyCount;
  final bool hasUnseenStories;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Create gradient colors
    final gradientColors = hasUnseenStories
        ? [DsColors.primary, DsColors.secondary, DsColors.primary]
        : [
            DsColors.textMutedLight,
            DsColors.offlineIndicator,
            DsColors.textMutedLight,
          ];

    final gradient = SweepGradient(
      colors: gradientColors,
      startAngle: 0,
      endAngle: math.pi * 2,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (storyCount == 1) {
      // Single story - draw full circle
      canvas.drawCircle(center, radius, paint);
    } else {
      // Multiple stories - draw segments with gaps
      const gapAngle = math.pi / 36; // Small gap between segments
      final totalGapAngle = gapAngle * storyCount;
      final arcAngle = (math.pi * 2 - totalGapAngle) / storyCount;

      for (int i = 0; i < storyCount; i++) {
        final startAngle = -math.pi / 2 + (i * (arcAngle + gapAngle));
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          arcAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StoryRingPainter oldDelegate) {
    return oldDelegate.storyCount != storyCount ||
        oldDelegate.hasUnseenStories != hasUnseenStories ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// A badge indicating a user has stories, shown on profile cards.
class StoryBadge extends StatelessWidget {
  const StoryBadge({
    super.key,
    required this.storyCount,
    this.hasUnseen = false,
    this.compact = false,
  });

  final int storyCount;
  final bool hasUnseen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (storyCount <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: hasUnseen
                  ? [
                      DsColors.primary.withValues(alpha: 0.7),
                      DsColors.secondary.withValues(alpha: 0.5),
                    ]
                  : [
                      DsColors.ink300.withValues(alpha: 0.6),
                      DsColors.ink200.withValues(alpha: 0.4),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DsColors.surfaceLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: DsColors.surfaceLight,
                size: compact ? 10 : 12,
              ),
              const SizedBox(width: 3),
              Text(
                AppLocalizations.of(context).storyCountStr(storyCount),
                style: TextStyle(
                  color: DsColors.surfaceLight,
                  fontSize: compact ? 9 : 11,
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

/// Animated story ring with a shimmer effect for unseen stories.
class AnimatedStoryRing extends StatefulWidget {
  const AnimatedStoryRing({
    super.key,
    required this.child,
    this.stories = const [],
    this.size = 60,
    this.strokeWidth = 3,
    this.gap = 4,
    this.hasUnseenStories = false,
    this.onTap,
  });

  final Widget child;
  final List<ProfileStory> stories;
  final double size;
  final double strokeWidth;
  final double gap;
  final bool hasUnseenStories;
  final VoidCallback? onTap;

  @override
  State<AnimatedStoryRing> createState() => _AnimatedStoryRingState();
}

class _AnimatedStoryRingState extends State<AnimatedStoryRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.hasUnseenStories && widget.stories.active.isNotEmpty) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedStoryRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasUnseenStories && widget.stories.active.isNotEmpty) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<ProfileStory> get activeStories => widget.stories.active;
  bool get hasStories => activeStories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasStories) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: widget.child,
      );
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated story ring
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _AnimatedStoryRingPainter(
                      storyCount: activeStories.length,
                      hasUnseenStories: widget.hasUnseenStories,
                      strokeWidth: widget.strokeWidth,
                      animationValue: _controller.value,
                    ),
                  );
                },
              ),
              // Avatar with gap
              Padding(
                padding: EdgeInsets.all(widget.strokeWidth + widget.gap),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated painter with rotating highlight.
class _AnimatedStoryRingPainter extends CustomPainter {
  _AnimatedStoryRingPainter({
    required this.storyCount,
    required this.hasUnseenStories,
    this.strokeWidth = 3,
    this.animationValue = 0,
  });

  final int storyCount;
  final bool hasUnseenStories;
  final double strokeWidth;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Rotate the gradient based on animation
    final rotationAngle = animationValue * math.pi * 2;

    final gradientColors = hasUnseenStories
        ? [
            DsColors.primary,
            DsColors.secondary,
            DsColors.surfaceLight.withValues(alpha: 0.8),
            DsColors.secondary,
            DsColors.primary,
          ]
        : [
            DsColors.textMutedLight,
            DsColors.offlineIndicator,
            DsColors.textMutedLight,
          ];

    final gradient = SweepGradient(
      colors: gradientColors,
      startAngle: rotationAngle,
      endAngle: rotationAngle + math.pi * 2,
      transform: GradientRotation(rotationAngle),
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (storyCount == 1) {
      canvas.drawCircle(center, radius, paint);
    } else {
      const gapAngle = math.pi / 36;
      final totalGapAngle = gapAngle * storyCount;
      final arcAngle = (math.pi * 2 - totalGapAngle) / storyCount;

      for (int i = 0; i < storyCount; i++) {
        final startAngle = -math.pi / 2 + (i * (arcAngle + gapAngle));
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          arcAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedStoryRingPainter oldDelegate) {
    return oldDelegate.storyCount != storyCount ||
        oldDelegate.hasUnseenStories != hasUnseenStories ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.animationValue != animationValue;
  }
}
