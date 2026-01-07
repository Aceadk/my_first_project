import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// A notification badge that can display a count or just a dot indicator.
class CrushBadge extends StatelessWidget {
  final int? count;
  final bool showDot;
  final Color? color;
  final Color? textColor;
  final double size;
  final Widget child;
  final AlignmentGeometry alignment;

  const CrushBadge({
    super.key,
    this.count,
    this.showDot = false,
    this.color,
    this.textColor,
    this.size = 18,
    required this.child,
    this.alignment = Alignment.topRight,
  });

  /// Creates a badge that only shows when count > 0.
  const CrushBadge.count({
    super.key,
    required int this.count,
    this.color,
    this.textColor,
    this.size = 18,
    required this.child,
    this.alignment = Alignment.topRight,
  }) : showDot = false;

  /// Creates a simple dot indicator badge.
  const CrushBadge.dot({
    super.key,
    this.color,
    this.size = 10,
    required this.child,
    this.alignment = Alignment.topRight,
  })  : count = null,
        showDot = true,
        textColor = null;

  @override
  Widget build(BuildContext context) {
    final shouldShow = showDot || (count != null && count! > 0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (shouldShow)
          Positioned(
            top: -size * 0.3,
            right: alignment == Alignment.topRight ? -size * 0.3 : null,
            left: alignment == Alignment.topLeft ? -size * 0.3 : null,
            child: _BadgeContent(
              count: count,
              showDot: showDot,
              color: color ?? DsColors.primary,
              textColor: textColor ?? Colors.white,
              size: size,
            ),
          ),
      ],
    );
  }
}

class _BadgeContent extends StatelessWidget {
  final int? count;
  final bool showDot;
  final Color color;
  final Color textColor;
  final double size;

  const _BadgeContent({
    required this.count,
    required this.showDot,
    required this.color,
    required this.textColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (showDot) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 2,
          ),
        ),
      );
    }

    final displayText = count != null && count! > 99 ? '99+' : '$count';
    final isWide = displayText.length > 2;

    return Container(
      height: size,
      constraints: BoxConstraints(minWidth: size),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 6 : 0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.6,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// A "NEW" badge for highlighting new content.
class CrushNewBadge extends StatelessWidget {
  final Widget child;

  const CrushNewBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DsColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// An animated badge that pulses to draw attention.
class CrushPulsingBadge extends StatefulWidget {
  final Widget child;
  final Color? color;
  final double size;

  const CrushPulsingBadge({
    super.key,
    required this.child,
    this.color,
    this.size = 12,
  });

  @override
  State<CrushPulsingBadge> createState() => _CrushPulsingBadgeState();
}

class _CrushPulsingBadgeState extends State<CrushPulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = widget.color ?? DsColors.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: -widget.size * 0.3,
          right: -widget.size * 0.3,
          child: SizedBox(
            width: widget.size * 2,
            height: widget.size * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
