import 'package:crushhour/core/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Best-effort secure storage wrapper for auth-critical ephemeral state.
///
/// On platforms where secure storage is unavailable in debug/simulator builds,
/// values are mirrored in memory so the current app session can keep working.
class AuthSecureStorage {
  AuthSecureStorage({
    FlutterSecureStorage? secureStorage,
    required String logPrefix,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _logPrefix = logPrefix;

  final FlutterSecureStorage _secureStorage;
  final String _logPrefix;
  final Map<String, String> _volatileValues = <String, String>{};

  Future<String?> read(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        _volatileValues[key] = value;
      }
      return value ?? _volatileValues[key];
    } catch (error, stackTrace) {
      _log('read', key, error, stackTrace);
      return _volatileValues[key];
    }
  }

  Future<void> write({required String key, required String value}) async {
    _volatileValues[key] = value;
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (error, stackTrace) {
      _log('write', key, error, stackTrace);
    }
  }

  Future<void> delete(String key) async {
    _volatileValues.remove(key);
    try {
      await _secureStorage.delete(key: key);
    } catch (error, stackTrace) {
      _log('delete', key, error, stackTrace);
    }
  }

  void _log(String operation, String key, Object error, StackTrace stackTrace) {
    AppLogger.error(
      '[$_logPrefix] Secure storage $operation failed',
      error: error,
      stackTrace: stackTrace,
      data: <String, dynamic>{'key': key},
    );
  }
}
