import 'package:crushhour/core/services/screen_capture_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenCaptureService', () {
    test('parses screenshot event payload', () {
      final event = ScreenCaptureService.instance.parseForTest({
        'type': 'screenshot',
        'timestampMs': 1000,
      });

      expect(event.type, ScreenCaptureEventType.screenshot);
      expect(event.timestamp, DateTime.fromMillisecondsSinceEpoch(1000));
    });

    test('parses recording events payload', () {
      final started = ScreenCaptureService.instance.parseForTest({
        'type': 'recording_started',
      });
      final stopped = ScreenCaptureService.instance.parseForTest({
        'type': 'recording_stopped',
      });

      expect(started.type, ScreenCaptureEventType.recordingStarted);
      expect(stopped.type, ScreenCaptureEventType.recordingStopped);
    });

    test('returns unknown for malformed payload', () {
      final malformed = ScreenCaptureService.instance.parseForTest(
        'bad_payload',
      );
      final unknownType = ScreenCaptureService.instance.parseForTest({
        'type': 'other',
      });

      expect(malformed.type, ScreenCaptureEventType.unknown);
      expect(unknownType.type, ScreenCaptureEventType.unknown);
    });
  });
}
