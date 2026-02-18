# TODO: Onboarding Flow Module
**Priority:** P1 – High
**Estimated Effort:** 20-30 hours
**Dependencies:** Auth module, Profile module, responsive design system
**Assigned:** AI + Developer

---

## ONBOARD-001: Implement Progressive Disclosure Onboarding
**Files:** `lib/features/auth/presentation/screens/basic_info_screen.dart`, `lib/features/profile/presentation/screens/profile_setup_screen.dart`
**Description:** Current onboarding asks for all information at once (name, birthday, gender, orientation, photos, bio, interests, location). Implement progressive disclosure: collect minimal info first (name, age, photos), then prompt for additional details after first match or during browsing.
**Acceptance Criteria:**
- [ ] Step 1 (required): Name, birthday, gender (3 fields only)
- [ ] Step 2 (required): At least 2 photos
- [ ] Step 3 (optional, can skip): Bio, interests, orientation
- [ ] Skipped fields prompted later via contextual nudges
- [ ] Progress indicator showing current step
- [ ] Back navigation between steps preserves entered data
**Testing:** Widget test for step navigation; integration test for data persistence across steps.

---

## ONBOARD-002: Add Permission Rationale Screens
**Files:** `lib/features/auth/presentation/screens/` (new permission screens)
**Description:** Before requesting system permissions (location, notifications, camera, photos), show a custom rationale screen explaining why the permission is needed and what the user gets in return.
**Acceptance Criteria:**
- [ ] Location: "Find matches near you" with map illustration
- [ ] Notifications: "Know when you get a match" with notification illustration
- [ ] Camera: "Take photos for your profile" with camera illustration
- [ ] Photos: "Add your best photos" with gallery illustration
- [ ] Each screen has "Allow" (triggers system prompt) and "Not Now" (skips)
- [ ] Skipped permissions can be re-requested from settings
**Testing:** Widget test for each permission screen; manual test for system prompt triggering.

---

## ONBOARD-003: Responsive Onboarding Layout for iPad
**Files:** `lib/features/auth/presentation/screens/basic_info_screen.dart`, `lib/features/profile/presentation/screens/profile_setup_screen.dart`, `lib/design_system/widgets/auth_scaffold.dart`
**Description:** Onboarding screens use full-width layouts that look stretched on iPad. Constrain form width to 480px centered, with illustration/branding on the side panel on tablet.
**Acceptance Criteria:**
- [ ] Form fields constrained to max 480px width on tablet+
- [ ] Two-column layout on tablet: branding/illustration left, form right
- [ ] Bottom sheets (orientation selector, etc.) constrained width on iPad
- [ ] Keyboard handling works with external keyboard on iPad
**Testing:** Widget test at tablet breakpoints; manual test on iPad simulator.

---

## ONBOARD-004: Add Onboarding Analytics and Funnel Tracking
**Files:** `lib/features/auth/presentation/bloc/auth_bloc.dart`, `lib/core/services/analytics_service.dart`
**Description:** Track onboarding funnel to identify where users drop off. Log events for each step entry, completion, and abandonment.
**Acceptance Criteria:**
- [ ] Events: `onboarding_started`, `onboarding_step_completed{step}`, `onboarding_abandoned{step}`, `onboarding_completed`
- [ ] Time-on-step tracked for each step
- [ ] Drop-off rate calculated per step in analytics dashboard
- [ ] Photo upload success/failure tracked separately
**Testing:** Unit test verifying analytics events fire at correct points.

---

## ONBOARD-005: Implement Welcome Tutorial for First-Time Users
**Files:** `lib/features/discovery/presentation/screens/deck_screen.dart` (new overlay), `lib/core/services/onboarding_progress_service.dart`
**Description:** After onboarding, show a brief interactive tutorial overlay on the discovery deck explaining swipe gestures, like/pass buttons, and navigation. Dismiss after user completes first swipe.
**Acceptance Criteria:**
- [ ] Overlay shows on first visit to discovery deck
- [ ] Highlights: swipe right to like, swipe left to pass, tap for profile details
- [ ] Animated hand gesture demonstrating swipe
- [ ] "Got it" button to dismiss
- [ ] Never shows again after dismissal (persisted flag)
- [ ] Respects reduced motion preference
**Testing:** Widget test for overlay rendering; persistence test for dismiss flag.
