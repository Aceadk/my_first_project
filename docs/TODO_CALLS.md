# TODO: Calls Module (Audio & Video)

**Priority:** P1 – High
**Estimated Effort:** 60-90 hours
**Dependencies:** WebRTC backend (Agora/Twilio/LiveKit), CallKit (iOS), ConnectionService (Android), VoIP Push
**Assigned:** AI + Developer

---

## CALL-001: Integrate WebRTC Video Calling SDK

**Files:** `lib/features/calls/presentation/screens/video_call_screen.dart`, `lib/features/calls/data/services/call_service.dart`, `pubspec.yaml`
**Description:** `VideoCallScreen` remains a stub for actual media rendering, but `CallService` no longer auto-connects via `Future.delayed`. It now attempts Cloud Function signaling (`initiateCall` / `answerCall` / `endCall`) with Firestore call-state sync and local fallback.
**Acceptance Criteria:**

- [ ] WebRTC SDK added to `pubspec.yaml`
- [ ] Real video rendering: local camera PiP + remote video full screen

- [ ] Adaptive video quality on poor network
      **Testing:** Unit test for signaling; widget test for layout; manual two-device test.

---

## CALL-002: Implement CallKit Integration (iOS)

**Files:** `lib/features/calls/data/services/callkit_service.dart` (new), `ios/Runner/AppDelegate.swift`
**Description:** Added native CallKit bridge (`crushhour/callkit` + `crushhour/callkit_events`) with iOS `CXProvider` coordinator in `AppDelegate`. Incoming-call reporting now supports remote-notification payload handling and native actions emit answer/decline/end/mute events to Flutter.
**Acceptance Criteria:**

- [ ] Native incoming call screen on VoIP push (even when backgrounded)

**Testing:** Manual test on physical iOS device for background and lock screen calls.

---

## CALL-003: Implement ConnectionService Integration (Android)

**Files:** `lib/features/calls/data/services/connection_service.dart` (new), `android/app/src/main/AndroidManifest.xml`
**Description:** Android equivalent of CallKit. Enables full-screen incoming call notification, Bluetooth/car system integration, DND bypass.
**Acceptance Criteria:**

- [ ] ConnectionService via `callkeep` package
- [ ] Full-screen heads-up notification when backgrounded
- [ ] Audio routing: speaker, earpiece, Bluetooth
- [ ] Ongoing call notification with timer
      **Testing:** Manual test on physical Android device.


## CALL-004: Build Incoming Call Screen

**Files:** `lib/features/calls/presentation/screens/incoming_call_screen.dart` (new)
**Description:** Added a dedicated Flutter incoming-call screen with caller identity, countdown, decline/audio/video quick actions, slide-to-answer affordance, and router/app wiring so `CallService.handleIncomingCall()` presents real UI instead of only updating state.
**Acceptance Criteria:**

**Testing:** Widget tests cover layout/actions, decline + accept flows, slide-to-answer behavior, and timeout handling in `test/incoming_call_screen_test.dart`; router coverage confirms the incoming-call route branch renders correctly in `test/router_create_router_test.dart`.

---

## CALL-005: Implement Call Signaling via Cloud Functions

**Files:** `functions/src/calls/signaling.ts` (new), `functions/src/index.ts`
**Description:** Added production signaling callables: `initiateCall`, `answerCall`, `endCall`, `addIceCandidate`, and `getIceServers`. Calls persist to Firestore `calls/{callId}` with participant validation, ring-timeout metadata, ICE candidate exchange via `calls/{callId}/iceCandidates`, and the exported trigger `enforceCallRingTimeout` moves unanswered ringing calls to `missed/timeout` after 30 seconds.
**Acceptance Criteria:**

**Testing:** Focused Cloud Function tests cover auth/validation helpers, ICE config, and signaling callable guards in `functions/test/call-signaling.test.js`; targeted build + test verification passes locally. Emulator integration coverage for full device-to-device signaling flow remains recommended.

---

## CALL-006: Implement Call History and Missed Call Tracking

**Files:** `lib/features/calls/data/services/call_service.dart`, `lib/features/calls/presentation/screens/call_history_screen.dart` (new)
**Description:** Call history now includes a dedicated paginated UI with pull-to-refresh and grouping. `CallService` performs best-effort Firestore persistence to per-user `users/{uid}/call_history` records with in-memory fallback, emits missed-call events, and app-host wiring presents local missed-call notifications that deep-link to `CrushRoutes.callHistory`.
**Acceptance Criteria:**

**Testing:** Widget tests cover grouped rendering, missed-call status display, pagination, and refresh behavior in `test/call_history_screen_test.dart`; service tests cover missed-call event emission/non-emission plus history persistence in `test/call_service_test.dart`; router coverage confirms the call-history branch in `test/router_create_router_test.dart`.

---

## CALL-007: Add Call Quality Monitoring and Adaptive Bitrate

**Files:** `lib/features/calls/data/services/call_quality_service.dart` (new), `lib/features/calls/presentation/screens/call_screen.dart`
**Description:** Replaced the static quality badge with sampled connection telemetry. `CallQualityService` now tracks latency, packet loss, bitrate, and frame rate, emits adaptive quality state, degrades video tier (`HD → SD → Audio`) on sustained poor quality, and flags reconnect attempts on severe degradation; `CallScreen` consumes that state for the connection indicator, automatic video fallback, and reconnect UI handling.
**Acceptance Criteria:**

**Testing:** Unit tests cover classification thresholds, adaptive degradation/recovery, reconnect triggers, and audio-call badge behavior in `test/call_quality_service_test.dart`; `test/features/calls/presentation/screens/call_screen_responsive_test.dart` keeps the call-screen compile path covered; manual throttling remains recommended on devices.

---

## CALL-008: Implement Picture-in-Picture for Video Calls

**Files:** `lib/features/calls/presentation/widgets/pip_video_overlay.dart` (new)
**Description:** Added native Android PiP entry path (`MainActivity` method channel + manifest support) and retained in-app PiP fallback overlay (`CallPiPOverlayService`). On minimize, app now attempts native PiP first, then falls back to draggable overlay.
**Acceptance Criteria:**

- [ ] iOS: AVPictureInPictureController (iOS 15+)

**Testing:** Manual test still required for true native PiP; in-app overlay path verified in development flow.

---

## CALL-009: Add VoIP Push Notifications

**Files:** `functions/src/calls/signaling.ts`, `lib/core/services/push_notification_service.dart`, `ios/Runner/AppDelegate.swift`
**Description:** Signaling now dispatches high-priority incoming-call FCM data messages and timeout fallback missed-call FCM notifications using user token store (`users/{uid}/fcmTokens`). iOS now includes CallKit bridge and remote-notification incoming-call reporting; PushKit VoIP token + PKPushRegistry path remains pending.
**Acceptance Criteria:**

- [ ] iOS: PushKit VoIP token registration triggering CallKit

**Testing:** Cloud Function unit tests for signaling lane are passing (`functions/test/call-signaling.test.js`). Native terminated-state VoIP behavior still requires physical iOS/Android validation.

---

## CALL-010: Implement Call Safety Features

**Files:** `lib/features/calls/presentation/widgets/call_safety_controls.dart` (new), `lib/core/services/screen_capture_service.dart` (new), `lib/features/calls/presentation/screens/call_screen.dart`, `ios/Runner/AppDelegate.swift`, `functions/src/calls/signaling.ts`
**Description:** Added dedicated in-call safety controls with first-call safety tip persistence (per match), quick report/block actions during calls, post-call safety check prompt, and iOS screen capture event handling (screenshot + recording start/stop). Capture events now trigger `notifyCallSafetyEvent` backend callable to notify the other user.
**Acceptance Criteria:**

**Testing:** Widget tests added for safety controls (`test/call_safety_controls_test.dart`), unit tests added for capture event parsing (`test/screen_capture_service_test.dart`), and signaling callable tests added for safety event path (`functions/test/call-signaling.test.js`).
