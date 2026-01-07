import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// A reusable empty state widget for when there's no content to display.
class CrushEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? customIcon;
  final double iconSize;

  const CrushEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.customIcon,
    this.iconSize = 72,
  });

  /// Empty state for no matches.
  factory CrushEmptyState.noMatches({
    VoidCallback? onKeepSwiping,
  }) {
    return CrushEmptyState(
      icon: Icons.favorite_border,
      title: 'No matches yet',
      subtitle: 'Keep swiping and sending message requests.\nWhen you match with someone, they will appear here.',
      actionLabel: 'Keep swiping',
      onAction: onKeepSwiping,
    );
  }

  /// Empty state for no messages/chats.
  factory CrushEmptyState.noMessages({
    VoidCallback? onFindMatches,
  }) {
    return CrushEmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'No conversations yet',
      subtitle: 'When you match with someone, you can start chatting here.',
      actionLabel: 'Find matches',
      onAction: onFindMatches,
    );
  }

  /// Empty state for no people nearby.
  factory CrushEmptyState.noPeopleNearby({
    VoidCallback? onChangeFilters,
    VoidCallback? onTryPassport,
    bool showPassportOption = true,
  }) {
    return CrushEmptyState(
      icon: Icons.people_outline,
      title: "You're all caught up!",
      subtitle: 'There are no more people nearby right now.\nTry adjusting your filters or exploring with Passport.',
      actionLabel: 'Change filters',
      onAction: onChangeFilters,
      secondaryActionLabel: showPassportOption ? 'Try Passport' : null,
      onSecondaryAction: onTryPassport,
    );
  }

  /// Empty state for connection error.
  factory CrushEmptyState.connectionError({
    VoidCallback? onRetry,
    String? message,
  }) {
    return CrushEmptyState(
      icon: Icons.wifi_off,
      title: 'Connection issue',
      subtitle: message ?? 'Check your internet connection and try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  /// Empty state for incomplete profile.
  factory CrushEmptyState.incompleteProfile({
    VoidCallback? onCompleteProfile,
    double completionPercent = 0,
  }) {
    return CrushEmptyState(
      icon: Icons.person_outline,
      title: 'Complete your profile',
      subtitle: 'Add photos and a bio to start matching with others.',
      actionLabel: 'Complete profile',
      onAction: onCompleteProfile,
      customIcon: _ProfileCompletionIcon(percent: completionPercent),
    );
  }

  /// Empty state for search with no results.
  factory CrushEmptyState.noSearchResults({
    VoidCallback? onClearSearch,
    String? query,
  }) {
    return CrushEmptyState(
      icon: Icons.search_off,
      title: 'No results found',
      subtitle: query != null ? 'No matches for "$query"' : 'Try a different search term.',
      actionLabel: 'Clear search',
      onAction: onClearSearch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ??
                Icon(
                  icon,
                  size: iconSize,
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
            const SizedBox(height: DsSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DsSpacing.sm),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DsSpacing.xxl),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: DsSpacing.md),
              OutlinedButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionIcon extends StatelessWidget {
  final double percent;

  const _ProfileCompletionIcon({required this.percent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 6,
              backgroundColor: isDark ? DsColors.borderDark : DsColors.borderLight,
              color: DsColors.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// An animated empty state that slides and fades in.
class CrushAnimatedEmptyState extends StatefulWidget {
  final CrushEmptyState child;
  final Duration delay;

  const CrushAnimatedEmptyState({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<CrushAnimatedEmptyState> createState() => _CrushAnimatedEmptyStateState();
}

class _CrushAnimatedEmptyStateState extends State<CrushAnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
