import 'package:crushhour/features/discovery/domain/repositories/realtime_match_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RealtimeMatchNotification.fromRtdb', () {
    test('maps full payload values', () {
      final notification = RealtimeMatchNotification.fromRtdb('match_1', {
        'otherUserId': 'user_2',
        'otherUserName': 'Alex',
        'otherUserPhotoUrl': 'https://example.com/photo.jpg',
        'createdAt': 123456789,
      });

      expect(notification.matchId, 'match_1');
      expect(notification.otherUserId, 'user_2');
      expect(notification.otherUserName, 'Alex');
      expect(notification.otherUserPhotoUrl, 'https://example.com/photo.jpg');
      expect(notification.createdAt, 123456789);
    });

    test('uses safe defaults when fields are missing', () {
      final notification = RealtimeMatchNotification.fromRtdb('match_2', {});

      expect(notification.matchId, 'match_2');
      expect(notification.otherUserId, '');
      expect(notification.otherUserName, 'Someone');
      expect(notification.otherUserPhotoUrl, isNull);
      expect(notification.createdAt, 0);
    });

    test('coerces mixed payload types without throwing', () {
      final notification = RealtimeMatchNotification.fromRtdb('match_3', {
        'otherUserId': 42,
        'otherUserName': true,
        'otherUserPhotoUrl': 98765,
        'createdAt': '1234567890',
      });

      expect(notification.matchId, 'match_3');
      expect(notification.otherUserId, '42');
      expect(notification.otherUserName, 'true');
      expect(notification.otherUserPhotoUrl, '98765');
      expect(notification.createdAt, 1234567890);
    });

    test('falls back safely for blank strings and invalid timestamp', () {
      final notification = RealtimeMatchNotification.fromRtdb('match_4', {
        'otherUserId': '   ',
        'otherUserName': '',
        'otherUserPhotoUrl': '   ',
        'createdAt': 'not-a-number',
      });

      expect(notification.matchId, 'match_4');
      expect(notification.otherUserId, '');
      expect(notification.otherUserName, 'Someone');
      expect(notification.otherUserPhotoUrl, isNull);
      expect(notification.createdAt, 0);
    });
  });
}
