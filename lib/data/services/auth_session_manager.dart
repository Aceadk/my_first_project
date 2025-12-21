import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSessionManager {
  static const _sessionTokenKey = 'auth_session_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_session_expires_at_ms';
  static const _clockSkew = Duration(seconds: 30);

  final FlutterSecureStorage _storage;
  final fb.FirebaseAuth _auth;

  AuthSessionManager({
    FlutterSecureStorage? storage,
    fb.FirebaseAuth? auth,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _auth = auth ?? fb.FirebaseAuth.instance;

  Future<void> persistFromUser(fb.User user) async {
    final tokenResult = await user.getIdTokenResult();
    final token = tokenResult.token;
    if (token == null || token.isEmpty) return;
    await _storage.write(key: _sessionTokenKey, value: token);
    await _storage.write(
      key: _refreshTokenKey,
      value: user.refreshToken ?? '',
    );
    final expiresAt = tokenResult.expirationTime?.millisecondsSinceEpoch;
    if (expiresAt != null) {
      await _storage.write(key: _expiresAtKey, value: '$expiresAt');
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _sessionTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }

  Future<bool> validateOrRefresh() async {
    final stored = await _readStored();
    if (stored == null) {
      await clear();
      return false;
    }
    if (stored.expiresAt != null) {
      final now = DateTime.now();
      if (now.isBefore(stored.expiresAt!.subtract(_clockSkew))) {
        return true;
      }
    }

    final user = _auth.currentUser;
    if (user == null) {
      await clear();
      return false;
    }

    try {
      await user.getIdToken(true);
      await persistFromUser(user);
      return true;
    } catch (_) {
      await clear();
      await _auth.signOut();
      return false;
    }
  }

  Future<_StoredSession?> _readStored() async {
    final token = await _storage.read(key: _sessionTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    if (token == null || token.isEmpty) return null;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final expiresAtMs = int.tryParse(expiresAtRaw ?? '');
    final expiresAt =
        expiresAtMs != null ? DateTime.fromMillisecondsSinceEpoch(expiresAtMs) : null;
    return _StoredSession(
      token: token,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }
}

class _StoredSession {
  final String token;
  final String refreshToken;
  final DateTime? expiresAt;

  const _StoredSession({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
  });
}
