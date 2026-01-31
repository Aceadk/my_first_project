import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';

/// Shimmer animation for skeleton loading states.
class DsShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const DsShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<DsShimmer> createState() => _DsShimmerState();
}

class _DsShimmerState extends State<DsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? DsColors.skeletonDark : DsColors.skeletonLight;
    final highlightColor = isDark
        ? baseColor.withValues(alpha: 0.5)
        : baseColor.withValues(alpha: 0.3);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Basic skeleton box with configurable dimensions.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = DsRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? DsColors.skeletonDark : DsColors.skeletonLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Circular skeleton for avatars.
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? DsColors.skeletonDark : DsColors.skeletonLight,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton for a chat list item.
class SkeletonChatTile extends StatelessWidget {
  const SkeletonChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SkeletonCircle(size: 56),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 16, borderRadius: 4.0),
                SizedBox(height: 8),
                SkeletonBox(
                    width: double.infinity, height: 14, borderRadius: 4.0),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonBox(width: 40, height: 12, borderRadius: 4.0),
              SizedBox(height: 8),
              SkeletonCircle(size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a match card.
class SkeletonMatchCard extends StatelessWidget {
  const SkeletonMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? DsColors.surfaceDark
            : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(DsRadius.lg),
      ),
      child: const Row(
        children: [
          SkeletonCircle(size: 64),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 18, borderRadius: 4.0),
                SizedBox(height: 8),
                SkeletonBox(width: 150, height: 14, borderRadius: 4.0),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 12, borderRadius: 4.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a profile card (swipe deck).
class SkeletonProfileCard extends StatelessWidget {
  const SkeletonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? DsColors.skeletonDark
            : DsColors.skeletonLight,
        borderRadius: BorderRadius.circular(DsRadius.xl),
      ),
      child: Stack(
        children: [
          // Main card area
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DsRadius.xl),
              ),
            ),
          ),
          // Bottom info area
          const Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 180, height: 28, borderRadius: DsRadius.sm),
                SizedBox(height: 8),
                SkeletonBox(width: 120, height: 18, borderRadius: 4.0),
                SizedBox(height: 12),
                Row(
                  children: [
                    SkeletonBox(
                        width: 60, height: 24, borderRadius: DsRadius.round),
                    SizedBox(width: 8),
                    SkeletonBox(
                        width: 80, height: 24, borderRadius: DsRadius.round),
                    SizedBox(width: 8),
                    SkeletonBox(
                        width: 70, height: 24, borderRadius: DsRadius.round),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton list with shimmer effect.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding,
  });

  /// Creates a skeleton list with chat tiles.
  factory SkeletonList.chat({int itemCount = 5}) {
    return SkeletonList(
      itemCount: itemCount,
      itemBuilder: (_, __) => const SkeletonChatTile(),
    );
  }

  /// Creates a skeleton list with match cards.
  factory SkeletonList.matches({int itemCount = 5}) {
    return SkeletonList(
      itemCount: itemCount,
      itemBuilder: (_, __) => const SkeletonMatchCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsShimmer(
      child: ListView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Skeleton grid for profile photos or matches grid.
class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return DsShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? DsColors.skeletonDark
                  : DsColors.skeletonLight,
              borderRadius: BorderRadius.circular(DsRadius.md),
            ),
          );
        },
      ),
    );
  }
}
