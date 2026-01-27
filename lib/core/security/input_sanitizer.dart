import 'package:flutter/foundation.dart';
import 'package:crushhour/core/constants/validation_constants.dart';

/// Input sanitization utilities for security.
///
/// SECURITY FEATURES:
/// - Removes potentially dangerous characters
/// - Prevents XSS attacks by escaping HTML entities
/// - Limits input length to prevent DoS
/// - Validates and sanitizes URLs
/// - Strips control characters
class InputSanitizer {
  /// Maximum length for various field types - uses centralized constants
  static const int maxNameLength = ValidationConstants.maxNameLength;
  static const int maxBioLength = ValidationConstants.maxBioLength;
  static const int maxCityLength = ValidationConstants.maxCityLength;
  static const int maxJobTitleLength = ValidationConstants.maxJobTitleLength;
  static const int maxCompanyLength = ValidationConstants.maxCompanyLength;
  static const int maxSchoolLength = ValidationConstants.maxSchoolLength;
  static const int maxInterestLength = ValidationConstants.maxInterestLength;
  static const int maxPromptLength = ValidationConstants.maxPromptLength;
  static const int maxUrlLength = ValidationConstants.maxUrlLength;

  /// Sanitize a general text field.
  /// Removes control characters and trims whitespace.
  static String sanitizeText(String? input, {int? maxLength}) {
    if (input == null || input.isEmpty) return '';

    // Remove null bytes and control characters (except newlines and tabs)
    var sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Limit length
    final limit = maxLength ?? 1000;
    if (sanitized.length > limit) {
      sanitized = sanitized.substring(0, limit);
    }

    return sanitized;
  }

  /// Sanitize a name field (no HTML, limited special chars).
  static String sanitizeName(String? input) {
    if (input == null || input.isEmpty) return '';

    var sanitized = sanitizeText(input, maxLength: maxNameLength);

    // Remove HTML tags
    sanitized = _stripHtmlTags(sanitized);

    // Only allow letters, numbers, spaces, hyphens, apostrophes, and periods
    sanitized = sanitized.replaceAll(RegExp(r"[^a-zA-Z0-9\s\-'\.À-ÿ]"), '');

    return sanitized.trim();
  }

  /// Sanitize a bio/description field (preserves more formatting).
  static String sanitizeBio(String? input) {
    if (input == null || input.isEmpty) return '';

    var sanitized = sanitizeText(input, maxLength: maxBioLength);

    // Remove HTML tags but preserve line breaks
    sanitized = _stripHtmlTags(sanitized);

    // Escape any remaining HTML entities for safety
    sanitized = _escapeHtml(sanitized);

    return sanitized;
  }

  /// Sanitize a city/location field.
  static String sanitizeCity(String? input) {
    if (input == null || input.isEmpty) return '';

    var sanitized = sanitizeText(input, maxLength: maxCityLength);
    sanitized = _stripHtmlTags(sanitized);

    // Only allow letters, numbers, spaces, hyphens, commas, and periods
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-,\.À-ÿ]'), '');

    return sanitized.trim();
  }

  /// Sanitize job title or company name.
  static String sanitizeJobField(String? input, {int? maxLength}) {
    if (input == null || input.isEmpty) return '';

    var sanitized = sanitizeText(input, maxLength: maxLength ?? maxJobTitleLength);
    sanitized = _stripHtmlTags(sanitized);

    // Allow letters, numbers, spaces, hyphens, ampersands, periods, parentheses
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-&\.\(\)À-ÿ]'), '');

    return sanitized.trim();
  }

  /// Sanitize an interest tag.
  static String sanitizeInterest(String? input) {
    if (input == null || input.isEmpty) return '';

    var sanitized = sanitizeText(input, maxLength: maxInterestLength);
    sanitized = _stripHtmlTags(sanitized);

    // Only allow alphanumeric and spaces
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');

    return sanitized.trim();
  }

  /// Sanitize a list of interests.
  static List<String> sanitizeInterests(List<String>? inputs) {
    if (inputs == null || inputs.isEmpty) return [];

    return inputs
        .map((i) => sanitizeInterest(i))
        .where((i) => i.isNotEmpty)
        .take(50) // Limit number of interests
        .toList();
  }

  /// Sanitize a URL (for photo/video URLs).
  /// In debug mode, allows local file paths for development with local file fallback.
  static String? sanitizeUrl(String? input, {bool allowLocalPaths = false}) {
    if (input == null || input.isEmpty) return null;

    var sanitized = sanitizeText(input, maxLength: maxUrlLength);

    // Check if it's a local file path (for debug mode fallback)
    final isLocalPath = !sanitized.startsWith('http://') &&
                        !sanitized.startsWith('https://') &&
                        (sanitized.startsWith('/') || sanitized.startsWith('file://'));

    // In debug mode, allow local file paths if enabled
    if (isLocalPath) {
      if (kDebugMode && allowLocalPaths) {
        // Allow local paths in debug mode for development
        return sanitized;
      }
      return null;
    }

    // Try to parse as valid URI
    try {
      final uri = Uri.parse(sanitized);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return null;
      }

      // Block dangerous schemes
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return null;
      }

      // Block javascript: and data: schemes (even if encoded)
      final lowered = sanitized.toLowerCase();
      if (lowered.contains('javascript:') || lowered.contains('data:')) {
        return null;
      }

      return sanitized;
    } catch (e) {
      debugPrint('InputSanitizer: URL sanitization error: $e');
      return null;
    }
  }

  /// Sanitize a list of URLs.
  /// In debug mode, allows local file paths for development with local file fallback.
  static List<String> sanitizeUrls(List<String>? inputs, {bool allowLocalPaths = true}) {
    if (inputs == null || inputs.isEmpty) return [];

    return inputs
        .map((u) => sanitizeUrl(u, allowLocalPaths: allowLocalPaths))
        .where((u) => u != null)
        .cast<String>()
        .take(20) // Limit number of URLs
        .toList();
  }

  /// Sanitize a phone number.
  static String sanitizePhone(String? input) {
    if (input == null || input.isEmpty) return '';

    // Only allow digits, plus sign, hyphens, spaces, parentheses
    var sanitized = input.replaceAll(RegExp(r'[^\d\+\-\s\(\)]'), '');

    // Limit length
    if (sanitized.length > 20) {
      sanitized = sanitized.substring(0, 20);
    }

    return sanitized.trim();
  }

  /// Sanitize an email address.
  static String sanitizeEmail(String? input) {
    if (input == null || input.isEmpty) return '';

    var sanitized = input.trim().toLowerCase();

    // Basic email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(sanitized)) {
      return '';
    }

    // Limit length
    if (sanitized.length > 254) {
      return '';
    }

    return sanitized;
  }

  /// Sanitize a username.
  static String sanitizeUsername(String? input) {
    if (input == null || input.isEmpty) return '';

    var sanitized = input.trim().toLowerCase();

    // Only allow alphanumeric and underscores
    sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // Limit length
    if (sanitized.length > 30) {
      sanitized = sanitized.substring(0, 30);
    }

    return sanitized;
  }

  /// Strip HTML tags from input.
  static String _stripHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Escape HTML entities to prevent XSS.
  static String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Validate age is within reasonable bounds.
  static int? sanitizeAge(int? age) {
    if (age == null) return null;
    if (age < 18 || age > 120) return null;
    return age;
  }

  /// Validate height in cm is within reasonable bounds.
  static int? sanitizeHeight(int? heightCm) {
    if (heightCm == null) return null;
    if (heightCm < 100 || heightCm > 250) return null;
    return heightCm;
  }

  /// Sanitize geographic coordinates.
  static double? sanitizeLatitude(double? lat) {
    if (lat == null) return null;
    if (lat < -90 || lat > 90) return null;
    return lat;
  }

  static double? sanitizeLongitude(double? lng) {
    if (lng == null) return null;
    if (lng < -180 || lng > 180) return null;
    return lng;
  }
}
