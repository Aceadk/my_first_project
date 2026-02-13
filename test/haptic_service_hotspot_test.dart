import 'package:crushhour/core/services/haptic_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('HapticService', () {
    test('single feedback methods invoke platform haptics', () async {
      await HapticService.lightTap();
      await HapticService.selection();
      await HapticService.mediumTap();
      await HapticService.navTap();
      await HapticService.heavyTap();
      await HapticService.swipeStart();
      await HapticService.swipeThreshold();
      await HapticService.like();
      await HapticService.nope();
      await HapticService.rewind();
      await HapticService.messageSent();
      await HapticService.messageReceived();
      await HapticService.messageLongPress();
      await HapticService.photoNavigation();
      await HapticService.photoZoom();
      await HapticService.refreshThreshold();
      await HapticService.refreshComplete();

      expect(calls.length, 17);
      expect(calls.every((c) => c.method == 'HapticFeedback.vibrate'), isTrue);
      final args = calls.map((c) => c.arguments).toList();
      expect(args, contains('HapticFeedbackType.lightImpact'));
      expect(args, contains('HapticFeedbackType.mediumImpact'));
      expect(args, contains('HapticFeedbackType.heavyImpact'));
      expect(args, contains('HapticFeedbackType.selectionClick'));
    });

    test('superLike emits heavy then medium impact', () async {
      await HapticService.superLike();
      expect(calls.length, 2);
      expect(calls[0].arguments, 'HapticFeedbackType.heavyImpact');
      expect(calls[1].arguments, 'HapticFeedbackType.mediumImpact');
    });

    test('matchCelebration emits heavy, medium, heavy, light', () async {
      await HapticService.matchCelebration();
      expect(calls.length, 4);
      expect(calls.map((c) => c.arguments).toList(), <Object?>[
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.lightImpact',
      ]);
    });

    test('success/error/warning patterns emit expected sequences', () async {
      await HapticService.success();
      expect(calls.map((c) => c.arguments).toList(), <Object?>[
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.lightImpact',
      ]);

      calls.clear();
      await HapticService.error();
      expect(calls.map((c) => c.arguments).toList(), <Object?>[
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.heavyImpact',
      ]);

      calls.clear();
      await HapticService.warning();
      expect(calls.map((c) => c.arguments).toList(), <Object?>[
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
    });
  });
}
