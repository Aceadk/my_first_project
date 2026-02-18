# TODO: Responsive Design Module
**Priority:** P0-P1 – High
**Estimated Effort:** 50-70 hours
**Dependencies:** Design system tokens (`lib/design_system/tokens/breakpoints.dart`), AdaptiveLayout (`lib/design_system/widgets/adaptive_layout.dart`)
**Assigned:** AI + Developer

---

## RESP-001: Integrate DsBreakpoints into Chat Screens
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`, `chat_list_screen.dart`, `matches_screen.dart`, `message_requests_screen.dart`
**Description:** Chat screens have ZERO responsive code. On tablet/desktop, implement master-detail layout. Message bubbles need max width constraints.
**Acceptance Criteria:**
- [ ] `chat_list_screen.dart` uses `AdaptiveLayout` for list + detail on tablet (>=600px)
- [ ] `chat_screen.dart` constrains message bubbles to max 480px on tablet/desktop
- [ ] `matches_screen.dart` uses `DsBreakpoints.gridColumnsOf()` (2 cols tablet, 3 desktop)
- [ ] All chat widgets respect `DsBreakpoints.contentMaxWidth()`
**Testing:** Widget tests at 360px, 600px, 1024px, 1440px. Visual regression on tablet simulator.

---

## RESP-002: Add Responsive Layout to Discovery Deck
**Files:** `lib/features/discovery/presentation/screens/deck_screen.dart`, `swipe_card.dart`, `deck_card_stack.dart`
**Description:** Discovery deck is full-screen only. On tablet, center card at max 480px. On desktop, add side panel for profile details.
**Acceptance Criteria:**
- [ ] Card centered with max width on tablet/desktop
- [ ] Action buttons remain centered below card
- [ ] Optional detail panel on desktop (>=1024px)
- [ ] Swipe physics work correctly at constrained width
**Testing:** Widget tests at breakpoints; manual swipe testing on iPad; 60fps verification.

---

## RESP-003: Add Tablet Layout to Profile Screens
**Files:** `lib/features/profile/presentation/screens/profile_edit_screen.dart`, `profile_view_screen.dart`, `profile_media_screen.dart`
**Description:** Profile edit stretches edge-to-edge on tablet. Add two-column form layout and constrain content width.
**Acceptance Criteria:**
- [ ] Two-column field layout on tablet+ via `DsBreakpoints.of()`
- [ ] Form fields max width 720px on tablet
- [ ] Photo grid uses `DsBreakpoints.gridColumnsOf()` (2 mobile, 3 tablet, 4 desktop)
- [ ] All profile sheets constrain max width on tablet
**Testing:** Widget tests; manual verification on iPad.

---

## RESP-004: Adopt AdaptiveScaffold in Settings Screens
**Files:** `lib/features/settings/presentation/screens/settings_screen.dart` and all sub-settings screens
**Description:** Settings screens use single-column list without `AdaptiveLayout`. On tablet/desktop, use master-detail: categories left, detail right.
**Acceptance Criteria:**
- [ ] Settings list as `sidePanel`, selected sub-page as `body` in `AdaptiveLayout`
- [ ] Tablet (>=600px): tap category shows detail in right panel
- [ ] Mobile (<600px): push navigation preserved
- [ ] Content areas respect `DsBreakpoints.contentMaxWidth()`
**Testing:** Widget tests at breakpoints; manual test on iPad.

---

## RESP-005: Responsive Auth and Onboarding Screens
**Files:** `lib/features/auth/presentation/screens/`, `lib/design_system/widgets/auth_scaffold.dart`
**Description:** Auth forms stretch full width on tablet. Constrain to max 480px centered with card-style layout.
**Acceptance Criteria:**
- [ ] `auth_scaffold.dart` constrains to max 480px, centered on tablet+
- [ ] Card-style layouts on tablet (form inside glass container)
- [ ] OTP and phone fields properly sized
- [ ] Background fills viewport, form stays centered
**Testing:** Widget tests at 360px, 600px, 1024px.

---

## RESP-006: Responsive Likes-You and Weekly Picks Grids
**Files:** `lib/features/discovery/presentation/screens/likes_you_screen.dart`, `weekly_picks_screen.dart`, `story_viewer_screen.dart`
**Description:** Grid screens don't use `DsBreakpoints.gridColumnsOf()`. Add responsive column counts.
**Acceptance Criteria:**
- [ ] Dynamic column count via `DsBreakpoints.gridColumnsOf()`
- [ ] Grid cards maintain aspect ratio
- [ ] Story viewer constrains to max 480px on tablet/desktop
**Testing:** Widget tests at breakpoints; scrolling performance test.

---

## RESP-007: Home Screen Navigation Adapts to Tablet/Desktop
**Files:** `lib/presentation/screens/home_screen.dart`, `lib/design_system/widgets/glass_bottom_nav_bar.dart`
**Description:** Bottom nav appropriate for mobile but not tablet/desktop. Convert to NavigationRail on tablet, NavigationDrawer on desktop.
**Acceptance Criteria:**
- [ ] Mobile (<600px): bottom navigation bar
- [ ] Tablet (600-1024px): NavigationRail on left side
- [ ] Desktop (>=1024px): expanded NavigationDrawer
- [ ] Navigation state preserved across layout changes
**Testing:** Widget tests at three breakpoints; manual resize testing.

---

## RESP-008: Audit Design System Usage Across All Screens
**Files:** All screen files
**Description:** Only 4 files reference responsive design system widgets. Systematic audit needed to identify screens not using breakpoints.
**Acceptance Criteria:**
- [ ] Audit report listing every screen's responsive adoption status
- [ ] Script flagging `MediaQuery.of(context).size.width` without `DsBreakpoints`
- [ ] Migration guide for converting screens
- [ ] Compact phone (<360px) verified on all critical screens
**Testing:** Run audit script; manual verification on compact device.
