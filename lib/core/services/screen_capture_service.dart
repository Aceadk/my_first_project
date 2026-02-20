import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ScreenCaptureEventType {
  screenshot,
  recordingStarted,
  recordingStopped,
  unknown,
}

class ScreenCaptureEvent {
  const ScreenCaptureEvent({required this.type, this.timestamp});

  final ScreenCaptureEventType type;
  final DateTime? timestamp;
}

/// Streams screenshot and screen-recording events from native platforms.
class ScreenCaptureService {
  ScreenCaptureService._();

  static final ScreenCaptureService instance = ScreenCaptureService._();

  static const EventChannel _channel = EventChannel(
    'crushhour/screen_capture_events',
  );

  Stream<ScreenCaptureEvent>? _events;

  Stream<ScreenCaptureEvent> get events {
    _events ??= _channel
        .receiveBroadcastStream()
        .map(_parseEvent)
        .where((event) => event.type != ScreenCaptureEventType.unknown);
    return _events!;
  }

  @visibleForTesting
  ScreenCaptureEvent parseForTest(dynamic raw) => _parseEvent(raw);

  ScreenCaptureEvent _parseEvent(dynamic raw) {
    if (raw is! Map) {
      return const ScreenCaptureEvent(type: ScreenCaptureEventType.unknown);
    }

    final map = Map<String, dynamic>.from(raw);
    final typeRaw = map['type'] as String?;
    final tsRaw = map['timestampMs'];

    final timestamp = tsRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(tsRaw)
        : null;

    final type = switch (typeRaw) {
      'screenshot' => ScreenCaptureEventType.screenshot,
      'recording_started' => ScreenCaptureEventType.recordingStarted,
      'recording_stopped' => ScreenCaptureEventType.recordingStopped,
      _ => ScreenCaptureEventType.unknown,
    };

    return ScreenCaptureEvent(type: type, timestamp: timestamp);
  }
}
