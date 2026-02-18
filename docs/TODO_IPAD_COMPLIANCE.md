# TODO: iPad Compliance — Critical Store Rejection Prevention
**Priority:** P0 – Critical (Apple rejects apps with broken iPad layouts)
**Estimated Effort:** 80-120 hours
**Dependencies:** TODO_RESPONSIVE_DESIGN.md
**Assigned:** AI + Developer

---

## IPAD-001: Audit All 48 Screens for Responsive Layout
**Files:** All files in `lib/features/*/presentation/screens/*.dart`
**Description:** Every screen must use responsive layout (LayoutBuilder, MediaQuery, or DsBreakpoints). Identify screens with NO responsive handling. The responsive infrastructure exists (`AdaptiveLayout`, `DsBreakpoints`, `ResponsiveContext`) but most screens don't use it.
**Current State:** Design system provides `AdaptiveLayout`, `AdaptiveScaffold`, `AdaptiveGrid`, `DsBreakpoints`, `ResponsiveContext` extension — but actual screen usage is minimal.
**Acceptance Criteria:**
- [ ] Every screen audited for responsive behavior
- [ ] Every screen uses LayoutBuilder or DsBreakpoints for layout decisions
- [ ] No hardcoded widths/heights that break on iPad
- [ ] Content max-width constrained on screens > 600px wide
**Testing:** Run on iPad Air 11" simulator in portrait and landscape.

### Screens Requiring iPad Layout Work (Known Issues):

| Screen | File | Issue |
|--------|------|-------|
| DeckScreen | `discovery/presentation/screens/deck_screen.dart` (1765 lines) | Full-screen card, no tablet adaptation |
| ChatScreen | `chat/presentation/screens/chat_screen.dart` (3230 lines) | No split-view, no responsive layout |
| ChatListScreen | `chat/presentation/screens/chat_list_screen.dart` | No master-detail for iPad |
| ProfileEditScreen | `profile/presentation/screens/profile_edit_screen.dart` | No two-column form layout |
| BasicInfoScreen | `auth/presentation/screens/basic_info_screen.dart` (37KB) | Form not tablet-optimized |
| SignUpScreen | `auth/presentation/screens/sign_up_screen.dart` (67KB) | Stretched on wide screens |
| CallScreen | `calls/presentation/screens/call_screen.dart` | Controls spacing not adaptive |
| VideoCallScreen | `calls/presentation/screens/video_call_screen.dart` | Stub - needs iPad PiP |
| SettingsScreen | `settings/presentation/screens/settings_screen.dart` | OK but dialogs need constraining |

---

## IPAD-002: Implement Master-Detail Pattern for Chat
**Files:** `lib/features/chat/presentation/screens/chat_list_screen.dart`, `chat_screen.dart`
**Description:** On iPad/tablet (>600px), show conversation list and active chat side-by-side using AdaptiveLayout. This is the most impactful iPad UX improvement.
**Acceptance Criteria:**
- [ ] iPad landscape: conversation list (320px) + chat (remaining) side-by-side
- [ ] iPad portrait: conversation list (320px) + chat (remaining) side-by-side
- [ ] iPhone: single-column navigation (current behavior preserved)
- [ ] Split View (1/2): graceful degradation to single column
- [ ] Slide Over (320pt): single column
**Testing:** iPad Pro 12.9" simulator in all orientations + Split View.

---

## IPAD-003: Constrain Content Width on Large Screens
**Files:** All screen files
**Description:** On iPad/desktop, content (text, forms, cards) must be constrained to 600-800px max width to prevent stretched, unreadable layouts. Use DsBreakpoints.contentMaxWidth().
**Acceptance Criteria:**
- [ ] All text content stays within 40-70 characters per line
- [ ] Forms centered with max-width 600px on tablet
- [ ] Card layouts max 800px on desktop
- [ ] Settings screens constrained to readable width
**Testing:** Visual check on iPad Pro 12.9" in landscape.

---

## IPAD-004: Fix Bottom Sheets and Dialogs for iPad
**Files:** All files using `showModalBottomSheet`, `showDialog`, `showCupertinoModalPopup`
**Description:** Bottom sheets must use proper iPad presentation (constrained width, popover style). Dialogs must not be tiny centered boxes on 13" screens. Action sheets MUST have sourceView/sourceRect on iPad (crashes without it on UIAlertController.ActionSheet).
**Acceptance Criteria:**
- [ ] Bottom sheets constrained to max 500px width on iPad
- [ ] Dialogs centered with max 400px width on iPad
- [ ] No full-width bottom sheets on 13" iPad
- [ ] Action sheets use popover presentation on iPad
**Testing:** Trigger every bottom sheet and dialog on iPad Pro 12.9".

---

## IPAD-005: Orientation Change Handling
**Files:** All stateful screens
**Description:** Test every screen in portrait AND landscape on iPad. Verify: no content clipping, form state preserved, scroll position maintained, keyboard handling adapts.
**Acceptance Criteria:**
- [ ] All screens render correctly in both orientations
- [ ] State preserved during rotation (form data, scroll position)
- [ ] Keyboard avoidance adapts to orientation changes
- [ ] Media aspect ratios maintained during rotation
**Testing:** Rotate iPad during active operations (typing, scrolling, video playing).

---

## IPAD-006: Multitasking Support (Split View, Slide Over, Stage Manager)
**Files:** All screens
**Description:** App must work correctly in Split View (1/3, 1/2, 2/3 width), Slide Over (320pt), and Stage Manager (resizable windows on M-series iPads).
**Acceptance Criteria:**
- [ ] Split View 1/2: all screens functional, compact layout
- [ ] Split View 1/3: graceful degradation, no crashes
- [ ] Slide Over (320pt): phone-like layout, fully functional
- [ ] Size class changes don't cause state loss
- [ ] Real-time features (chat, notifications) work in all modes
**Testing:** Test in all Split View configurations on iPad Pro with Stage Manager.

---

## IPAD-007: External Keyboard and Trackpad/Mouse Support
**Files:** All text input screens, all interactive elements
**Description:** Support external keyboard navigation: Tab between fields, Enter to submit, Escape to dismiss. Support trackpad/mouse: hover states, proper cursor changes.
**Acceptance Criteria:**
- [ ] Tab moves between form fields in correct order
- [ ] Enter submits forms (where appropriate)
- [ ] Escape dismisses modals and bottom sheets
- [ ] Hover states on interactive elements (buttons, cards, links)
- [ ] Mouse cursor changes on interactive elements (pointer on buttons)
- [ ] Text fields work with hardware keyboard
- [ ] Apple Pencil Scribble works in text fields
**Testing:** Connect Magic Keyboard to iPad, test all form screens.

---

## IPAD-008: Discovery Deck iPad Adaptation
**Files:** `lib/features/discovery/presentation/screens/deck_screen.dart`, `widgets/swipe_card.dart`
**Description:** The swipe deck is designed for phone-size screens. On iPad, cards should be constrained width, action buttons repositioned, and consider a grid-based explore view as alternative.
**Acceptance Criteria:**
- [ ] Card max width 500px centered on iPad
- [ ] Action buttons (like/pass/super-like) responsive positioning
- [ ] Swipe gesture works on large touch targets
- [ ] Profile overlay content readable on iPad (not stretched)
- [ ] Consider adding keyboard shortcuts (← pass, → like, ↑ super-like)
**Testing:** iPad Air 10.9" and iPad Pro 12.9" in portrait and landscape.

---

## IPAD-009: Verify iPad App Icon Sizes
**Files:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
**Description:** iPad requires additional icon sizes: 76x76@1x, 83.5x83.5@2x (167x167). Verify all required sizes are present.
**Acceptance Criteria:**
- [ ] 76x76@1x iPad icon present
- [ ] 83.5x83.5@2x (167x167) iPad Pro icon present
- [ ] 1024x1024 App Store icon present
- [ ] All icons match current branding
**Testing:** Verify in Xcode Assets catalog.

---

## IPAD-010: Launch Screen Configuration for iPad
**Files:** `ios/Runner/Base.lproj/LaunchScreen.storyboard`
**Description:** Verify launch screen renders correctly on all iPad sizes. Flutter default LaunchScreen.storyboard should work but verify no layout issues.
**Acceptance Criteria:**
- [ ] Launch screen fills entire screen on all iPad models
- [ ] No black bars or misaligned elements
- [ ] Brand colors and logo (if any) centered correctly
**Testing:** Launch app on iPad Mini, iPad Air, iPad Pro 11", iPad Pro 12.9".

---

## IPAD-011: Verify UIDeviceFamily Includes iPad
**Files:** `ios/Runner.xcodeproj/project.pbxproj`
**Description:** Flutter includes both iPhone (1) and iPad (2) in UIDeviceFamily by default. Verify this hasn't been overridden to iPhone-only.
**Acceptance Criteria:**
- [ ] `TARGETED_DEVICE_FAMILY = "1,2"` in Xcode project
- [ ] App available for iPad in App Store Connect
**Testing:** Check Xcode project settings; verify in App Store Connect.
