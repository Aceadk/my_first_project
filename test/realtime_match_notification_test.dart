import 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';
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
  });
}
