# TODO: Security — Frontend
**Priority:** P1
**Estimated Effort:** 20-30 hours
**Dependencies:** SEC-BE-003/004 (App Check backend), API endpoints
**Assigned:** AI + Developer

---

## SEC-FE-001: Configure Certificate Pinning with Production Pins
**Files:** `lib/core/network/certificate_pinning.dart`, `lib/core/network/api_client.dart`
**Description:** Certificate pinning framework exists but has no production pins configured. Vulnerable to MITM attacks.
**Acceptance Criteria:**
- [ ] SPKI hashes for Firebase endpoints extracted and configured
- [ ] Primary + backup pin for each endpoint
- [ ] Integrated into API client HTTP interceptor
- [ ] Disabled in debug, enabled in release
- [ ] Pin rotation procedure documented
**Testing:** Release mode against production; proxy interception rejected.

---

## SEC-FE-002: Audit and Harden Secure Storage Usage
**Files:** `lib/core/security/`, `lib/features/auth/`
**Description:** Audit all device storage for sensitive data. Verify nothing in plain SharedPreferences, unencrypted SQLite, or filesystem.
**Acceptance Criteria:**
- [ ] All storage locations audited
- [ ] Sensitive data in flutter_secure_storage only
- [ ] No API keys/secrets hardcoded in source
- [ ] No PII in plain text on filesystem
**Testing:** Inspect storage on rooted/jailbroken device.

---

## SEC-FE-003: Comprehensive Input Sanitization Audit
**Files:** `lib/core/security/input_sanitizer.dart`, all text input screens
**Description:** Verify all user inputs sanitized before backend submission. Chat messages, profile fields, search filters.
**Acceptance Criteria:**
- [ ] Every TextField traced to submission handler with sanitization
- [ ] Length limits match backend validation
- [ ] HTML/script content stripped from chat input
- [ ] Zero-width characters stripped from profile name
- [ ] No raw user input in Firestore queries
**Testing:** Widget tests with XSS payloads; zero-width character tests.

---

## SEC-FE-004: Remove Debug Print Statements from Secure Logger
**Files:** `lib/core/security/secure_logger.dart`
**Description:** Contains multiple raw `print()` calls (lines 49-89) outputting OTP codes and debug info. Must use AppLogger.
**Acceptance Criteria:**
- [ ] All `print()` replaced with `AppLogger`
- [ ] OTP display removed or behind explicit build flag
- [ ] Zero console output in release mode from security code
**Testing:** Grep for print() in security directory; release mode console check.

---

## SEC-FE-005: Implement Biometric Authentication
**Files:** `pubspec.yaml`, `lib/core/security/biometric_auth.dart` (new)
**Description:** Privacy feature: biometric lock for app, payment confirmation, account deletion.
**Acceptance Criteria:**
- [ ] App lock setting (opt-in) with biometric prompt after 30s background
- [ ] Account deletion requires biometric/password confirmation
- [ ] Payment changes require biometric confirmation
- [ ] Graceful fallback to PIN/password
**Testing:** Test on iOS Face ID and Android fingerprint devices.

---

## SEC-FE-006: Implement Secure Clipboard Handling
**Files:** `lib/core/security/clipboard_manager.dart` (new), chat screen
**Description:** Copied content persists in clipboard indefinitely. Auto-clear after 60 seconds.
**Acceptance Criteria:**
- [ ] Clipboard auto-clear after 60 seconds
- [ ] `FLAG_SECURE` on chat/profile screens (Android screenshot prevention)
- [ ] User notified: "Copied — will clear in 60 seconds"
**Testing:** Copy message, wait 60s, verify clipboard empty.

---

## SEC-FE-007: Network Security Configuration for Android
**Files:** `android/app/src/main/res/xml/network_security_config.xml` (new), `AndroidManifest.xml`
**Description:** Enforce HTTPS-only connections, configure certificate pins at OS level.
**Acceptance Criteria:**
- [ ] `cleartextTrafficPermitted="false"`
- [ ] Certificate pins for Firebase domains
- [ ] Debug overrides for development proxy
**Testing:** HTTP request in release mode fails; proxy in debug works.

---

## SEC-FE-008: Implement Jailbreak/Root Detection
**Files:** `lib/core/security/device_integrity.dart` (new)
**Description:** Detect jailbroken/rooted devices. Warn user, log for fraud detection.
**Acceptance Criteria:**
- [ ] Detection on startup (non-blocking)
- [ ] Informational dialog on positive detection
- [ ] Result sent to analytics
- [ ] No false positives on standard emulators in debug
**Testing:** Test on rooted emulator; verify no warning on standard device.
