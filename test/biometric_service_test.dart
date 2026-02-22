import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/security/biometric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late _LocalAuthMockState localAuthState;
  late Map<String, String> secureStore;
  final service = BiometricService.instance;

  Future<dynamic> localAuthHandler(MethodCall call) async {
    if (localAuthState.throwOnMethods.contains(call.method)) {
      throw PlatformException(code: 'local-auth-error', message: call.method);
    }
    switch (call.method) {
      case 'getAvailableBiometrics':
        return localAuthState.availableBiometrics;
      case 'isDeviceSupported':
        return localAuthState.isDeviceSupported;
      case 'authenticate':
        return localAuthState.authenticateResult;
      default:
        return null;
    }
  }

  Future<dynamic> secureStorageHandler(MethodCall call) async {
    final args = ((call.arguments as Map?) ?? const <Object?, Object?>{})
        .cast<Object?, Object?>();
    final key = args['key'] as String?;
    switch (call.method) {
      case 'read':
        return key == null ? null : secureStore[key];
      case 'write':
        if (key != null) {
          final value = args['value']?.toString();
          if (value == null) {
            secureStore.remove(key);
          } else {
            secureStore[key] = value;
          }
        }
        return null;
      case 'delete':
        if (key != null) {
          secureStore.remove(key);
        }
        return null;
      case 'deleteAll':
        secureStore.clear();
        return null;
      default:
        return null;
    }
  }

  setUp(() async {
    localAuthState = _LocalAuthMockState();
    secureStore = <String, String>{};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localAuthChannel, localAuthHandler);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, secureStorageHandler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localAuthChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  group('BiometricService', () {
    test(
      'isAvailable returns true when biometrics and device support exist',
      () async {
        localAuthState
          ..availableBiometrics = const <String>['fingerprint']
          ..isDeviceSupported = true;

        final available = await service.isAvailable();

        expect(available, isTrue);
      },
    );

    test('isAvailable returns false when no enrolled biometrics', () async {
      localAuthState
        ..availableBiometrics = const <String>[]
        ..isDeviceSupported = true;

      final available = await service.isAvailable();

      expect(available, isFalse);
    });

    test('isAvailable returns false on platform exception', () async {
      localAuthState.throwOnMethods.add('isDeviceSupported');

      final available = await service.isAvailable();

      expect(available, isFalse);
    });

    test('getAvailableBiometrics returns empty list on error', () async {
      localAuthState.throwOnMethods.add('getAvailableBiometrics');

      final biometrics = await service.getAvailableBiometrics();

      expect(biometrics, isEmpty);
    });

    test(
      'getBiometricTypeName maps face/fingerprint/iris and default',
      () async {
        localAuthState.availableBiometrics = const <String>['face'];
        expect(await service.getBiometricTypeName(), 'Face ID');

        localAuthState.availableBiometrics = const <String>['fingerprint'];
        expect(await service.getBiometricTypeName(), 'Fingerprint');

        localAuthState.availableBiometrics = const <String>['iris'];
        expect(await service.getBiometricTypeName(), 'Iris');

        localAuthState.availableBiometrics = const <String>['undefined'];
        expect(await service.getBiometricTypeName(), 'Biometric');
      },
    );

    test('authenticate returns true/false based on native response', () async {
      localAuthState.authenticateResult = true;
      expect(await service.authenticate(reason: 'test reason'), isTrue);

      localAuthState.authenticateResult = false;
      expect(await service.authenticate(reason: 'test reason'), isFalse);
    });

    test('authenticate returns false on platform exception', () async {
      localAuthState.throwOnMethods.add('authenticate');

      final ok = await service.authenticate(reason: 'test reason');

      expect(ok, isFalse);
    });

    test('setEnabled and isEnabled persist preference', () async {
      expect(await service.isEnabled(), isFalse);

      await service.setEnabled(true);
      expect(await service.isEnabled(), isTrue);

      await service.setEnabled(false);
      expect(await service.isEnabled(), isFalse);
    });

    test('pin hash lifecycle methods persist and verify correctly', () async {
      expect(await service.hasPinSetup(), isFalse);

      await service.setPinHash('hash-123');
      expect(await service.hasPinSetup(), isTrue);
      expect(await service.verifyPinHash('hash-123'), isTrue);
      expect(await service.verifyPinHash('hash-456'), isFalse);
    });

    test('clear removes biometric enabled and pin hash keys', () async {
      await service.setEnabled(true);
      await service.setPinHash('hash-abc');

      expect(await service.isEnabled(), isTrue);
      expect(await service.hasPinSetup(), isTrue);

      await service.clear();

      expect(await service.isEnabled(), isFalse);
      expect(await service.hasPinSetup(), isFalse);
    });
  });
}

class _LocalAuthMockState {
  List<String> availableBiometrics = const <String>['fingerprint'];
  bool isDeviceSupported = true;
  bool authenticateResult = true;
  final Set<String> throwOnMethods = <String>{};
}
