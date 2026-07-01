# Crush — Blaze Go-Live Runbook (crush-f5352) — 2026-06-12

Blaze is active, which unblocks **Storage** and **Cloud Functions**. This runbook completes
provisioning for every service and keeps **Crush App (Flutter)** and **crush-web (Next.js)** aligned.

Deploys run from YOUR authenticated machine (`firebase` CLI logged into crush.date.app, which
owns the project). Console steps run in the Firebase console as crush.date.app.

## Readiness verified (code side — done)
- `.firebaserc` → `crush-f5352` (both repos). `firebase.json` configures firestore (nam5),
  storage, database, functions, hosting.
- `firestore.rules` (incl. H-2 private split) + `firestore.indexes.json` (20 indexes, 3 field
  overrides) + `storage.rules` + `database.rules.json` present and valid.
- Mobile config on crush-f5352: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`,
  `macos/Runner/GoogleService-Info.plist`.
- Auth parity: mobile uses Email/Password + Google + Phone + Apple; web uses Google + Phone.
- App Check present both sides (web reCAPTCHA Enterprise; mobile DeviceCheck/Play Integrity).
- functions: Node 22, build `tsc`. `mirrorUserPrivateFields` (H-2) compiles clean.

---

## 1. Firestore — create DB + deploy rules/indexes
```bash
cd "Crush App"
firebase firestore:databases:create "(default)" --location nam5 --project crush-f5352  # if not created
firebase deploy --only firestore:rules,firestore:indexes --project crush-f5352
```
Verify: console > Firestore shows the database; Rules tab shows the H-2 `private` match; Indexes
building/enabled. Run `cd firestore-tests && npm test` (emulator) — H-2 + all rule tests green.

## 2. Storage — enable + deploy rules (Blaze)
```bash
firebase deploy --only storage --project crush-f5352
```
If the default bucket isn't created yet: console > Storage > Get started once (location should
match nam5 region family), then re-run. Verify bucket `crush-f5352.firebasestorage.app` exists
and Rules tab shows `storage.rules`.

## 3. Realtime Database — create instance + deploy rules
Console > Realtime Database > Create database (pick region; locked once chosen). Then:
```bash
firebase deploy --only database --project crush-f5352
```
Verify: RTDB URL exists; `NEXT_PUBLIC_FIREBASE_DATABASE_URL` (web) + mobile config point at it;
Rules tab shows `database.rules.json` (read_receipts/presence/typing paths).

## 4. Cloud Functions — deploy (Blaze)
```bash
cd "Crush App/functions" && npm ci && npm run build
cd .. && firebase deploy --only functions --project crush-f5352
```
Verify: all functions deploy (incl. triggers `onSubscriptionUpdated`, `syncLegacyDiscoveryFields`,
`mirrorUserPrivateFields`, callables). Check logs: `firebase functions:log --project crush-f5352`.
Note: first deploy enables required Google APIs (Cloud Build, Artifact Registry, Eventarc).

## 5. Authentication — enable providers (console)
Console > Authentication > Sign-in method > Add new provider:
- Email/Password — already enabled.
- **Google** — enable + set support email.
- **Phone** — enable.
- **Apple** — enable + configure Service ID/key (for web/Android Apple sign-in).
Add authorized domains (Settings > Authorized domains): `crush-f5352.firebaseapp.com`, your Vercel
domain, and the production domain (crush.app) when live.

## 6. Phone Verification
- Auth > Phone provider enabled (step 5).
- App Check must allow phone auth, OR reCAPTCHA fallback configured (web).
- **iOS**: upload an **APNs auth key (.p8)** to console > Project settings > Cloud Messaging
  (silent push powers iOS phone-auth + FCM). Use a **NEW** .p8 — the old `AuthKey_84457L85X6.p8`
  was leaked (see SECURITY_credential_rotation runbook).
- Test with a real device + a Firebase test phone number (Auth > Phone > test numbers) for CI.

## 7. Messaging (FCM)
- **Android**: works via `google-services.json` (present). No console step.
- **iOS**: upload the new APNs `.p8` (same as step 6).
- **Web**: console > Cloud Messaging > Web Push certificates > generate key pair → set
  `NEXT_PUBLIC_FIREBASE_VAPID_KEY` in Vercel.
  - ⚠️ GAP: web push **client registration is not wired** (service worker exists, but no
    `getToken`/`serviceWorker.register` in `apps/web/src`). Web will not receive push until a
    registration hook is added (request permission → `getToken({vapidKey})` →
    write `users/{uid}/fcmTokens/{token}`). Mobile push is unaffected. Track as follow-up.

## 8. App Check — register providers + enforce
Console > App Check:
- **Web** app → reCAPTCHA Enterprise (set `NEXT_PUBLIC_FIREBASE_APPCHECK_RECAPTCHA_KEY`).
- **Android** → Play Integrity. **iOS** → DeviceCheck/App Attest.
- Register a debug token for local dev only.
- Turn ON enforcement for Firestore, Storage, Functions AFTER clients ship with valid App Check
  (enforcing early will hard-block existing clients).

## 9. Vercel (web env) + redeploy
Ensure all keys from `crush-web/apps/web/.env.example` are set in Vercel (now includes App Check,
VAPID, measurement ID, API origin, Firebase Admin). Use a FRESH crush-f5352 admin key. Redeploy;
check `/api/health`.

---

## App ↔ Web parity (confirmed) + keep-in-sync rules
- Same project `crush-f5352`; same canonical user doc (shared fixture); same backend
  (functions/callables); same auth providers; same App Check posture; both write
  `users/{uid}/fcmTokens`.
- `firestore.rules` ↔ `functions/firestore.rules` must stay identical (CI rules-sync enforces).
- `apps/web/.env.example` synced to the full template on 2026-06-12.
- H-2 private-split: deploy rules + `mirrorUserPrivateFields` + run backfill on BOTH before the
  Phase 2 cutover (see `h2_user_private_split_runbook_2026-06-12.md`).

## Go-live verification checklist
- [ ] Firestore reads/writes succeed under rules; emulator tests green.
- [ ] Storage upload/download works (profile photo) under storage.rules.
- [ ] RTDB presence/typing/read-receipts work.
- [ ] Functions deployed; callables + triggers fire (check logs).
- [ ] Sign in via Email, Google, Phone, Apple on web + a device.
- [ ] Phone OTP delivered on a real device (iOS needs APNs key).
- [ ] Push: Android + iOS device receive a test notification.
- [ ] App Check enforcement ON only after clients ship; no legit traffic blocked.
- [ ] Vercel `/api/health` green on a fresh deploy with the new admin key.
```
