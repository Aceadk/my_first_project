import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/design_system/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('runs only the latest callback within delay window', () {
      fakeAsync((async) {
        var calls = 0;
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

        debouncer.run(() => calls++);
        debouncer.run(() => calls++);

        async.elapse(const Duration(milliseconds: 49));
        expect(calls, equals(0));

        async.elapse(const Duration(milliseconds: 1));
        expect(calls, equals(1));
      });
    });

    test('cancel and dispose prevent pending callback execution', () {
      fakeAsync((async) {
        var calls = 0;
        final debouncer = Debouncer(delay: const Duration(milliseconds: 30));

        debouncer.run(() => calls++);
        debouncer.cancel();
        async.elapse(const Duration(milliseconds: 30));
        expect(calls, equals(0));

        debouncer.run(() => calls++);
        debouncer.dispose();
        async.elapse(const Duration(milliseconds: 30));
        expect(calls, equals(0));
      });
    });
  });

  group('Throttler', () {
    test('runs immediately then throttles subsequent calls', () {
      fakeAsync((async) {
        var calls = 0;
        final throttler = Throttler(duration: const Duration(milliseconds: 60));

        throttler.run(() => calls++);
        throttler.run(() => calls++);
        expect(calls, equals(1));

        async.elapse(const Duration(milliseconds: 59));
        expect(calls, equals(1));

        async.elapse(const Duration(milliseconds: 1));
        expect(calls, equals(2));

        throttler.run(() => calls++);
        expect(calls, equals(2));
        async.elapse(const Duration(milliseconds: 60));
        expect(calls, equals(3));
      });
    });

    test('cancel and dispose clear scheduled throttle callback', () {
      fakeAsync((async) {
        var calls = 0;
        final throttler = Throttler(duration: const Duration(milliseconds: 40));

        throttler.run(() => calls++);
        throttler.run(() => calls++);
        throttler.cancel();
        async.elapse(const Duration(milliseconds: 40));
        expect(calls, equals(1));

        throttler.run(() => calls++);
        throttler.run(() => calls++);
        throttler.dispose();
        async.elapse(const Duration(milliseconds: 40));
        expect(calls, equals(1));
      });
    });
  });

  group('SearchDebouncer', () {
    test('debounces search and invokes empty callback when cleared', () {
      fakeAsync((async) {
        String? searched;
        var emptyCalls = 0;

        final debouncer = SearchDebouncer(
          delay: const Duration(milliseconds: 100),
          onSearch: (query) => searched = query,
          onEmpty: () => emptyCalls++,
        );

        debouncer.search('h');
        debouncer.search('hello');
        async.elapse(const Duration(milliseconds: 99));
        expect(searched, isNull);

        async.elapse(const Duration(milliseconds: 1));
        expect(searched, equals('hello'));

        debouncer.search('   ');
        expect(emptyCalls, equals(1));
      });
    });

    test('searchNow, cancel, reset and dispose work as expected', () {
      fakeAsync((async) {
        String? searched;
        var emptyCalls = 0;

        final debouncer = SearchDebouncer(
          delay: const Duration(milliseconds: 50),
          onSearch: (query) => searched = query,
          onEmpty: () => emptyCalls++,
        );

        debouncer.searchNow(' now ');
        expect(searched, equals('now'));

        debouncer.search('later');
        debouncer.cancel();
        async.elapse(const Duration(milliseconds: 50));
        expect(searched, equals('now'));

        debouncer.reset();
        debouncer.search('again');
        async.elapse(const Duration(milliseconds: 50));
        expect(searched, equals('again'));

        debouncer.searchNow('  ');
        expect(emptyCalls, equals(1));

        debouncer.search('disposed');
        debouncer.dispose();
        async.elapse(const Duration(milliseconds: 50));
        expect(searched, equals('again'));
      });
    });
  });
}
