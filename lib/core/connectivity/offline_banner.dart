import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/connectivity/connectivity_cubit.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';

/// A banner that appears at the top of the screen when offline.
///
/// Auto-dismisses when connectivity is restored. Wrap screens or scaffold
/// bodies with this widget to show an offline indicator.
///
/// ```dart
/// OfflineBanner(
///   child: MyScreenContent(),
/// )
/// ```
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        return Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                );
              },
              child: status == ConnectivityStatus.offline
                  ? const _OfflineBar(key: ValueKey('offline'))
                  : const SizedBox.shrink(key: ValueKey('online')),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.lg,
        vertical: DsSpacing.sm,
      ),
      color: DsColors.warning,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: DsColors.ink900),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(
              ErrorMessages.offline.split('.').first,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DsColors.ink900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
