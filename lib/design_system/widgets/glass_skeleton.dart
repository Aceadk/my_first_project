import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// A glassmorphism-styled skeleton loader with shimmer effect.
class GlassSkeleton extends StatefulWidget {
  const GlassSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.isCircle = false,
  });

  /// Width of the skeleton. If null, expands to fill.
  final double? width;

  /// Height of the skeleton.
  final double? height;

  /// Border radius. Defaults to DsRadius.md.
  final double? borderRadius;

  /// If true, renders as a circle.
  final bool isCircle;

  @override
  State<GlassSkeleton> createState() => _GlassSkeletonState();
}

class _GlassSkeletonState extends State<GlassSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = DsGlassColors.surfaceFor(context);
    final highlightColor = DsGlassColors.highlightFor(context, strong: true);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: widget.isCircle
              ? BorderRadius.circular(1000)
              : BorderRadius.circular(widget.borderRadius ?? DsRadius.md),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DsBlur.subtle,
              sigmaY: DsBlur.subtle,
            ),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircle
                    ? null
                    : BorderRadius.circular(widget.borderRadius ?? DsRadius.md),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [baseColor, highlightColor, baseColor],
                  stops: [
                    (_animation.value - 0.3).clamp(0.0, 1.0),
                    _animation.value.clamp(0.0, 1.0),
                    (_animation.value + 0.3).clamp(0.0, 1.0),
                  ],
                ),
                border: Border.all(
                  color: DsGlassColors.borderFor(context),
                  width: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for a profile card in the deck.
class GlassSkeletonCard extends StatelessWidget {
  const GlassSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DsRadius.lg),
        border: Border.all(color: DsGlassColors.borderFor(context), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background shimmer
          const GlassSkeleton(),
          // Content overlay
          const PositionedDirectional(
            start: DsSpacing.lg,
            end: DsSpacing.lg,
            bottom: DsSpacing.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name skeleton
                GlassSkeleton(
                  width: 180,
                  height: 28,
                  borderRadius: DsRadius.sm,
                ),
                SizedBox(height: DsSpacing.sm),
                // Bio skeleton
                GlassSkeleton(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                SizedBox(height: DsSpacing.xs),
                GlassSkeleton(width: 200, height: 16, borderRadius: 4),
                SizedBox(height: DsSpacing.md),
                // Location skeleton
                Row(
                  children: [
                    GlassSkeleton(width: 14, height: 14, isCircle: true),
                    SizedBox(width: DsSpacing.xs),
                    GlassSkeleton(width: 120, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
          // Top indicators skeleton
          PositionedDirectional(
            top: DsSpacing.md,
            start: DsSpacing.md,
            end: DsSpacing.md,
            child: Row(
              children: List.generate(
                4,
                (index) => Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsetsDirectional.only(end: index < 3 ? 4 : 0),
                    child: const GlassSkeleton(borderRadius: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for a chat list item.
class GlassSkeletonChatTile extends StatelessWidget {
  const GlassSkeletonChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      child: Row(
        children: [
          // Avatar
          GlassSkeleton(width: 56, height: 56, isCircle: true),
          SizedBox(width: DsSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlassSkeleton(width: 100, height: 18, borderRadius: 4),
                    Spacer(),
                    GlassSkeleton(width: 40, height: 14, borderRadius: 4),
                  ],
                ),
                SizedBox(height: DsSpacing.xs),
                GlassSkeleton(width: 180, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for a match tile.
class GlassSkeletonMatchTile extends StatelessWidget {
  const GlassSkeletonMatchTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsetsDirectional.only(end: DsSpacing.md),
      child: const Column(
        children: [
          // Avatar
          GlassSkeleton(width: 80, height: 80, isCircle: true),
          SizedBox(height: DsSpacing.xs),
          // Name
          GlassSkeleton(width: 60, height: 14, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton loader for profile view.
class GlassSkeletonProfile extends StatelessWidget {
  const GlassSkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          // Header image
          GlassSkeleton(width: double.infinity, height: 400, borderRadius: 0),
          Padding(
            padding: EdgeInsets.all(DsSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and age
                GlassSkeleton(
                  width: 200,
                  height: 32,
                  borderRadius: DsRadius.sm,
                ),
                SizedBox(height: DsSpacing.md),
                // Bio
                GlassSkeleton(
                  width: double.infinity,
                  height: 60,
                  borderRadius: DsRadius.md,
                ),
                SizedBox(height: DsSpacing.lg),
                // Info cards
                GlassSkeleton(
                  width: double.infinity,
                  height: 80,
                  borderRadius: DsRadius.md,
                ),
                SizedBox(height: DsSpacing.md),
                GlassSkeleton(
                  width: double.infinity,
                  height: 80,
                  borderRadius: DsRadius.md,
                ),
                SizedBox(height: DsSpacing.md),
                GlassSkeleton(
                  width: double.infinity,
                  height: 80,
                  borderRadius: DsRadius.md,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for message bubble.
class GlassSkeletonMessage extends StatelessWidget {
  const GlassSkeletonMessage({super.key, this.isFromMe = false, this.width});

  final bool isFromMe;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: isFromMe ? 60 : DsSpacing.md,
          end: isFromMe ? DsSpacing.md : 60,
          bottom: DsSpacing.sm,
        ),
        child: GlassSkeleton(
          width: width ?? (isFromMe ? 180 : 220),
          height: 40,
          borderRadius: DsRadius.lg,
        ),
      ),
    );
  }
}

/// A list of skeleton chat tiles.
class GlassSkeletonChatList extends StatelessWidget {
  const GlassSkeletonChatList({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const GlassSkeletonChatTile(),
    );
  }
}

/// A horizontal list of skeleton match tiles.
class GlassSkeletonMatchList extends StatelessWidget {
  const GlassSkeletonMatchList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
        itemCount: itemCount,
        itemBuilder: (context, index) => const GlassSkeletonMatchTile(),
      ),
    );
  }
}
