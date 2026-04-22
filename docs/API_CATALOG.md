# API Contract Catalog -- CRUSH Dating App

Date: 2026-04-22
Owner: Codex
Primary Sources:
- `functions/src/index.ts`
- `functions/src/calls/signaling.ts`
- `lib/core/network/api_version.dart`
- current runtime client wrappers under `lib/features/**/data/repositories/impl/`

## Purpose

This document is the canonical inventory of the currently exported backend
surface for CRUSH. It records:

- callable Cloud Functions currently exported
- versioned REST endpoints currently exposed by the Express `api` function
- standalone HTTP webhooks, Firestore triggers, and scheduled jobs
- the direct client wrappers that target those contracts today
- currently known contract drift between the client and backend

## Conventions

- REST routes below are shown with their real backend paths, for example
  `/v1/profile/me`.
- Flutter `ApiEndpoints` constants intentionally omit the `/v1` prefix because
  `ApiConfig.getUrl()` prepends `/v1` at request time.
- `callable<T>()` in `functions/src/index.ts` enforces App Check and normalizes
  unexpected failures to generic `HttpsError("internal", ...)`.
- `functions.https.onCall(...)` exports outside that wrapper do not inherit the
  same behavior unless they call `verifyAppCheck(...)` themselves.
- The shared Flutter [`ApiClient`](/Users/ace/my_first_project/lib/core/network/api_client.dart)
  only auto-retries transport failures for `GET` requests. Write verbs
  (`POST`, `PUT`, `PATCH`, `DELETE`) return the first socket/timeout failure
  unless the retry is part of the one-time 401 token-refresh replay path.
- "Client" references below list direct runtime call sites in `lib/`. Test-only
  usage is intentionally excluded.

## Callable Functions

### Auth And Account

| Export | Auth | App Check | Client | Request | Response | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `requestEmailOtp` | Anonymous for login/reset; signed-in context required for add/change email purpose | Yes via `callable<T>()` | `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart`, `lib/features/auth/data/repositories/impl/http_auth_repository.dart` | `identifier`, `purpose`, `email?` | `{ status }` | Rate-limited by IP and identifier; silent success on unknown identifiers to avoid enumeration. |
| `verifyEmailOtp` | Same as above | Yes | `firebase_auth_repository.dart`, `http_auth_repository.dart` | `identifier`, `purpose`, `otp`, `newEmail?`, `newPassword?` | `{ status, customToken? }` | Per-OTP failed-attempt lock; purpose-specific side effects for login, email change, and password reset. |
| `claimUsername` | Required | Yes | no direct runtime wrapper found | `username` | `{ status, username }` | Transactional uniqueness check; invalid usernames fail with `invalid-argument`. |
| `signUpWithPassword` | Anonymous | Yes | `firebase_auth_repository.dart`, `http_auth_repository.dart` | `username`, `email`, `password` | `{ status, customToken }` | Rate-limited by IP, email, and username. |
| `loginWithPassword` | Anonymous | Yes | `firebase_auth_repository.dart`, `http_auth_repository.dart` | `identifier`, `password` | `{ status, customToken }` | Constant-time miss path; rate-limited by IP and identifier. |
| `requestPasswordReset` | Anonymous | Yes | `firebase_auth_repository.dart`, `http_auth_repository.dart` | `email` | `{ status, message }` | Silent success when email is unknown or unsupported. |
| `verifyPasswordResetOtp` | Anonymous | Yes | `firebase_auth_repository.dart`, `http_auth_repository.dart` | `email`, `otp` | `{ status, resetToken }` | Rate-limited; returns one-time reset token. |
| `resetPasswordWithToken` | Anonymous | Yes | `firebase_auth_repository.dart`, `http_auth_repository.dart` | `email`, `resetToken`, `newPassword` | `{ status }` | Invalid or expired tokens fail with `failed-precondition` / `permission-denied`. |
| `changePassword` | Required | Yes | `firebase_auth_repository.dart` | `currentPassword`, `newPassword` | `{ status }` | Revokes sessions on success; rate-limited by IP and UID. |
| `requestAccountDeletion` | Required | Manual `verifyAppCheck(...)` | `http_auth_repository.dart` | `reason?` | `{ success, scheduledAt, gracePeriodDays, message }` | Not wrapped by `callable<T>()`; schedules 14-day deletion grace period. |
| `cancelAccountDeletion` | Required | Manual `verifyAppCheck(...)` | no direct runtime wrapper found | none | `{ success, message }` | Not wrapped by `callable<T>()`; returns success even when nothing is pending. |
| `requestDataExport` | Required | Yes | `lib/core/services/data_export_request_service.dart` | none | `{ requestId, status }` | Email verification required; cooldown enforced at 7 days. |

### Discovery And Matching

| Export | Auth | App Check | Client | Request | Response | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `fetchDiscoveryCandidates` | Required | Yes | `lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart` | discovery filters such as `cursor`, `limit`, age range, distance, gender filters, interest filters, coordinates | `{ candidates, total, hasMore, nextCursor, requesterStatus? }` | Current callable path no longer requires verified email; eligibility and exclusion logic still run server-side. |
| `getMyDiscoveryStatus` | Required | Yes | no direct runtime wrapper found | none | `{ eligible, reasons, summary }` | Debug/status endpoint for why a requester is or is not discoverable. |
| `swipeRight` | Required | Yes | `firebase_discovery_repository.dart` | `targetUserId`, `attachedMessage?` | `{ matched, matchId? }` | Email verification and profile-quality gate required; like limit enforcement can return `resource-exhausted`. |
| `swipeLeft` | Required | Yes | `firebase_discovery_repository.dart` | `targetUserId` | `{ ok }` | Email verification and profile-quality gate required. |
| `sendPreMatchMessageRequest` | Required | Yes | no direct runtime wrapper found | `targetUserId`, `content` | `{ ok }` | Max three unreplied requests per sender/pair. |

### Chat, Safety, And Moderation

| Export | Auth | App Check | Client | Request | Response | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `sendMessage` | Required | Yes | `lib/features/chat/data/repositories/impl/firebase_chat_repository.dart` | `matchId`, `toUserId`, `content?`, `type?`, `mediaUrl?` | `{ ok, messageId }` | Email verification required; participant enforcement and moderation checks happen server-side. |
| `editMessage` | Required | Yes | `firebase_chat_repository.dart` | `matchId`, `messageId`, `content` | `{ ok }` | Sender-only edit. |
| `unsendMessage` | Required | Yes | `firebase_chat_repository.dart` | `matchId`, `messageId` | `{ ok }` | Plus-only feature; sender-only. |
| `markMessagesRead` | Required | Yes | `firebase_chat_repository.dart` | `matchId` | `{ ok, markedCount }` | Participant-only; updates read receipts. |
| `setTyping` | Required | Yes | indirect realtime/chat usage | `matchId`, `isTyping` | `{ ok }` | Match participant required. |
| `setPresenceStatus` | Required | Yes | no direct runtime wrapper found | `isOnline?` | `{ ok }` | Presence/last-seen update helper. |
| `setMediaSendingEnabled` | Required | Yes | `firebase_chat_repository.dart` | `matchId`, `enabled` | `{ ok }` | Match participant required. |
| `addReaction` | Required | Yes | no direct runtime wrapper found | `matchId`, `messageId`, `emoji` | `{ ok }` | Match participant required. |
| `removeReaction` | Required | Yes | no direct runtime wrapper found | `matchId`, `messageId` | `{ ok }` | Removes the caller's own reaction. |
| `unmatch` | Required | Yes | `firebase_chat_repository.dart` | `matchId` | `{ ok }` | Email verification required; participant-only. |
| `reportUser` | Required | Yes | `firebase_chat_repository.dart` | `reportedId`, `reason`, `matchId?`, `messageId?`, `source?`, `description?` | `{ ok }` | Email verification required; report rate limit enforced. |
| `blockUser` | Required | Yes | `firebase_chat_repository.dart` | `blockedId` | `{ ok }` | Email verification required; block rate limit enforced. |
| `unblockUser` | Required | Yes | `firebase_chat_repository.dart` | `blockedId` | `{ ok }` | Unblock rate limit enforced. |
| `appealSafetyAction` | Required | Yes | `lib/features/chat/data/repositories/impl/firebase_chat_repository.dart` | `reason`, `targetType?`, `targetId?` | `{ ok }` | Creates appeal document and reopens user appeal flag. |
| `moderateTextContent` | Anonymous | Yes | `lib/core/services/content_moderation_service.dart` | `content` | `{ status, action, reason, severity }` | Text moderation helper for client-side preflight and server parity. |
| `moderateImageContent` | Anonymous | Yes | `content_moderation_service.dart` | `imageUrl` | `{ status, action, reason, severity }` | Placeholder implementation currently returns a clean result. |
| `notifyDatePlanContact` | Required | Yes | `lib/features/safety/data/services/date_plan_service.dart` | contact, match, date/time, location, notes fields | `{ success }` | Per-contact rate limit; Resend-backed safety email. |
| `getChatMediaSignedUrl` | Required | Yes | no direct runtime wrapper found | `matchId`, `filePath` | `{ url }` | Email verification required; validates match membership and file-path prefix. |

### Subscription, Purchases, And Chat Retention

| Export | Auth | App Check | Client | Request | Response | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `createCheckoutSession` | Required | Yes | `lib/features/subscription/data/repositories/impl/firebase_subscription_repository.dart` | `priceId`, `successUrl`, `cancelUrl` | `{ url }` | Email verification required; Stripe must be configured. |
| `verifyGooglePurchaseToken` | Required | Yes | no matching runtime client wrapper; see drift section | `productId`, `purchaseToken`, `packageName?` | synced entitlement payload | Email verification required; validates and persists Google Play subscription state. |
| `verifyAppleTransaction` | Required | Yes | no direct runtime wrapper found | `transactionId`, `productId?` | synced entitlement payload | Email verification required; validates App Store authoritative transaction data. |
| `verifyPurchaseReceipt` | Required | Yes | `firebase_subscription_repository.dart` | `platform`, `receiptData`, `productId?`, `packageName?` | synced entitlement payload | Unified mobile purchase validation entrypoint. |
| `syncSubscriptionStatus` | Required | Yes | `firebase_subscription_repository.dart` | none | `{ plan, status, currentPeriodEnd?, cancelAtPeriodEnd? }` | Stripe-backed entitlement refresh. |
| `updateChatSettings` | Required | Yes | `lib/features/settings/presentation/bloc/chat_settings_cubit.dart` | `extendedRetention` | `{ success, extendedRetention, retentionHours, message }` | Free users: 1h or 24h; Plus users still get 7-day retention in RTDB sync. |
| `updateMatchChatSettings` | Required | Yes | `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart` | `matchId`, `extendedRetention` | `{ success, matchId, extendedRetention, retentionHours, message }` | Match participant required. |

### Calls And Real-Time Signaling

| Export | Auth | App Check | Client | Request | Response | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `initiateCall` | Required | Yes via shared `callable<T>()` wrapper | `lib/features/calls/data/services/call_service.dart`, `lib/features/calls/data/repositories/impl/firebase_call_repository.dart` | `receiverId`, `type`, `offer?` | `{ callId, status, expiresAtMs }` | Per-caller 10-second initiation rate limit. |
| `answerCall` | Required | Yes via shared `callable<T>()` wrapper | `call_service.dart` | `callId`, `answer?` | `{ callId, status }` | Receiver-only answer path. |
| `endCall` | Required | Yes via shared `callable<T>()` wrapper | `call_service.dart` | `callId`, `reason?` | `{ callId, status, endReason }` | Participant-only end path. |
| `addIceCandidate` | Required | Yes via shared `callable<T>()` wrapper | `call_service.dart` | `callId`, `target`, `candidate` | `{ callId, candidateId }` | Valid targets are `caller`, `receiver`, or `all`. |
| `getIceServers` | Required | Yes via shared `callable<T>()` wrapper | `call_service.dart` | none | `{ iceServers, ttlSeconds }` | Returns TURN config plus default STUN servers. |
| `notifyCallSafetyEvent` | Required | Yes via shared `callable<T>()` wrapper | `call_service.dart`, `lib/features/calls/presentation/screens/call_screen.dart` | `targetUserId`, `eventType`, `callId?`, `isVideoCall?` | `{ eventType, deliveredTo }` | Valid event types: screenshot / recording_started / recording_stopped. |
| `generateAgoraToken` | Required | Yes | no direct runtime wrapper found | `channelName`, `uid?`, `isVideoCall?` | `{ token, appId, channelName, uid, expireTime }` | Raw Agora token minting helper. |
| `getAgoraToken` | Required | Yes | no direct runtime wrapper found | `channelName`, `isVideoCall?` | `{ token, uid, appId, isVideoCall }` | Uses auth UID hash as Agora UID. |

### Profile Utility

| Export | Auth | App Check | Client | Request | Response | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `checkProfileCompleteness` | Required | Yes | `lib/features/profile/data/services/profile_validation_service.dart` | `minimum?` (`swipe` or `messaging`) | completeness scoring payload | Returns normalized completeness score, breakdown, missing items, threshold info, and minimum checks. |

## Versioned REST Endpoints (`api`)

### Auth

| Method | Path | Auth | App Check | Client | Contract Summary | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `POST` | `/v1/auth/otp/send` | No | Yes via `appCheckRestMiddleware` | no direct runtime wrapper found | request `phone_number`; response `{ success, verification_id, message }` | Export remains for legacy/compatibility clients; current repositories use Firebase phone auth instead. |
| `POST` | `/v1/auth/otp/verify` | No | Yes | no direct runtime wrapper found | request `phone_number`, `otp`, `verification_id?`; response `{ success, message, user, tokens }` | Export remains for legacy/compatibility clients; current repositories use Firebase phone auth instead. |
| `POST` | `/v1/auth/token/refresh` | No | Yes | no direct runtime wrapper found | request `refresh_token`; response `{ access_token, refresh_token, expires_in }` | Current HTTP auth mode now refreshes Firebase ID tokens through the session bridge instead of this legacy contract. |
| `POST` | `/v1/auth/logout` | Required | Yes | `ApiEndpoints.authLogout`, `HttpAuthRepository.signOut()` | empty request; response `{ success }` | Revokes refresh tokens. |
| `POST` | `/v1/auth/password/change` | Required | Yes | `HttpAuthRepository.changePassword(...)` | request `current_password` or `currentPassword`, `new_password` or `newPassword`; response `{ success, message }` | Verified password required; rate-limited by IP and UID. |
| `POST` | `/v1/auth/apple/revocation` | No client auth; Apple server-to-server webhook | No | external Apple server callback | form payload JWT; response `{ success }` or structured error | Used for Apple credential revocation handling. |

### Profile

| Method | Path | Auth | App Check | Client | Contract Summary | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `/v1/profile/me` | Required | No dedicated REST App Check middleware | `ApiEndpoints.profileMe`, `Http profile wrappers` | response includes account fields plus normalized `photos`, `prompts`, and canonical nested `preferences` | 404 when user doc is missing. |
| `PATCH` | `/v1/profile/me` | Required | No dedicated REST App Check middleware | `ApiEndpoints.profileUpdate` | validated patch payload; response `{ success, message }` | Verified email/password required through `requireVerifiedEmail`. |
| `POST` | `/v1/profile/photos` | Required | No dedicated REST App Check middleware | `ApiEndpoints.profilePhotos`, `ApiClient.uploadFile(...)` consumers | multipart `photo`, optional `is_primary`; response `{ id, url, is_primary }` | Verified email required; server-side MIME allowlist, magic-byte validation, moderation, private tokenized URLs. |
| `DELETE` | `/v1/profile/photos/:photoId` | Required | No dedicated REST App Check middleware | `ApiEndpoints.profilePhotoById(...)` | path `photo_INDEX`; response `{ success }` | 400 on malformed photo id; 404 when user or photo is missing. |
| `POST` | `/v1/profile/photos/reorder` | Required | No dedicated REST App Check middleware | `ApiEndpoints.profilePhotoReorder`, `HttpProfileRepository.reorderPhotos(...)` | request `photo_ids[]`; response `{ success, photos }` | Requires the full ordered photo id list; rejects duplicates or missing ids. |
| `PATCH` | `/v1/profile/preferences` | Required | No dedicated REST App Check middleware | `ApiEndpoints.profilePreferences` | preference patch; response `{ success, preferences }` | Merges over canonical nested preferences; 400 on invalid age range. |
| `GET` | `/v1/profile/:userId` | Required | No dedicated REST App Check middleware | `ApiEndpoints.profileById(...)`, `ApiEndpoints.profiles(...)` consumers | response includes public profile view with normalized `photos`, `prompts`, and verification flag | 404 when user is missing. |

### Discovery

| Method | Path | Auth | App Check | Client | Contract Summary | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `/v1/discovery/deck` | Required | No dedicated REST App Check middleware | `ApiEndpoints.discoveryDeck`, `HttpDiscoveryRepository` | query filters and `cursor`; response includes `candidates`, legacy `profiles`, `total`, `hasMore`, `nextCursor`, `requester_status` | `rateLimitDiscovery`; response intentionally duplicates camelCase and snake_case cursor fields. |
| `GET` | `/v1/discovery/likes-you` | Required | No dedicated REST App Check middleware | `ApiEndpoints.discoveryLikesYou`, `HttpDiscoveryRepository.fetchLikesYou(...)` | optional query `offset`, `limit`; response `{ candidates, profiles, total_count, has_more, next_offset }` | `rateLimitDiscovery`; merges inbound `likes` and `swipes`, deduplicates by liker using newest activity first, and keeps backward compatibility by returning the full merged list when no explicit `limit` is supplied. |
| `POST` | `/v1/discovery/swipe` | Required | No dedicated REST App Check middleware | `ApiEndpoints.discoverySwipe`, `HttpDiscoveryRepository` | request `target_user_id`, `action`, `message?`; response `{ success, is_match, match_id }` | Verified email required; supports `like`, `super_like`, and `pass`. |
| `POST` | `/v1/discovery/boost` | Required | No dedicated REST App Check middleware | `ApiEndpoints.discoveryBoost` | empty request; response `{ success, expires_at }` | Verified email required. |

Rewind is intentionally absent from the current exported discovery contract.
Discovery runtime/UI now treats rewind as unavailable instead of simulating a
local undo without a reversible backend ledger.

### Matches And Chat

| Method | Path | Auth | App Check | Client | Contract Summary | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `/v1/matches` | Required | No dedicated REST App Check middleware | `ApiEndpoints.matches`, `HttpDiscoveryRepository`, `HttpChatRepository.fetchUserMatchesPaginated(...)` | query `offset`, `limit`, optional `before`; response `{ matches, total_count, has_more, next_cursor }` | Existing offset pagination remains supported for current clients; optional `before` adds a backward-compatible keyset path using the oldest page `lastMessageAt` ISO timestamp, malformed cursors fail with 400, and `rateLimitDefault` applies. |
| `POST` | `/v1/matches/:matchId/unmatch` | Required | No dedicated REST App Check middleware | `ApiEndpoints.unmatch(...)` | empty request; response `{ success }` | Participant-only. |
| `GET` | `/v1/chat/conversations` | Required | No dedicated REST App Check middleware | `ApiEndpoints.chatConversations`, `HttpChatRepository` | query `limit`, `before`; response `{ conversations, total_count, has_more, next_cursor }` | `rateLimitDefault`; cursor is the oldest page `lastMessageAt` ISO timestamp, responses keep legacy `participant` while also emitting `match_id` and `participants[]`, and invalid `before` cursors fail with 400. |
| `GET` | `/v1/chat/:conversationId/messages` | Required | No dedicated REST App Check middleware | `ApiEndpoints.chatMessages(...)`, `HttpChatRepository` | query `limit`, `before`; response `{ messages, has_more, next_cursor }` | `before` now accepts the ISO timestamp cursor already used by the client, with legacy message-id fallback; participant check and `rateLimitDefault` apply. |
| `POST` | `/v1/chat/:conversationId/send` | Required | No dedicated REST App Check middleware | `ApiEndpoints.chatSend(...)`, `HttpChatRepository` | request `type`, `content`, `media_url`; response `{ id, success }` | `rateLimitMessage`; content sanitized before write. |
| `POST` | `/v1/chat/:conversationId/media` | Required | No dedicated REST App Check middleware | `ApiClient.uploadFile(...)` chat upload consumers | multipart `media`, required `type`; response `{ url }` | Verified email required; match membership enforced; private tokenized storage URLs. |
| `POST` | `/v1/chat/:conversationId/read` | Required | No dedicated REST App Check middleware | `ApiEndpoints.chatRead(...)`, `HttpChatRepository` | empty request; response `{ success }` | Updates `readBy.<uid>` on match document. |
| `PUT` | `/v1/chat/settings` | Required | No dedicated REST App Check middleware | no direct HTTP runtime wrapper found | request `extended_retention`; response `{ success, extended_retention, retention_hours, message }` | Updates chat retention settings and RTDB mirror. |
| `GET` | `/v1/chat/settings` | Required | No dedicated REST App Check middleware | no direct HTTP runtime wrapper found | response `{ extended_retention, is_premium, retention_hours, retention_description }` | Mirrors per-user retention status. |
| `POST` | `/v1/calls/start` | Required | No dedicated REST App Check middleware | `ApiEndpoints.callStart`, `HttpCallRepository.startCall(...)` | request `match_id`, `is_video`; response `{ call_id, channel_name, local_uid, status, expires_at_ms }` | Verified email required; resolves the remote participant from the match before reusing the signaling backend, and inherits the shared 10-second per-caller initiation throttle from `initiateCallForUser` so repeated rapid attempts return 429 / `resource-exhausted`. |
| `POST` | `/v1/calls/end` | Required | No dedicated REST App Check middleware | `ApiEndpoints.callEnd`, `HttpCallRepository.endCall(...)` | request `call_id`, `reason?`; response `{ success, call_id, status, end_reason }` | Participant-only call termination path backed by the shared signaling logic. |

### Subscription And Safety

| Method | Path | Auth | App Check | Client | Contract Summary | Key Errors / Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `GET` | `/v1/subscription/plans` | No | No dedicated REST App Check middleware | `ApiEndpoints.subscriptionPlans`, `HttpSubscriptionRepository` | response `{ plans }` | Returns DB-backed plans or default Free/Plus fallback. |
| `POST` | `/v1/subscription/checkout` | Required | No dedicated REST App Check middleware | `ApiEndpoints.subscriptionPurchase`, `HttpSubscriptionRepository.startCheckout(...)` | request `price_id`, `success_url?`, `cancel_url?`; response `{ session_id, url }` | Stripe must be configured. |
| `GET` | `/v1/subscription/current` | Required | No dedicated REST App Check middleware | `ApiEndpoints.subscriptionStatus`, `HttpSubscriptionRepository` | response `{ plan, expires_at, is_active }` | Minimal subscription status endpoint. |
| `POST` | `/v1/safety/appeal` | Required | No dedicated REST App Check middleware | `ApiEndpoints.safetyAppeal`, `HttpChatRepository.submitSafetyAppeal(...)` | request `reason`, `target_type?`, `target_id?`; response `{ success }` | REST parity for the callable appeal flow used by HTTP mode. |
| `POST` | `/v1/users/block` | Required | No dedicated REST App Check middleware | `ApiEndpoints.blockUser`, `HttpChatRepository.blockUser(...)` | request `blocked_id`; response `{ success }` | Verified email required; structured audit logging and rate limiting. |
| `POST` | `/v1/users/unblock` | Required | No dedicated REST App Check middleware | `ApiEndpoints.unblockUser`, `HttpChatRepository.unblockUser(...)` | request `blocked_id`; response `{ success }` | Verified email required; structured audit logging and rate limiting. |
| `POST` | `/v1/users/report` | Required | No dedicated REST App Check middleware | `ApiEndpoints.reportUser`, `HttpChatRepository.reportUser(...)` | request `reported_id`, `reason`, `description?`, `match_id?`, `message_id?`; response `{ success }` | Verified email required; structured audit logging and rate limiting. |

## Standalone HTTP, Triggers, And Scheduled Jobs

### Standalone HTTP Functions

| Export | Type | Contract Summary |
| --- | --- | --- |
| `appleSubscriptionWebhook` | `functions.https.onRequest` | Apple App Store Server Notifications v2 ingestion. Accepts signed payload; updates entitlement lifecycle and user subscription fields. |
| `googleRtdnWebhook` | `functions.https.onRequest` | Google Play RTDN ingestion. Verifies token if configured; updates entitlement lifecycle and user purchase metadata. |
| `stripeWebhook` | `functions.https.onRequest` | Stripe webhook ingestion. Handles checkout completion and subscription lifecycle events. |

### Firestore Triggers

| Export | Trigger | Contract Summary |
| --- | --- | --- |
| `onMessageCreated` | `matches/{matchId}/messages/{messageId}` on create | Moderation and notification side effects for new messages. |
| `onMatchCreated` | `matches/{matchId}` on create | Migrates pre-match requests and sends new-match notifications. |
| `onSubscriptionUpdated` | `users/{userId}` on update | Emits subscription change notifications. |
| `syncLegacyDiscoveryFields` | `users/{userId}` on write/update path | Maintains mirrored root discovery fields used by indexed deck queries. |
| `onMessageRead` | `matches/{matchId}/messages/{messageId}` on update | Schedules retention-based deletion for both sender and reader. |
| `onPlanChangeUpdateChatSettings` | `users/{userId}` on update | Syncs chat retention mirrors after plan changes. |
| `processDataExportRequest` | `users/{userId}/dataExportRequests/{requestId}` on create | Builds async GDPR export bundle and posts download notification. |
| `enforceCallRingTimeout` | `calls/{callId}` on create | Marks unanswered calls missed after the configured ring timeout. |

### Scheduled / Queue Jobs

| Export | Schedule | Contract Summary |
| --- | --- | --- |
| `flushNotificationQueue` | Pub/Sub schedule | Flushes queued notification work. |
| `processMessageDeletionQueue` | every 15 minutes | Applies chat-retention deletions and clears RTDB queue items. |
| `cleanupExpiredMessageRequests` | every 1 hour | Deletes expired message-request documents. |
| `processScheduledAccountDeletions` | every 6 hours | Executes pending account-deletion cascade jobs. |
| `scheduledFirestoreBackup` | every 24 hours | Starts Firestore export to Cloud Storage backup bucket. |

## Remaining Contract Drift

The 2026-04-19 API-004, 2026-04-21 API-005, and 2026-04-21 API-006
remediation slices removed the documented dead client paths for discovery/chat/
subscription/calls/profile utilities, aligned HTTP auth with real backend
contracts, retired discovery rewind explicitly at the runtime/product layer,
and brought call signaling under the shared callable App Check wrapper.

There is no separately documented client/backend contract drift remaining in
this catalog at this time. The next API backlog slice returns to broader API
quality work such as pagination, rate limiting, and retry semantics.

## Verification

Inventory verification for this document was done against live source and
representative endpoint tests:

- `rg -n "^export const [A-Za-z0-9_]+ =" functions/src/index.ts`
- `rg -n "app\\.(get|post|patch|put|delete)\\(" functions/src/index.ts`
- `rg -n "httpsCallable\\(" lib`
- `npx mocha --exit test/callables.test.js` in `functions/`
- `npx mocha --exit test/call-signaling.test.js test/appCheckRest.test.js` in `functions/`
- `npx mocha --exit test/profileRestEndpoints.test.js --grep "GET /v1/profile/me|POST /v1/profile/photos|POST /v1/chat/:conversationId/media"` in `functions/`

## Actionable Outcome

`API-001`, `API-005`, and `API-006` are complete. The next execution step
should be `API-002` for pagination, rate limiting, and retry semantics, not
another inventory pass.
