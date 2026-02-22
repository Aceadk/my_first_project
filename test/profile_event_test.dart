import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:flutter_test/flutter_test.dart';

const _prefs = DiscoveryPreferences(
  minAge: 18,
  maxAge: 40,
  maxDistanceKm: 80,
  showMeGenders: ['female'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'US',
  city: 'New York',
);

const _profile = Profile(
  id: 'user-1',
  username: 'johnny',
  name: 'John',
  lastName: 'Doe',
  age: 29,
  gender: 'male',
  photoUrls: ['https://example.com/p1.jpg'],
  videoUrls: ['https://example.com/v1.mp4'],
  bio: 'Test bio',
  interests: ['music', 'travel'],
  country: 'US',
  city: 'New York',
  isVerified: false,
  preferences: _prefs,
);

void main() {
  group('ProfileEvent', () {
    test('base event exposes empty props', () {
      expect(ProfileLoadRequested().props, isEmpty);
    });

    test('load/save events are equatable and include profile in props', () {
      expect(ProfileLoadRequested(), equals(ProfileLoadRequested()));

      final saveA = ProfileSaveRequested(profile: _profile);
      final saveB = ProfileSaveRequested(profile: _profile);

      expect(saveA, equals(saveB));
      expect(saveA.props, equals([_profile]));
    });

    test('basic info event includes all optional and required fields', () {
      final dob = DateTime.utc(1995, 6, 10);
      final event = ProfileBasicInfoSubmitted(
        username: 'johnny',
        name: 'John',
        lastName: 'Doe',
        age: 29,
        gender: 'male',
        sexualOrientation: 'straight',
        dateOfBirth: dob,
        showFirstName: true,
        showLastName: false,
      );

      expect(
        event.props,
        equals([
          'johnny',
          'John',
          'Doe',
          29,
          'male',
          'straight',
          dob,
          true,
          false,
        ]),
      );
    });

    test('details event includes profile details and location fields', () {
      const favourites = ProfileFavourites(food: 'Pizza', movie: 'Inception');
      final event = ProfileDetailsSubmitted(
        bio: 'Updated bio',
        photoUrls: const ['https://example.com/p2.jpg'],
        videoUrls: const ['https://example.com/v2.mp4'],
        jobTitle: 'Engineer',
        company: 'Crush',
        school: 'State University',
        interests: const ['fitness', 'coding'],
        city: 'Austin',
        country: 'US',
        favourites: favourites,
        showMeGenders: const ['female', 'male'],
        latitude: 30.2672,
        longitude: -97.7431,
      );

      expect(
        event.props,
        equals([
          'Updated bio',
          const ['https://example.com/p2.jpg'],
          const ['https://example.com/v2.mp4'],
          'Engineer',
          'Crush',
          'State University',
          const ['fitness', 'coding'],
          'Austin',
          'US',
          favourites,
          const ['female', 'male'],
          30.2672,
          -97.7431,
        ]),
      );
    });

    test('id verification marker events are equatable', () {
      expect(ProfileIdDocumentUploaded(), equals(ProfileIdDocumentUploaded()));
      expect(ProfileIdVerifiedMarked(), equals(ProfileIdVerifiedMarked()));
    });

    test('location update event stores coordinates and place values', () {
      final event = ProfileLocationUpdateRequested(
        latitude: 40.7128,
        longitude: -74.0060,
        city: 'New York',
        country: 'US',
      );

      expect(event.props, equals([40.7128, -74.006, 'New York', 'US']));
    });

    test('skip and reset events are equatable with expected props', () {
      final skipBasic = ProfileBasicInfoSkipped(username: 'johnny');
      expect(skipBasic.props, equals(['johnny']));

      expect(ProfileSetupSkipped(), equals(ProfileSetupSkipped()));
      expect(ProfileResetRequested(), equals(ProfileResetRequested()));
    });
  });
}
