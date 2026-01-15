import 'dart:math';

import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import 'package:crushhour/core/services/haptic_service.dart';

/// An animated super like effect with star burst.
class SuperLikeAnimation extends StatefulWidget {
  const SuperLikeAnimation({
    super.key,
    required this.onComplete,
    this.color,
    this.size = 120,
  });

  /// Called when the animation completes.
  final VoidCallback onComplete;

  /// Color of the star (defaults to secondary/blue).
  final Color? color;

  /// Size of the animation.
  final double size;

  @override
  State<SuperLikeAnimation> createState() => _SuperLikeAnimationState();
}

class _SuperLikeAnimationState extends State<SuperLikeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation - pop in and out
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_scaleController);

    // Rotation animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.elasticOut),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animations
    _startAnimation();
  }

  void _startAnimation() async {
    HapticService.superLike();
    _scaleController.forward();
    _rotateController.forward();
    _particleController.forward();

    await _scaleController.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starColor = widget.color ?? DsColors.secondary;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _particleController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Particle burst
            ..._buildParticles(starColor),
            // Main star
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Icon(
                  Icons.star_rounded,
                  size: widget.size,
                  color: starColor,
                  shadows: [
                    Shadow(
                      color: starColor.withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            // Glow
            Transform.scale(
              scale: _scaleAnimation.value * 1.5,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      starColor.withValues(alpha: 0.3 * (1 - _particleController.value)),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildParticles(Color color) {
    const particleCount = 12;
    final particles = <Widget>[];

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final distance = widget.size * 0.8 * _particleController.value;

      particles.add(
        Transform.translate(
          offset: Offset(
            cos(angle) * distance,
            sin(angle) * distance,
          ),
          child: Opacity(
            opacity: (1 - _particleController.value).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 1 - _particleController.value * 0.5,
              child: Icon(
                i % 2 == 0 ? Icons.star : Icons.auto_awesome,
                size: 16,
                color: color,
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }
}

/// Overlay widget to show super like animation on the screen.
class SuperLikeOverlay extends StatelessWidget {
  const SuperLikeOverlay({
    super.key,
    required this.show,
    required this.onComplete,
  });

  final bool show;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: SuperLikeAnimation(onComplete: onComplete),
        ),
      ),
    );
  }
}
