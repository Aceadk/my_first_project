import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

const bool kUseFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATOR',
  defaultValue: bool.fromEnvironment('USE_EMULATORS', defaultValue: false),
);
const String kEmulatorHostOverride = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: String.fromEnvironment('EMULATOR_HOST', defaultValue: ''),
);
const int kAuthEmulatorPort = int.fromEnvironment(
  'FIREBASE_AUTH_EMULATOR_PORT',
  defaultValue: 9099,
);
const int kFunctionsEmulatorPort = int.fromEnvironment(
  'FIREBASE_FUNCTIONS_EMULATOR_PORT',
  defaultValue: 5001,
);
const int kFirestoreEmulatorPort = int.fromEnvironment(
  'FIREBASE_FIRESTORE_EMULATOR_PORT',
  defaultValue: 8080,
);
const int kStorageEmulatorPort = int.fromEnvironment(
  'FIREBASE_STORAGE_EMULATOR_PORT',
  defaultValue: 9199,
);

bool _configured = false;

String resolveEmulatorHostOverrideForEnv({
  required String emulatorHostOverride,
  required String legacyEmulatorHost,
}) {
  if (emulatorHostOverride.isNotEmpty) return emulatorHostOverride;
  return legacyEmulatorHost;
}

Future<void> configureFirebaseEmulators() async {
  if (!kUseFirebaseEmulators || _configured) return;
  _configured = true;

  final host = _resolveEmulatorHost();
  fb.FirebaseAuth.instance.useAuthEmulator(host, kAuthEmulatorPort);
  if (!kIsWeb) {
    await fb.FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }
  FirebaseFirestore.instance.useFirestoreEmulator(host, kFirestoreEmulatorPort);
  FirebaseFunctions.instance.useFunctionsEmulator(host, kFunctionsEmulatorPort);
  // Wire Storage to the emulator too, so profile photo uploads work locally
  // without hitting production rules / App Check. Without this, Storage leaks
  // to the live bucket while auth uses an emulator token, so every upload is
  // rejected and the photo silently fails to attach.
  await FirebaseStorage.instance.useStorageEmulator(host, kStorageEmulatorPort);
}

String _resolveEmulatorHost() {
  if (kEmulatorHostOverride.isNotEmpty) {
    return kEmulatorHostOverride;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}
