import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../theme/theme_extensions.dart';

/// Animated typing indicator with three bouncing dots.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.dotColor,
    this.backgroundColor,
    this.dotSize = 8.0,
    this.spacing = 4.0,
    this.showGlassBackground = true,
  });

  /// Color of the dots.
  final Color? dotColor;

  /// Background color of the container.
  final Color? backgroundColor;

  /// Size of each dot.
  final double dotSize;

  /// Spacing between dots.
  final double spacing;

  /// Whether to show the glass background.
  final bool showGlassBackground;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -8,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // Start animations with stagger
    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor =
        widget.dotColor ??
        (isDark ? DsColors.textMutedDark : DsColors.textMutedLight);
    final bgColor = widget.backgroundColor ?? DsGlassColors.surfaceFor(context);

    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );

    if (!widget.showGlassBackground) {
      return dots;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.md,
            vertical: DsSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(DsRadius.lg),
            border: Border.all(
              color: DsGlassColors.borderFor(context),
              width: 0.5,
            ),
          ),
          child: dots,
        ),
      ),
    );
  }
}

/// A chat bubble showing that the other user is typing.
class TypingBubble extends StatelessWidget {
  const TypingBubble({
    super.key,
    this.userName,
    this.showAvatar = true,
    this.avatarUrl,
  });

  /// Name of the user typing (optional).
  final String? userName;

  /// Whether to show the avatar.
  final bool showAvatar;

  /// URL of the avatar image.
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: DsGlassColors.surfaceFor(
                context,
                strength: DsGlassSurfaceStrength.medium,
              ),
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.grey,
                    )
                  : null,
            ),
            const SizedBox(width: DsSpacing.sm),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userName != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: DsSpacing.xs,
                    bottom: DsSpacing.xs / 2,
                  ),
                  child: Text(
                    userName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                ),
              const TypingIndicator(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated fade-in wrapper for typing indicator.
class AnimatedTypingIndicator extends StatelessWidget {
  const AnimatedTypingIndicator({
    super.key,
    required this.isTyping,
    this.userName,
    this.avatarUrl,
  });

  final bool isTyping;
  final String? userName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final motionScale =
        Theme.of(context).extension<CrushThemeEffects>()?.motionScale ?? 1.0;
    return AnimatedSwitcher(
      duration: Duration(milliseconds: (200 * motionScale).round()),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isTyping
          ? TypingBubble(
              key: const ValueKey('typing'),
              userName: userName,
              avatarUrl: avatarUrl,
            )
          : const SizedBox.shrink(key: ValueKey('not_typing')),
    );
  }
}
