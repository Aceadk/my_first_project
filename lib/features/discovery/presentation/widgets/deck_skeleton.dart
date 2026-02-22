import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/widgets/glass_skeleton.dart';
import 'package:flutter/material.dart';

/// Skeleton loading state for the discovery deck.
///
/// Uses design system [SkeletonBox] and [SkeletonCircle] instead of
/// local duplicates.
class DeckSkeletonList extends StatelessWidget {
  const DeckSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: DsSpacing.lg),
        FractionallySizedBox(
          widthFactor: 0.6,
          child: GlassSkeleton(height: 18),
        ),
        SizedBox(height: DsSpacing.md),
        FractionallySizedBox(
          widthFactor: 0.9,
          child: GlassSkeleton(height: 250),
        ),
        SizedBox(height: DsSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GlassSkeleton(width: 60, height: 60, isCircle: true),
            GlassSkeleton(width: 60, height: 60, isCircle: true),
            GlassSkeleton(width: 60, height: 60, isCircle: true),
          ],
        ),
        SizedBox(height: DsSpacing.lg),
      ],
    );
  }
}
