import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/repositories/chat_repository.dart';
import 'package:crushhour/data/repositories/subscription_repository.dart';
import 'package:crushhour/logic/chat/chat_bloc.dart';
import 'package:crushhour/logic/chat/chat_event.dart';
import 'package:crushhour/logic/chat/chat_state.dart';

class _FakeChatRepository implements ChatRepository {
  final List<Message> sent = [];
  int uploads = 0;
  final _typingController = StreamController<Set<String>>.broadcast()
    ..add(const {});
  final _presenceController = StreamController<bool>.broadcast()..add(false);
  final _mediaController = StreamController<bool>.broadcast()..add(true);

  @override
  Stream<List<Message>> watchMessages(String matchId) async* {
    yield const [];
  }

  @override
  Stream<Set<String>> watchTyping(String matchId) => _typingController.stream;

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {}

  @override
  Stream<bool> watchPresence(String userId) => _presenceController.stream;

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {}

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) =>
      _mediaController.stream;

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {
    _mediaController.add(enabled);
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
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {}

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    sent.add(Message(
      id: 'new',
      matchId: matchId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: content,
      type: type,
      sentAt: DateTime.now(),
      isRead: false,
      isDeletedForSender: false,
    ));
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {}

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
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
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    uploads += 1;
    return 'https://example.com/media/$uploads';
  }
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  SubscriptionPlan plan;
  _FakeSubscriptionRepository(this.plan);

  @override
  Stream<SubscriptionPlan> watchPlan() async* {
    yield plan;
  }

  @override
  Future<SubscriptionPlan> getCurrentPlan() async => plan;

  @override
  Future<void> purchasePlusPlan() async {}

  @override
  Future<String> startPlusCheckout() async => '';

  @override
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async =>
      SubscriptionStatus(plan: SubscriptionPlan.free);
}

Message _mediaMessage(String userId, MessageType type) => Message(
      id: 'm-${type.name}',
      matchId: 'match',
      fromUserId: userId,
      toUserId: 'other',
      content: 'url',
      type: type,
      sentAt: DateTime.now(),
      isRead: false,
      isDeletedForSender: false,
    );

void main() {
  group('ChatBloc media limits', () {
    test('blocks media when non-Plus user exceeds limit', () async {
      final chatRepo = _FakeChatRepository();
      final subRepo = _FakeSubscriptionRepository(SubscriptionPlan.free);
      final bloc =
          ChatBloc(chatRepository: chatRepo, subscriptionRepository: subRepo);

      // Seed 8 existing media messages from current user
      bloc.add(ChatMessagesUpdated(
        List<Message>.filled(8, _mediaMessage('me', MessageType.image)),
        SubscriptionPlan.free,
      ));
      await expectLater(bloc.stream, emits(isA<ChatState>()));

      bloc.add(ChatMediaSendRequested(
        matchId: 'match',
        fromUserId: 'me',
        toUserId: 'other',
        filePath: '/tmp/img.jpg',
        type: MessageType.image,
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ChatState>((s) => s.errorMessage != null)),
      );
      expect(chatRepo.sent, isEmpty);
    });

    test('allows media for Plus users', () async {
      final chatRepo = _FakeChatRepository();
      final subRepo = _FakeSubscriptionRepository(SubscriptionPlan.plus);
      final bloc =
          ChatBloc(chatRepository: chatRepo, subscriptionRepository: subRepo);

      bloc.add(ChatMediaSendRequested(
        matchId: 'match',
        fromUserId: 'me',
        toUserId: 'other',
        filePath: '/tmp/video.mp4',
        type: MessageType.video,
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(
            predicate<ChatState>((s) => s.sendStatus == SendStatus.idle)),
      );
      expect(chatRepo.sent.length, 1);
      expect(chatRepo.sent.first.type, MessageType.video);
    });
  });
}
