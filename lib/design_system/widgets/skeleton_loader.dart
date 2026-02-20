import 'package:flutter/material.dart';

/// Backward-compatible shimmer wrapper used by legacy tests/components.
class DsShimmer extends StatefulWidget {
  const DsShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Duration duration;

  @override
  State<DsShimmer> createState() => _DsShimmerState();
}

class _DsShimmerState extends State<DsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (2.0 * t), 0),
              end: Alignment(1.0 + (2.0 * t), 0),
              colors: const <Color>[
                Color(0x1FFFFFFF),
                Color(0x52FFFFFF),
                Color(0x1FFFFFFF),
              ],
              stops: const <double>[0.1, 0.45, 0.9],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      decoration: BoxDecoration(
        color: const Color(0x2AFFFFFF),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      constraints: BoxConstraints(maxWidth: size, maxHeight: size),
      decoration: const BoxDecoration(
        color: Color(0x2AFFFFFF),
        shape: BoxShape.circle,
      ),
    );
  }
}

class SkeletonChatTile extends StatelessWidget {
  const SkeletonChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          SkeletonCircle(size: 56),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonBox(width: 110, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 180, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonMatchCard extends StatelessWidget {
  const SkeletonMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 96,
      child: Column(
        children: <Widget>[
          SkeletonCircle(size: 80),
          SizedBox(height: 8),
          SkeletonBox(width: 64, height: 14),
        ],
      ),
    );
  }
}

class SkeletonProfileCard extends StatelessWidget {
  const SkeletonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SkeletonBox(width: double.infinity, height: 220),
        SizedBox(height: 12),
        SkeletonBox(width: 180, height: 24),
        SizedBox(height: 8),
        SkeletonBox(width: double.infinity, height: 16),
        SizedBox(height: 8),
        SkeletonBox(width: double.infinity, height: 16),
      ],
    );
  }
}
