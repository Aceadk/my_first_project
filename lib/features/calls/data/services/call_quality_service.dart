import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

typedef CallMetricsProvider = Future<CallQualityMetrics> Function();

/// Connection quality buckets used by call UI and adaptive behavior.
enum CallQualityLevel { hd, sd, poor }

/// Effective video tier after adaptive degradation/recovery.
enum VideoQualityTier { hd720, sd480, audioOnly }

/// Raw call quality metrics sampled from the active call session.
class CallQualityMetrics {
  CallQualityMetrics({
    required this.latencyMs,
    required this.packetLossPercent,
    required this.bitrateKbps,
    required this.frameRate,
    DateTime? sampledAt,
  }) : sampledAt = sampledAt ?? DateTime.now();

  final int latencyMs;
  final double packetLossPercent;
  final int bitrateKbps;
  final double frameRate;
  final DateTime sampledAt;
}

/// Derived quality state consumed by the UI layer.
class CallQualityState {
  const CallQualityState({
    required this.metrics,
    required this.quality,
    required this.videoQuality,
    required this.isVideoCall,
    required this.shouldAttemptReconnect,
  });

  final CallQualityMetrics metrics;
  final CallQualityLevel quality;
  final VideoQualityTier videoQuality;
  final bool isVideoCall;
  final bool shouldAttemptReconnect;

  String get badgeLabel {
    if (!isVideoCall) {
      return quality == CallQualityLevel.poor ? 'Poor' : 'Voice';
    }
    switch (videoQuality) {
      case VideoQualityTier.hd720:
        return 'HD';
      case VideoQualityTier.sd480:
        return 'SD';
      case VideoQualityTier.audioOnly:
        return 'Audio';
    }
  }
}

/// Samples call quality and emits adaptive connection state.
class CallQualityService {
  CallQualityService({CallMetricsProvider? metricsProvider})
    : _metricsProvider = metricsProvider;

  static final CallQualityService instance = CallQualityService();

  final _random = Random();
  final _metricsController = StreamController<CallQualityMetrics>.broadcast();
  final _qualityStateController =
      StreamController<CallQualityState>.broadcast();

  CallMetricsProvider? _metricsProvider;
  Timer? _sampleTimer;
  bool _isMonitoring = false;
  bool _isSampling = false;
  bool _isVideoCall = false;

  int _poorStreak = 0;
  int _sdStreak = 0;
  int _hdStreak = 0;
  VideoQualityTier _videoQuality = VideoQualityTier.hd720;

  Stream<CallQualityMetrics> get metricsStream => _metricsController.stream;
  Stream<CallQualityState> get qualityStateStream =>
      _qualityStateController.stream;
  bool get isMonitoring => _isMonitoring;

  void startMonitoring({
    required bool isVideoCall,
    Duration sampleInterval = const Duration(seconds: 2),
    CallMetricsProvider? metricsProvider,
  }) {
    stopMonitoring();
    _isVideoCall = isVideoCall;
    if (metricsProvider != null) {
      _metricsProvider = metricsProvider;
    }
    _isMonitoring = true;
    _resetAdaptiveState();

    unawaited(_sampleOnce());
    _sampleTimer = Timer.periodic(sampleInterval, (_) {
      unawaited(_sampleOnce());
    });
  }

  void stopMonitoring() {
    _sampleTimer?.cancel();
    _sampleTimer = null;
    _isMonitoring = false;
    _isSampling = false;
    _resetAdaptiveState();
  }

  Future<void> _sampleOnce() async {
    if (!_isMonitoring || _isSampling) return;
    _isSampling = true;
    try {
      final metrics = _metricsProvider != null
          ? await _metricsProvider!.call()
          : _generateSample();
      _emit(metrics);
    } finally {
      _isSampling = false;
    }
  }

  CallQualityMetrics _generateSample() {
    if (_isVideoCall) {
      return CallQualityMetrics(
        latencyMs: 70 + _random.nextInt(220),
        packetLossPercent: _random.nextDouble() * 7.0,
        bitrateKbps: 550 + _random.nextInt(1000),
        frameRate: 18 + _random.nextDouble() * 14,
      );
    }

    return CallQualityMetrics(
      latencyMs: 60 + _random.nextInt(180),
      packetLossPercent: _random.nextDouble() * 5.0,
      bitrateKbps: 48 + _random.nextInt(128),
      frameRate: 0,
    );
  }

  CallQualityState _emit(CallQualityMetrics metrics) {
    final quality = _classify(metrics, isVideoCall: _isVideoCall);
    _applyAdaptiveRules(quality);

    final shouldAttemptReconnect =
        quality == CallQualityLevel.poor &&
        (metrics.latencyMs >= 1200 || metrics.packetLossPercent >= 25);

    final state = CallQualityState(
      metrics: metrics,
      quality: quality,
      videoQuality: _isVideoCall ? _videoQuality : VideoQualityTier.audioOnly,
      isVideoCall: _isVideoCall,
      shouldAttemptReconnect: shouldAttemptReconnect,
    );

    _metricsController.add(metrics);
    _qualityStateController.add(state);
    return state;
  }

  static CallQualityLevel _classify(
    CallQualityMetrics metrics, {
    required bool isVideoCall,
  }) {
    if (!isVideoCall) {
      final poor =
          metrics.latencyMs >= 450 ||
          metrics.packetLossPercent >= 12 ||
          metrics.bitrateKbps < 40;
      if (poor) return CallQualityLevel.poor;

      final sd =
          metrics.latencyMs >= 220 ||
          metrics.packetLossPercent >= 5 ||
          metrics.bitrateKbps < 72;
      if (sd) return CallQualityLevel.sd;

      return CallQualityLevel.hd;
    }

    final poor =
        metrics.latencyMs >= 350 ||
        metrics.packetLossPercent >= 8 ||
        metrics.bitrateKbps < 250 ||
        (isVideoCall && metrics.frameRate < 12);
    if (poor) return CallQualityLevel.poor;

    final sd =
        metrics.latencyMs >= 180 ||
        metrics.packetLossPercent >= 3 ||
        metrics.bitrateKbps < 700 ||
        (isVideoCall && metrics.frameRate < 20);
    if (sd) return CallQualityLevel.sd;

    return CallQualityLevel.hd;
  }

  void _applyAdaptiveRules(CallQualityLevel quality) {
    switch (quality) {
      case CallQualityLevel.poor:
        _poorStreak++;
        _sdStreak = 0;
        _hdStreak = 0;
        if (_isVideoCall) {
          if (_videoQuality == VideoQualityTier.hd720) {
            _videoQuality = VideoQualityTier.sd480;
          } else if (_videoQuality == VideoQualityTier.sd480 &&
              _poorStreak >= 2) {
            _videoQuality = VideoQualityTier.audioOnly;
          }
        }
        break;
      case CallQualityLevel.sd:
        _sdStreak++;
        _poorStreak = 0;
        _hdStreak = 0;
        if (_isVideoCall &&
            _videoQuality == VideoQualityTier.hd720 &&
            _sdStreak >= 2) {
          _videoQuality = VideoQualityTier.sd480;
        }
        break;
      case CallQualityLevel.hd:
        _hdStreak++;
        _poorStreak = 0;
        _sdStreak = 0;
        if (_isVideoCall) {
          if (_videoQuality == VideoQualityTier.audioOnly && _hdStreak >= 3) {
            _videoQuality = VideoQualityTier.sd480;
          } else if (_videoQuality == VideoQualityTier.sd480 &&
              _hdStreak >= 4) {
            _videoQuality = VideoQualityTier.hd720;
          }
        }
        break;
    }
  }

  void _resetAdaptiveState() {
    _poorStreak = 0;
    _sdStreak = 0;
    _hdStreak = 0;
    _videoQuality = _isVideoCall
        ? VideoQualityTier.hd720
        : VideoQualityTier.audioOnly;
  }

  @visibleForTesting
  void resetForTest({required bool isVideoCall}) {
    stopMonitoring();
    _isVideoCall = isVideoCall;
    _resetAdaptiveState();
  }

  @visibleForTesting
  CallQualityState evaluateForTest(CallQualityMetrics metrics) {
    return _emit(metrics);
  }
}
