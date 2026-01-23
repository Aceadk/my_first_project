import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafetyCubit', () {
    late SharedPreferences prefs;
    late _StubChatRepository chatRepo;
    late _StubDiscoveryRepository discoveryRepo;
    late SafetyCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      chatRepo = _StubChatRepository();
      discoveryRepo = _StubDiscoveryRepository();
      cubit = SafetyCubit(
        preferences: prefs,
        chatRepository: chatRepo,
        discoveryRepository: discoveryRepo,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('blocks and unblocks users with backend calls', () async {
      await cubit.toggleBlock(
        'target',
        block: true,
        currentUserId: 'me',
      );
      expect(cubit.state.blockedUsers, contains('target'));
      expect(chatRepo.blockedPairs, contains(('me', 'target')));

      await cubit.toggleBlock(
        'target',
        block: false,
        currentUserId: 'me',
      );
      expect(cubit.state.blockedUsers, isNot(contains('target')));
      expect(chatRepo.unblockedPairs, contains(('me', 'target')));
    });

    test('reports users via backend', () async {
      await cubit.reportWithContext(
        reporterId: 'me',
        reportedId: 'target',
        reason: 'spam',
        source: 'deck',
      );

      expect(
        chatRepo.reports,
        contains(
          (
            reporterId: 'me',
            reportedId: 'target',
            reason: 'spam',
            source: 'deck'
          ),
        ),
      );
      expect(cubit.state.errorMessage, isNull);
    });

    test('emits errorMessage when backend fails', () async {
      chatRepo.shouldThrow = true;

      await cubit.reportWithContext(
        reporterId: 'me',
        reportedId: 'target',
        reason: 'spam',
      );

      expect(cubit.state.errorMessage, isNotNull);
    });
  });
}

class _StubChatRepository implements ChatRepository {
  bool shouldThrow = false;
  final List<(String, String)> blockedPairs = [];
  final List<(String, String)> unblockedPairs = [];
  final List<({String reporterId, String reportedId, String reason, String? source})>
      reports = [];

  void _maybeThrow() {
    if (shouldThrow) throw Exception('network failed');
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _maybeThrow();
    blockedPairs.add((blockerId, blockedId));
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _maybeThrow();
    unblockedPairs.add((blockerId, blockedId));
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) async {
    _maybeThrow();
    reports.add((
      reporterId: reporterId,
      reportedId: reportedId,
      reason: reason,
      source: source
    ));
  }

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
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    _maybeThrow();
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    _maybeThrow();
    return const [];
  }

  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    _maybeThrow();
    return const PaginatedResult(items: [], total: 0, hasMore: false);
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    _maybeThrow();
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    _maybeThrow();
  }

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    _maybeThrow();
    return '';
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    _maybeThrow();
  }

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    _maybeThrow();
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    _maybeThrow();
  }

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    _maybeThrow();
  }

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) async {
    _maybeThrow();
    return const PaginatedResult(items: [], total: 0, hasMore: false);
  }

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) =>
      const Stream.empty();

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
  }) async {
    _maybeThrow();
    return null;
  }

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async {
    _maybeThrow();
    return const [];
  }

  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) async {
    _maybeThrow();
    return false;
  }

  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) async {
    _maybeThrow();
    return 0;
  }
}

class _StubDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async => [];

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async => null;

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
