# Discovery UI Audit & Action-Layer Refactor — DISC-UI-001 / 002 / 003

- Date: 2026-05-30
- Scope: `lib/features/discovery/presentation/**` (deck screen, swipe card,
  action buttons, state views, responsive tokens)
- Source TODO: `docs/TODO_DISCOVERY_UI.md`
- Method: static read of the Flutter source + targeted refactor.
- Verification: the local Flutter SDK (3.44.0 / Dart 3.12.0, at
  `/Users/ace/Development/flutter`) was used to run `flutter analyze` and
  `flutter test` on every change — all green (see Test Plan and the Round 2
  addendum). A manual device / screen-reader pass is still recommended before
  release.
- See the **Round 2 addendum** at the end of this file for the follow-up fixes
  landed on 2026-05-31.

Legend: ✅ already solid · ⚠️ gap / risk · 🔧 changed in this commit · 🔎 needs
device or screen-reader verification.

---

## Summary

The discovery feature is already mature: action buttons, keyboard shortcuts,
responsive breakpoints, an explore-grid alternative, and dedicated
empty/error/skeleton views all pre-existed. This pass focused (per request) on a
**deep refactor of the action / accessibility layer** (DISC-UI-003), plus a
written audit of the responsive (001) and filter/empty-state (002) tasks.

| Task | State | Headline |
| --- | --- | --- |
| DISC-UI-001 (responsive deck) | ✅ audited | Card width capped at 500 on tablet/desktop; explore-grid alternative. Open: action-button column overflow on short viewports; explore-grid action/keyboard parity. |
| DISC-UI-002 (filter / empty / error) | ✅ audited | Dedicated empty/error/skeleton views with recovery actions. Open: screen-reader announcements on state transitions; zero-result-after-filter path. |
| DISC-UI-003 (accessible actions) | 🔧 refactored | Hardened `DeckActionButton`; unified every action path through one gated `_performSwipe`; added gesture-equivalent semantic hints; added widget tests. |

---

## What changed in this commit (DISC-UI-003)

### 1. `DeckActionButton` accessibility hardening — `deck_ui_helpers.dart`
- **Minimum 48dp hit target.** The rewind button renders at 44dp; the
  interactive area is now expanded to `kMinInteractiveDimension` (48dp) via a
  wrapping `SizedBox` + `Center`, **without** changing the visual circle size,
  satisfying Material / WCAG 2.5.5. The `GestureDetector` uses
  `HitTestBehavior.opaque` so the whole padded area is tappable.
- **Disabled state exposed non-visually.** `Semantics(enabled: isEnabled)` now
  tracks the `enabled` flag, so assistive tech announces the disabled state in
  addition to the existing colour/opacity dimming.
- **Tooltip.** Added a `Tooltip` (new optional `tooltip` prop, defaulting to
  `semanticLabel`) so pointer / hover (web+desktop) / long-press users get the
  same affordance label screen readers announce.

### 2. Unified action pipeline — `deck_screen.dart`
- Added `_performSwipe(...)` and a private `enum _SwipeAction { pass, like,
  superLike }`. This is now the single source of truth behind **all nine** ways
  to act on the current profile:
  - 3 drag-gesture callbacks (`onSwipeLeft/Right/Up` on `SwipeableCard`),
  - 3 on-screen `DeckActionButton`s (pass / super-like / like),
  - 3 keyboard handlers (`_handleKeyboardPass/Like/SuperLike`).
- Previously the completeness check → backend-allowance round-trip → event
  dispatch was copy-pasted at every one of those sites (~40 lines each). The
  duplication is removed; the gating logic and the dispatched
  `DiscoverySwiped*` / `DiscoverySuperLiked` events are now guaranteed identical
  across gesture, button, and keyboard entry points — directly serving the
  DISC-UI-003 requirement that non-swipe actions behave exactly like swipes.
- Behaviour parity preserved: `announceBlock` defaults to `true` (gesture +
  button paths still surface the "complete your profile" dialog on an incomplete
  profile) and is `false` for the keyboard path (previously silent). Super-like
  still respects `superLikesRemaining`. The bloc is captured **before** the first
  `await` so no stale `BuildContext` is touched.

### 3. Gesture-equivalent semantic hints — `deck_screen.dart`
Each action button now carries a `semanticHint` teaching the gesture mapping:
pass → "Same as swiping left", like → "Same as swiping right", super-like →
"Same as swiping up", rewind → "Same as swiping down".

### 4. Tests — `test/features/discovery/presentation/widgets/deck_action_button_test.dart` (new)
≥48dp hit target at size 44; visual size preserved at 52; tooltip mirrors label;
explicit tooltip honoured; `onTap` fires when enabled and never when disabled;
disabled button is dimmed; labelled button node published to assistive tech.

---

## DISC-UI-001 — Responsive deck layout (audit only)

- ✅ Card max width constrained: `LayoutBuilder` →
  `DsBreakpoints.responsiveValue(maxWidth, mobile: double.infinity, tablet: 500,
  desktop: 500)` inside a `ConstrainedBox` — prevents stretched, unreadable
  cards on large screens.
- ✅ Tablet/desktop non-swipe alternative: `_exploreMode` → `ExploreGridView`
  when `!DsBreakpoints.isMobile(width)`.
- ⚠️ **Action-button column overflow on short viewports.** The right-edge
  `Column` (rewind 44 + pass 52 + super-like 48 + like 52, three `DsSpacing.md`
  gaps, plus an overflowing badge) has no scroll/shrink guard in short landscape
  / split-screen heights. _Recommend:_ wrap in `SingleChildScrollView` or
  `FittedBox`, and/or shrink gaps when height is small. 🔎
- ⚠️ **Action buttons + keyboard shortcuts are swipe-branch only.** Confirm
  `ExploreGridView` cards expose their own like/pass/super-like affordance and
  that keyboard shortcuts remain available there. 🔎 (couples with DISC-UI-003).

## DISC-UI-002 — Filter UX, empty & error states (audit only)

- ✅ Distinct loading / empty / error states with recovery via
  `AsyncStateScaffold`: `DeckSkeletonList` / `DeckOutOfPeopleView` (refresh +
  passport upsell) / `DeckErrorStateView` (retry countdown + retry + passport).
- ⚠️ **No assistive announcement on state transitions.** The `BlocConsumer`
  `listenWhen` reacts to `errorMessage`, `newMatch`, `premiumGateSource` only;
  a screen-reader user is not told when the deck flips loading→empty/error.
  _Recommend:_ `SemanticsService.announce(...)` on `state.status` change. 🔎
- 🔎 **Verify zero-result-after-filter routing.** Filters live in
  `discovery_filters_settings_screen.dart`. Confirm an over-narrow filter set
  lands on `DeckOutOfPeopleView` with a "broaden your filters" recovery action,
  and that invalid ranges (min age > max age) are blocked at input.

---

## Recommended follow-ups (not in this commit — land with SDK available)

1. State + outcome announcements (002/003): extend the deck listener with
   `SemanticsService.announce` on status change and on like/pass/match.
2. Action-button overflow guard on short viewports (001).
3. Explore-grid action + keyboard parity (001/003).
4. Filter → zero-result recovery action + invalid-range guard (002).

---

## Test Plan (run on a machine with the Flutter SDK)

### Automated
```bash
flutter analyze lib/features/discovery test/features/discovery
flutter test test/features/discovery/presentation/widgets/deck_action_button_test.dart
flutter test test/features/discovery
```
- New: `deck_action_button_test.dart` (see §4).
- Keep green: `deck_screen_state_views_test.dart`, `discovery_bloc_test.dart`,
  and the broader discovery suite (the `_performSwipe` extraction must not change
  which events are dispatched).

### Manual — accessibility
- VoiceOver (iOS) / TalkBack (Android): focus each action button; confirm it
  announces label + "Same as swiping …" hint + button role + disabled state;
  tooltips appear on hover/long-press.
- Keyboard (web/desktop): ← → ↑ ↓ map to pass / like / super-like / rewind.
- Touch-target audit: every action button ≥ 48dp hit area incl. the 44dp rewind.

### Manual — responsive (DISC-UI-001)
- iPhone SE / Pixel / iPhone Pro Max; iPad portrait + landscape; web at
  800 / 1200 / 1600 px. Watch for action-button clipping in short landscape,
  cards not stretched beyond 500px, and intentional empty/error/skeleton states.

### Regression focus for the refactor
Because `_performSwipe` now backs gesture + button + keyboard, manually exercise
all three for like / pass / super-like and verify: identical gating, the
incomplete-profile dialog still appears for gesture/button (not keyboard),
super-like respects the remaining count, and rewind still works (unchanged).

---

## Round 2 addendum — follow-ups landed 2026-05-31 (verified)

The deferred items from the first pass were implemented and verified with the
local SDK. `flutter analyze` on all changed files: **No issues found.**
`flutter test test/features/discovery test/discovery_bloc_test.dart`: **53
passed.** `flutter test test/features/discovery/presentation`: **20 passed.**

1. **Action-button overflow guard (DISC-UI-001)** — `deck_screen.dart`.
   The right-edge action column (rewind/pass/super-like/like) had no overflow
   protection and could clip on short landscape / split-screen heights. It is
   now wrapped in `LayoutBuilder → SingleChildScrollView → ConstrainedBox(minHeight)
   → IntrinsicHeight → Column(center)` — the same pattern already used by
   `DeckOutOfPeopleView`. It stays centred when there is room and becomes
   scrollable when there is not. No visual change in the common case.

2. **Deck state-transition announcements (DISC-UI-002 / 003)** — `deck_screen.dart`.
   The `BlocConsumer` `listenWhen` now also fires on `status` change, and a new
   `_announceDeckStatus(...)` calls `DsAccessibility.announce(...)` on
   transitions: "Profiles ready" (ready) and "No more profiles nearby" (empty).
   It de-duplicates via `_lastAnnouncedStatus`. Loading/initial are intentionally
   silent (transient); errors are left to the existing auto-announced error
   snackbar to avoid double-speaking. Reuses the existing
   `DsAccessibility.announce` helper rather than calling `SemanticsService`
   directly.

3. **Explore-grid semantics fix (DISC-UI-001 / 003)** — `explore_grid_view.dart`.
   On assessment, the "actions without swipes" requirement on tablet/desktop was
   **already met**: each grid card opens `other_user_profile_screen`, which has
   full Like/Pass buttons wired to the same `DiscoverySwiped*` events. The real
   defect was a redundant nested `Semantics(button: true)` wrapping another
   `Semantics(button: true)` on the card, producing a doubled/noisy node. Fixed:
   a single merged button node (`excludeSemantics: true` + `onTap`) with a hint
   ("Opens full profile with like and pass actions"). Nested-Semantics count is
   now 0.

4. **Filter invalid-range / zero-result (DISC-UI-002)** — assessed, **no change
   needed.** Age uses a two-thumb `RangeSlider`, so start > end is structurally
   impossible; the no-results state (`DeckOutOfPeopleView`) already offers an
   "Adjust filters" button (with an active-filter count badge), a refresh, and a
   passport path. Inventing extra validation here would have been speculative.

### Files changed in Round 2
- `lib/features/discovery/presentation/screens/deck_screen.dart` (overflow guard,
  announcements, `DsAccessibility` import)
- `lib/features/discovery/presentation/widgets/explore_grid_view.dart` (semantics)
