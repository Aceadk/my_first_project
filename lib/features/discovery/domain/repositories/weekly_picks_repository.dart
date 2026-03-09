import 'package:crushhour/features/discovery/domain/models/weekly_picks.dart';

abstract class WeeklyPicksRepository {
  Stream<WeeklyPicks> get picksStream;
  WeeklyPicks? get currentPicks;
  bool get hasUnseenPicks;
  int get unseenCount;
  bool get isCurrentWeek;

  Future<WeeklyPicks> loadPicks(String userId);
  Future<void> markPickViewed(String pickId);
  Future<void> markPickLiked(String pickId);
  bool isPickViewed(String pickId);
  bool isPickLiked(String pickId);
  List<WeeklyPick> getUnviewedPicks();
  List<WeeklyPick> getAllPicks();
  Duration getTimeUntilRefresh();
  String getNewPicksTimeDisplay();
  void clearUserData();
  void dispose();
}
