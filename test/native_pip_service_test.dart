import 'package:crushhour/features/calls/data/services/native_pip_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('crushhour/native_pip');
  final service = NativePiPService.instance;

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('enterPictureInPicture returns true when native channel succeeds', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });

    final result = await service.enterPictureInPicture();

    expect(result, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'enterPictureInPicture');
  });

  test('enterPictureInPicture returns false when native channel throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'native-error');
    });

    final result = await service.enterPictureInPicture();

    expect(result, isFalse);
  });
}
