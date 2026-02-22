import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/security/clipboard_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureClipboard', () {
    String? clipboardText;
    bool failSetData = false;

    setUp(() {
      clipboardText = null;
      failSetData = false;
      SecureClipboard.cancelTimer();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              if (failSetData) {
                throw PlatformException(
                  code: 'set_failed',
                  message: 'setData failed',
                );
              }
              final args = Map<dynamic, dynamic>.from(call.arguments as Map);
              clipboardText = args['text'] as String?;
              return null;
            }

            if (call.method == 'Clipboard.getData') {
              return <String, dynamic>{'text': clipboardText};
            }

            return null;
          });
    });

    tearDown(() {
      SecureClipboard.cancelTimer();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('copy stores clipboard text and returns true', () async {
      final copied = await SecureClipboard.copy('sensitive');

      expect(copied, isTrue);
      expect(clipboardText, 'sensitive');
    });

    test('copy returns false when Clipboard.setData throws', () async {
      failSetData = true;

      final copied = await SecureClipboard.copy('value');

      expect(copied, isFalse);
      expect(clipboardText, isNull);
    });

    test('clear writes an empty clipboard payload', () async {
      await SecureClipboard.copy('temporary');

      SecureClipboard.clear();

      expect(clipboardText, '');
    });

    test('auto-clear timer clears clipboard after configured delay', () {
      fakeAsync((async) {
        SecureClipboard.copy('otp');
        async.flushMicrotasks();
        expect(clipboardText, 'otp');

        async.elapse(SecureClipboard.clearDelay);
        async.flushTimers();
        async.flushMicrotasks();

        expect(clipboardText, '');
      });
    });

    test('cancelTimer prevents pending auto-clear from firing', () {
      fakeAsync((async) {
        SecureClipboard.copy('keep-me');
        async.flushMicrotasks();
        expect(clipboardText, 'keep-me');

        SecureClipboard.cancelTimer();
        async.elapse(SecureClipboard.clearDelay);
        async.flushTimers();
        async.flushMicrotasks();

        expect(clipboardText, 'keep-me');
      });
    });
  });
}
