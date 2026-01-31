# AI Change Log

This file tracks all changes made by AI assistants (Claude, Codex, etc.)

---

## [2026-01-31] Task: Fix Discovery Payload Mismatch (REST API)

**Summary:**
- Fixed REST API `/v1/discovery/deck` to return `candidates` key (in addition to `profiles` for backward compatibility)
- Updated `DiscoveryDeckDto` to support both `candidates` (new) and `profiles` (legacy) keys
- Updated `HttpDiscoveryRepository` to try `candidates` first, then fall back to `profiles`

**Files Modified:**
- `/functions/src/index.ts` - REST API now returns both `candidates` and `profiles` keys
- `/lib/core/network/dto/discovery_dto.dart` - DTO now parses `candidates` first, falls back to `profiles`
- `/lib/features/discovery/data/repositories/impl/http_discovery_repository.dart` - Updated fetchTopPicks and fetchLikesYou

**Why / Notes:**
- Firebase Callable (`fetchDiscoveryCandidates`) returns `candidates`
- REST API (`/v1/discovery/deck`) was returning `profiles`
- Client had two repositories: one expecting `candidates`, one expecting `profiles`
- Now both are aligned with backward compatibility maintained

**Risks & Mitigations:**
- Backward compatible: legacy clients expecting `profiles` still work
- New key `candidates` added for consistency with callable function
- Total count added as both `total` and `total_count` for compatibility

**Follow-ups / TODO:**
- Deploy Cloud Functions with `firebase deploy --only functions`

---

## [2026-01-31] Task: Verify Storage Rules Alignment

**Summary:**
- Verified that storage rules mismatch (R-106) has already been resolved
- All upload paths in code match storage rules
- No code changes needed - rules were previously updated

**Files Verified (no changes needed):**
- `/storage.rules` - Contains correct paths:
  - `users/{uid}/photos/{fileName}` (lines 44-49)
  - `users/{uid}/videos/{fileName}` (lines 52-57)
  - `chat_media/{matchId}/{userId}/{fileName}` (lines 82-90)
- `/lib/features/profile/data/services/profile_media_service.dart` - Uses `users/$userId/photos/` and `users/$userId/videos/`
- `/lib/features/chat/data/repositories/impl/firebase_chat_repository.dart` - Uses `chat_media/$matchId/$userId/`

**Why / Notes:**
- AUDIT_REPORT mentioned storage rules mismatch but rules have already been fixed
- Legacy paths (`users/{uid}/media`, `chats/{matchId}/{messageId}`) kept for backwards compatibility
- Current paths are fully supported by storage rules
- Risk R-106 marked as resolved

**Risks & Mitigations:**
- None - storage paths are properly aligned
- Requires `firebase deploy --only storage` if rules haven't been deployed

**Follow-ups / TODO:**
- Ensure storage rules are deployed to Firebase

---

## [2026-01-31] Task: Verify Discovery Payload Alignment

**Summary:**
- Verified that discovery payload mismatch (R-104) has already been resolved
- Cloud Function returns `candidates` with flattened profile data
- Client correctly expects `candidates` key

**Files Verified (no changes needed):**
- `/functions/src/index.ts` - Lines 3335-3346 return `candidates` with `...c.profile` flattening
- `/lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart` - Line 29 expects `candidates`

**Why / Notes:**
- AUDIT_REPORT mentioned payload mismatch but code has already been fixed
- Cloud Function returns: `{ candidates: [{ id, userId, ...profile, username, distanceKm, score }], total }`
- Client reads: `result.data['candidates']` and maps via `_profileFromFirestore()`
- Risk R-104 marked as resolved

**Risks & Mitigations:**
- None - payload structure is properly aligned

**Follow-ups / TODO:**
- None

---

## [2026-01-31] Task: Add iOS Privacy Manifest to Xcode Project

**Summary:**
- Verified existing PrivacyInfo.xcprivacy file content is comprehensive
- Added PrivacyInfo.xcprivacy to Xcode project build (was missing from project.pbxproj)
- File now properly bundled with app for iOS 17+ compliance

**Files Modified:**
- `/ios/Runner.xcodeproj/project.pbxproj` - Added PrivacyInfo.xcprivacy to build

**Why / Notes:**
- iOS 17+ requires apps to declare "required reason APIs" in PrivacyInfo.xcprivacy
- File existed but was NOT included in Xcode project build
- App would have been rejected from App Store without this fix
- Manifest declares: UserDefaults, FileTimestamp, SystemBootTime, DiskSpace APIs
- Also declares collected data types: Name, Email, Phone, DOB, Photos, Location, UserID
- Risk R-119 (iOS Privacy Manifest Missing) is now resolved

**Risks & Mitigations:**
- Build verified to include PrivacyInfo in Resources bundle
- All required reason APIs properly declared with correct codes

**Follow-ups / TODO:**
- None - iOS Privacy Manifest is now complete and included in build

---

## [2026-01-31] Task: Configure Privacy Policy & Terms URLs

**Summary:**
- Created public web pages for Privacy Policy and Terms of Service
- Updated Firebase Hosting configuration with URL rewrites
- Created centralized LegalConfig for all legal URLs and contact info
- Updated Flutter screens to use centralized config

**Files Added:**
- `/public/privacy.html` - Public Privacy Policy page for App Store/Play Store
- `/public/terms.html` - Public Terms of Service page for App Store/Play Store
- `/lib/config/legal_config.dart` - Centralized legal URLs and contact config

**Files Modified:**
- `/firebase.json` - Added rewrites for /privacy and /terms routes
- `/lib/presentation/screens/privacy_policy_screen.dart` - Use LegalConfig
- `/lib/presentation/screens/terms_of_service_screen.dart` - Use LegalConfig

**Why / Notes:**
- App Store and Play Store require publicly accessible Privacy Policy URLs
- URLs now accessible at https://crushhour.app/privacy and https://crushhour.app/terms
- Centralized config makes URLs easy to update across the app
- Risk R-117 (Missing Privacy Policy URLs) is now resolved

**Risks & Mitigations:**
- Requires `firebase deploy --only hosting` to publish the web pages
- HTML pages are self-contained with consistent branding

**Follow-ups / TODO:**
- Deploy to Firebase Hosting
- Update App Store Connect and Play Console with URLs

---

## [2026-01-31] Task: Add Age Gate (18+) to Signup Flow

**Summary:**
- Added age gate dialog at AuthGatewayScreen before allowing signup
- Users must confirm they are 18+ before proceeding to account creation
- Meets App Store and Play Store compliance requirements for dating apps

**Files Modified:**
- `/lib/features/auth/presentation/screens/auth_gateway_screen.dart` - Added `_showAgeGate()` method and `_AgeGateDialog` widget

**Why / Notes:**
- Dating apps require explicit age verification before account creation
- Previous flow had age validation only at BasicInfoScreen (step 3 of onboarding)
- Now users must confirm 18+ at the very first entry point (Create Account button)
- Clean dialog with clear messaging and legal notice

**Risks & Mitigations:**
- Risk R-115 (Missing Age Gate) is now resolved
- Dialog is non-dismissible (barrierDismissible: false) to ensure compliance
- Users who decline cannot proceed to signup

**Follow-ups / TODO:**
- Consider adding server-side age verification for stronger compliance
- May want to add DOB input in addition to confirmation

---

## [2026-01-31] Task: Update AUDIT_REPORT.md with New Analysis Findings

**Summary:**
- Merged comprehensive codebase analysis into existing AUDIT_REPORT.md
- Updated file counts, scores, and statistics
- Added new Delta Review section (2026-01-31)
- Documented promo code feature
- Updated test coverage analysis
- Added current limitations and critical findings

**Files Modified:**
- `/AUDIT_REPORT.md` - Major update with new findings

**Why / Notes:**
- Previous audit had 337+ files, now 457 files
- Previous score 9.1/10, updated to 82/100 (more rigorous scoring)
- Added critical findings: missing age gate, Sign in with Apple, Privacy URLs
- Documented new promo code system
- Updated test coverage analysis (4.6% ratio)

**Risks & Mitigations:**
- Report now reflects more critical view of store compliance
- Clear action items for P0/P1/P2 priorities

**Follow-ups / TODO:**
- Implement age gate (18+) - CRITICAL
- Add Sign in with Apple - CRITICAL
- Configure Privacy Policy URL - CRITICAL
- Increase test coverage
- Fix 23 lint warnings

---

## [2026-01-31] Task: Comprehensive Codebase Analysis

**Summary:**
- Executed 8-phase multi-role analysis of codebase
- Created comprehensive analysis report

**Files Added:**
- `/docs/COMPREHENSIVE_CODEBASE_ANALYSIS.md` - Full analysis report

**Why / Notes:**
- Provided detailed analysis across Flutter, Web, UI/UX, Architecture, Security, Store Compliance
- Identified 457 Dart files, ~200,330 LOC
- Found 24 BLoC/Cubits, 32 Repositories, 14 Features

---

## [2026-01-31] Task: Promo Code Feature Implementation

**Summary:**
- Added promo code system to subscription feature
- Implemented Stub, Firebase, and HTTP repository support
- Added fallback demo codes for development

**Files Added:**
- `/lib/data/models/promo_code.dart` - PromoCode model
- `/lib/features/subscription/presentation/widgets/promo_code_sheet.dart` - UI

**Files Modified:**
- `/lib/features/subscription/data/repositories/subscription_repository.dart` - Interface
- `/lib/features/subscription/data/repositories/impl/stub_subscription_repository.dart`
- `/lib/features/subscription/data/repositories/impl/firebase_subscription_repository.dart`
- `/lib/features/subscription/data/repositories/impl/http_subscription_repository.dart`
- `/lib/features/settings/presentation/screens/settings_screen.dart` - Added promo code entry

**Why / Notes:**
- Enable promo code redemption for marketing campaigns
- Support discount, free trial, bonus likes/super likes
- Fallback demo codes when Cloud Functions unavailable

---

## [2026-01-31] Task: Wire ProfileRepository into DiscoveryBloc

**Summary:**
- Wired ProfileRepository into DiscoveryBloc for profile completeness checks

**Files Modified:**
- `/lib/core/di.dart` - Added `profileRepository: context.read<ProfileRepository>()` to DiscoveryBloc

**Why / Notes:**
- DiscoveryBloc already had optional profileRepository parameter
- Now properly wired for profile validation before swiping

---

## [2026-01-31] Task: Normalize Profile Completeness Scoring

**Summary:**
- Normalized profile completeness scoring between Cloud Functions (server) and client
- Server was returning 0-100 scores, client expected 0.0-1.0

**Files Modified:**
- `/functions/src/index.ts` - Changed scoring to 0.0-1.0 range, breakdown uses weighted values
- `/lib/features/profile/data/services/profile_validation_service.dart` - Fixed error fallback score from 100.0 to 1.0

**Why / Notes:**
- Server breakdown now: photos=0-0.30, bio=0-0.25, interests=0-0.25, location=0-0.20
- Thresholds normalized: swipeThreshold=1.0, messagingThreshold=1.0
- Client and server now speak the same language

---

## [2026-01-31] Task: Verify No Stub Data Leaks to Production

**Summary:**
- Added production guards to HybridDiscoveryRepository to prevent stub/mock data from appearing in release builds

**Files Modified:**
- `/lib/features/discovery/data/repositories/impl/hybrid_discovery_repository.dart`
  - StubDiscoveryRepository is now null in release mode (kReleaseMode check)
  - Added `_includeStubData` getter
  - All methods now check `_includeStubData` before using stub data

**Why / Notes:**
- SECURITY: Stub profiles (mock_ IDs) were potentially visible in production
- Now: `_stubRepo = kReleaseMode ? null : StubDiscoveryRepository()`
- All fetch methods return Firebase-only data in release mode

**Risks & Mitigations:**
- Risk: Fake profiles appearing in production - MITIGATED with kReleaseMode check

---

## [2026-01-31] Task: Enable Firebase App Check / Device Attestation

**Summary:**
- Added Firebase App Check for device attestation and request authenticity verification
- Protects backend from abuse by verifying requests come from authentic apps

**Files Added:**
- `/lib/core/services/app_check_service.dart` - App Check initialization service
  - Uses DeviceCheck (iOS) and Play Integrity (Android) in release
  - Uses debug provider in development
  - Token management and refresh listeners

**Files Modified:**
- `/pubspec.yaml` - Added `firebase_app_check: ^0.4.1+3`
- `/lib/main.dart` - Added `AppCheckService.instance.initialize()` after Firebase init
- `/functions/src/index.ts` - Added App Check verification to Cloud Functions
  - `verifyAppCheck()` helper function
  - `ENFORCE_APP_CHECK` flag (currently false for testing)

**Why / Notes:**
- App Check verifies requests come from genuine apps on genuine devices
- Prevents API abuse, bot attacks, and request forgery
- Currently in "monitor mode" (ENFORCE_APP_CHECK=false)

**Risks & Mitigations:**
- Risk: Breaking existing users - MITIGATED with ENFORCE_APP_CHECK=false initially
- Risk: Debug builds failing - MITIGATED with debug provider in kDebugMode

**Follow-ups / TODO:**
- Configure App Check in Firebase Console (iOS DeviceCheck, Android Play Integrity)
- Register debug tokens for development devices
- Set `ENFORCE_APP_CHECK=true` after testing
- Deploy Cloud Functions: `firebase deploy --only functions`

---

## [2026-01-31] Task: Review Secure Token Flow - Prevent Token Leaks

**Summary:**
- Enhanced SecureLogger with comprehensive token redaction
- Updated app_check_service.dart and push_notification_service.dart to use secure logging
- Verified no token leaks in auth repositories or network layer

**Files Modified:**
- `/lib/core/security/secure_logger.dart` - Added token-specific secure logging:
  - `logToken()` - Logs token with redaction (first4...last4 format)
  - `logTokenRefresh()` - Logs refresh event without token content
  - `logTokenError()` - Logs errors without token content
  - `redactToken()` - Public helper for token redaction
  - `_neverLogFullTokens` - Constant ensuring tokens are always redacted
  - `logAuth()` - Safe auth event logging
  - `logSecurityEvent()` - Security audit logging

- `/lib/core/services/app_check_service.dart`:
  - Import SecureLogger
  - Replace `debugPrint('$token')` with `SecureLogger.logToken()`
  - Replace token refresh logging with `SecureLogger.logTokenRefresh()`
  - Replace error logging with `SecureLogger.logTokenError()`

- `/lib/core/services/push_notification_service.dart`:
  - Import SecureLogger
  - Replace `debugPrint('FCM Token: $token')` with `SecureLogger.logToken()`

**Why / Notes:**
- SECURITY: Tokens (FCM, App Check, JWT, etc.) should NEVER appear in logs
- Previous code logged full tokens which could leak via log aggregation, crash reports
- Now all token logging uses redaction: "dK7x...9mN2 (152 chars)"
- Auth repositories and network layer verified - no token logging found

**Risks & Mitigations:**
- Risk: Token leakage via logs - RESOLVED with SecureLogger
- Risk: Debug token needed for Firebase Console - MITIGATED with redacted format + length

---

## [2026-01-31] Task: Confirm Rate Limiting - OTP, Login, Report/Block Throttles

**Summary:**
- Verified existing rate limiting for OTP and login operations
- Added rate limiting for report/block operations (callable functions + REST API)

**Existing Rate Limits Verified:**
- OTP Request: 5 requests per 10 min window, 20 min block (IP + identifier)
- OTP Verify: 10 attempts per 10 min window, 20 min block
- Login: 8 attempts per 10 min window, 20 min block
- Signup: 5 attempts per 10 min window, 20 min block
- Password Reset: 5 attempts per 10 min window, 20 min block
- Change Password: Same as login limits

**New Rate Limits Added:**
- Report: 10 reports per hour, 2 hour block after exceeding
- Block: 20 blocks per hour, 1 hour block after exceeding
- Unblock: 30 unblocks per hour, 30 min block after exceeding

**Files Modified:**
- `/functions/src/index.ts`:
  - Added `REPORT_LIMIT`, `BLOCK_LIMIT`, `UNBLOCK_LIMIT` constants with windows
  - Added rate limiting to `reportUser` callable function
  - Added rate limiting to `blockUser` callable function
  - Added rate limiting to `unblockUser` callable function
  - Added rate limiting to `/v1/users/report` REST endpoint
  - Added rate limiting to `/v1/users/block` REST endpoint
  - Added rate limiting to `/v1/users/unblock` REST endpoint

**Why / Notes:**
- Prevents abuse of safety features (spam reports, block/unblock cycling)
- Rate limits are per-user (uses UID), stored in `auth_rate_limits` collection
- Returns 429 status with retry timing for REST API
- Throws rate limit error for callable functions

**Verification:**
- Cloud Functions build succeeds (`npm run build`)
- Deploy with: `firebase deploy --only functions`

---
