import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/design_system/widgets/empty_state.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

/// Fallback screen for unknown routes.
///
/// Shown by the router's `errorPageBuilder` instead of the auth gateway so
/// that signed-in users who hit a stale or mistyped URL (most common on web)
/// are not presented with a login screen while still authenticated.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: DsEmptyState(
            icon: Icons.explore_off_outlined,
            title: l10n.pageNotFoundTitle,
            message: l10n.pageNotFoundMessage,
            actionLabel: l10n.goToHome,
            onAction: () => context.go(CrushRoutes.home),
          ),
        ),
      ),
    );
  }
}
