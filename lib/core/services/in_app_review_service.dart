import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing in-app review prompts.
///
/// Uses intelligent timing to prompt users for reviews at optimal moments:
/// - After a successful match
/// - After completing a certain number of interactions
/// - Not more than once per 30 days
class InAppReviewService {
  InAppReviewService._();
  static final InAppReviewService instance = InAppReviewService._();

  final InAppReview _inAppReview = InAppReview.instance;

  static const String _keyLastPromptDate = 'in_app_review_last_prompt';
  static const String _keyTotalMatches = 'in_app_review_total_matches';
  static const String _keyTotalMessages = 'in_app_review_total_messages';
  static const String _keyHasReviewed = 'in_app_review_has_reviewed';

  /// Minimum days between review prompts.
  static const int _minDaysBetweenPrompts = 30;

  /// Number of matches after which to first prompt.
  static const int _matchesThreshold = 3;

  /// Number of messages after which to prompt (if no matches).
  static const int _messagesThreshold = 50;

  /// Records a new match and potentially triggers a review prompt.
  Future<void> recordMatch() async {
    final prefs = await SharedPreferences.getInstance();
    final totalMatches = (prefs.getInt(_keyTotalMatches) ?? 0) + 1;
    await prefs.setInt(_keyTotalMatches, totalMatches);

    // Check if we should prompt after this match
    if (totalMatches >= _matchesThreshold) {
      await _maybeRequestReview();
    }
  }

  /// Records messages sent and potentially triggers a review prompt.
  Future<void> recordMessagesSent(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final totalMessages = (prefs.getInt(_keyTotalMessages) ?? 0) + count;
    await prefs.setInt(_keyTotalMessages, totalMessages);

    // Check if we should prompt after reaching message threshold
    if (totalMessages >= _messagesThreshold) {
      await _maybeRequestReview();
    }
  }

  /// Manually triggers a review request if conditions are met.
  ///
  /// Call this after positive user experiences like:
  /// - Successful match celebration
  /// - Completing profile setup
  /// - After a successful date planning
  Future<bool> maybeRequestReview() async {
    return _maybeRequestReview();
  }

  /// Checks if a review can be requested and shows the prompt.
  Future<bool> _maybeRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user has already reviewed
    if (prefs.getBool(_keyHasReviewed) ?? false) {
      AppLogger.debug('InAppReviewService: User has already reviewed');
      return false;
    }

    // Check if enough time has passed since last prompt
    final lastPromptMillis = prefs.getInt(_keyLastPromptDate);
    if (lastPromptMillis != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMillis);
      final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;

      if (daysSinceLastPrompt < _minDaysBetweenPrompts) {
        AppLogger.debug(
          'InAppReviewService: Too soon since last prompt '
          '($daysSinceLastPrompt days, need $_minDaysBetweenPrompts)',
        );
        return false;
      }
    }

    // Check if in-app review is available
    final isAvailable = await _inAppReview.isAvailable();
    if (!isAvailable) {
      AppLogger.debug('InAppReviewService: In-app review not available');
      return false;
    }

    // Request the review
    try {
      AppLogger.debug('InAppReviewService: Requesting in-app review');
      await _inAppReview.requestReview();

      // Record that we prompted (we can't know if they actually reviewed)
      await prefs.setInt(
        _keyLastPromptDate,
        DateTime.now().millisecondsSinceEpoch,
      );

      return true;
    } catch (e) {
      AppLogger.error('InAppReviewService: Error requesting review: $e');
      return false;
    }
  }

  /// Opens the app store page for manual review.
  ///
  /// Use this for a "Rate Us" button in settings.
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: 'YOUR_APP_STORE_ID', // Replace with actual App Store ID
      );

      // Mark as reviewed since they intentionally opened the store
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasReviewed, true);
    } catch (e) {
      AppLogger.error('InAppReviewService: Error opening store listing: $e');
    }
  }

  /// Resets review tracking (for testing purposes).
  @visibleForTesting
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastPromptDate);
    await prefs.remove(_keyTotalMatches);
    await prefs.remove(_keyTotalMessages);
    await prefs.remove(_keyHasReviewed);
  }

  /// Gets current review statistics (for debugging).
  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'totalMatches': prefs.getInt(_keyTotalMatches) ?? 0,
      'totalMessages': prefs.getInt(_keyTotalMessages) ?? 0,
      'hasReviewed': prefs.getBool(_keyHasReviewed) ?? false,
      'lastPromptDate': prefs.getInt(_keyLastPromptDate) != null
          ? DateTime.fromMillisecondsSinceEpoch(
              prefs.getInt(_keyLastPromptDate)!,
            ).toIso8601String()
          : null,
    };
  }
}
