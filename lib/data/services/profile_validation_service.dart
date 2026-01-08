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

/// Stub implementation of ProfileValidationService.
/// Replace with your actual backend integration.
class ProfileValidationService {
  Future<RemoteProfileCompleteness> validate({String minimum = 'swipe'}) async {
    // TODO: Implement profile validation with your backend
    // For now, return a default that allows all actions
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
