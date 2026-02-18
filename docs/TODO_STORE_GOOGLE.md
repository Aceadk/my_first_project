# TODO: Store Compliance — Google Play Store
**Priority:** P0 (Ship-blocking)
**Estimated Effort:** 25-35 hours
**Dependencies:** Google Play Console access, Google Play Billing Library, Data Safety section
**Assigned:** AI + Developer

---

## STORE-GPG-001: Implement Google Play Billing Library v6+ Integration
**Files:** `pubspec.yaml`, `lib/features/subscription/data/services/native_billing_service.dart`
**Description:** Google requires Play Billing for all digital content. The `in_app_purchase` Flutter plugin wraps Google Play Billing. Ensure proper integration with v6+ features.
**Acceptance Criteria:**
- [ ] Google Play Billing v6+ via `in_app_purchase` plugin
- [ ] Subscription products created in Google Play Console
- [ ] Purchase flow: user taps → Google Play payment → confirmed → entitlement
- [ ] `queryPurchases()` for restore on new device
- [ ] Server-side verification via Google Play Developer API
- [ ] Pending purchases handled (slow cards, gift cards)
**Testing:** Internal testing track purchase; license test accounts.

---

## STORE-GPG-002: Fill Out Data Safety Section
**Files:** Google Play Console (configuration)
**Description:** Google requires Data Safety declaration: what data collected, shared, security practices.
**Acceptance Criteria:**
- [ ] All data types declared: name, email, phone, photos, location, messages, usage, identifiers
- [ ] Collection purpose: app functionality, analytics, personalization
- [ ] Data sharing: Firebase (Google), analytics SDKs
- [ ] Security practices: encryption in transit (yes), deletion on request (yes)
- [ ] Declarations match actual behavior and privacy policy
**Testing:** Review against codebase data collection; verify consistency.

---

## STORE-GPG-003: Target SDK 34+ and Verify Permissions
**Files:** `android/app/build.gradle.kts`, `AndroidManifest.xml`
**Description:** Google requires targeting SDK 34+ (Android 14). Verify all permission declarations comply with new permission model.
**Acceptance Criteria:**
- [ ] `targetSdkVersion 34` or higher in build.gradle
- [ ] `SCHEDULE_EXACT_ALARM` permission: only if needed, with rationale
- [ ] `POST_NOTIFICATIONS` runtime permission for Android 13+
- [ ] `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` replacing `READ_EXTERNAL_STORAGE`
- [ ] `FOREGROUND_SERVICE_TYPE` specified for all foreground services
- [ ] No deprecated permissions
**Testing:** Build with target SDK 34; test all permissions on Android 14 device.

---

## STORE-GPG-004: Generate Android App Bundle (AAB) for Submission
**Files:** Build configuration
**Description:** Google Play requires AAB format (not APK). Verify AAB builds correctly with all features.
**Acceptance Criteria:**
- [ ] `flutter build appbundle --release` succeeds
- [ ] AAB size under 150MB limit (current: 60.3MB)
- [ ] Signing configured with production keystore
- [ ] Play App Signing enrolled in Google Play Console
- [ ] ProGuard/R8 rules correct (no missing class errors)
**Testing:** Upload AAB to internal testing track; install from Play Store; smoke test.

---

## STORE-GPG-005: Create Google Play Store Listing
**Files:** Google Play Console (configuration)
**Description:** Complete store listing: title, short/full description, screenshots, feature graphic, category.
**Acceptance Criteria:**
- [ ] Title (30 chars), short description (80 chars), full description (4000 chars)
- [ ] Screenshots for phone (1080x1920 or 1440x2560) — minimum 4, recommended 8
- [ ] Screenshots for tablet (if targeting tablets): 7" and 10"
- [ ] Feature graphic (1024x500)
- [ ] Category: Social → Dating
- [ ] Content rating questionnaire completed (IARC)
**Testing:** Preview listing in Google Play Console.

---

## STORE-GPG-006: Configure Google Play Integrity API
**Files:** Google Cloud Console, `android/app/build.gradle.kts`
**Description:** Complement Firebase App Check (SEC-BE-003) with Play Integrity for device attestation and anti-tampering.
**Acceptance Criteria:**
- [ ] Play Integrity API enabled in Google Cloud Console
- [ ] Integrated with Firebase App Check
- [ ] API key restricted to production package name and SHA-256
- [ ] Verdict handling: allow MEETS_DEVICE_INTEGRITY, warn on others
**Testing:** Verify on real device; verify emulator fails attestation.

---

## STORE-GPG-007: Implement Google Play In-App Review API
**Files:** `pubspec.yaml`, `lib/core/services/review_prompt_service.dart` (new)
**Description:** Prompt users for Play Store reviews at the right moment (after match, after successful chat). Use Google's in-app review API for a frictionless experience.
**Acceptance Criteria:**
- [ ] `in_app_review` package added
- [ ] Review prompt triggered after 3rd match (not on first use)
- [ ] Frequency limit: max once per 30 days
- [ ] Respects Google's quota (system may suppress prompt)
- [ ] No custom review UI (uses Google's native flow)
**Testing:** Test with internal testing account; verify prompt appears.

---

## STORE-GPG-008: Prepare Pre-Launch Report and Testing
**Files:** Google Play Console
**Description:** Upload AAB to closed testing track and review Google's automated pre-launch report for crashes, accessibility issues, and security vulnerabilities.
**Acceptance Criteria:**
- [ ] AAB uploaded to closed testing track
- [ ] Pre-launch report reviewed: no critical crashes
- [ ] Accessibility issues from automated testing addressed
- [ ] Security vulnerabilities from automated scan addressed
- [ ] Tested on Google's device lab (Firebase Test Lab integration)
**Testing:** Review pre-launch report; fix any flagged issues.
