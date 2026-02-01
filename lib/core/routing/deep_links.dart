import 'package:flutter/foundation.dart';
import 'package:crushhour/core/router.dart';

/// Deep link configuration for the app.
///
/// Supported URL schemes:
/// - crushhour://  (custom scheme)
/// - https://crushhour.app/  (universal links)
///
/// Deep link paths:
/// - /user-profile/:userId - View a user's profile
/// - /chat/:matchId - Open a chat
/// - /match/:matchId - View a match (routes to chat)
/// - /settings - Open settings
/// - /premium or /upgrade - Open settings (subscription section)
/// - /auth/login - Login
/// - /auth/signup - Signup
/// - /auth/reset - Password reset
/// - /email-verification - Email verification
/// - /privacy-policy - Privacy policy
/// - /terms-of-service - Terms of service
class DeepLinkConfig {
  static const String customScheme = 'crushhour';
  static const String universalHost = 'crushhour.app';
  static const String universalHostWww = 'www.crushhour.app';

  /// Parse a deep link URI and return the corresponding app route.
  static DeepLinkResult? parse(Uri uri) {
    // Check if this is a valid deep link
    if (!_isValidDeepLink(uri)) {
      return null;
    }

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) {
      return const DeepLinkResult(route: CrushRoutes.home);
    }

    final firstSegment = pathSegments.first;

    switch (firstSegment) {
      case 'profile':
        if (pathSegments.length >= 2) {
          final userId = pathSegments[1];
          return DeepLinkResult(
            route: '${CrushRoutes.userProfile}/$userId',
            params: {'userId': userId},
            requiresAuth: true,
          );
        }
        return null;

      case 'chat':
        if (pathSegments.length >= 2) {
          final matchId = pathSegments[1];
          return DeepLinkResult(
            route: '${CrushRoutes.chat}/$matchId',
            params: {'matchId': matchId},
            requiresAuth: true,
          );
        }
        return null;

      case 'match':
        if (pathSegments.length >= 2) {
          final matchId = pathSegments[1];
          return DeepLinkResult(
            route: '${CrushRoutes.chat}/$matchId',
            params: {'matchId': matchId},
            requiresAuth: true,
          );
        }
        return null;

      case 'settings':
        return const DeepLinkResult(
          route: CrushRoutes.settings,
          requiresAuth: true,
        );

      case 'premium':
      case 'upgrade':
        return const DeepLinkResult(
          route: CrushRoutes.settings,
          requiresAuth: true,
        );

      case 'verify':
        final token = uri.queryParameters['token'];
        if (token != null) {
          return DeepLinkResult(
            route: CrushRoutes.emailProtection,
            queryParams: {'token': token},
          );
        }
        return null;

      case 'verify-email':
        // Email verification magic link for sign up
        final email = uri.queryParameters['email'];
        final token = uri.queryParameters['token'];
        return DeepLinkResult(
          route: CrushRoutes.emailVerification,
          queryParams: {
            'email': ?email,
            'token': ?token,
          },
        );

      case 'reset-password':
        final token = uri.queryParameters['token'];
        if (token != null) {
          return DeepLinkResult(
            route: CrushRoutes.resetPassword,
            queryParams: {'token': token},
          );
        }
        return null;

      case 'login':
        return const DeepLinkResult(route: CrushRoutes.login);

      case 'signup':
        final referral = uri.queryParameters['ref'];
        return DeepLinkResult(
          route: CrushRoutes.signUp,
          queryParams: referral != null ? {'ref': referral} : null,
        );

      default:
        // Try to match known routes directly
        final knownRoutes = [
          CrushRoutes.home,
          CrushRoutes.safety,
          CrushRoutes.profile,
          CrushRoutes.settings,
          CrushRoutes.authGateway,
          CrushRoutes.privacyPolicy,
          CrushRoutes.termsOfService,
        ];
        final path = '/${pathSegments.join('/')}';
        if (knownRoutes.any((r) => path.startsWith(r))) {
          return DeepLinkResult(route: path);
        }
        return null;
    }
  }

  static bool _isValidDeepLink(Uri uri) {
    // Custom scheme
    if (uri.scheme == customScheme) {
      return true;
    }

    // Universal links (HTTPS)
    if (uri.scheme == 'https' &&
        (uri.host == universalHost || uri.host == universalHostWww)) {
      return true;
    }

    // For debugging in debug mode
    if (kDebugMode && uri.scheme == 'http' && uri.host == 'localhost') {
      return true;
    }

    return false;
  }

  /// Build a deep link URL for sharing.
  static Uri buildShareLink({
    required String path,
    Map<String, String>? queryParams,
    bool useUniversalLink = true,
  }) {
    if (useUniversalLink) {
      return Uri(
        scheme: 'https',
        host: universalHost,
        path: path,
        queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
      );
    }

    return Uri(
      scheme: customScheme,
      host: '',
      path: path,
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
  }

  /// Build a profile share link.
  static Uri buildProfileShareLink(String userId) {
    return buildShareLink(path: '${CrushRoutes.userProfile}/$userId');
  }

  /// Build a referral signup link.
  static Uri buildReferralLink(String referralCode) {
    return buildShareLink(
      path: '/signup',
      queryParams: {'ref': referralCode},
    );
  }
}

/// Result of parsing a deep link.
class DeepLinkResult {
  const DeepLinkResult({
    required this.route,
    this.params,
    this.queryParams,
    this.requiresAuth = false,
    this.extra,
  });

  /// The app route to navigate to.
  final String route;

  /// Path parameters extracted from the deep link.
  final Map<String, String>? params;

  /// Query parameters to pass to the route.
  final Map<String, String>? queryParams;

  /// Whether the route requires authentication.
  final bool requiresAuth;

  /// Extra data to pass to the route.
  final Object? extra;

  /// Build the full route path with query parameters.
  String get fullPath {
    if (queryParams == null || queryParams!.isEmpty) {
      return route;
    }
    final query = queryParams!.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$route?$query';
  }

  @override
  String toString() =>
      'DeepLinkResult(route: $route, params: $params, requiresAuth: $requiresAuth)';
}

/// Handler for processing incoming deep links.
class DeepLinkHandler {
  DeepLinkHandler({
    required this.onNavigate,
    required this.onAuthRequired,
  });

  /// Callback to navigate to a route.
  final void Function(String route, {Object? extra}) onNavigate;

  /// Callback when auth is required but user is not logged in.
  /// Returns the pending deep link to process after login.
  final void Function(DeepLinkResult pendingLink) onAuthRequired;

  DeepLinkResult? _pendingLink;

  /// Get any pending deep link waiting to be processed after auth.
  DeepLinkResult? get pendingLink => _pendingLink;

  /// Clear the pending deep link.
  void clearPendingLink() {
    _pendingLink = null;
  }

  /// Handle an incoming deep link.
  void handleDeepLink(Uri uri, {required bool isAuthenticated}) {
    final result = DeepLinkConfig.parse(uri);
    if (result == null) {
      return;
    }

    if (result.requiresAuth && !isAuthenticated) {
      // Store for processing after login
      _pendingLink = result;
      onAuthRequired(result);
      return;
    }

    onNavigate(result.fullPath, extra: result.extra);
  }

  /// Process any pending deep link after successful authentication.
  void processPendingLink() {
    final link = _pendingLink;
    if (link != null) {
      _pendingLink = null;
      onNavigate(link.fullPath, extra: link.extra);
    }
  }
}
