import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/services/app_update_service.dart';

void main() {
  const packageInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = AppUpdateService.instance;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  group('AppUpdateService version logic', () {
    test('compareVersions supports numeric and prerelease-like inputs', () {
      expect(service.compareVersions('1.0.0', '1.0.0'), 0);
      expect(service.compareVersions('1.2.0', '1.1.9'), greaterThan(0));
      expect(service.compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(service.compareVersions('v2.0.0-beta.1', '2.0.0'), greaterThan(0));
      expect(service.compareVersions('1.0', '1.0.0.1'), lessThan(0));
    });

    test('checkVersion returns forceUpdate when below minimum and forced', () {
      final current = service.currentVersion;
      final higher = _bumpPatch(current);
      final result = service.checkVersion(
        minVersion: higher,
        forceUpdate: true,
        updateMessage: 'Update now',
      );

      expect(result.status, UpdateStatus.forceUpdate);
      expect(result.requiresUpdate, isTrue);
      expect(result.isForced, isTrue);
      expect(result.message, 'Update now');
      expect(result.toString(), contains('UpdateCheckResult('));
    });

    test('checkVersion returns updateRequired when below minimum', () {
      final current = service.currentVersion;
      final higher = _bumpPatch(current);
      final result = service.checkVersion(
        minVersion: higher,
        forceUpdate: false,
      );

      expect(result.status, UpdateStatus.updateRequired);
      expect(result.requiresUpdate, isTrue);
      expect(result.isForced, isFalse);
    });

    test('checkVersion returns updateAvailable when latest is newer', () {
      final current = service.currentVersion;
      final newer = _bumpPatch(current);
      final result = service.checkVersion(
        minVersion: current,
        latestVersion: newer,
      );

      expect(result.status, UpdateStatus.updateAvailable);
      expect(result.requiresUpdate, isFalse);
    });

    test('checkVersion returns upToDate when current satisfies latest', () {
      final current = service.currentVersion;
      final result = service.checkVersion(
        minVersion: current,
        latestVersion: current,
      );

      expect(result.status, UpdateStatus.upToDate);
      expect(result.requiresUpdate, isFalse);
    });

    test('checkWithFeatureFlags forwards values correctly', () {
      final current = service.currentVersion;
      final newer = _bumpPatch(current);
      final result = service.checkWithFeatureFlags(
        minAppVersion: current,
        latestVersion: newer,
        forceUpdate: false,
        forceUpdateMessage: 'New build available',
      );

      expect(result.status, UpdateStatus.updateAvailable);
      expect(result.message, 'New build available');
    });
  });

  group('AppUpdateService platform and initialization', () {
    test('storeUrl resolves to Play Store on non-mobile test platforms', () {
      expect(service.storeUrl, contains('play.google.com'));
    });

    test(
      'openStore returns false gracefully when launcher is unavailable',
      () async {
        final opened = await service.openStore();
        expect(opened, isFalse);
      },
    );

    test('initialize handles missing platform impl without crashing', () async {
      await service.initialize();
      expect(service.isInitialized, isFalse);
    });

    test(
      'initialize populates package metadata when channel is mocked',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(packageInfoChannel, (call) async {
              if (call.method == 'getAll') {
                return <String, dynamic>{
                  'appName': 'CrushHour',
                  'packageName': 'com.ace.crush',
                  'version': '1.2.3',
                  'buildNumber': '42',
                  'buildSignature': '',
                  'installerStore': null,
                };
              }
              return null;
            });

        await service.initialize();
        expect(service.isInitialized, isTrue);
        expect(service.currentVersion, '1.2.3');
        expect(service.buildNumber, '42');
        expect(service.fullVersion, '1.2.3+42');
        expect(service.appName, 'CrushHour');
        expect(service.packageName, 'com.ace.crush');
      },
    );
  });
}

String _bumpPatch(String version) {
  final normalized = version.replaceFirst(RegExp(r'^v'), '');
  final parts = normalized.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  while (parts.length < 3) {
    parts.add(0);
  }
  parts[2] = parts[2] + 1;
  return '${parts[0]}.${parts[1]}.${parts[2]}';
}
