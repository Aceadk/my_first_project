import 'package:crushhour/features/calls/data/services/callkit_service.dart';
import 'package:crushhour/features/calls/domain/repositories/callkit_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('crushhour/callkit');
  final service = CallKitService.instance;

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('showIncomingCall delegates to native channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
          calls.add(call);
          return true;
        });

    final result = await service.showIncomingCall(
      callId: 'call-1',
      callerId: 'user-a',
      callerName: 'Alex',
      isVideoCall: true,
    );

    expect(result, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'showIncomingCall');
    expect((calls.single.arguments as Map)['callId'], 'call-1');
    expect((calls.single.arguments as Map)['callerId'], 'user-a');
    expect((calls.single.arguments as Map)['isVideoCall'], true);
    expect((calls.single.arguments as Map)['callType'], 'video');
  });

  test('endCall returns false when native channel throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (_) async {
          throw PlatformException(code: 'native-error');
        });

    final result = await service.endCall(callId: 'call-2');

    expect(result, isFalse);
  });

  test('parseEventForTest parses answered payload', () {
    final event = CallKitService.parseEventForTest({
      'type': 'answered',
      'callId': 'call-3',
      'payload': {'callerId': 'user-x'},
    });

    expect(event.type, CallKitEventType.answered);
    expect(event.callId, 'call-3');
    expect(event.payload['callerId'], 'user-x');
  });

  test('parseEventForTest parses muted_changed boolean variants', () {
    final event = CallKitService.parseEventForTest({
      'type': 'muted_changed',
      'callId': 'call-4',
      'isMuted': 'true',
    });

    expect(event.type, CallKitEventType.mutedChanged);
    expect(event.isMuted, isTrue);
  });
}
