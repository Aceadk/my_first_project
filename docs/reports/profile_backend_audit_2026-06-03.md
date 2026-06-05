# Profile Backend Audit - 2026-06-03

Scope: `PROF-BE-001`, `PROF-BE-002`, and `PROF-BE-003` from
[`docs/TODO_PROFILE_BACKEND.md`](../TODO_PROFILE_BACKEND.md).

Surface reviewed: profile validators + REST routes and the upload pipeline in
[`functions/src/index.ts`](../../functions/src/index.ts), the call signaling
file, [`firestore.rules`](../../firestore.rules), [`storage.rules`](../../storage.rules),
the production Flutter upload path (`profile_media_service.dart`,
`image_optimizer.dart`), and the account-deletion cascade (`cascadeDeleteUserData`).

## Result

PROF-BE-001 passes as-built (strict allowlist validation + server-only protected
fields). PROF-BE-002 passes on the production path (client re-encode strips EXIF;
moderation enforced via the documented callable) with server-side defense-in-depth
tracked. PROF-BE-003 found and **fixed** a real orphaned-data/privacy bug: account
deletion was not removing production profile media, ID-verification documents, or
production chat media from Cloud Storage.

Legend: ✅ verified · ⚠️ finding/recommendation · 🔧 fixed this pass.

---

## PROF-BE-001 - Profile payload validation and permission boundaries

Status: Pass

- **Write surface is allowlisted.** The REST `PATCH /v1/profile/me` accepts only
  `PROFILE_PATCH_ALLOWED_FIELDS` (`display_name`, `bio`, `birth_date`, `gender`,
  `job_title`, `company`, `education`, `city`, `country`, `interests`) and rejects
  any other key. Preferences (`PATCH /v1/profile/preferences`) use a separate
  `PROFILE_PREFERENCES_ALLOWED_FIELDS` allowlist.
- **Every accepted field is validated server-side:** length caps + `stripHtml`
  (name 2–50 sanitized, bio ≤500, text fields capped), `validateMinimumAge` on
  birth date, `normalizeProfileGender` against `CANONICAL_DISCOVERY_GENDER_SET`,
  and `validateProfileInterests` (≤20 items).
- **Privileged fields cannot be mutated by clients.** `plan`, `isIdVerified`,
  `stripeCustomerId`, `stripeSubscriptionId`, `isEmailVerified`, `createdAt`,
  `kycVerificationStatus` are server-only in `firestore.rules` (DB-001 audit), and
  none are in the REST allowlists — so neither the direct Firestore path nor the
  REST path can escalate verification/moderation/subscription state. Photo/interest
  array sizes are also bounded by the rules (≤9 / ≤20).

No changes required.

---

## PROF-BE-002 - Image-processing privacy and moderation pipeline

Status: Pass on the production path; server-side enforcement tracked

- **EXIF / metadata removal (production):** ✅ The Flutter client uploads through
  `ImageOptimizer.optimize`, which decodes the image, re-renders the pixels via a
  `Canvas` (`PictureRecorder` → `picture.toImage`) and re-encodes. A full pixel
  re-encode does not carry the source EXIF/GPS/device metadata, so privacy-sensitive
  metadata is removed before the bytes ever reach Storage.
- **Moderation (production):** ✅ enforced via the `moderateImageContent` /
  `moderateTextContent` callables (`ContentModerationService`). The REST
  `POST /v1/profile/photos` path additionally runs Cloud Vision SafeSearch inline
  and requires a detectable face on primary photos, and `validateBinaryUpload`
  enforces size + MIME allowlist + magic-byte anti-spoofing.
- ⚠️ **No server-side enforcement on direct-to-Storage uploads.** In production the
  client writes straight to `users/{uid}/photos/...`; `storage.rules` only checks
  `contentType` + size, so a modified client could upload EXIF-laden or
  unmoderated media. The REST handlers also save the raw buffer without
  re-encoding. *Recommend (tracked):* a Storage `onFinalize` Cloud Function that
  (a) re-encodes/strips metadata and (b) runs SafeSearch, deleting or quarantining
  on failure — the single server-side choke point for both formats (incl. HEIC).
  Not implemented here: it needs an image lib (e.g. `sharp`) + HEIC handling + a
  delete-on-reject policy decision.

---

## PROF-BE-003 - Deletion cascade for profile-owned data

Status: 🔧 Fixed (orphaned-media bug closed) + regression-tested

### The bug
`cascadeDeleteUserData` only swept two Cloud Storage prefixes — `photos/{uid}/`
and `chat_media/{uid}/` — which are the **legacy REST** paths. The production
Firebase client stores media elsewhere, so account deletion left it **orphaned and
still readable** (any signed-in user can read `users/{uid}/photos/*`):

| Media | Production path | Swept before? |
|-------|-----------------|---------------|
| Profile photos | `users/{uid}/photos/` | ❌ |
| Profile videos | `users/{uid}/videos/` | ❌ |
| Stories | `users/{uid}/stories/` | ❌ |
| Generic profile media | `users/{uid}/media/` | ❌ |
| ID verification docs (PII) | `verification/{uid}/` | ❌ |
| Chat media (uploaded by user) | `chat_media/{matchId}/{uid}/` | ❌ (only `chat_media/{uid}/`) |

### The fix
`cascadeDeleteUserData` now sweeps every prefix via the new pure helper
`userStorageDeletionPrefixes(uid, matchIds)`:
`users/{uid}/`, `verification/{uid}/`, `photos/{uid}/`, `chat_media/{uid}/`, and
`chat_media/{matchId}/{uid}/` for every match the user belonged to (collected
during the match sweep). Each prefix is deleted independently with its own
error capture, so one failure can't orphan the rest. Covered by new cases in
`functions/test/accountDeletionMap.test.js`.

The Firestore/RTDB/Auth cascade coverage was already correct (verified in the
DB-002 audit, `database_audit_2026-06-02.md`): matches + message subcollections,
relation records, `message_requests` (fixed in DB-002), account-tracking docs,
auth credentials, RTDB presence/typing, the user doc, and the Auth user.

Manual staging checklist:
- For a disposable staging user with a profile photo (`users/{uid}/photos/*`), a
  story, an ID-verification doc, and chat media in a match, force the deletion
  sweep and confirm all objects are gone from Storage (not just the legacy paths).
- Confirm media uploaded by the *other* match participant
  (`chat_media/{matchId}/{otherUid}/`) is retained.

---

## Verification

- `npm run build` (functions) — clean; `npm run lint` — clean.
- `npx mocha --exit test/accountDeletionMap.test.js` — **8 passing** (incl. 3 new
  PROF-BE-003 storage-prefix cases).
- PROF-BE-001/002 verified by source review of the validators, REST routes,
  `firestore.rules`, `storage.rules`, and the production upload path.

## Tracked follow-ups
- Storage `onFinalize` trigger for server-side metadata stripping + moderation on
  direct-to-Storage uploads (PROF-BE-002 defense-in-depth).
- Optional: strip metadata server-side in the REST upload handlers (non-production
  path) using the same future image utility.
