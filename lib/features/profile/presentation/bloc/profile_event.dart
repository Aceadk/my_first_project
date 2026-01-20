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
  final int age;
  final String gender;
  final String? sexualOrientation;
  final DateTime? dateOfBirth;

  ProfileBasicInfoSubmitted({
    this.username,
    required this.name,
    required this.age,
    required this.gender,
    this.sexualOrientation,
    this.dateOfBirth,
  });

  @override
  List<Object?> get props => [username, name, age, gender, sexualOrientation, dateOfBirth];
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
  });

  @override
  List<Object?> get props =>
      [bio, photoUrls, videoUrls, jobTitle, company, school, interests, city, country, favourites];
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
