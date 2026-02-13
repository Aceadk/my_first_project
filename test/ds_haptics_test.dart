import 'package:crushhour/design_system/utils/haptics.dart';
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

  group('DsHaptics', () {
    test('invokes single feedback methods', () async {
      await DsHaptics.light();
      await DsHaptics.medium();
      await DsHaptics.heavy();
      await DsHaptics.selection();
      await DsHaptics.vibrate();
      await DsHaptics.like();
      await DsHaptics.swipe();

      expect(calls.length, 7);
      expect(calls.every((c) => c.method == 'HapticFeedback.vibrate'), isTrue);

      final args = calls.map((c) => c.arguments).toList();
      expect(args, contains('HapticFeedbackType.lightImpact'));
      expect(args, contains('HapticFeedbackType.mediumImpact'));
      expect(args, contains('HapticFeedbackType.heavyImpact'));
      expect(args, contains('HapticFeedbackType.selectionClick'));
      expect(args, contains(null));
    });

    test('success pattern emits light then medium impact', () async {
      await DsHaptics.success();

      expect(calls.length, 2);
      expect(calls[0].arguments, 'HapticFeedbackType.lightImpact');
      expect(calls[1].arguments, 'HapticFeedbackType.mediumImpact');
    });

    test('error pattern emits heavy impact twice', () async {
      await DsHaptics.error();

      expect(calls.length, 2);
      expect(calls[0].arguments, 'HapticFeedbackType.heavyImpact');
      expect(calls[1].arguments, 'HapticFeedbackType.heavyImpact');
    });

    test('super like pattern emits heavy then light impact', () async {
      await DsHaptics.superLike();

      expect(calls.length, 2);
      expect(calls[0].arguments, 'HapticFeedbackType.heavyImpact');
      expect(calls[1].arguments, 'HapticFeedbackType.lightImpact');
    });

    test('match pattern emits heavy, medium, then light impact', () async {
      await DsHaptics.match();

      expect(calls.length, 3);
      expect(calls[0].arguments, 'HapticFeedbackType.heavyImpact');
      expect(calls[1].arguments, 'HapticFeedbackType.mediumImpact');
      expect(calls[2].arguments, 'HapticFeedbackType.lightImpact');
    });
  });
}
