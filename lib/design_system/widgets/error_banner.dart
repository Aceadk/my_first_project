import 'package:flutter/material.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  /// Optional action button label (e.g. "Try Again", "Change Filters").
  final String? actionLabel;

  /// Callback when the action button is tapped.
  final VoidCallback? onAction;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.error.withValues(alpha: 0.1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DsRadius.md),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: DsSpacing.xs,
                    ),
                    child: GestureDetector(
                      onTap: onAction,
                      child: Text(
                        actionLabel!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: theme.colorScheme.error,
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
