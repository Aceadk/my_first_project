# TODO: Store Compliance — Apple App Store
**Priority:** P0 (Ship-blocking)
**Estimated Effort:** 40-60 hours (includes IAP as largest item)
**Dependencies:** Apple Developer account, App Store Connect, StoreKit 2
**Assigned:** AI + Developer

---

## STORE-APL-001: Implement In-App Purchases with StoreKit 2 (CRITICAL)
**Files:** `pubspec.yaml`, `lib/features/subscription/`, `functions/src/subscription/` (new)
**Description:** Apple REQUIRES all digital content purchases via IAP (Guideline 3.1.1). No IAP package exists. SHIP BLOCKER.
**Acceptance Criteria:**
- [ ] IAP products created in App Store Connect (Crush+ monthly/yearly auto-renewable)
- [ ] Purchase flow: user taps → Apple payment sheet → confirmed → entitlement granted
- [ ] Restore purchases flow working
- [ ] Server-side receipt validation via Cloud Function
- [ ] Grace period handling
- [ ] Sandbox testing passes on real device
**Testing:** Sandbox purchase/restore on real iOS device; receipt validation test.

---

## STORE-APL-002: Set Age Rating to 17+
**Files:** App Store Connect (configuration)
**Description:** Dating apps must be 17+. Age rating questionnaire must reflect: UGC, meeting strangers, location-based features.
**Acceptance Criteria:**
- [ ] Questionnaire completed accurately
- [ ] Rating shows 17+
- [ ] Age gate in app (18+ confirmation during onboarding)
**Testing:** Verify rating in App Store Connect preview.

---

## STORE-APL-003: Fill Out Privacy Nutrition Labels
**Files:** App Store Connect (configuration)
**Description:** Declare all collected data: Contact Info, Location, User Content, Identifiers, Usage Data, Diagnostics.
**Acceptance Criteria:**
- [ ] All data categories declared with usage purpose
- [ ] Declarations match actual app behavior
- [ ] Declarations match privacy policy
- [ ] ATT usage declared
**Testing:** Review each declaration against codebase data collection.

---

## STORE-APL-004: Create iPad Screenshots for App Store Listing
**Files:** Design assets
**Description:** iPad screenshots required since app supports iPad. Sizes: iPad Pro 12.9" (2048x2732), iPad Pro 11" (1668x2388).
**Acceptance Criteria:**
- [ ] 5+ screenshots per iPad size: discovery, profile, chat, match, settings
- [ ] Screenshots show adaptive layout (not stretched mobile UI)
- [ ] Uploaded to App Store Connect
**Testing:** Run on iPad simulator; capture at required resolutions.

---

## STORE-APL-005: App Review Guidelines Compliance Check
**Files:** Various (depends on findings)
**Description:** Comprehensive check against Apple Review Guidelines: content moderation (1.1.4), UGC reporting (1.2), no placeholders (2.1), privacy (5.1).
**Acceptance Criteria:**
- [ ] Content moderation verified (profanity filter, image moderation, report/block)
- [ ] All placeholder/debug content removed from release
- [ ] Privacy policy accessible in-app and on App Store
- [ ] Terms of service and community guidelines accessible
- [ ] Third-party licenses included
- [ ] App Review notes prepared with test account
**Testing:** Fresh install test; report/block test; content moderation test.

---

## STORE-APL-006: Implement Subscription Management UI
**Files:** `lib/features/subscription/presentation/screens/paywall_screen.dart` (new), `subscription_management_screen.dart` (new)
**Description:** Apple requires: clear paywall, subscription management, localized pricing, ToS/PP links, restore button.
**Acceptance Criteria:**
- [ ] Paywall with feature comparison, StoreKit-localized pricing, ToS/PP links
- [ ] Restore Purchases button visible without scrolling
- [ ] Subscription management or link to Apple settings
- [ ] No dark patterns or misleading trial language
**Testing:** Verify localized pricing in different Sandbox regions.

---

## STORE-APL-007: Configure App Store Connect Metadata
**Files:** App Store Connect (configuration)
**Description:** Complete all metadata: name, subtitle, description, keywords, category, support URL.
**Acceptance Criteria:**
- [ ] App name, subtitle (30 chars), description (4000 chars)
- [ ] Keywords optimized (100 char limit)
- [ ] Category: Social Networking (primary), Lifestyle (secondary)
- [ ] Support and marketing URLs live
**Testing:** Verify URLs load; preview in App Store Connect.

---

## STORE-APL-008: Prepare App Review Notes and Demo Account
**Files:** App Store Connect, Firebase Console
**Description:** Reviewer needs demo accounts with pre-populated data to test matching and chat.
**Acceptance Criteria:**
- [ ] Two test accounts with complete profiles and pre-existing match
- [ ] App Review notes: sign-in instructions, feature walkthrough, known limitations
- [ ] Notes include: "Location permission required" notice
**Testing:** Follow review notes step-by-step as mock reviewer.
