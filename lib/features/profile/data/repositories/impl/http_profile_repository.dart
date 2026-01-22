import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/dto/profile_dto.dart';
import 'package:crushhour/core/network/mappers/profile_mapper.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/favourites.dart';
import '../profile_repository.dart';

/// HTTP-based implementation of ProfileRepository.
class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  CrushUser? _cachedUser;

  @override
  Future<CrushUser?> getCurrentUser() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.profileMe,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      debugPrint('HttpProfileRepository: Failed to get current user - ${result.error}');
      return _cachedUser;
    }

    final profileDto = ProfileDto.fromJson(result.data!);
    final profile = ProfileMapper.profileFromDto(profileDto);

    _cachedUser = CrushUser(
      id: profile.id,
      phoneNumber: result.data!['phone_number'] as String? ?? '',
      email: result.data!['email'] as String?,
      username: profile.name,
      isEmailVerified: result.data!['email_verified'] as bool? ?? false,
      isPhoneVerified: result.data!['phone_verified'] as bool? ?? true,
      isIdVerified: profile.isVerified,
      plan: result.data!['is_premium'] == true ? SubscriptionPlan.plus : SubscriptionPlan.free,
      profile: profile,
    );

    return _cachedUser;
  }

  @override
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
  }) async {
    // Use provided birth date or calculate from age
    final birthDate = dateOfBirth ?? DateTime(DateTime.now().year - age, 1, 1);

    final request = UpdateProfileRequestDto(
      displayName: name,
      birthDate: birthDate,
      gender: gender,
    );

    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.profileUpdate,
      dto: request,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to save basic info');
    }

    // Refresh user data
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
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
    String? city,
    String? country,
    ProfileFavourites? favourites,
  }) async {
    final request = UpdateProfileRequestDto(
      bio: bio,
      jobTitle: jobTitle,
      company: company,
      education: school,
      interests: interests,
    );

    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.profileUpdate,
      dto: request,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to save profile details');
    }

    // Upload photos if provided
    for (int i = 0; i < photoUrls.length; i++) {
      final photoUrl = photoUrls[i];
      // Skip if already a remote URL
      if (photoUrl.startsWith('http')) continue;

      await _uploadPhoto(photoUrl, isPrimary: i == 0);
    }

    // Refresh user data
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
  }

  @override
  Future<void> uploadIdDocument(/* e.g. File or bytes type */) async {
    // ID document upload requires a file path parameter
    // This method signature would need to be updated in the interface
    // to accept a file path or File object
    debugPrint('HttpProfileRepository: uploadIdDocument - update interface to accept file path');
  }

  /// Upload an ID document for verification.
  Future<void> uploadIdDocumentFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final result = await _apiClient.uploadFile<Map<String, dynamic>>(
      endpoint: '/profile/verify/document',
      file: file,
      fieldName: 'document',
      fields: {'type': 'id_verification'},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to upload ID document');
    }
  }

  @override
  Future<CrushUser> markIdVerified() async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/profile/verify',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to mark ID verified');
    }

    // Refresh user data
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
  }

  @override
  Future<CrushUser> updateProfile(Profile profile) async {
    final request = ProfileMapper.profileToUpdateRequest(profile);

    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.profileUpdate,
      dto: request,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to update profile');
    }

    // Update preferences if changed
    final prefsDto = ProfileMapper.preferencesToDto(profile.preferences);
    await _apiClient.patch<void>(
      ApiEndpoints.profilePreferences,
      dto: prefsDto,
    );

    // Refresh user data
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
  }

  /// Upload a profile photo.
  ///
  /// Returns the remote URL of the uploaded photo.
  Future<String> _uploadPhoto(String localPath, {bool isPrimary = false}) async {
    final file = File(localPath);

    if (!await file.exists()) {
      throw Exception('Photo file not found: $localPath');
    }

    final result = await _apiClient.uploadFile<Map<String, dynamic>>(
      endpoint: ApiEndpoints.profilePhotos,
      file: file,
      fieldName: 'photo',
      fields: {
        'is_primary': isPrimary.toString(),
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to upload photo');
    }

    final photoUrl = result.data?['url'] as String?;
    if (photoUrl == null) {
      throw Exception('No photo URL returned from server');
    }

    debugPrint('HttpProfileRepository: Photo uploaded successfully - $photoUrl');
    return photoUrl;
  }

  /// Upload a profile photo and return its URL.
  ///
  /// This is a public method that can be called directly.
  Future<String> uploadPhoto(String filePath, {bool isPrimary = false}) async {
    return _uploadPhoto(filePath, isPrimary: isPrimary);
  }

  /// Upload multiple photos at once.
  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    final files = <File>[];
    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Photo file not found: $path');
      }
      files.add(file);
    }

    final result = await _apiClient.uploadFiles<Map<String, dynamic>>(
      endpoint: ApiEndpoints.profilePhotos,
      files: files,
      fieldName: 'photos',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to upload photos');
    }

    final urls = (result.data?['urls'] as List<dynamic>?)
        ?.map((url) => url as String)
        .toList();

    if (urls == null || urls.isEmpty) {
      throw Exception('No photo URLs returned from server');
    }

    return urls;
  }

  /// Delete a profile photo.
  Future<void> deletePhoto(String photoId) async {
    final result = await _apiClient.delete<void>(
      ApiEndpoints.profilePhotoById(photoId),
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to delete photo');
    }
  }

  /// Reorder profile photos.
  Future<void> reorderPhotos(List<String> photoIds) async {
    final result = await _apiClient.post<void>(
      '${ApiEndpoints.profilePhotos}/reorder',
      body: {'photo_ids': photoIds},
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to reorder photos');
    }
  }

  @override
  Future<CrushUser> skipBasicInfo({required String username}) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/profile/skip-basic-info',
      body: {'username': username},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to skip basic info');
    }

    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
  }

  @override
  Future<CrushUser> skipProfileSetup() async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/profile/skip-setup',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to skip profile setup');
    }

    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
  }
}
