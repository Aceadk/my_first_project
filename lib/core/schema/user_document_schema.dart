/// Canonical user document schema uses nested `profile.*` fields.
///
/// Legacy data may still contain flat top-level profile fields and mirrors
/// such as `preferences`, `privacySettings`, and `favourites`.
const List<String> kLegacyFlatProfileScalarKeys = [
  'name',
  'lastName',
  'age',
  'gender',
  'sexualOrientation',
  'birthDate',
  'dateOfBirth',
  'lastDobChangeAt',
  'lastNameChangeAt',
  'bio',
  'photoUrls',
  'videoUrls',
  'primaryPhotoIndex',
  'interests',
  'country',
  'city',
  'latitude',
  'longitude',
  'livingIn',
  'isVerified',
  'heightCm',
  'relationshipGoals',
  'languages',
  'zodiacSign',
  'educationLevel',
  'familyPlans',
  'personalityType',
  'religion',
  'workout',
  'socialMedia',
  'sleepingHabits',
  'smoking',
  'drinking',
  'pets',
  'favoriteSongs',
  'favoriteSinger',
  'jobTitle',
  'company',
  'school',
];

const Map<String, String> kLegacyFlatProfileScalarKeyAliases = {
  // Canonical nested profile key is `birthDate`.
  'dateOfBirth': 'birthDate',
};

const Map<String, String> kLegacyWebFlatProfileScalarKeyAliases = {
  'displayName': 'name',
  'photos': 'photoUrls',
};

const Map<String, String> kLegacyWebLocationKeyAliases = {
  'latitude': 'latitude',
  'longitude': 'longitude',
  'city': 'city',
  'country': 'country',
};

const List<String> kLegacyFlatProfileObjectKeys = [
  'preferences',
  'privacySettings',
  'favourites',
];

Map<String, dynamic> _asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

bool _hasMapContent(dynamic value) => _asStringDynamicMap(value).isNotEmpty;

bool _isNonEmptyList(dynamic value) => value is List && value.isNotEmpty;

class UserDocumentCanonicalizationResult {
  const UserDocumentCanonicalizationResult({
    required this.canonicalUserData,
    required this.canonicalProfile,
    required this.legacyRootKeysToDelete,
    required this.hasLegacyData,
    required this.shouldPersistMigration,
  });

  final Map<String, dynamic> canonicalUserData;
  final Map<String, dynamic> canonicalProfile;
  final Set<String> legacyRootKeysToDelete;
  final bool hasLegacyData;
  final bool shouldPersistMigration;
}

/// Normalizes a user document into canonical nested `profile.*` shape.
///
/// This does not write to Firestore directly. Callers can use
/// `legacyRootKeysToDelete` to clean root legacy keys during persistence.
UserDocumentCanonicalizationResult canonicalizeUserDocumentSchema(
  Map<String, dynamic> userData,
) {
  final originalProfile = _asStringDynamicMap(userData['profile']);
  final hasLegacyNestedDateOfBirth = originalProfile.containsKey('dateOfBirth');
  final canonicalUserData = Map<String, dynamic>.from(userData);
  final profile = _asStringDynamicMap(canonicalUserData['profile']);
  final hasProfileMap = canonicalUserData['profile'] is Map;
  var migratedProfileFields = false;
  final keysToDelete = <String>{};

  for (final key in kLegacyFlatProfileScalarKeys) {
    if (!userData.containsKey(key)) continue;
    final targetKey = kLegacyFlatProfileScalarKeyAliases[key] ?? key;
    final legacyValue = userData[key];
    if (legacyValue != null && !profile.containsKey(targetKey)) {
      profile[targetKey] = legacyValue;
      migratedProfileFields = true;
    }
    if (profile.containsKey(targetKey) || legacyValue == null) {
      keysToDelete.add(key);
    }
  }

  for (final key in kLegacyFlatProfileObjectKeys) {
    if (!userData.containsKey(key)) continue;
    final legacyMap = _asStringDynamicMap(userData[key]);
    if (legacyMap.isNotEmpty && !_hasMapContent(profile[key])) {
      profile[key] = legacyMap;
      migratedProfileFields = true;
    }
    if (_hasMapContent(profile[key]) || legacyMap.isEmpty) {
      keysToDelete.add(key);
    }
  }

  for (final entry in kLegacyWebFlatProfileScalarKeyAliases.entries) {
    final legacyValue = userData[entry.key];
    if (legacyValue == null || profile.containsKey(entry.value)) continue;
    profile[entry.value] = legacyValue;
    migratedProfileFields = true;
  }

  final legacyLocation = _asStringDynamicMap(userData['location']);
  for (final entry in kLegacyWebLocationKeyAliases.entries) {
    final legacyValue = legacyLocation[entry.key];
    if (legacyValue == null || profile.containsKey(entry.value)) continue;
    profile[entry.value] = legacyValue;
    migratedProfileFields = true;
  }

  final existingPreferences = _asStringDynamicMap(profile['preferences']);
  var migratedPreferenceFields = false;
  final legacyInterestedIn = userData['interestedIn'];
  if (_isNonEmptyList(legacyInterestedIn) &&
      !existingPreferences.containsKey('showMeGenders')) {
    existingPreferences['showMeGenders'] = legacyInterestedIn;
    migratedPreferenceFields = true;
  }

  final legacySettings = _asStringDynamicMap(userData['settings']);
  if (legacySettings.isNotEmpty) {
    final preferenceAliases = <String, String>{
      'maxDistance': 'maxDistanceKm',
      'ageRangeMin': 'minAge',
      'ageRangeMax': 'maxAge',
      'showDistance': 'showMyDistance',
      'showAge': 'showMyAge',
      'incognitoMode': 'incognitoMode',
    };

    for (final entry in preferenceAliases.entries) {
      if (!legacySettings.containsKey(entry.key) ||
          existingPreferences.containsKey(entry.value)) {
        continue;
      }
      existingPreferences[entry.value] = legacySettings[entry.key];
      migratedPreferenceFields = true;
    }
  }

  if (migratedPreferenceFields) {
    profile['preferences'] = existingPreferences;
    migratedProfileFields = true;
  }

  if (profile.containsKey('dateOfBirth')) {
    final legacyNestedDob = profile['dateOfBirth'];
    if (legacyNestedDob != null && !profile.containsKey('birthDate')) {
      profile['birthDate'] = legacyNestedDob;
    }
    profile.remove('dateOfBirth');
    migratedProfileFields = true;
  }

  if (profile.isNotEmpty) {
    canonicalUserData['profile'] = profile;
  }

  final hasLegacyData =
      kLegacyFlatProfileScalarKeys.any(userData.containsKey) ||
      kLegacyFlatProfileObjectKeys.any(userData.containsKey) ||
      kLegacyWebFlatProfileScalarKeyAliases.keys.any(userData.containsKey) ||
      userData.containsKey('location') ||
      userData.containsKey('interestedIn') ||
      userData.containsKey('settings') ||
      hasLegacyNestedDateOfBirth;

  final shouldPersistMigration =
      migratedProfileFields ||
      (!hasProfileMap && profile.isNotEmpty) ||
      keysToDelete.isNotEmpty;

  return UserDocumentCanonicalizationResult(
    canonicalUserData: canonicalUserData,
    canonicalProfile: profile,
    legacyRootKeysToDelete: keysToDelete,
    hasLegacyData: hasLegacyData,
    shouldPersistMigration: shouldPersistMigration,
  );
}
