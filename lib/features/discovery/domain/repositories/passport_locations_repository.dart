abstract class PassportLocationsRepository {
  Future<void> recordLocation(String city, String country);
  Future<List<Map<String, String>>> getPassportLocations();
  Future<int> getLocationCount(String city, String country);
  Future<List<Map<String, dynamic>>> getTrendingLocations();
  Future<List<Map<String, String>>> searchLocations(String query);
}
