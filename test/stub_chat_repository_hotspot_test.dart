import 'dart:async';
import 'dart:convert';

import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/chat/data/repositories/impl/stub_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StubChatRepository hotspot branches', () {
    late StubChatRepository repo;
    late _TestClock clock;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = _TestClock(DateTime(2026, 2, 15, 12));
      repo = StubChatRepository(
        delayExecutor: (_) async {},
        nowProvider: clock.next,
        shouldAutoReply: (_) => false,
        watchNewMessagesInterval: const Duration(milliseconds: 5),
      );
    });

    tearDown(() {
      repo.dispose();
    });

    test('watchMessages emits initial and updated messages', () async {
      const matchId = 'match_watch';
      final events = <List<Message>>[];
      final sub = repo.watchMessages(matchId).listen(events.add);
      addTearDown(sub.cancel);

      await _waitUntil(() => events.isNotEmpty);
      expect(events.first, isEmpty);

      await repo.sendMessage(
        matchId: matchId,
        fromUserId: 'u1',
        toUserId: 'u2',
        content: 'hello',
        type: MessageType.text,
      );

      await _waitUntil(() => events.any((e) => e.isNotEmpty));
      expect(events.last.single.content, 'hello');
    });

    test('fetchMessagesPaginated applies cursor and ordering', () async {
      const matchId = 'match_page';
      await repo.sendMessage(
        matchId: matchId,
        fromUserId: 'u1',
        toUserId: 'u2',
        content: 'first',
        type: MessageType.text,
      );
      await repo.sendMessage(
        matchId: matchId,
        fromUserId: 'u1',
        toUserId: 'u2',
        content: 'second',
        type: MessageType.text,
      );

      final all = await repo.fetchMessagesPaginated(matchId, limit: 10);
      expect(all.items.map((m) => m.content).toList(), <String>[
        'first',
        'second',
      ]);
      expect(all.hasMore, isFalse);

      final secondTimestamp = all.items.last.sentAt;
      final beforeSecond = await repo.fetchMessagesPaginated(
        matchId,
        limit: 10,
        beforeTimestamp: secondTimestamp,
      );
      expect(beforeSecond.items, hasLength(1));
      expect(beforeSecond.items.single.content, 'first');
    });

    test('watchNewMessages emits only messages sent after cursor', () async {
      const matchId = 'match_new_msgs';
      await repo.sendMessage(
        matchId: matchId,
        fromUserId: 'u1',
        toUserId: 'u2',
        content: 'old',
        type: MessageType.text,
      );
      final current = await repo.fetchMessagesPaginated(matchId, limit: 10);
      final afterTimestamp = current.items.single.sentAt;

      final completer = Completer<List<Message>>();
      final sub = repo
          .watchNewMessages(matchId, afterTimestamp: afterTimestamp)
          .listen((messages) {
            if (messages.isNotEmpty && !completer.isCompleted) {
              completer.complete(messages);
            }
          });

      await repo.sendMessage(
        matchId: matchId,
        fromUserId: 'u1',
        toUserId: 'u2',
        content: 'new',
        type: MessageType.text,
      );

      final emitted = await completer.future.timeout(
        const Duration(seconds: 2),
      );
      expect(emitted, hasLength(1));
      expect(emitted.single.content, 'new');
      await sub.cancel();
    });

    test(
      'sendMessage auto-reply path emits typing and reply deterministically',
      () async {
        repo.dispose();
        clock = _TestClock(DateTime(2026, 2, 15, 13));
        repo = StubChatRepository(
          delayExecutor: (_) async {},
          nowProvider: clock.next,
          shouldAutoReply: (_) => true,
        );

        const matchId = 'match_auto';
        final typingStates = <Set<String>>[];
        final typingSub = repo.watchTyping(matchId).listen((value) {
          typingStates.add(value);
        });
        addTearDown(typingSub.cancel);

        await repo.sendMessage(
          matchId: matchId,
          fromUserId: 'u1',
          toUserId: 'u2',
          content: 'hey',
          type: MessageType.text,
        );

        await _waitUntil(() async {
          final messages = await repo.fetchMessagesPaginated(
            matchId,
            limit: 10,
          );
          return messages.items.length >= 2;
        });

        final messages = await repo.fetchMessagesPaginated(matchId, limit: 10);
        expect(messages.items.any((m) => m.fromUserId == 'u2'), isTrue);
        expect(typingStates.any((s) => s.contains('u2')), isTrue);
        expect(typingStates.last, isEmpty);
      },
    );

    test(
      'markMessagesRead, reactions, edit and unsend update message state',
      () async {
        const matchId = 'match_update';
        await repo.sendMessage(
          matchId: matchId,
          fromUserId: 'u1',
          toUserId: 'u2',
          content: 'original',
          type: MessageType.text,
        );
        final firstFetch = await repo.fetchMessagesPaginated(
          matchId,
          limit: 10,
        );
        final messageId = firstFetch.items.single.id;

        await repo.markMessagesRead(matchId, 'u2');
        await repo.addReaction(
          matchId: matchId,
          messageId: messageId,
          userId: 'u2',
          emoji: '🔥',
        );
        await repo.editMessage(
          matchId: matchId,
          messageId: messageId,
          newContent: 'edited',
        );

        var updated = await repo.fetchMessagesPaginated(matchId, limit: 10);
        expect(updated.items.single.isRead, isTrue);
        expect(updated.items.single.content, 'edited');
        expect(updated.items.single.reactions['u2'], '🔥');

        await repo.removeReaction(
          matchId: matchId,
          messageId: messageId,
          userId: 'u2',
        );
        updated = await repo.fetchMessagesPaginated(matchId, limit: 10);
        expect(updated.items.single.reactions.containsKey('u2'), isFalse);

        await repo.unsendMessage(matchId: matchId, messageId: messageId);
        updated = await repo.fetchMessagesPaginated(matchId, limit: 10);
        expect(updated.items, isEmpty);
      },
    );

    test(
      'deleteForMe/report/appeal/uploadMedia persist expected side effects',
      () async {
        const matchId = 'match_side_effects';
        await repo.sendMessage(
          matchId: matchId,
          fromUserId: 'u1',
          toUserId: 'u2',
          content: 'to-delete',
          type: MessageType.text,
        );

        final messages = await repo.fetchMessagesPaginated(matchId, limit: 10);
        final messageId = messages.items.single.id;

        await repo.deleteForMe(
          matchId: matchId,
          messageId: messageId,
          userId: 'u1',
        );
        await repo.reportUser(
          reporterId: 'u1',
          reportedId: 'u2',
          reason: 'Spam',
          matchId: matchId,
          messageId: messageId,
          source: 'chat',
          description: 'bad content',
        );
        await repo.submitSafetyAppeal(
          userId: 'u2',
          reason: 'please review',
          targetType: 'report',
          targetId: messageId,
        );

        final mediaPath = await repo.uploadMedia(
          matchId: matchId,
          filePath: '/tmp/file.jpg',
          type: MessageType.image,
        );
        expect(mediaPath, '/tmp/file.jpg');

        final prefs = await SharedPreferences.getInstance();
        final deletedRaw = prefs.getString('mock_deleted_u1_$matchId');
        expect(deletedRaw, isNotNull);
        expect(Set<String>.from(jsonDecode(deletedRaw!)), contains(messageId));

        final reports = prefs.getStringList('mock_reports');
        expect(reports, isNotNull);
        final latestReport = jsonDecode(reports!.last) as Map<String, dynamic>;
        expect(latestReport['reporterId'], 'u1');
        expect(latestReport['description'], 'bad content');

        final appeals = prefs.getStringList('mock_appeals');
        expect(appeals, isNotNull);
        final latestAppeal = jsonDecode(appeals!.last) as Map<String, dynamic>;
        expect(latestAppeal['userId'], 'u2');
        expect(latestAppeal['targetType'], 'report');
      },
    );

    test(
      'presence and media-enabled streams emit defaults and updates',
      () async {
        final presence = <bool>[];
        final presenceSub = repo.watchPresence('u1').listen(presence.add);
        addTearDown(presenceSub.cancel);

        await _waitUntil(() => presence.isNotEmpty);
        expect(presence.first, isTrue);
        await repo.setPresence(userId: 'u1', isOnline: false);
        await _waitUntil(() => presence.length >= 2);
        expect(presence.last, isFalse);

        final media = <bool>[];
        final mediaSub = repo
            .watchMediaSendingEnabled('match_media')
            .listen(media.add);
        addTearDown(mediaSub.cancel);

        await _waitUntil(() => media.isNotEmpty);
        expect(media.first, isTrue);
        await repo.setMediaSendingEnabled(
          matchId: 'match_media',
          enabled: false,
          requesterId: 'u1',
        );
        await _waitUntil(() => media.length >= 2);
        expect(media.last, isFalse);
      },
    );

    test('block/unblock/unmatch and match pagination branches', () async {
      final prefs = await SharedPreferences.getInstance();

      await repo.unblockUser(blockerId: 'u1', blockedId: 'u2');

      await repo.blockUser(blockerId: 'u1', blockedId: 'u2');
      var blocked = Set<String>.from(
        jsonDecode(prefs.getString('mock_blocked_u1')!) as List<dynamic>,
      );
      expect(blocked, contains('u2'));

      await repo.unblockUser(blockerId: 'u1', blockedId: 'u2');
      blocked = Set<String>.from(
        jsonDecode(prefs.getString('mock_blocked_u1')!) as List<dynamic>,
      );
      expect(blocked.contains('u2'), isFalse);

      await prefs.setString(
        'mock_messages_match-1',
        jsonEncode(<dynamic>[
          <String, dynamic>{
            'id': 'm1',
            'matchId': 'match-1',
            'fromUserId': 'u1',
            'toUserId': 'u2',
            'content': 'seed',
            'type': 'text',
            'sentAt': DateTime.now().toIso8601String(),
          },
        ]),
      );

      await prefs.setString(
        'mock_matches_u1',
        jsonEncode(<dynamic>[
          <String, dynamic>{
            'id': 'match-1',
            'userId': 'u1',
            'otherUserId': 'u2',
            'status': 'invalid-status',
          },
          <String, dynamic>{
            'id': 'match-2',
            'userId': 'u1',
            'otherUserId': 'u3',
            'status': 'pending',
            'preMatchMessageRequestsCount': 2,
            'pinnedForUser': true,
            'otherUserName': 'Zoe',
            'otherUserPhotoUrl': 'https://cdn.example.com/z.jpg',
          },
        ]),
      );

      final matches = await repo.fetchUserMatches('u1');
      expect(matches, hasLength(2));
      expect(matches.first.status, MatchStatus.mutual);
      expect(matches.first.preMatchMessageRequestsCount, 0);
      expect(matches.first.pinnedForUser, isFalse);

      final paged = await repo.fetchUserMatchesPaginated(
        'u1',
        offset: 1,
        limit: 1,
      );
      expect(paged.items, hasLength(1));
      expect(paged.items.single.id, 'match-2');
      expect(paged.hasMore, isFalse);

      await repo.unmatch(matchId: 'match-1', userId: 'u1');
      final afterUnmatch = await repo.fetchUserMatches('u1');
      expect(afterUnmatch.map((m) => m.id), isNot(contains('match-1')));
      expect(prefs.getString('mock_messages_match-1'), isNull);
    });

    test(
      'message request pruning, dedupe, pending check and migration',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final now = clock.current;
        await prefs.setString(
          'mock_message_requests',
          jsonEncode(<dynamic>[
            <String, dynamic>{
              'id': 'expired',
              'fromUserId': 'u1',
              'toUserId': 'u2',
              'content': 'old',
              'type': 'text',
              'sentAt': now
                  .subtract(const Duration(hours: 72))
                  .toIso8601String(),
              'expiresAt': now
                  .subtract(const Duration(hours: 24))
                  .toIso8601String(),
            },
            <String, dynamic>{
              'id': 'active',
              'fromUserId': 'u1',
              'toUserId': 'u2',
              'content': 'hello',
              'type': 'text',
              'sentAt': now
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
              'expiresAt': now.add(const Duration(hours: 24)).toIso8601String(),
            },
          ]),
        );

        final visible = await repo.fetchMessageRequests('u1');
        expect(visible, hasLength(1));
        expect(visible.single.id, 'active');

        final pending = await repo.hasPendingMessageRequest(
          userId: 'u2',
          otherUserId: 'u1',
        );
        expect(pending, isTrue);

        final duplicate = await repo.sendMessageRequest(
          fromUserId: 'u2',
          toUserId: 'u1',
          content: 'duplicate',
          type: MessageType.text,
        );
        expect(duplicate, isNull);

        final migrated = await repo.migrateMessageRequestsForMatches(
          userId: 'u1',
          matches: const <CrushMatch>[
            CrushMatch(
              id: 'match_req',
              userId: 'u1',
              otherUserId: 'u2',
              status: MatchStatus.mutual,
              preMatchMessageRequestsCount: 0,
              pinnedForUser: false,
            ),
          ],
        );
        expect(migrated, 1);

        final remaining = await repo.fetchMessageRequests('u1');
        expect(remaining, isEmpty);
        final migratedMessages = await repo.fetchMessagesPaginated(
          'match_req',
          limit: 10,
        );
        expect(migratedMessages.items, hasLength(1));
        expect(migratedMessages.items.single.content, 'hello');
      },
    );

    test('e2ee stubs return no-op defaults', () async {
      expect(repo.isE2eeEnabled, isFalse);
      repo.setE2eeEnabled(true);
      expect(repo.isEncryptedContent('abc'), isFalse);

      final message = Message(
        id: 'm',
        matchId: 'match',
        fromUserId: 'u1',
        toUserId: 'u2',
        content: 'hello',
        type: MessageType.text,
        sentAt: DateTime(2026, 2, 1),
        isRead: false,
        isDeletedForSender: false,
        reactions: const <String, String>{},
      );
      final decrypted = await repo.decryptMessage(message);
      expect(decrypted, message);
    });
  });
}

class _TestClock {
  _TestClock(this._current);

  DateTime _current;

  DateTime get current => _current;

  DateTime next() {
    final now = _current;
    _current = _current.add(const Duration(milliseconds: 10));
    return now;
  }
}

Future<void> _waitUntil(
  FutureOr<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 2),
  Duration poll = const Duration(milliseconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    final result = await condition();
    if (result) {
      return;
    }
    await Future<void>.delayed(poll);
  }
  throw TimeoutException('Condition was not met within $timeout');
}
