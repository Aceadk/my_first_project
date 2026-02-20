import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crushhour/core/connectivity/connectivity_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [InternetAddress] for testing.
class _FakeInternetAddress implements InternetAddress {
  _FakeInternetAddress(List<int> bytes)
      : rawAddress = Uint8List.fromList(bytes);

  @override
  final Uint8List rawAddress;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Allow stream events to be delivered.
Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  group('ConnectivityCubit', () {
    test('initial state is unknown', () {
      final cubit = ConnectivityCubit(
        dnsLookup: (_) async => [_FakeInternetAddress([1, 2, 3, 4])],
      );
      expect(cubit.state, ConnectivityStatus.unknown);
      cubit.close();
    });

    test('checkNow emits online when lookup succeeds', () async {
      final cubit = ConnectivityCubit(
        dnsLookup: (_) async => [_FakeInternetAddress([1, 2, 3, 4])],
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();

      expect(states, [ConnectivityStatus.online]);

      await sub.cancel();
      await cubit.close();
    });

    test('checkNow emits offline on SocketException', () async {
      final cubit = ConnectivityCubit(
        dnsLookup: (_) => throw const SocketException('no network'),
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();

      expect(states, [ConnectivityStatus.offline]);

      await sub.cancel();
      await cubit.close();
    });

    test('checkNow emits offline on TimeoutException', () async {
      final cubit = ConnectivityCubit(
        dnsLookup: (_) => throw TimeoutException('timed out'),
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();

      expect(states, [ConnectivityStatus.offline]);

      await sub.cancel();
      await cubit.close();
    });

    test('checkNow emits offline on empty result', () async {
      final cubit = ConnectivityCubit(
        dnsLookup: (_) async => [],
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();

      expect(states, [ConnectivityStatus.offline]);

      await sub.cancel();
      await cubit.close();
    });

    test('checkNow emits offline on empty rawAddress', () async {
      final cubit = ConnectivityCubit(
        dnsLookup: (_) async => [_FakeInternetAddress([])],
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();

      expect(states, [ConnectivityStatus.offline]);

      await sub.cancel();
      await cubit.close();
    });

    test('does not emit duplicate states', () async {
      final cubit = ConnectivityCubit(
        dnsLookup: (_) async => [_FakeInternetAddress([8, 8, 8, 8])],
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();
      await cubit.checkNow();
      await tick();
      await cubit.checkNow();
      await tick();

      expect(states, [ConnectivityStatus.online]);

      await sub.cancel();
      await cubit.close();
    });

    test('transitions from online to offline', () async {
      var shouldFail = false;
      final cubit = ConnectivityCubit(
        dnsLookup: (_) {
          if (shouldFail) throw const SocketException('down');
          return Future.value([_FakeInternetAddress([1, 1, 1, 1])]);
        },
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();
      expect(states, [ConnectivityStatus.online]);

      shouldFail = true;
      await cubit.checkNow();
      await tick();
      expect(states, [ConnectivityStatus.online, ConnectivityStatus.offline]);

      await sub.cancel();
      await cubit.close();
    });

    test('transitions from offline back to online', () async {
      var shouldFail = true;
      final cubit = ConnectivityCubit(
        dnsLookup: (_) {
          if (shouldFail) throw const SocketException('down');
          return Future.value([_FakeInternetAddress([1, 1, 1, 1])]);
        },
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();
      expect(states, [ConnectivityStatus.offline]);

      shouldFail = false;
      await cubit.checkNow();
      await tick();
      expect(states, [ConnectivityStatus.offline, ConnectivityStatus.online]);

      await sub.cancel();
      await cubit.close();
    });

    test('stopMonitoring cancels timer', () async {
      final cubit = ConnectivityCubit(
        checkInterval: const Duration(milliseconds: 50),
        dnsLookup: (_) async => [_FakeInternetAddress([1, 2, 3, 4])],
      );

      cubit.startMonitoring();
      // Give the immediate check time to complete
      await Future<void>.delayed(const Duration(milliseconds: 30));

      cubit.stopMonitoring();

      // Capture state count after stop
      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // No new emissions after stop
      expect(states, isEmpty);

      await sub.cancel();
      await cubit.close();
    });

    test('close cancels timer and does not throw', () async {
      final cubit = ConnectivityCubit(
        checkInterval: const Duration(milliseconds: 50),
        dnsLookup: (_) async => [_FakeInternetAddress([1, 2, 3, 4])],
      );

      cubit.startMonitoring();
      // Let the immediate _check() finish before closing
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await cubit.close();

      // Should not throw after close
    });

    test('handles generic exceptions as offline', () async {
      final cubit = ConnectivityCubit(
        dnsLookup: (_) => throw Exception('unexpected'),
      );

      final states = <ConnectivityStatus>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.checkNow();
      await tick();

      expect(states, [ConnectivityStatus.offline]);

      await sub.cancel();
      await cubit.close();
    });
  });
}
