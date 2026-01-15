import 'dart:ui';

import 'package:flutter/material.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// A navigation item for the [GlassBottomNavBar].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
    this.badgeCount = 0,
  });

  /// Icon when not selected.
  final IconData icon;

  /// Icon when selected.
  final IconData activeIcon;

  /// Label text for the item.
  final String label;

  /// Gradient to use when selected.
  final LinearGradient gradient;

  /// Badge count to display. Shows badge if > 0.
  final int badgeCount;
}

/// A frosted glass bottom navigation bar with animated tab indicators.
///
/// Features:
/// - Frosted glass background with blur effect
/// - Animated pill-style selected indicator
/// - Gradient glow on selected item
/// - Smooth transitions between states
///
/// Example:
/// ```dart
/// GlassBottomNavBar(
///   currentIndex: _selectedIndex,
///   onTap: (index) => setState(() => _selectedIndex = index),
///   items: [
///     GlassNavItem(
///       icon: Icons.home_outlined,
///       activeIcon: Icons.home,
///       label: 'Home',
///       gradient: DsGradients.discover,
///     ),
///     // ... more items
///   ],
/// )
/// ```
class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.blur = DsBlur.heavy,
    this.backgroundColor,
    this.height = 80,
  });

  /// Currently selected index.
  final int currentIndex;

  /// Callback when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Navigation items to display.
  final List<GlassNavItem> items;

  /// Blur sigma for the glass effect.
  final double blur;

  /// Override background color.
  final Color? backgroundColor;

  /// Height of the nav bar.
  final double height;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark
            ? DsGlassColors.surfaceHeavyDark
            : DsGlassColors.surfaceHeavyLight);

    final borderColor =
        isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight;

    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.sm,
                  vertical: DsSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    return _GlassNavItemWidget(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onTap(index),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItemWidget extends StatelessWidget {
  const _GlassNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final inactiveColor =
        isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    // Build accessibility label
    final semanticLabel = StringBuffer(item.label);
    if (item.badgeCount > 0) {
      semanticLabel.write(', ${item.badgeCount} new');
    }
    if (isSelected) {
      semanticLabel.write(', selected');
    }

    return Semantics(
      label: semanticLabel.toString(),
      button: true,
      selected: isSelected,
      hint: 'Double tap to navigate to ${item.label}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? DsSpacing.lg : DsSpacing.md,
          vertical: DsSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? item.gradient : null,
          borderRadius: BorderRadius.circular(DsRadius.round),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.gradient.colors.first.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey(isSelected),
                    size: 24,
                    color: isSelected ? Colors.white : inactiveColor,
                  ),
                ),
                // Badge
                if (item.badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: _NavBadge(count: item.badgeCount),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: DsSpacing.sm),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Badge widget for nav items.
class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : count.toString();
    final isSmall = count < 10;

    return Container(
      constraints: BoxConstraints(
        minWidth: isSmall ? 18 : 22,
        minHeight: 18,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 0 : 5,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DsColors.primary, Color(0xFFFF6B9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: DsColors.primary.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
