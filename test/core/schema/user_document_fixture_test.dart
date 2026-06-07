// Validates the mobile user-document canonicalizer against the SHARED contract
// fixture (docs/contracts/canonical_user_document.fixture.json) — the same
// fixture mirrored into crush-web for the TypeScript builder tests. Part of
// Phase 3 Step 5 (canonical-only profile writes).

import 'dart:convert';
import 'dart:io';

import 'package:crushhour/core/schema/user_document_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(
    File('docs/contracts/canonical_user_document.fixture.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;

  final rejectedFlatRootKeys =
      (fixture['rejectedFlatRootKeys'] as List).cast<String>();

  group('canonical user document fixture', () {
    test('the canonical fixture has no legacy flat root keys', () {
      final canonical = (fixture['canonical'] as Map).cast<String, dynamic>();
      final offenders =
          canonical.keys.where(rejectedFlatRootKeys.contains).toList();
      expect(offenders, isEmpty,
          reason: 'canonical doc must keep demographics under profile.*');
    });

    test('canonicalizer migrates legacy flat keys into profile.*', () {
      final legacyInput =
          (fixture['legacyInput'] as Map).cast<String, dynamic>();
      final expectedProfile =
          (fixture['legacyInputExpectedProfile'] as Map).cast<String, dynamic>();

      final result = canonicalizeUserDocumentSchema(legacyInput);

      // Expected demographic fields landed under the canonical nested profile.
      expectedProfile.forEach((key, value) {
        expect(result.canonicalProfile[key], value,
            reason: 'profile.$key should be migrated from the flat root key');
      });

      // The flat root keys are marked for deletion during persistence.
      for (final key in ['age', 'gender', 'bio', 'interests', 'birthDate']) {
        expect(result.legacyRootKeysToDelete, contains(key),
            reason: '$key should be cleaned from the root on persistence');
      }
    });

    test('after applying legacyRootKeysToDelete, no flat root keys remain', () {
      final legacyInput =
          (fixture['legacyInput'] as Map).cast<String, dynamic>();
      final result = canonicalizeUserDocumentSchema(legacyInput);

      final cleaned = Map<String, dynamic>.from(result.canonicalUserData)
        ..removeWhere((key, _) => result.legacyRootKeysToDelete.contains(key));

      final offenders =
          cleaned.keys.where(rejectedFlatRootKeys.contains).toList();
      expect(offenders, isEmpty);
    });
  });
}
