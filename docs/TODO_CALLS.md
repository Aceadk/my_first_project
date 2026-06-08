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

## CALL-011: WebRTC Calling Parity for Web

**Files:** `/Users/ace/crush-web/apps/web/**`, shared RTC services, web call UI routes
**Description:** The CEO directive targets web as a first-class platform. The current web backlog still lacks audio/video calling. Define and implement the minimum viable WebRTC parity path for browser calling, device permission UX, and responsive call surfaces.
**Acceptance Criteria:**

- [ ] Product decision records whether browser calling is required, deferred, or unsupported
- [ ] Web app supports browser-based audio/video call setup with permission prompts and failure recovery
- [ ] Call UI works on desktop and tablet browser widths with intentional responsive layout
- [ ] Call signaling/auth rules stay aligned with the existing backend call model
- [ ] Web Permissions-Policy permits camera/microphone only on approved calling routes/origins
- [ ] Reconnect, decline, missed-call, end-call, device selection, and denied-permission states are handled
- [ ] Marketing and FAQ claims match the deployed browser capability

**Testing:** Browser smoke tests in Chrome/Safari/Firefox, manual device permission verification, and backend signaling regression coverage.
**Status:** open — P2 until mobile call reliability and the product decision are complete.

---
