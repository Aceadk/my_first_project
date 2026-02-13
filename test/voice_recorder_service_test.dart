import 'dart:io';

import 'package:crushhour/features/chat/data/services/voice_recorder_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const permissionChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const recordChannel = MethodChannel('com.llfbandit.record/messages');

  late Directory tempDir;
  late int permissionStatus;
  late int requestStatus;
  String? lastRecordingPath;
  bool throwOnStart = false;
  bool throwOnStop = false;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('voice_recorder_test_');
    permissionStatus = 1; // granted
    requestStatus = 1; // granted
    lastRecordingPath = null;
    throwOnStart = false;
    throwOnStop = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
              return permissionStatus;
            case 'requestPermissions':
              final requested = (call.arguments as List<dynamic>).cast<int>();
              return <int, int>{
                for (final permission in requested) permission: requestStatus,
              };
            default:
              return null;
          }
        });

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
        .setMockMethodCallHandler(permissionChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, null);
  });

  group('VoiceRecorderService', () {
    test('permission helpers map granted/denied correctly', () async {
      final service = VoiceRecorderService();
      addTearDown(service.dispose);

      permissionStatus = 0;
      expect(await service.hasPermission(), isFalse);

      requestStatus = 1;
      expect(await service.requestPermission(), isTrue);

      requestStatus = 0;
      expect(await service.requestPermission(), isFalse);
    });

    test('startRecording returns null when permission denied', () async {
      permissionStatus = 0;
      requestStatus = 0;

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
