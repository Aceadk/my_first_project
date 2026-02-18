# TODO: Discovery & Matching — UI
**Priority:** P0-P1
**Estimated Effort:** 30-40 hours
**Dependencies:** TODO_IPAD_COMPLIANCE.md, TODO_RESPONSIVE_DESIGN.md
**Assigned:** AI + Developer

---

## DISC-UI-001: Implement Responsive Deck Layout for iPad/Tablet
**Files:** `lib/features/discovery/presentation/screens/deck_screen.dart` (1765 lines)
**Description:** DeckScreen uses full-screen immersive card design. On iPad (>600px), constrain card to 500px centered, reposition action buttons, add breathing room. Use AdaptiveLayout.
**Acceptance Criteria:**
- [ ] Card max-width 500px on tablet/desktop, centered
- [ ] Action buttons (like/pass/super-like/rewind) repositioned below card on tablet
- [ ] Status bar (location banner, boost, weekly picks) repositioned for wide screens
- [ ] Landscape: card 50% width left, profile details 50% right
**Testing:** iPad Air + iPad Pro in portrait/landscape.

---

## DISC-UI-002: Add Accessibility to Swipe Card
**Files:** `lib/features/discovery/presentation/widgets/swipe_card.dart`
**Description:** SwipeCard has minimal accessibility. Add: semantic labels for profile properties, announce swipe hints, keyboard navigation, media progress semantics.
**Acceptance Criteria:**
- [ ] Profile name, age, distance announced by screen reader
- [ ] Swipe hint: "Swipe right to like, left to pass"
- [ ] Media progress bars have semantic labels ("Photo 2 of 5")
- [ ] Action buttons (like/pass/super-like) have proper semantic roles
- [ ] Video play/pause announced as toggle
**Testing:** VoiceOver testing on iPhone and iPad.

---

## DISC-UI-003: Add Keyboard-Based Swipe Alternative
**Files:** `lib/features/discovery/presentation/screens/deck_screen.dart`
**Description:** Users with motor disabilities cannot perform swipe gestures. Add button-based like/pass for accessibility. Also add keyboard shortcuts for iPad external keyboard users.
**Acceptance Criteria:**
- [ ] Large, visible like/pass buttons below card (always visible, not just on hover)
- [ ] Arrow key shortcuts: ← pass, → like, ↑ super-like, ↓ rewind
- [ ] Buttons meet 44x44pt minimum tap target
- [ ] Focus management: keyboard focus stays on card after action
**Testing:** VoiceOver + external keyboard on iPad.

---

## DISC-UI-004: Fix Video Player Error Handling
**Files:** `lib/features/discovery/presentation/widgets/swipe_card.dart`
**Description:** If video fails to load, shows infinite loading spinner with no timeout or fallback UI. Add timeout, error state, and fallback to photo.
**Acceptance Criteria:**
- [ ] Video loading timeout: 10 seconds
- [ ] On timeout/error: show fallback photo with "Video unavailable" overlay
- [ ] VideoPlayerController properly disposed on error
- [ ] No memory leak from cached failed controllers
**Testing:** Unit test with mocked video URL returning 404.

---

## DISC-UI-005: Implement Explore Grid View for iPad/Web
**Files:** New: `lib/features/discovery/presentation/screens/explore_screen.dart`
**Description:** On iPad/tablet, offer an alternative to swipe: a grid-based explore view showing 4-6 profile cards. Users tap to expand, then like/pass. Better UX for wide screens.
**Acceptance Criteria:**
- [ ] Grid layout with 2 columns (tablet) or 3 columns (desktop)
- [ ] Profile card shows: photo, name, age, distance
- [ ] Tap to expand into full profile view with like/pass actions
- [ ] Toggle between swipe and explore views
**Testing:** iPad Pro 12.9" in landscape with 3-column grid.

---

## DISC-UI-006: Fix Hardcoded Positioning in Deck UI
**Files:** `lib/features/discovery/presentation/screens/deck_screen.dart`, `widgets/swipe_card.dart`
**Description:** Multiple hardcoded pixel values: action buttons at 70px right margin, profile overlay at bottom: 90px/140px/240px. Replace with responsive spacing.
**Acceptance Criteria:**
- [ ] All pixel values replaced with DsSpacing tokens or responsive calculations
- [ ] Action button column uses DsBreakpoints.responsiveValue for positioning
- [ ] Profile overlay position adapts to screen height
- [ ] No content clipping on iPhone SE (smallest) or iPad Pro 12.9" (largest)
**Testing:** Run on iPhone SE 3rd gen and iPad Pro 12.9" simulator.

---

## DISC-UI-007: Add Haptic Feedback to Swipe Interactions
**Files:** `lib/features/discovery/presentation/widgets/swipeable_card.dart`
**Description:** Add haptic feedback using HapticService for: swipe threshold reached, like confirmed, pass confirmed, super-like, match celebration. Respect reduced motion preference.
**Acceptance Criteria:**
- [ ] Light haptic on swipe threshold
- [ ] Medium haptic on like/pass confirmation
- [ ] Heavy haptic on super-like
- [ ] Success haptic on match
- [ ] No haptics if prefers-reduced-motion is enabled
**Testing:** Manual test on physical device with haptic engine.
