import 'dart:io';

import 'package:crushhour/features/chat/data/services/voice_recorder_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const recordChannel = MethodChannel('com.llfbandit.record/messages');

  late Directory tempDir;
  late List<bool> permissionResponses;
  late List<bool?> permissionRequestFlags;
  String? lastRecordingPath;
  bool throwOnStart = false;
  bool throwOnStop = false;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('voice_recorder_test_');
    permissionResponses = <bool>[true];
    permissionRequestFlags = <bool?>[];
    lastRecordingPath = null;
    throwOnStart = false;
    throwOnStop = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, (call) async {
          switch (call.method) {
            case 'create':
              return null;
            case 'hasPermission':
              final args = call.arguments as Map<dynamic, dynamic>;
              permissionRequestFlags.add(args['request'] as bool?);
              if (permissionResponses.length > 1) {
                return permissionResponses.removeAt(0);
              }
              return permissionResponses.first;
            case 'start':
              if (throwOnStart) {
                throw PlatformException(code: 'start_failed');
              }
              final args = call.arguments as Map<dynamic, dynamic>;
              lastRecordingPath = args['path'] as String?;
              return null;
            case 'stop':
              if (throwOnStop) {
                throw PlatformException(code: 'stop_failed');
              }
              return lastRecordingPath;
            case 'dispose':
            case 'cancel':
            case 'pause':
            case 'resume':
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, null);
  });

  group('VoiceRecorderService', () {
    test('permission helpers map granted/denied correctly', () async {
      final service = VoiceRecorderService();
      addTearDown(service.dispose);

      permissionResponses = <bool>[false];
      expect(await service.hasPermission(), isFalse);

      permissionResponses = <bool>[true];
      expect(await service.requestPermission(), isTrue);

      permissionResponses = <bool>[false];
      expect(await service.requestPermission(), isFalse);
      expect(permissionRequestFlags, <bool?>[false, true, true]);
    });

    test('startRecording returns null when permission denied', () async {
      permissionResponses = <bool>[false];

      final service = VoiceRecorderService();
      addTearDown(service.dispose);

      final result = await service.startRecording();
      expect(result, isNull);
      expect(service.isRecording, isFalse);
      expect(await service.stopRecording(), isNull);
    });

    test('start/stop short recording deletes file and returns null', () async {
      final service = VoiceRecorderService();
      addTearDown(service.dispose);

      final filePath = await service.startRecording();
      expect(filePath, isNotNull);
      expect(service.isRecording, isTrue);

      final shortFile = File(filePath!);
      await shortFile.writeAsString('short');
      expect(await shortFile.exists(), isTrue);

      final stopResult = await service.stopRecording();
      expect(stopResult, isNull);
      expect(service.isRecording, isFalse);
      expect(await shortFile.exists(), isFalse);
    });

    test(
      'start/stop recording after min duration returns saved path',
      () async {
        final service = VoiceRecorderService();
        addTearDown(service.dispose);

        final filePath = await service.startRecording();
        expect(filePath, isNotNull);
        expect(service.currentDuration, isNot(Duration.zero));

        await Future<void>.delayed(const Duration(milliseconds: 1100));
        final stopResult = await service.stopRecording();
        expect(stopResult, filePath);
        expect(service.isRecording, isFalse);
        expect(service.currentDuration, Duration.zero);
      },
    );

    test('cancelRecording deletes file and resets recording state', () async {
      final service = VoiceRecorderService();
      addTearDown(service.dispose);

      final filePath = await service.startRecording();
      expect(filePath, isNotNull);

      final file = File(filePath!);
      await file.writeAsString('to-delete');
      expect(await file.exists(), isTrue);

      await service.cancelRecording();
      expect(service.isRecording, isFalse);
      expect(await file.exists(), isFalse);
    });

    test('duration stream emits while recording', () async {
      final service = VoiceRecorderService();
      addTearDown(service.dispose);

      await service.startRecording();
      final emitted = await service.durationStream
          .firstWhere((duration) => duration >= const Duration(milliseconds: 1))
          .timeout(const Duration(seconds: 2));
      expect(emitted, greaterThan(Duration.zero));

      await service.cancelRecording();
    });

    test('start and stop failures are handled safely', () async {
      final service = VoiceRecorderService();
      addTearDown(service.dispose);

      throwOnStart = true;
      final failedStart = await service.startRecording();
      expect(failedStart, isNull);
      expect(service.isRecording, isFalse);

      throwOnStart = false;
      final startedPath = await service.startRecording();
      expect(startedPath, isNotNull);
      expect(service.isRecording, isTrue);

      throwOnStop = true;
      final failedStop = await service.stopRecording();
      expect(failedStop, isNull);
      expect(service.isRecording, isFalse);
      expect(service.currentDuration, Duration.zero);
    });
  });
}
