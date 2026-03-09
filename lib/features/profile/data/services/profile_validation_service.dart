import 'package:cloud_functions/cloud_functions.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_validation_repository.dart';

/// Profile completeness data returned from the server.
///
/// All scores are normalized to 0.0-1.0 range to match client-side
/// [ProfileCompletenessSummary] from profile_completeness.dart.
///
/// Breakdown format (weighted scores, sum = total score):
/// - photos: 0.0-0.30 (30% weight)
/// - bio: 0.0-0.25 (25% weight)
/// - interests: 0.0-0.25 (25% weight)
/// - location: 0.0-0.20 (20% weight)
/// - prompts: 0.0-1.0 (tracking only, not counted in score)
class RemoteProfileCompleteness {
  RemoteProfileCompleteness({
    required this.score,
    required this.breakdown,
    required this.missing,
    required this.requiredMissing,
    required this.meetsSwipeMinimum,
    required this.meetsMessagingMinimum,
    required this.meetsRequiredFields,
    required this.meetsMinimum,
    required this.minimum,
    required this.threshold,
  });

  /// Overall completeness score (0.0-1.0, where 1.0 = 100% complete)
  final double score;
  final Map<String, double> breakdown;
  final List<String> missing;
  final List<String> requiredMissing;
  final bool meetsSwipeMinimum;
  final bool meetsMessagingMinimum;
  final bool meetsRequiredFields;
  final bool meetsMinimum;
  final String minimum;
  final double threshold;

  bool get allowsSwipe => meetsSwipeMinimum && meetsRequiredFields;
  bool get allowsMessaging => meetsMessagingMinimum && meetsRequiredFields;

  List<String> get missingForMessaging =>
      requiredMissing.isNotEmpty ? requiredMissing : missing;
  List<String> get missingForSwipe =>
      requiredMissing.isNotEmpty ? requiredMissing : missing;

  factory RemoteProfileCompleteness.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) => value is num ? value.toDouble() : 0.0;

    Map<String, double> toBreakdown(dynamic value) {
      if (value is Map) {
        return value.map((key, val) => MapEntry(key.toString(), toDouble(val)));
      }
      return {};
    }

    List<String> toList(dynamic value) {
      if (value is Iterable) {
        return value
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    final minimum = (map['minimum'] as String?) ?? 'swipe';

    return RemoteProfileCompleteness(
      score: toDouble(map['score']),
      breakdown: toBreakdown(map['breakdown']),
      missing: toList(map['missing']),
      requiredMissing: toList(map['requiredMissing']),
      meetsSwipeMinimum: map['meetsSwipeMinimum'] == true,
      meetsMessagingMinimum: map['meetsMessagingMinimum'] == true,
      meetsRequiredFields: map['meetsRequiredFields'] == true,
      meetsMinimum: map['meetsMinimum'] == true,
      minimum: minimum,
      threshold: toDouble(map['threshold']),
    );
  }
}

/// Service to validate profile completeness via Firebase Functions.

class ProfileValidationService implements ProfileValidationRepository {
  ProfileValidationService({
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(String minimum)?
    fetchCompletenessOverride,
  }) : _functions = functions ?? FirebaseFunctions.instance,
       _fetchCompletenessOverride = fetchCompletenessOverride;

  final FirebaseFunctions _functions;
  final Future<Map<String, dynamic>> Function(String minimum)?
  _fetchCompletenessOverride;
  final Map<String, RemoteProfileCompleteness> _lastKnownByMinimum = {};

  /// Timeout for Firebase function calls to prevent hanging
  static const Duration _callTimeout = Duration(seconds: 5);

  @override
  Future<RemoteProfileCompleteness> validate({String minimum = 'swipe'}) async {
    try {
      final data = _fetchCompletenessOverride != null
          ? await _fetchCompletenessOverride(minimum)
          : await _fetchRemoteCompleteness(minimum);
      final completeness = RemoteProfileCompleteness.fromMap(data);
      _lastKnownByMinimum[minimum] = completeness;
      return completeness;
    } catch (e) {
      AppLogger.error('ProfileValidationService.validate error: $e');

      final cached = _lastKnownByMinimum[minimum];
      if (cached != null) {
        AppLogger.warning(
          'ProfileValidationService.validate: using cached result for minimum=$minimum',
        );
        return cached;
      }

      if (e is TimeoutException) {
        throw ProfileValidationUnavailableException(
          'Profile validation timed out. Using local checks.',
          minimum: minimum,
          cause: e,
        );
      }

      throw ProfileValidationUnavailableException(
        'Could not verify profile completeness with the server. Using local checks.',
        minimum: minimum,
        cause: e,
      );
    }
  }

  Future<Map<String, dynamic>> _fetchRemoteCompleteness(String minimum) async {
    final callable = _functions.httpsCallable(
      'checkProfileCompleteness',
      options: HttpsCallableOptions(timeout: _callTimeout),
    );
    final result = await callable
        .call<Map<String, dynamic>>({'minimum': minimum})
        .timeout(
          _callTimeout,
          onTimeout: () {
            AppLogger.error(
              'ProfileValidationService.validate: timeout after $_callTimeout',
            );
            throw TimeoutException('Profile validation timed out');
          },
        );

    return Map<String, dynamic>.from(result.data);
  }
}

/// Exception thrown when a timeout occurs
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

/// Exception thrown when remote profile validation is unavailable and no cache exists.
class ProfileValidationUnavailableException implements Exception {
  ProfileValidationUnavailableException(
    this.message, {
    required this.minimum,
    this.cause,
  });

  final String message;
  final String minimum;
  final Object? cause;

  @override
  String toString() => message;
}
