import 'dart:async';
import 'dart:io';

import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/core/services/data_export_request_service.dart';
import 'package:crushhour/core/services/data_export_service.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_repository.dart';
import 'package:crushhour/features/settings/domain/commands/account_action_commands.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

typedef RequestDataExportFn = Future<DataExportRequestResult> Function();
typedef RunLocalDataExportFn =
    Future<DataExportResult> Function({
      required CrushUser user,
      AccountExportProgressCallback? onProgress,
    });
typedef ShareDataExportFn = Future<void> Function(String filePath);

/// Default data-layer implementation for account action commands.
class DefaultAccountActionCommands implements AccountActionCommands {
  DefaultAccountActionCommands({
    required AuthRepository authRepository,
    ProfileRepository? profileRepository,
    DiscoveryRepository? discoveryRepository,
    ChatRepository? chatRepository,
    RequestDataExportFn? requestDataExport,
    RunLocalDataExportFn? runLocalDataExport,
    ShareDataExportFn? shareDataExport,
    Future<SharedPreferences> Function()? preferencesProvider,
    DateTime Function()? now,
    int exportCooldownDays = 7,
    String lastExportRequestedAtKey = _defaultLastExportRequestedAtKey,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _discoveryRepository = discoveryRepository,
       _chatRepository = chatRepository,
       _requestDataExport =
           requestDataExport ??
           (() => DataExportRequestService().requestExport()),
       _runLocalDataExport = runLocalDataExport,
       _shareDataExport = shareDataExport ?? _defaultShareDataExport,
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now,
       _exportCooldownDays = exportCooldownDays,
       _lastExportRequestedAtKey = lastExportRequestedAtKey;

  static const _defaultLastExportRequestedAtKey =
      'settings_last_export_request_at';

  final AuthRepository _authRepository;
  final ProfileRepository? _profileRepository;
  final DiscoveryRepository? _discoveryRepository;
  final ChatRepository? _chatRepository;
  final RequestDataExportFn _requestDataExport;
  final RunLocalDataExportFn? _runLocalDataExport;
  final ShareDataExportFn _shareDataExport;
  final Future<SharedPreferences> Function() _preferencesProvider;
  final DateTime Function() _now;
  final int _exportCooldownDays;
  final String _lastExportRequestedAtKey;

  @override
  Future<AccountActionCommandResult<AccountDataExportOutcome>>
  requestDataExport({
    required CrushUser user,
    AccountExportProgressCallback? onProgress,
  }) async {
    if (user.id.trim().isEmpty) {
      return AccountActionCommandResult.failure(
        const AccountActionFailure(
          type: AccountActionFailureType.sessionMissing,
          message: 'Please sign in to request your data export.',
          code: 'auth_session_missing',
        ),
      );
    }

    try {
      final prefs = await _preferencesProvider();
      final now = _now();
      final cooldownFailure = _checkExportCooldown(prefs: prefs, now: now);
      if (cooldownFailure != null) {
        return AccountActionCommandResult.failure(cooldownFailure);
      }

      final requestResult = await _requestDataExport();
      if (requestResult.isSuccess) {
        await prefs.setInt(
          _lastExportRequestedAtKey,
          now.millisecondsSinceEpoch,
        );
        return AccountActionCommandResult.success(
          AccountDataExportOutcome.remoteRequestQueued(),
        );
      }

      if (_shouldFallbackToLocalExport(requestResult.code)) {
        return _runFallbackLocalExport(
          user: user,
          prefs: prefs,
          now: now,
          onProgress: onProgress,
        );
      }

      final nextAllowedAt = _parseNextAllowedAt(requestResult.nextAllowedAtIso);
      final failure = _mapExportRequestFailure(
        result: requestResult,
        nextAllowedAt: nextAllowedAt,
      );
      return AccountActionCommandResult.failure(failure);
    } catch (error) {
      return AccountActionCommandResult.failure(
        _mapThrowableFailure(
          error,
          fallbackMessage: 'Could not request data export. Please try again.',
          fallbackCode: 'export_unknown',
        ),
      );
    }
  }

  @override
  Future<AccountActionCommandResult<void>> deactivateAccount({
    required String reason,
  }) {
    return _guardAuthAction(
      () => _authRepository.deactivateAccount(reason: reason.trim()),
      logLabel: 'DefaultAccountActionCommands.deactivateAccount',
      fallbackType: AuthFailureType.unknown,
      fallbackMessage: 'Failed to deactivate account. Please try again.',
    );
  }

  @override
  Future<AccountActionCommandResult<void>> deleteAccount({
    required String password,
    required String reason,
  }) {
    return _guardAuthAction(
      () => _authRepository.deleteAccount(
        password: password,
        reason: reason.trim(),
      ),
      logLabel: 'DefaultAccountActionCommands.deleteAccount',
      fallbackType: AuthFailureType.invalidCredentials,
      fallbackMessage:
          'Failed to schedule account deletion. Check your password and try again.',
    );
  }

  @override
  Future<AccountActionCommandResult<void>> cancelPendingDeletion() {
    final repo = _authRepository;
    if (repo is! AccountDeletionCancellationCapability) {
      return Future.value(
        AccountActionCommandResult.failure(
          const AccountActionFailure(
            type: AccountActionFailureType.unsupported,
            message:
                'Canceling pending deletion is not supported. Sign in during the grace period to recover your account.',
            code: 'cancel_deletion_unsupported',
          ),
        ),
      );
    }

    final cancellationRepo = repo as AccountDeletionCancellationCapability;

    return _guardAuthAction(
      () => cancellationRepo.cancelPendingDeletion(),
      logLabel: 'DefaultAccountActionCommands.cancelPendingDeletion',
      fallbackType: AuthFailureType.unknown,
      fallbackMessage: 'Failed to cancel pending account deletion.',
    );
  }

  @override
  Future<AccountActionCommandResult<void>> shareDataExport({
    required String filePath,
  }) async {
    if (filePath.trim().isEmpty) {
      return AccountActionCommandResult.failure(
        const AccountActionFailure(
          type: AccountActionFailureType.unknown,
          message: 'Export file path is missing.',
          code: 'export_file_path_missing',
        ),
      );
    }

    try {
      await _shareDataExport(filePath);
      return AccountActionCommandResult.success();
    } catch (error) {
      return AccountActionCommandResult.failure(
        _mapThrowableFailure(
          error,
          fallbackMessage: 'Could not share export file.',
          fallbackCode: 'export_share_failed',
        ),
      );
    }
  }

  Future<AccountActionCommandResult<AccountDataExportOutcome>>
  _runFallbackLocalExport({
    required CrushUser user,
    required SharedPreferences prefs,
    required DateTime now,
    AccountExportProgressCallback? onProgress,
  }) async {
    final exportRunner = _runLocalDataExport ?? _defaultRunLocalDataExport;
    if (exportRunner == null) {
      return AccountActionCommandResult.failure(
        const AccountActionFailure(
          type: AccountActionFailureType.unsupported,
          message: 'Local export fallback is unavailable.',
          code: 'export_local_fallback_unavailable',
        ),
      );
    }

    try {
      final exportResult = await exportRunner(
        user: user,
        onProgress: onProgress,
      );
      if (!exportResult.isSuccess || exportResult.filePath == null) {
        return AccountActionCommandResult.failure(
          AccountActionFailure(
            type: AccountActionFailureType.unknown,
            message: exportResult.error ?? 'Failed to generate data export.',
            code: 'export_local_generation_failed',
          ),
        );
      }

      await prefs.setInt(_lastExportRequestedAtKey, now.millisecondsSinceEpoch);
      return AccountActionCommandResult.success(
        AccountDataExportOutcome.localFileReady(
          filePath: exportResult.filePath!,
        ),
      );
    } catch (error) {
      return AccountActionCommandResult.failure(
        _mapThrowableFailure(
          error,
          fallbackMessage: 'Failed to generate local data export.',
          fallbackCode: 'export_local_generation_failed',
        ),
      );
    }
  }

  RunLocalDataExportFn? get _defaultRunLocalDataExport {
    final profileRepository = _profileRepository;
    final discoveryRepository = _discoveryRepository;
    final chatRepository = _chatRepository;

    if (profileRepository == null ||
        discoveryRepository == null ||
        chatRepository == null) {
      return null;
    }

    return ({
      required CrushUser user,
      AccountExportProgressCallback? onProgress,
    }) async {
      final fallbackProfile = user.profile;
      final exportService = DataExportService(
        currentUserId: user.id,
        getUserData: () async => user,
        getProfileData: () async {
          final refreshedUser = await profileRepository.getCurrentUser();
          return refreshedUser?.profile ?? fallbackProfile;
        },
        getMatchesData: () => discoveryRepository.fetchMatches(user.id),
        getLikesData: () => discoveryRepository.fetchLikesYou(user.id),
        getMessagesData: () => _collectAllMessages(
          chatRepository: chatRepository,
          userId: user.id,
        ),
        getPreferencesData: () async {
          final refreshedUser = await profileRepository.getCurrentUser();
          final profile = refreshedUser?.profile ?? fallbackProfile;
          return profile?.preferences;
        },
      );

      return exportService.exportData(onProgress: onProgress);
    };
  }

  Future<List<Message>> _collectAllMessages({
    required ChatRepository chatRepository,
    required String userId,
  }) async {
    final allMessages = <Message>[];
    final matches = await chatRepository.fetchUserMatches(userId);

    for (final match in matches) {
      DateTime? cursor;
      var hasMore = true;

      while (hasMore) {
        final page = await chatRepository.fetchMessagesPaginated(
          match.id,
          limit: 100,
          beforeTimestamp: cursor,
        );

        if (page.items.isEmpty) break;
        allMessages.addAll(page.items);

        final nextCursor = page.items.last.sentAt;
        if (!page.hasMore || (cursor != null && !nextCursor.isBefore(cursor))) {
          hasMore = false;
        } else {
          cursor = nextCursor;
        }
      }
    }

    return allMessages;
  }

  AccountActionFailure? _checkExportCooldown({
    required SharedPreferences prefs,
    required DateTime now,
  }) {
    final lastRequestMs = prefs.getInt(_lastExportRequestedAtKey);
    if (lastRequestMs == null) return null;

    final lastRequest = DateTime.fromMillisecondsSinceEpoch(lastRequestMs);
    final nextAllowedAt = lastRequest.add(Duration(days: _exportCooldownDays));
    if (!now.isBefore(nextAllowedAt)) return null;

    return AccountActionFailure(
      type: AccountActionFailureType.cooldownActive,
      message:
          'Data export is on cooldown until ${nextAllowedAt.toIso8601String()}',
      code: 'export_cooldown_active',
      nextAllowedAt: nextAllowedAt,
    );
  }

  bool _shouldFallbackToLocalExport(String? code) {
    final normalizedCode = _normalizeCode(code ?? '');
    return normalizedCode == 'not_found' ||
        normalizedCode == 'unimplemented' ||
        normalizedCode == 'unavailable';
  }

  DateTime? _parseNextAllowedAt(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  AccountActionFailure _mapExportRequestFailure({
    required DataExportRequestResult result,
    DateTime? nextAllowedAt,
  }) {
    if (nextAllowedAt != null) {
      return AccountActionFailure(
        type: AccountActionFailureType.cooldownActive,
        message: result.message.isNullOrBlank
            ? 'Data export is on cooldown.'
            : result.message!,
        code: _normalizeCode(result.code ?? 'export_cooldown_active'),
        nextAllowedAt: nextAllowedAt,
      );
    }

    final code = _normalizeCode(result.code ?? 'unknown');
    final message = result.message ?? 'Could not request data export.';
    final type = switch (code) {
      'unauthenticated' ||
      'permission_denied' => AccountActionFailureType.sessionMissing,
      'resource_exhausted' ||
      'too_many_requests' => AccountActionFailureType.rateLimited,
      'deadline_exceeded' ||
      'network_error' ||
      'socket_exception' => AccountActionFailureType.network,
      _ => AccountActionFailureType.unknown,
    };
    return AccountActionFailure(type: type, message: message, code: code);
  }

  Future<AccountActionCommandResult<void>> _guardAuthAction(
    Future<void> Function() run, {
    required String logLabel,
    required AuthFailureType fallbackType,
    required String fallbackMessage,
  }) async {
    try {
      await run();
      return AccountActionCommandResult.success();
    } catch (error) {
      final authFailure = AuthFailureMapper.from(
        error,
        fallbackType: fallbackType,
        fallbackMessage: fallbackMessage,
      );
      return AccountActionCommandResult.failure(
        _mapAuthFailure(
          authFailure,
          fallbackMessage: fallbackMessage,
          logLabel: logLabel,
        ),
      );
    }
  }

  AccountActionFailure _mapAuthFailure(
    AuthFailure authFailure, {
    required String fallbackMessage,
    required String logLabel,
  }) {
    final mappedType = switch (authFailure.type) {
      AuthFailureType.invalidCredentials =>
        AccountActionFailureType.invalidCredentials,
      AuthFailureType.sessionMissing ||
      AuthFailureType.accountNotFound ||
      AuthFailureType.unauthorized => AccountActionFailureType.sessionMissing,
      AuthFailureType.rateLimited => AccountActionFailureType.rateLimited,
      AuthFailureType.network => AccountActionFailureType.network,
      AuthFailureType.unsupportedProvider =>
        AccountActionFailureType.unsupported,
      _ => AccountActionFailureType.unknown,
    };

    return AccountActionFailure(
      type: mappedType,
      message: authFailure.message.isEmpty
          ? fallbackMessage
          : authFailure.message,
      code: authFailure.type.code,
    );
  }

  AccountActionFailure _mapThrowableFailure(
    Object error, {
    required String fallbackMessage,
    required String fallbackCode,
  }) {
    if (error is SocketException || error is TimeoutException) {
      return const AccountActionFailure(
        type: AccountActionFailureType.network,
        message: 'Network error. Check your connection and try again.',
        code: 'network_error',
      );
    }

    final message = error.toString().trim();
    return AccountActionFailure(
      type: AccountActionFailureType.unknown,
      message: message.isEmpty ? fallbackMessage : message,
      code: fallbackCode,
    );
  }

  String _normalizeCode(String code) {
    return code
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll('/', '_')
        .replaceAll('.', '_');
  }

  static Future<void> _defaultShareDataExport(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'CrushHour Data Export',
      text: 'Your personal data export from CrushHour',
    );
  }
}

extension on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}
