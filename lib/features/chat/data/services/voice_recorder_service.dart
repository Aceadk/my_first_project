import 'dart:async';
import 'dart:io';
import 'package:crushhour/core/app_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service for recording voice notes.
import 'package:crushhour/features/chat/domain/repositories/voice_recorder_repository.dart';

class VoiceRecorderService implements VoiceRecorderRepository {
  VoiceRecorderService();

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  final _durationController = StreamController<Duration>.broadcast();

  /// Stream of recording duration updates (every 100ms).
  @override
  Stream<Duration> get durationStream => _durationController.stream;

  /// Whether currently recording.
  @override
  bool get isRecording => _isRecording;

  /// Current recording duration.
  @override
  Duration get currentDuration {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Maximum recording duration (60 seconds).
  static const maxDuration = Duration(seconds: 60);

  /// Minimum recording duration to send (1 second).
  static const minDuration = Duration(seconds: 1);

  /// Request microphone permission.
  @override
  Future<bool> requestPermission() async {
    return _recorder.hasPermission();
  }

  /// Check if microphone permission is granted.
  @override
  Future<bool> hasPermission() async {
    return _recorder.hasPermission(request: false);
  }

  /// Start recording a voice note.
  /// Returns the file path where the recording will be saved.
  @override
  Future<String?> startRecording() async {
    if (_isRecording) return null;

    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) return null;
    }

    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/voice_note_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final duration = currentDuration;
        _durationController.add(duration);

        // Auto-stop at max duration
        if (duration >= maxDuration) {
          stopRecording();
        }
      });

      return filePath;
    } catch (e) {
      _isRecording = false;
      _recordingStartTime = null;
      return null;
    }
  }

  /// Stop recording and return the file path.
  /// Returns null if recording was too short or failed.
  @override
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _durationTimer?.cancel();
    _durationTimer = null;

    final duration = currentDuration;
    _isRecording = false;

    try {
      final path = await _recorder.stop();
      _recordingStartTime = null;

      // Check minimum duration
      if (duration < minDuration) {
        // Delete the file if too short
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        return null;
      }

      return path;
    } catch (e) {
      _recordingStartTime = null;
      return null;
    }
  }

  /// Cancel the current recording without saving.
  @override
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _durationTimer?.cancel();
    _durationTimer = null;
    _isRecording = false;

    try {
      final path = await _recorder.stop();
      _recordingStartTime = null;

      // Delete the file
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      AppLogger.error('VoiceRecorderService: Error canceling recording: $e');
      _recordingStartTime = null;
    }
  }

  /// Dispose resources.
  @override
  Future<void> dispose() async {
    await cancelRecording();
    await _durationController.close();
    _recorder.dispose();
  }
}
