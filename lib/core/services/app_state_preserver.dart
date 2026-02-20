import 'package:shared_preferences/shared_preferences.dart';

/// Service to preserve and restore app state across background/foreground transitions.
/// This allows the app to resume where the user left off instead of always starting from splash.
class AppStatePreserver {
  static const String _lastRouteKey = 'app_last_route';
  static const String _lastRouteTimestampKey = 'app_last_route_timestamp';

  /// Maximum time (in milliseconds) to consider a saved route as valid.
  /// After this time, we start fresh from splash/home.
  /// Set to 30 minutes - if app was in background longer, start fresh.
  static const int _maxRouteAgeMs = 30 * 60 * 1000;

  static AppStatePreserver? _instance;
  static AppStatePreserver get instance => _instance ??= AppStatePreserver._();

  AppStatePreserver._();

  SharedPreferences? _prefs;
  String? _currentRoute;

  /// Initialize with SharedPreferences instance
  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// Save the current route when app goes to background
  Future<void> saveCurrentRoute(String route) async {
    if (_prefs == null) return;

    // Don't save splash, auth routes, or onboarding routes
    if (_shouldNotPreserve(route)) return;

    _currentRoute = route;
    await _prefs!.setString(_lastRouteKey, route);
    await _prefs!.setInt(
      _lastRouteTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get the last saved route if it's still valid
  String? getPreservedRoute() {
    if (_prefs == null) return null;

    final route = _prefs!.getString(_lastRouteKey);
    final timestamp = _prefs!.getInt(_lastRouteTimestampKey);

    if (route == null || timestamp == null) return null;

    // Check if route is still valid (not too old)
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _maxRouteAgeMs) {
      // Route is too old, clear it
      clearPreservedRoute();
      return null;
    }

    // Don't restore auth/onboarding routes
    if (_shouldNotPreserve(route)) {
      clearPreservedRoute();
      return null;
    }

    return route;
  }

  /// Clear the preserved route (call after successful restoration or on logout)
  Future<void> clearPreservedRoute() async {
    if (_prefs == null) return;
    await _prefs!.remove(_lastRouteKey);
    await _prefs!.remove(_lastRouteTimestampKey);
    _currentRoute = null;
  }

  /// Get current in-memory route
  String? get currentRoute => _currentRoute;

  /// Update current route (call from router observer)
  void updateCurrentRoute(String route) {
    if (!_shouldNotPreserve(route)) {
      _currentRoute = route;
    }
  }

  /// Check if a route should NOT be preserved
  bool _shouldNotPreserve(String route) {
    return route == '/' ||
        route == '/splash' ||
        route.startsWith('/auth') ||
        route == '/terms-conditions' ||
        route == '/basic-info' ||
        route == '/profile-setup' ||
        route == '/id-verification' ||
        route == '/email-verification' ||
        route == '/logout';
  }
}
