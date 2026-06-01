import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/routing/deep_links.dart';

class NotificationRouteResolution {
  const NotificationRouteResolution({
    required this.route,
    required this.source,
    this.usedPayloadRoute = false,
  });

  final String route;
  final String source;
  final bool usedPayloadRoute;
}

class NotificationRouteResolver {
  static const _fallbackRoute = CrushRoutes.notificationCenter;

  static const _allowedExactRoutes = <String>{
    CrushRoutes.home,
    CrushRoutes.notificationCenter,
    CrushRoutes.likesYou,
    CrushRoutes.weeklyPicks,
    CrushRoutes.messageRequests,
    CrushRoutes.callHistory,
    CrushRoutes.safety,
    CrushRoutes.settings,
    CrushRoutes.notificationsSettings,
    CrushRoutes.accountSettings,
    CrushRoutes.chatSettings,
    CrushRoutes.subscriptionSettings,
    CrushRoutes.profile,
    CrushRoutes.profileInsights,
    CrushRoutes.paywall,
  };

  static NotificationRouteResolution resolve(Map<String, dynamic> data) {
    final explicitRoute =
        _sanitizeRoute(_stringValue(data, 'targetRoute')) ??
        _sanitizeRoute(_stringValue(data, 'route')) ??
        _sanitizeRoute(_stringValue(data, 'deepLink'));
    if (explicitRoute != null) {
      return NotificationRouteResolution(
        route: explicitRoute,
        source: 'payload',
        usedPayloadRoute: true,
      );
    }

    final type =
        (_stringValue(data, 'type') ??
                _stringValue(data, 'notificationType') ??
                '')
            .toLowerCase();
    final targetId =
        _stringValue(data, 'targetId') ??
        _stringValue(data, 'matchId') ??
        _stringValue(data, 'conversationId');

    final route = switch (type) {
      'message' || 'match' =>
        targetId != null ? '${CrushRoutes.chat}/$targetId' : CrushRoutes.home,
      'message_request' => CrushRoutes.messageRequests,
      'like' || 'super_like' => CrushRoutes.likesYou,
      'missed_call' => CrushRoutes.callHistory,
      'incoming_call' || 'call' => CrushRoutes.incomingCall,
      'call_safety_alert' || 'safety_alert' => CrushRoutes.safety,
      'profile_view' => CrushRoutes.notificationCenter,
      'weekly_picks' => CrushRoutes.weeklyPicks,
      'subscription' => CrushRoutes.subscriptionSettings,
      'data_export_ready' => CrushRoutes.accountSettings,
      'boost_expired' || 'system' => CrushRoutes.notificationCenter,
      _ => _fallbackRoute,
    };

    return NotificationRouteResolution(route: route, source: 'type:$type');
  }

  static String? _sanitizeRoute(String? rawRoute) {
    final trimmed = rawRoute?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (uri.hasScheme) {
      final deepLink = DeepLinkConfig.parse(uri);
      return _allowPath(deepLink?.fullPath);
    }

    if (!trimmed.startsWith('/')) return null;
    return _allowPath(trimmed);
  }

  static String? _allowPath(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return null;

    final uri = Uri.tryParse(rawPath);
    if (uri == null || uri.hasScheme || uri.host.isNotEmpty) return null;

    final path = uri.path;
    final normalizedPath = switch (path) {
      '/settings/account-actions' => CrushRoutes.accountSettings,
      _ => path,
    };

    final allowed =
        _allowedExactRoutes.contains(normalizedPath) ||
        _isParameterizedRoute(normalizedPath);
    if (!allowed) return null;

    final query = uri.query.isEmpty ? '' : '?${uri.query}';
    return '$normalizedPath$query';
  }

  static bool _isParameterizedRoute(String path) {
    if (path.startsWith('${CrushRoutes.chat}/')) {
      return path.length > '${CrushRoutes.chat}/'.length;
    }
    if (path.startsWith('${CrushRoutes.userProfile}/')) {
      return path.length > '${CrushRoutes.userProfile}/'.length;
    }
    if (path.startsWith('${CrushRoutes.supportCategoryBase}/')) {
      return path.length > '${CrushRoutes.supportCategoryBase}/'.length;
    }
    return false;
  }

  static String? _stringValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }
}
