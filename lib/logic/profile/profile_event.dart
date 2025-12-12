import 'package:equatable/equatable.dart';
import '../../data/models/profile.dart';

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
  final String name;
  final int age;
  final String gender;
  final String? sexualOrientation;

  ProfileBasicInfoSubmitted({
    required this.name,
    required this.age,
    required this.gender,
    this.sexualOrientation,
  });

  @override
  List<Object?> get props => [name, age, gender, sexualOrientation];
}

class ProfileDetailsSubmitted extends ProfileEvent {
  final String bio;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final String? jobTitle;
  final String? company;
  final String? school;
  final List<String> interests;

  ProfileDetailsSubmitted({
    required this.bio,
    required this.photoUrls,
    required this.videoUrls,
    this.jobTitle,
    this.company,
    this.school,
    required this.interests,
  });

  @override
  List<Object?> get props =>
      [bio, photoUrls, videoUrls, jobTitle, company, school, interests];
}

class ProfileIdDocumentUploaded extends ProfileEvent {}

class ProfileIdVerifiedMarked extends ProfileEvent {}
