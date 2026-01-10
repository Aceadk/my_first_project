import 'package:flutter/material.dart';
import '../../data/models/profile.dart';
import 'swipe_card.dart';

/// A swipeable card widget that handles horizontal swipe gestures.
/// Swipe left to right = Like, Swipe right to left = Pass
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
  double _dragX = 0;
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragX = details.globalPosition.dx - _dragStartX;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldSwipeRight = _dragX > _swipeThreshold || velocity > 500;
    final shouldSwipeLeft = _dragX < -_swipeThreshold || velocity < -500;

    if (shouldSwipeRight) {
      // Swipe left to right = Like
      _animateOut(true);
    } else if (shouldSwipeLeft) {
      // Swipe right to left = Pass
      _animateOut(false);
    } else {
      // Snap back to center
      _animateBack();
    }
  }

  void _animateOut(bool isLike) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isLike ? screenWidth : -screenWidth;

    _animation = Tween<double>(begin: _dragX, end: targetX).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0).then((_) {
      if (isLike) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
      // Reset position for next card
      setState(() {
        _dragX = 0;
      });
      _animationController.reset();
    });
  }

  void _animateBack() {
    _animation = Tween<double>(begin: _dragX, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addListener(_onAnimationUpdate);

    _animationController.forward(from: 0).then((_) {
      _animationController.removeListener(_onAnimationUpdate);
    });
  }

  void _onAnimationUpdate() {
    setState(() {
      _dragX = _animation.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rotation = (_dragX / 500).clamp(-_maxRotation, _maxRotation);
    final opacity = 1 - (_dragX.abs() / 300).clamp(0.0, 0.3);

    return GestureDetector(
      onTap: _isDragging ? null : widget.onTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final currentX =
              _animationController.isAnimating ? _animation.value : _dragX;
          return Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(currentX, 0, 0)
              ..rotateZ(rotation),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Opacity(
                  opacity: opacity,
                  child: SwipeCard(profile: widget.profile),
                ),
                // Like indicator (right side)
                if (_dragX > 20)
                  Positioned(
                    left: 30,
                    top: 30,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LIKE',
                          style: TextStyle(
                            color: Colors.green,
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
                    ),
                  ),
                // Pass indicator (left side)
                if (_dragX < -20)
                  Positioned(
                    right: 30,
                    top: 30,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NOPE',
                          style: TextStyle(
                            color: Colors.red,
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
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
