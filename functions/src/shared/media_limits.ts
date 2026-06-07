/**
 * Media upload limits & MIME tables (Phase 9 Step 21 — first domain extraction).
 *
 * Pure data extracted verbatim from index.ts as the first slice of the
 * functions domain split (see docs/contracts/complexity_reduction_plan_2026-06-07.md).
 * Behavior is unchanged: index.ts imports these names. Profile photo limits here
 * are the canonical source mirrored by the web client
 * (packages/core/src/config/profile_capabilities.ts).
 */

export const PROFILE_PHOTO_MAX_BYTES = 10 * 1024 * 1024; // 10MB
export const PROFILE_PHOTO_ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
]);
export const PROFILE_PHOTO_EXTENSION_BY_MIME: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heif",
};

export type ChatMediaUploadKind = "image" | "video" | "audio";

export const CHAT_MEDIA_MAX_BYTES_BY_KIND: Record<ChatMediaUploadKind, number> = {
  image: 25 * 1024 * 1024,
  video: 100 * 1024 * 1024,
  audio: 25 * 1024 * 1024,
};
export const CHAT_MEDIA_ALLOWED_MIME_TYPES_BY_KIND: Record<
  ChatMediaUploadKind,
  Set<string>
> = {
  image: new Set([
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "image/heic",
    "image/heif",
  ]),
  video: new Set([
    "video/mp4",
    "video/quicktime",
    "video/x-msvideo",
    "video/webm",
  ]),
  audio: new Set([
    "audio/mpeg",
    "audio/mp4",
    "audio/aac",
    "audio/wav",
    "audio/ogg",
  ]),
};
export const CHAT_MEDIA_EXTENSION_BY_MIME: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/gif": "gif",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heif",
  "video/mp4": "mp4",
  "video/quicktime": "mov",
  "video/x-msvideo": "avi",
  "video/webm": "webm",
  "audio/mpeg": "mp3",
  "audio/mp4": "m4a",
  "audio/aac": "aac",
  "audio/wav": "wav",
  "audio/ogg": "ogg",
};
export const CHAT_MEDIA_MAX_BYTES = Math.max(
  ...Object.values(CHAT_MEDIA_MAX_BYTES_BY_KIND),
);
