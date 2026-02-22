import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

import 'package:crushhour/core/security/biometric_service.dart';
import 'package:crushhour/features/auth/presentation/bloc/biometric_cubit.dart';

void main() {
  group('BiometricState', () {
    test('isAuthenticated and needsAuth reflect status', () {
      const authenticated = BiometricState(
        status: BiometricStatus.authenticated,
      );
      const enabled = BiometricState(status: BiometricStatus.enabled);
      const authenticating = BiometricState(
        status: BiometricStatus.authenticating,
      );
      const disabled = BiometricState(status: BiometricStatus.disabled);

      expect(authenticated.isAuthenticated, isTrue);
      expect(authenticated.needsAuth, isFalse);
      expect(enabled.needsAuth, isTrue);
      expect(authenticating.needsAuth, isTrue);
      expect(disabled.needsAuth, isFalse);
    });
  });

  group('BiometricCubit', () {
    late _FakeBiometricService service;
    late BiometricCubit cubit;

    setUp(() {
      service = _FakeBiometricService();
      cubit = BiometricCubit(biometricService: service);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('checkAvailability emits unavailable when not supported', () async {
      service.available = false;

      await cubit.checkAvailability();

      expect(cubit.state.status, BiometricStatus.unavailable);
    });

    test('checkAvailability emits enabled with biometric type', () async {
      service
        ..available = true
        ..enabled = true
        ..biometricTypeName = 'Face ID';

      await cubit.checkAvailability();

      expect(cubit.state.status, BiometricStatus.enabled);
      expect(cubit.state.biometricTypeName, 'Face ID');
    });

    test('enable succeeds and persists preference', () async {
      service.enqueueAuthResult(true);

      final result = await cubit.enable();

      expect(result, isTrue);
      expect(service.enabled, isTrue);
      expect(cubit.state.status, BiometricStatus.enabled);
    });

    test('enable failure sets error message', () async {
      service.enqueueAuthResult(false);

      final result = await cubit.enable();

      expect(result, isFalse);
      expect(cubit.state.errorMessage, isNotEmpty);
    });

    test('disable turns off preference and emits disabled state', () async {
      service.enabled = true;

      await cubit.disable();

      expect(service.enabled, isFalse);
      expect(cubit.state.status, BiometricStatus.disabled);
    });

    test('authenticateWithBiometric success resets failures', () async {
      service.enqueueAuthResult(true);

      await cubit.authenticateWithBiometric();

      expect(cubit.state.status, BiometricStatus.authenticated);
      expect(cubit.state.biometricFailures, 0);
      expect(cubit.state.pinFailures, 0);
    });

    test(
      'authenticateWithBiometric failure before max emits failed with remaining',
      () async {
        service.enqueueAuthResult(false);

        await cubit.authenticateWithBiometric();

        expect(cubit.state.status, BiometricStatus.failed);
        expect(cubit.state.biometricFailures, 1);
        expect(cubit.state.errorMessage, contains('attempts remaining'));
      },
    );

    test(
      'authenticateWithBiometric falls back to pinRequired after max',
      () async {
        service
          ..hasPin = true
          ..enqueueAuthResult(false)
          ..enqueueAuthResult(false)
          ..enqueueAuthResult(false);

        await cubit.authenticateWithBiometric();
        await cubit.authenticateWithBiometric();
        await cubit.authenticateWithBiometric();

        expect(
          cubit.state.biometricFailures,
          BiometricService.maxBiometricAttempts,
        );
        expect(cubit.state.status, BiometricStatus.pinRequired);
      },
    );

    test(
      'authenticateWithBiometric falls back to pinSetupRequired when no PIN',
      () async {
        service
          ..hasPin = false
          ..enqueueAuthResult(false)
          ..enqueueAuthResult(false)
          ..enqueueAuthResult(false);

        await cubit.authenticateWithBiometric();
        await cubit.authenticateWithBiometric();
        await cubit.authenticateWithBiometric();

        expect(cubit.state.status, BiometricStatus.pinSetupRequired);
      },
    );

    test('setupPin then verifyPin authenticates and resets failures', () async {
      await cubit.setupPin('1234');
      expect(cubit.state.status, BiometricStatus.authenticated);

      await cubit.verifyPin('1234');
      expect(cubit.state.status, BiometricStatus.authenticated);
      expect(cubit.state.pinFailures, 0);
      expect(cubit.state.biometricFailures, 0);
    });

    test(
      'verifyPin wrong PIN increments and locks after max attempts',
      () async {
        await cubit.setupPin('1234');

        for (var i = 0; i < BiometricService.maxPinAttempts - 1; i++) {
          await cubit.verifyPin('0000');
        }

        expect(cubit.state.status, BiometricStatus.pinRequired);
        expect(cubit.state.pinFailures, BiometricService.maxPinAttempts - 1);
        expect(cubit.state.errorMessage, contains('attempts remaining'));

        await cubit.verifyPin('0000');

        expect(cubit.state.status, BiometricStatus.locked);
        expect(cubit.state.pinFailures, BiometricService.maxPinAttempts);
        expect(cubit.state.errorMessage, contains('Too many PIN attempts'));
      },
    );

    test('clear resets to initial state and clears service data', () async {
      await cubit.setupPin('5678');
      expect(service.pinHash, isNotNull);

      await cubit.clear();

      expect(service.clearCalled, isTrue);
      expect(cubit.state, const BiometricState());
    });
  });
}

class _FakeBiometricService implements BiometricService {
  final Queue<bool> _authResults = Queue<bool>();

  bool available = true;
  bool enabled = false;
  bool hasPin = false;
  String biometricTypeName = 'Biometric';
  String? pinHash;
  bool clearCalled = false;

  void enqueueAuthResult(bool result) {
    _authResults.add(result);
  }

  @override
  Future<bool> authenticate({
    String reason = 'Verify your identity to continue',
  }) async {
    if (_authResults.isEmpty) {
      return false;
    }
    return _authResults.removeFirst();
  }

  @override
  Future<void> clear() async {
    clearCalled = true;
    enabled = false;
    pinHash = null;
    hasPin = false;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => <BiometricType>[
    BiometricType.fingerprint,
  ];

  @override
  Future<String> getBiometricTypeName() async => biometricTypeName;

  @override
  Future<bool> hasPinSetup() async => hasPin;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    this.enabled = enabled;
  }

  @override
  Future<void> setPinHash(String pinHash) async {
    this.pinHash = pinHash;
    hasPin = true;
  }

  @override
  Future<bool> verifyPinHash(String pinHash) async => this.pinHash == pinHash;
}
