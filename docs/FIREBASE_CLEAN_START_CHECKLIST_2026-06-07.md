# Firebase Clean-Start Checklist

- Date: 2026-06-07
- Decision: Create a completely new Firebase project under a new Google account.
- Source project to retire: `crush-265f7`
- Data migration: None. Existing Auth users, Firestore/RTDB data, Storage objects,
  FCM tokens, and other old-project resources are intentionally discarded.
- Supported targets in this checklist: Android, iOS, Crush Web, Firebase backend.

## Non-Negotiable Order

1. Create and configure the new Firebase project.
2. Connect backend, Android, iOS, and Crush Web.
3. Validate every critical flow against the new project.
4. Remove all runtime references to `crush-265f7`.
5. Delete `crush-265f7` last.

Deleting the old project first will make the current app/backend unusable before
the replacement is ready.

## Values To Choose

Set these placeholders before running commands:

```bash
export OLD_PROJECT_ID="crush-265f7"
export NEW_FIREBASE_ACCOUNT="NEW_GOOGLE_ACCOUNT_EMAIL"
export NEW_PROJECT_ID="NEW_GLOBALLY_UNIQUE_PROJECT_ID"
```

Rules:

- The new project ID must be globally unique, lowercase, and 6-30 characters.
- A deleted project ID cannot be reused.
- Keep the shipping Android package and Apple bundle ID as `com.ace.crush`
  unless intentionally creating entirely different App Store/Play Store apps.

## Phase 1 - Create The New Firebase Project

### 1. Sign Into The New Google Account

Use a separate browser profile or private window so the old and new accounts are
not confused.

For CLI access:

```bash
firebase logout
firebase login
firebase projects:list

gcloud auth login "$NEW_FIREBASE_ACCOUNT"
gcloud config set account "$NEW_FIREBASE_ACCOUNT"
```

Verify the displayed account before every destructive or deployment command.

### 2. Create The Project

Recommended: Firebase console -> Add project, signed into the new account.

- Choose the permanent `NEW_PROJECT_ID`.
- Enable Google Analytics if Analytics/Crashlytics/Performance reporting is
  required.
- Link a valid billing account/Blaze plan. Functions and several production
  Firebase capabilities require billing.

CLI alternative:

```bash
firebase projects:create "$NEW_PROJECT_ID" --display-name "Crush"
gcloud billing accounts list
gcloud billing projects link "$NEW_PROJECT_ID" \
  --billing-account="YOUR_BILLING_ACCOUNT_ID"
```

Then verify:

```bash
firebase projects:list
gcloud config set project "$NEW_PROJECT_ID"
gcloud projects describe "$NEW_PROJECT_ID"
```

### 3. Create Core Firebase Services

In the Firebase console:

1. Authentication -> Get started.
2. Firestore Database -> create `(default)` in `nam5`.
3. Realtime Database -> create the default instance.
4. Storage -> Get started and choose the intended production location.
5. Functions -> confirm billing is active.

CLI can create Firestore and RTDB after Firebase is added:

```bash
firebase firestore:databases:create "(default)" \
  --project "$NEW_PROJECT_ID" \
  --location nam5 \
  --delete-protection ENABLED

firebase database:instances:create "${NEW_PROJECT_ID}-default-rtdb" \
  --project "$NEW_PROJECT_ID" \
  --location us-central1
```

Create Storage from the console because bucket setup/location and billing must be
reviewed explicitly.

## Phase 2 - Configure Authentication And Providers

In Firebase console -> Authentication:

1. Enable Email/Password.
2. Enable Phone if the product will use phone authentication.
3. Enable Google and choose the support email.
4. Enable Apple and provide the required Apple configuration.
5. Add authorized domains:
   - `localhost`
   - the Vercel production/preview domains actually used
   - `crush.app` and approved subdomains
   - the new project's Firebase Hosting domains
6. Configure email templates/action URLs after the new hosting/auth-link route is
   deployed.

Do not enable App Check enforcement yet. Register providers first, validate
clients, then enforce.

## Phase 3 - Register Android And iOS Apps

### 1. Normalize Apple Bundle IDs First

Open `ios/Runner.xcworkspace` in Xcode:

- Runner target -> Build Settings / Signing & Capabilities.
- Ensure every shipping Debug/Profile/Release configuration uses
  `com.ace.crush`.
- Remove historical shipping bundle IDs such as `com.gyanendra.*`.

### 2. Run FlutterFire Configuration

`flutterfire` is installed but not on this shell's PATH, so use the global Dart
runner:

```bash
dart pub global run flutterfire_cli:flutterfire configure \
  --project="$NEW_PROJECT_ID" \
  --account="$NEW_FIREBASE_ACCOUNT" \
  --platforms=android,ios \
  --android-package-name=com.ace.crush \
  --ios-bundle-id=com.ace.crush \
  --android-out=android/app/google-services.json \
  --ios-out=ios/Runner/GoogleService-Info.plist \
  --overwrite-firebase-options
```

This must replace:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

If Flutter macOS/web/windows targets remain supported, run a second intentional
configuration pass for those platforms rather than silently reusing old values.

### 3. Android Configuration

Current package:

```text
com.ace.crush
```

Generate signing fingerprints:

```bash
cd android
./gradlew signingReport
cd ..
```

Add the debug, local release, and Google Play App Signing SHA-1/SHA-256
fingerprints in Firebase console -> Project settings -> Android app.

Current local fingerprints found during this audit:

```text
Debug SHA-1:   AA:DB:5E:D8:58:D6:83:0F:66:19:78:9A:27:EA:B9:CF:B8:7A:FE:A4
Debug SHA-256: 28:7C:76:AF:94:71:D8:3C:55:51:59:6C:A2:AC:C6:51:BC:FD:A4:8D:A2:F4:95:A5:C5:C4:B5:0B:77:33:F5:7E
Local release SHA-1:   44:86:19:80:38:BD:BA:31:29:D2:42:7F:81:B8:33:B7:F5:D3:C1:72
Local release SHA-256: 0A:EC:40:A9:F7:CD:EC:9F:29:33:C1:57:D6:AF:8A:C4:C2:AC:1E:9D:ED:50:EE:86:2C:A5:94:68:53:5C:5B:CB
```

After adding fingerprints, download/regenerate `google-services.json` again.

Configure:

- Authentication -> Google/Phone providers.
- App Check -> Android -> Play Integrity.
- Cloud Messaging as required.

Replace the old Firebase email-link host in:

- `android/app/src/main/AndroidManifest.xml`
- `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`
- `public/finishSignIn.html`

Use the new Firebase Hosting auth-domain route initially, or the approved
`crush.app` route after it is configured and verified.

Android verification:

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --debug
flutter build appbundle --release
```

Then manually verify signup/login, Google/phone auth, Firestore reads/writes,
Storage upload, App Check, push token registration, and email-link completion.

### 4. iOS Configuration

Current intended bundle ID:

```text
com.ace.crush
```

After replacing `GoogleService-Info.plist`:

1. Read the new `REVERSED_CLIENT_ID`:

```bash
plutil -extract REVERSED_CLIENT_ID raw ios/Runner/GoogleService-Info.plist
```

2. In `ios/Runner/Info.plist`, replace the old
   `com.googleusercontent.apps.72015170328-...` URL scheme with the new
   `REVERSED_CLIENT_ID`.
3. In Firebase console -> Project settings -> Cloud Messaging, upload the Apple
   APNs authentication key for the new project.
4. Configure Authentication -> Apple and Google.
5. Configure App Check -> Apple with App Attest/DeviceCheck.
6. Confirm Xcode capabilities:
   - Push Notifications
   - Sign in with Apple
   - required Associated Domains, when configured

iOS verification:

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter analyze
flutter build ios --debug --no-codesign
```

Then manually verify on a physical iPhone: signup/login, Google/Apple auth,
Firestore, Storage, App Check, APNs/FCM token, notification delivery, and email
links.

## Phase 4 - Deploy Fresh Backend Infrastructure

### 1. Add A Temporary New-Project Alias

Keep the old project identifiable until final deletion:

```bash
firebase use --add
```

Assign the new project an alias such as `new`. Use explicit `--project` on every
deployment.

### 2. Deploy Rules And Indexes

```bash
firebase deploy --project "$NEW_PROJECT_ID" \
  --only firestore:rules,firestore:indexes,database,storage
```

### 3. Configure Functions Environment

Create an untracked `functions/.env.$NEW_PROJECT_ID` with new-project production
values. Required/currently referenced keys include:

```text
CORS_ALLOWED_ORIGINS
STRIPE_SECRET
STRIPE_WEBHOOK_SECRET
GOOGLE_PLAY_PACKAGE_NAME=com.ace.crush
APPLE_ISSUER_ID
APPLE_KEY_ID
APPLE_PRIVATE_KEY
APPLE_BUNDLE_ID=com.ace.crush
GOOGLE_RTDN_VERIFICATION_TOKEN
AGORA_APP_ID
AGORA_APP_CERTIFICATE
OTP_SECRET
RESEND_API_KEY
EMAIL_FROM
PROFILE_PREFERENCES_LEGACY_FALLBACK_CUTOFF
```

Generate a fresh OTP secret:

```bash
openssl rand -base64 32
```

Use test or newly rotated Stripe/Resend/Agora/Apple credentials. Do not copy
secrets into tracked files, docs, chat, or shell history.

### 4. Deploy Functions And Auth-Link Hosting

```bash
npm --prefix functions ci
npm --prefix functions run build
npm --prefix functions test

firebase deploy --project "$NEW_PROJECT_ID" --only functions
firebase deploy --project "$NEW_PROJECT_ID" --only hosting
```

Hosting here serves the mobile email-link completion pages from `public/`; Crush
Web itself remains deployed through Vercel.

Update external systems to the new URLs:

- Stripe webhook endpoints and redirects
- OAuth callbacks
- Resend/email action links
- Agora/call configuration
- Google Play RTDN
- Apple server notifications
- CI/CD and monitoring

## Phase 5 - Connect Crush Web

### 1. Register A Dedicated Web App

Create a separate Firebase web app for the Next.js Crush Web deployment:

```bash
firebase apps:create web "Crush Web" --project "$NEW_PROJECT_ID"
firebase apps:list --project "$NEW_PROJECT_ID"
firebase apps:sdkconfig web NEW_WEB_APP_ID --project "$NEW_PROJECT_ID"
```

Use the printed web SDK config for the following Vercel/local environment
variables:

```text
NEXT_PUBLIC_FIREBASE_API_KEY
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
NEXT_PUBLIC_FIREBASE_PROJECT_ID
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
NEXT_PUBLIC_FIREBASE_APP_ID
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID
NEXT_PUBLIC_FIREBASE_DATABASE_URL
```

### 2. Configure Web Security And Messaging

In Firebase console:

1. Authentication -> authorized domains: Vercel domains, `crush.app`, localhost.
2. App Check -> register the dedicated web app with reCAPTCHA Enterprise.
3. Create/copy the web push VAPID key.
4. Keep App Check enforcement disabled until staging validation passes.

Set these web environment values:

```text
NEXT_PUBLIC_FIREBASE_APPCHECK_RECAPTCHA_KEY
NEXT_PUBLIC_FIREBASE_APPCHECK_PROVIDER=recaptcha-enterprise
NEXT_PUBLIC_FIREBASE_VAPID_KEY
NEXT_PUBLIC_APP_ENV
```

### 3. Configure Firebase Admin For Web Server Routes

Create a least-privilege service account for Crush Web server-side Admin SDK
usage. Store its credentials only in Vercel secrets:

```text
FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON
```

Do not commit the service-account JSON.

### 4. Update Web Project References

Update:

- `/Users/ace/crush-web/.firebaserc`
- local untracked web env files
- Vercel Preview/Production environment variables
- operational scripts/tests that intentionally target the active project

Do not rewrite historical task logs just because they mention the old project.

Web verification:

```bash
cd /Users/ace/crush-web
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

Deploy Vercel and verify `/api/health`, signup/login, onboarding/profile,
discovery, chat, notifications, subscriptions, and account lifecycle.

## Phase 6 - Remove Old Project Runtime References

Update active runtime configuration in the main repo:

- `.firebaserc`
- `lib/firebase_options.dart`
- `lib/core/network/api_version.dart`
- `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `public/finishSignIn.html`
- active tests and operational scripts

Find remaining references:

```bash
rg -n --hidden \
  --glob '!**/.git/**' \
  --glob '!**/node_modules/**' \
  --glob '!functions/build/**' \
  'crush-265f7|72015170328' \
  .

cd /Users/ace/crush-web
rg -n --hidden \
  --glob '!**/.git/**' \
  --glob '!**/node_modules/**' \
  --glob '!**/.next/**' \
  'crush-265f7|72015170328' \
  .
```

Classify remaining matches:

- Active runtime/config/script/test: replace.
- Historical reports/task logs: retain as history.

## Phase 7 - Validate The Empty New Production Project

Before deleting the old project, prove:

- New account can administer Firebase, Google Cloud, billing, and Vercel.
- Android and iOS builds contain only new Firebase IDs.
- Crush Web/Vercel contains only new Firebase IDs and new Admin credentials.
- Rules, indexes, RTDB rules, Storage rules, Functions, schedules, triggers, and
  email-link hosting are deployed.
- New signup creates the user only in the new Auth/Firestore project.
- Profile/media, discovery, match/chat, report/block, notifications, calls,
  subscription, account deletion, and scheduled jobs use the new project.
- App Check works before enforcement; then enforcement can be enabled gradually.
- No required external webhook points at the old project.

Because no old data is required, Auth/Firestore/RTDB/Storage should start empty
except for deliberate validation records. Delete test records after sign-off.

## Phase 8 - Permanently Retire The Old Firebase Project

Only after Phase 7 passes:

1. Sign into the old owning Google account.
2. Confirm the selected project ID is exactly `crush-265f7`.
3. Remove/disable external integrations still targeting it.
4. Unlink billing to avoid unexpected charges.
5. Shut down the project:

```bash
gcloud projects delete crush-265f7 --account="OLD_GOOGLE_ACCOUNT_EMAIL"
```

Google marks the project unusable immediately and fully deletes it after the
30-day recovery period. The project ID cannot be reused. Some resources such as
Storage or Pub/Sub can disappear sooner.

Then remove local old-account access:

```bash
firebase logout OLD_GOOGLE_ACCOUNT_EMAIL
gcloud auth revoke OLD_GOOGLE_ACCOUNT_EMAIL
```

Deleting the Firebase/Google Cloud project does not delete the old Google account
itself. Google-account deletion is a separate Google Account operation.

## Final Exit Criteria

- Android, iOS, Crush Web, and backend use only the new Firebase project.
- Critical flows pass on the new empty project.
- App Check, FCM/APNs/VAPID, Auth providers, Functions, rules, billing, and
  external integrations are verified.
- `crush-265f7` is shut down and scheduled for permanent deletion.
- Old Firebase/gcloud account credentials are removed locally.
