import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/core/network/certificate_pinning.dart';

void main() {
  group('CertificatePinning', () {
    test('testing hooks expose configured defaults', () {
      expect(CertificatePinning.hasPinsConfiguredForTesting, isFalse);
      expect(
        CertificatePinning.isTrustedGoogleDomainForTesting(
          'us-central1.cloudfunctions.net',
        ),
        isTrue,
      );
      expect(
        CertificatePinning.isTrustedGoogleDomainForTesting('api.crushhour.app'),
        isFalse,
      );
      expect(
        CertificatePinning.isPinnedHostForTesting(
          'firebasestorage.googleapis.com',
        ),
        isFalse,
      );
      expect(
        CertificatePinning.isPinnedHostForTesting('api.crushhour.app'),
        isFalse,
      );
    });

    test(
      'selects staging fingerprints by host naming and defaults otherwise',
      () {
        expect(
          CertificatePinning.fingerprintsForHostForTesting(
            'staging-api.crushhour.app',
          ),
          isEmpty,
        );
        expect(
          CertificatePinning.fingerprintsForHostForTesting('api.crushhour.app'),
          isEmpty,
        );
      },
    );

    test('computes SHA-256 fingerprint from certificate DER bytes', () {
      final cert = _FakeX509Certificate(derBytes: [1, 2, 3, 4, 5]);
      final expected = base64.encode(sha256.convert([1, 2, 3, 4, 5]).bytes);

      expect(
        CertificatePinning.certificateFingerprintForTesting(cert),
        equals(expected),
      );
    });

    test('returns null fingerprint when DER extraction throws', () {
      final cert = _FakeX509Certificate(throwOnDer: true);

      expect(CertificatePinning.certificateFingerprintForTesting(cert), isNull);
    });

    test('validateFingerprintForTesting matches and rejects correctly', () {
      final cert = _FakeX509Certificate(derBytes: [9, 8, 7]);
      final match = base64.encode(sha256.convert([9, 8, 7]).bytes);

      expect(
        CertificatePinning.validateFingerprintForTesting(
          cert: cert,
          expectedFingerprints: [match],
        ),
        isTrue,
      );

      expect(
        CertificatePinning.validateFingerprintForTesting(
          cert: cert,
          expectedFingerprints: const ['not-a-match'],
        ),
        isFalse,
      );
    });

    test(
      'validateHost returns structured error for unreachable endpoint',
      () async {
        final result = await CertificatePinning.validateHost('localhost');

        expect(result.host, equals('localhost'));
        expect(result.isValid, isFalse);
        expect(result.error, isNotNull);
        expect(result.toString(), contains('error'));
      },
    );
  });

  group('CertificatePinningResult', () {
    test('isExpiringSoon handles null, near expiry, and far expiry', () {
      expect(
        const CertificatePinningResult(
          isValid: true,
          host: 'api',
        ).isExpiringSoon,
        isFalse,
      );

      expect(
        CertificatePinningResult(
          isValid: true,
          host: 'api',
          validUntil: DateTime.now().add(const Duration(days: 5)),
        ).isExpiringSoon,
        isTrue,
      );

      expect(
        CertificatePinningResult(
          isValid: true,
          host: 'api',
          validUntil: DateTime.now().add(const Duration(days: 120)),
        ).isExpiringSoon,
        isFalse,
      );
    });

    test('toString includes host and validation details', () {
      const valid = CertificatePinningResult(
        isValid: true,
        host: 'api.crushhour.app',
        fingerprint: 'abc',
      );
      const errored = CertificatePinningResult(
        isValid: false,
        host: 'api.crushhour.app',
        error: 'boom',
      );

      expect(valid.toString(), contains('isValid: true'));
      expect(valid.toString(), contains('api.crushhour.app'));
      expect(errored.toString(), contains('error: boom'));
    });
  });
}

class _FakeX509Certificate implements X509Certificate {
  _FakeX509Certificate({
    this.derBytes = const [1, 2, 3],
    this.throwOnDer = false,
  });

  final List<int> derBytes;
  final bool throwOnDer;

  @override
  Uint8List get der {
    if (throwOnDer) {
      throw StateError('DER unavailable');
    }
    return Uint8List.fromList(derBytes);
  }

  @override
  String get issuer => 'CN=Issuer';

  @override
  String get subject => 'CN=Subject';

  @override
  DateTime get startValidity => DateTime(2020);

  @override
  DateTime get endValidity => DateTime(2030);

  @override
  String get pem => 'pem';

  @override
  Uint8List get sha1 => Uint8List.fromList(const [1, 2, 3]);
}
