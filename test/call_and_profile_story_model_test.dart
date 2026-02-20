import 'package:crushhour/data/models/profile_story.dart';
import 'package:crushhour/features/calls/domain/models/call.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Call model', () {
    final now = DateTime(2026, 2, 12, 10, 30);

    test('computed properties and display formatting', () {
      final call = Call(
        id: 'c1',
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.video,
        status: CallStatus.ongoing,
        createdAt: now,
        duration: 125,
      );

      expect(call.isActive, isTrue);
      expect(call.isVideo, isTrue);
      expect(call.durationDisplay, '2:05');
      expect(Call.maxFreeDuration, const Duration(minutes: 30));
      expect(Call.ringTimeout, const Duration(seconds: 30));
    });

    test('copyWith and JSON round-trip preserve values', () {
      final call = Call(
        id: 'c2',
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.audio,
        status: CallStatus.ringing,
        createdAt: now,
      );

      final updated = call.copyWith(
        status: CallStatus.ended,
        duration: 31,
        endReason: CallEndReason.completed,
      );
      expect(updated.status, CallStatus.ended);
      expect(updated.durationDisplay, '0:31');
      expect(updated.endReason, CallEndReason.completed);

      final fromJson = Call.fromJson(updated.toJson());
      expect(fromJson, updated);
    });

    test('fromJson uses fallback values for unknown enum names', () {
      final parsed = Call.fromJson({
        'id': 'c3',
        'callerId': 'u1',
        'receiverId': 'u2',
        'type': 'unknown_type',
        'status': 'unknown_status',
        'createdAt': now.toIso8601String(),
        'endReason': 'unknown_reason',
      });

      expect(parsed.type, CallType.audio);
      expect(parsed.status, CallStatus.ended);
      expect(parsed.endReason, CallEndReason.unknown);
    });

    test('CallEndReasonExtension returns user-facing labels', () {
      expect(CallEndReason.completed.displayText, 'Call ended');
      expect(CallEndReason.missed.displayText, 'Missed call');
      expect(CallEndReason.declined.displayText, 'Call declined');
      expect(CallEndReason.busy.displayText, 'User busy');
      expect(CallEndReason.noAnswer.displayText, 'No answer');
      expect(CallEndReason.networkError.displayText, 'Connection lost');
      expect(CallEndReason.timeout.displayText, 'Call timed out');
      expect(CallEndReason.userHangup.displayText, 'Call ended');
      expect(CallEndReason.unknown.displayText, 'Call ended');
    });
  });

  group('ProfileStory model', () {
    final now = DateTime.now();

    ProfileStory buildStory({
      required String id,
      required StoryMediaType type,
      DateTime? createdAt,
      DateTime? expiresAt,
      int viewCount = 0,
    }) {
      return ProfileStory(
        id: id,
        userId: 'u1',
        mediaUrl: 'https://example.com/$id.jpg',
        mediaType: type,
        createdAt: createdAt ?? now,
        expiresAt: expiresAt,
        viewCount: viewCount,
      );
    }

    test('expiration and media helpers work as expected', () {
      final active = buildStory(
        id: 's1',
        type: StoryMediaType.photo,
        createdAt: now.subtract(const Duration(hours: 1)),
      );
      final expired = buildStory(
        id: 's2',
        type: StoryMediaType.video,
        createdAt: now.subtract(const Duration(days: 2)),
      );

      expect(active.isActive, isTrue);
      expect(active.isExpired, isFalse);
      expect(active.isPhoto, isTrue);
      expect(active.isVideo, isFalse);

      expect(expired.isExpired, isTrue);
      expect(expired.isActive, isFalse);
      expect(expired.remainingTime, Duration.zero);
      expect(expired.remainingTimeDisplay, 'Expired');
    });

    test('remainingTimeDisplay renders hours/minutes edge cases', () {
      final withHours = buildStory(
        id: 's3',
        type: StoryMediaType.photo,
        createdAt: now.subtract(const Duration(hours: 22, minutes: 10)),
      );
      final withMinutes = buildStory(
        id: 's4',
        type: StoryMediaType.photo,
        createdAt: now.subtract(const Duration(hours: 23, minutes: 40)),
      );
      final lessThanMinute = buildStory(
        id: 's5',
        type: StoryMediaType.photo,
        expiresAt: now.add(const Duration(seconds: 30)),
      );

      expect(withHours.remainingTimeDisplay, contains('h'));
      expect(withMinutes.remainingTimeDisplay, contains('m left'));
      expect(lessThanMinute.remainingTimeDisplay, 'Less than 1m left');
    });

    test('copyWith, toJson, and fromJson preserve structure', () {
      final story = buildStory(
        id: 's6',
        type: StoryMediaType.video,
        viewCount: 4,
      );
      final updated = story.copyWith(viewCount: 7, thumbnailUrl: 'thumb.jpg');
      final parsed = ProfileStory.fromJson(updated.toJson());

      expect(updated.viewCount, 7);
      expect(updated.thumbnailUrl, 'thumb.jpg');
      expect(parsed, updated);
    });

    test('fromJson falls back to photo for unknown media type', () {
      final parsed = ProfileStory.fromJson({
        'id': 's7',
        'userId': 'u1',
        'mediaUrl': 'https://example.com/s7',
        'mediaType': 'unsupported',
        'createdAt': now.toIso8601String(),
      });

      expect(parsed.mediaType, StoryMediaType.photo);
    });

    test('list extension filters active/media and finds mostRecent', () {
      final oldActive = buildStory(
        id: 'old',
        type: StoryMediaType.photo,
        createdAt: now.subtract(const Duration(hours: 2)),
      );
      final recentActive = buildStory(
        id: 'new',
        type: StoryMediaType.video,
        createdAt: now.subtract(const Duration(minutes: 10)),
      );
      final expired = buildStory(
        id: 'expired',
        type: StoryMediaType.video,
        createdAt: now.subtract(const Duration(days: 2)),
      );

      final stories = [oldActive, recentActive, expired];

      expect(stories.active.length, 2);
      expect(stories.videos.length, 2);
      expect(stories.photos.length, 1);
      expect(stories.mostRecent?.id, 'new');
      expect(<ProfileStory>[].mostRecent, isNull);
    });
  });
}
