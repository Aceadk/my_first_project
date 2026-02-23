# Discovery & Matching Frontend Module

Priority: P0-P1
Scope: Swipe interface, matching algorithm, filters, location-based discovery, recommendation engine.

## Action Items

### [x] DISC-UI-001: Implement iPad-optimized grid discovery alternative

- **Description**: Swiping on a 13" iPad is ergonomically poor. Provide a Grid View for tablet/web users to browse profiles similarly to a catalog.
- **Affected Files**: lib/features/discovery/presentation/screens/deck_screen.dart
- **Acceptance Criteria**: Users on tablets have a toggle or automatic shift to view multiple profiles in a grid. Maintain responsive resizing.
- **Testing Requirements**: UI interaction tests on both phone (swipe) and tablet (grid) configurations.

### [x] DISC-UI-002: Refactor Swipe mechanics for 60FPS

- **Description**: Ensure the card swipe animation maintains perfect frame rates by removing heavy nested rebuilds. Use RepaintBoundary explicitly.
- **Affected Files**: lib/features/discovery/presentation/widgets/swipe_deck.dart
- **Acceptance Criteria**: DevTools performance timeline shows no dropped frames during swipe gestures on mid-range devices.
- **Testing Requirements**: Flutter driver benchmark test for swipe interactions.

### [x] DISC-UI-003: Haptic Feedback Integration & Accessibility Fallback

- **Description**: Add contextual haptics when reaching the threshold for a Like/Pass/Superlike. Include on-screen buttons as a hard fallback for users incapable of swipe gestures.
- **Affected Files**: lib/features/discovery/presentation/widgets/swipe_card.dart
- **Acceptance Criteria**: Distinct haptics for each action type using HapticFeedback. Buttons exist and pass VoiceOver accessibility tests.
- **Testing Requirements**: Device-level testing on physical iOS and Android devices.
