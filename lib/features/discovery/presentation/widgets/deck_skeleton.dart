import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';

/// Skeleton loading state for the discovery deck.
class DeckSkeletonList extends StatelessWidget {
  const DeckSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 16),
        SkeletonCard(height: 18, widthFactor: 0.6),
        SizedBox(height: 12),
        SkeletonCard(height: 250),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SkeletonCircle(size: 60),
            SkeletonCircle(size: 60),
            SkeletonCircle(size: 60),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

/// A rectangular skeleton placeholder for loading states.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.height,
    this.widthFactor,
  });

  final double height;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor ?? 0.9,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: DsColors.skeletonLight,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// A circular skeleton placeholder for loading states.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: DsColors.skeletonLight,
        shape: BoxShape.circle,
      ),
    );
  }
}
