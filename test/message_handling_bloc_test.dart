import 'dart:async';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'package:crushhour/features/chat/presentation/bloc/message_handling_bloc.dart';
import 'package:crushhour/features/subscription/domain/models/subscription_product.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/stub_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  group('MessageHandlingBloc hotspot coverage', () {
    late _FakeChatRepository chatRepo;
    late _FakeSubscriptionRepository subscriptionRepo;
    late MessageHandlingBloc bloc;

    setUp(() {
      chatRepo = _FakeChatRepository();
      subscriptionRepo = _FakeSubscriptionRepository(
        tier: SubscriptionTier.free,
      );
      bloc = MessageHandlingBloc(
        chatRepository: chatRepo,
        subscriptionRepository: subscriptionRepo,
        isE2eeEnabled: () => chatRepo.isE2eeEnabled,
      );
    });

    tearDown(() async {
      await bloc.close();
      await chatRepo.dispose();
    });

    test(
      'initial load succeeds with pagination and marks messages read',
      () async {
        subscriptionRepo.tier = SubscriptionTier.plus;
        chatRepo.initialPage = PaginatedResult<Message>(
          items: [
            _msg('m1', content: 'hello', sentAt: DateTime(2026, 2, 10, 10)),
            _msg('m2', content: 'world', sentAt: DateTime(2026, 2, 10, 11)),
          ],
          total: 2,
          hasMore: false,
        );

        bloc.add(
          MsgInitialLoadRequested(matchId: 'match-1', currentUserId: 'me'),
        );
        await _settle();

        expect(bloc.state.isInitialLoading, isFalse);
        expect(bloc.state.messages.map((m) => m.id), ['m1', 'm2']);
        expect(bloc.state.canUnsend, isTrue);
        expect(bloc.state.canEdit, isTrue);
        expect(bloc.state.canSeeReadReceipts, isTrue);
        expect(bloc.state.hasMoreMessages, isFalse);
        expect(chatRepo.watchNewMessagesCalls, 1);
        expect(chatRepo.markReadCalls, 1);
      },
    );

    test('initial load surfaces subscription plan failure', () async {
      subscriptionRepo.throwOnGetCurrentPlan = true;

      bloc.add(
        MsgInitialLoadRequested(matchId: 'match-1', currentUserId: 'me'),
      );
      await _settle();

      expect(bloc.state.isInitialLoading, isFalse);
      expect(bloc.state.errorMessage, 'Could not load chat.');
    });

    test(
      'initial load falls back to legacy stream when pagination fails',
      () async {
        chatRepo.throwOnFetchInitial = true;

        bloc.add(
          MsgInitialLoadRequested(matchId: 'match-legacy', currentUserId: 'me'),
        );
        await _settle();

        expect(chatRepo.watchMessagesCalls, 1);
        expect(bloc.state.hasMoreMessages, isFalse);
        expect(bloc.state.errorMessage, 'Could not load messages.');

        chatRepo.legacyMessagesController.add([
          _msg('legacy-1', content: 'legacy'),
        ]);
        await _settle();

        expect(bloc.state.messages.map((m) => m.id), ['legacy-1']);
      },
    );

    test('initial load decrypts messages when E2EE is enabled', () async {
      chatRepo.setE2eeEnabled(true);
      chatRepo.initialPage = PaginatedResult<Message>(
        items: [_msg('enc-1', content: 'enc:secret')],
        total: 1,
        hasMore: false,
      );

      bloc.add(
        MsgInitialLoadRequested(matchId: 'match-e2ee', currentUserId: 'me'),
      );
      await _settle();

      expect(chatRepo.decryptCalls, 1);
      expect(bloc.state.messages.single.content, 'dec:secret');
    });

    test('send ignores empty content', () async {
      bloc.add(
        MsgSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          content: '   ',
        ),
      );
      await _settle();

      expect(chatRepo.sendCalls, 0);
      expect(bloc.state.failedMessages, isEmpty);
    });

    test('send failure stores failed optimistic message', () async {
      chatRepo.throwOnSend = true;

      bloc.add(
        MsgSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          content: 'hello fail',
        ),
      );
      await _settle();

      expect(chatRepo.sendCalls, 1);
      expect(chatRepo.setTypingCalls, 1);
      expect(bloc.state.sendStatus, SendStatus.idle);
      expect(bloc.state.failedMessages.length, 1);
      expect(
        bloc.state.failedMessages.values.single.sendStatus,
        MessageSendStatus.failed,
      );
      expect(
        bloc.state.errorMessage,
        'Message failed to send. Check your connection and retry.',
      );
    });

    test('send success clears optimistic entry and typing status', () async {
      bloc.add(
        MsgSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          content: 'hello success',
        ),
      );
      await _settle();

      expect(chatRepo.sendCalls, 1);
      expect(chatRepo.setTypingCalls, 1);
      expect(bloc.state.sendStatus, SendStatus.idle);
      expect(bloc.state.failedMessages, isEmpty);
      expect(bloc.state.errorMessage, isNull);
    });

    test('media send enforces disabled and free-plan limit checks', () async {
      bloc.add(
        MsgMediaSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          filePath: '/tmp/photo.jpg',
          type: MessageType.image,
          mediaSendingEnabled: false,
        ),
      );
      await _settle();

      expect(
        bloc.state.errorMessage,
        'Media sending is disabled for this match.',
      );
      expect(chatRepo.uploadCalls, 0);

      bloc.add(
        MsgLegacyMessagesUpdated(
          List.generate(
            8,
            (i) => _msg(
              'media-$i',
              fromUserId: 'me',
              type: MessageType.image,
              content: 'https://cdn/$i.jpg',
              sentAt: DateTime(2026, 2, 11, 9, i),
            ),
          ),
          SubscriptionTier.free,
        ),
      );
      await _settle();

      bloc.add(
        MsgMediaSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          filePath: '/tmp/over-limit.jpg',
          type: MessageType.image,
          mediaSendingEnabled: true,
        ),
      );
      await _settle();

      expect(
        bloc.state.errorMessage,
        'Media limit reached. Upgrade to Plus for unlimited media.',
      );
      expect(chatRepo.uploadCalls, 0);
    });

    test('media send handles upload and send failures', () async {
      subscriptionRepo.tier = SubscriptionTier.plus;
      chatRepo.throwOnUpload = true;

      bloc.add(
        MsgMediaSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          filePath: '/tmp/fail-upload.jpg',
          type: MessageType.image,
          mediaSendingEnabled: true,
        ),
      );
      await _settle();

      expect(bloc.state.sendStatus, SendStatus.idle);
      expect(bloc.state.uploadingAttachmentName, isNull);
      expect(
        bloc.state.errorMessage,
        'Media message failed to send. Check your connection and try again.',
      );

      chatRepo.throwOnUpload = false;
      chatRepo.throwOnSend = true;
      bloc.add(
        MsgMediaSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          filePath: '/tmp/fail-send.jpg',
          type: MessageType.image,
          mediaSendingEnabled: true,
        ),
      );
      await _settle();

      expect(chatRepo.uploadCalls, greaterThan(0));
      expect(chatRepo.sendCalls, greaterThan(0));
      expect(
        bloc.state.errorMessage,
        'Media message failed to send. Check your connection and try again.',
      );
    });

    test(
      'unsend and edit enforce plan checks and repository failures',
      () async {
        bloc.add(MsgUnsendRequested(matchId: 'match-1', messageId: 'msg-1'));
        await _settle();
        expect(bloc.state.errorMessage, 'Upgrade to Plus to unsend messages.');

        bloc.add(
          MsgEditRequested(
            matchId: 'match-1',
            messageId: 'msg-1',
            newContent: 'updated',
          ),
        );
        await _settle();
        expect(bloc.state.errorMessage, 'Upgrade to Plus to edit messages.');

        subscriptionRepo.tier = SubscriptionTier.plus;
        chatRepo.throwOnUnsend = true;
        bloc.add(MsgUnsendRequested(matchId: 'match-1', messageId: 'msg-2'));
        await _settle();
        expect(bloc.state.errorMessage, 'Could not unsend message.');

        chatRepo.throwOnUnsend = false;
        chatRepo.throwOnEdit = true;
        bloc.add(
          MsgEditRequested(
            matchId: 'match-1',
            messageId: 'msg-2',
            newContent: 'updated again',
          ),
        );
        await _settle();
        expect(bloc.state.errorMessage, 'Could not edit message.');
      },
    );

    test('delete and reaction failures are surfaced in state', () async {
      chatRepo.throwOnDeleteForMe = true;
      bloc.add(
        MsgDeleteForMeRequested(
          matchId: 'match-1',
          messageId: 'msg-1',
          userId: 'me',
        ),
      );
      await _settle();
      expect(bloc.state.errorMessage, 'Could not delete message.');

      chatRepo.throwOnAddReaction = true;
      bloc.add(
        MsgReactionAdded(
          matchId: 'match-1',
          messageId: 'msg-1',
          userId: 'me',
          emoji: '🔥',
        ),
      );
      await _settle();
      expect(bloc.state.errorMessage, 'Could not add reaction.');

      chatRepo.throwOnRemoveReaction = true;
      bloc.add(
        MsgReactionRemoved(
          matchId: 'match-1',
          messageId: 'msg-1',
          userId: 'me',
        ),
      );
      await _settle();
      expect(bloc.state.errorMessage, 'Could not remove reaction.');
    });

    test(
      'load more appends older messages and handles load failures',
      () async {
        chatRepo.initialPage = PaginatedResult<Message>(
          items: [_msg('newer', sentAt: DateTime(2026, 2, 12, 12, 0))],
          total: 1,
          hasMore: true,
        );
        chatRepo.olderPage = PaginatedResult<Message>(
          items: [_msg('older', sentAt: DateTime(2026, 2, 12, 11, 0))],
          total: 2,
          hasMore: false,
        );
        bloc.add(
          MsgInitialLoadRequested(matchId: 'match-1', currentUserId: 'me'),
        );
        await _settle();
        expect(bloc.state.hasMoreMessages, isTrue);

        bloc.add(MsgLoadMoreRequested('match-1'));
        await _settle();

        expect(bloc.state.messages.map((m) => m.id), ['older', 'newer']);
        expect(bloc.state.hasMoreMessages, isFalse);

        final fetchCallsBefore = chatRepo.fetchMessagesPaginatedCalls;
        bloc.add(MsgLoadMoreRequested('match-1'));
        await _settle();
        expect(chatRepo.fetchMessagesPaginatedCalls, fetchCallsBefore);

        chatRepo.initialPage = PaginatedResult<Message>(
          items: [_msg('newer-2', sentAt: DateTime(2026, 2, 12, 13, 0))],
          total: 1,
          hasMore: true,
        );
        chatRepo.throwOnFetchMore = true;
        bloc.add(
          MsgInitialLoadRequested(matchId: 'match-2', currentUserId: 'me'),
        );
        await _settle();
        bloc.add(MsgLoadMoreRequested('match-2'));
        await _settle();

        expect(bloc.state.errorMessage, 'Could not load more messages.');
      },
    );

    test(
      'new message and legacy dedupe paths update state deterministically',
      () async {
        final existing = _msg('existing', content: 'enc:hello');
        bloc.add(MsgLegacyMessagesUpdated([existing], SubscriptionTier.free));
        await _settle();

        bloc.add(MsgNewMessagesReceived([existing]));
        await _settle();
        expect(bloc.state.messages.length, 1);

        final newMessage = _msg(
          'new',
          content: 'new text',
          sentAt: DateTime(2026, 2, 12, 14, 0),
        );
        bloc.add(MsgNewMessagesReceived([newMessage]));
        await _settle();
        expect(bloc.state.messages.map((m) => m.id), ['existing', 'new']);
      },
    );

    test(
      'legacy update clears matching optimistic messages by signature',
      () async {
        chatRepo.throwOnSend = true;
        bloc.add(
          MsgSendRequested(
            matchId: 'match-1',
            fromUserId: 'me',
            toUserId: 'them',
            content: 'optimistic hello',
          ),
        );
        await _settle();

        final optimistic = bloc.state.failedMessages.values.single;
        final serverMessage = _msg(
          'server-real',
          fromUserId: optimistic.fromUserId,
          toUserId: optimistic.toUserId,
          content: optimistic.content,
          type: optimistic.type,
          sentAt: optimistic.sentAt.add(const Duration(seconds: 5)),
        );

        bloc.add(
          MsgLegacyMessagesUpdated([serverMessage], SubscriptionTier.free),
        );
        await _settle();

        expect(bloc.state.failedMessages, isEmpty);
        expect(bloc.state.messages.map((m) => m.id), ['server-real']);
      },
    );

    test('retry handles missing, success, and failure paths', () async {
      bloc.add(
        MsgRetryRequested(matchId: 'match-1', messageId: 'missing-message'),
      );
      await _settle();
      expect(
        bloc.state.errorMessage,
        'Message not found. It may have already been sent.',
      );

      chatRepo.throwOnSend = true;
      bloc.add(
        MsgSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          content: 'retry me',
        ),
      );
      await _settle();
      final failedId = bloc.state.failedMessages.keys.single;

      chatRepo.throwOnSend = false;
      bloc.add(MsgRetryRequested(matchId: 'match-1', messageId: failedId));
      await _settle();
      expect(bloc.state.failedMessages, isEmpty);

      chatRepo.throwOnSend = true;
      bloc.add(
        MsgSendRequested(
          matchId: 'match-1',
          fromUserId: 'me',
          toUserId: 'them',
          content: 'retry fail',
        ),
      );
      await _settle();
      final failedId2 = bloc.state.failedMessages.keys.single;

      bloc.add(MsgRetryRequested(matchId: 'match-1', messageId: failedId2));
      await _settle();
      expect(
        bloc.state.failedMessages[failedId2]?.sendStatus,
        MessageSendStatus.failed,
      );
      expect(
        bloc.state.errorMessage,
        'Message failed to send. Please try again.',
      );
    });

    test(
      'reset and explicit subscription cancel restore initial state',
      () async {
        bloc.add(
          MsgLegacyMessagesUpdated([
            _msg('before-reset', content: 'value'),
          ], SubscriptionTier.plus),
        );
        await _settle();
        expect(bloc.state.messages, isNotEmpty);

        bloc.cancelSubscriptions();
        bloc.add(MsgResetRequested());
        await _settle();

        expect(bloc.state, const MessageHandlingState());
      },
    );
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 60));
}

Message _msg(
  String id, {
  String matchId = 'match-1',
  String fromUserId = 'me',
  String toUserId = 'them',
  String content = 'hello',
  MessageType type = MessageType.text,
  DateTime? sentAt,
}) {
  return Message(
    id: id,
    matchId: matchId,
    fromUserId: fromUserId,
    toUserId: toUserId,
    content: content,
    type: type,
    sentAt: sentAt ?? DateTime(2026, 2, 12, 10, 0),
    isRead: false,
    isDeletedForSender: false,
  );
}

Message _cloneWithContent(Message source, String content) {
  return Message(
    id: source.id,
    matchId: source.matchId,
    fromUserId: source.fromUserId,
    toUserId: source.toUserId,
    content: content,
    type: source.type,
    sentAt: source.sentAt,
    isRead: source.isRead,
    readAt: source.readAt,
    isDeletedForSender: source.isDeletedForSender,
    reactions: source.reactions,
    moderationStatus: source.moderationStatus,
    moderationReason: source.moderationReason,
    moderationAction: source.moderationAction,
    isFlagged: source.isFlagged,
    sendStatus: source.sendStatus,
  );
}

class _FakeChatRepository implements ChatRepository {
  PaginatedResult<Message> initialPage = const PaginatedResult(
    items: [],
    total: 0,
    hasMore: false,
  );
  PaginatedResult<Message> olderPage = const PaginatedResult(
    items: [],
    total: 0,
    hasMore: false,
  );

  final StreamController<List<Message>> legacyMessagesController =
      StreamController<List<Message>>.broadcast();
  final StreamController<List<Message>> newMessagesController =
      StreamController<List<Message>>.broadcast();

  bool throwOnFetchInitial = false;
  bool throwOnFetchMore = false;
  bool throwOnMarkRead = false;
  bool throwOnSend = false;
  bool throwOnSetTyping = false;
  bool throwOnUpload = false;
  bool throwOnUnsend = false;
  bool throwOnEdit = false;
  bool throwOnDeleteForMe = false;
  bool throwOnAddReaction = false;
  bool throwOnRemoveReaction = false;

  int fetchMessagesPaginatedCalls = 0;
  int watchMessagesCalls = 0;
  int watchNewMessagesCalls = 0;
  int markReadCalls = 0;
  int sendCalls = 0;
  int setTypingCalls = 0;
  int uploadCalls = 0;
  int unsendCalls = 0;
  int editCalls = 0;
  int deleteForMeCalls = 0;
  int addReactionCalls = 0;
  int removeReactionCalls = 0;
  int decryptCalls = 0;

  String uploadUrl = 'https://cdn.example.com/uploaded-media.jpg';
  bool encryptedContentFlag = false;
  bool _isE2eeEnabled = false;

  Future<void> dispose() async {
    await legacyMessagesController.close();
    await newMessagesController.close();
  }

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    watchMessagesCalls++;
    return legacyMessagesController.stream;
  }

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) async {
    fetchMessagesPaginatedCalls++;
    if (beforeTimestamp == null) {
      if (throwOnFetchInitial) {
        throw Exception('initial fetch failed');
      }
      return initialPage;
    }
    if (throwOnFetchMore) {
      throw Exception('load more failed');
    }
    return olderPage;
  }

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) {
    watchNewMessagesCalls++;
    return newMessagesController.stream;
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    sendCalls++;
    if (throwOnSend) {
      throw Exception('send failed');
    }
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    uploadCalls++;
    if (throwOnUpload) {
      throw Exception('upload failed');
    }
    return uploadUrl;
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    markReadCalls++;
    if (throwOnMarkRead) {
      throw Exception('mark read failed');
    }
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    unsendCalls++;
    if (throwOnUnsend) {
      throw Exception('unsend failed');
    }
  }

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    editCalls++;
    if (throwOnEdit) {
      throw Exception('edit failed');
    }
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    deleteForMeCalls++;
    if (throwOnDeleteForMe) {
      throw Exception('delete failed');
    }
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
  }) async {}

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    addReactionCalls++;
    if (throwOnAddReaction) {
      throw Exception('add reaction failed');
    }
  }

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    removeReactionCalls++;
    if (throwOnRemoveReaction) {
      throw Exception('remove reaction failed');
    }
  }

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
  }) async {
    setTypingCalls++;
    if (throwOnSetTyping) {
      throw Exception('typing failed');
    }
  }

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
  Future<List<CrushMatch>> fetchUserMatches(String userId) async => const [];

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
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async =>
      const [];

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
  bool get isE2eeEnabled => _isE2eeEnabled;

  @override
  void setE2eeEnabled(bool enabled) {
    _isE2eeEnabled = enabled;
  }

  @override
  bool isEncryptedContent(String content) {
    if (encryptedContentFlag) return true;
    return content.startsWith('enc:');
  }

  @override
  Future<Message> decryptMessage(Message message) async {
    decryptCalls++;
    if (message.content.startsWith('enc:')) {
      return _cloneWithContent(
        message,
        'dec:${message.content.replaceFirst('enc:', '')}',
      );
    }
    return _cloneWithContent(message, 'dec:${message.content}');
  }
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({required this.tier});

  SubscriptionTier tier;
  bool throwOnGetCurrentPlan = false;

  @override
  Stream<SubscriptionTier> watchPlan() async* {
    yield tier;
  }

  @override
  Future<SubscriptionTier> getCurrentPlan() async {
    if (throwOnGetCurrentPlan) {
      throw Exception('plan fetch failed');
    }
    return tier;
  }

  @override
  Future<void> purchaseSubscription({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async {}

  @override
  Future<void> purchaseProduct({required String productId}) async {
    final selection = subscriptionSelectionForProductId(productId);
    if (selection == null) {
      throw UnsupportedError('Unknown subscription product: $productId');
    }
    await purchaseSubscription(tier: selection.tier, period: selection.period);
  }

  @override
  Future<String> startCheckout({
    required SubscriptionTier tier,
    required BillingPeriod period,
  }) async => '';

  @override
  Future<void> launchCheckoutUrl(String url) async {}

  @override
  Future<SubscriptionStatus> refreshStatus() async =>
      SubscriptionStatus(tier: tier);

  @override
  Future<SubscriptionStatus> restorePurchases() => refreshStatus();

  @override
  Future<SubscriptionStatus> verifyPurchaseReceipt({
    required String platform,
    required String receiptData,
    required String productId,
    String? packageName,
  }) => refreshStatus();

  @override
  Future<List<SubscriptionProduct>> fetchAvailableProducts() async => const [];

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      PromoCodeRedemptionResult.failure('not implemented');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => const [];
}
