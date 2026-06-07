# Profile & Settings Capability Matrix (Phase 9 Step 19)

- Date: 2026-06-07
- Authority: backend `functions/src/index.ts` + `firestore.rules` (canonical
  support); mobile `lib/features/profile` + `lib/core/constants` (product limits).
- Enforced by: `packages/core/src/config/profile_capabilities.ts` +
  `apps/web/src/lib/__tests__/profile-capabilities.test.ts`.
- Rule for web: **implement a field/setting only when canonical backend support
  exists** (REST allowlist, rules-permitted client write, or callable).

## 1. Profile fields

Backend canonical write paths: REST `PATCH /v1/profile/me`
(`PROFILE_PATCH_ALLOWED_FIELDS`) and rules-permitted client writes to
`users/{uid}` (everything except the protected set, bounded array sizes).
Protected (server-only): `plan, isIdVerified, stripe*, isEmailVerified,
emailVerified, createdAt, kycVerificationStatus, boost, subscription*, isPremium,
premiumPlan, safetyFlags`.

| Field | Canonical support | Mobile | Web | Status |
|---|---|---|---|---|
| display name | REST PATCH `display_name` | ✅ | ✅ | aligned |
| bio | REST PATCH `bio` | ✅ | ✅ | aligned |
| birth date / age | REST PATCH `birth_date` (min-age validated) | ✅ | ✅ | aligned |
| gender | REST PATCH `gender` | ✅ | ✅ | aligned |
| sexual orientation | rules write `profile.sexualOrientation` | ✅ | ✅ | aligned |
| job title / company | REST PATCH `job_title`/`company` | ✅ | ✅ | aligned |
| education | REST PATCH `education` | ✅ | ✅ | aligned |
| city / country | REST PATCH `city`/`country` | ✅ | ✅ | aligned |
| interests | REST PATCH `interests`; rules ≤ 20 | ✅ ≤10 | ✅ ≤10 | aligned (product cap 10) |
| photos | rules `profile.photoUrls` ≤ 9; upload `/v1/profile/photos` | ✅ 9 | ⚠️→✅ **was 6, fixed to 9** | fixed this phase |
| prompts | rules client write (`prompts` retained root) | ✅ | ✅ ≤3 | aligned |
| lifestyle (height, education, drinking, smoking, workout) | rules client write (`lifestyle` retained root) | ✅ | ✅ | aligned |
| verification badge (`isVerified`) | **read-only** (server sets `isIdVerified`/`kycVerificationStatus`) | display | display | aligned — **no web submit** (no canonical endpoint) |

## 2. Media limits (canonical → enforced via `profile_capabilities.ts`)

| Limit | Value | Authority |
|---|---|---|
| Max profile photos | **9** | mobile `ProfileMediaLimits.maxPhotos`; rules ≤ 9 |
| Min photos | 1 | onboarding gate |
| Photo max size | **10 MB** | backend `PROFILE_PHOTO_MAX_BYTES`; mobile `maxPhotoSizeBytes` |
| Photo MIME | jpeg, png, webp, heic, heif | backend `PROFILE_PHOTO_ALLOWED_MIME_TYPES` |
| Max interests | **10** | mobile `save_profile_details`; rules ≤ 20 |
| Max prompts | **3** | profile editor |
| Chat media | image 25MB · video 100MB · audio 25MB | backend `CHAT_MEDIA_MAX_BYTES_BY_KIND` |

**Fix applied this phase:** web `PhotoGridReorder` defaulted to 6 and onboarding/
edit passed `maxPhotos={6}`, so web users could not use photo slots 7–9 that the
backend and mobile allow. Now all web photo surfaces use `MAX_PROFILE_PHOTOS`
(=9) from the shared constant; interests/prompts caps also reference the shared
constants. Guarded by the parity test.

## 3. Privacy controls

| Control | Canonical field | Mobile | Web | Status |
|---|---|---|---|---|
| Show my distance | `profile.preferences.showMyDistance` | ✅ | ✅ | aligned — web `settings.showDistance` is bridged to the canonical field by `user_document.ts` (`updateUserSettings`), so discovery honors it |
| Show my age | `profile.preferences.showMyAge` | ✅ | ✅ | aligned (same bridge) |
| Hide from discovery | `profile.preferences.hideFromDiscovery` | ✅ | ✅ | aligned (bridge) |
| Incognito | `incognitoMode` (Premium-gated) | ✅ | ✅ | aligned |
| Show online status | `settings.showOnlineStatus` | ✅ | ✅ | aligned |
| Block / unblock | `blockUser`/`unblockUser`/`getBlockedUsers` callables | ✅ | ✅ | aligned |
| Report | `reportUser` callable | ✅ | ✅ | aligned |

Note (verified, not a defect): the web privacy page persists `settings.show*`, and
`user_document.ts` maps those to the canonical `profile.preferences.showMy*`
fields that discovery actually reads — so the toggles take effect.

## 4. Settings parity

| Setting page | Backend support | Web | Status |
|---|---|---|---|
| Account (delete/export) | `requestAccountDeletion`, `cancelAccountDeletion`, `requestDataExport` callables | ✅ | aligned |
| Notifications | `notificationPrefs` (8 categories + channels) | ✅ | aligned (Step 14) |
| Privacy | preferences + settings (see §3) | ✅ | aligned |
| Discovery | `/v1/profile/preferences` (minAge/maxAge/maxDistanceKm/showMeGenders) | ✅ | aligned |
| Incognito | `incognitoMode` (Premium) | ✅ | aligned |
| Blocked users | `getBlockedUsers` callable | ✅ | aligned |

## Done-when status (Step 19)
- ✅ Shared profile-field capability matrix published (this doc) + machine-enforced
  via `profile_capabilities.ts` + parity test.
- ✅ Media limits aligned (photo cap fixed 6→9; interests/prompts via constants);
  prompts, lifestyle, privacy controls confirmed aligned; verification documented
  as server-owned/display-only.
- ✅ No web setting added without canonical backend support (verification submit
  deliberately NOT built — no canonical endpoint).
