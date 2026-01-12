import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crushhour/shared/utils/profile_completeness.dart';

class DeckActionButton extends StatefulWidget {
  const DeckActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<DeckActionButton> createState() => _DeckActionButtonState();
}

class _DeckActionButtonState extends State<DeckActionButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.08 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(widget.icon, color: Colors.black),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }
}

class DeckStatusBar extends StatelessWidget {
  const DeckStatusBar({
    super.key,
    required this.isLoading,
    required this.retryInSeconds,
    required this.completeness,
  });

  final bool isLoading;
  final int? retryInSeconds;
  final ProfileCompletenessSummary completeness;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (retryInSeconds != null) {
      return Container(
        width: double.infinity,
        color: Colors.orange.withAlpha((0.08 * 255).round()),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.refresh, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Retrying in ~${retryInSeconds}s…',
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        ),
      );
    }

    if (!completeness.meetsSwipeMinimum) {
      final percent = (completeness.score * 100).round();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: completeness.score, minHeight: 6),
            const SizedBox(height: 8),
            Text(
              'Profile completeness: $percent% — finish your profile to swipe and message.',
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 2);
  }
}
