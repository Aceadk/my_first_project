import 'package:crushhour/features/analytics/domain/models/profile_insights.dart';

/// Abstract interface for profile insights operations.
abstract class ProfileInsightsRepository {
  Stream<ProfileInsights> get insightsStream;
  ProfileInsights? get currentInsights;

  Future<ProfileInsights> loadInsights(String userId);
  Future<ProfileInsights> refreshInsights(String userId);

  Future<ProfileInsights> getInsightsForRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  });

  Future<void> recordProfileView(String viewerUserId);
  Future<void> recordLikeReceived({bool isSuperLike = false});
  Future<void> recordLikeSent();

  List<PhotoPerformance> getPhotoPerformance();
  String getBestTimeToBeActive();

  void clearUserData();
  void dispose();
}
