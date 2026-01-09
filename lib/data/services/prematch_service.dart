import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock implementation of PreMatchService.
/// Stores pre-match message requests locally for demo purposes.
class PreMatchService {
  static const _preMatchRequestsKey = 'mock_prematch_requests';

  Future<void> sendPreMatchMessageRequest({
    required String targetUserId,
    required String content,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Store the request locally
    final prefs = await SharedPreferences.getInstance();
    final requestsJson = prefs.getString(_preMatchRequestsKey);
    final requests = requestsJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(requestsJson))
        : <Map<String, dynamic>>[];

    requests.add({
      'id': 'prematch_${DateTime.now().millisecondsSinceEpoch}',
      'targetUserId': targetUserId,
      'content': content,
      'sentAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    });

    await prefs.setString(_preMatchRequestsKey, jsonEncode(requests));
  }

  /// Get all sent pre-match requests (for debugging/demo)
  Future<List<Map<String, dynamic>>> getSentRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final requestsJson = prefs.getString(_preMatchRequestsKey);
    if (requestsJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(requestsJson));
  }

  /// Clear all pre-match requests (for testing)
  Future<void> clearRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preMatchRequestsKey);
  }
}
