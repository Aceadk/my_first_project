import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/favourites.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileSaveRequested extends ProfileEvent {
  final Profile profile;

  ProfileSaveRequested({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileBasicInfoSubmitted extends ProfileEvent {
  final String? username;
  final String name;
  final String? lastName;
  final int age;
  final String gender;
  final String? sexualOrientation;
  final DateTime? dateOfBirth;
  final bool? showFirstName;
  final bool? showLastName;

  ProfileBasicInfoSubmitted({
    this.username,
    required this.name,
    this.lastName,
    required this.age,
    required this.gender,
    this.sexualOrientation,
    this.dateOfBirth,
    this.showFirstName,
    this.showLastName,
  });

  @override
  List<Object?> get props => [
    username,
    name,
    lastName,
    age,
    gender,
    sexualOrientation,
    dateOfBirth,
    showFirstName,
    showLastName,
  ];
}

class ProfileDetailsSubmitted extends ProfileEvent {
  final String bio;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final String? jobTitle;
  final String? company;
  final String? school;
  final List<String> interests;
  final String? city;
  final String? country;
  final ProfileFavourites? favourites;
  final List<String>? showMeGenders; // Who to show in deck
  final double? latitude; // For discovery distance filtering
  final double? longitude; // For discovery distance filtering

  ProfileDetailsSubmitted({
    required this.bio,
    required this.photoUrls,
    required this.videoUrls,
    this.jobTitle,
    this.company,
    this.school,
    required this.interests,
    this.city,
    this.country,
    this.favourites,
    this.showMeGenders,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
    bio,
    photoUrls,
    videoUrls,
    jobTitle,
    company,
    school,
    interests,
    city,
    country,
    favourites,
    showMeGenders,
    latitude,
    longitude,
  ];
}

class ProfileIdDocumentUploaded extends ProfileEvent {}

class ProfileIdVerifiedMarked extends ProfileEvent {}

/// Event to update the user's location in their profile.
class ProfileLocationUpdateRequested extends ProfileEvent {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  ProfileLocationUpdateRequested({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  @override
  List<Object?> get props => [latitude, longitude, city, country];
}

/// Event to skip basic info setup (only username is required).
class ProfileBasicInfoSkipped extends ProfileEvent {
  final String username;

  ProfileBasicInfoSkipped({required this.username});

  @override
  List<Object?> get props => [username];
}

/// Event to skip profile setup entirely.
class ProfileSetupSkipped extends ProfileEvent {}

/// Event to reset profile state on logout.
/// CRITICAL: Prevents data leakage to next user.
class ProfileResetRequested extends ProfileEvent {}
