import 'dart:io';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/cache/cache_policy.dart';
import 'package:crushhour/core/cache/cache_store.dart';
import 'package:crushhour/core/cache/cached_repository.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/circuit_breaker.dart';
import 'package:crushhour/core/network/dto/profile_dto.dart';
import 'package:crushhour/core/network/dto/upload_response_dto.dart';
import 'package:crushhour/core/network/mappers/profile_mapper.dart';
import 'package:crushhour/core/security/input_sanitizer.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';

import '../profile_repository.dart';

/// HTTP-based implementation of ProfileRepository.
class HttpProfileRepository with CachingMixin implements ProfileRepository {
  HttpProfileRepository({required ApiClient apiClient})
    : _apiClient = apiClient,
      _circuitBreaker = CircuitBreakerRegistry.instance.get('profile') {
    _store = MemoryCacheStore(maxEntries: 1);
    initCache(_store);
  }

  final ApiClient _apiClient;
  final CircuitBreaker _circuitBreaker;
  late final CacheStore _store;

  // Cache key for the current user
  static const _currentUserCacheKey = 'http_current_user';

  @override
  Future<CrushUser?> getCurrentUser() async {
    if (!_circuitBreaker.allowRequest()) {
      AppLogger.warning(
        'HttpProfileRepository: getCurrentUser blocked by circuit breaker',
      );
      final cacheEntry = await _store.get<CrushUser>(_currentUserCacheKey);
      return cacheEntry?.data;
    }

    try {
      return await cached<CrushUser>(
        key: _currentUserCacheKey,
        policy: CachePolicy.networkFirst,
        config: CacheConfig.standard,
        fetch: () async {
          final result = await _apiClient.get<Map<String, dynamic>>(
            ApiEndpoints.profileMe,
            parser: (data) => data as Map<String, dynamic>,
          );

          if (result.isFailure) {
            _circuitBreaker.recordFailure();
            AppLogger.debug(
              'HttpProfileRepository: Failed to get current user - ${result.error}',
            );
            // Re-throw to fall back to cache in cached()
            throw Exception('Failed to get current user: ${result.error}');
          }

          _circuitBreaker.recordSuccess();

          final payload = result.data!;
          final profileDto = ProfileDto.fromJson(payload);
          final profile = ProfileMapper.profileFromDto(profileDto);
          final nestedProfile = payload['profile'];
          final nestedUsername = nestedProfile is Map<String, dynamic>
              ? nestedProfile['username'] as String?
              : null;
          final canonicalUsername = (payload['username'] as String?)?.trim();
          final fallbackUsername = nestedUsername?.trim();
          final legacyUsername = (payload['usernameLower'] as String?)?.trim();
          final username =
              (canonicalUsername != null && canonicalUsername.isNotEmpty)
              ? canonicalUsername
              : (fallbackUsername != null && fallbackUsername.isNotEmpty)
              ? fallbackUsername
              : (legacyUsername != null && legacyUsername.isNotEmpty)
              ? legacyUsername
              : profile.name;

          return CrushUser(
            id: profile.id,
            phoneNumber: payload['phone_number'] as String? ?? '',
            email: payload['email'] as String?,
            username: username,
            isEmailVerified: payload['email_verified'] as bool? ?? false,
            isPhoneVerified: payload['phone_verified'] as bool? ?? true,
            isIdVerified: profile.isVerified,
            tier: payload['is_premium'] == true
                ? SubscriptionTier.plus
                : SubscriptionTier.free,
            themePreference:
                payload['theme_preference'] as String? ??
                payload['themePreference'] as String?,
            profile: profile,
          );
        },
      );
    } catch (e) {
      AppLogger.warning(
        'HttpProfileRepository: Network fetch and cache fallback failed - $e',
      );
      return null;
    }
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

    final sanitizedName = InputSanitizer.sanitizeName(name);

    final request = UpdateProfileRequestDto(
      displayName: sanitizedName,
      birthDate: birthDate,
      gender: gender,
    );

    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.profileUpdate,
      dto: request,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to save basic info');
    }

    _circuitBreaker.recordSuccess();

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
    String? city,
    String? country,
    ProfileFavourites? favourites,
    List<String>? showMeGenders,
    double? latitude,
    double? longitude,
  }) async {
    // Sanitize input (matches firebase_profile_repository.dart)
    final sanitizedBio = InputSanitizer.sanitizeBio(bio);
    final sanitizedJobTitle = jobTitle != null
        ? InputSanitizer.sanitizeJobField(jobTitle)
        : null;
    final sanitizedCompany = company != null
        ? InputSanitizer.sanitizeJobField(
            company,
            maxLength: InputSanitizer.maxCompanyLength,
          )
        : null;
    final sanitizedSchool = school != null
        ? InputSanitizer.sanitizeText(
            school,
            maxLength: InputSanitizer.maxSchoolLength,
          )
        : null;
    final sanitizedInterests = InputSanitizer.sanitizeInterests(interests);

    final request = UpdateProfileRequestDto(
      bio: sanitizedBio,
      jobTitle: sanitizedJobTitle,
      company: sanitizedCompany,
      education: sanitizedSchool,
      interests: sanitizedInterests,
    );

    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.profileUpdate,
      dto: request,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(
        result.error?.message ?? 'Failed to save profile details',
      );
    }

    _circuitBreaker.recordSuccess();

    // Upload photos if provided
    for (int i = 0; i < photoUrls.length; i++) {
      final photoUrl = photoUrls[i];
      // Skip if already a remote URL
      if (photoUrl.startsWith('http')) continue;

      await _uploadPhoto(photoUrl, isPrimary: i == 0);
    }

    // Invalidate cache before refreshing user data to get fresh photo urls
    await invalidate(_currentUserCacheKey);

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
    AppLogger.debug(
      'HttpProfileRepository: uploadIdDocument - update interface to accept file path',
    );
  }

  /// Upload an ID document for verification.
  Future<void> uploadIdDocumentFile(String filePath) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final result = await _apiClient.uploadFile<UploadResponseDto>(
      endpoint: '/profile/verify/document',
      file: file,
      fieldName: 'document',
      fields: {'type': 'id_verification'},
      parser: (data) =>
          UploadResponseDto.fromJson(data as Map<String, dynamic>),
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to upload ID document');
    }

    _circuitBreaker.recordSuccess();
  }

  @override
  Future<CrushUser> markIdVerified() async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      '/profile/verify',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to mark ID verified');
    }

    _circuitBreaker.recordSuccess();

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

    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.profileUpdate,
      dto: request,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to update profile');
    }

    _circuitBreaker.recordSuccess();

    // Update preferences if changed
    final prefsDto = ProfileMapper.preferencesToDto(profile.preferences);
    await _apiClient.patch<void>(
      ApiEndpoints.profilePreferences,
      dto: prefsDto,
    );

    await invalidate(_currentUserCacheKey);

    // Refresh user data
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
  }

  /// Update local cache when changing theme since there's no dedicated endpoint.
  @override
  Future<void> updateThemePreference(String preference) async {
    final cachedData = await _store.get<CrushUser>(_currentUserCacheKey);
    if (cachedData != null) {
      final updatedUser = cachedData.data.copyWith(themePreference: preference);
      await _store.put<CrushUser>(
        _currentUserCacheKey,
        updatedUser,
        CacheConfig.standard,
      );
    }
  }

  /// Upload a profile photo.
  ///
  /// Returns the remote URL of the uploaded photo.
  Future<String> _uploadPhoto(
    String localPath, {
    bool isPrimary = false,
  }) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final file = File(localPath);

    if (!await file.exists()) {
      throw Exception('Photo file not found: $localPath');
    }

    final result = await _apiClient.uploadFile<UploadResponseDto>(
      endpoint: ApiEndpoints.profilePhotos,
      file: file,
      fieldName: 'photo',
      fields: {'is_primary': isPrimary.toString()},
      parser: (data) =>
          UploadResponseDto.fromJson(data as Map<String, dynamic>),
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to upload photo');
    }

    _circuitBreaker.recordSuccess();

    final photoUrl = result.data?.url;
    if (photoUrl == null) {
      throw Exception('No photo URL returned from server');
    }

    AppLogger.debug(
      'HttpProfileRepository: Photo uploaded successfully - $photoUrl',
    );
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
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final files = <File>[];
    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Photo file not found: $path');
      }
      files.add(file);
    }

    final result = await _apiClient.uploadFiles<UploadMultipleResponseDto>(
      endpoint: ApiEndpoints.profilePhotos,
      files: files,
      fieldName: 'photos',
      parser: (data) =>
          UploadMultipleResponseDto.fromJson(data as Map<String, dynamic>),
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to upload photos');
    }

    _circuitBreaker.recordSuccess();

    final urls = result.data?.urls;

    if (urls == null || urls.isEmpty) {
      throw Exception('No photo URLs returned from server');
    }

    return urls;
  }

  /// Delete a profile photo.
  Future<void> deletePhoto(String photoId) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _apiClient.delete<void>(
      ApiEndpoints.profilePhotoById(photoId),
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to delete photo');
    }

    _circuitBreaker.recordSuccess();
  }

  /// Reorder profile photos.
  Future<void> reorderPhotos(List<String> photoIds) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _apiClient.post<void>(
      '${ApiEndpoints.profilePhotos}/reorder',
      body: {'photo_ids': photoIds},
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to reorder photos');
    }

    _circuitBreaker.recordSuccess();
  }

  @override
  Future<CrushUser> skipBasicInfo({required String username}) async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      '/profile/skip-basic-info',
      body: {'username': username},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to skip basic info');
    }

    _circuitBreaker.recordSuccess();

    await invalidate(_currentUserCacheKey);

    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
  }

  @override
  Future<CrushUser> skipProfileSetup() async {
    if (!_circuitBreaker.allowRequest()) {
      throw Exception('Service unavailable (Circuit open)');
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      '/profile/skip-setup',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _circuitBreaker.recordFailure();
      throw Exception(result.error?.message ?? 'Failed to skip profile setup');
    }

    _circuitBreaker.recordSuccess();

    await invalidate(_currentUserCacheKey);

    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to retrieve updated user');
    }

    return user;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULT-RETURNING METHODS (CR-AUD-035)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<CrushUser>> saveBasicInfoResult({
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
    return Result.guard(
      () => saveBasicInfo(
        username: username,
        name: name,
        lastName: lastName,
        age: age,
        gender: gender,
        sexualOrientation: sexualOrientation,
        dateOfBirth: dateOfBirth,
        showFirstName: showFirstName,
        showLastName: showLastName,
      ),
      logLabel: 'HttpProfileRepository.saveBasicInfoResult',
    );
  }

  @override
  Future<Result<CrushUser>> saveProfileDetailsResult({
    required String bio,
    required List<String> photoUrls,
    required List<String> videoUrls,
    String? jobTitle,
    String? company,
    String? school,
    required List<String> interests,
    String? city,
    String? country,
    ProfileFavourites? favourites,
    List<String>? showMeGenders,
    double? latitude,
    double? longitude,
  }) async {
    return Result.guard(
      () => saveProfileDetails(
        bio: bio,
        photoUrls: photoUrls,
        videoUrls: videoUrls,
        jobTitle: jobTitle,
        company: company,
        school: school,
        interests: interests,
        city: city,
        country: country,
        favourites: favourites,
        showMeGenders: showMeGenders,
        latitude: latitude,
        longitude: longitude,
      ),
      logLabel: 'HttpProfileRepository.saveProfileDetailsResult',
    );
  }

  @override
  Future<Result<CrushUser>> markIdVerifiedResult() async {
    return Result.guard(
      () => markIdVerified(),
      logLabel: 'HttpProfileRepository.markIdVerifiedResult',
    );
  }

  @override
  Future<Result<CrushUser>> updateProfileResult(Profile profile) async {
    return Result.guard(
      () => updateProfile(profile),
      logLabel: 'HttpProfileRepository.updateProfileResult',
    );
  }

  @override
  Future<Result<CrushUser>> skipBasicInfoResult({
    required String username,
  }) async {
    return Result.guard(
      () => skipBasicInfo(username: username),
      logLabel: 'HttpProfileRepository.skipBasicInfoResult',
    );
  }

  @override
  Future<Result<CrushUser>> skipProfileSetupResult() async {
    return Result.guard(
      () => skipProfileSetup(),
      logLabel: 'HttpProfileRepository.skipProfileSetupResult',
    );
  }
}
