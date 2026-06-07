# Calls Capability & Decision (Phase 9 Step 20)

- Date: 2026-06-07
- Decision owner: product (answered 2026-06-07): **web calling = mobile-only for
  now** (do not build web WebRTC calling this phase).

## Canonical backend support
- `generateAgoraToken` / `getAgoraToken` callables mint Agora RTC tokens.
- REST `POST /v1/calls/start` + `POST /v1/calls/end` for call lifecycle records.
- There is **no bespoke WebRTC signaling** server — Agora's SDK handles transport;
  the backend only authorizes (tokens) and records. This means web calling, if
  ever built, would use the **Agora Web SDK** with the same token callable.

## Mobile (source of truth) — status
Implemented (`lib/features/calls`): `call_service`, `call_repository`,
`call_bloc`, `callkit_service`, `native_pip_service`, `call_quality_service`, and
the CallKit bridge in `lib/app.dart`. Covers native video rendering, call
lifecycle, CallKit/PushKit incoming-call UX, and Picture-in-Picture.

**Remaining for mobile (operational, not code):** real-device validation —
- ☐ 📱 iOS PushKit + CallKit incoming call (locked/background/foreground).
- ☐ 📱 Android ConnectionService/full-screen-intent incoming call.
- ☐ 📱 Native video rendering + camera/mic permissions on real devices.
- ☐ 📱 Picture-in-Picture (iOS + Android) during an active call.
- ☐ 📱 Call quality / reconnect under network changes; call history persists.

(Tracked as release-gate evidence in the infrastructure & release checklist.)

## Web — decision
**Not required now (mobile-only).** Rationale: large WebRTC build for a secondary
platform; the deployed web capability today is messaging only; backend has no
signaling beyond Agora tokens. Web users are directed to the mobile app for
video calls.

### Marketing claims aligned to deployed capability (done this phase)
- FAQ "Can I video chat on Crush?" → now states video calling is in the **mobile
  app**; on web you can message, continue in the app for calls.
- Features "Video Chat" card → "Video call your matches safely **in the Crush
  mobile app**".
- Safety page mention of "video calls" left as-is (generic product advice, true on
  mobile).

### If web calling is required later (scope checklist, NOT built)
- Add `agora-rtc-sdk-ng`; `/messages/[matchId]` call entry + a `/calls/[callId]`
  route.
- Mic/camera permission prompts + denied/permission-denied states (UX taxonomy).
- Join via `getAgoraToken`; publish/subscribe tracks; reconnect on network loss.
- Call history via `/v1/calls/start` + `/v1/calls/end` records.
- Then revert the marketing qualifications above.

## Done-when status (Step 20)
- ✅ Mobile calling implemented (code); device-validation matrix documented as
  operational hand-off.
- ✅ Web-calling decision made: **mobile-only**.
- ✅ Web marketing claims updated to match deployed capability (web = messaging;
  video = mobile app).
- ✅ Future web-calling implementation scope captured (not built, per decision).
