# Firebase Account And Project Switch Runbook

- Date: 2026-06-07
- Current Firebase project: `crush-265f7`
- Current project number: `72015170328`
- Firestore location configured in repo: `nam5`
- Purpose: Safely switch the managing Google account or migrate Crush to a new Firebase project without accidental lockout, data loss, or broken clients.

## First Decision

Choose exactly one path:

### Path A - New Google Account, Same Firebase Project (Recommended)

Use this when the goal is to remove the old Google account but keep the current
Firebase data, users, functions, app registrations, URLs, and configuration.

Benefits:

- No Auth, Firestore, Realtime Database, Storage, or Functions migration.
- Existing mobile/web releases continue working.
- Existing FCM tokens, App Check registrations, OAuth clients, and function URLs
  remain valid.

### Path B - Entirely New Firebase Project

Use this only when Crush must move to a different Firebase/Google Cloud project.
This is a full infrastructure and data migration, not an account switch.

Consequences:

- New Firebase app IDs, API keys, project number, buckets, function URLs, OAuth
  clients, App Check registrations, and FCM sender identity.
- Existing sessions and FCM tokens will not remain valid.
- Firestore/Auth/Storage/RTDB data must be migrated separately.
- External integrations and deployed clients must be cut over.

## Current-State Findings

- `crush-265f7` currently has only one human IAM owner. Do not remove that owner
  until a new owner has been added and independently verified.
- Firebase CLI currently targets `crush-265f7`.
- `gcloud` currently targets an unrelated project, so every migration/deploy
  command must use an explicit `--project` until configuration is corrected.
- Registered Firebase apps:
  - Android: `com.ace.crush`
  - Apple: `com.ace.crush`
  - Web: Crush web app
- Runtime references to `crush-265f7` exist in:
  - `.firebaserc`
  - `lib/firebase_options.dart`
  - `lib/core/network/api_version.dart`
  - `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`
  - `android/app/src/main/AndroidManifest.xml`
  - `public/finishSignIn.html`
  - `/Users/ace/crush-web/.firebaserc`
  - web/Vercel Firebase environment variables
- Local native Firebase files must also be replaced for a new project:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `macos/Runner/GoogleService-Info.plist`
- Xcode project settings contain historical bundle identifiers in some build
  configurations. Normalize every shipping configuration to `com.ace.crush`
  before registering/cutting over Apple apps.
- Function configuration contains sensitive third-party credentials. Rotate
  credentials during a full project migration; do not copy secrets into docs,
  commits, shell history, or chat.

## Path A - Transfer The Existing Project To A New Google Account

### A1. Add And Verify The New Account

1. Sign in to the Firebase console with the current owner.
2. Open `crush-265f7` -> Project settings -> Users and permissions.
3. Add the new Google account as Owner temporarily.
4. Confirm the new account can independently:
   - Open Firebase console and Google Cloud console.
   - View Auth, Firestore, Storage, Functions, App Check, and project settings.
   - View or manage the linked billing account.
   - View the linked Google Analytics property, if used.
   - List and deploy functions/rules from CLI.

CLI alternative for the temporary owner grant:

```bash
gcloud projects add-iam-policy-binding crush-265f7 \
  --member="user:NEW_ACCOUNT_EMAIL" \
  --role="roles/owner"
```

### A2. Switch Local CLI Authentication

Log out of the old Firebase account and sign in with the new account:

```bash
firebase logout
firebase login
firebase projects:list
firebase use crush-265f7
```

Switch `gcloud` separately:

```bash
gcloud auth login NEW_ACCOUNT_EMAIL
gcloud config set account NEW_ACCOUNT_EMAIL
gcloud config set project crush-265f7
gcloud auth list
gcloud config get-value project
```

Verify both CLIs before changing access:

```bash
firebase apps:list --project crush-265f7
firebase functions:list --project crush-265f7
gcloud projects get-iam-policy crush-265f7
```

### A3. Remove The Old Account

Only after the new account has passed all verification:

1. Confirm billing and Analytics access are not owned only by the old account.
2. Remove the old account from Firebase/Google Cloud IAM.
3. Remove the old account from Analytics, Crashlytics integrations, Vercel,
   Stripe, Apple, Google Play, Resend, Agora, and CI/CD where applicable.
4. Rotate credentials that the old account could access.

CLI removal:

```bash
gcloud projects remove-iam-policy-binding crush-265f7 \
  --member="user:OLD_ACCOUNT_EMAIL" \
  --role="roles/owner"
```

### A4. Path A Exit Criteria

- New account is the verified project owner.
- New account can deploy rules and functions.
- Billing and Analytics access are verified.
- Old account has been removed.
- Mobile/web configuration and production data remain unchanged.

## Path B - Migrate To A New Firebase Project

Use placeholders throughout:

```bash
export OLD_PROJECT_ID=crush-265f7
export NEW_PROJECT_ID=YOUR_NEW_FIREBASE_PROJECT_ID
```

### B1. Create And Prepare The Destination Project

1. Sign into Firebase and `gcloud` with the new Google account.
2. Create the new Firebase project.
3. Link billing/Blaze before using Functions or managed Firestore export/import.
4. Create Firestore in the intended location. Use `nam5` if preserving the
   current location strategy.
5. Enable Realtime Database and Storage.
6. Enable the required APIs and products:
   - Authentication / Identity Toolkit
   - Firestore
   - Realtime Database
   - Storage
   - Cloud Functions
   - Cloud Build and Artifact Registry
   - Cloud Scheduler and Pub/Sub
   - Eventarc, Cloud Run, and Secret Manager as required
   - App Check
   - Cloud Messaging
   - Remote Config, Analytics, Crashlytics, and Performance as required

Set both CLIs explicitly:

```bash
firebase logout
firebase login
firebase projects:list
firebase use --add

gcloud auth login NEW_ACCOUNT_EMAIL
gcloud config set account NEW_ACCOUNT_EMAIL
gcloud config set project "$NEW_PROJECT_ID"
```

### B2. Register Destination Firebase Apps

Register the same shipping identities:

- Android package: `com.ace.crush`
- Apple bundle ID: `com.ace.crush`
- Web app: Crush

Before Apple registration, verify every shipping Xcode configuration uses
`com.ace.crush`.

Generate/update Flutter configuration:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project="$NEW_PROJECT_ID"
```

Select Android, iOS, macOS, Web, and Windows only if each target is supported.
Review generated changes rather than accepting unrelated platform changes.

Replace local native config files with destination-project files:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

### B3. Configure Authentication And Client Trust

Recreate and verify:

- Email/password, phone, Google, Apple, and email-link providers.
- Authorized domains and action-code/continue URLs.
- OAuth consent screen and OAuth client settings.
- Android SHA-1 and SHA-256 fingerprints for debug/release/Play signing.
- Apple APNs key/certificate and Sign in with Apple configuration.
- Web push VAPID key.
- App Check registration and providers:
  - Android Play Integrity
  - Apple App Attest/DeviceCheck
  - Web reCAPTCHA Enterprise
- App Check enforcement only after destination clients pass staging validation.

### B4. Deploy Destination Infrastructure Before Data

Update project aliases, but keep old/new aliases during migration:

```json
{
  "projects": {
    "old": "crush-265f7",
    "new": "YOUR_NEW_FIREBASE_PROJECT_ID"
  }
}
```

Deploy rules/indexes before importing data:

```bash
firebase deploy --project "$NEW_PROJECT_ID" \
  --only firestore:rules,firestore:indexes,database,storage
```

Recreate function environment values using newly rotated credentials. Do not
copy sensitive values into tracked files. Then build and deploy:

```bash
npm --prefix functions run build
firebase deploy --project "$NEW_PROJECT_ID" --only functions
```

Update external webhook/callback URLs after new functions are deployed:

- Stripe webhooks and checkout redirects
- Resend/email identity and links
- Agora/call credentials
- OAuth callbacks
- Vercel environment variables and deployment
- Any monitoring, scheduler, or CI/CD identities

### B5. Migrate Data

#### Firebase Authentication

Export users from the source and import them into the destination while
preserving UIDs. Password users require the source password hash parameters.
Protect the export and hash configuration as sensitive data.

```bash
firebase auth:export /secure/path/auth-users.json \
  --project "$OLD_PROJECT_ID" \
  --format=json

firebase auth:import /secure/path/auth-users.json \
  --project "$NEW_PROJECT_ID" \
  --hash-algo=SCRYPT \
  --hash-key="SOURCE_HASH_KEY" \
  --salt-separator="SOURCE_SALT_SEPARATOR" \
  --rounds=SOURCE_ROUNDS \
  --mem-cost=SOURCE_MEM_COST
```

Existing Firebase Auth sessions are source-project tokens and will not remain
valid. Plan a user re-authentication event after cutover.

#### Firestore

Managed cross-project export/import requires billing on both projects. Deploy
indexes first. For a consistent final export, stop client and Admin-SDK writes.

High-level sequence:

```bash
gcloud firestore export gs://SOURCE_EXPORT_BUCKET \
  --project="$OLD_PROJECT_ID"

gcloud firestore import gs://SOURCE_EXPORT_BUCKET/EXPORT_PREFIX \
  --project="$NEW_PROJECT_ID"
```

Grant the destination Firestore service account read access to the export bucket
before import.

#### Realtime Database

Export the source database JSON, then import it into the destination using the
Firebase console or an approved Admin SDK migration script. Validate rules and
record counts before enabling clients.

#### Cloud Storage

Copy/transfer objects from the old bucket to the new bucket with Google Cloud
Storage Transfer Service or `gcloud storage` for a small dataset.

Important: Existing Firestore documents can contain old Firebase Storage download
URLs. Copying objects does not rewrite those URLs. Inventory and rewrite stored
media URLs, or keep the old bucket available until all references are migrated.

#### Products That Need Manual Recreation

These are not automatically moved by Firestore/Auth/Storage migration:

- App Check apps/providers/enforcement
- FCM/VAPID/APNs configuration and token validity
- Authentication providers, templates, authorized domains, and OAuth clients
- Remote Config
- Analytics history/property configuration
- Crashlytics/Performance project linkage
- Extensions
- Function environment/secrets
- Scheduler/Pub/Sub/Eventarc integrations not recreated by deployment
- Billing budgets, alerts, IAM, service accounts, and CI identities

### B6. Update Runtime References

Replace old project references in application/runtime configuration:

- Main `.firebaserc`
- `/Users/ace/crush-web/.firebaserc`
- `lib/firebase_options.dart`
- `lib/core/network/api_version.dart`
- `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`
- `android/app/src/main/AndroidManifest.xml`
- `public/finishSignIn.html`
- Native Firebase config files
- Vercel `NEXT_PUBLIC_FIREBASE_*`, App Check, VAPID, and Admin credentials
- Any CI/CD project IDs, service accounts, or deployment identities

Update tests and current operational docs after runtime cutover. Historical task
logs should remain unchanged.

### B7. Validate Before Cutover

Required destination-project checks:

- Auth: signup, login, Google/Apple/phone/email link, logout, password reset,
  session refresh, deletion/cancel deletion.
- Profile/media: create, edit, upload, read, delete.
- Discovery/match/chat: discovery, swipe, match, messages, read/edit/unsend,
  reactions, typing, block/report.
- Calls, notifications, subscriptions, safety, exports, scheduled jobs.
- Firestore/RTDB/Storage rules and indexes.
- Functions and REST endpoints with App Check.
- Web/Vercel deployment and mobile release candidates.
- Record counts and representative records across Auth, Firestore, RTDB, and
  Storage.

### B8. Cutover And Retire The Old Project

1. Announce a maintenance/write-freeze window.
2. Stop old-project writes from clients and backend services.
3. Run final Auth/Firestore/RTDB/Storage migration and reconciliation.
4. Deploy destination-configured web/mobile clients and backend.
5. Monitor auth, permission, App Check, function, messaging, and data errors.
6. Keep the old project read-only and backed up during an observation window.
7. Only after sign-off:
   - Remove the old Google account or reduce its access.
   - Disable old integrations and rotate credentials.
   - Delete the old Firebase project only when no clients, URLs, stored media
     references, or recovery requirements depend on it.

### B9. Path B Exit Criteria

- Destination project passes all critical journeys and rules checks.
- Auth UIDs and required data are reconciled.
- Storage URLs and external webhooks no longer depend on the old project.
- App Check, FCM, OAuth, APNs, billing, IAM, and CI/CD are verified.
- Old project is backed up and no longer receives required traffic.

## Recommended Choice For The Current Request

Decision update (2026-06-07): The developer confirmed that old project data is
not required and selected **Path B**, a clean start under a new Firebase project.
Use the executable checklist:

`docs/FIREBASE_CLEAN_START_CHECKLIST_2026-06-07.md`

Do not delete `crush-265f7` until the replacement Android, iOS, Crush Web, and
backend validation gate passes.
