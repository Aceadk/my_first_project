import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/core/errors.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/matches_state.dart';

void main() {
  group('MatchesBloc', () {
    // =========================================================================
    // INITIAL STATE
    // =========================================================================

    group('Initial State', () {
      test('has correct initial values', () {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        expect(bloc.state.status, MatchesStatus.initial);
        expect(bloc.state.matches, isEmpty);
        expect(bloc.state.isLoading, false);
        expect(bloc.state.isLoadingMore, false);
        expect(bloc.state.hasMore, true);
        expect(bloc.state.total, 0);
        expect(bloc.state.errorMessage, isNull);
        expect(bloc.state.nextRetrySeconds, isNull);

        bloc.close();
      });
    });

    // =========================================================================
    // MATCHES LOAD REQUESTED
    // =========================================================================

    group('MatchesLoadRequested', () {
      test('loads matches successfully', () async {
        final matches = [_testMatch('m1'), _testMatch('m2')];
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(matchesToReturn: matches),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesState>()
                .having((s) => s.isLoading, 'isLoading', true)
                .having((s) => s.status, 'status', MatchesStatus.loading),
            isA<MatchesState>()
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.status, 'status', MatchesStatus.loaded)
                .having((s) => s.matches.length, 'count', 2)
                .having((s) => s.errorMessage, 'error', isNull),
          ]),
        );
        bloc.add(const MatchesLoadRequested());
        await expectation;

        await bloc.close();
      });

      test('emits empty status when no matches found', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(matchesToReturn: const []),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesState>().having(
              (s) => s.status,
              'status',
              MatchesStatus.loading,
            ),
            isA<MatchesState>()
                .having((s) => s.status, 'status', MatchesStatus.empty)
                .having((s) => s.matches, 'matches', isEmpty),
          ]),
        );
        bloc.add(const MatchesLoadRequested());
        await expectation;

        await bloc.close();
      });

      test('emits error state when fetching matches fails', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(shouldFailFetch: true),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesState>().having((s) => s.isLoading, 'isLoading', true),
            isA<MatchesState>()
                .having((s) => s.isLoading, 'isLoading', false)
                .having((s) => s.status, 'status', MatchesStatus.error)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ]),
        );
        bloc.add(const MatchesLoadRequested());
        await expectation;

        await bloc.close();
      });

      test('uses cached data on second load within cache window', () async {
        final matches = [_testMatch('m1')];
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(matchesToReturn: matches),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // First load
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );

        expect(bloc.state.status, MatchesStatus.loaded);
        expect(bloc.state.matches.length, 1);

        // Second load should use cache (no new states emitted)
        bloc.add(const MatchesLoadRequested());
        await _drainMicrotasks();

        // State should still be the same (cache hit)
        expect(bloc.state.status, MatchesStatus.loaded);
        expect(bloc.state.matches.length, 1);

        await bloc.close();
      });

      test('shows empty state when error indicates no matches', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(
            shouldFailFetch: true,
            useRepositoryException: true,
            errorMessage: 'no matches found',
          ),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        final expectation = expectLater(
          bloc.stream,
          emitsThrough(
            isA<MatchesState>()
                .having((s) => s.status, 'status', MatchesStatus.empty)
                .having((s) => s.matches, 'matches', isEmpty),
          ),
        );
        bloc.add(const MatchesLoadRequested());
        await expectation;

        await bloc.close();
      });
    });

    // =========================================================================
    // MATCHES REFRESH REQUESTED
    // =========================================================================

    group('MatchesRefreshRequested', () {
      test('force refreshes matches bypassing cache', () async {
        final matches = [_testMatch('m1')];
        final refreshedMatches = [_testMatch('m1'), _testMatch('m2')];
        final chatRepo = _StubChatRepository(matchesToReturn: matches);
        final bloc = MatchesBloc(
          chatRepository: chatRepo,
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // First load
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );
        expect(bloc.state.matches.length, 1);

        // Update data and reset fetch state so next fetch returns new data
        chatRepo.matchesToReturn = refreshedMatches;
        chatRepo.resetFetchState();

        // Force refresh
        final expectation = expectLater(
          bloc.stream,
          emitsThrough(
            isA<MatchesState>()
                .having((s) => s.status, 'status', MatchesStatus.loaded)
                .having((s) => s.matches.length, 'count', 2),
          ),
        );
        bloc.add(const MatchesRefreshRequested());
        await expectation;

        await bloc.close();
      });

      test('handles refresh failure gracefully', () async {
        final chatRepo = _StubChatRepository(
          matchesToReturn: [_testMatch('m1')],
        );
        final bloc = MatchesBloc(
          chatRepository: chatRepo,
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // First load succeeds
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );
        expect(bloc.state.status, MatchesStatus.loaded);

        // Now make refresh fail — reset fetch state so the next call
        // goes through the first-paginated path and throws
        chatRepo.resetFetchState();
        chatRepo.shouldFailFetch = true;

        bloc.add(const MatchesRefreshRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.error,
        );

        expect(bloc.state.status, MatchesStatus.error);
        expect(bloc.state.errorMessage, isNotNull);
        expect(bloc.state.isLoading, isFalse);

        await bloc.close();
      });
    });

    // =========================================================================
    // MATCHES LOAD MORE REQUESTED (Pagination)
    // =========================================================================

    group('MatchesLoadMoreRequested', () {
      test('appends more matches to existing list', () async {
        final initialMatches = [_testMatch('m1')];
        final moreMatches = [_testMatch('m2'), _testMatch('m3')];
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(
            matchesToReturn: initialMatches,
            moreMatchesToReturn: moreMatches,
          ),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // Load initial matches
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );
        expect(bloc.state.matches.length, 1);

        // Load more
        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<MatchesState>().having(
              (s) => s.isLoadingMore,
              'loadingMore',
              true,
            ),
            isA<MatchesState>()
                .having((s) => s.isLoadingMore, 'loadingMore', false)
                .having((s) => s.matches.length, 'total count', 3),
          ]),
        );
        bloc.add(const MatchesLoadMoreRequested());
        await expectation;

        await bloc.close();
      });

      test('does not load more when already loading more', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(
            matchesToReturn: [_testMatch('m1')],
          ),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // Load initial
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );

        // Request load more - should work fine
        bloc.add(const MatchesLoadMoreRequested());
        await _drainMicrotasks();

        await bloc.close();
      });

      test('does not load more when hasMore is false', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(
            matchesToReturn: [_testMatch('m1')],
            hasMoreMatches: false,
          ),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // Load initial
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );

        // hasMore should be false from initial load
        expect(bloc.state.hasMore, false);

        // Try to load more - should not emit new states
        bloc.add(const MatchesLoadMoreRequested());
        await _drainMicrotasks();

        // Count should remain unchanged
        expect(bloc.state.matches.length, 1);

        await bloc.close();
      });

      test('handles pagination failure without crashing', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(
            matchesToReturn: [_testMatch('m1')],
            shouldFailLoadMore: true,
          ),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // Load initial
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );

        // Load more fails
        final expectation = expectLater(
          bloc.stream,
          emitsThrough(
            isA<MatchesState>()
                .having((s) => s.isLoadingMore, 'loadingMore', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );
        bloc.add(const MatchesLoadMoreRequested());
        await expectation;

        await bloc.close();
      });
    });

    // =========================================================================
    // MATCHES RESET REQUESTED (Logout)
    // =========================================================================

    group('MatchesResetRequested', () {
      test('resets state to initial on explicit reset', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(
            matchesToReturn: [_testMatch('m1'), _testMatch('m2')],
          ),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // Load matches
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );
        expect(bloc.state.matches.isNotEmpty, true);

        // Reset
        final expectation = expectLater(
          bloc.stream,
          emits(
            isA<MatchesState>()
                .having((s) => s.status, 'status', MatchesStatus.initial)
                .having((s) => s.matches, 'matches', isEmpty)
                .having((s) => s.isLoading, 'loading', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ),
        );
        bloc.add(const MatchesResetRequested());
        await expectation;

        await bloc.close();
      });
    });

    // =========================================================================
    // AUTH STATE CHANGES (Logout clears data)
    // =========================================================================

    group('Auth State Changes', () {
      test('resets state when user logs out via auth stream', () async {
        final authController = StreamController<CrushUser?>.broadcast();
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(
            matchesToReturn: [_testMatch('m1')],
          ),
          authRepository: _StubAuthRepository(
            userStreamController: authController,
          ),
          userId: 'user-1',
        );

        // Load matches
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );
        expect(bloc.state.matches.isNotEmpty, true);

        // Simulate logout via auth stream
        final expectation = expectLater(
          bloc.stream,
          emits(
            isA<MatchesState>()
                .having((s) => s.status, 'status', MatchesStatus.initial)
                .having((s) => s.matches, 'matches', isEmpty),
          ),
        );
        authController.add(null);
        await expectation;

        await authController.close();
        await bloc.close();
      });
    });

    // =========================================================================
    // CACHE INVALIDATION
    // =========================================================================

    group('Cache Invalidation', () {
      test('invalidateCache forces fresh fetch on next load', () async {
        final matches = [_testMatch('m1')];
        final chatRepo = _StubChatRepository(matchesToReturn: matches);
        final bloc = MatchesBloc(
          chatRepository: chatRepo,
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        // First load
        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );
        expect(bloc.state.matches.length, 1);

        // Invalidate cache and update data
        bloc.invalidateCache();
        chatRepo.matchesToReturn = [_testMatch('m1'), _testMatch('m2')];
        chatRepo.resetFetchState();

        // Load again - should fetch fresh data since cache was invalidated
        final expectation = expectLater(
          bloc.stream,
          emitsThrough(
            isA<MatchesState>().having((s) => s.matches.length, 'count', 2),
          ),
        );
        bloc.add(const MatchesLoadRequested());
        await expectation;

        await bloc.close();
      });
    });

    // =========================================================================
    // MATCHES STATE PROPERTIES
    // =========================================================================

    group('MatchesState', () {
      test('copyWith preserves existing values when no overrides', () {
        const state = MatchesState(
          matches: [],
          isLoading: true,
          status: MatchesStatus.loading,
          total: 5,
        );

        final copied = state.copyWith();

        expect(copied.isLoading, true);
        expect(copied.status, MatchesStatus.loading);
        expect(copied.total, 5);
      });

      test('copyWith overrides specified values', () {
        const state = MatchesState();

        final modified = state.copyWith(
          isLoading: true,
          status: MatchesStatus.loading,
          errorMessage: 'test error',
        );

        expect(modified.isLoading, true);
        expect(modified.status, MatchesStatus.loading);
        expect(modified.errorMessage, 'test error');
      });

      test('copyWith can clear errorMessage with null', () {
        const state = MatchesState(errorMessage: 'old error');
        final cleared = state.copyWith(errorMessage: null);
        expect(cleared.errorMessage, isNull);
      });

      test('Equatable compares correctly', () {
        const state1 = MatchesState(total: 5, status: MatchesStatus.loaded);
        const state2 = MatchesState(total: 5, status: MatchesStatus.loaded);
        const state3 = MatchesState(total: 10, status: MatchesStatus.loaded);

        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });
    });

    // =========================================================================
    // MATCHES EVENTS
    // =========================================================================

    group('MatchesEvent', () {
      test('events have correct Equatable props', () {
        const event1 = MatchesLoadRequested();
        const event2 = MatchesLoadRequested();
        const refresh = MatchesRefreshRequested();

        expect(event1, equals(event2));
        expect(event1, isNot(equals(refresh)));
      });
    });

    // =========================================================================
    // BLOC CLOSE
    // =========================================================================

    group('Bloc lifecycle', () {
      test('can close cleanly', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        await expectLater(bloc.close(), completes);
      });

      test('can close after loading', () async {
        final bloc = MatchesBloc(
          chatRepository: _StubChatRepository(
            matchesToReturn: [_testMatch('m1')],
          ),
          authRepository: _StubAuthRepository(),
          userId: 'user-1',
        );

        bloc.add(const MatchesLoadRequested());
        await _waitForState(
          bloc,
          (state) => state.status == MatchesStatus.loaded,
        );

        await expectLater(bloc.close(), completes);
      });
    });
  });
}

Future<void> _waitForState(
  MatchesBloc bloc,
  bool Function(MatchesState state) predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate(bloc.state)) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for MatchesBloc state condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> _drainMicrotasks() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

// =============================================================================
// Test Data
// =============================================================================

CrushMatch _testMatch(String id) => CrushMatch(
  id: id,
  userId: 'user-1',
  otherUserId: 'other-$id',
  status: MatchStatus.mutual,
  preMatchMessageRequestsCount: 0,
  pinnedForUser: false,
  otherUserName: 'User $id',
  otherUserPhotoUrl: 'https://example.com/$id.jpg',
);

// =============================================================================
// Stub Repositories
// =============================================================================

class _StubChatRepository implements ChatRepository {
  _StubChatRepository({
    this.matchesToReturn = const [],
    this.moreMatchesToReturn = const [],
    this.shouldFailFetch = false,
    this.shouldFailLoadMore = false,
    this.hasMoreMatches = true,
    this.errorMessage,
    this.useRepositoryException = false,
  });

  List<CrushMatch> matchesToReturn;
  final List<CrushMatch> moreMatchesToReturn;
  bool shouldFailFetch;
  final bool shouldFailLoadMore;
  final bool hasMoreMatches;
  final String? errorMessage;
  final bool useRepositoryException;
  bool _isFirstPaginated = true;

  /// Reset fetch state so the next call acts like a first fetch again.
  void resetFetchState() {
    _isFirstPaginated = true;
  }

  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    if (offset > 0 || !_isFirstPaginated) {
      if (shouldFailLoadMore) {
        throw Exception('Failed to load more matches');
      }
      return PaginatedResult(
        items: moreMatchesToReturn,
        total: matchesToReturn.length + moreMatchesToReturn.length,
        hasMore: false,
      );
    }

    _isFirstPaginated = false;

    if (shouldFailFetch) {
      if (useRepositoryException) {
        throw RepositoryException(
          'no_matches',
          errorMessage ?? 'no matches found',
        );
      }
      throw Exception(errorMessage ?? 'network failed');
    }
    return PaginatedResult(
      items: matchesToReturn,
      total: matchesToReturn.length,
      hasMore: hasMoreMatches && matchesToReturn.isNotEmpty,
    );
  }

  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) async => 0;

  // Unimplemented methods below - not used by MatchesBloc

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) =>
      throw UnimplementedError();

  @override
  Stream<List<Message>> watchMessages(String matchId) =>
      throw UnimplementedError();

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) => throw UnimplementedError();

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) => throw UnimplementedError();

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) => throw UnimplementedError();

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) => throw UnimplementedError();

  @override
  Future<void> markMessagesRead(String matchId, String userId) =>
      throw UnimplementedError();

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) => throw UnimplementedError();

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) => throw UnimplementedError();

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) => throw UnimplementedError();

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) => throw UnimplementedError();

  @override
  Stream<Set<String>> watchTyping(String matchId) => const Stream.empty();

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {}

  @override
  Stream<bool> watchPresence(String userId) => const Stream.empty();

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {}

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) => const Stream.empty();

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {}

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) => throw UnimplementedError();

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) => throw UnimplementedError();

  @override
  Future<void> unmatch({required String matchId, required String userId}) =>
      throw UnimplementedError();

  @override
  Future<MessageRequest?> sendMessageRequest({
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? toUserName,
    String? toUserPhotoUrl,
  }) => throw UnimplementedError();

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) =>
      throw UnimplementedError();

  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) => throw UnimplementedError();

  @override
  bool get isE2eeEnabled => false;

  @override
  void setE2eeEnabled(bool enabled) {}

  @override
  bool isEncryptedContent(String content) => false;

  @override
  Future<Message> decryptMessage(Message message) async => message;
}

class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.userStreamController});

  final StreamController<CrushUser?>? userStreamController;

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  Stream<CrushUser?> authStateChanges() =>
      userStreamController?.stream ?? const Stream.empty();

  @override
  Future<void> bootstrapSession() async {}

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) => throw UnimplementedError();

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) => throw UnimplementedError();

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<CrushUser> signInWithApple() => throw UnimplementedError();

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {}

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) => throw UnimplementedError();

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<CrushUser?> checkEmailVerification() async => null;

  @override
  Future<void> schedulePhoneDeletion() async {}

  @override
@override
  Future<void> verifyPassword(String password) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deactivateAccount({required String reason}) async {}

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {}

  @override
  Future<bool> isEmailRegistered(String email) async => false;

  @override
  Future<CrushUser> acceptTermsAndConditions() => throw UnimplementedError();

  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}
