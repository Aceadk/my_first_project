import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/security/biometric_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════════

enum BiometricStatus {
  /// Initial state, not yet checked.
  initial,

  /// Checking device capability.
  checking,

  /// Device supports biometric and user has enabled it.
  enabled,

  /// Device supports biometric but user has not enabled it.
  disabled,

  /// Device does not support biometric authentication.
  unavailable,

  /// Biometric prompt is active.
  authenticating,

  /// Authentication succeeded.
  authenticated,

  /// Authentication failed (biometric or PIN).
  failed,

  /// PIN setup screen needed.
  pinSetupRequired,

  /// PIN entry needed (biometric failed too many times).
  pinRequired,

  /// Too many PIN failures, require full password login.
  locked,
}

class BiometricState extends Equatable {
  const BiometricState({
    this.status = BiometricStatus.initial,
    this.biometricTypeName = 'Biometric',
    this.biometricFailures = 0,
    this.pinFailures = 0,
    this.errorMessage,
  });

  final BiometricStatus status;
  final String biometricTypeName;
  final int biometricFailures;
  final int pinFailures;
  final String? errorMessage;

  bool get isAuthenticated => status == BiometricStatus.authenticated;
  bool get needsAuth =>
      status == BiometricStatus.enabled ||
      status == BiometricStatus.authenticating;

  BiometricState copyWith({
    BiometricStatus? status,
    String? biometricTypeName,
    int? biometricFailures,
    int? pinFailures,
    String? errorMessage,
  }) {
    return BiometricState(
      status: status ?? this.status,
      biometricTypeName: biometricTypeName ?? this.biometricTypeName,
      biometricFailures: biometricFailures ?? this.biometricFailures,
      pinFailures: pinFailures ?? this.pinFailures,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    biometricTypeName,
    biometricFailures,
    pinFailures,
    errorMessage,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUBIT
// ═══════════════════════════════════════════════════════════════════════════════

class BiometricCubit extends Cubit<BiometricState> {
  BiometricCubit({BiometricService? biometricService})
    : _service = biometricService ?? BiometricService.instance,
      super(const BiometricState());

  final BiometricService _service;

  /// Check device capability and user preference.
  Future<void> checkAvailability() async {
    emit(state.copyWith(status: BiometricStatus.checking));

    final isAvailable = await _service.isAvailable();
    if (!isAvailable) {
      emit(state.copyWith(status: BiometricStatus.unavailable));
      return;
    }

    final typeName = await _service.getBiometricTypeName();
    final isEnabled = await _service.isEnabled();

    emit(
      state.copyWith(
        status: isEnabled ? BiometricStatus.enabled : BiometricStatus.disabled,
        biometricTypeName: typeName,
      ),
    );
  }

  /// Enable biometric authentication.
  ///
  /// Triggers a biometric prompt to verify the user can authenticate,
  /// then persists the preference.
  Future<bool> enable() async {
    final success = await _service.authenticate(
      reason: 'Verify your identity to enable biometric login',
    );

    if (success) {
      await _service.setEnabled(true);
      final typeName = await _service.getBiometricTypeName();
      emit(
        state.copyWith(
          status: BiometricStatus.enabled,
          biometricTypeName: typeName,
        ),
      );
      return true;
    }

    emit(
      state.copyWith(
        errorMessage: 'Biometric verification failed. Please try again.',
      ),
    );
    return false;
  }

  /// Disable biometric authentication.
  Future<void> disable() async {
    await _service.setEnabled(false);
    emit(state.copyWith(status: BiometricStatus.disabled));
  }

  /// Attempt biometric authentication (e.g., on app resume).
  Future<void> authenticateWithBiometric() async {
    emit(state.copyWith(status: BiometricStatus.authenticating));

    final success = await _service.authenticate(
      reason: 'Verify your identity to unlock Crush',
    );

    if (success) {
      emit(
        state.copyWith(
          status: BiometricStatus.authenticated,
          biometricFailures: 0,
          pinFailures: 0,
        ),
      );
      return;
    }

    final failures = state.biometricFailures + 1;
    if (failures >= BiometricService.maxBiometricAttempts) {
      // Too many biometric failures — fall back to PIN
      final hasPin = await _service.hasPinSetup();
      emit(
        state.copyWith(
          status: hasPin
              ? BiometricStatus.pinRequired
              : BiometricStatus.pinSetupRequired,
          biometricFailures: failures,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: BiometricStatus.failed,
          biometricFailures: failures,
          errorMessage:
              'Authentication failed. ${BiometricService.maxBiometricAttempts - failures} attempts remaining.',
        ),
      );
    }
  }

  /// Set up a PIN for fallback authentication.
  Future<void> setupPin(String pin) async {
    final hash = _hashPin(pin);
    await _service.setPinHash(hash);
    emit(state.copyWith(status: BiometricStatus.authenticated));
  }

  /// Verify PIN for fallback authentication.
  Future<void> verifyPin(String pin) async {
    final hash = _hashPin(pin);
    final isValid = await _service.verifyPinHash(hash);

    if (isValid) {
      emit(
        state.copyWith(
          status: BiometricStatus.authenticated,
          biometricFailures: 0,
          pinFailures: 0,
        ),
      );
      return;
    }

    final failures = state.pinFailures + 1;
    if (failures >= BiometricService.maxPinAttempts) {
      emit(
        state.copyWith(
          status: BiometricStatus.locked,
          pinFailures: failures,
          errorMessage:
              'Too many PIN attempts. Please sign in with your password.',
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: BiometricStatus.pinRequired,
          pinFailures: failures,
          errorMessage:
              'Incorrect PIN. ${BiometricService.maxPinAttempts - failures} attempts remaining.',
        ),
      );
    }
  }

  /// Clear biometric data (on logout).
  Future<void> clear() async {
    await _service.clear();
    emit(const BiometricState());
  }

  /// Hash a PIN using SHA-256 for secure storage comparison.
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
