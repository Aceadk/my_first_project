import '../models/user.dart';
import '../models/profile.dart';

abstract class ProfileRepository {
  Future<CrushUser?> getCurrentUser();

  Future<CrushUser> saveBasicInfo({
    required String name,
    required int age,
    required String gender,
    String? sexualOrientation,
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
  });

  Future<void> uploadIdDocument(/* e.g. File or bytes type */);

  Future<CrushUser> markIdVerified();

  Future<CrushUser> updateProfile(Profile profile);
}
