import 'package:crushhour/features/calls/data/services/call_quality_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallQualityService', () {
    late CallQualityService service;

    setUp(() {
      service = CallQualityService();
      service.resetForTest(isVideoCall: true);
    });

    test('classifies healthy metrics as HD', () {
      final state = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 90,
          packetLossPercent: 1.2,
          bitrateKbps: 1400,
          frameRate: 28,
        ),
      );

      expect(state.quality, CallQualityLevel.hd);
      expect(state.videoQuality, VideoQualityTier.hd720);
      expect(state.badgeLabel, 'HD');
      expect(state.shouldAttemptReconnect, isFalse);
    });

    test('degrades video tier to SD then Audio on sustained poor quality', () {
      final firstPoor = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 420,
          packetLossPercent: 10.0,
          bitrateKbps: 220,
          frameRate: 10,
        ),
      );
      final secondPoor = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 450,
          packetLossPercent: 12.0,
          bitrateKbps: 180,
          frameRate: 9,
        ),
      );

      expect(firstPoor.quality, CallQualityLevel.poor);
      expect(firstPoor.videoQuality, VideoQualityTier.sd480);
      expect(secondPoor.videoQuality, VideoQualityTier.audioOnly);
      expect(secondPoor.badgeLabel, 'Audio');
    });

    test('recovers video tier from Audio to HD after stable samples', () {
      service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 430,
          packetLossPercent: 11.0,
          bitrateKbps: 210,
          frameRate: 10,
        ),
      );
      service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 440,
          packetLossPercent: 12.0,
          bitrateKbps: 190,
          frameRate: 9,
        ),
      );

      CallQualityState state = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 80,
          packetLossPercent: 0.5,
          bitrateKbps: 1500,
          frameRate: 29,
        ),
      );
      state = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 85,
          packetLossPercent: 0.8,
          bitrateKbps: 1600,
          frameRate: 30,
        ),
      );
      state = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 90,
          packetLossPercent: 0.9,
          bitrateKbps: 1700,
          frameRate: 30,
        ),
      );

      expect(state.videoQuality, VideoQualityTier.sd480);

      state = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 95,
          packetLossPercent: 0.7,
          bitrateKbps: 1650,
          frameRate: 30,
        ),
      );

      expect(state.videoQuality, VideoQualityTier.hd720);
      expect(state.badgeLabel, 'HD');
    });

    test('flags reconnect when quality is severely degraded', () {
      final state = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 1400,
          packetLossPercent: 28.0,
          bitrateKbps: 120,
          frameRate: 8,
        ),
      );

      expect(state.quality, CallQualityLevel.poor);
      expect(state.shouldAttemptReconnect, isTrue);
    });

    test('audio calls always use audio tier and voice badge', () {
      service.resetForTest(isVideoCall: false);

      final healthy = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 110,
          packetLossPercent: 1.0,
          bitrateKbps: 96,
          frameRate: 0,
        ),
      );

      expect(healthy.videoQuality, VideoQualityTier.audioOnly);
      expect(healthy.badgeLabel, 'Voice');

      final poor = service.evaluateForTest(
        CallQualityMetrics(
          latencyMs: 420,
          packetLossPercent: 12.0,
          bitrateKbps: 30,
          frameRate: 0,
        ),
      );

      expect(poor.videoQuality, VideoQualityTier.audioOnly);
      expect(poor.badgeLabel, 'Poor');
    });
  });
}
