import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

/// A temporary notification that fades away on its own.
class ChatFadeNotification extends StatefulWidget {
  const ChatFadeNotification({
    super.key,
    required this.message,
    required this.icon,
    required this.onDismiss,
  });

  final String message;
  final IconData icon;
  final VoidCallback onDismiss;

  @override
  State<ChatFadeNotification> createState() => _ChatFadeNotificationState();
}

class _ChatFadeNotificationState extends State<ChatFadeNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween<Offset>(Offset.zero), weight: 55),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.3),
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);

    return PositionedDirectional(
      top: MediaQuery.of(context).padding.top + 100,
      start: 0,
      end: 0,
      child: Semantics(
        liveRegion: true,
        label: widget.message,
        excludeSemantics: true,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(position: _slideAnimation, child: child),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DsRadius.round),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: DsBlur.heavy,
                  sigmaY: DsBlur.heavy,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.lg,
                    vertical: DsSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        baseSurface.withValues(alpha: 0.9),
                        baseSurface.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DsRadius.round),
                    border: Border.all(
                      color: DsGlassColors.borderFor(context),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DsColors.ink900.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: DsGradients.primaryHorizontal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: DsColors.surfaceLight,
                        ),
                      ),
                      const SizedBox(width: DsSpacing.md),
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? DsColors.textPrimaryDark
                              : DsColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
