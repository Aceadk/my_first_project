import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crushhour/features/chat/data/repositories/impl/firebase_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// REAL-001/REAL-002: presence must decay to offline when the heartbeat goes
/// stale, so a crashed/force-killed client (which never writes isOnline:false,
/// because the app has no RTDB onDisconnect handler) does not appear online
/// forever. These exercise the pure decision used by `watchPresence`.
void main() {
  final now = DateTime(2026, 6, 2, 12, 0, 0);

  Map<String, dynamic> presence({
    required bool isOnline,
    Duration? seenAgo,
  }) {
    return {
      'isOnline': isOnline,
      if (seenAgo != null)
        'lastSeen': Timestamp.fromDate(now.subtract(seenAgo)),
    };
  }

  group('FirebaseChatRepository.isPresenceOnline', () {
    test('online + fresh heartbeat -> online', () {
      expect(
        FirebaseChatRepository.isPresenceOnline(
          presence(isOnline: true, seenAgo: const Duration(seconds: 30)),
          now,
        ),
        isTrue,
      );
    });

    test('online flag but STALE heartbeat -> offline (the crash case)', () {
      // isOnline still true (never cleared on crash) but lastSeen is old.
      expect(
        FirebaseChatRepository.isPresenceOnline(
          presence(isOnline: true, seenAgo: const Duration(minutes: 5)),
          now,
        ),
        isFalse,
      );
    });

    test('online flag with no lastSeen -> offline', () {
      expect(
        FirebaseChatRepository.isPresenceOnline(
          presence(isOnline: true),
          now,
        ),
        isFalse,
      );
    });

    test('explicitly offline -> offline regardless of freshness', () {
      expect(
        FirebaseChatRepository.isPresenceOnline(
          presence(isOnline: false, seenAgo: const Duration(seconds: 1)),
          now,
        ),
        isFalse,
      );
    });

    test('null / empty document -> offline', () {
      expect(FirebaseChatRepository.isPresenceOnline(null, now), isFalse);
      expect(FirebaseChatRepository.isPresenceOnline(<String, dynamic>{}, now),
          isFalse);
    });

    test('boundary: just inside the freshness window -> online', () {
      final justInside =
          FirebaseChatRepository.presenceFreshnessWindow -
          const Duration(seconds: 1);
      expect(
        FirebaseChatRepository.isPresenceOnline(
          presence(isOnline: true, seenAgo: justInside),
          now,
        ),
        isTrue,
      );
    });

    test('boundary: just past the freshness window -> offline', () {
      final justPast =
          FirebaseChatRepository.presenceFreshnessWindow +
          const Duration(seconds: 1);
      expect(
        FirebaseChatRepository.isPresenceOnline(
          presence(isOnline: true, seenAgo: justPast),
          now,
        ),
        isFalse,
      );
    });
  });
}
