import 'package:flutter/material.dart';
import 'package:crushhour/data/models/profile.dart';
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
  });

  final Profile profile;
  final VoidCallback onTap;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  // Use ValueNotifier for efficient updates without setState
  final ValueNotifier<double> _dragXNotifier = ValueNotifier(0);
  double _dragStartX = 0;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const double _swipeThreshold = 100.0;
  static const double _maxRotation = 0.1; // radians

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
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
    super.dispose();
  }

  void _onAnimationUpdate() {
    // Update notifier during animation - no setState needed
    if (_animationController.isAnimating) {
      _dragXNotifier.value = _animation.value;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    // Update ValueNotifier instead of calling setState
    _dragXNotifier.value = details.globalPosition.dx - _dragStartX;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final dragX = _dragXNotifier.value;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldSwipeRight = dragX > _swipeThreshold || velocity > 500;
    final shouldSwipeLeft = dragX < -_swipeThreshold || velocity < -500;

    if (shouldSwipeRight) {
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

    _animation = Tween<double>(begin: _dragXNotifier.value, end: targetX).animate(
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
      _animationController.reset();
    });
  }

  void _animateBack() {
    _animation = Tween<double>(begin: _dragXNotifier.value, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isDragging ? null : widget.onTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      // RepaintBoundary isolates repaints to this subtree
      child: RepaintBoundary(
        child: ValueListenableBuilder<double>(
          valueListenable: _dragXNotifier,
          builder: (context, dragX, child) {
            final rotation = (dragX / 500).clamp(-_maxRotation, _maxRotation);
            final opacity = 1 - (dragX.abs() / 300).clamp(0.0, 0.3);

            return Transform(
              transform: Matrix4.identity()
                ..setTranslationRaw(dragX, 0, 0)
                ..rotateZ(rotation),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Opacity(
                    opacity: opacity,
                    // Use child parameter for static content optimization
                    child: child,
                  ),
                  // Like indicator (right side)
                  if (dragX > 20)
                    const Positioned(
                      left: 30,
                      top: 30,
                      child: _SwipeIndicator(
                        text: 'LIKE',
                        color: Colors.green,
                        angle: -0.3,
                      ),
                    ),
                  // Pass indicator (left side)
                  if (dragX < -20)
                    const Positioned(
                      right: 30,
                      top: 30,
                      child: _SwipeIndicator(
                        text: 'NOPE',
                        color: Colors.red,
                        angle: 0.3,
                      ),
                    ),
                ],
              ),
            );
          },
          // Static child passed to builder for optimization
          child: SwipeCard(profile: widget.profile),
        ),
      ),
    );
  }
}

/// Extracted swipe indicator widget to avoid rebuilds
class _SwipeIndicator extends StatelessWidget {
  final String text;
  final Color color;
  final double angle;

  const _SwipeIndicator({
    required this.text,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
