# Upload Validation Policy

Date: 2026-04-19
Owner: Codex
Related TODO: `API-003`

## Scope

This report documents the enforced server-side validation policy for the
backend upload ingress in `functions/src/index.ts`.

Covered endpoints:

- `POST /v1/profile/photos`
- `POST /v1/chat/:conversationId/media`

## Shared Validation Rules

Both upload endpoints now enforce the following server-side rules:

- authenticated access is required before upload processing
- upload payload must contain a non-empty file buffer
- size limits are enforced server-side
- client-declared MIME type must be on the endpoint allowlist
- magic-byte detection must also resolve to an allowed type
- storage object names are randomized and do not expose the original filename
- uploaded files are stored behind tokenized download URLs instead of public
  bucket objects

## Profile Photo Policy

Route: `POST /v1/profile/photos`

- authz:
  - authenticated user only
  - verified-email gate for email/password users
  - user document must exist before storage write
- allowed types:
  - `image/jpeg`
  - `image/png`
  - `image/webp`
  - `image/heic`
  - `image/heif`
- max size:
  - 10 MB
- additional checks:
  - Google Vision safe-search moderation gate
  - primary photo requires at least one detected face

## Chat Media Policy

Route: `POST /v1/chat/:conversationId/media`

- authz:
  - authenticated user only
  - verified-email gate for email/password users
  - requester must belong to the target match / conversation
- supported media kinds:
  - `image`
  - `video`
  - `audio`
- per-kind limits:
  - image: 25 MB
  - video: 100 MB
  - audio: 25 MB
- allowed MIME families:
  - image:
    - `image/jpeg`
    - `image/png`
    - `image/gif`
    - `image/webp`
    - `image/heic`
    - `image/heif`
  - video:
    - `video/mp4`
    - `video/quicktime`
    - `video/x-msvideo`
    - `video/webm`
  - audio:
    - `audio/mpeg`
    - `audio/mp4`
    - `audio/aac`
    - `audio/wav`
    - `audio/ogg`

## Storage Ingress Policy

- profile photos are stored under `photos/<uid>/...`
- chat media is stored under `chat_media/<uid>/<conversationId>/...`
- original filenames are not preserved in object paths
- files are saved with server-chosen extension derived from validated content
- download access is tokenized through Firebase Storage URLs

## Verification

- `npm run build` in `functions/`
- `npm run lint` in `functions/`
- `npx mocha --exit test/profileRestEndpoints.test.js --grep "POST /v1/profile/photos|POST /v1/chat/:conversationId/media"` in `functions/`

## Verification Note

The broader `functions/test/profileRestEndpoints.test.js` file still contains
two unrelated failing preference-route assertions outside this upload slice.
Those failures are not in the upload ingress path and were not changed here.
