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
  });
}
