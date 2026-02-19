import 'dart:io';

import 'package:crushhour/core/errors.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('success creates a successful result', () {
      const result = Result.success(42);
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.data, 42);
      expect(result.errorMessage, null);
    });

    test('failure creates a failed result', () {
      const result = Result<int>.failure('Oops', code: 'err_1');
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.data, null);
      expect(result.errorMessage, 'Oops');
      expect(result.errorCode, 'err_1');
    });

    test('valueOrNull returns data on success', () {
      const result = Result.success('test');
      expect(result.valueOrNull, 'test');
    });

    test('valueOrNull returns null on failure', () {
      const result = Result<String>.failure('error');
      expect(result.valueOrNull, null);
    });

    test('getOrElse returns data on success', () {
      const result = Result.success(10);
      expect(result.getOrElse(0), 10);
    });

    test('getOrElse returns default on failure', () {
      const result = Result<int>.failure('error');
      expect(result.getOrElse(0), 0);
    });

    group('map', () {
      test('transforms data on success', () {
        const result = Result.success(5);
        final mapped = result.map((i) => i * 2);
        expect(mapped.data, 10);
      });

      test('propagates failure', () {
        const result = Result<int>.failure('orig error', code: '1');
        final mapped = result.map((i) => i * 2);
        expect(mapped.isFailure, true);
        expect(mapped.errorMessage, 'orig error');
        expect(mapped.errorCode, '1');
      });
    });

    group('flatMap', () {
      test('chains success', () {
        const result = Result.success(5);
        final flatMapped = result.flatMap((i) => Result.success(i.toString()));
        expect(flatMapped.data, '5');
      });

      test('chains failure from transform', () {
        const result = Result.success(5);
        final flatMapped = result.flatMap(
          (i) => const Result<String>.failure('fail'),
        );
        expect(flatMapped.isFailure, true);
        expect(flatMapped.errorMessage, 'fail');
      });

      test('propagates original failure', () {
        const result = Result<int>.failure('orig');
        final flatMapped = result.flatMap((i) => const Result.success('new'));
        expect(flatMapped.errorMessage, 'orig');
      });
    });

    group('fold', () {
      test('calls onSuccess on success', () {
        const result = Result.success('yes');
        final value = result.fold(
          onSuccess: (s) => 'success $s',
          onFailure: (e, c) => 'fail',
        );
        expect(value, 'success yes');
      });

      test('calls onFailure on failure', () {
        const result = Result<String>.failure('no', code: '404');
        final value = result.fold(
          onSuccess: (s) => 'success',
          onFailure: (e, c) => '$e ($c)',
        );
        expect(value, 'no (404)');
      });
    });

    group('guard', () {
      test('captures value on success', () async {
        final result = await Result.guard(() async => 42);
        expect(result.data, 42);
      });

      test('captures exception as failure', () async {
        final result = await Result.guard(() async => throw Exception('boom'));
        expect(result.isFailure, true);
        // Default fallback error message
        expect(result.errorMessage, 'Something went wrong. Please try again.');
      });

      test('captures SocketException with specific message', () async {
        final result = await Result.guard(
          () async => throw const SocketException('no net'),
        );
        expect(result.errorCode, 'network_unavailable');
      });

      test('captures RepositoryException with specific code', () async {
        final result = await Result.guard(
          () async => throw RepositoryException('my_code', 'custom'),
        );
        expect(result.errorCode, 'my_code');
        expect(result.errorMessage, 'custom');
      });
    });

    group('guardSync', () {
      test('captures value on success', () {
        final result = Result.guardSync(() => 42);
        expect(result.data, 42);
      });

      test('captures exception', () {
        final result = Result.guardSync(() => throw Exception('boom'));
        expect(result.isFailure, true);
      });
    });

    test('equality works', () {
      expect(const Result.success(1), const Result.success(1));
      expect(const Result.success(1), isNot(const Result.success(2)));
      expect(const Result<int>.failure('a'), const Result<int>.failure('a'));
    });
  });
}
