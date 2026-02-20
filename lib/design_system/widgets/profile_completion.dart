import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// A circular progress indicator showing profile completion percentage.
class ProfileCompletionIndicator extends StatefulWidget {
  const ProfileCompletionIndicator({
    super.key,
    required this.percentage,
    this.size = 80,
    this.strokeWidth = 6,
    this.backgroundColor,
    this.showPercentage = true,
    this.animate = true,
  });

  /// Completion percentage (0.0 - 1.0).
  final double percentage;

  /// Size of the indicator.
  final double size;

  /// Width of the progress stroke.
  final double strokeWidth;

  /// Background color of the track.
  final Color? backgroundColor;

  /// Whether to show the percentage text.
  final bool showPercentage;

  /// Whether to animate the progress.
  final bool animate;

  @override
  State<ProfileCompletionIndicator> createState() =>
      _ProfileCompletionIndicatorState();
}

class _ProfileCompletionIndicatorState extends State<ProfileCompletionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.percentage,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ProfileCompletionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation =
          Tween<double>(
            begin: _animation.value,
            end: widget.percentage,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? DsGlassColors.surfaceFor(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = widget.animate ? _animation.value : widget.percentage;
        final percentText = (value * 100).round();

        return Semantics(
          label: 'Profile $percentText% complete',
          value: '$percentText%',
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _CircularProgressPainter(
                    progress: 1.0,
                    strokeWidth: widget.strokeWidth,
                    color: bgColor,
                  ),
                ),
                // Progress arc
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _CircularProgressPainter(
                    progress: value,
                    strokeWidth: widget.strokeWidth,
                    gradient: _getGradientForProgress(value),
                  ),
                ),
                // Center content (excluded from semantics — parent announces value)
                if (widget.showPercentage)
                  ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percentText%',
                          style: TextStyle(
                            fontSize: widget.size * 0.22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? DsColors.textPrimaryDark
                                : DsColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: widget.size * 0.1,
                            color: isDark
                                ? DsColors.textMutedDark
                                : DsColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getGradientForProgress(double progress) {
    if (progress < 0.3) {
      return const LinearGradient(
        colors: [DsColors.warning, Color(0xFFFF8A5B)],
      );
    } else if (progress < 0.7) {
      return const LinearGradient(
        colors: [DsColors.primary, Color(0xFFFFA3B1)],
      );
    } else {
      return const LinearGradient(
        colors: [DsColors.primary, DsColors.secondary],
      );
    }
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color? color;
  final LinearGradient? gradient;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    this.color,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color ?? Colors.grey;
    }

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.gradient != gradient;
  }
}

/// A detailed profile completion card with checklist.
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({super.key, required this.items, this.onItemTap});

  /// List of completion items.
  final List<ProfileCompletionItem> items;

  /// Callback when an incomplete item is tapped.
  final void Function(ProfileCompletionItem)? onItemTap;

  double get completionPercentage {
    if (items.isEmpty) return 0;
    final completed = items.where((item) => item.isComplete).length;
    return completed / items.length;
  }

  String _accessibilitySummary() {
    final percent = (completionPercentage * 100).round();
    final missing = items
        .where((i) => !i.isComplete)
        .map((i) => i.label)
        .toList();
    if (missing.isEmpty) return 'Profile $percent% complete';
    return 'Profile $percent% complete. Missing: ${missing.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: _accessibilitySummary(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
          child: Container(
            padding: const EdgeInsets.all(DsSpacing.lg),
            decoration: BoxDecoration(
              color: DsGlassColors.surfaceFor(
                context,
                strength: DsGlassSurfaceStrength.medium,
              ),
              borderRadius: BorderRadius.circular(DsRadius.lg),
              border: Border.all(color: DsGlassColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    ProfileCompletionIndicator(
                      percentage: completionPercentage,
                      size: 60,
                      strokeWidth: 5,
                    ),
                    const SizedBox(width: DsSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? DsColors.textPrimaryDark
                                  : DsColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getMotivationalText(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? DsColors.textMutedDark
                                  : DsColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DsSpacing.lg),

                // Checklist
                ...items.map(
                  (item) => _CompletionItemTile(
                    item: item,
                    onTap: item.isComplete ? null : () => onItemTap?.call(item),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMotivationalText() {
    final percent = (completionPercentage * 100).round();
    if (percent >= 100) {
      return 'Your profile is complete! Great job!';
    } else if (percent >= 80) {
      return 'Almost there! Just a few more steps.';
    } else if (percent >= 50) {
      return 'You\'re halfway there!';
    } else {
      return 'Complete profiles get 40% more matches!';
    }
  }
}

class _CompletionItemTile extends StatelessWidget {
  const _CompletionItemTile({required this.item, this.onTap});

  final ProfileCompletionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '${item.label}, ${item.isComplete ? 'completed' : 'incomplete'}',
      button: !item.isComplete && onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: item.isComplete
                      ? const LinearGradient(
                          colors: [DsColors.primary, DsColors.secondary],
                        )
                      : null,
                  border: item.isComplete
                      ? null
                      : Border.all(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                          width: 2,
                        ),
                ),
                child: item.isComplete
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: DsSpacing.md),
              // Icon
              Icon(
                item.icon,
                size: 20,
                color: item.isComplete
                    ? (isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight)
                    : DsColors.primary,
              ),
              const SizedBox(width: DsSpacing.sm),
              // Label
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.isComplete
                        ? (isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight)
                        : (isDark
                              ? DsColors.textPrimaryDark
                              : DsColors.textPrimaryLight),
                    decoration: item.isComplete
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              // Arrow for incomplete items
              if (!item.isComplete)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark
                      ? DsColors.textMutedDark
                      : DsColors.textMutedLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A profile completion checklist item.
class ProfileCompletionItem {
  final String id;
  final String label;
  final IconData icon;
  final bool isComplete;

  const ProfileCompletionItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.isComplete,
  });

  /// Common profile completion items.
  static List<ProfileCompletionItem> forProfile({
    required bool hasPhoto,
    required bool hasBio,
    required bool hasPrompts,
    required bool hasInterests,
    required bool hasBasicInfo,
    required bool isVerified,
  }) {
    return [
      ProfileCompletionItem(
        id: 'photo',
        label: 'Add a profile photo',
        icon: Icons.photo_camera,
        isComplete: hasPhoto,
      ),
      ProfileCompletionItem(
        id: 'bio',
        label: 'Write a bio',
        icon: Icons.edit_note,
        isComplete: hasBio,
      ),
      ProfileCompletionItem(
        id: 'prompts',
        label: 'Answer profile prompts',
        icon: Icons.chat_bubble_outline,
        isComplete: hasPrompts,
      ),
      ProfileCompletionItem(
        id: 'interests',
        label: 'Add your interests',
        icon: Icons.favorite_border,
        isComplete: hasInterests,
      ),
      ProfileCompletionItem(
        id: 'basic_info',
        label: 'Complete basic info',
        icon: Icons.person_outline,
        isComplete: hasBasicInfo,
      ),
      ProfileCompletionItem(
        id: 'verified',
        label: 'Verify your profile',
        icon: Icons.verified_outlined,
        isComplete: isVerified,
      ),
    ];
  }
}
