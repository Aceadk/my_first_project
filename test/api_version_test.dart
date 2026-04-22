import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/network/api_version.dart';

void main() {
  group('ApiVersion', () {
    test('parse supports prefixed, partial, and invalid versions', () {
      expect(ApiVersion.parse('v1.2.3'), const ApiVersion(1, 2, 3));
      expect(ApiVersion.parse('2'), const ApiVersion(2, 0, 0));
      expect(ApiVersion.parse('bad.version'), const ApiVersion(0, 0, 0));
    });

    test('comparison operators and compatibility behave correctly', () {
      const v100 = ApiVersion(1, 0, 0);
      const v110 = ApiVersion(1, 1, 0);
      const v200 = ApiVersion(2, 0, 0);

      expect(v110 > v100, isTrue);
      expect(v100 < v110, isTrue);
      expect(v100 <= v100, isTrue);
      expect(v110 >= v100, isTrue);
      expect(v100.isCompatibleWith(v110), isTrue);
      expect(v100.isCompatibleWith(v200), isFalse);
      expect(v110.meetsMinimum(v100), isTrue);
      expect(v100.meetsMinimum(v110), isFalse);
    });

    test('toString, pathSegment, equality, and hashCode are stable', () {
      const version = ApiVersion(1, 2, 3);

      expect(version.toString(), '1.2.3');
      expect(version.pathSegment, 'v1');
      expect(version, const ApiVersion(1, 2, 3));
      expect(version.hashCode, const ApiVersion(1, 2, 3).hashCode);
    });
  });

  group('ApiConfig', () {
    test('getUrl normalizes endpoints with and without leading slash', () {
      const config = ApiConfig(
        baseUrl: 'https://api.example.com',
        version: ApiVersion(2, 0, 0),
      );

      expect(config.getUrl('/matches'), 'https://api.example.com/v2/matches');
      expect(config.getUrl('chat'), 'https://api.example.com/v2/chat');
    });

    test('copyWith overrides only provided fields', () {
      const initial = ApiConfig(
        baseUrl: 'https://api.example.com',
        version: ApiVersion(1, 0, 0),
      );

      final updated = initial.copyWith(
        timeout: const Duration(seconds: 10),
        retryCount: 5,
      );

      expect(updated.baseUrl, 'https://api.example.com');
      expect(updated.version, const ApiVersion(1, 0, 0));
      expect(updated.timeout, const Duration(seconds: 10));
      expect(updated.retryCount, 5);
    });

    test('named environment configs expose expected host shape', () {
      expect(ApiConfig.development.baseUrl, contains('127.0.0.1'));
      expect(ApiConfig.staging.baseUrl, contains('cloudfunctions.net'));
      expect(ApiConfig.production.baseUrl, contains('cloudfunctions.net'));
    });
  });

  group('ApiEndpoints', () {
    test('dynamic endpoint builders produce expected paths', () {
      expect(ApiEndpoints.profileById('u1'), '/profile/u1');
      expect(ApiEndpoints.profilePhotoById('p1'), '/profile/photos/p1');
      expect(ApiEndpoints.chatMessages('c1'), '/chat/c1/messages');
      expect(ApiEndpoints.chatSend('c1'), '/chat/c1/send');
      expect(ApiEndpoints.chatRead('c1'), '/chat/c1/read');
      expect(ApiEndpoints.matchById('m1'), '/matches/m1');
      expect(ApiEndpoints.unmatch('m1'), '/matches/m1/unmatch');
    });

    test('remapped live endpoints match the current backend surface', () {
      expect(ApiEndpoints.subscriptionStatus, '/subscription/current');
      expect(ApiEndpoints.subscriptionPlans, '/subscription/plans');
      expect(ApiEndpoints.subscriptionPurchase, '/subscription/checkout');
      expect(ApiEndpoints.reportUser, '/users/report');
      expect(ApiEndpoints.blockUser, '/users/block');
      expect(ApiEndpoints.unblockUser, '/users/unblock');
      expect(ApiEndpoints.safetyAppeal, '/safety/appeal');
      expect(ApiEndpoints.callStart, '/calls/start');
      expect(ApiEndpoints.callEnd, '/calls/end');
      expect(ApiEndpoints.profilePhotoReorder, '/profile/photos/reorder');
    });
  });

  group('ApiFeatures', () {
    test('isAvailable handles known and unknown features', () {
      expect(
        ApiFeatures.isAvailable('video_calls', const ApiVersion(1, 0, 0)),
        isFalse,
      );
      expect(
        ApiFeatures.isAvailable('video_calls', const ApiVersion(1, 1, 0)),
        isTrue,
      );
      expect(
        ApiFeatures.isAvailable('unknown_feature', const ApiVersion(1, 0, 0)),
        isTrue,
      );
    });

    test(
      'required version and available feature list are derived correctly',
      () {
        expect(
          ApiFeatures.getRequiredVersion('advanced_filters'),
          const ApiVersion(1, 2, 0),
        );
        final v100Features = ApiFeatures.getAvailableFeatures(
          const ApiVersion(1, 0, 0),
        );
        final v120Features = ApiFeatures.getAvailableFeatures(
          const ApiVersion(1, 2, 0),
        );

        expect(v100Features, contains('read_receipts'));
        expect(v100Features, isNot(contains('advanced_filters')));
        expect(
          v120Features,
          containsAll(['advanced_filters', 'voice_messages']),
        );
      },
    );
  });

  group('VersionNegotiationResult', () {
    test('negotiate marks upgrade required when below server minimum', () {
      final result = VersionNegotiationResult.negotiate(
        clientVersion: const ApiVersion(1, 0, 0),
        serverMinVersion: const ApiVersion(1, 1, 0),
        serverMaxVersion: const ApiVersion(1, 2, 0),
      );

      expect(result.isCompatible, isFalse);
      expect(result.upgradeRequired, isTrue);
      expect(result.negotiatedVersion, const ApiVersion(1, 0, 0));
    });

    test(
      'negotiate provides warning for out-of-date but compatible client',
      () {
        final result = VersionNegotiationResult.negotiate(
          clientVersion: const ApiVersion(1, 1, 0),
          serverMinVersion: const ApiVersion(1, 0, 0),
          serverMaxVersion: const ApiVersion(1, 2, 0),
          serverRecommendedVersion: const ApiVersion(1, 2, 0),
        );

        expect(result.isCompatible, isTrue);
        expect(result.upgradeRequired, isFalse);
        expect(result.deprecationWarning, isNotNull);
        expect(result.negotiatedVersion, const ApiVersion(1, 1, 0));
      },
    );

    test('negotiate caps version to server max when client is newer', () {
      final result = VersionNegotiationResult.negotiate(
        clientVersion: const ApiVersion(1, 5, 0),
        serverMinVersion: const ApiVersion(1, 0, 0),
        serverMaxVersion: const ApiVersion(1, 2, 0),
      );

      expect(result.negotiatedVersion, const ApiVersion(1, 2, 0));
    });
  });

  group('ApiHeaders', () {
    test('getDefaultHeaders includes request id when provided', () {
      final headers = ApiHeaders.getDefaultHeaders(
        appVersion: '1.0.0',
        platform: 'android',
        requestId: 'req-123',
      );

      expect(headers[ApiHeaders.clientVersion], ApiVersion.current.toString());
      expect(headers[ApiHeaders.appVersion], '1.0.0');
      expect(headers[ApiHeaders.platform], 'android');
      expect(headers[ApiHeaders.requestId], 'req-123');
    });

    test('getDefaultHeaders omits request id when null or empty', () {
      final nullHeaders = ApiHeaders.getDefaultHeaders(
        appVersion: '1.0.0',
        platform: 'ios',
      );
      final emptyHeaders = ApiHeaders.getDefaultHeaders(
        appVersion: '1.0.0',
        platform: 'ios',
        requestId: '',
      );

      expect(nullHeaders.containsKey(ApiHeaders.requestId), isFalse);
      expect(emptyHeaders.containsKey(ApiHeaders.requestId), isFalse);
    });
  });
}
