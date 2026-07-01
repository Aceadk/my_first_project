import 'package:crushhour/core/schema/user_document_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonicalizeUserDocumentSchema', () {
    test('migrates flat profile fields into nested profile', () {
      final result = canonicalizeUserDocumentSchema({
        'name': 'Alex',
        'age': 29,
        'gender': 'female',
        'bio': 'Hello there',
        'dateOfBirth': '1996-05-10T00:00:00.000Z',
        'preferences': {'minAge': 24, 'maxAge': 35},
        'privacySettings': {'isProfileVisible': true},
        'favourites': {'favoriteFood': 'Pizza'},
      });

      final profile =
          result.canonicalUserData['profile'] as Map<String, dynamic>;
      expect(profile['name'], 'Alex');
      expect(profile['age'], 29);
      expect(profile['gender'], 'female');
      expect(profile['bio'], 'Hello there');
      expect(profile['birthDate'], '1996-05-10T00:00:00.000Z');
      expect(profile.containsKey('dateOfBirth'), isFalse);
      expect(profile['preferences'], {'minAge': 24, 'maxAge': 35});
      expect(profile['privacySettings'], {'isProfileVisible': true});
      expect(profile['favourites'], {'favoriteFood': 'Pizza'});

      expect(result.hasLegacyData, isTrue);
      expect(result.shouldPersistMigration, isTrue);
      expect(
        result.legacyRootKeysToDelete,
        containsAll([
          'name',
          'age',
          'gender',
          'bio',
          'dateOfBirth',
          'preferences',
          'privacySettings',
          'favourites',
        ]),
      );
    });

    test('normalizes nested dateOfBirth into canonical birthDate', () {
      final result = canonicalizeUserDocumentSchema({
        'profile': {
          'name': 'Taylor',
          'dateOfBirth': '1998-02-14T00:00:00.000Z',
        },
      });

      final profile =
          result.canonicalUserData['profile'] as Map<String, dynamic>;
      expect(profile['birthDate'], '1998-02-14T00:00:00.000Z');
      expect(profile.containsKey('dateOfBirth'), isFalse);
      expect(result.hasLegacyData, isTrue);
      expect(result.shouldPersistMigration, isTrue);
    });

    test('keeps existing nested preferences and deletes legacy mirror key', () {
      final result = canonicalizeUserDocumentSchema({
        'profile': {
          'name': 'Jamie',
          'preferences': {'minAge': 21, 'maxAge': 32},
        },
        'preferences': {'minAge': 18, 'maxAge': 60},
      });

      final profile =
          result.canonicalUserData['profile'] as Map<String, dynamic>;
      expect(profile['preferences'], {'minAge': 21, 'maxAge': 32});
      expect(result.legacyRootKeysToDelete, contains('preferences'));
      expect(result.shouldPersistMigration, isTrue);
    });

    test('returns no migration work for canonical user documents', () {
      final result = canonicalizeUserDocumentSchema({
        'profile': {
          'name': 'Morgan',
          'age': 30,
          'gender': 'female',
          'preferences': {'minAge': 26, 'maxAge': 36},
        },
        'plan': 'free',
      });

      expect(result.hasLegacyData, isFalse);
      expect(result.shouldPersistMigration, isFalse);
      expect(result.legacyRootKeysToDelete, isEmpty);
    });

    test('canonicalizes flat web profile fields into nested profile data', () {
      final result = canonicalizeUserDocumentSchema({
        'displayName': 'Avery Web',
        'birthDate': '1997-06-15T00:00:00.000Z',
        'gender': 'female',
        'photos': ['https://img.example.com/avery.jpg'],
        'location': {
          'city': 'Austin',
          'country': 'US',
          'latitude': 30.2672,
          'longitude': -97.7431,
        },
        'interestedIn': ['male'],
        'settings': {
          'maxDistance': 75,
          'ageRangeMin': 24,
          'ageRangeMax': 36,
          'showDistance': true,
          'showAge': true,
          'incognitoMode': false,
        },
      });

      final profile =
          result.canonicalUserData['profile'] as Map<String, dynamic>;
      final preferences = profile['preferences'] as Map<String, dynamic>;

      expect(profile['name'], 'Avery Web');
      expect(profile['photoUrls'], ['https://img.example.com/avery.jpg']);
      expect(profile['city'], 'Austin');
      expect(profile['country'], 'US');
      expect(profile['latitude'], 30.2672);
      expect(profile['longitude'], -97.7431);
      expect(preferences['showMeGenders'], ['male']);
      expect(preferences['maxDistanceKm'], 75);
      expect(preferences['minAge'], 24);
      expect(preferences['maxAge'], 36);
      expect(preferences['showMyDistance'], isTrue);
      expect(preferences['showMyAge'], isTrue);
      expect(preferences['incognitoMode'], isFalse);
      expect(result.hasLegacyData, isTrue);
      expect(result.shouldPersistMigration, isTrue);
      expect(
        result.legacyRootKeysToDelete,
        containsAll(['birthDate', 'gender']),
      );
    });

    test('migrates a legacy single display photo when no gallery exists', () {
      final result = canonicalizeUserDocumentSchema({
        'displayName': 'Legacy User',
        'profilePhotoUrl': ' https://img.example.com/legacy.jpg ',
      });

      expect(result.canonicalProfile['photoUrls'], [
        'https://img.example.com/legacy.jpg',
      ]);
      expect(result.canonicalProfile['primaryPhotoIndex'], 0);
      expect(result.shouldPersistMigration, isTrue);
    });

    test('canonical nested photo list wins over stale root photo mirrors', () {
      final result = canonicalizeUserDocumentSchema({
        'photos': ['https://img.example.com/stale-list.jpg'],
        'profilePhotoUrl': 'https://img.example.com/stale-display.jpg',
        'profile': {
          'photoUrls': ['https://img.example.com/canonical.jpg'],
          'primaryPhotoIndex': 0,
        },
      });

      expect(result.canonicalProfile['photoUrls'], [
        'https://img.example.com/canonical.jpg',
      ]);
      expect(result.canonicalProfile['primaryPhotoIndex'], 0);
    });
  });
}
