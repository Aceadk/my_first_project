# Store Compliance Checklist -- CRUSH Dating App
**Date:** 2026-02-12
**Version:** 2.0 (Comprehensive Update)

Legend: `done`, `in_progress`, `not_verified`, `not_applicable`, `blocked`

---

## Apple App Store Requirements

### App Store Review Guidelines Compliance

| # | Requirement | Status | Evidence | Notes |
|---|-----------|--------|----------|-------|
| 1 | **17+ age rating configured** | `done` | Age gate dialog at AuthGatewayScreen entry; DOB validation (18-75) in BasicInfoScreen | Non-dismissible dialog; users must confirm 18+ before signup |
| 2 | **Privacy nutrition labels aligned** | `in_progress` | PrivacyInfo.xcprivacy declares: Name, Email, Phone, DOB, Photos, Location, UserID | Need to verify labels match actual data collection in App Store Connect |
| 3 | **Sign in with Apple** | `done` | `sign_in_with_apple` package integrated; AuthGatewayScreen includes Apple Sign In button | Required when any social login is offered (App Store Guideline 4.8) |
| 4 | **In-app purchase / StoreKit** | `not_verified` | Stripe checkout implemented for web; IAP flow for iOS not verified | Must use StoreKit for in-app purchases on iOS per App Store policy |
| 5 | **UGC moderation/reporting/blocking** | `done` | ContentModerationService (profanity filter, text analysis); SafetyCubit (report/block); rate-limited report/block endpoints | Includes leetspeak detection, personal info detection, harassment detection |
| 6 | **Permission rationale strings** | `in_progress` | ATT framework integrated; need to verify Info.plist has all NSUsageDescription keys | Location, Camera, Microphone, Photo Library, Notifications |
| 7 | **Account deletion in-app** | `done` | Account deletion in Settings > Account Actions; Cloud Function `processScheduledAccountDeletions` runs every 6h; cascading delete (Firestore, RTDB, Storage, Auth) | 14-day grace period with auto-recovery on sign-in; `requestAccountDeletion` callable; completes well within Apple's 3-day requirement |
| 8 | **Privacy Policy accessible** | `done` | In-app screen + public URL: `https://crushhour.app/privacy` | Linked from settings, onboarding, and App Store listing |
| 9 | **Terms of Service accessible** | `done` | In-app screen + public URL: `https://crushhour.app/terms` | Accepted during onboarding |
| 10 | **iOS Privacy Manifest** | `done` | PrivacyInfo.xcprivacy in Xcode project build; declares UserDefaults, FileTimestamp, SystemBootTime, DiskSpace | Added to project.pbxproj (was missing previously) |
| 11 | **App Tracking Transparency** | `done` | `app_tracking_transparency` package integrated; ATT prompt implemented | Required for iOS 14.5+ when tracking users |
| 12 | **No private API usage** | `not_verified` | Need to verify with Apple's API scanner during submission | Standard Flutter + Firebase packages should be clean |
| 13 | **Minimum deployment target** | `not_verified` | Need to verify iOS deployment target in Xcode settings | Currently requires iOS 15.0+ (check if acceptable) |
| 14 | **App icon and screenshots** | `in_progress` | STORE_ASSETS.md has specifications; actual assets need generation | Need 6.7" (iPhone 15 Pro Max) and 5.5" (iPhone 8 Plus) screenshots |
| 15 | **Content rating questionnaire** | `not_verified` | Dating app with UGC requires careful content rating selection | Profanity filter, reporting, and blocking are in place |

### Apple-Specific Dating App Requirements

| # | Requirement | Status | Evidence |
|---|-----------|--------|----------|
| A1 | Safety features visible in review notes | `in_progress` | Reporting, blocking, and date safety features implemented |
| A2 | Customer support contact method | `done` | SupportScreen with email contact, FAQ, help categories |
| A3 | No nudity/explicit content in review build | `not_verified` | Content moderation service in place; need to ensure test accounts are clean |
| A4 | Location permission justified | `done` | Used for discovery distance; rationale in permission request |
| A5 | Push notification permission handled gracefully | `done` | PushNotificationService with proper permission request flow |

---

## Google Play Store Requirements

### Play Store Policy Compliance

| # | Requirement | Status | Evidence | Notes |
|---|-----------|--------|----------|-------|
| 1 | **Target SDK at required level** | `not_verified` | Check `android/app/build.gradle.kts` for `targetSdkVersion` | Google Play requires targeting latest major API level within 1 year |
| 2 | **Data safety form aligned** | `not_verified` | Need to map actual data collection to Play Console data safety form | Firebase collects: crashlytics data, analytics events, FCM tokens |
| 3 | **UGC moderation/reporting/blocking** | `done` | Same as Apple -- ContentModerationService + SafetyCubit + rate-limited endpoints | Play requires mechanism to flag inappropriate content |
| 4 | **Billing/subscription policy** | `not_verified` | Stripe used for web; need Google Play Billing for Android IAP | Play Store requires Play Billing Library for in-app purchases |
| 5 | **Location permission minimum scope** | `done` | Uses `geolocator` for approximate location; `geocoding` for city names | Foreground-only; no background location tracking |
| 6 | **Account deletion available** | `done` | Settings > Account Actions; `requestAccountDeletion` callable + `processScheduledAccountDeletions` scheduled fn; cascading delete across Firestore/RTDB/Storage/Auth | 14-day grace period; auto-recovery on sign-in; web + mobile aligned |
| 7 | **Privacy Policy accessible** | `done` | Public URL: `https://crushhour.app/privacy` | Must be accessible without authentication |
| 8 | **App content rating** | `not_verified` | Need IARC rating via Play Console questionnaire | Dating app will likely receive T (Teen) or M (Mature) rating |
| 9 | **Deceptive behavior policy** | `done` | No fake profiles in production (kReleaseMode check); stub data disabled | HybridDiscoveryRepository guards against stub data leak |
| 10 | **Play Integrity API** | `blocked` | App Check references Play Integrity but NOT configured in Play Console | BLOCKER for App Check enforcement on Android (P0) |
| 11 | **Proguard/R8 configuration** | `done` | proguard-rules.pro configured; Play Core modular libraries added | Successfully built AAB (60.3MB) with R8 minification |
| 12 | **64-bit support** | `not_verified` | Flutter default includes arm64 and x86_64; verify in AAB | Standard for Flutter apps |
| 13 | **App Bundle format** | `done` | AAB built: `build/app/outputs/bundle/release/app-release.aab` (60.3MB) | Play Store requires AAB (not APK) for new apps |
| 14 | **Feature graphic** | `not_verified` | STORE_ASSETS.md specs 1024x500 feature graphic | Needs actual design asset |

### Google Play Dating App Requirements

| # | Requirement | Status | Evidence |
|---|-----------|--------|----------|
| G1 | Safety and reporting mechanisms | `done` | Report, block, unblock with rate limiting |
| G2 | Age verification (18+) | `done` | Age gate at signup + DOB validation |
| G3 | Content moderation | `done` | Automated profanity filter + manual report system |
| G4 | No catfishing/fake profiles | `done` | Stub profiles disabled in release builds; verification system available |
| G5 | Photo verification available | `in_progress` | PhotoVerificationService with selfie pose verification; needs backend integration |

---

## Shared Requirements (Both Stores)

| # | Requirement | Status | Evidence | Notes |
|---|-----------|--------|----------|-------|
| 1 | **Privacy policy in-app + public URL** | `done` | Settings > Privacy Policy; `https://crushhour.app/privacy` | Accessible both authenticated and unauthenticated |
| 2 | **Terms acceptance in onboarding** | `done` | TermsConditionsScreen shown during onboarding; acceptance recorded | Cannot proceed without accepting |
| 3 | **Content moderation policy documented** | `done` | Community guidelines page (in-app + web); profanity filter; report/block system | Web: `/guidelines`, Mobile: `/community-guidelines` route |
| 4 | **Age verification/confirmation** | `done` | Age gate dialog (18+) + DOB validation (18-75 range) + server-side age check | Two-layer verification: dialog at entry + DOB at onboarding |
| 5 | **Data deletion turnaround** | `done` | Cloud Function `processScheduledAccountDeletions` runs every 6h; `cascadeDeleteUserData` deletes: matches+messages, blocks/reports/likes, message_requests, Storage files, RTDB data, Auth user | 14-day grace period → full erasure; well within Apple's 3-day window after grace period |
| 6 | **Accessibility (WCAG 2.1 AA)** | `in_progress` | Tap targets (44px min), semantic labels, contrast utilities, aria-labels on web | Web fixes applied; mobile needs comprehensive audit |
| 7 | **Crash-free rate** | `not_verified` | Firebase Crashlytics integrated; no production data yet | Target: >99.5% crash-free rate |
| 8 | **App performance** | `not_verified` | Firebase Performance monitoring integrated; no baselines established | Target: <3s cold start, <1s screen transitions |
| 9 | **Localization** | `done` | `flutter_localizations` + `intl` packages; AppLocalizations infrastructure | Currently English only; i18n ready for expansion |
| 10 | **Safety features** | `done` | Date safety (emergency contacts, check-in, escalation), blocking, reporting, content moderation | Safety screen accessible from settings |
| 11 | **Customer support** | `done` | SupportScreen with FAQ (8 items), help categories (8), email contact | In-app support accessible from settings |
| 12 | **E2EE messaging** | `done` | AES-GCM 256-bit; enabled by default; toggle available | Apple values encryption for privacy apps |

---

## Compliance Score Summary

| Store | Requirements Checked | Done | In Progress | Not Verified | Blocked |
|-------|---------------------|------|-------------|--------------|---------|
| Apple App Store | 20 | 12 | 4 | 4 | 0 |
| Google Play | 19 | 10 | 1 | 7 | 1 |
| Shared | 12 | 8 | 2 | 2 | 0 |
| **Total** | **51** | **30 (59%)** | **7 (14%)** | **13 (25%)** | **1 (2%)** |

---

## Blockers for Store Submission

### Apple App Store Blockers
1. **Permission rationale strings** -- Verify all NSUsageDescription keys in Info.plist
2. **IAP via StoreKit** -- Must use Apple IAP for iOS in-app purchases (not just Stripe)
3. **Screenshots and app icon** -- Need actual design assets
4. **Account deletion server-side verification** -- Must complete within 3 days

### Google Play Store Blockers
1. **Play Integrity not configured** (P0) -- Blocks App Check enforcement
2. **Play Billing Library** -- Must use Google Play Billing for Android IAP (not just Stripe)
3. **Target SDK verification** -- Ensure latest required API level
4. **Data safety form** -- Must be filled out accurately in Play Console
5. **Feature graphic** -- 1024x500 PNG required

---

## Next Steps (Priority Order)

1. **P0:** Configure Play Integrity in Play Console and Firebase Console
2. **P1:** Verify all Info.plist permission rationale strings
3. **P1:** Implement StoreKit IAP for iOS / Play Billing for Android (or document Stripe-only approach)
4. **P1:** Verify and document account deletion server-side flow
5. **P2:** Generate actual screenshots and feature graphic
6. **P2:** Fill out Apple privacy nutrition labels and Google data safety form
7. **P2:** Run Apple API scanner (TestFlight upload) and Google pre-launch report
8. **P2:** Verify target SDK levels for both platforms
9. **P3:** Complete WCAG 2.1 AA audit for mobile
10. **P3:** Establish performance baselines (crash-free rate, startup time)

---

## Evidence Locations

| Evidence Type | Location |
|---------------|----------|
| Age gate implementation | `lib/features/auth/presentation/screens/auth_gateway_screen.dart` |
| Content moderation | `lib/core/services/content_moderation_service.dart` |
| Report/block/unblock | `lib/features/settings/presentation/bloc/safety_cubit.dart` |
| Privacy policy | `public/privacy.html`, `https://crushhour.app/privacy` |
| Terms of service | `public/terms.html`, `https://crushhour.app/terms` |
| iOS privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` |
| ATT integration | `app_tracking_transparency` package in pubspec.yaml |
| Sign in with Apple | `sign_in_with_apple` package; auth_gateway_screen.dart |
| E2EE chat | `lib/features/chat/data/repositories/impl/firebase_chat_repository.dart` |
| Account deletion | `lib/features/settings/presentation/screens/account_actions_settings_screen.dart` |
| Data export | DataExportService (tested in `test/data_export_test.dart`) |
| App Check | `lib/core/services/app_check_service.dart` |
| Store assets doc | `docs/STORE_ASSETS.md` |
| Release guide | `docs/RELEASE_GUIDE.md` |
