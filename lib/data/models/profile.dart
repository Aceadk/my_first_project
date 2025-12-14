import 'package:equatable/equatable.dart';
import 'preferences.dart';

class Profile extends Equatable {
  final String id; // Firestore user document ID
  final String name;
  final int age;
  final String gender;
  final String? sexualOrientation;
  final String bio;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final bool isVerified;
  final String? jobTitle;
  final String? company;
  final String? school;
  final List<String> interests;
  final List<String> prompts;
  final String country;
  final String city;
  final double? latitude;
  final double? longitude;
  final DiscoveryPreferences preferences;

  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.sexualOrientation,
    required this.bio,
    required this.photoUrls,
    required this.videoUrls,
    required this.isVerified,
    required this.jobTitle,
    required this.company,
    required this.school,
    required this.interests,
    this.prompts = const [],
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.preferences,
  });

  Profile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? sexualOrientation,
    String? bio,
    List<String>? photoUrls,
    List<String>? videoUrls,
    bool? isVerified,
    String? jobTitle,
    String? company,
    String? school,
    List<String>? interests,
    List<String>? prompts,
    String? country,
    String? city,
    double? latitude,
    double? longitude,
    DiscoveryPreferences? preferences,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      bio: bio ?? this.bio,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      isVerified: isVerified ?? this.isVerified,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      school: school ?? this.school,
      interests: interests ?? this.interests,
      prompts: prompts ?? this.prompts,
      country: country ?? this.country,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        gender,
        sexualOrientation,
        bio,
        photoUrls,
        videoUrls,
        isVerified,
        jobTitle,
        company,
        school,
        interests,
        prompts,
        country,
        city,
        latitude,
        longitude,
        preferences,
      ];
}
