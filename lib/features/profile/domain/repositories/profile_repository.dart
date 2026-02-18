import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/favourites.dart';

abstract class ProfileRepository {
  Future<CrushUser?> getCurrentUser();

  Future<CrushUser> saveBasicInfo({
    String? username,
    required String name,
    String? lastName,
    required int age,
    required String gender,
    String? sexualOrientation,
    DateTime? dateOfBirth,
    bool? showFirstName,
    bool? showLastName,
  });

  Future<CrushUser> saveProfileDetails({
    required String bio,
    required List<String> photoUrls,
    required List<String> videoUrls,
    String? jobTitle,
    String? company,
    String? school,
    required List<String> interests,
    List<String>? prompts,
    String? city,
    String? country,
    ProfileFavourites? favourites,
    List<String>? showMeGenders,
    double? latitude, // For discovery distance filtering
    double? longitude, // For discovery distance filtering
  });

  Future<void> uploadIdDocument(/* e.g. File or bytes type */);

  Future<CrushUser> markIdVerified();

  Future<CrushUser> updateProfile(Profile profile);

  /// Update the user's theme preference (stored at account level).
  Future<void> updateThemePreference(String preference);

  /// Skip basic info setup - only saves username, marks hasCompletedBasicInfo as true.
  Future<CrushUser> skipBasicInfo({required String username});

  /// Skip profile setup entirely - marks hasCompletedProfileSetup as true.
  Future<CrushUser> skipProfileSetup();
}
