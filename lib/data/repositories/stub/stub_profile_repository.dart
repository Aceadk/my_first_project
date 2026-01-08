import '../../models/user.dart';
import '../../models/profile.dart';
import '../profile_repository.dart';

/// Stub implementation of ProfileRepository.
/// Replace this with your actual backend implementation.
class StubProfileRepository implements ProfileRepository {
  @override
  Future<CrushUser?> getCurrentUser() async {
    // TODO: Implement fetching current user from your backend
    return null;
  }

  @override
  Future<CrushUser> saveBasicInfo({
    String? username,
    required String name,
    required int age,
    required String gender,
    String? sexualOrientation,
  }) async {
    // TODO: Implement saving basic info to your backend
    throw UnimplementedError('Save basic info not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser> saveProfileDetails({
    required String bio,
    required List<String> photoUrls,
    required List<String> videoUrls,
    String? jobTitle,
    String? company,
    String? school,
    required List<String> interests,
    List<String>? prompts,
  }) async {
    // TODO: Implement saving profile details to your backend
    throw UnimplementedError('Save profile details not implemented. Connect your backend.');
  }

  @override
  Future<void> uploadIdDocument(/* e.g. File or bytes type */) async {
    // TODO: Implement ID document upload to your backend
    throw UnimplementedError('ID upload not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser> markIdVerified() async {
    // TODO: Implement ID verification marking
    throw UnimplementedError('ID verification not implemented. Connect your backend.');
  }

  @override
  Future<CrushUser> updateProfile(Profile profile) async {
    // TODO: Implement profile update to your backend
    throw UnimplementedError('Profile update not implemented. Connect your backend.');
  }
}
