import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/security/device_integrity.dart';

void main() {
  group('DeviceIntegrityService', () {
    setUp(DeviceIntegrityService.resetForTesting);
    tearDown(DeviceIntegrityService.resetForTesting);

    test('returns false in debug mode and caches result', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => true,
        isAndroid: () => true,
      );

      final first = await DeviceIntegrityService.checkIntegrity();
      final second = await DeviceIntegrityService.checkIntegrity();

      expect(first, isFalse);
      expect(second, isFalse);
      expect(DeviceIntegrityService.isCompromised, isFalse);
    });

    test('detects Android compromise when su binary path exists', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => true,
        isIOS: () => false,
        fileExists: (path) async => path == '/system/xbin/su',
      );

      final result = await DeviceIntegrityService.checkIntegrity();

      expect(result, isTrue);
      expect(DeviceIntegrityService.isCompromised, isTrue);
    });

    test('detects Android compromise when build tags include test-keys', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => true,
        isIOS: () => false,
        fileExists: (_) async => false,
        processRunner: (executable, arguments) async =>
            ProcessResult(0, 0, 'test-keys', ''),
      );

      final result = await DeviceIntegrityService.checkIntegrity();

      expect(result, isTrue);
    });

    test('returns false when Android indicators are absent', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => true,
        isIOS: () => false,
        fileExists: (_) async => false,
        processRunner: (executable, arguments) async =>
            ProcessResult(0, 0, 'release-keys', ''),
      );

      final result = await DeviceIntegrityService.checkIntegrity();

      expect(result, isFalse);
    });

    test('returns false when Android getprop call throws', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => true,
        isIOS: () => false,
        fileExists: (_) async => false,
        processRunner: (executable, arguments) async =>
            throw Exception('getprop unavailable'),
      );

      final result = await DeviceIntegrityService.checkIntegrity();

      expect(result, isFalse);
    });

    test('detects iOS compromise when jailbreak path exists', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => false,
        isIOS: () => true,
        fileExists: (path) async => path == '/Applications/Cydia.app',
        directoryExists: (_) async => false,
        iosSandboxWriteProbe: () async => false,
      );

      final result = await DeviceIntegrityService.checkIntegrity();

      expect(result, isTrue);
    });

    test('detects iOS compromise when sandbox write probe succeeds', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => false,
        isIOS: () => true,
        fileExists: (_) async => false,
        directoryExists: (_) async => false,
        iosSandboxWriteProbe: () async => true,
      );

      final result = await DeviceIntegrityService.checkIntegrity();

      expect(result, isTrue);
    });

    test('returns false for iOS when no indicators exist', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => false,
        isIOS: () => true,
        fileExists: (_) async => false,
        directoryExists: (_) async => false,
        iosSandboxWriteProbe: () async => false,
      );

      final result = await DeviceIntegrityService.checkIntegrity();

      expect(result, isFalse);
    });

    test('returns false when platform is not Android or iOS', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => false,
        isIOS: () => false,
      );

      final result = await DeviceIntegrityService.checkIntegrity();

      expect(result, isFalse);
    });

    test('caches computed result and avoids duplicate checks', () async {
      var fileChecks = 0;
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => true,
        isIOS: () => false,
        fileExists: (_) async {
          fileChecks += 1;
          return true;
        },
      );

      final first = await DeviceIntegrityService.checkIntegrity();
      final second = await DeviceIntegrityService.checkIntegrity();

      expect(first, isTrue);
      expect(second, isTrue);
      expect(fileChecks, 1);
    });

    test('resetCache clears compromised state', () async {
      DeviceIntegrityService.configureForTesting(
        isDebugMode: () => false,
        isAndroid: () => true,
        fileExists: (_) async => true,
      );

      expect(await DeviceIntegrityService.checkIntegrity(), isTrue);
      expect(DeviceIntegrityService.isCompromised, isTrue);

      DeviceIntegrityService.resetCache();
      expect(DeviceIntegrityService.isCompromised, isFalse);
    });
  });
}
