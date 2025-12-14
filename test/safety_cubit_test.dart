import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_project/data/models/match.dart';
import 'package:my_first_project/data/models/message.dart';
import 'package:my_first_project/data/repositories/chat_repository.dart';
import 'package:my_first_project/logic/safety/safety_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafetyCubit', () {
    late SharedPreferences prefs;
    late _StubChatRepository chatRepo;
    late SafetyCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      chatRepo = _StubChatRepository();
      cubit = SafetyCubit(preferences: prefs, chatRepository: chatRepo);
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
      );

      expect(chatRepo.reports, contains(('me', 'target', 'spam')));
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
  final List<(String, String, String)> reports = [];

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
  }) async {
    _maybeThrow();
    reports.add((reporterId, reportedId, reason));
  }

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
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    _maybeThrow();
  }
}
