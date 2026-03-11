import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fake repositories env parity', () {
    test('prefers API_BASE_URL over legacy CRUSH_API_BASE_URL', () {
      final baseUrl = resolveBackendBaseUrlForEnv(
        apiBaseUrl: 'https://api.primary.example',
        legacyApiBaseUrl: 'https://api.legacy.example',
      );

      expect(baseUrl, 'https://api.primary.example');
    });

    test('falls back to legacy key when API_BASE_URL is empty', () {
      final baseUrl = resolveBackendBaseUrlForEnv(
        apiBaseUrl: '',
        legacyApiBaseUrl: 'https://api.legacy.example',
      );

      expect(baseUrl, 'https://api.legacy.example');
    });

    test('uses fallback when both env values are empty', () {
      final baseUrl = resolveBackendBaseUrlForEnv(
        apiBaseUrl: '',
        legacyApiBaseUrl: '',
        fallback: 'https://api.default.example',
      );

      expect(baseUrl, 'https://api.default.example');
    });
  });
}
