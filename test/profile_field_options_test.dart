import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/shared/utils/profile_field_options.dart';

void main() {
  group('ProfileFieldOptions', () {
    test('returns formatted labels for known values', () {
      expect(
        ProfileFieldOptions.getRelationshipGoalLabel('long_term'),
        contains('Long-term partner'),
      );
      expect(
        ProfileFieldOptions.getEducationLabel('masters'),
        contains('Master'),
      );
      expect(
        ProfileFieldOptions.getFamilyPlanLabel('want'),
        contains('I want children'),
      );
      expect(
        ProfileFieldOptions.getPersonalityLabel('intj'),
        equals('INTJ - The Architect'),
      );
      expect(
        ProfileFieldOptions.getWorkoutLabel('everyday'),
        contains('Everyday'),
      );
      expect(
        ProfileFieldOptions.getSocialMediaLabel('active'),
        contains('Socially active'),
      );
      expect(
        ProfileFieldOptions.getSleepingLabel('night_owl'),
        contains('Night owl'),
      );
      expect(
        ProfileFieldOptions.getSmokingLabel('regular'),
        contains('Regular smoker'),
      );
      expect(
        ProfileFieldOptions.getDrinkingLabel('socially'),
        contains('Socially'),
      );
      expect(ProfileFieldOptions.getPetLabel('dog'), contains('Dog'));
      expect(ProfileFieldOptions.getZodiacLabel('leo'), contains('Leo'));
      expect(ProfileFieldOptions.getReligionLabel('hindu'), contains('Hindu'));
      expect(ProfileFieldOptions.getGenderLabel('female'), equals('Female'));
      expect(
        ProfileFieldOptions.getSexualOrientationLabel('bisexual'),
        equals('Bisexual'),
      );
      expect(
        ProfileFieldOptions.getLookingForLabel('female'),
        contains('Women'),
      );
    });

    test('returns null for unknown or null values', () {
      expect(ProfileFieldOptions.getRelationshipGoalLabel(null), isNull);
      expect(ProfileFieldOptions.getEducationLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getFamilyPlanLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getPersonalityLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getWorkoutLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getSocialMediaLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getSleepingLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getSmokingLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getDrinkingLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getPetLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getZodiacLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getReligionLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getGenderLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getSexualOrientationLabel('unknown'), isNull);
      expect(ProfileFieldOptions.getLookingForLabel('unknown'), isNull);
    });

    test('converts looking-for values and defaults correctly', () {
      expect(
        ProfileFieldOptions.getDefaultLookingFor('male'),
        equals('female'),
      );
      expect(
        ProfileFieldOptions.getDefaultLookingFor('female'),
        equals('male'),
      );
      expect(
        ProfileFieldOptions.getDefaultLookingFor('non_binary'),
        equals('everyone'),
      );

      expect(
        ProfileFieldOptions.lookingForToShowMeGenders('male'),
        equals(const ['male']),
      );
      final everyone = ProfileFieldOptions.lookingForToShowMeGenders(
        'everyone',
      );
      expect(everyone, containsAll(const ['male', 'female', 'non_binary']));

      expect(
        ProfileFieldOptions.showMeGendersToLookingFor(const ['male']),
        equals('male'),
      );
      expect(
        ProfileFieldOptions.showMeGendersToLookingFor(const ['female']),
        equals('female'),
      );
      expect(
        ProfileFieldOptions.showMeGendersToLookingFor(const ['male', 'female']),
        equals('everyone'),
      );
      expect(
        ProfileFieldOptions.showMeGendersToLookingFor(const []),
        equals('everyone'),
      );
    });

    test('converts and formats height values', () {
      final feetInches = ProfileFieldOptions.cmToFeetInchesValues(178);
      expect(feetInches.feet, equals(5));
      expect(feetInches.inches, equals(10));

      expect(ProfileFieldOptions.cmToFeetInchesString(178), equals('5\'10"'));
      expect(
        ProfileFieldOptions.formatHeightDisplay(178),
        equals('5\'10" (178 cm)'),
      );
      expect(ProfileFieldOptions.feetInchesToCm(5, 10), equals(178));
    });
  });
}
