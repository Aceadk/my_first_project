import 'package:crushhour/core/services/haptic_service.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_reaction.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/utils/accessibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'swipe_card.dart';

/// A swipeable card widget that handles horizontal swipe gestures.
/// Swipe left to right = Like, Swipe right to left = Pass
///
/// Performance optimizations:
/// - Uses ValueNotifier to avoid setState during drag operations
/// - Uses RepaintBoundary to isolate repaints to this subtree
/// - Uses AnimatedBuilder's child parameter for static content
class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.onSwipeUp,
    this.superLikeEnabled = true,
    this.onReaction,
  });

  final Profile profile;
  final VoidCallback onTap;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback? onSwipeUp; // For SuperLike
  final bool superLikeEnabled;

  /// Callback when user reacts to content (photo/prompt).
  final void Function(
    String reactionType,
    ReactionContentType contentType,
    int index,
    String? comment,
  )?
  onReaction;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  // Use ValueNotifier for efficient updates without setState
  final ValueNotifier<double> _dragXNotifier = ValueNotifier(0);
  final ValueNotifier<double> _dragYNotifier = ValueNotifier(0);
  double _dragStartX = 0;
  double _dragStartY = 0;
  bool _isDragging = false;
  bool _crossedThreshold = false; // Track if threshold was crossed for haptic
  bool _crossedUpThreshold = false; // Track if upward threshold was crossed
  late AnimationController _animationController;
  late Animation<double> _animationX;
  late Animation<double> _animationY;

  static const double _swipeThreshold = 100.0;
  static const double _swipeUpThreshold = 80.0; // Lower threshold for swipe up
  static const double _velocityThreshold = 500.0;
  static const double _velocityUpThreshold = 400.0;
  static const double _maxRotation = 0.1; // radians
  static const double _rotationDivisor = 500.0;
  static const double _opacityDivisor = 300.0;
  static const double _indicatorVisibilityThreshold = 20.0;

  @override
  void initState() {
    super.initState();
    // We defer setting the duration until build/animateOut where context is available
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationX = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationY = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Single listener for animation updates
    _animationController.addListener(_onAnimationUpdate);
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationUpdate);
    _animationController.dispose();
    _dragXNotifier.dispose();
    _dragYNotifier.dispose();
    super.dispose();
  }

  void _onAnimationUpdate() {
    // Update notifiers during animation - no setState needed
    if (_animationController.isAnimating) {
      _dragXNotifier.value = _animationX.value;
      _dragYNotifier.value = _animationY.value;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartY = details.globalPosition.dy;
    _isDragging = true;
    _crossedThreshold = false;
    _crossedUpThreshold = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    // Update ValueNotifiers instead of calling setState
    final newDragX = details.globalPosition.dx - _dragStartX;
    final newDragY = details.globalPosition.dy - _dragStartY;
    _dragXNotifier.value = newDragX;
    _dragYNotifier.value = newDragY;

    // Haptic feedback when crossing horizontal threshold (only once per drag)
    if (!_crossedThreshold && newDragX.abs() > _swipeThreshold) {
      _crossedThreshold = true;
      if (!DsAccessibility.prefersReducedMotion(context)) {
        HapticService.swipeThreshold();
      }
    }

    // Haptic feedback when crossing upward threshold (for SuperLike)
    if (!_crossedUpThreshold &&
        newDragY < -_swipeUpThreshold &&
        widget.superLikeEnabled) {
      _crossedUpThreshold = true;
      if (!DsAccessibility.prefersReducedMotion(context)) {
        HapticService.swipeThreshold();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final dragX = _dragXNotifier.value;
    final dragY = _dragYNotifier.value;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final velocityY = details.velocity.pixelsPerSecond.dy;

    // Check for swipe up (SuperLike) first - negative Y means upward
    final shouldSwipeUp =
        widget.superLikeEnabled &&
        widget.onSwipeUp != null &&
        (dragY < -_swipeUpThreshold || velocityY < -_velocityUpThreshold);

    final shouldSwipeRight =
        dragX > _swipeThreshold || velocityX > _velocityThreshold;
    final shouldSwipeLeft =
        dragX < -_swipeThreshold || velocityX < -_velocityThreshold;

    if (shouldSwipeUp && dragY.abs() > dragX.abs()) {
      // Prioritize swipe up if vertical movement is dominant
      _animateOutUp();
    } else if (shouldSwipeRight) {
      _animateOut(true);
    } else if (shouldSwipeLeft) {
      _animateOut(false);
    } else {
      _animateBack();
    }
  }

  void _animateOut(bool isLike) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isLike ? screenWidth : -screenWidth;

    // Haptic feedback when swipe is confirmed
    final reducedMotion = DsAccessibility.prefersReducedMotion(context);
    if (!reducedMotion) {
      if (isLike) {
        HapticService.like();
      } else {
        HapticService.nope();
      }
    }

    // Faster or instant transition for reduced motion
    _animationController.duration = Duration(
      milliseconds: reducedMotion ? 50 : 200,
    );

    _animationX = Tween<double>(begin: _dragXNotifier.value, end: targetX)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationY = Tween<double>(begin: _dragYNotifier.value, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0).then((_) {
      if (isLike) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
      // Reset position
      _dragXNotifier.value = 0;
      _dragYNotifier.value = 0;
      _animationController.reset();
    });
  }

  void _animateOutUp() {
    final screenHeight = MediaQuery.of(context).size.height;
    final reducedMotion = DsAccessibility.prefersReducedMotion(context);

    // Strong haptic feedback for SuperLike
    if (!reducedMotion) {
      HapticService.superLike();
    }

    _animationController.duration = Duration(
      milliseconds: reducedMotion ? 50 : 200,
    );

    _animationX = Tween<double>(begin: _dragXNotifier.value, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationY = Tween<double>(begin: _dragYNotifier.value, end: -screenHeight)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward(from: 0).then((_) {
      widget.onSwipeUp?.call();
      // Reset position
      _dragXNotifier.value = 0;
      _dragYNotifier.value = 0;
      _animationController.reset();
    });
  }

  void _animateBack() {
    final reducedMotion = DsAccessibility.prefersReducedMotion(context);
    _animationController.duration = Duration(
      milliseconds: reducedMotion ? 50 : 200,
    );

    _animationX = Tween<double>(begin: _dragXNotifier.value, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationY = Tween<double>(begin: _dragYNotifier.value, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Profile card for ${widget.profile.name}',
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Pass'): widget.onSwipeLeft,
        const CustomSemanticsAction(label: 'Like'): widget.onSwipeRight,
        if (widget.superLikeEnabled && widget.onSwipeUp != null)
          const CustomSemanticsAction(label: 'Super Like'): widget.onSwipeUp!,
      },
      child: GestureDetector(
        onTap: _isDragging ? null : widget.onTap,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        // RepaintBoundary isolates repaints to this subtree
        child: RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: _dragXNotifier,
            builder: (context, dragX, _) {
              return ValueListenableBuilder<double>(
                valueListenable: _dragYNotifier,
                builder: (context, dragY, child) {
                  final reducedMotion = DsAccessibility.prefersReducedMotion(
                    context,
                  );

                  // Cancel rotation entirely if reduced motion is preferred
                  final rotation = reducedMotion
                      ? 0.0
                      : (dragX / _rotationDivisor).clamp(
                          -_maxRotation,
                          _maxRotation,
                        );

                  final horizontalOpacity =
                      1 - (dragX.abs() / _opacityDivisor).clamp(0.0, 0.3);
                  final verticalOpacity =
                      1 - (dragY.abs() / _opacityDivisor).clamp(0.0, 0.3);
                  final opacity = horizontalOpacity < verticalOpacity
                      ? horizontalOpacity
                      : verticalOpacity;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setTranslationRaw(dragX, dragY, 0)
                      ..rotateZ(rotation),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: opacity,
                          // Use child parameter for static content optimization
                          child: child,
                        ),
                        // Like indicator (right side) - Red heart icon
                        if (dragX > _indicatorVisibilityThreshold)
                          const PositionedDirectional(
                            start: 30.0,
                            top: 30.0,
                            child: _SwipeIconIndicator(
                              icon: Icons.favorite_rounded,
                              color: DsColors.primary,
                              angle: -0.3,
                            ),
                          ),
                        // Pass indicator (left side) - Bold red X icon
                        if (dragX < -_indicatorVisibilityThreshold)
                          const PositionedDirectional(
                            end: 30.0,
                            top: 30.0,
                            child: _SwipeIconIndicator(
                              icon: Icons.close_rounded,
                              color: DsColors.error,
                              angle: 0.3,
                            ),
                          ),
                        // SuperLike indicator (top center) - Purple star icon
                        if (dragY < -_indicatorVisibilityThreshold &&
                            widget.superLikeEnabled)
                          const PositionedDirectional(
                            start: 0,
                            end: 0,
                            bottom: 100.0,
                            child: Center(
                              child: _SwipeIconIndicator(
                                icon: Icons.star_rounded,
                                color: DsColors.secondary,
                                angle: 0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                // Static child passed to builder for optimization
                child: SwipeCard(
                  profile: widget.profile,
                  onReaction: widget.onReaction,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Swipe indicator widget showing icon instead of text
class _SwipeIconIndicator extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double angle;

  const _SwipeIconIndicator({
    required this.icon,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 48,
          shadows: [
            Shadow(
              color: DsColors.ink900.withValues(alpha: 0.3),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
