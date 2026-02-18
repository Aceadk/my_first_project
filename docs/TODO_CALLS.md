# TODO: Calls Module (Audio & Video)
**Priority:** P1 – High
**Estimated Effort:** 60-90 hours
**Dependencies:** WebRTC backend (Agora/Twilio/LiveKit), CallKit (iOS), ConnectionService (Android), VoIP Push
**Assigned:** AI + Developer

---

## CALL-001: Integrate WebRTC Video Calling SDK
**Files:** `lib/features/calls/presentation/screens/video_call_screen.dart`, `lib/features/calls/data/services/call_service.dart`, `pubspec.yaml`
**Description:** `VideoCallScreen` is a stub displaying "Video calling is not yet configured." `CallService` simulates connections with `Future.delayed(3 seconds)`. Replace with real WebRTC SDK (Agora or LiveKit).
**Acceptance Criteria:**
- [ ] WebRTC SDK added to `pubspec.yaml`
- [ ] Real video rendering: local camera PiP + remote video full screen
- [ ] `_simulateCallConnection()` replaced with real signaling
- [ ] Camera/microphone permissions requested with context
- [ ] Adaptive video quality on poor network
**Testing:** Unit test for signaling; widget test for layout; manual two-device test.

---

## CALL-002: Implement CallKit Integration (iOS)
**Files:** `lib/features/calls/data/services/callkit_service.dart` (new), `ios/Runner/AppDelegate.swift`
**Description:** No CallKit integration. Required by Apple for apps with calling features. Without it, calls can't be received when backgrounded/locked.
**Acceptance Criteria:**
- [ ] CallKit package added and configured
- [ ] Native incoming call screen on VoIP push (even when backgrounded)
- [ ] Call actions from native UI: answer, decline, mute, end
- [ ] Recent calls appear in iOS Phone app
- [ ] Audio session management (interrupts music, resumes after)
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

---

## CALL-004: Build Incoming Call Screen
**Files:** `lib/features/calls/presentation/screens/incoming_call_screen.dart` (new)
**Description:** No Flutter-layer incoming call screen exists. `CallService.handleIncomingCall()` updates state but no UI presents it.
**Acceptance Criteria:**
- [ ] Caller name, photo, call type, animated ring effect
- [ ] Accept (green) and Decline (red) buttons
- [ ] Slide-to-answer gesture
- [ ] Auto-dismiss after 30 seconds (ring timeout)
- [ ] "Accept as Video" and "Accept as Audio" for video calls
**Testing:** Widget test for layout; animation test; navigation test.

---

## CALL-005: Implement Call Signaling via Cloud Functions
**Files:** `functions/src/calls/signaling.ts` (new), `functions/src/index.ts`
**Description:** Replace simulated connections with real signaling: `initiateCall`, `answerCall`, `endCall`, ICE candidate exchange via Firestore.
**Acceptance Criteria:**
- [ ] Firestore `calls/{callId}` as signaling channel
- [ ] TURN server credentials via `getIceServers` Cloud Function
- [ ] Call timeout: 30 seconds, auto-end with `missed` status
- [ ] Rate limiting: max 1 call per 10 seconds per user
**Testing:** Cloud Function unit tests; integration test for full signaling flow.

---

## CALL-006: Implement Call History and Missed Call Tracking
**Files:** `lib/features/calls/data/services/call_service.dart`, `lib/features/calls/presentation/screens/call_history_screen.dart` (new)
**Description:** `getCallHistory()` returns empty list with simulated delay. Implement persistent Firestore call history.
**Acceptance Criteria:**
- [ ] Call records in Firestore with: caller, receiver, type, duration, status, timestamps
- [ ] Call history screen with grouping, missed call highlighting
- [ ] Missed call push notifications
- [ ] Pull-to-refresh and pagination
**Testing:** Widget test for list rendering; Cubit test for state management.

---

## CALL-007: Add Call Quality Monitoring and Adaptive Bitrate
**Files:** `lib/features/calls/data/services/call_quality_service.dart` (new), `lib/features/calls/presentation/screens/call_screen.dart`
**Description:** Call screen shows static "HD" indicator. Implement real-time quality monitoring and adaptive video quality.
**Acceptance Criteria:**
- [ ] Track: latency, packet loss, bitrate, frame rate
- [ ] Dynamic indicator: "HD" (green), "SD" (yellow), "Poor" (red)
- [ ] Auto-reduce video quality on poor network (720p → 480p → audio only)
- [ ] Reconnection logic: auto-reconnect within 15 seconds
**Testing:** Unit test for threshold calculations; manual test with network throttling.

---

## CALL-008: Implement Picture-in-Picture for Video Calls
**Files:** `lib/features/calls/presentation/widgets/pip_video_overlay.dart` (new)
**Description:** Video call should continue in PiP window when user navigates away.
**Acceptance Criteria:**
- [ ] Android: Native PiP via manifest config
- [ ] iOS: AVPictureInPictureController (iOS 15+)
- [ ] Draggable floating window with remote video
- [ ] Tap returns to full call screen
**Testing:** Manual test on physical devices.

---

## CALL-009: Add VoIP Push Notifications
**Files:** `lib/core/services/push_notification_service.dart`, `ios/Runner/AppDelegate.swift`
**Description:** iOS needs APNs VoIP push for instant call delivery. Android needs high-priority FCM data messages.
**Acceptance Criteria:**
- [ ] iOS: PushKit VoIP token registration triggering CallKit
- [ ] Android: High-priority FCM with `priority: "high"` and `ttl: 0`
- [ ] Token stored in Firestore per user
- [ ] Fallback to regular FCM "Missed call" after timeout
**Testing:** Manual test on physical devices: app terminated → call received.

---

## CALL-010: Implement Call Safety Features
**Files:** `lib/features/calls/presentation/widgets/call_safety_controls.dart` (new)
**Description:** Dating app calls need: safety tips, quick block/report during call, screenshot/recording detection.
**Acceptance Criteria:**
- [ ] Safety tip banner on first call with a match
- [ ] Report/block buttons accessible during call
- [ ] Screenshot detection (iOS) notifying other party
- [ ] Screen recording warning
- [ ] Post-call safety check prompt
**Testing:** Widget test for safety controls; manual test for report flow during call.
