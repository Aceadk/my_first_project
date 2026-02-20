import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';

/// Animated reaction button with scale effect on tap.
class ChatReactionButton extends StatefulWidget {
  const ChatReactionButton({
    super.key,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<ChatReactionButton> createState() => _ChatReactionButtonState();
}

class _ChatReactionButtonState extends State<ChatReactionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isSelected
          ? 'Remove ${widget.emoji} reaction'
          : 'React with ${widget.emoji}',
      toggled: widget.isSelected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: widget.isSelected
                    ? BoxDecoration(
                        color: DsColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  widget.emoji,
                  style: TextStyle(fontSize: widget.isSelected ? 28 : 24),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
