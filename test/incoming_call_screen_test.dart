import 'package:crushhour/features/calls/domain/models/call.dart';
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:crushhour/features/calls/data/services/call_service.dart';
import 'package:crushhour/features/calls/presentation/screens/incoming_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = CallService.instance;

  Future<void> resetService() async {
    if (service.hasActiveCall) {
      await service.endCall();
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));
    }
  }

  Call buildIncoming({CallType type = CallType.video}) {
    return Call(
      id: 'incoming-${type.name}',
      callerId: 'caller-1',
      receiverId: 'receiver-1',
      type: type,
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
      callerName: 'Taylor',
    );
  }

  setUp(() async {
    await resetService();
  });

  tearDown(() async {
    await resetService();
  });

  Future<void> pumpIncoming(
    WidgetTester tester, {
    required Call call,
    Duration? ringTimeout,
    Future<void> Function(Call call, CallType selectedType)? onAccepted,
    Future<void> Function(Call call)? onDeclined,
    Future<void> Function(Call call)? onTimedOut,
  }) async {
    await tester.pumpWidget(
      RepositoryProvider<CallManagerRepository>.value(
        value: service,
        child: MaterialApp(
          home: IncomingCallScreen(
            incomingCall: call,
            ringTimeout: ringTimeout ?? const Duration(minutes: 5),
            onAccepted: onAccepted,
            onDeclined: onDeclined,
            onTimedOut: onTimedOut,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('IncomingCallScreen', () {
    testWidgets('renders caller, timeout, and video accept options', (
      tester,
    ) async {
      await pumpIncoming(tester, call: buildIncoming(type: CallType.video));

      expect(find.byKey(const Key('incoming_caller_name')), findsOneWidget);
      expect(find.text('Taylor'), findsOneWidget);
      expect(find.byKey(const Key('incoming_timeout_text')), findsOneWidget);
      expect(find.byKey(const Key('incoming_decline_button')), findsOneWidget);
      expect(
        find.byKey(const Key('incoming_accept_audio_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('incoming_accept_video_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('incoming_slide_track')), findsOneWidget);
    });

    testWidgets('audio accept button accepts as audio', (tester) async {
      Call? acceptedCall;
      CallType? acceptedType;

      await pumpIncoming(
        tester,
        call: buildIncoming(type: CallType.video),
        onAccepted: (call, selectedType) async {
          acceptedCall = call;
          acceptedType = selectedType;
        },
      );

      await tester.tap(find.byKey(const Key('incoming_accept_audio_button')));
      await tester.pump(const Duration(milliseconds: 150));

      expect(acceptedType, CallType.audio);
      expect(acceptedCall, isNotNull);
      expect(acceptedCall!.status, CallStatus.ongoing);
      expect(acceptedCall!.type, CallType.audio);
    });

    testWidgets('slide-to-answer triggers default accept type', (tester) async {
      CallType? acceptedType;

      await pumpIncoming(
        tester,
        call: buildIncoming(type: CallType.video),
        onAccepted: (_, selectedType) async {
          acceptedType = selectedType;
        },
      );

      final knobFinder = find.byKey(const Key('incoming_slide_knob'));
      final trackFinder = find.byKey(const Key('incoming_slide_track'));
      final knobCenter = tester.getCenter(knobFinder);
      final trackRight = tester.getTopRight(trackFinder).dx - 12;
      final deltaX = trackRight - knobCenter.dx;

      final gesture = await tester.startGesture(knobCenter);
      await gesture.moveBy(Offset(deltaX, 0));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 350));

      expect(acceptedType, CallType.video);
    });

    testWidgets('auto timeout invokes callback', (tester) async {
      var timedOut = false;

      await pumpIncoming(
        tester,
        call: buildIncoming(type: CallType.audio),
        ringTimeout: const Duration(milliseconds: 120),
        onTimedOut: (_) async {
          timedOut = true;
        },
      );

      await tester.pump(const Duration(milliseconds: 160));

      expect(timedOut, isTrue);
    });
  });
}
