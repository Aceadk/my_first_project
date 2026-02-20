import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Custom pull-to-refresh wrapper with branded styling.
class DsRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;

  const DsRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? DsColors.primary,
      backgroundColor:
          backgroundColor ??
          (isDark ? DsColors.surfaceDark : DsColors.surfaceLight),
      displacement: displacement,
      edgeOffset: edgeOffset,
      strokeWidth: 2.5,
      child: child,
    );
  }
}

/// Custom refresh indicator with gradient styling.
class DsGradientRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const DsGradientRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<DsGradientRefreshIndicator> createState() =>
      _DsGradientRefreshIndicatorState();
}

class _DsGradientRefreshIndicatorState
    extends State<DsGradientRefreshIndicator> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: DsColors.primary,
      backgroundColor: Colors.white,
      child: widget.child,
    );
  }
}

/// A custom scroll physics that enables overscroll for RefreshIndicator
/// even when content doesn't fill the viewport.
class AlwaysScrollableRefreshPhysics extends AlwaysScrollableScrollPhysics {
  const AlwaysScrollableRefreshPhysics({super.parent});

  @override
  AlwaysScrollableRefreshPhysics applyTo(ScrollPhysics? ancestor) {
    return AlwaysScrollableRefreshPhysics(parent: buildParent(ancestor));
  }
}

/// Animated loading indicator with brand colors.
class DsLoadingIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const DsLoadingIndicator({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  State<DsLoadingIndicator> createState() => _DsLoadingIndicatorState();
}

class _DsLoadingIndicatorState extends State<DsLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return SweepGradient(
              colors: const [
                DsColors.primary,
                DsColors.secondary,
                DsColors.primary,
              ],
              transform: GradientRotation(_controller.value * 6.28),
            ).createShader(bounds);
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: widget.strokeWidth,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing dots loading indicator.
class DsPulsingDots extends StatefulWidget {
  final int dotCount;
  final double dotSize;
  final Color? color;

  const DsPulsingDots({
    super.key,
    this.dotCount = 3,
    this.dotSize = 8,
    this.color,
  });

  @override
  State<DsPulsingDots> createState() => _DsPulsingDotsState();
}

class _DsPulsingDotsState extends State<DsPulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? DsColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index / widget.dotCount;
            final animation = (_controller.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (animation - 0.5).abs() * 2));

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.dotSize / 4),
              width: widget.dotSize,
              height: widget.dotSize,
              child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
