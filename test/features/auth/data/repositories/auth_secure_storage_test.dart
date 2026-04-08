import 'package:crushhour/features/auth/data/repositories/impl/auth_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSecureStorage', () {
    test('returns in-memory fallback when secure storage read fails', () async {
      final storage = AuthSecureStorage(
        secureStorage: _ThrowingSecureStorage(),
        logPrefix: 'test',
      );

      await storage.write(key: 'token', value: 'abc123');

      expect(await storage.read('token'), 'abc123');
    });

    test(
      'clears fallback value even when secure storage delete fails',
      () async {
        final storage = AuthSecureStorage(
          secureStorage: _ThrowingSecureStorage(),
          logPrefix: 'test',
        );

        await storage.write(key: 'token', value: 'abc123');
        await storage.delete('token');

        expect(await storage.read('token'), isNull);
      },
    );

    test(
      'uses last successful secure storage read as future fallback',
      () async {
        final backing = _SwitchableSecureStorage(
          readValues: <String, String>{'token': 'persisted'},
        );
        final storage = AuthSecureStorage(
          secureStorage: backing,
          logPrefix: 'test',
        );

        expect(await storage.read('token'), 'persisted');

        backing.throwOnRead = true;

        expect(await storage.read('token'), 'persisted');
      },
    );
  });
}

class _ThrowingSecureStorage extends FlutterSecureStorage {
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    throw Exception('write failed');
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    throw Exception('read failed');
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    throw Exception('delete failed');
  }
}

class _SwitchableSecureStorage extends FlutterSecureStorage {
  _SwitchableSecureStorage({required Map<String, String> readValues})
    : _readValues = readValues;

  final Map<String, String> _readValues;
  bool throwOnRead = false;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwOnRead) {
      throw Exception('read failed');
    }
    return _readValues[key];
  }
}
