import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/gradients.dart';
import 'glass_button.dart';

/// A polished empty state widget with icon, message, and optional action.
class DsEmptyState extends StatelessWidget {
  const DsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconGradient,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  /// Icon to display (use large icon for visual impact).
  final IconData icon;

  /// Main title text.
  final String title;

  /// Optional description message.
  final String? message;

  /// Primary action button label.
  final String? actionLabel;

  /// Primary action callback.
  final VoidCallback? onAction;

  /// Icon color (or use iconGradient for gradient effect).
  final Color? iconColor;

  /// Gradient to apply to the icon container.
  final LinearGradient? iconGradient;

  /// Secondary action label.
  final String? secondaryActionLabel;

  /// Secondary action callback.
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;
    final mutedColor = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    final effectiveIconColor = iconColor ?? DsColors.primary;

    return Padding(
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: iconGradient ??
                    LinearGradient(
                      colors: [
                        effectiveIconColor.withValues(alpha: 0.2),
                        effectiveIconColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveIconColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: effectiveIconColor,
              ),
            ),
          ),
          const SizedBox(height: DsSpacing.xl),
          // Title with fade-in animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: DsSpacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: DsSpacing.xl),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: GlassPrimaryButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: DsSpacing.sm),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state for no matches found.
class EmptyStateNoMatches extends StatelessWidget {
  const EmptyStateNoMatches({super.key, this.onRefresh, this.onAdjustFilters});

  final VoidCallback? onRefresh;
  final VoidCallback? onAdjustFilters;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      icon: Icons.favorite_border,
      iconColor: DsColors.primary,
      title: 'No matches yet',
      message: 'Keep swiping to find your perfect match!',
      actionLabel: 'Start swiping',
      onAction: onRefresh,
      secondaryActionLabel: 'Adjust filters',
      onSecondaryAction: onAdjustFilters,
    );
  }
}

/// Empty state for no messages in chat.
class EmptyStateNoMessages extends StatelessWidget {
  const EmptyStateNoMessages({super.key, required this.otherName, this.onSendHi});

  final String otherName;
  final VoidCallback? onSendHi;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      icon: Icons.chat_bubble_outline,
      iconColor: DsColors.secondary,
      title: 'Say hello!',
      message: 'Start a conversation with $otherName',
      actionLabel: 'Send a message',
      onAction: onSendHi,
    );
  }
}

/// Empty state for no people in deck.
class EmptyStateDeck extends StatelessWidget {
  const EmptyStateDeck({
    super.key,
    this.onRefresh,
    this.onExpandSearch,
    this.locationLabel,
  });

  final VoidCallback? onRefresh;
  final VoidCallback? onExpandSearch;
  final String? locationLabel;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      icon: Icons.explore_outlined,
      iconGradient: DsGradients.discover,
      title: 'All caught up!',
      message: locationLabel != null
          ? 'No more people near $locationLabel right now.\nCheck back soon or expand your search.'
          : 'No more people nearby right now.\nCheck back soon or expand your search.',
      actionLabel: 'Refresh',
      onAction: onRefresh,
      secondaryActionLabel: 'Expand search',
      onSecondaryAction: onExpandSearch,
    );
  }
}

/// Empty state for search results.
class EmptyStateSearch extends StatelessWidget {
  const EmptyStateSearch({super.key, required this.query, this.onClear});

  final String query;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      icon: Icons.search_off,
      iconColor: DsColors.textMutedLight,
      title: 'No results found',
      message: 'We couldn\'t find anything matching "$query"',
      actionLabel: 'Clear search',
      onAction: onClear,
    );
  }
}

/// Empty state for error with retry.
class EmptyStateError extends StatelessWidget {
  const EmptyStateError({
    super.key,
    this.message,
    this.onRetry,
  });

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      icon: Icons.error_outline,
      iconColor: DsColors.error,
      title: 'Something went wrong',
      message: message ?? 'An unexpected error occurred. Please try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

/// Empty state for no internet connection.
class EmptyStateOffline extends StatelessWidget {
  const EmptyStateOffline({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      icon: Icons.wifi_off,
      iconColor: DsColors.textMutedLight,
      title: 'No internet connection',
      message: 'Check your connection and try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

/// Empty state for weekly picks.
class EmptyStateWeeklyPicks extends StatelessWidget {
  const EmptyStateWeeklyPicks({super.key, this.nextRefreshTime});

  final String? nextRefreshTime;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      icon: Icons.auto_awesome,
      iconGradient: DsGradients.primaryVertical,
      title: 'Fresh picks coming soon!',
      message: nextRefreshTime != null
          ? 'New weekly picks in $nextRefreshTime'
          : 'Check back later for your curated weekly picks.',
    );
  }
}
