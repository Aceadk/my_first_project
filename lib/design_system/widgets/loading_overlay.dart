import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    final theme = Theme.of(context);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: DsSpacing.md),
                  Text(message!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
