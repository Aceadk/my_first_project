# TODO: Security — Backend
**Priority:** P0-P1
**Estimated Effort:** 40-55 hours
**Dependencies:** Firebase Console access, Cloud Functions, Firestore rules
**Assigned:** AI + Developer

---

## SEC-BE-001: Restrict Storage Rules for Chat Media
**Files:** `storage.rules`
**Description:** Chat media at `chats/{matchId}/` readable by any authenticated user. Must verify requesting user is a match participant.
**Acceptance Criteria:**
- [ ] Storage rule verifies `request.auth.uid` in match participants
- [ ] Unauthenticated users denied
- [ ] Non-participants receive 403
- [ ] Match participants read/write normally
**Testing:** Firebase Rules emulator unit tests; manual test with non-participant account.

---

## SEC-BE-002: Initialize Firebase Storage in Console
**Files:** Firebase Console (manual step)
**Description:** Firebase Storage not initialized in console (flagged T-2026-02-06-01). Without it, storage rules can't deploy and uploads fail.
**Acceptance Criteria:**
- [ ] Storage initialized in Firebase Console
- [ ] Default bucket created
- [ ] `storage.rules` deployed successfully
- [ ] Photo upload verified end-to-end
**Testing:** Upload profile photo; upload chat attachment; deploy storage rules.

---

## SEC-BE-003: Enable Firebase App Check for Android (Play Integrity)
**Files:** `android/app/build.gradle.kts`, `lib/core/services/app_check_service.dart`
**Description:** App Check not configured for Android. Backend can't distinguish real app from scripts/emulators.
**Acceptance Criteria:**
- [ ] Play Integrity API enabled in Google Cloud Console
- [ ] `firebase_app_check` configured with PlayIntegrityProvider
- [ ] App Check token attached to Cloud Functions calls
- [ ] Enforcement enabled (warning mode first, then enforce after 48h)
**Testing:** Deploy to real Android device; verify App Check token; monitor logs.

---

## SEC-BE-004: Enable Firebase App Check for iOS (App Attest)
**Files:** `ios/Runner/Info.plist`, `lib/core/services/app_check_service.dart`
**Description:** iOS equivalent of SEC-BE-003. Apple's App Attest provides device attestation.
**Acceptance Criteria:**
- [ ] App Attest capability added in Xcode
- [ ] `firebase_app_check` configured with AppleProvider
- [ ] Enforcement enabled after 48h warning mode
**Testing:** Deploy to real iOS device via TestFlight; verify App Check token.

---

## SEC-BE-005: Add Rate Limiting to Critical Cloud Functions
**Files:** `functions/src/index.ts`, `functions/src/middleware/rate_limiter.ts` (new)
**Description:** No rate limiting on critical endpoints. Attacker with valid token could spam swipes, exhaust candidates, flood reports.
**Acceptance Criteria:**
- [ ] `swipeRight/Left`: max 100/hour per user
- [ ] `sendMessage`: max 60/minute per user
- [ ] `reportUser`: max 10/hour per user
- [ ] `fetchDiscoveryCandidates`: max 30/hour per user
- [ ] 429 response with `retryAfter` header
**Testing:** Unit test exceeding limits; load test for latency impact.

---

## SEC-BE-006: Enforce Email Verification on All Write Cloud Functions
**Files:** `functions/src/index.ts`
**Description:** Comprehensive audit of all 55+ callables for `requireEmailVerified` on writes. Generate checklist.
**Acceptance Criteria:**
- [ ] All 55+ functions documented: name, auth requirement, email verification
- [ ] Every write callable has `requireAuth` + `requireEmailVerified`
- [ ] Read-only callables have minimum `requireAuth`
- [ ] Exceptions documented with justification
**Testing:** Unverified email account attempts each write callable; verify denied.

---

## SEC-BE-007: Add Server-Side Input Validation to Cloud Functions
**Files:** `functions/src/index.ts`, `functions/src/utils/validators.ts` (new)
**Description:** Server must not trust client input. Add schema validation for all inputs using zod or manual validation.
**Acceptance Criteria:**
- [ ] Validation utility created
- [ ] Messages: content 1-2000 chars, no script injection
- [ ] Profiles: name 2-50, bio 0-500, age 18-99
- [ ] Reports: reason 10-1000 chars, valid category enum
- [ ] Invalid input returns 400 with descriptive error
**Testing:** Unit tests for validators; integration tests with invalid input.

---

## SEC-BE-008: Implement Firestore Backup and Recovery
**Files:** Firebase Console, `functions/src/scheduled/firestore_backup.ts` (new)
**Description:** No automated backup. Data loss from bad deployment or breach would be catastrophic. Implement daily exports with 30-day retention.
**Acceptance Criteria:**
- [ ] Daily export via Cloud Scheduler
- [ ] Stored in dedicated Cloud Storage bucket with 30-day lifecycle
- [ ] Restricted IAM on backup bucket
- [ ] Recovery procedure documented
- [ ] Test restore performed
**Testing:** Manual export; verify files; test restore to separate instance.

---

## SEC-BE-009: Harden Firestore Rules for Edge Cases
**Files:** `firestore.rules`
**Description:** Verify: no cross-user profile modification, no full-collection reads, server-enforced timestamps, bounded array sizes, client can't write subscription status.
**Acceptance Criteria:**
- [ ] All writes validate ownership (`request.auth.uid == resource.id`)
- [ ] List operations require indexed filter
- [ ] Timestamps validated against `request.time`
- [ ] Array fields bounded (photos <= 9, interests <= 20)
- [ ] Subscription fields read-only for clients
**Testing:** Emulator unit tests for all edge cases.
