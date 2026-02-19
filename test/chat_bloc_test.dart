// ignore_for_file: close_sinks - test mock controllers don't require cleanup

import 'dart:async';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_event.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_state.dart';
import 'mock/firebase_mock.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  group('ChatBloc', () {
    group('Initial State', () {
      test('has correct initial values', () {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        expect(bloc.state.messages, isEmpty);
        expect(bloc.state.sendStatus, SendStatus.idle);
        expect(bloc.state.typingUserIds, isEmpty);
        expect(bloc.state.otherUserOnline, false);
        expect(bloc.state.isUnmatched, false);

        bloc.close();
      });
    });

    group('ChatOpened', () {
      test('opens chat and sets initial loading state', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatOpened('match-1', 'user-1', 'user-2'));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ChatState>()
                .having((s) => s.isInitialLoading, 'loading', false),
          ),
        );

        await bloc.close();
      });

      test('sets other user photo url when provided', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatOpened('match-1', 'user-1', 'user-2',
            otherUserPhotoUrl: 'https://example.com/photo.jpg'));

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>().having(
              (s) => s.otherUserPhotoUrl,
              'photoUrl',
              'https://example.com/photo.jpg',
            ),
          ),
        );

        await bloc.close();
      });
    });

    group('ChatMessageSent', () {
      test('sends message and updates send status', () async {
        final chatRepo = _FakeChatRepository();
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: chatRepo,
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatMessageSent(
          matchId: 'match-1',
          fromUserId: 'user-1',
          toUserId: 'user-2',
          content: 'Hello!',
        ));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatState>().having(
                (s) => s.sendStatus, 'status', SendStatus.sendingText),
            isA<ChatState>()
                .having((s) => s.sendStatus, 'status', SendStatus.idle),
          ]),
        );

        expect(chatRepo.sent.length, 1);
        expect(chatRepo.sent.first.content, 'Hello!');

        await bloc.close();
      });

      test('ignores empty message content', () async {
        final chatRepo = _FakeChatRepository();
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: chatRepo,
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatMessageSent(
          matchId: 'match-1',
          fromUserId: 'user-1',
          toUserId: 'user-2',
          content: '   ',
        ));

        await Future.delayed(const Duration(milliseconds: 100));
        expect(chatRepo.sent, isEmpty);

        await bloc.close();
      });

      test('handles send failure with error message', () async {
        final chatRepo = _FakeChatRepository(shouldFailSend: true);
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: chatRepo,
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatMessageSent(
          matchId: 'match-1',
          fromUserId: 'user-1',
          toUserId: 'user-2',
          content: 'Hello!',
        ));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ChatState>().having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );

        await bloc.close();
      });
    });

    group('ChatTypingStatusChanged', () {
      test('updates typing status', () async {
        final chatRepo = _FakeChatRepository();
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: chatRepo,
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatTypingStatusChanged(
          matchId: 'match-1',
          userId: 'user-1',
          isTyping: true,
        ));

        await Future.delayed(const Duration(milliseconds: 100));
        expect(chatRepo.typingCalls, 1);

        await bloc.close();
      });
    });

    group('ChatTypingUsersUpdated', () {
      test('updates typing user ids in state', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatTypingUsersUpdated(const {'user-2', 'user-3'}));

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>().having(
              (s) => s.typingUserIds,
              'typingIds',
              {'user-2', 'user-3'},
            ),
          ),
        );

        await bloc.close();
      });
    });

    group('ChatPresenceUpdated', () {
      test('updates other user online status', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatPresenceUpdated(true));

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>()
                .having((s) => s.otherUserOnline, 'online', true),
          ),
        );

        await bloc.close();
      });
    });

    group('ChatMessageUnsendRequested', () {
      test('requires Plus subscription to unsend', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatMessageUnsendRequested('match-1', 'msg-1'));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ChatState>().having(
              (s) => s.errorMessage,
              'error',
              contains('Plus'),
            ),
          ),
        );

        await bloc.close();
      });

      test('allows Plus users to unsend', () async {
        final chatRepo = _FakeChatRepository();
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: chatRepo,
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.plus),
          authRepository: authRepo,
        );

        bloc.add(ChatMessageUnsendRequested('match-1', 'msg-1'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatState>()
                .having((s) => s.isUnsendInProgress, 'progress', true),
            isA<ChatState>()
                .having((s) => s.isUnsendInProgress, 'progress', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ]),
        );

        expect(chatRepo.unsendCalls, 1);
        await bloc.close();
      });
    });

    group('ChatMessageEditRequested', () {
      test('requires Plus subscription to edit', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatMessageEditRequested(
          matchId: 'match-1',
          messageId: 'msg-1',
          newContent: 'Edited content',
        ));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ChatState>().having(
              (s) => s.errorMessage,
              'error',
              contains('Plus'),
            ),
          ),
        );

        await bloc.close();
      });

      test('allows Plus users to edit', () async {
        final chatRepo = _FakeChatRepository();
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: chatRepo,
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.plus),
          authRepository: authRepo,
        );

        bloc.add(ChatMessageEditRequested(
          matchId: 'match-1',
          messageId: 'msg-1',
          newContent: 'Edited content',
        ));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatState>().having((s) => s.isEditInProgress, 'progress', true),
            isA<ChatState>()
                .having((s) => s.isEditInProgress, 'progress', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ]),
        );

        expect(chatRepo.editCalls, 1);
        await bloc.close();
      });
    });

    group('ChatUnmatchRequested', () {
      test('unmatches user successfully', () async {
        final chatRepo = _FakeChatRepository();
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: chatRepo,
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatUnmatchRequested(matchId: 'match-1', userId: 'user-1'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatState>().having((s) => s.isUnmatching, 'unmatching', true),
            isA<ChatState>()
                .having((s) => s.isUnmatching, 'unmatching', false)
                .having((s) => s.isUnmatched, 'unmatched', true),
          ]),
        );

        expect(chatRepo.unmatchCalls, 1);
        await bloc.close();
      });
    });

    group('ChatMediaStatusUpdated', () {
      test('updates media sending enabled status', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatMediaStatusUpdated(false));

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>()
                .having((s) => s.mediaSendingEnabled, 'enabled', false),
          ),
        );

        await bloc.close();
      });
    });

    group('ChatResetRequested', () {
      test('resets state to initial', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        // First add some messages
        bloc.add(ChatMessagesUpdated([_testMessage('1')], SubscriptionPlan.free));
        await Future.delayed(const Duration(milliseconds: 100));
        expect(bloc.state.messages.isNotEmpty, true);

        // Then reset
        bloc.add(ChatResetRequested());

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>()
                .having((s) => s.messages, 'messages', isEmpty),
          ),
        );

        await bloc.close();
      });
    });

    group('ChatE2eeToggled', () {
      test('updates e2ee status in state', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        bloc.add(ChatE2eeToggled(false));

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>()
                .having((s) => s.isE2eeEnabled, 'e2ee', false),
          ),
        );

        bloc.add(ChatE2eeToggled(true));

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>()
                .having((s) => s.isE2eeEnabled, 'e2ee', true),
          ),
        );

        await bloc.close();
      });
    });

    group('ChatMessagesUpdated', () {
      test('updates messages list', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        final messages = [_testMessage('1'), _testMessage('2')];
        bloc.add(ChatMessagesUpdated(messages, SubscriptionPlan.free));

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>()
                .having((s) => s.messages.length, 'count', 2),
          ),
        );

        await bloc.close();
      });

      test('sets premium features based on plan', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.plus),
          authRepository: authRepo,
        );

        bloc.add(ChatMessagesUpdated([_testMessage('1')], SubscriptionPlan.plus));

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>()
                .having((s) => s.canUnsend, 'canUnsend', true)
                .having((s) => s.canEdit, 'canEdit', true)
                .having((s) => s.canSeeReadReceipts, 'receipts', true),
          ),
        );

        await bloc.close();
      });
    });

    group('Auth State Changes', () {
      test('resets state when user logs out', () async {
        final authRepo = _FakeAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ChatBloc(
          chatRepository: _FakeChatRepository(),
          subscriptionRepository: _FakeSubscriptionRepository(SubscriptionPlan.free),
          authRepository: authRepo,
        );

        // Add messages first
        bloc.add(ChatMessagesUpdated([_testMessage('1')], SubscriptionPlan.free));
        await Future.delayed(const Duration(milliseconds: 100));

        // Trigger logout
        authRepo.emitLogout();

        await expectLater(
          bloc.stream,
          emits(
            isA<ChatState>()
                .having((s) => s.messages, 'messages', isEmpty),
          ),
        );

        await bloc.close();
      });
    });
  });
}

// =============================================================================
// Test Helpers
// =============================================================================

Message _testMessage(String id) => Message(
      id: id,
      matchId: 'match-1',
      fromUserId: 'user-1',
      toUserId: 'user-2',
      content: 'Test message $id',
      type: MessageType.text,
      sentAt: DateTime.now(),
      isRead: false,
      isDeletedForSender: false,
    );

// =============================================================================
// Stub Repositories
// =============================================================================

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({this.shouldFailSend = false});

  final bool shouldFailSend;
  final List<Message> sent = [];
  int uploads = 0;
  int typingCalls = 0;
  int unsendCalls = 0;
  int editCalls = 0;
  int unmatchCalls = 0;

  final _typingController = StreamController<Set<String>>.broadcast()..add(const {});
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
  }) async {
    typingCalls++;
  }

  @override
  Stream<bool> watchPresence(String userId) => _presenceController.stream;

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {}

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) => _mediaController.stream;

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
    if (shouldFailSend) {
      throw Exception('Failed to send message');
    }
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
  }) async {
    unsendCalls++;
  }

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    editCalls++;
  }

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
  }) async {
    unmatchCalls++;
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async => [];

  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async =>
      const PaginatedResult(items: [], total: 0, hasMore: false);

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    uploads += 1;
    return 'https://example.com/media/$uploads';
  }

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) async =>
      const PaginatedResult(items: [], total: 0, hasMore: false);

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) async* {
    yield const [];
  }

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
  }) async =>
      null;

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async => const [];

  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) async =>
      false;

  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) async =>
      0;

  // ── E2EE stubs ──
  @override
  bool get isE2eeEnabled => false;

  @override
  void setE2eeEnabled(bool enabled) {}

  @override
  bool isEncryptedContent(String content) => false;

  @override
  Future<Message> decryptMessage(Message message) async => message;
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

  @override
  Future<PromoCode?> validatePromoCode(String code) async => null;

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async =>
      PromoCodeRedemptionResult.failure('Not implemented in test');

  @override
  Future<List<PromoCode>> getRedeemedCodes() async => [];
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<CrushUser?> _controller =
      StreamController<CrushUser?>.broadcast();

  void emitLogout() {
    _controller.add(null);
  }

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  Future<void> bootstrapSession() async {}

  @override
  Stream<CrushUser?> authStateChanges() => _controller.stream;

  void dispose() {
    _controller.close();
  }

  @override
  Future<void> sendOtp(String phoneNumber) async => throw UnimplementedError();

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> sendEmailSignInLink(String email) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signInWithApple() async => throw UnimplementedError();

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) async =>
      throw UnimplementedError();

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }

  @override
  Future<void> sendEmailVerification() async => throw UnimplementedError();

  @override
  Future<CrushUser?> checkEmailVerification() async =>
      throw UnimplementedError();

  @override
  Future<void> schedulePhoneDeletion() async => throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deactivateAccount({required String reason}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> isEmailRegistered(String email) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> acceptTermsAndConditions() async =>
      throw UnimplementedError();

  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}
