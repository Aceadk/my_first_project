import 'dart:async';

abstract class VoiceRecorderRepository {
  Stream<Duration> get durationStream;
  bool get isRecording;
  Duration get currentDuration;

  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<String?> startRecording();
  Future<String?> stopRecording();
  Future<void> cancelRecording();
  Future<void> dispose();
}
