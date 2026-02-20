import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crushhour/core/app_logger.dart';

/// Wrapper around local_auth for biometric authentication.
///
/// Handles Face ID, Touch ID, and fingerprint authentication with
/// secure storage for preference persistence.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _enabledKey = 'biometric_auth_enabled';
  static const String _pinHashKey = 'biometric_pin_hash';
  static const int maxBiometricAttempts = 3;
  static const int maxPinAttempts = 5;

  /// Check if biometric authentication is available on this device.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException catch (e) {
      AppLogger.error('BiometricService: isAvailable failed - $e');
      return false;
    }
  }

  /// Get the list of available biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      AppLogger.error('BiometricService: getAvailableBiometrics failed - $e');
      return [];
    }
  }

  /// Attempt biometric authentication.
  ///
  /// Returns true if authentication succeeds.
  /// [reason] is shown to the user in the biometric prompt.
  Future<bool> authenticate({
    String reason = 'Verify your identity to continue',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      AppLogger.error('BiometricService: authenticate failed - $e');
      return false;
    }
  }

  /// Check if biometric auth is enabled by the user.
  Future<bool> isEnabled() async {
    final value = await _secureStorage.read(key: _enabledKey);
    return value == 'true';
  }

  /// Enable or disable biometric authentication preference.
  Future<void> setEnabled(bool enabled) async {
    await _secureStorage.write(key: _enabledKey, value: enabled.toString());
  }

  /// Check if a PIN has been set up as fallback.
  Future<bool> hasPinSetup() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Store a hashed PIN for fallback authentication.
  /// The PIN should be hashed before calling this method.
  Future<void> setPinHash(String pinHash) async {
    await _secureStorage.write(key: _pinHashKey, value: pinHash);
  }

  /// Verify a PIN against the stored hash.
  /// Returns true if the hash matches.
  Future<bool> verifyPinHash(String pinHash) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    return storedHash == pinHash;
  }

  /// Clear all biometric data (on logout or account deletion).
  Future<void> clear() async {
    await _secureStorage.delete(key: _enabledKey);
    await _secureStorage.delete(key: _pinHashKey);
  }

  /// Get a human-readable name for the primary biometric type.
  Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }
}
