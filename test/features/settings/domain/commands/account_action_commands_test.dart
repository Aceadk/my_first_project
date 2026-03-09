import 'package:crushhour/core/services/data_export_request_service.dart';
import 'package:crushhour/core/services/data_export_service.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/features/settings/data/commands/default_account_action_commands.dart';
import 'package:crushhour/features/settings/domain/commands/account_action_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('DefaultAccountActionCommands delete', () {
    test('deleteAccount succeeds with valid password', () async {
      final authRepository = FakeAuthRepository();
      await authRepository.signUpWithPassword(
        username: 'delete_ok',
        email: 'delete_ok@example.com',
        password: 'password123',
      );

      final commands = DefaultAccountActionCommands(
        authRepository: authRepository,
      );
      final result = await commands.deleteAccount(
        password: 'password123',
        reason: 'cleanup',
      );

      expect(result.isSuccess, isTrue);
      expect(result.failure, isNull);
    });

    test('deleteAccount maps bad password to invalidCredentials', () async {
      final authRepository = FakeAuthRepository();
      await authRepository.signUpWithPassword(
        username: 'delete_bad_password',
        email: 'delete_bad_password@example.com',
        password: 'password123',
      );

      final commands = DefaultAccountActionCommands(
        authRepository: authRepository,
      );
      final result = await commands.deleteAccount(
        password: 'wrong-password',
        reason: 'cleanup',
      );

      expect(result.isFailure, isTrue);
      expect(result.failure?.type, AccountActionFailureType.invalidCredentials);
    });
  });

  group('DefaultAccountActionCommands export', () {
    test(
      'requestDataExport enforces cooldown after successful request',
      () async {
        var remoteCallCount = 0;
        final commands = DefaultAccountActionCommands(
          authRepository: FakeAuthRepository(),
          requestDataExport: () async {
            remoteCallCount += 1;
            return DataExportRequestResult.success(status: 'queued');
          },
        );

        final first = await commands.requestDataExport(user: _sampleUser());
        final second = await commands.requestDataExport(user: _sampleUser());

        expect(first.isSuccess, isTrue);
        expect(first.data?.mode, AccountDataExportMode.remoteRequestQueued);
        expect(second.isFailure, isTrue);
        expect(second.failure?.type, AccountActionFailureType.cooldownActive);
        expect(remoteCallCount, 1);
      },
    );

    test(
      'requestDataExport uses local fallback for unsupported cloud endpoint',
      () async {
        var localExportCalled = false;
        final commands = DefaultAccountActionCommands(
          authRepository: FakeAuthRepository(),
          requestDataExport: () async => DataExportRequestResult.failure(
            code: 'not-found',
            message: 'requestDataExport endpoint missing',
          ),
          runLocalDataExport:
              ({
                required CrushUser user,
                AccountExportProgressCallback? onProgress,
              }) async {
                localExportCalled = true;
                onProgress?.call('Exporting local copy', 0.5);
                return DataExportResult.success(
                  filePath: '/tmp/crushhour_export.json',
                  exportDate: DateTime.utc(2026, 3, 8),
                  dataCategories: const <String>['account'],
                  matchCount: 0,
                  messageCount: 0,
                );
              },
        );

        final result = await commands.requestDataExport(user: _sampleUser());

        expect(localExportCalled, isTrue);
        expect(result.isSuccess, isTrue);
        expect(result.data?.mode, AccountDataExportMode.localFileReady);
        expect(result.data?.filePath, '/tmp/crushhour_export.json');
        expect(result.data?.usedFallback, isTrue);
      },
    );
  });

  group('DefaultAccountActionCommands cancel delete', () {
    test(
      'cancelPendingDeletion returns unsupported when capability is missing',
      () async {
        final commands = DefaultAccountActionCommands(
          authRepository: FakeAuthRepository(),
        );

        final result = await commands.cancelPendingDeletion();

        expect(result.isFailure, isTrue);
        expect(result.failure?.type, AccountActionFailureType.unsupported);
      },
    );

    test(
      'cancelPendingDeletion succeeds when repository supports capability',
      () async {
        final authRepository = _CancelableFakeAuthRepository();
        final commands = DefaultAccountActionCommands(
          authRepository: authRepository,
        );

        final result = await commands.cancelPendingDeletion();

        expect(result.isSuccess, isTrue);
        expect(authRepository.cancelCalled, isTrue);
      },
    );
  });
}

CrushUser _sampleUser({String id = 'export_user'}) {
  return CrushUser(
    id: id,
    phoneNumber: '+15550001111',
    email: 'export_user@example.com',
    username: 'export_user',
    isEmailVerified: true,
    isPhoneVerified: true,
    isIdVerified: false,
    plan: SubscriptionPlan.free,
  );
}

class _CancelableFakeAuthRepository extends FakeAuthRepository
    implements AccountDeletionCancellationCapability {
  bool cancelCalled = false;

  @override
  Future<void> cancelPendingDeletion() async {
    cancelCalled = true;
  }
}
