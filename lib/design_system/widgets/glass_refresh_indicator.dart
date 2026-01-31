import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import 'package:crushhour/core/services/haptic_service.dart';
import '../theme/theme_extensions.dart';

/// A glassmorphism-styled refresh indicator.
class GlassRefreshIndicator extends StatefulWidget {
  const GlassRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 60.0,
    this.color,
    this.backgroundColor,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the user drags down to refresh.
  final Future<void> Function() onRefresh;

  /// Distance from the top to show the indicator.
  final double displacement;

  /// Color of the progress indicator.
  final Color? color;

  /// Background color of the indicator container.
  final Color? backgroundColor;

  @override
  State<GlassRefreshIndicator> createState() => _GlassRefreshIndicatorState();
}

class _GlassRefreshIndicatorState extends State<GlassRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _dragOffset = 0;
  bool _isRefreshing = false;
  bool _hasTriggeredHaptic = false;

  static const double _triggerThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isRefreshing) return;

    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 150.0);
    });

    // Trigger haptic when threshold is crossed
    if (_dragOffset >= _triggerThreshold && !_hasTriggeredHaptic) {
      HapticService.refreshThreshold();
      _hasTriggeredHaptic = true;
    } else if (_dragOffset < _triggerThreshold) {
      _hasTriggeredHaptic = false;
    }
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (_isRefreshing) return;

    if (_dragOffset >= _triggerThreshold) {
      setState(() {
        _isRefreshing = true;
        _dragOffset = _triggerThreshold;
      });

      _rotationController.repeat();

      try {
        await widget.onRefresh();
      } finally {
        if (mounted) {
          _rotationController.stop();
          HapticService.refreshComplete();
          setState(() {
            _isRefreshing = false;
            _dragOffset = 0;
            _hasTriggeredHaptic = false;
          });
        }
      }
    } else {
      setState(() {
        _dragOffset = 0;
        _hasTriggeredHaptic = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effects = Theme.of(context).extension<CrushThemeEffects>();
    final motionScale = effects?.motionScale ?? 1.0;
    final indicatorColor = widget.color ?? DsColors.primary;
    final bgColor = widget.backgroundColor ??
        DsGlassColors.surfaceFor(
          context,
          strength: DsGlassSurfaceStrength.medium,
        );

    final progress = (_dragOffset / _triggerThreshold).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Indicator
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: _isRefreshing
                ? Duration.zero
                : Duration(milliseconds: (200 * motionScale).round()),
            height: _dragOffset,
            child: Center(
              child: AnimatedOpacity(
                duration: Duration(milliseconds: (150 * motionScale).round()),
                opacity: progress,
                child: Transform.scale(
                  scale: progress,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DsRadius.round),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: DsBlur.light,
                        sigmaY: DsBlur.light,
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DsGlassColors.borderFor(context),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: indicatorColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isRefreshing
                            ? RotationTransition(
                                turns: _rotationController,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(indicatorColor),
                                  ),
                                ),
                              )
                            : Icon(
                                progress >= 1.0
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: indicatorColor,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Content with drag handling
        GestureDetector(
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: AnimatedContainer(
            duration: _isRefreshing
                ? Duration.zero
                : Duration(milliseconds: (200 * motionScale).round()),
            transform: Matrix4.translationValues(0, _dragOffset, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// A simpler wrapper that uses the standard RefreshIndicator with glass styling.
class GlassRefreshWrapper extends StatelessWidget {
  const GlassRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticService.refreshThreshold();
        await onRefresh();
        HapticService.refreshComplete();
      },
      color: color ?? DsColors.primary,
      backgroundColor: DsGlassColors.surfaceFor(
        context,
        strength: DsGlassSurfaceStrength.medium,
      ),
      strokeWidth: 2.5,
      child: child,
    );
  }
}
