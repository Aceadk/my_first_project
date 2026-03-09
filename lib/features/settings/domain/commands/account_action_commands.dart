import 'package:crushhour/data/models/user.dart';

/// Normalized failure categories for account action commands.
enum AccountActionFailureType {
  sessionMissing,
  invalidCredentials,
  cooldownActive,
  rateLimited,
  network,
  unsupported,
  unknown,
}

/// Typed failure payload returned by account action commands.
class AccountActionFailure {
  const AccountActionFailure({
    required this.type,
    required this.message,
    this.code,
    this.nextAllowedAt,
  });

  final AccountActionFailureType type;
  final String message;
  final String? code;
  final DateTime? nextAllowedAt;
}

/// Typed command result wrapper for account action operations.
class AccountActionCommandResult<T> {
  const AccountActionCommandResult._({this.data, this.failure});

  final T? data;
  final AccountActionFailure? failure;

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  factory AccountActionCommandResult.success([T? data]) {
    return AccountActionCommandResult<T>._(data: data);
  }

  factory AccountActionCommandResult.failure(AccountActionFailure failure) {
    return AccountActionCommandResult<T>._(failure: failure);
  }
}

enum AccountDataExportMode { remoteRequestQueued, localFileReady }

/// Result payload for export command.
class AccountDataExportOutcome {
  const AccountDataExportOutcome._({
    required this.mode,
    this.filePath,
    this.usedFallback = false,
  });

  final AccountDataExportMode mode;
  final String? filePath;
  final bool usedFallback;

  factory AccountDataExportOutcome.remoteRequestQueued() {
    return const AccountDataExportOutcome._(
      mode: AccountDataExportMode.remoteRequestQueued,
    );
  }

  factory AccountDataExportOutcome.localFileReady({required String filePath}) {
    return AccountDataExportOutcome._(
      mode: AccountDataExportMode.localFileReady,
      filePath: filePath,
      usedFallback: true,
    );
  }
}

typedef AccountExportProgressCallback =
    void Function(String status, double progress);

/// Optional auth capability for repositories that can cancel pending deletion.
abstract class AccountDeletionCancellationCapability {
  Future<void> cancelPendingDeletion();
}

/// Command layer contract for destructive account actions in settings.
abstract class AccountActionCommands {
  Future<AccountActionCommandResult<AccountDataExportOutcome>>
  requestDataExport({
    required CrushUser user,
    AccountExportProgressCallback? onProgress,
  });

  Future<AccountActionCommandResult<void>> deactivateAccount({
    required String reason,
  });

  Future<AccountActionCommandResult<void>> deleteAccount({
    required String password,
    required String reason,
  });

  Future<AccountActionCommandResult<void>> cancelPendingDeletion();

  Future<AccountActionCommandResult<void>> shareDataExport({
    required String filePath,
  });
}
