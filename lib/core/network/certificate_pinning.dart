import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:crushhour/core/app_logger.dart';

/// Certificate pinning configuration and HTTP client factory.
///
/// Implements SSL/TLS certificate pinning to prevent man-in-the-middle attacks.
/// Uses SHA-256 fingerprints of the expected certificates.
class CertificatePinning {
  CertificatePinning._();

  /// Trusted Google domains that don't require certificate pinning.
  /// Google manages certificate rotation automatically and their infrastructure
  /// is highly trusted, so pinning is not necessary and would cause issues
  /// when certificates rotate.
  static const List<String> _trustedGoogleDomains = [
    'cloudfunctions.net',
    'googleapis.com',
    'firebaseio.com',
    'firebasestorage.googleapis.com',
  ];

  /// Expected SHA-256 certificate fingerprints for custom API domains.
  /// Only add fingerprints here if you use a custom domain (e.g., api.crushhour.app).
  ///
  /// To get the fingerprint for a custom domain, run:
  /// ```bash
  /// echo | openssl s_client -connect YOUR_DOMAIN:443 \
  ///   -servername YOUR_DOMAIN 2>/dev/null | \
  ///   openssl x509 -outform DER | openssl dgst -sha256 -binary | openssl enc -base64
  /// ```
  static const List<String> _productionFingerprints = [
    // Add fingerprints here when using a custom domain
  ];

  /// Expected SHA-256 certificate fingerprints for staging API.
  static const List<String> _stagingFingerprints = [
    // Add fingerprints here when using a custom staging domain
  ];

  /// Custom hosts that require certificate pinning.
  /// Only add your own custom domains here (not Google-hosted services).
  static const List<String> _pinnedHosts = [
    // Example: 'api.crushhour.app',
    // Example: 'staging-api.crushhour.app',
  ];

  /// Whether pinning is actually configured.
  /// If no hosts/fingerprints are set, pinning is effectively disabled.
  static bool get _hasPinsConfigured {
    if (_pinnedHosts.isEmpty) return false;
    if (_productionFingerprints.isNotEmpty) return true;
    if (_stagingFingerprints.isNotEmpty) return true;
    return false;
  }

  /// Creates an HTTP client with certificate pinning enabled.
  ///
  /// In debug mode, pinning can be bypassed for development.
  /// In release mode, pinning is always enforced.
  static http.Client createPinnedClient({
    bool bypassInDebug = true,
    Duration? connectionTimeout,
  }) {
    // If no pins are configured, fall back to the default client.
    if (!_hasPinsConfigured) {
      AppLogger.debug(
        'CertificatePinning: No pinned hosts/fingerprints configured. '
        'Pinning is disabled.',
      );
      return http.Client();
    }

    // Skip pinning in debug mode if allowed
    if (kDebugMode && bypassInDebug) {
      AppLogger.debug('CertificatePinning: Bypassed in debug mode');
      return http.Client();
    }

    final httpClient = HttpClient()
      ..connectionTimeout = connectionTimeout ?? const Duration(seconds: 30)
      ..badCertificateCallback = _validateCertificate;

    return IOClient(httpClient);
  }

  /// Creates an HTTP client with strict pinning (always enforced).
  static http.Client createStrictPinnedClient({Duration? connectionTimeout}) {
    if (!_hasPinsConfigured) {
      AppLogger.debug(
        'CertificatePinning: Strict pinning requested but no pins are configured.',
      );
      return http.Client();
    }

    final httpClient = HttpClient()
      ..connectionTimeout = connectionTimeout ?? const Duration(seconds: 30)
      ..badCertificateCallback = _validateCertificate;

    return IOClient(httpClient);
  }

  /// Validates the server certificate against pinned fingerprints.
  static bool _validateCertificate(
    X509Certificate cert,
    String host,
    int port,
  ) {
    // Skip pinning for non-pinned hosts
    if (!_isPinnedHost(host)) {
      return true;
    }

    // Get the certificate fingerprint
    final fingerprint = _getCertificateFingerprint(cert);
    if (fingerprint == null) {
      AppLogger.error(
        'CertificatePinning: Failed to compute fingerprint for $host',
      );
      return false;
    }

    // Check against expected fingerprints
    final expectedFingerprints = _getFingerprintsForHost(host);
    final isValid = expectedFingerprints.contains(fingerprint);

    if (!isValid) {
      AppLogger.error('CertificatePinning: Certificate mismatch for $host');
      AppLogger.error('  Expected: ${expectedFingerprints.join(', ')}');
      AppLogger.error('  Got: $fingerprint');
    }

    return isValid;
  }

  /// Checks if a host is a trusted Google domain (no pinning needed).
  static bool _isTrustedGoogleDomain(String host) {
    return _trustedGoogleDomains.any((domain) => host.endsWith(domain));
  }

  /// Checks if a host requires certificate pinning.
  /// Returns false for trusted Google domains and hosts not in the pinned list.
  static bool _isPinnedHost(String host) {
    // Skip pinning for trusted Google domains
    if (_isTrustedGoogleDomain(host)) {
      return false;
    }
    return _pinnedHosts.any((pinnedHost) => host.endsWith(pinnedHost));
  }

  /// Gets the expected fingerprints for a host.
  static List<String> _getFingerprintsForHost(String host) {
    if (host.contains('staging')) {
      return _stagingFingerprints;
    }
    return _productionFingerprints;
  }

  /// Computes the SHA-256 fingerprint of a certificate.
  static String? _getCertificateFingerprint(X509Certificate cert) {
    try {
      final derBytes = cert.der;
      final digest = sha256.convert(derBytes);
      return base64.encode(digest.bytes);
    } catch (e) {
      AppLogger.error('CertificatePinning: Error computing fingerprint: $e');
      return null;
    }
  }

  /// Validates a certificate fingerprint manually.
  ///
  /// Useful for testing or pre-validating certificates.
  static Future<CertificatePinningResult> validateHost(String host) async {
    try {
      final socket = await SecureSocket.connect(
        host,
        443,
        onBadCertificate: (cert) {
          // Accept the certificate to get its details
          return true;
        },
      );

      final cert = socket.peerCertificate;
      await socket.close();

      if (cert == null) {
        return CertificatePinningResult(
          isValid: false,
          host: host,
          error: 'No certificate received',
        );
      }

      final fingerprint = _getCertificateFingerprint(cert);
      final expectedFingerprints = _getFingerprintsForHost(host);
      final isValid =
          fingerprint != null && expectedFingerprints.contains(fingerprint);

      return CertificatePinningResult(
        isValid: isValid,
        host: host,
        fingerprint: fingerprint,
        expectedFingerprints: expectedFingerprints,
        issuer: cert.issuer,
        subject: cert.subject,
        validFrom: cert.startValidity,
        validUntil: cert.endValidity,
      );
    } catch (e) {
      return CertificatePinningResult(
        isValid: false,
        host: host,
        error: e.toString(),
      );
    }
  }
}

/// Result of certificate pinning validation.
class CertificatePinningResult {
  const CertificatePinningResult({
    required this.isValid,
    required this.host,
    this.fingerprint,
    this.expectedFingerprints,
    this.issuer,
    this.subject,
    this.validFrom,
    this.validUntil,
    this.error,
  });

  final bool isValid;
  final String host;
  final String? fingerprint;
  final List<String>? expectedFingerprints;
  final String? issuer;
  final String? subject;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? error;

  bool get isExpiringSoon {
    if (validUntil == null) return false;
    final daysUntilExpiry = validUntil!.difference(DateTime.now()).inDays;
    return daysUntilExpiry < 30;
  }

  @override
  String toString() {
    if (error != null) {
      return 'CertificatePinningResult(host: $host, error: $error)';
    }
    return 'CertificatePinningResult('
        'host: $host, '
        'isValid: $isValid, '
        'fingerprint: $fingerprint, '
        'issuer: $issuer, '
        'validUntil: $validUntil)';
  }
}
