import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

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
    double toDouble(dynamic value) =>
        value is num ? value.toDouble() : 0.0;

    Map<String, double> toBreakdown(dynamic value) {
      if (value is Map) {
        return value.map(
          (key, val) => MapEntry(
            key.toString(),
            toDouble(val),
          ),
        );
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
class ProfileValidationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<RemoteProfileCompleteness> validate({String minimum = 'swipe'}) async {
    try {
      final callable = _functions.httpsCallable('checkProfileCompleteness');
      final result = await callable.call<Map<String, dynamic>>({
        'minimum': minimum,
      });

      return RemoteProfileCompleteness.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } catch (e) {
      debugPrint('ProfileValidationService.validate error: $e');
      // Return a permissive default on error to not block the user
      return RemoteProfileCompleteness(
        score: 100.0,
        breakdown: {},
        missing: [],
        requiredMissing: [],
        meetsSwipeMinimum: true,
        meetsMessagingMinimum: true,
        meetsRequiredFields: true,
        meetsMinimum: true,
        minimum: minimum,
        threshold: 0.0,
      );
    }
  }
}
