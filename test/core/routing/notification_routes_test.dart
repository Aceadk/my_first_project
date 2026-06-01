import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/routing/notification_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationRouteResolver', () {
    test('maps message and match payloads to chat routes', () {
      expect(
        NotificationRouteResolver.resolve({
          'type': 'message',
          'matchId': 'match-1',
        }).route,
        '${CrushRoutes.chat}/match-1',
      );

      expect(
        NotificationRouteResolver.resolve({
          'type': 'match',
          'targetId': 'match-2',
        }).route,
        '${CrushRoutes.chat}/match-2',
      );
    });

    test('allows only known payload routes', () {
      expect(
        NotificationRouteResolver.resolve({
          'targetRoute': '${CrushRoutes.chat}/match-3',
        }).route,
        '${CrushRoutes.chat}/match-3',
      );

      expect(
        NotificationRouteResolver.resolve({
          'targetRoute': 'https://example.com/phish',
          'type': 'system',
        }).route,
        CrushRoutes.notificationCenter,
      );
    });

    test('normalizes legacy account action route', () {
      expect(
        NotificationRouteResolver.resolve({
          'route': '/settings/account-actions',
        }).route,
        CrushRoutes.accountSettings,
      );
    });

    test('falls back to notification center for malformed payloads', () {
      expect(
        NotificationRouteResolver.resolve({'type': 'unknown'}).route,
        CrushRoutes.notificationCenter,
      );
    });
  });
}
