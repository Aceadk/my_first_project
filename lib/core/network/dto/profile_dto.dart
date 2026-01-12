import 'base_dto.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE DTOs
// ═══════════════════════════════════════════════════════════════════════════

/// Full profile DTO.
class ProfileDto extends BaseDto with DtoMetadata {
  const ProfileDto({
    required this.id,
    this.displayName,
    this.bio,
    this.birthDate,
    this.gender,
    this.interestedIn,
    this.photos,
    this.location,
    this.height,
    this.jobTitle,
    this.company,
    this.education,
    this.livingIn,
    this.hometown,
    this.languages,
    this.interests,
    this.relationshipGoals,
    this.drinkingHabit,
    this.smokingHabit,
    this.exerciseHabit,
    this.dietaryPreference,
    this.zodiacSign,
    this.personalityType,
    this.lovingLanguage,
    this.communicationStyle,
    this.pets,
    this.isVerified,
    this.isPremium,
    this.profileCompleteness,
    this.lastActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? displayName;
  final String? bio;
  final DateTime? birthDate;
  final String? gender;
  final List<String>? interestedIn;
  final List<ProfilePhotoDto>? photos;
  final LocationDto? location;
  final int? height;
  final String? jobTitle;
  final String? company;
  final String? education;
  final String? livingIn;
  final String? hometown;
  final List<String>? languages;
  final List<String>? interests;
  final String? relationshipGoals;
  final String? drinkingHabit;
  final String? smokingHabit;
  final String? exerciseHabit;
  final String? dietaryPreference;
  final String? zodiacSign;
  final String? personalityType;
  final String? lovingLanguage;
  final String? communicationStyle;
  final String? pets;
  final bool? isVerified;
  final bool? isPremium;
  final double? profileCompleteness;
  final DateTime? lastActive;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String? get serverId => id;

  /// Calculate age from birthdate.
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Get primary photo URL.
  String? get primaryPhotoUrl {
    if (photos == null || photos!.isEmpty) return null;
    return photos!.firstWhere((p) => p.isPrimary ?? false, orElse: () => photos!.first).url;
  }

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    return ProfileDto(
      id: json.getString('id') ?? '',
      displayName: json.getString('display_name'),
      bio: json.getString('bio'),
      birthDate: json.getDateTime('birth_date'),
      gender: json.getString('gender'),
      interestedIn: json.getList('interested_in', (e) => e.toString()),
      photos: json.getList('photos', (e) => ProfilePhotoDto.fromJson(e as Map<String, dynamic>)),
      location: json.getMap('location') != null ? LocationDto.fromJson(json.getMap('location')!) : null,
      height: json.getInt('height'),
      jobTitle: json.getString('job_title'),
      company: json.getString('company'),
      education: json.getString('education'),
      livingIn: json.getString('living_in'),
      hometown: json.getString('hometown'),
      languages: json.getList('languages', (e) => e.toString()),
      interests: json.getList('interests', (e) => e.toString()),
      relationshipGoals: json.getString('relationship_goals'),
      drinkingHabit: json.getString('drinking_habit'),
      smokingHabit: json.getString('smoking_habit'),
      exerciseHabit: json.getString('exercise_habit'),
      dietaryPreference: json.getString('dietary_preference'),
      zodiacSign: json.getString('zodiac_sign'),
      personalityType: json.getString('personality_type'),
      lovingLanguage: json.getString('loving_language'),
      communicationStyle: json.getString('communication_style'),
      pets: json.getString('pets'),
      isVerified: json.getBool('is_verified'),
      isPremium: json.getBool('is_premium'),
      profileCompleteness: json.getDouble('profile_completeness'),
      lastActive: json.getDateTime('last_active'),
      createdAt: json.getDateTime('created_at'),
      updatedAt: json.getDateTime('updated_at'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        if (displayName != null) 'display_name': displayName,
        if (bio != null) 'bio': bio,
        if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
        if (gender != null) 'gender': gender,
        if (interestedIn != null) 'interested_in': interestedIn,
        if (photos != null) 'photos': photos!.map((p) => p.toJson()).toList(),
        if (location != null) 'location': location!.toJson(),
        if (height != null) 'height': height,
        if (jobTitle != null) 'job_title': jobTitle,
        if (company != null) 'company': company,
        if (education != null) 'education': education,
        if (livingIn != null) 'living_in': livingIn,
        if (hometown != null) 'hometown': hometown,
        if (languages != null) 'languages': languages,
        if (interests != null) 'interests': interests,
        if (relationshipGoals != null) 'relationship_goals': relationshipGoals,
        if (drinkingHabit != null) 'drinking_habit': drinkingHabit,
        if (smokingHabit != null) 'smoking_habit': smokingHabit,
        if (exerciseHabit != null) 'exercise_habit': exerciseHabit,
        if (dietaryPreference != null) 'dietary_preference': dietaryPreference,
        if (zodiacSign != null) 'zodiac_sign': zodiacSign,
        if (personalityType != null) 'personality_type': personalityType,
        if (lovingLanguage != null) 'loving_language': lovingLanguage,
        if (communicationStyle != null) 'communication_style': communicationStyle,
        if (pets != null) 'pets': pets,
        if (isVerified != null) 'is_verified': isVerified,
        if (isPremium != null) 'is_premium': isPremium,
        if (profileCompleteness != null) 'profile_completeness': profileCompleteness,
        if (lastActive != null) 'last_active': lastActive!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Create a copy with updated fields.
  ProfileDto copyWith({
    String? displayName,
    String? bio,
    DateTime? birthDate,
    String? gender,
    List<String>? interestedIn,
    List<ProfilePhotoDto>? photos,
    LocationDto? location,
    int? height,
    String? jobTitle,
    String? company,
    String? education,
    String? livingIn,
    String? hometown,
    List<String>? languages,
    List<String>? interests,
    String? relationshipGoals,
  }) {
    return ProfileDto(
      id: id,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      height: height ?? this.height,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      education: education ?? this.education,
      livingIn: livingIn ?? this.livingIn,
      hometown: hometown ?? this.hometown,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      relationshipGoals: relationshipGoals ?? this.relationshipGoals,
      drinkingHabit: drinkingHabit,
      smokingHabit: smokingHabit,
      exerciseHabit: exerciseHabit,
      dietaryPreference: dietaryPreference,
      zodiacSign: zodiacSign,
      personalityType: personalityType,
      lovingLanguage: lovingLanguage,
      communicationStyle: communicationStyle,
      pets: pets,
      isVerified: isVerified,
      isPremium: isPremium,
      profileCompleteness: profileCompleteness,
      lastActive: lastActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Profile photo DTO.
class ProfilePhotoDto extends BaseDto {
  const ProfilePhotoDto({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.isPrimary,
    this.order,
    this.isVerified,
    this.createdAt,
  });

  final String id;
  final String url;
  final String? thumbnailUrl;
  final bool? isPrimary;
  final int? order;
  final bool? isVerified;
  final DateTime? createdAt;

  factory ProfilePhotoDto.fromJson(Map<String, dynamic> json) {
    return ProfilePhotoDto(
      id: json.getString('id') ?? '',
      url: json.getString('url') ?? '',
      thumbnailUrl: json.getString('thumbnail_url'),
      isPrimary: json.getBool('is_primary'),
      order: json.getInt('order'),
      isVerified: json.getBool('is_verified'),
      createdAt: json.getDateTime('created_at'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (isPrimary != null) 'is_primary': isPrimary,
        if (order != null) 'order': order,
        if (isVerified != null) 'is_verified': isVerified,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

/// Location DTO.
class LocationDto extends BaseDto {
  const LocationDto({
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.countryCode,
  });

  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? countryCode;

  /// Get display string for location.
  String get displayString {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  factory LocationDto.fromJson(Map<String, dynamic> json) {
    return LocationDto(
      latitude: json.getDouble('latitude'),
      longitude: json.getDouble('longitude'),
      city: json.getString('city'),
      state: json.getString('state'),
      country: json.getString('country'),
      countryCode: json.getString('country_code'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        if (countryCode != null) 'country_code': countryCode,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE UPDATE REQUEST
// ═══════════════════════════════════════════════════════════════════════════

/// Request to update profile.
class UpdateProfileRequestDto extends BaseDto {
  const UpdateProfileRequestDto({
    this.displayName,
    this.bio,
    this.birthDate,
    this.gender,
    this.interestedIn,
    this.height,
    this.jobTitle,
    this.company,
    this.education,
    this.livingIn,
    this.hometown,
    this.languages,
    this.interests,
    this.relationshipGoals,
    this.drinkingHabit,
    this.smokingHabit,
    this.exerciseHabit,
    this.dietaryPreference,
    this.zodiacSign,
    this.personalityType,
    this.lovingLanguage,
    this.communicationStyle,
    this.pets,
  });

  final String? displayName;
  final String? bio;
  final DateTime? birthDate;
  final String? gender;
  final List<String>? interestedIn;
  final int? height;
  final String? jobTitle;
  final String? company;
  final String? education;
  final String? livingIn;
  final String? hometown;
  final List<String>? languages;
  final List<String>? interests;
  final String? relationshipGoals;
  final String? drinkingHabit;
  final String? smokingHabit;
  final String? exerciseHabit;
  final String? dietaryPreference;
  final String? zodiacSign;
  final String? personalityType;
  final String? lovingLanguage;
  final String? communicationStyle;
  final String? pets;

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (displayName != null) json['display_name'] = displayName;
    if (bio != null) json['bio'] = bio;
    if (birthDate != null) json['birth_date'] = birthDate!.toIso8601String();
    if (gender != null) json['gender'] = gender;
    if (interestedIn != null) json['interested_in'] = interestedIn;
    if (height != null) json['height'] = height;
    if (jobTitle != null) json['job_title'] = jobTitle;
    if (company != null) json['company'] = company;
    if (education != null) json['education'] = education;
    if (livingIn != null) json['living_in'] = livingIn;
    if (hometown != null) json['hometown'] = hometown;
    if (languages != null) json['languages'] = languages;
    if (interests != null) json['interests'] = interests;
    if (relationshipGoals != null) json['relationship_goals'] = relationshipGoals;
    if (drinkingHabit != null) json['drinking_habit'] = drinkingHabit;
    if (smokingHabit != null) json['smoking_habit'] = smokingHabit;
    if (exerciseHabit != null) json['exercise_habit'] = exerciseHabit;
    if (dietaryPreference != null) json['dietary_preference'] = dietaryPreference;
    if (zodiacSign != null) json['zodiac_sign'] = zodiacSign;
    if (personalityType != null) json['personality_type'] = personalityType;
    if (lovingLanguage != null) json['loving_language'] = lovingLanguage;
    if (communicationStyle != null) json['communication_style'] = communicationStyle;
    if (pets != null) json['pets'] = pets;
    return json;
  }

  @override
  String? validate() {
    final validator = DtoValidator();

    if (displayName != null) {
      validator.requireMinLength(displayName, 2, 'display_name');
    }

    if (bio != null) {
      validator.require(bio!.length <= 500, 'bio', 'Bio must be 500 characters or less');
    }

    if (height != null) {
      validator.requireRange(height, 100, 250, 'height');
    }

    return validator.build().firstError;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DISCOVERY PREFERENCES
// ═══════════════════════════════════════════════════════════════════════════

/// Discovery preferences DTO.
class DiscoveryPreferencesDto extends BaseDto {
  const DiscoveryPreferencesDto({
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.distanceUnit,
    this.genderPreferences,
    this.showMe,
    this.globalMode,
  });

  final int? minAge;
  final int? maxAge;
  final int? maxDistance;
  final String? distanceUnit;
  final List<String>? genderPreferences;
  final bool? showMe;
  final bool? globalMode;

  factory DiscoveryPreferencesDto.fromJson(Map<String, dynamic> json) {
    return DiscoveryPreferencesDto(
      minAge: json.getInt('min_age'),
      maxAge: json.getInt('max_age'),
      maxDistance: json.getInt('max_distance'),
      distanceUnit: json.getString('distance_unit'),
      genderPreferences: json.getList('gender_preferences', (e) => e.toString()),
      showMe: json.getBool('show_me'),
      globalMode: json.getBool('global_mode'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (minAge != null) 'min_age': minAge,
        if (maxAge != null) 'max_age': maxAge,
        if (maxDistance != null) 'max_distance': maxDistance,
        if (distanceUnit != null) 'distance_unit': distanceUnit,
        if (genderPreferences != null) 'gender_preferences': genderPreferences,
        if (showMe != null) 'show_me': showMe,
        if (globalMode != null) 'global_mode': globalMode,
      };

  @override
  String? validate() {
    return DtoValidator()
        .requireRange(minAge, 18, 99, 'min_age')
        .requireRange(maxAge, 18, 99, 'max_age')
        .require(
          minAge == null || maxAge == null || minAge! <= maxAge!,
          'age_range',
          'Minimum age must be less than maximum age',
        )
        .requireRange(maxDistance, 1, 500, 'max_distance')
        .build()
        .firstError;
  }
}
