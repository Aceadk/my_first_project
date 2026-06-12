# Security — Credential Exposure & Rotation Runbook (2026-06-12)

## What was found

A separate git repo named **`Credentials/`** (remote: `github.com/Aceadk/crush-credentials.git`)
commits a full set of **live secrets**:

| File | What it is | Sensitivity |
|------|-----------|-------------|
| `crush-f5352-firebase-adminsdk-fbsvc-a7da9ce026.json` | Firebase **Admin SDK private key** (crush-f5352) | CRITICAL — full backend access |
| `crushhour-release.keystore` | Android **release keystore** | CRITICAL — app signing |
| `crushhour-keystore-backup.txt` | Keystore **passwords in plaintext** (Store/Key password, alias) | CRITICAL |
| `AuthKey_84457L85X6.p8` | Apple **.p8 auth key** (APNs / Sign in with Apple) | HIGH |
| `Crush_*.mobileprovision`, `*.cer`, `*.certSigningRequest` | Apple provisioning/certs | LOW–MED |
| `GoogleService-Info*.plist`, `google-services.json` | Firebase **client** config | LOW (not secret, identifies project) |

**Exposure scope (good news):**
- The GitHub repo returns **404 unauthenticated** → it is **private or already deleted**, NOT public. This is not an open-internet leak.
- The app repos (`Crush App`, `crush-web`, `crushhour-recommendation-service`) contain **none** of these secrets in their git history — exposure is contained to the `crush-credentials` repo.
- All three backends already initialize Firebase Admin **from env / ambient credentials** (Functions `initializeApp()`, crush-web `FIREBASE_ADMIN_*` env, recommender `applicationDefault()`), so **rotation needs no code changes** — only updating env/secret stores.

Rotation is still strongly recommended (private ≠ safe: old clones, collaborators, secret-scanners).

---

## Identifiers you'll need (non-secret)

```
Firebase project        : crush-f5352
Leaked SA client_email  : firebase-adminsdk-fbsvc@crush-f5352.iam.gserviceaccount.com
Leaked SA private_key_id: a7da9ce0268e8d0feaad126126736f4279655575
Leaked SA client_id     : 106136555142286869886
```

---

## 1. Rotate the Firebase Admin SDK key (create → switch → disable → delete)

Run as an account with `roles/iam.serviceAccountKeyAdmin` on crush-f5352.

```bash
SA=firebase-adminsdk-fbsvc@crush-f5352.iam.gserviceaccount.com

# A) Create a NEW key (downloads new JSON locally; do NOT commit it)
gcloud iam service-accounts keys create ~/crush-f5352-admin-NEW.json \
  --iam-account="$SA" --project=crush-f5352

# B) See existing keys (note the old KEY_ID = a7da9ce0268e8d0feaad126126736f4279655575)
gcloud iam service-accounts keys list --iam-account="$SA" --project=crush-f5352

# C) DISABLE the old key first (reversible)
gcloud iam service-accounts keys disable a7da9ce0268e8d0feaad126126736f4279655575 \
  --iam-account="$SA" --project=crush-f5352
```

Then update every place that holds the admin credential (see §4), redeploy, and verify
(login/signup, profile write, image upload, chat, recommendations, notifications). Once
everything works on the new key:

```bash
# D) DELETE the old key (irreversible — only after verifying the new one works)
gcloud iam service-accounts keys delete a7da9ce0268e8d0feaad126126736f4279655575 \
  --iam-account="$SA" --project=crush-f5352
```

> No code change needed — backends read the credential from env. You only swap the value.

---

## 2. Rotate the Android keystore

First determine: **is the app already on Google Play, and are you on Play App Signing?**
(Play Console → Test and release → Setup → App signing.)

- **Not published yet** → just generate a fresh keystore and use it going forward:
  ```bash
  keytool -genkeypair -v -keystore crush-release-new.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias crush
  # update android/key.properties (storeFile/passwords/alias) — keep it OUT of git
  flutter clean && flutter pub get && flutter build appbundle --release
  ```
- **Published + Play App Signing, leaked = upload key only** (most common) →
  Play Console → App signing → **request upload key reset** (upload a new upload certificate).
  Google manages the real app-signing key; you just rotate the upload key.
- **Published + leaked = the actual app-signing key** → serious; follow Play Console's
  key-upgrade / compromise flow.

The plaintext password file `crushhour-keystore-backup.txt` means the keystore passwords are
also exposed — set **new passwords** when you create the new keystore regardless of the above.

---

## 3. Rotate the Apple `.p8` key

`AuthKey_84457L85X6.p8` should be treated as compromised:
- Apple Developer → Certificates, Identifiers & Profiles → **Keys** → revoke key `84457L85X6`,
  create a new key with the same capabilities (APNs / Sign in with Apple).
- Update wherever it's used (Firebase Cloud Messaging APNs auth key upload, and any server).
- The certs/provisioning profiles are lower risk but regenerate if convenient.

---

## 4. Update secret stores after rotation, then purge old values

Set the NEW admin credential in each place the stack reads it:
- **Vercel** (crush-web): `FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON` (or the `FIREBASE_ADMIN_*` triplet) → redeploy.
- **Recommendation service** (Cloud Run/host): point `GOOGLE_APPLICATION_CREDENTIALS` at the new key, or use the host's attached service account (preferred — no key file at all).
- **Cloud Functions**: uses the runtime SA automatically — nothing to set.
- **Local `.env` / scripts**: `GOOGLE_APPLICATION_CREDENTIALS=~/crush-f5352-admin-NEW.json`.
- **GitHub Actions secrets**: replace any stored admin key.

Then remove old values everywhere (old deployments, old laptops/VPS, CI). Check:
GitHub → Settings → Secrets and variables → Actions, and → Code security → Secret scanning.

---

## 5. Fix the `crush-credentials` repo itself

Storing live keys in a git repo (even private) is the root cause. After rotating:
1. Make sure it's **private** (it 404s now — confirm it's private, not just logged-out).
2. Purge the secret blobs from history (or simplest: **delete the repo** and stop using it):
   ```bash
   # if keeping the repo, scrub history (coordinate with anyone who cloned):
   git filter-repo --invert-paths \
     --path 'crush-f5352-firebase-adminsdk-fbsvc-a7da9ce026.json' \
     --path 'crushhour-release.keystore' \
     --path 'crushhour-keystore-backup.txt' \
     --path 'AuthKey_84457L85X6.p8'
   git push --force --all
   ```
3. Going forward, store secrets in a **secret manager** (Google Secret Manager / Vercel env /
   GitHub Actions secrets), never in a repo. Keep local copies in an ignored `~/secure/` dir.

App-repo `.gitignore` files were hardened on 2026-06-12 to block `*serviceAccount*.json`,
`*-adminsdk-*.json`, `*.p8`, `*.p12`, `*.jks`, `*.keystore`, `key.properties`, and
`*keystore-backup*.txt`, so these can never be committed into the app repos.
```
