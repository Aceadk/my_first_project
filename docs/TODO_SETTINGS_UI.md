# TODO: Settings UI Module
**Priority:** P1-P2 – High to Medium
**Estimated Effort:** 30-45 hours
**Dependencies:** Subscription module, Notifications module, Responsive layout system
**Assigned:** AI + Developer

---

## SET-001: Add Subscription Management Navigation in Settings
**Files:** `lib/features/settings/presentation/screens/settings_screen.dart`, `lib/core/routing/settings_routes.dart`
**Description:** The "Manage subscription" button currently triggers `PlusCheckoutRequested()` (new checkout) instead of navigating to a management screen for Plus members.
**Acceptance Criteria:**
- [ ] "Manage subscription" for Plus users navigates to subscription management screen
- [ ] "Upgrade to Plus" for free users triggers checkout flow
- [ ] Add top-level settings tile for "Subscription" with current plan info
- [ ] Plus members see: "Plus Member - Renews on MM/DD/YYYY"
- [ ] Free members see: "Free Plan - Upgrade for unlimited likes"
**Testing:** Widget test for conditional button behavior; navigation test for route.

---

## SET-002: Constrain Dialogs and Bottom Sheets on iPad
**Files:** `lib/features/settings/presentation/screens/settings_screen.dart`, `lib/design_system/widgets/adaptive_dialog.dart` (new)
**Description:** All `showDialog()` and `showModalBottomSheet()` calls use unconstrained widths. On iPad, these stretch to full width. Create `AdaptiveDialog` and `AdaptiveBottomSheet` helpers that constrain width on tablets.
**Acceptance Criteria:**
- [ ] `AdaptiveDialog` utility: wraps `showDialog` with max width 540px on tablets
- [ ] `AdaptiveBottomSheet` utility: wraps `showModalBottomSheet` with max width 640px on tablets
- [ ] All settings dialogs migrated to use adaptive wrappers
- [ ] Centered positioning on large screens
**Testing:** Widget test with simulated iPad screen sizes; manual test on iPad simulator.

---

## SET-003: Complete Data Export Functionality (GDPR Article 20)
**Files:** `lib/core/services/data_export_service.dart`, `lib/features/settings/presentation/screens/account_actions_settings_screen.dart`
**Description:** GDPR requires data portability. Ensure the export service covers all user data and the UI provides progress feedback.
**Acceptance Criteria:**
- [ ] "Request Data Export" button in Account Actions settings
- [ ] Export includes: profile, photos, messages, matches, likes, preferences
- [ ] Cloud Function generates export asynchronously
- [ ] Progress feedback with push notification when complete
- [ ] Rate limited: max 1 export per 7 days
**Testing:** Integration test for export generation; widget test for progress UI.

---

## SET-004: Improve Account Deletion UX
**Files:** `lib/features/settings/presentation/screens/account_actions_settings_screen.dart`
**Description:** Account deletion exists but UX needs improvement: clearer warnings, "Download data first" prompt, type-to-confirm, and grace period display.
**Acceptance Criteria:**
- [ ] Multi-step flow: What will be deleted → Download data? → Confirm (type username)
- [ ] Grace period prominently displayed: "Deleted on {date}. Sign back in within 14 days to cancel."
- [ ] Optional reason selector for analytics
- [ ] Dialog constrained on iPad
**Testing:** Widget test for multi-step flow; dialog constraint test on tablet.

---

## SET-005: Add Theme Preview in Appearance Settings
**Files:** `lib/features/settings/presentation/screens/appearance_settings_screen.dart`
**Description:** Theme selection has no preview. Add visual preview cards showing mini mockups in each theme's colors.
**Acceptance Criteria:**
- [ ] Theme option cards with mini preview (profile card, chat bubble, button)
- [ ] Current theme highlighted with checkmark
- [ ] Premium themes gated behind subscription
- [ ] Smooth transition animation when switching
**Testing:** Widget test for theme card rendering; golden test for each theme.

---

## SET-006: Add Linked Accounts Management
**Files:** `lib/features/settings/presentation/screens/account_security_settings_screen.dart`
**Description:** Allow users to link/unlink additional auth providers (Google, Apple, Phone, Email) for account recovery.
**Acceptance Criteria:**
- [ ] "Linked Accounts" section showing provider status
- [ ] Link button triggers `linkWithCredential()`
- [ ] Unlink blocked if it's the last provider
- [ ] Clear error for already-linked accounts
**Testing:** Widget test for linked/unlinked states; unit test for link/unlink logic.
