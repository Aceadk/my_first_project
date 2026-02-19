import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/core/services/data_export_request_service.dart';

import 'mock/firebase_mock.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  late FirebaseFunctionsPlatform originalFunctionsPlatform;
  late _FakeFunctionsPlatform fakeFunctionsPlatform;

  setUpAll(() {
    originalFunctionsPlatform = FirebaseFunctionsPlatform.instance;
    fakeFunctionsPlatform = _FakeFunctionsPlatform();
    FirebaseFunctionsPlatform.instance = fakeFunctionsPlatform;
  });

  tearDownAll(() {
    FirebaseFunctionsPlatform.instance = originalFunctionsPlatform;
  });

  setUp(() {
    fakeFunctionsPlatform.reset();
  });

  test('returns success when export request callable succeeds', () async {
    fakeFunctionsPlatform.onCall = (functionName, parameters) async {
      expect(functionName, 'requestDataExport');
      return <String, dynamic>{
        'requestId': 'req_123',
        'status': 'queued',
        'nextAllowedAt': '2026-02-26T00:00:00.000Z',
      };
    };

    final service = DataExportRequestService();
    final result = await service.requestExport();

    expect(result.isSuccess, isTrue);
    expect(result.requestId, 'req_123');
    expect(result.status, 'queued');
    expect(result.nextAllowedAtIso, '2026-02-26T00:00:00.000Z');
    expect(result.code, isNull);
    expect(result.message, isNull);
  });

  test('surfaces callable precondition details on cooldown errors', () async {
    fakeFunctionsPlatform.onCall = (functionName, parameters) async {
      expect(functionName, 'requestDataExport');
      throw FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'Data export can only be requested once every 7 days.',
        details: const <String, dynamic>{
          'nextAllowedAt': '2026-02-26T00:00:00.000Z',
        },
      );
    };

    final service = DataExportRequestService();
    final result = await service.requestExport();

    expect(result.isSuccess, isFalse);
    expect(result.code, 'failed-precondition');
    expect(
      result.message,
      'Data export can only be requested once every 7 days.',
    );
    expect(result.nextAllowedAtIso, '2026-02-26T00:00:00.000Z');
  });

  test('returns unknown failure when non-functions error is thrown', () async {
    fakeFunctionsPlatform.onCall = (functionName, parameters) async {
      expect(functionName, 'requestDataExport');
      throw Exception('boom');
    };

    final service = DataExportRequestService();
    final result = await service.requestExport();

    expect(result.isSuccess, isFalse);
    expect(result.code, 'unknown');
    expect(result.message, contains('Exception: boom'));
  });
}

class _FakeFunctionsPlatform extends FirebaseFunctionsPlatform {
  _FakeFunctionsPlatform() : super(null, 'us-central1');

  Future<dynamic> Function(String functionName, Object? parameters)? onCall;

  void reset() {
    onCall = null;
  }

  @override
  FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) {
    return this;
  }

  @override
  HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) {
    return _FakeHttpsCallable(this, origin, name, options, null);
  }

  @override
  HttpsCallablePlatform httpsCallableWithUri(
    String? origin,
    Uri uri,
    HttpsCallableOptions options,
  ) {
    return _FakeHttpsCallable(this, origin, null, options, uri);
  }
}

class _FakeHttpsCallable extends HttpsCallablePlatform {
  _FakeHttpsCallable(
    super.functions,
    super.origin,
    super.name,
    super.options,
    super.uri,
  );

  _FakeFunctionsPlatform get _functions => functions as _FakeFunctionsPlatform;

  @override
  Future<dynamic> call([dynamic parameters]) async {
    final handler = _functions.onCall;
    if (handler == null) {
      throw FirebaseFunctionsException(
        code: 'unavailable',
        message: 'No fake callable response configured',
      );
    }
    return handler(name ?? uri.toString(), parameters);
  }

  @override
  Stream<dynamic> stream(Object? parameters) => const Stream<dynamic>.empty();
}
