# Dependency Inventory (2026-02-12)

## Flutter App Dependencies
Source: `pubspec.yaml`
Raw list: `audit/raw/pubspec_direct_deps_raw.txt`

Summary:
- Direct dependencies: 50
- Key stacks:
- State/navigation: `flutter_bloc`, `go_router`
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_messaging`, `firebase_storage`, `firebase_database`, `firebase_app_check`, `firebase_analytics`, `firebase_remote_config`, `firebase_performance`, `firebase_crashlytics`
- Media/chat: `image_picker`, `record`, `just_audio`, `audio_waveforms`, `web_socket_channel`
- Security/privacy: `flutter_secure_storage`, `crypto`, `cryptography`, `app_tracking_transparency`

Outdated baseline (`dart pub outdated`):
- 60 locked dependencies are upgradable.
- 12 dependencies are constrained below resolvable versions.

## Functions Dependencies
Source: `functions/package.json`
Raw list: `audit/raw/functions_deps_raw.txt`

Summary:
- Runtime dependencies: 10
- Dev dependencies: 11
- Core runtime stack: `firebase-functions`, `firebase-admin`, `express`, `cors`, `stripe`, `@google-cloud/bigquery`, `agora-access-token`, `multer`, `bcryptjs`

## Vulnerability Baseline
- NPM audit (`functions`): 0 high/critical vulnerabilities in current lockfile.
- Raw report: `audit/raw/npm_audit_raw.json`

## Dependency Audit Gaps
- Flutter security vulnerability audit command is not currently available via `flutter pub` in this toolchain.
- Action required: add explicit dependency security scanning for Dart/Flutter packages in CI (e.g., scheduled advisory scan and upgrade bot workflow).
