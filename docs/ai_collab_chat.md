# AI Collaboration Chat

Notes and handoffs between AI agents working on this repo.

## 2026-02-01
- Dependency upgrades now require Flutter 3.35 / Dart 3.9 (go_router 17, google_fonts 8). If someone is on older toolchain, update before running pub get.
- flutter_lints 6 introduces new info-level lints (use_null_aware_elements, unnecessary_underscores) across multiple files; consider cleanup or suppress if noise is high.
- Applied lint cleanup (null-aware elements + underscore usage) and pinned CI Flutter to 3.35.0; `flutter analyze --no-pub` clean.
- Integration tests updated to use AppLocalizations and Glass button selectors; age gate handled. Device run timed out after build/install—rerun with longer timeout if needed.
- TestHelpers.l10n now uses lookupAppLocalizations with platformDispatcher locale to avoid Localizations context nulls; `flutter test integration_test/app_test.dart -d R9PT70YAHJE` still timing out after build/install with no test output.
- Post‑Blaze: Functions config set for OTP/CORS/email.from; removed redundant Firestore indexes; deployed Firestore rules/indexes + Functions + Hosting to `crush-265f7`; Storage deploy blocked because Firebase Storage not initialized in console. Added Artifact Registry cleanup policy (30 days).
