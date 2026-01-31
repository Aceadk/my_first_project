import 'dart:async';

import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';

/// A pulsing icon container with expanding/contracting outer ring animation.
/// Used in the empty deck state to draw attention to the icon.
class PulsingIconContainer extends StatefulWidget {
  const PulsingIconContainer({
    super.key,
    required this.icon,
    this.iconSize = 56,
    this.iconColor,
    this.baseSize = 96,
  });

  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final double baseSize;

  @override
  State<PulsingIconContainer> createState() => _PulsingIconContainerState();
}

class _PulsingIconContainerState extends State<PulsingIconContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Smooth pulse animation using curved intervals
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Fade the outer ring in and out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0.6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.3)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = widget.iconColor ??
        (isDark ? DsColors.textMutedDark : DsColors.textMutedLight);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.baseSize * 1.3,
          height: widget.baseSize * 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: widget.baseSize * 1.2,
                  height: widget.baseSize * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: effectiveColor.withValues(
                        alpha: _opacityAnimation.value * 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Second pulsing ring (slightly delayed feel)
              Transform.scale(
                scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.6,
                child: Container(
                  width: widget.baseSize * 1.1,
                  height: widget.baseSize * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: effectiveColor.withValues(
                        alpha: _opacityAnimation.value * 0.3,
                      ),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Inner static container with icon
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: widget.baseSize,
        height: widget.baseSize,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.iconColor != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.iconColor!.withValues(alpha: 0.25),
                    widget.iconColor!.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: widget.iconColor == null
              ? (isDark ? DsColors.skeletonDark : DsColors.skeletonLight)
              : null,
        ),
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: effectiveColor,
        ),
      ),
    );
  }
}

/// An animated passport button with plane takeoff animation.
/// The plane takes off from left to right every 10 seconds.
class AnimatedPassportButton extends StatefulWidget {
  const AnimatedPassportButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isPlus = false,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isPlus;

  @override
  State<AnimatedPassportButton> createState() => _AnimatedPassportButtonState();
}

class _AnimatedPassportButtonState extends State<AnimatedPassportButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _planePosition;
  late Animation<double> _planeAltitude;
  late Animation<double> _planeRotation;
  late Animation<double> _textOpacity;
  late Animation<double> _planeOpacity;
  Timer? _loopTimer;

  // Button content width for calculations
  static const double _contentWidth = 220.0;

  @override
  void initState() {
    super.initState();
    // Slower, more realistic takeoff duration (4 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Realistic plane movement - mostly horizontal with gradual progress
    // Real planes accelerate on runway, lift off, and climb gradually
    _planePosition = TweenSequence<double>([
      // Taxi/acceleration phase - slow start
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.12, end: 0.15)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      // Liftoff and initial climb - steady speed
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 0.5)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 35,
      ),
      // Climb out - continues steady
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 0.85)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 30,
      ),
      // Exit frame
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
    ]).animate(_controller);

    // Realistic altitude - planes climb at roughly 10-15 degree angle
    // Very gradual rise, not dramatic vertical movement
    _planeAltitude = TweenSequence<double>([
      // On runway - no altitude change
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 20,
      ),
      // Rotation and liftoff - slight rise
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // Initial climb - gradual steady rise
      TweenSequenceItem(
        tween: Tween<double>(begin: -3, end: -8)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 35,
      ),
      // Continue climb - still gradual
      TweenSequenceItem(
        tween: Tween<double>(begin: -8, end: -14)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Realistic rotation - planes pitch up slightly during takeoff
    // About 10-15 degrees nose up, very subtle
    _planeRotation = TweenSequence<double>([
      // On runway - level
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 20,
      ),
      // Rotation - nose comes up for liftoff
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -0.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // Climb attitude - maintain pitch
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.18, end: -0.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      // Slight adjustment during climb out
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.15, end: -0.12)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Text fades out smoothly when plane enters, fades back in after exit
    _textOpacity = TweenSequence<double>([
      // Quick fade out as plane enters
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      // Stay hidden while plane flies through
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 76,
      ),
      // Fade back in smoothly after plane exits
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 12,
      ),
    ]).animate(_controller);

    // Plane visibility - fade in at start, fade out at end
    _planeOpacity = TweenSequence<double>([
      // Fade in smoothly
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      // Fully visible during flight
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 84,
      ),
      // Fade out as it exits
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
    ]).animate(_controller);

    // Start the animation loop
    _startAnimationLoop();
  }

  void _startAnimationLoop() {
    // Play after a short delay on first load
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _controller.forward(from: 0);
      }
    });

    // Then repeat every 10 seconds
    _loopTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: DsColors.info,
            side: BorderSide(color: DsColors.info.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: SizedBox(
            width: _contentWidth,
            height: 24,
            child: ClipRect(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Static icon on the left (fades with text during animation)
                  Positioned(
                    left: 0,
                    child: Opacity(
                      opacity: _textOpacity.value,
                      child: const Icon(Icons.flight_takeoff, size: 18),
                    ),
                  ),
                  // Text label (fades out during animation)
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 26),
                        Text(
                          widget.label,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ],
                    ),
                  ),
                  // Animated flying plane
                  if (_controller.isAnimating || _planeOpacity.value > 0)
                    Positioned(
                      left: _planePosition.value * _contentWidth - 15,
                      top: 2 + _planeAltitude.value,
                      child: Opacity(
                        opacity: _planeOpacity.value,
                        child: Transform.rotate(
                          angle: _planeRotation.value,
                          child: const _AnimatedPlane(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A small animated plane with trailing effect
class _AnimatedPlane extends StatelessWidget {
  const _AnimatedPlane();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Contrail / trail effect
          Positioned(
            left: 0,
            child: Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DsColors.info.withValues(alpha: 0),
                    DsColors.info.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Second trail line (slightly offset)
          Positioned(
            left: 2,
            top: 4,
            child: Container(
              width: 15,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DsColors.info.withValues(alpha: 0),
                    DsColors.info.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // The plane icon
          const Positioned(
            right: 0,
            child: Icon(
              Icons.flight,
              size: 20,
              color: DsColors.info,
            ),
          ),
        ],
      ),
    );
  }
}

/// A rotating compass icon for the explore/passport states
class AnimatedCompassIcon extends StatefulWidget {
  const AnimatedCompassIcon({
    super.key,
    this.size = 56,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<AnimatedCompassIcon> createState() => _AnimatedCompassIconState();
}

class _AnimatedCompassIconState extends State<AnimatedCompassIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Gentle wobble rotation
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: -0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.1, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? DsColors.info;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Icon(
            Icons.explore,
            size: widget.size,
            color: effectiveColor,
          ),
        );
      },
    );
  }
}
