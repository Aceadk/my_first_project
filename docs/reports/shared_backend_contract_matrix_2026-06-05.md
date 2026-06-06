# Shared Backend Contract Matrix - 2026-06-05

**Purpose:** Define the canonical backend contract for both mobile and web clients. All web mutations must use these endpoints or callables; direct Firestore writes are restricted by `firestore.rules`.

**Generated from:**
- `functions/src/index.ts` — 69 exported callables and REST endpoints
- `firestore.rules` — 2 collections and storage rules
- `Firebase Storage` — media paths

---

## I. Cloud Functions Callables

All callables require valid Firebase Auth token and App Check attestation. Request/response types are defined in `functions/src/index.ts`.

### Authentication

| Callable | Request | Response | Notes |
|----------|---------|----------|-------|
| `requestEmailOtp` | `{ email: string }` | `{ success: boolean; verificationId: string }` | Sends OTP to email |
| `verifyEmailOtp` | `{ email: string; otp: string }` | `{ success: boolean; user: UserDTO }` | Verifies email OTP, returns user token |
| `claimUsername` | `{ username: string }` | `{ success: boolean }` | Claims/reserves username (onboarding) |
| `signUpWithPassword` | `{ email: string; password: string; username?: string }` | `{ success: boolean; user: UserDTO }` | Creates account with password |
| `loginWithPassword` | `{ email: string; password: string }` | `{ success: boolean; user: UserDTO }` | Logs in with password |
| `requestPasswordReset` | `{ email: string }` | `{ success: boolean; verificationId: string }` | Initiates password reset flow |
| `verifyPasswordResetOtp` | `{ email: string; otp: string; verificationId: string }` | `{ success: boolean; token: string }` | Verifies password reset OTP |
| `resetPasswordWithToken` | `{ token: string; newPassword: string }` | `{ success: boolean }` | Finalizes password reset |
| `changePassword` | `{ currentPassword: string; newPassword: string }` | `{ success: boolean }` | Changes password for signed-in user |

### Discovery & Matching

> **Verified against source 2026-06-05.** Shapes below match
> `functions/src/index.ts` exactly. Backend success envelope is `{ ok: true }`
> (NOT `{ success }`). swipeRight does **not** return a match DTO.

| Callable | Request | Response | Notes |
|----------|---------|----------|-------|
| `fetchDiscoveryCandidates` | `{ limit?: number; cursor?: string }` | `{ candidates: CandidateDTO[]; cursor?: string }` | Paginated discovery deck |
| `getMyDiscoveryStatus` | `{}` | `{ isEligible: boolean; reason?: string; stats: DiscoveryStats }` | Checks discovery eligibility |
| `swipeRight` | `{ targetUserId: string; attachedMessage?: string }` | `{ matched: boolean; matchId?: string }` | Returns matchId only when mutual; fetch the match doc for full data |
| `swipeLeft` | `{ targetUserId: string }` | `{ ok: true }` | Logs pass only |
| `sendPreMatchMessageRequest` | `{ targetUserId: string; content: string }` | `{ ok: true; ... }` | Sends pre-match message (3/sender until reply) |
| `unmatch` | `{ matchId: string }` | `{ ok: true }` | Sets status `unmatched`; notifies other user |

### Chat & Messages

| Callable | Request | Response | Notes |
|----------|---------|----------|-------|
| `sendMessage` | `{ matchId: string; toUserId: string; content?: string; type?: string; mediaUrl?: string }` | `{ ok: true; messageId: string }` | `toUserId` is REQUIRED (other participant). Must have content or mediaUrl |
| `unsendMessage` | `{ matchId: string; messageId: string }` | `{ ok: true }` | Plus-plan only; sender-only |
| `editMessage` | `{ matchId: string; messageId: string; content: string }` | `{ ok: true }` | Sender-only edit |
| `markMessagesRead` | `{ matchId: string }` | `{ ok: true; markedCount: number }` | Marks all unread messages sent to caller |
| `setTyping` | `{ matchId: string; isTyping: boolean }` | `{ ok: true }` | Writes `typing.{uid}` on match doc |
| `setPresenceStatus` | `{ isOnline: boolean }` | `{ ok: true }` | Writes isOnline/lastSeenAt on user doc |
| `addReaction` | `{ matchId: string; messageId: string; emoji: string }` | `{ ok: true }` | Stores `reactions.{uid} = emoji` (one per user) |
| `removeReaction` | `{ matchId: string; messageId: string }` | `{ ok: true }` | NO emoji param; removes caller's reaction |
| `updateChatSettings` | `{ extendedRetention: boolean }` | `{ ok: true }` | Updates user's chat settings |
| `updateMatchChatSettings` | `{ matchId: string; extendedRetention: boolean }` | `{ ok: true }` | Updates match-specific chat settings |
| `getChatMediaSignedUrl` | `{ matchId: string; filePath: string }` | `{ url: string }` | Returns signed URL for media access |

### Profile & User Data

| Callable | Request | Response | Notes |
|----------|---------|----------|-------|
| `checkProfileCompleteness` | `{ [field: string]: unknown }` | `{ isComplete: boolean; missingFields: string[] }` | Validates profile completeness |
| `requestDataExport` | `{ format?: string }` | `{ success: boolean; requestId: string }` | Initiates data export job |

### Safety, Moderation & Account

| Callable | Request | Response | Notes |
|----------|---------|----------|-------|
| `reportUser` | `{ userId: string; reason: string; context?: string }` | `{ success: boolean; reportId: string }` | Files abuse report |
| `blockUser` | `{ userId: string }` | `{ success: boolean }` | Blocks user |
| `unblockUser` | `{ userId: string }` | `{ success: boolean }` | Unblocks user |
| `appealSafetyAction` | `{ actionId: string; reason: string }` | `{ success: boolean; appealId: string }` | Appeals safety restriction |
| `moderateTextContent` | `{ text: string }` | `{ safe: boolean; reason?: string }` | Checks text for violations |
| `moderateImageContent` | `{ image: Blob; context?: string }` | `{ safe: boolean; reason?: string }` | Checks image for violations |
| `notifyDatePlanContact` | `{ email: string; subject: string; body: string }` | `{ success: boolean }` | Sends email to date plan contact |

### Subscriptions & Payments

| Callable | Request | Response | Notes |
|----------|---------|----------|-------|
| `createCheckoutSession` | `{ planId: string; successUrl?: string; cancelUrl?: string }` | `{ success: boolean; sessionId: string; url?: string }` | Creates Stripe checkout session |
| `verifyGooglePurchaseToken` | `{ token: string; packageName: string }` | `{ success: boolean; entitlement: EntitlementDTO }` | Validates Google Play purchase |
| `verifyAppleTransaction` | `{ transactionId: string; bundleId: string }` | `{ success: boolean; entitlement: EntitlementDTO }` | Validates Apple receipt |
| `verifyPurchaseReceipt` | `{ receipt: string; platform: 'ios' \| 'android' }` | `{ success: boolean; entitlement: EntitlementDTO }` | Generic purchase validation |
| `syncSubscriptionStatus` | `{}` | `{ success: boolean; entitlement: EntitlementDTO }` | Syncs server subscription status |

### Calls & Signaling

| Callable | Request | Response | Notes |
|----------|---------|----------|-------|
| `initiateCall` | `{ recipientId: string }` | `{ success: boolean; callId: string }` | Initiates 1:1 call |
| `answerCall` | `{ callId: string }` | `{ success: boolean; iceServers: IceServer[] }` | Accepts incoming call |
| `endCall` | `{ callId: string }` | `{ success: boolean }` | Ends call |
| `addIceCandidate` | `{ callId: string; candidate: RTCIceCandidate }` | `{ success: boolean }` | Adds ICE candidate during call |
| `getIceServers` | `{}` | `{ iceServers: IceServer[] }` | Retrieves TURN/STUN servers |
| `enforceCallRingTimeout` | `{ callId: string }` | `{ success: boolean }` | Enforces ring timeout (backend) |
| `notifyCallSafetyEvent` | `{ callId: string; event: string }` | `{ success: boolean }` | Logs safety-related call event |
| `generateAgoraToken` | `{ channelName: string; uid: number }` | `{ token: string; expiresIn: number }` | Generates Agora RTC token |
| `getAgoraToken` | `{ channelName: string; uid: number }` | `{ token: string; expiresIn: number }` | Alias for generateAgoraToken |

---

## II. REST API Endpoints (`/v1/...`)

All endpoints require:
- `Authorization: Bearer {idToken}` header (Firebase ID token)
- `X-Goog-IAM-Authority-Selector` and `X-Goog-IAM-Authorization-Token` for App Check (staging/prod)

### Authentication

| Method | Path | Purpose | Body | Response |
|--------|------|---------|------|----------|
| POST | `/v1/auth/otp/send` | Send phone OTP | `{ phone_number: string }` | `{ success: boolean; verification_id: string }` |
| POST | `/v1/auth/otp/verify` | Verify phone OTP | `{ phone_number: string; otp: string; verification_id?: string }` | `{ success: boolean; user: UserDTO; tokens: TokensDTO }` |
| POST | `/v1/auth/token/refresh` | Refresh auth token | `{ refresh_token: string }` | `{ access_token: string; refresh_token: string; expires_in: number }` |
| POST | `/v1/auth/logout` | Logout user | `{}` | `{ success: boolean }` |
| POST | `/v1/auth/password/change` | Change password | `{ currentPassword: string; newPassword: string }` | `{ success: boolean }` |
| POST | `/v1/auth/apple/revocation` | Apple token revocation webhook | Signed payload | `{ success: boolean }` |

### Discovery & Matching

| Method | Path | Purpose | Body | Response |
|--------|------|---------|------|----------|
| GET | `/v1/discovery/deck` | Fetch discovery candidates | Query: `limit`, `cursor` | `{ candidates: CandidateDTO[]; cursor?: string }` |
| POST | `/v1/discovery/swipe` | Swipe on candidate | `{ candidateId: string; direction: 'right' \| 'left'; message?: string }` | `{ success: boolean; match?: MatchDTO }` |
| GET | `/v1/discovery/likes-you` | Fetch users who liked you | Query: `limit`, `cursor` | `{ likes: LikeDTO[]; cursor?: string }` |
| POST | `/v1/discovery/boost` | Activate discovery boost | `{ boostType?: string }` | `{ success: boolean; boostId: string; expiresAt: number }` |
| GET | `/v1/matches` | List user's matches | Query: `limit`, `cursor`, `status` | `{ matches: MatchDTO[]; cursor?: string }` |
| POST | `/v1/matches/:matchId/unmatch` | Unmatch with user | `{}` | `{ success: boolean }` |

### Chat & Messages

| Method | Path | Purpose | Body/Query | Response |
|--------|------|---------|-----------|----------|
| GET | `/v1/chat/conversations` | List all conversations | Query: `limit`, `cursor` | `{ conversations: ConversationDTO[]; cursor?: string }` |
| GET | `/v1/chat/:conversationId/messages` | Fetch messages | Query: `limit`, `cursor`, `from`, `to` | `{ messages: MessageDTO[]; cursor?: string; readAt?: number }` |
| POST | `/v1/chat/:conversationId/send` | Send message | `{ type: string; content: string; mediaUrl?: string; reactions?: string[] }` | `{ success: boolean; messageId: string; timestamp: number }` |
| POST | `/v1/chat/:conversationId/read` | Mark as read | `{ upToTimestamp: number }` | `{ success: boolean }` |
| POST | `/v1/chat/:conversationId/media` | Upload media (multipart) | File + `{ kind: 'image' \| 'video' \| 'audio' }` | `{ success: boolean; url: string; mediaId: string }` |
| PATCH | `/v1/chat/settings` | Update chat settings | `{ extendedRetention: boolean; ... }` | `{ success: boolean }` |

### Profile & Account

| Method | Path | Purpose | Body/Query | Response |
|--------|------|---------|-----------|----------|
| GET | `/v1/profile/me` | Get current user | — | `{ user: UserDTO }` |
| GET | `/v1/profile/:userId` | Get user profile | — | `{ user: UserDTO }` |
| PATCH | `/v1/profile/me` | Update profile | `{ profile: Partial<ProfileDTO> }` | `{ success: boolean; user: UserDTO }` |
| GET | `/v1/profile/preferences` | Get user preferences | — | `{ preferences: PreferencesDTO }` |
| PATCH | `/v1/profile/preferences` | Update preferences | `{ preferences: Partial<PreferencesDTO> }` | `{ success: boolean; preferences: PreferencesDTO }` |
| POST | `/v1/profile/photos` | Upload profile photo (multipart) | File + metadata | `{ success: boolean; photoId: string; url: string }` |
| DELETE | `/v1/profile/photos/:photoId` | Delete profile photo | — | `{ success: boolean }` |
| PATCH | `/v1/profile/photos/reorder` | Reorder photos | `{ photoIds: string[] }` | `{ success: boolean }` |

### Safety & Moderation

| Method | Path | Purpose | Body | Response |
|--------|------|---------|------|----------|
| POST | `/v1/users/report` | Report user | `{ userId: string; reason: string; context?: string }` | `{ success: boolean; reportId: string }` |
| POST | `/v1/users/block` | Block user | `{ userId: string }` | `{ success: boolean }` |
| POST | `/v1/users/unblock` | Unblock user | `{ userId: string }` | `{ success: boolean }` |
| POST | `/v1/safety/appeal` | Appeal safety action | `{ actionId: string; reason: string }` | `{ success: boolean; appealId: string }` |

### Calls

| Method | Path | Purpose | Body | Response |
|--------|------|---------|------|----------|
| POST | `/v1/calls/start` | Initiate call | `{ recipientId: string }` | `{ success: boolean; callId: string }` |
| POST | `/v1/calls/end` | End call | `{ callId: string }` | `{ success: boolean }` |

### Subscriptions & Billing

| Method | Path | Purpose | Body | Response |
|--------|------|---------|------|----------|
| GET | `/v1/subscription/plans` | List subscription plans | — | `{ plans: PlanDTO[] }` |
| GET | `/v1/subscription/current` | Get current subscription | — | `{ entitlement: EntitlementDTO; plan?: PlanDTO }` |
| POST | `/v1/subscription/checkout` | Create checkout session | `{ planId: string; successUrl?: string }` | `{ success: boolean; sessionId: string; url?: string }` |

---

## III. Firestore Collections & Schema

All Firestore rules are in `firestore.rules` (v2). Client writes are restricted; only backend mutations via Cloud Functions are allowed for sensitive fields.

### Users Collection
**Path:** `users/{uid}`

```typescript
{
  uid: string;                          // Doc ID = Firebase Auth UID
  email?: string;
  phoneNumber?: string;
  username?: string;
  plan: 'free' | 'plus';
  isEmailVerified: boolean;
  isPhoneVerified: boolean;
  isIdVerified: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  profile: {
    displayName?: string;
    bio?: string;
    gender?: 'male' | 'female' | 'other' | 'prefer_not_to_say';
    birthDate?: Timestamp;
    photoUrls?: string[];                // Max 9 photos
    videoUrls?: string[];
    interests?: string[];                // Max 20 interests
    location?: { latitude: number; longitude: number };
    heightCm?: number;
    relationshipGoals?: string;
    languages?: string[];
    // ... 20+ additional fields
    privacySettings?: {
      isProfileVisible: boolean;
      isPhoneVisible: boolean;
      isLocationVisible: boolean;
    };
  };
  preferences?: {
    ageRange?: { min: number; max: number };
    distanceKm?: number;
    genders?: string[];
    interestedIn?: string[];
    // ... additional preferences
  };
  stripeCustomerId?: string;            // Backend-only
  stripeSubscriptionId?: string;        // Backend-only
  fcmTokens?: { [token: string]: { platform: 'ios' | 'android' | 'web'; createdAt: Timestamp } };
  notificationPrefs?: {
    messages: boolean;
    matches: boolean;
    calls: boolean;
    // ... additional categories
  };
}
```

**Rules:**
- Owner can read/update own document
- Cannot directly modify `plan`, `isIdVerified`, `stripeCustomerId`, `stripeSubscriptionId`, `isEmailVerified`, `createdAt`
- Legacy flat fields (`name`, `gender`, `photoUrls`, etc.) are read-only for migration compatibility
- Profile photo URLs max 9; interests max 20

### Matches Collection
**Path:** `matches/{matchId}` — **verified against source 2026-06-05**

```typescript
{
  // Doc ID is auto-generated (db.collection("matches").doc()), NOT "uid1_uid2".
  userIds: [string, string];             // Participant UIDs
  status: 'active' | 'unmatched';        // (no archived/cancelled)
  preMatchRequests: { [uid: string]: number };  // per-user request counts
  pinnedForUser: { [uid: string]: boolean };    // per-user pin state
  createdAt: Timestamp;
  // NOTE: no `updatedAt`. Freshness comes from lastMessageAt.
  lastMessageAt?: Timestamp;
  lastMessageContent?: string | null;    // truncated to 100 chars
  lastMessageType?: string;
  lastMessageFromUserId?: string;
  readBy?: { [uid: string]: Timestamp }; // per-user last-read marker
  typing?: { [uid: string]: boolean };   // per-user typing flag
  typingUpdatedAt?: Timestamp;
  mediaSendingEnabled?: boolean;
  unmatchedBy?: string;
  unmatchedAt?: Timestamp;
  // Per-user unread count is NOT stored; backend computes at read time.
}
```

**Subcollection `matches/{matchId}/messages`:** — **verified against source**
```typescript
{
  // Doc ID is auto-generated.
  matchId: string;
  fromUserId: string;                   // sender (NOT senderId)
  toUserId: string;                     // recipient
  type: 'text' | 'image' | 'video' | 'audio' | 'voice' | 'gift';
  content: string | null;
  mediaUrl?: string | null;
  sentAt: Timestamp;                    // (NOT createdAt)
  isRead: boolean;
  readAt?: Timestamp;
  readBy?: string;
  isDeletedForSender: boolean;          // soft delete (per side)
  isDeletedForRecipient: boolean;
  reactions: { [uid: string]: string }; // one emoji per user (NOT emoji→[uid])
  reactionsUpdatedAt?: Timestamp;
  visibleTo: [string, string];          // [fromUserId, toUserId]
  editedAt?: Timestamp;                 // present after editMessage
  moderation?: { status; action; reason; severity; flagged };
}
```

**Rules:**
- Only match participants can read/update own messages
- Only message sender can edit/unsend own message
- Backend-managed match creation, status changes, and user participant updates
- Direct message creation is limited; mutations via callable preferred

### Blocks Collection
**Path:** `blocks/{blockerUid_blockedUid}`

```typescript
{
  blockerUid: string;
  blockedUid: string;
  createdAt: Timestamp;
  reason?: string;
}
```

### Auth Collections (Backend-Only)
- `auth_email_otps/{otpId}` — OTP verification records
- `auth_rate_limits/{key}` — Rate limit counters
- `auth_audit_logs/{logId}` — Auth event audit logs

### Reports Collection (Backend-Only)
**Path:** `reports/{reportId}`

```typescript
{
  reportId: string;
  reporterUid: string;
  reportedUid: string;
  reason: string;                       // Predefined codes
  context?: string;
  status: 'open' | 'investigating' | 'resolved' | 'dismissed';
  createdAt: Timestamp;
  resolutionNotes?: string;
}
```

---

## IV. Firebase Storage Paths

All storage operations are authenticated and use signed URLs returned by callables.

### Profile Photos
**Path:** `users/{uid}/profile_photos/{photoId}.{ext}`
- Formats: jpeg, png, webp, heic, heif
- Max: 10 MB per file
- Signed URL TTL: 1 hour (default)

### Chat Media
**Path:** `matches/{matchId}/media/{messageId}/{fileName}.{ext}`
- Images: jpeg, png, gif, webp, heic, heif (25 MB)
- Videos: mp4, quicktime, avi, webm (100 MB)
- Audio: mpeg, mp4, aac, wav, ogg (25 MB)
- Signed URL TTL: 1 hour (default)

### Data Exports
**Path:** `exports/{uid}/export_{timestamp}_{requestId}.json`
- Generated on-demand, time-limited signed URL
- TTL: 24 hours
- Auto-deleted after download TTL expires

### Firestore Backups
**Path:** `gs://{projectId}-firestore-backups/{YYYY-MM-DD}/`
- Daily automated backup
- Retention: 30 days (managed by bucket lifecycle policy)

---

## V. Environment & Firebase Configuration

### Firebase Project
- **Project ID:** `crush-265f7`
- **Auth Provider:** Firebase Authentication (Email, Phone, Google, Apple)
- **Database:** Firestore (default database)
- **Storage:** Cloud Storage for media
- **Functions Runtime:** Cloud Functions v2 (Node.js)

### CORS Allowed Origins
Configured via `CORS_ALLOWED_ORIGINS` environment variable.
Current production: `crushhour.app` (to be unified per domain matrix)

### Parameters (Firebase Functions)
- `CORS_ALLOWED_ORIGINS` — Comma-separated CORS allowlist
- `STRIPE_SECRET` — Stripe API secret key
- `STRIPE_WEBHOOK_SECRET` — Stripe webhook signature secret
- `GOOGLE_PLAY_PACKAGE_NAME` — Android package name for IAP validation
- `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`, `APPLE_BUNDLE_ID` — Apple receipt validation
- `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE` — Agora RTC credentials
- `OTP_SECRET` — Secret for OTP generation and verification
- `RESEND_API_KEY` — Resend.com email API key
- `EMAIL_FROM` — Default sender email address

---

## VI. How Web Should Consume This Contract

### Rules for Web Development

1. **All mutations must use callables or REST endpoints.** Direct Firestore writes to `matches/*`, `messages/*`, and other sensitive collections will fail under `firestore.rules`.

2. **Query patterns must match Firestore rules expectations.** For example:
   - Read `users/{uid}` only if owner, signed in, and not blocked, or if user has shared access
   - Read `matches/{matchId}/messages` only if participant
   - Query `matches` by index (backend pre-creates, web reads)

3. **Signed URLs for media.** Always call `getChatMediaSignedUrl` or retrieve from message DTO; do not construct direct Storage paths.

4. **No direct Firestore schema mutations.** If schema needs to change (e.g., adding a new field to user profile), update both mobile and web tests, then both client implementations, and finally deploy backend/rules together.

5. **Version-aware client updates.** If a callable or REST response shape changes, coordinate with mobile client updates. Use feature flags or graceful fallbacks during transition periods.

---

## VII. Testing Contract Compliance

All changes to this contract must pass:
- `functions/test/*` — Callable and REST endpoint contract tests
- Cross-repo E2E tests (web + mobile against shared backend)
- Firestore emulator tests for schema and rules

**Next Steps:**
1. Add `crush-web` contract tests that validate REST request/response shapes against this matrix
2. Add Firestore emulator tests for web query patterns
3. Add E2E tests for core flows (discovery → match → chat → unmatch)

---

## Revision History

| Date | Changes |
|------|---------|
| 2026-06-05 | Initial contract matrix from `my_first_project/functions` and `firestore.rules`. 69 callables/endpoints, 5+ collections, Firebase Storage paths documented. |
| 2026-06-05 (rev 2) | **Verified callable + Firestore shapes directly against `functions/src/index.ts`** during web V2 implementation. Corrected: swipe/message/reaction request shapes, `{ ok }` success envelope, swipeRight returns `{ matched, matchId? }` (no DTO), message fields (`fromUserId`/`toUserId`/`sentAt`/`reactions` map), match fields (`pinnedForUser`/`preMatchRequests` maps, no `participants`/`updatedAt`). |
