import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/message_request.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/features/chat/domain/repositories/chat_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock/stub_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafetyCubit', () {
    late SharedPreferences prefs;
    late _StubChatRepository chatRepo;
    late _StubDiscoveryRepository discoveryRepo;
    late SafetyCubit cubit;
    late StubAnalyticsService analytics;

    setUp(() async {
      analytics = StubAnalyticsService();
      AnalyticsService.setInstance(analytics);
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
      AnalyticsService.resetInstance();
    });

    Future<void> recreateCubitWithPrefs(
      Map<String, Object> initialValues,
    ) async {
      await cubit.close();
      SharedPreferences.setMockInitialValues(initialValues);
      prefs = await SharedPreferences.getInstance();
      cubit = SafetyCubit(
        preferences: prefs,
        chatRepository: chatRepo,
        discoveryRepository: discoveryRepo,
      );
    }

    test('blocks and unblocks users with backend calls', () async {
      await cubit.toggleBlock('target', block: true, currentUserId: 'me');
      expect(cubit.state.blockedUsers, contains('target'));
      expect(chatRepo.blockedPairs, contains(('me', 'target')));
      expect(analytics.loggedEvents, contains('logUserBlocked'));

      await cubit.toggleBlock('target', block: false, currentUserId: 'me');
      expect(cubit.state.blockedUsers, isNot(contains('target')));
      expect(chatRepo.unblockedPairs, contains(('me', 'target')));
    });

    test('returns user-facing error when current user id is missing', () async {
      await cubit.toggleBlock('target', block: true, currentUserId: '');

      expect(chatRepo.blockedPairs, isEmpty);
      expect(
        cubit.state.errorMessage,
        'Sign in again to manage safety actions.',
      );
    });

    test('emits fallback error when block backend call fails', () async {
      chatRepo.throwOnBlock = true;

      await cubit.toggleBlock('target', block: true, currentUserId: 'me');

      expect(cubit.state.blockedUsers, isNot(contains('target')));
      expect(
        cubit.state.errorMessage,
        'Could not block this user. Please try again.',
      );
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
        contains((
          reporterId: 'me',
          reportedId: 'target',
          reason: 'spam',
          source: 'deck',
        )),
      );
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.reportedUsers.containsKey('target'), isTrue);
      expect(cubit.isReportedRecently('target'), isTrue);
      expect(cubit.shouldHideFromFeed('target'), isTrue);
      expect(
        prefs
            .getStringList('safety_reported_users')
            ?.any((entry) => entry.startsWith('target:')),
        isTrue,
      );
      expect(analytics.loggedEvents, contains('logUserReported:spam'));
    });

    test('emits errorMessage when backend fails', () async {
      chatRepo.throwOnReport = true;

      await cubit.reportWithContext(
        reporterId: 'me',
        reportedId: 'target',
        reason: 'spam',
      );

      expect(cubit.state.errorMessage, isNotNull);
    });

    test('reportUser convenience wrapper uses anonymous reporter id', () async {
      await cubit.reportUser('target', 'harassment');

      expect(
        chatRepo.reports,
        contains((
          reporterId: 'anonymous',
          reportedId: 'target',
          reason: 'harassment',
          source: null,
        )),
      );
    });

    test('submitAppeal clears stale error message when successful', () async {
      chatRepo.throwOnReport = true;
      await cubit.reportWithContext(
        reporterId: 'me',
        reportedId: 'target',
        reason: 'spam',
      );
      expect(cubit.state.errorMessage, isNotNull);

      chatRepo.throwOnReport = false;
      await cubit.submitAppeal(
        userId: 'me',
        reason: 'I was mistaken',
        targetType: 'report',
        targetId: 'target',
      );

      expect(cubit.state.errorMessage, isNull);
      expect(
        chatRepo.appeals,
        contains((
          userId: 'me',
          reason: 'I was mistaken',
          targetType: 'report',
          targetId: 'target',
        )),
      );
    });

    test('submitAppeal emits fallback error when backend fails', () async {
      chatRepo.throwOnAppeal = true;

      await cubit.submitAppeal(userId: 'me', reason: 'Please review');

      expect(
        cubit.state.errorMessage,
        'Could not submit appeal. Please try again.',
      );
    });

    test('toggles muted sets and persists values to preferences', () async {
      await cubit.toggleMuteMessages('target', mute: true);
      await cubit.toggleMuteCalls('target', mute: true);
      expect(cubit.isMessagesMuted('target'), isTrue);
      expect(cubit.isCallsMuted('target'), isTrue);

      await cubit.toggleMuteMessages('target', mute: false);
      await cubit.toggleMuteCalls('target', mute: false);
      expect(cubit.isMessagesMuted('target'), isFalse);
      expect(cubit.isCallsMuted('target'), isFalse);
      expect(
        prefs.getStringList('safety_muted_messages'),
        isNot(contains('target')),
      );
      expect(
        prefs.getStringList('safety_muted_calls'),
        isNot(contains('target')),
      );
    });

    test(
      'parses reported users from prefs and applies recency window',
      () async {
        final recent = DateTime.now().subtract(const Duration(days: 2));
        final stale = DateTime.now().subtract(const Duration(days: 12));
        final recentDateOnly = recent.toIso8601String().split('T').first;
        final staleDateOnly = stale.toIso8601String().split('T').first;

        await recreateCubitWithPrefs({
          'safety_blocked': ['blocked-user'],
          'safety_muted_messages': ['muted-message-user'],
          'safety_muted_calls': ['muted-call-user'],
          'safety_reported_users': [
            'recent-user:$recentDateOnly',
            'stale-user:$staleDateOnly',
            'invalid-format',
            'bad-time:not-a-date',
          ],
        });

        expect(cubit.isBlocked('blocked-user'), isTrue);
        expect(cubit.isMessagesMuted('muted-message-user'), isTrue);
        expect(cubit.isCallsMuted('muted-call-user'), isTrue);
        expect(cubit.isReportedRecently('recent-user'), isTrue);
        expect(cubit.isReportedRecently('stale-user'), isFalse);
        expect(cubit.shouldHideFromFeed('blocked-user'), isTrue);
        expect(cubit.shouldHideFromFeed('recent-user'), isTrue);
        expect(cubit.shouldHideFromFeed('stale-user'), isFalse);
      },
    );

    test(
      'loadProfilesForSafetyUsers fetches uncached users and uses placeholders',
      () async {
        await recreateCubitWithPrefs({
          'safety_blocked': ['found-user', 'missing-user'],
          'safety_muted_messages': ['error-user'],
          'safety_muted_calls': ['found-user'],
        });

        discoveryRepo.profilesById['found-user'] = _profile(
          id: 'found-user',
          name: 'Found User',
          photoUrls: const ['https://example.com/p.jpg'],
        );
        discoveryRepo.throwForIds.add('error-user');

        await cubit.loadProfilesForSafetyUsers();

        expect(cubit.state.isLoadingProfiles, isFalse);
        expect(discoveryRepo.fetchProfileCalls.toSet().length, 3);
        expect(cubit.getProfileInfo('found-user')?.name, 'Found User');
        expect(
          cubit.getProfileInfo('found-user')?.photoUrl,
          'https://example.com/p.jpg',
        );
        expect(cubit.getProfileInfo('missing-user')?.name, 'User missing-user');
        expect(cubit.getProfileInfo('error-user')?.name, 'User error-user');
        expect(cubit.getProfileInfo('unknown'), isNull);

        await cubit.loadProfilesForSafetyUsers();
        expect(discoveryRepo.fetchProfileCalls.toSet().length, 3);
      },
    );
  });
}

class _StubChatRepository implements ChatRepository {
  bool throwOnBlock = false;
  bool throwOnUnblock = false;
  bool throwOnReport = false;
  bool throwOnAppeal = false;
  final List<(String, String)> blockedPairs = [];
  final List<(String, String)> unblockedPairs = [];
  final List<
    ({String reporterId, String reportedId, String reason, String? source})
  >
  reports = [];
  final List<
    ({String userId, String reason, String? targetType, String? targetId})
  >
  appeals = [];

  void _throwIf(bool enabled) {
    if (enabled) throw Exception('network failed');
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _throwIf(throwOnBlock);
    blockedPairs.add((blockerId, blockedId));
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _throwIf(throwOnUnblock);
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
    _throwIf(throwOnReport);
    reports.add((
      reporterId: reporterId,
      reportedId: reportedId,
      reason: reason,
      source: source,
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
    _throwIf(false);
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    _throwIf(false);
    return const [];
  }

  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    _throwIf(false);
    return const PaginatedResult(items: [], total: 0, hasMore: false);
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    _throwIf(false);
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    _throwIf(false);
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
    _throwIf(false);
    return '';
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    _throwIf(false);
  }

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    _throwIf(false);
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    _throwIf(false);
  }

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    _throwIf(throwOnAppeal);
    appeals.add((
      userId: userId,
      reason: reason,
      targetType: targetType,
      targetId: targetId,
    ));
  }

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) async {
    _throwIf(false);
    return const PaginatedResult(items: [], total: 0, hasMore: false);
  }

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) => const Stream.empty();

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
    _throwIf(false);
    return null;
  }

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async {
    _throwIf(false);
    return const [];
  }

  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) async {
    _throwIf(false);
    return false;
  }

  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) async {
    _throwIf(false);
    return 0;
  }

  @override
  bool get isE2eeEnabled => false;

  @override
  void setE2eeEnabled(bool enabled) {}

  @override
  bool isEncryptedContent(String content) => false;

  @override
  Future<Message> decryptMessage(Message message) async => message;
}

class _StubDiscoveryRepository implements DiscoveryRepository {
  final Map<String, Profile?> profilesById = {};
  final Set<String> throwForIds = {};
  final List<String> fetchProfileCalls = [];

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
  Future<Profile?> fetchProfileById(String profileId) async {
    fetchProfileCalls.add(profileId);
    if (throwForIds.contains(profileId)) {
      throw Exception('Failed to fetch profile');
    }
    return profilesById[profileId];
  }

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async => null;

  @override
  Future<Profile?> rewindLastSwipe(String userId) async => null;
}

Profile _profile({
  required String id,
  required String name,
  List<String> photoUrls = const [],
}) {
  return Profile(
    id: id,
    name: name,
    age: 25,
    gender: 'female',
    photoUrls: photoUrls,
    videoUrls: const [],
    bio: 'bio',
    interests: const ['music'],
    country: 'US',
    city: 'Austin',
    isVerified: false,
    preferences: const DiscoveryPreferences(
      minAge: 18,
      maxAge: 40,
      maxDistanceKm: 50,
      showMeGenders: ['male'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: 'US',
      city: 'Austin',
    ),
    privacySettings: ProfilePrivacySettings.allPublic(),
  );
}
