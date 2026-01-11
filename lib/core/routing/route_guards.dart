import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../feature_flags/feature_flags.dart';

/// Route guard result indicating whether navigation should proceed.
class RouteGuardResult {
  const RouteGuardResult.allow() : allowed = true, redirect = null, message = null;
  const RouteGuardResult.deny({this.redirect, this.message}) : allowed = false;

  final bool allowed;
  final String? redirect;
  final String? message;
}

/// Base class for route guards.
abstract class RouteGuard {
  const RouteGuard();

  /// Check if the route should be allowed.
  /// Return null to allow, or a redirect path to deny.
  Future<RouteGuardResult> canActivate(BuildContext context, GoRouterState state);
}

/// Guard that requires a specific feature flag to be enabled.
class FeatureFlagGuard extends RouteGuard {
  const FeatureFlagGuard(this.flag, {this.redirectTo});

  final FeatureFlag flag;
  final String? redirectTo;

  @override
  Future<RouteGuardResult> canActivate(BuildContext context, GoRouterState state) async {
    if (flag.isEnabled) {
      return const RouteGuardResult.allow();
    }
    return RouteGuardResult.deny(
      redirect: redirectTo,
      message: 'This feature is not available.',
    );
  }
}

/// Guard that requires premium subscription.
class PremiumGuard extends RouteGuard {
  const PremiumGuard({this.redirectTo, this.showUpsell = true});

  final String? redirectTo;
  final bool showUpsell;

  @override
  Future<RouteGuardResult> canActivate(BuildContext context, GoRouterState state) async {
    // Check if any premium feature is enabled (user is premium)
    final isPremium = FeatureFlagService.instance.isAnyEnabled(
      FeatureFlag.values.where((f) => f.isPremium).toList(),
    );

    if (isPremium) {
      return const RouteGuardResult.allow();
    }

    return RouteGuardResult.deny(
      redirect: redirectTo,
      message: 'Upgrade to Plus to access this feature.',
    );
  }
}

/// Guard that requires multiple feature flags.
class MultiFeatureFlagGuard extends RouteGuard {
  const MultiFeatureFlagGuard(
    this.flags, {
    this.requireAll = true,
    this.redirectTo,
  });

  final List<FeatureFlag> flags;
  final bool requireAll;
  final String? redirectTo;

  @override
  Future<RouteGuardResult> canActivate(BuildContext context, GoRouterState state) async {
    final service = FeatureFlagService.instance;
    final allowed = requireAll
        ? service.areAllEnabled(flags)
        : service.isAnyEnabled(flags);

    if (allowed) {
      return const RouteGuardResult.allow();
    }

    return RouteGuardResult.deny(
      redirect: redirectTo,
      message: 'This feature is not available.',
    );
  }
}

/// Guard that requires a feature to be enabled (kill switch).
class KillSwitchGuard extends RouteGuard {
  const KillSwitchGuard(this.flag, {this.message});

  final FeatureFlag flag;
  final String? message;

  @override
  Future<RouteGuardResult> canActivate(BuildContext context, GoRouterState state) async {
    if (flag.isEnabled) {
      return const RouteGuardResult.allow();
    }

    return RouteGuardResult.deny(
      message: message ?? 'This feature is temporarily unavailable.',
    );
  }
}

/// Composite guard that combines multiple guards.
class CompositeGuard extends RouteGuard {
  const CompositeGuard(this.guards);

  final List<RouteGuard> guards;

  @override
  Future<RouteGuardResult> canActivate(BuildContext context, GoRouterState state) async {
    for (final guard in guards) {
      final result = await guard.canActivate(context, state);
      if (!result.allowed) {
        return result;
      }
    }
    return const RouteGuardResult.allow();
  }
}

/// Route configuration with guards.
class GuardedRoute {
  const GuardedRoute({
    required this.path,
    required this.builder,
    this.guards = const [],
    this.name,
  });

  final String path;
  final Widget Function(BuildContext context, GoRouterState state) builder;
  final List<RouteGuard> guards;
  final String? name;

  /// Convert to GoRoute with guard integration.
  GoRoute toGoRoute({String? Function(BuildContext, GoRouterState)? baseRedirect}) {
    return GoRoute(
      path: path,
      name: name,
      redirect: (context, state) async {
        // Check base redirect first
        final baseResult = baseRedirect?.call(context, state);
        if (baseResult != null) return baseResult;

        // Check all guards
        for (final guard in guards) {
          final result = await guard.canActivate(context, state);
          if (!result.allowed) {
            if (result.message != null) {
              // Show a snackbar with the message if we have a context
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message!)),
                  );
                }
              });
            }
            return result.redirect;
          }
        }
        return null;
      },
      pageBuilder: (context, state) => _buildPage(state, builder(context, state)),
    );
  }
}

CustomTransitionPage<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.02),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
