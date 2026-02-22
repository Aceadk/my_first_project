import 'package:crushhour/core/services/app_state_preserver.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStatePreserver', () {
    late FlutterSecureStorage secureStorage;
    late AppStatePreserver preserver;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      secureStorage = const FlutterSecureStorage();
      preserver = AppStatePreserver.instance;
      await preserver.initialize(secureStorage);
      await preserver.clearPreservedRoute();
    });

    test(
      'saveCurrentRoute stores preservable routes and restores them',
      () async {
        await preserver.saveCurrentRoute('/home');

        expect(preserver.currentRoute, '/home');
        expect(await preserver.getPreservedRoute(), '/home');
      },
    );

    test('saveCurrentRoute ignores splash/auth/onboarding routes', () async {
      const blockedRoutes = <String>[
        '/',
        '/splash',
        '/auth/login',
        '/terms-conditions',
        '/basic-info',
        '/profile-setup',
        '/id-verification',
        '/email-verification',
        '/logout',
      ];

      for (final route in blockedRoutes) {
        await preserver.clearPreservedRoute();
        await preserver.saveCurrentRoute(route);

        expect(
          await preserver.getPreservedRoute(),
          isNull,
          reason: 'Expected blocked route "$route" to never be restored.',
        );
      }
    });

    test('getPreservedRoute clears stale routes', () async {
      await secureStorage.write(key: 'app_last_route', value: '/chat/123');
      await secureStorage.write(
        key: 'app_last_route_timestamp',
        value: (DateTime.now().millisecondsSinceEpoch - (31 * 60 * 1000))
            .toString(),
      );

      expect(await preserver.getPreservedRoute(), isNull);
    });

    test('getPreservedRoute clears persisted blocked routes', () async {
      await secureStorage.write(key: 'app_last_route', value: '/auth/login');
      await secureStorage.write(
        key: 'app_last_route_timestamp',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      expect(await preserver.getPreservedRoute(), isNull);
    });

    test('updateCurrentRoute stores only preservable routes', () async {
      preserver.updateCurrentRoute('/profile');
      expect(preserver.currentRoute, '/profile');

      preserver.updateCurrentRoute('/auth/login');
      expect(
        preserver.currentRoute,
        '/profile',
        reason: 'Blocked routes should not overwrite current route.',
      );
    });

    test('clearPreservedRoute removes route and timestamp keys', () async {
      await preserver.saveCurrentRoute('/settings');
      await preserver.clearPreservedRoute();

      expect(preserver.currentRoute, isNull);
      expect(await secureStorage.read(key: 'app_last_route'), isNull);
      expect(await secureStorage.read(key: 'app_last_route_timestamp'), isNull);
    });
  });
}
