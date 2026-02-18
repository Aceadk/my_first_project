# TODO: Accessibility Module (WCAG 2.1 AA)
**Priority:** P1 – High
**Estimated Effort:** 40-55 hours
**Dependencies:** Design system (`lib/design_system/`), all feature screens
**Assigned:** AI + Developer

---

## A11Y-001: Add Semantic Labels to All Interactive Elements
**Files:** All screens and widgets across the app
**Description:** Many screens (especially ChatScreen with ZERO Semantics calls) lack semantic labels. Every interactive element needs proper `Semantics` widget wrapping.
**Acceptance Criteria:**
- [ ] All buttons have `Semantics(label:)` or `tooltip` property
- [ ] All text fields have `Semantics(label:)` describing purpose
- [ ] All icons/icon buttons have `semanticLabel` property
- [ ] All images have `semanticLabel` (decorative images excluded from semantics)
- [ ] All toggle switches have state announced: "Enabled"/"Disabled"
**Testing:** VoiceOver on iPhone/iPad; TalkBack on Android; automated Semantics tree audit.

---

## A11Y-002: Implement Focus Management and Keyboard Navigation
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`, `lib/features/discovery/presentation/screens/deck_screen.dart`, all form screens
**Description:** External keyboard users (iPad Magic Keyboard) cannot navigate the app. Tab order, focus indicators, and keyboard shortcuts missing.
**Acceptance Criteria:**
- [ ] Tab moves focus between interactive elements in logical order
- [ ] Focus indicator visible on focused element (outline or highlight)
- [ ] Enter activates focused button/link
- [ ] Escape dismisses dialogs/sheets
- [ ] Arrow keys navigate within lists and grids
- [ ] Keyboard shortcuts for discovery: ← pass, → like, ↑ super-like
**Testing:** iPad with Magic Keyboard; TalkBack with external keyboard.

---

## A11Y-003: Ensure Color Contrast Meets WCAG 2.1 AA (4.5:1)
**Files:** `lib/design_system/tokens/colors.dart`, `lib/design_system/theme/app_theme.dart`
**Description:** Audit all text/background color combinations for minimum 4.5:1 contrast ratio (AA). The glassmorphism design style may have low contrast on blurred backgrounds.
**Acceptance Criteria:**
- [ ] All body text: minimum 4.5:1 contrast ratio
- [ ] All large text (>=18pt): minimum 3:1 contrast ratio
- [ ] All interactive elements: minimum 3:1 against adjacent colors
- [ ] Glass/blur backgrounds: solid color fallback ensuring minimum contrast
- [ ] Color-only information (like/pass indicators) also conveyed via icon/text
**Testing:** Automated contrast ratio checker; manual audit of each theme variant.

---

## A11Y-004: Support Dynamic Type / Text Scaling
**Files:** `lib/design_system/tokens/typography.dart`, all screen files
**Description:** Users with visual impairments need to scale text. Ensure the app handles system text size settings (1.0x to 2.0x) without layout breakage.
**Acceptance Criteria:**
- [ ] All text uses `TextStyle` that respects `MediaQuery.textScaleFactor`
- [ ] No text truncated at 1.5x scale (most common accessibility setting)
- [ ] Layout doesn't overflow at 2.0x scale (maximum accessibility)
- [ ] Buttons and tap targets grow with text scale
- [ ] `textScaleFactor` capped at 2.0x to prevent extreme layouts
**Testing:** Widget tests at 1.0x, 1.5x, and 2.0x text scale; manual test with iOS/Android system font size.

---

## A11Y-005: Add Live Region Announcements for Dynamic Content
**Files:** `lib/features/chat/presentation/widgets/chat_typing_indicator.dart`, `lib/features/discovery/presentation/widgets/swipe_card.dart`, `lib/design_system/widgets/profile_completion.dart`
**Description:** Dynamic content changes (typing indicators, match notifications, progress updates) need to be announced to screen readers via live regions.
**Acceptance Criteria:**
- [ ] Typing indicator: "John is typing" announced as live region
- [ ] New message: "New message from John" announced
- [ ] Match celebration: "You matched with John!" announced
- [ ] Profile completion changes: "Profile 75% complete" announced
- [ ] Swipe result: "Liked John" / "Passed on John" announced
**Testing:** VoiceOver and TalkBack testing for each dynamic announcement.

---

## A11Y-006: Ensure Minimum Tap Target Sizes (44x44pt)
**Files:** All screens and widgets
**Description:** Small tap targets are inaccessible to users with motor impairments. Audit all interactive elements for minimum 44x44pt (iOS HIG) / 48x48dp (Material).
**Acceptance Criteria:**
- [ ] All buttons, icons, links meet minimum 44x44pt
- [ ] Close/dismiss buttons in dialogs/sheets meet minimum size
- [ ] Chat action buttons (reply, react, copy) meet minimum size
- [ ] List item tap areas extend to full row width
- [ ] Spacing between adjacent tap targets prevents mis-taps
**Testing:** Manual audit with accessibility inspector; automated size checking.

---

## A11Y-007: Add Reduced Motion Support
**Files:** `lib/design_system/animations/ds_animations.dart`, `lib/features/discovery/presentation/widgets/swipeable_card.dart`, `lib/design_system/widgets/match_celebration.dart`
**Description:** Users with vestibular disorders need reduced motion option. Check `MediaQuery.disableAnimations` and simplify/skip animations.
**Acceptance Criteria:**
- [ ] All animations check `MediaQuery.of(context).disableAnimations`
- [ ] Swipe card: instant position snap instead of physics animation
- [ ] Match celebration: static display instead of particle animation
- [ ] Page transitions: fade instead of slide
- [ ] Haptic feedback disabled with reduced motion
**Testing:** Enable Reduce Motion in iOS/Android settings; verify all animations respect preference.

---

## A11Y-008: Add Semantic Labels to All Images and Media
**Files:** All image widgets, `lib/design_system/widgets/crush_avatar.dart`, `lib/design_system/widgets/verification_badge.dart`
**Description:** Profile photos, avatars, badges, and decorative images need proper semantic labels. Decorative images should be excluded from semantics.
**Acceptance Criteria:**
- [ ] Profile photos: "John's profile photo, photo 2 of 5"
- [ ] Avatars: "John's avatar"
- [ ] Verification badge: "Verified profile"
- [ ] Match celebration: "Match celebration with John"
- [ ] Decorative images: `excludeFromSemantics: true`
**Testing:** VoiceOver/TalkBack testing; widget tests for Semantics labels.
