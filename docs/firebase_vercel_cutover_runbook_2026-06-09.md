# Firebase + Vercel Cutover Runbook — crush-f5352 (2026-06-09)

Status snapshot from console audit (account `crush.date.app@gmail.com` owns Firebase; `adhikarigya8@gmail.com` owns Vercel):

- **Firestore** — NOT created. Region intent = `nam5` (per `firebase.json`).
- **Storage** — NOT enabled; requires Blaze plan.
- **Auth providers** — Email/Password already added; Google, Phone, Apple NOT yet enabled.
- **Plan** — Spark (free). Blaze required for Storage + Cloud Functions.
- **Vercel** — project `crush-web` exists under team `adhikarigya8-1550s-projects`; locally-pulled `.env.crush-web-web` already holds crush-f5352 values (remote not yet CLI-verified).

> Console SPAs (Firebase + Vercel) could not be driven reliably via browser automation this session — they never reach an idle state. CLI steps below are the reliable path.

## 1. Firestore + rules/indexes (Spark-OK) — run in `my_first_project/`
```bash
firebase firestore:databases:create "(default)" --location nam5 --project crush-f5352
# Fallback if the subcommand is missing in your firebase-tools version:
# gcloud firestore databases create --location=nam5 --type=firestore-native --project=crush-f5352

firebase deploy --only firestore:rules,firestore:indexes,database --project crush-f5352
```

## 2. Auth providers — Firebase console (crush.date.app)
Authentication → Sign-in method → **Add new provider**, enable & save each:
- Email/Password — already done.
- Google — enable, set support email, save.
- Phone — enable, save.
- Apple — enable, save (iOS Service ID/key config can follow later).

## 3. Vercel env verify + NEW admin key + redeploy — run in `crush-web/`
```bash
vercel login            # sign in as adhikarigya8@gmail.com
vercel link             # select team adhikarigya8-1550s-projects, project crush-web
vercel env ls production
```
- Confirm every `NEXT_PUBLIC_FIREBASE_*` value = crush-f5352 (API key, authDomain `crush-f5352.firebaseapp.com`, projectId `crush-f5352`, storageBucket `crush-f5352.firebasestorage.app`, messagingSenderId `305121585498`, appId, measurementId).
- **Admin SDK:** generate a NEW key from Firebase console → Project settings → Service accounts → *Generate new private key* (for crush-f5352). Set it in Vercel as `FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON` (and/or `FIREBASE_ADMIN_*`). The old crush-265f7 key will NOT work.
  - Do NOT paste the key into chat or commit it. Add via `vercel env add FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON production` (paste when prompted) or the Vercel UI.
- Redeploy so the new env is baked in (old deployments keep old env snapshots):
```bash
vercel --prod
```
- Validate: open the production URL `/api/health`.

## 4. Blaze-gated (do when ready to upgrade billing)
After upgrading crush-f5352 to Blaze:
```bash
firebase deploy --only storage,functions --project crush-f5352
```
Storage and Cloud Functions stay broken until this is done.
