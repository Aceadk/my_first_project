import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/message_requests_cubit.dart';
import 'package:crushhour/features/chat/presentation/bloc/message_requests_state.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/data/models/profile.dart';

import 'mock/firebase_mock.dart';

// =============================================================================
// Test Helpers
// =============================================================================

const _testUserId = 'user-123';
const _otherUserId = 'user-456';

MessageRequest _makeRequest({
  String id = 'req-1',
  String fromUserId = _otherUserId,
  String toUserId = _testUserId,
  String content = 'Hello!',
  String? fromUserName = 'Alice',
  String? toUserName = 'Bob',
}) {
  return MessageRequest(
    id: id,
    fromUserId: fromUserId,
    toUserId: toUserId,
    content: content,
    type: MessageType.text,
    sentAt: DateTime(2026, 2, 1),
    expiresAt: DateTime(2026, 2, 8),
    fromUserName: fromUserName,
    toUserName: toUserName,
  );
}

// =============================================================================
// Mock ChatRepository
// =============================================================================

class MockChatRepository implements ChatRepository {
  List<MessageRequest> requestsToReturn = [];
  Exception? fetchError;
  MessageRequest? lastSentRequest;
  bool fetchMessageRequestsCalled = false;

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async {
    fetchMessageRequestsCalled = true;
    if (fetchError != null) throw fetchError!;
    return requestsToReturn;
  }

  // --- Stubs for remaining interface methods ---
  @override
  Stream<List<Message>> watchMessages(String matchId) => const Stream.empty();
  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) async => const PaginatedResult(items: [], total: 0, hasMore: false);
  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) => const Stream.empty();
  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {}
  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async => '';
  @override
  Future<void> markMessagesRead(String matchId, String userId) async {}
  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {}
  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {}
  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {}
  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) async {}
  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {}
  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {}
  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {}
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
  }) async {}
  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {}
  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {}
  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async => [];
  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async => const PaginatedResult(items: [], total: 0, hasMore: false);
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
  }) async => null;
  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) async => false;
  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) async => 0;

  @override
  bool get isE2eeEnabled => false;

  @override
  void setE2eeEnabled(bool enabled) {}

  @override
  bool isEncryptedContent(String content) => false;

  @override
  Future<Message> decryptMessage(Message message) async => message;
}

// =============================================================================
// Mock DiscoveryRepository
// =============================================================================

class MockDiscoveryRepository implements DiscoveryRepository {
  CrushMatch? matchToReturn;
  Exception? swipeRightError;
  String? lastSwipeTargetUserId;

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    lastSwipeTargetUserId = targetUserId;
    if (swipeRightError != null) throw swipeRightError!;
    return matchToReturn;
  }

  // --- Stubs ---
  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async => [];
  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {}
  @override
  Future<List<Profile>> fetchTopPicks(String userId) async => [];
  @override
  Future<List<Profile>> fetchLikesYou(String userId) async => [];
  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async => [];
  @override
  Future<Profile?> fetchProfileById(String profileId) async => null;
  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async => null;
  @override
  Future<Profile?> rewindLastSwipe(String userId) async => null;
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  setupFirebaseAnalyticsMocks();

  // ─── MessageRequest model tests ───────────────────────────────────────────

  group('MessageRequest model', () {
    test('isInboundFor returns true when userId matches toUserId', () {
      final req = _makeRequest(toUserId: 'me');
      expect(req.isInboundFor('me'), isTrue);
    });

    test('isInboundFor returns false when userId matches fromUserId', () {
      final req = _makeRequest(fromUserId: 'me', toUserId: 'other');
      expect(req.isInboundFor('me'), isFalse);
    });

    test('otherUserIdFor returns toUserId when called with fromUserId', () {
      final req = _makeRequest(fromUserId: 'a', toUserId: 'b');
      expect(req.otherUserIdFor('a'), 'b');
    });

    test('otherUserIdFor returns fromUserId when called with toUserId', () {
      final req = _makeRequest(fromUserId: 'a', toUserId: 'b');
      expect(req.otherUserIdFor('b'), 'a');
    });

    test('otherUserNameFor returns correct name', () {
      final req = _makeRequest(
        fromUserId: 'a',
        toUserId: 'b',
        fromUserName: 'Alice',
        toUserName: 'Bob',
      );
      expect(req.otherUserNameFor('a'), 'Bob');
      expect(req.otherUserNameFor('b'), 'Alice');
    });

    test('isExpired returns true when expiresAt is in the past', () {
      final req = MessageRequest(
        id: 'x',
        fromUserId: 'a',
        toUserId: 'b',
        content: 'hi',
        type: MessageType.text,
        sentAt: DateTime(2020, 1, 1),
        expiresAt: DateTime(2020, 1, 2),
      );
      expect(req.isExpired, isTrue);
    });

    test('isExpired returns false when expiresAt is in the future', () {
      final req = MessageRequest(
        id: 'x',
        fromUserId: 'a',
        toUserId: 'b',
        content: 'hi',
        type: MessageType.text,
        sentAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
      expect(req.isExpired, isFalse);
    });

    test('Equatable compares by all props', () {
      final a = _makeRequest(id: 'same');
      final b = _makeRequest(id: 'same');
      expect(a, equals(b));
    });

    test('Equatable detects differences', () {
      final a = _makeRequest(id: 'one');
      final b = _makeRequest(id: 'two');
      expect(a, isNot(equals(b)));
    });

    test('otherUserPhotoUrlFor returns correct photo URL', () {
      final req = MessageRequest(
        id: 'x',
        fromUserId: 'a',
        toUserId: 'b',
        content: 'hi',
        type: MessageType.text,
        sentAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 2, 1),
        fromUserPhotoUrl: 'photo-a.jpg',
        toUserPhotoUrl: 'photo-b.jpg',
      );
      expect(req.otherUserPhotoUrlFor('a'), 'photo-b.jpg');
      expect(req.otherUserPhotoUrlFor('b'), 'photo-a.jpg');
    });
  });

  // ─── MessageRequestsState tests ───────────────────────────────────────────

  group('MessageRequestsState', () {
    test('default state has correct values', () {
      const state = MessageRequestsState();
      expect(state.requests, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.actionRequestId, isNull);
      expect(state.actionStatus, RequestActionStatus.idle);
      expect(state.actionErrorMessage, isNull);
      expect(state.showMatchNotification, isFalse);
      expect(state.matchedUserName, isNull);
    });

    test('copyWith preserves unmodified values', () {
      final requests = [_makeRequest()];
      final state = MessageRequestsState(
        requests: requests,
        isLoading: true,
        errorMessage: 'err',
      );
      final copied = state.copyWith(isLoading: false);
      expect(copied.requests, requests);
      expect(copied.isLoading, isFalse);
      // errorMessage is NOT preserved by copyWith (it passes null through)
      // because copyWith sets errorMessage: errorMessage (null if not provided)
    });

    test('copyWith updates actionRequestId and actionStatus', () {
      const state = MessageRequestsState();
      final updated = state.copyWith(
        actionRequestId: 'req-1',
        actionStatus: RequestActionStatus.loading,
      );
      expect(updated.actionRequestId, 'req-1');
      expect(updated.actionStatus, RequestActionStatus.loading);
    });

    test('copyWith updates showMatchNotification and matchedUserName', () {
      const state = MessageRequestsState();
      final updated = state.copyWith(
        showMatchNotification: true,
        matchedUserName: 'Alice',
      );
      expect(updated.showMatchNotification, isTrue);
      expect(updated.matchedUserName, 'Alice');
    });

    test('isProcessing returns true for matching request in loading state', () {
      const state = MessageRequestsState(
        actionRequestId: 'req-1',
        actionStatus: RequestActionStatus.loading,
      );
      expect(state.isProcessing('req-1'), isTrue);
      expect(state.isProcessing('req-other'), isFalse);
    });

    test('isProcessing returns false when status is not loading', () {
      const state = MessageRequestsState(
        actionRequestId: 'req-1',
        actionStatus: RequestActionStatus.success,
      );
      expect(state.isProcessing('req-1'), isFalse);
    });

    test('clearAction resets action fields but preserves requests', () {
      final requests = [_makeRequest()];
      final state = MessageRequestsState(
        requests: requests,
        isLoading: false,
        actionRequestId: 'req-1',
        actionStatus: RequestActionStatus.success,
        actionErrorMessage: 'oops',
        showMatchNotification: true,
        matchedUserName: 'Alice',
      );
      final cleared = state.clearAction();
      expect(cleared.requests, requests);
      expect(cleared.isLoading, isFalse);
      expect(cleared.actionRequestId, isNull);
      expect(cleared.actionStatus, RequestActionStatus.idle);
      expect(cleared.actionErrorMessage, isNull);
      expect(cleared.showMatchNotification, isFalse);
      expect(cleared.matchedUserName, isNull);
    });

    test('Equatable compares correctly', () {
      const a = MessageRequestsState(isLoading: true);
      const b = MessageRequestsState(isLoading: true);
      const c = MessageRequestsState(isLoading: false);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('RequestActionStatus enum has all expected values', () {
      expect(RequestActionStatus.values, hasLength(4));
      expect(
        RequestActionStatus.values,
        containsAll([
          RequestActionStatus.idle,
          RequestActionStatus.loading,
          RequestActionStatus.success,
          RequestActionStatus.error,
        ]),
      );
    });

    test('copyWith clears errorMessage when not provided', () {
      const state = MessageRequestsState(errorMessage: 'old error');
      final updated = state.copyWith(isLoading: false);
      // copyWith passes errorMessage: null (param default) which clears it
      expect(updated.errorMessage, isNull);
    });

    test('copyWith clears actionRequestId when not provided', () {
      const state = MessageRequestsState(actionRequestId: 'req-1');
      final updated = state.copyWith(isLoading: false);
      expect(updated.actionRequestId, isNull);
    });

    test('copyWith clears matchedUserName when not provided', () {
      const state = MessageRequestsState(matchedUserName: 'Alice');
      final updated = state.copyWith(isLoading: false);
      expect(updated.matchedUserName, isNull);
    });
  });

  // ─── MessageRequestsCubit tests ───────────────────────────────────────────

  group('MessageRequestsCubit', () {
    late MockChatRepository chatRepo;
    late MockDiscoveryRepository discoveryRepo;
    late MessageRequestsCubit cubit;

    setUp(() {
      chatRepo = MockChatRepository();
      discoveryRepo = MockDiscoveryRepository();
      cubit = MessageRequestsCubit(
        chatRepository: chatRepo,
        discoveryRepository: discoveryRepo,
        userId: _testUserId,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is default MessageRequestsState', () {
      expect(cubit.state, const MessageRequestsState());
      expect(cubit.state.requests, isEmpty);
      expect(cubit.state.isLoading, isFalse);
    });

    // ── load() ──

    test('load emits loading then data on success', () async {
      final requests = [_makeRequest(id: 'r1'), _makeRequest(id: 'r2')];
      chatRepo.requestsToReturn = requests;

      final states = <MessageRequestsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await Future.delayed(const Duration(milliseconds: 50));

      // First emission: loading=true
      expect(states[0].isLoading, isTrue);
      expect(states[0].errorMessage, isNull);

      // Second emission: loading=false, data populated
      expect(states[1].isLoading, isFalse);
      expect(states[1].requests, hasLength(2));
      expect(states[1].errorMessage, isNull);

      await sub.cancel();
    });

    test('load emits loading then error on failure', () async {
      chatRepo.fetchError = Exception('network error');

      final states = <MessageRequestsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states[0].isLoading, isTrue);
      expect(states[1].isLoading, isFalse);
      expect(states[1].errorMessage, isNotNull);

      await sub.cancel();
    });

    test('load sets fetchMessageRequestsCalled on repository', () async {
      chatRepo.requestsToReturn = [];
      await cubit.load();
      expect(chatRepo.fetchMessageRequestsCalled, isTrue);
    });

    test('load with empty results emits empty list', () async {
      chatRepo.requestsToReturn = [];

      final states = <MessageRequestsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.requests, isEmpty);
      expect(states.last.isLoading, isFalse);

      await sub.cancel();
    });

    // ── refresh() ──

    test('refresh delegates to load', () async {
      chatRepo.requestsToReturn = [_makeRequest()];

      final states = <MessageRequestsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.refresh();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(chatRepo.fetchMessageRequestsCalled, isTrue);
      expect(states.last.requests, hasLength(1));

      await sub.cancel();
    });

    // ── acceptRequest() ──

    test(
      'acceptRequest ignores outbound requests (not inbound for userId)',
      () async {
        // Request FROM testUser TO otherUser → not inbound for testUser
        final outbound = _makeRequest(
          fromUserId: _testUserId,
          toUserId: _otherUserId,
        );

        final states = <MessageRequestsState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.acceptRequest(outbound);
        await Future.delayed(const Duration(milliseconds: 50));

        // No state changes should have occurred
        expect(states, isEmpty);
        expect(discoveryRepo.lastSwipeTargetUserId, isNull);

        await sub.cancel();
      },
    );

    test(
      'acceptRequest emits loading then success with match notification',
      () async {
        final request = _makeRequest(
          id: 'req-accept',
          fromUserId: _otherUserId,
          toUserId: _testUserId,
          fromUserName: 'Alice',
        );

        // Pre-populate the cubit with requests
        chatRepo.requestsToReturn = [request];
        await cubit.load();

        discoveryRepo.matchToReturn = const CrushMatch(
          id: 'match-1',
          userId: _testUserId,
          otherUserId: _otherUserId,
          status: MatchStatus.mutual,
          preMatchMessageRequestsCount: 1,
          pinnedForUser: false,
        );

        final states = <MessageRequestsState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.acceptRequest(request);
        await Future.delayed(const Duration(milliseconds: 50));

        // First: loading state
        final loadingState = states.firstWhere(
          (s) => s.actionStatus == RequestActionStatus.loading,
        );
        expect(loadingState.actionRequestId, 'req-accept');

        // Last: success with match notification
        final successState = states.last;
        expect(successState.actionStatus, RequestActionStatus.success);
        expect(successState.showMatchNotification, isTrue);
        expect(successState.matchedUserName, 'Alice');
        // Request removed from list
        expect(
          successState.requests.where((r) => r.id == 'req-accept'),
          isEmpty,
        );

        // Verify swipeRight was called with correct target
        expect(discoveryRepo.lastSwipeTargetUserId, _otherUserId);

        await sub.cancel();
      },
    );

    test(
      'acceptRequest with no match returns success without notification',
      () async {
        final request = _makeRequest(
          id: 'req-no-match',
          fromUserId: _otherUserId,
          toUserId: _testUserId,
        );

        chatRepo.requestsToReturn = [request];
        await cubit.load();

        discoveryRepo.matchToReturn = null; // No match created

        final states = <MessageRequestsState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.acceptRequest(request);
        await Future.delayed(const Duration(milliseconds: 50));

        final successState = states.last;
        expect(successState.actionStatus, RequestActionStatus.success);
        expect(successState.showMatchNotification, isFalse);
        expect(
          successState.requests.where((r) => r.id == 'req-no-match'),
          isEmpty,
        );

        await sub.cancel();
      },
    );

    test('acceptRequest emits error state on exception', () async {
      final request = _makeRequest(
        fromUserId: _otherUserId,
        toUserId: _testUserId,
      );

      chatRepo.requestsToReturn = [request];
      await cubit.load();

      discoveryRepo.swipeRightError = Exception('swipe failed');

      final states = <MessageRequestsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.acceptRequest(request);
      await Future.delayed(const Duration(milliseconds: 50));

      final errorState = states.last;
      expect(errorState.actionStatus, RequestActionStatus.error);
      expect(
        errorState.actionErrorMessage,
        contains('Could not accept request'),
      );

      await sub.cancel();
    });

    test(
      'acceptRequest uses fromUserName as matchedUserName, default to Someone',
      () async {
        final requestNoName = _makeRequest(
          id: 'no-name',
          fromUserId: _otherUserId,
          toUserId: _testUserId,
          fromUserName: null,
        );

        chatRepo.requestsToReturn = [requestNoName];
        await cubit.load();

        discoveryRepo.matchToReturn = const CrushMatch(
          id: 'match-2',
          userId: _testUserId,
          otherUserId: _otherUserId,
          status: MatchStatus.mutual,
          preMatchMessageRequestsCount: 0,
          pinnedForUser: false,
        );

        final states = <MessageRequestsState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.acceptRequest(requestNoName);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.last.matchedUserName, 'Someone');

        await sub.cancel();
      },
    );

    // ── declineRequest() ──

    test(
      'declineRequest emits loading then error (Firestore not available in tests)',
      () async {
        // declineRequest uses FirebaseFirestore.instance directly.
        // In test environment, this will throw since there's no real Firestore.
        // We verify the cubit handles the error gracefully.
        final request = _makeRequest(id: 'req-decline');

        chatRepo.requestsToReturn = [request];
        await cubit.load();

        final states = <MessageRequestsState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.declineRequest(request);
        await Future.delayed(const Duration(milliseconds: 100));

        // Should emit loading first
        final loadingState = states.firstWhere(
          (s) => s.actionStatus == RequestActionStatus.loading,
        );
        expect(loadingState.actionRequestId, 'req-decline');

        // Then error (because FirebaseFirestore.instance fails in tests)
        final errorState = states.last;
        expect(errorState.actionStatus, RequestActionStatus.error);
        expect(
          errorState.actionErrorMessage,
          contains('Could not decline request'),
        );

        await sub.cancel();
      },
    );

    // ── clearMatchNotification() ──

    test(
      'clearMatchNotification resets action and notification state',
      () async {
        // First get into a state with a match notification
        final request = _makeRequest(
          id: 'req-clear',
          fromUserId: _otherUserId,
          toUserId: _testUserId,
        );

        chatRepo.requestsToReturn = [request];
        await cubit.load();

        discoveryRepo.matchToReturn = const CrushMatch(
          id: 'match-clear',
          userId: _testUserId,
          otherUserId: _otherUserId,
          status: MatchStatus.mutual,
          preMatchMessageRequestsCount: 0,
          pinnedForUser: false,
        );

        await cubit.acceptRequest(request);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.showMatchNotification, isTrue);

        final states = <MessageRequestsState>[];
        final sub = cubit.stream.listen(states.add);

        cubit.clearMatchNotification();
        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.last.showMatchNotification, isFalse);
        expect(states.last.actionStatus, RequestActionStatus.idle);
        expect(states.last.matchedUserName, isNull);

        await sub.cancel();
      },
    );

    // ── clearAction() ──

    test('clearAction resets all action state', () async {
      // Get into an error state first
      final request = _makeRequest(
        fromUserId: _otherUserId,
        toUserId: _testUserId,
      );

      chatRepo.requestsToReturn = [request];
      await cubit.load();

      discoveryRepo.swipeRightError = Exception('fail');
      await cubit.acceptRequest(request);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.actionStatus, RequestActionStatus.error);

      final states = <MessageRequestsState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.clearAction();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.actionStatus, RequestActionStatus.idle);
      expect(states.last.actionRequestId, isNull);
      expect(states.last.actionErrorMessage, isNull);

      await sub.cancel();
    });

    // ── Multiple requests management ──

    test('acceptRequest removes only the accepted request from list', () async {
      final req1 = _makeRequest(
        id: 'r1',
        fromUserId: 'other-1',
        toUserId: _testUserId,
      );
      final req2 = _makeRequest(
        id: 'r2',
        fromUserId: 'other-2',
        toUserId: _testUserId,
      );

      chatRepo.requestsToReturn = [req1, req2];
      await cubit.load();
      expect(cubit.state.requests, hasLength(2));

      discoveryRepo.matchToReturn = null;

      await cubit.acceptRequest(req1);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.requests, hasLength(1));
      expect(cubit.state.requests.first.id, 'r2');
    });

    // ── Lifecycle ──

    test('cubit can be closed without error', () async {
      await cubit.close();
      // No exception expected
    });

    test('multiple load calls replace previous data', () async {
      chatRepo.requestsToReturn = [_makeRequest(id: 'batch-1')];
      await cubit.load();
      expect(cubit.state.requests.first.id, 'batch-1');

      chatRepo.requestsToReturn = [_makeRequest(id: 'batch-2')];
      await cubit.load();
      expect(cubit.state.requests.first.id, 'batch-2');
    });

    test('load clears previous error on retry success', () async {
      chatRepo.fetchError = Exception('first fail');
      await cubit.load();
      expect(cubit.state.errorMessage, isNotNull);

      chatRepo.fetchError = null;
      chatRepo.requestsToReturn = [_makeRequest()];
      await cubit.load();
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.requests, hasLength(1));
    });
  });
}
