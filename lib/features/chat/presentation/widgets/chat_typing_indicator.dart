import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

/// Animated typing indicator showing when the other user is typing.
class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({super.key, required this.name});

  final String name;

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start animations with staggered delays
    for (var i = 0; i < _controllers.length; i++) {
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
    final baseSurface = DsGlassColors.surfaceFor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Animated dots container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: baseSurface.withValues(alpha: isDark ? 0.6 : 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DsGlassColors.borderFor(context),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  AnimatedBuilder(
                    animation: _animations[i],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -4 * _animations[i].value),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DsColors.primary.withValues(
                              alpha: 0.5 + (_animations[i].value * 0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (i < 2) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          DsGap.smH,
          Text(
            '${widget.name} is typing',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
