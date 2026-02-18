# API Contract Catalog -- CRUSH Dating App

> **Source:** `functions/src/index.ts`
> **Generated:** 2026-02-18
> **Runtime:** Firebase Functions v1 (Node.js 22)

---

## Table of Contents

1. [Callable Functions (onCall)](#1-callable-functions-oncall)
2. [HTTP Endpoints (onRequest -- Express REST API)](#2-http-endpoints-onrequest--express-rest-api)
3. [Standalone HTTP Endpoints (onRequest)](#3-standalone-http-endpoints-onrequest)
4. [Firestore Triggers](#4-firestore-triggers)
5. [Scheduled Functions (Pub/Sub)](#5-scheduled-functions-pubsub)
6. [Constants and Rate Limit Reference](#6-constants-and-rate-limit-reference)

---

## 1. Callable Functions (onCall)

All callable functions listed below go through the `callable<T>()` wrapper which:
- Automatically calls `verifyAppCheck(context, ...)` on **every** invocation (enforced in production, warning-only in emulator)
- Catches non-HttpsError exceptions and returns a generic "Unexpected error" response
- Logs errors with UID context

### 1.1 Authentication & Identity

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 1 | `requestEmailOtp` | No (but auth required for `add_email`/`change_email` purposes) | Yes (via wrapper) | No | **IP:** 5 req / 10 min (20 min block); **Identifier:** 5 req / 10 min (20 min block) | Request a 6-digit OTP sent to email. Supports purposes: `login`, `add_email`, `change_email`, `reset_password`, `new_device`, `sensitive_action`. Silent success on invalid identifier (no user enumeration). |
| 2 | `verifyEmailOtp` | No (but auth required for `add_email`/`change_email` purposes) | Yes (via wrapper) | No | **IP:** 10 req / 10 min (20 min block); **Identifier:** 10 req / 10 min (20 min block); **Per-OTP:** 5 failed attempts = 15 min lock | Verify a 6-digit OTP. For `login`: returns `customToken`. For `add_email`/`change_email`: updates email in Auth+Firestore. For `reset_password`: resets password directly if `newPassword` provided. |
| 3 | `claimUsername` | **Yes** | Yes (via wrapper) | No | None | Claim a unique username. Validates against regex `^[a-zA-Z0-9_]{3,20}$`. Transactional uniqueness check. |
| 4 | `signUpWithPassword` | No | Yes (via wrapper) | No | **IP:** 5 req / 10 min (20 min block); **Email:** 5 req / 10 min (20 min block); **Username:** 5 req / 10 min (20 min block) | Create account with username+email+password. Password min 8 chars. Creates Auth user, user doc, username reservation. Sends verification OTP. Returns `customToken`. |
| 5 | `loginWithPassword` | No | Yes (via wrapper) | No | **IP:** 8 req / 10 min (20 min block); **Identifier:** 8 req / 10 min (20 min block) | Login with email/username + password. Constant-time comparison (dummy hash on miss). Returns `customToken`. |
| 6 | `requestPasswordReset` | No | Yes (via wrapper) | No | **IP:** 5 req / 10 min (20 min block); **Identifier:** 5 req / 10 min (20 min block); **Cooldown:** 60s between requests | Send forgot-password OTP. Silent success even if email not found. Only sends if user has a password set and email is verified. |
| 7 | `verifyPasswordResetOtp` | No | Yes (via wrapper) | No | **IP:** 10 req / 10 min (20 min block); **Identifier:** 10 req / 10 min (20 min block) | Verify forgot-password OTP. Returns a one-time `resetToken` (64-char hex). Token expires in 15 min. |
| 8 | `resetPasswordWithToken` | No | Yes (via wrapper) | No | **IP:** 5 req / 10 min (20 min block); **Identifier:** 5 req / 10 min (20 min block) | Finalize password reset using the reset token + new password (min 8 chars). Revokes all sessions. Sends password-changed email. |
| 9 | `changePassword` | **Yes** | Yes (via wrapper) | No | **IP:** 8 req / 10 min (20 min block); **UID:** 8 req / 10 min (20 min block) | Change password while logged in. Requires current password. New password min 8 chars. Revokes all sessions. Sends password-changed email. |

**Input/Output Schemas -- Auth Functions:**

<details>
<summary>requestEmailOtp</summary>

**Input:**
```typescript
{
  identifier: string;  // Required. Email or username.
  purpose: "login" | "add_email" | "change_email" | "reset_password" | "new_device" | "sensitive_action";
  email?: string;      // Optional. Used for add_email/change_email.
}
```
**Output:** `{ status: "ok" }`
</details>

<details>
<summary>verifyEmailOtp</summary>

**Input:**
```typescript
{
  identifier: string;  // Required.
  purpose: "login" | "add_email" | "change_email" | "reset_password" | "new_device" | "sensitive_action";
  otp: string;         // Required. 6-digit code.
  newEmail?: string;   // For change_email purpose.
  newPassword?: string;// For reset_password purpose (min 8 chars).
}
```
**Output (login):** `{ status: "ok", customToken: string }`
**Output (other):** `{ status: "ok" }`
</details>

<details>
<summary>claimUsername</summary>

**Input:** `{ username: string }` -- 3-20 chars, alphanumeric + underscore
**Output:** `{ status: "ok", username: string }`
</details>

<details>
<summary>signUpWithPassword</summary>

**Input:**
```typescript
{
  username: string;  // 3-20 chars, ^[a-zA-Z0-9_]{3,20}$
  email: string;     // Valid email
  password: string;  // Min 8 chars
}
```
**Output:** `{ status: "ok", customToken: string }`
</details>

<details>
<summary>loginWithPassword</summary>

**Input:** `{ identifier: string, password: string }`
**Output:** `{ status: "ok", customToken: string }`
</details>

<details>
<summary>requestPasswordReset</summary>

**Input:** `{ email: string }`
**Output:** `{ status: "ok", message: "If the email is registered, a verification code will be sent." }`
</details>

<details>
<summary>verifyPasswordResetOtp</summary>

**Input:** `{ email: string, otp: string }`
**Output:** `{ status: "ok", resetToken: string }`
</details>

<details>
<summary>resetPasswordWithToken</summary>

**Input:**
```typescript
{
  email: string;
  resetToken: string;   // or reset_token
  newPassword: string;   // or new_password (min 8 chars)
}
```
**Output:** `{ status: "ok" }`
</details>

<details>
<summary>changePassword</summary>

**Input:**
```typescript
{
  currentPassword: string;  // or current_password
  newPassword: string;      // or new_password (min 8 chars)
}
```
**Output:** `{ status: "ok" }`
</details>

---

### 1.2 Discovery & Matching

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 10 | `fetchDiscoveryCandidates` | **Yes** | Yes (via wrapper) | **Yes** | None (query-level: max 120 docs) | Fetch discovery candidates. Filters by gender preference, age range, distance, blocked users. Scores by verification, distance, shared interests. Returns max 50 candidates. |
| 11 | `swipeRight` | **Yes** | Yes (via wrapper) | **Yes** | **Daily:** 30 (free) / 300 (plus); **Hourly:** 10 (free) / 50 (plus) | Like a user. Profile quality required. Creates like record. If mutual, creates match + RTDB notifications. Logs to BigQuery. |
| 12 | `swipeLeft` | **Yes** | Yes (via wrapper) | **Yes** | None | Pass on a user. Profile quality required. Logs to BigQuery. |
| 13 | `sendPreMatchMessageRequest` | **Yes** | Yes (via wrapper) | **Yes** | Max 3 requests per sender per pair | Send a pre-match message request. Profile quality required. Max 3 unreplied messages per pair. |

**Input/Output Schemas -- Discovery Functions:**

<details>
<summary>fetchDiscoveryCandidates</summary>

**Input:** `{ limit?: number }` -- Default 30, clamped to 5-50.
**Output:**
```typescript
{
  candidates: Array<{
    id: string;
    userId: string;
    name?: string;
    bio?: string;
    photoUrls?: string[];
    interests?: string[];
    // ...all profile fields flattened
    username?: string;
    distanceKm?: number;
    score: number;
  }>;
  total: number;
}
```
</details>

<details>
<summary>swipeRight</summary>

**Input:** `{ targetUserId: string, attachedMessage?: string }`
**Output:** `{ matched: boolean, matchId?: string }`
</details>

<details>
<summary>swipeLeft</summary>

**Input:** `{ targetUserId: string }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>sendPreMatchMessageRequest</summary>

**Input:** `{ targetUserId: string, content: string }`
**Output:** `{ ok: true }`
</details>

---

### 1.3 Chat & Messaging

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 14 | `sendMessage` | **Yes** | Yes (via wrapper) | **Yes** | None | Send message in a match. Must be match participant. Content or mediaUrl required. Content max 5000 chars. Creates message doc and updates match metadata. |
| 15 | `editMessage` | **Yes** | Yes (via wrapper) | **Yes** | None | Edit own message. Sender-only ownership check. Updates content and marks as edited. |
| 16 | `unsendMessage` | **Yes** | Yes (via wrapper) | **Yes** | None | Soft-delete own message (sender-only). **Plus plan required.** Sets `isDeletedForSender=true`. |
| 17 | `markMessagesRead` | **Yes** | Yes (via wrapper) | No | None | Batch-mark all unread messages in a match as read. Must be match participant. |
| 18 | `setTyping` | **Yes** | Yes (via wrapper) | No | None | Update typing indicator for a match. |
| 19 | `setMediaSendingEnabled` | **Yes** | Yes (via wrapper) | No | None | Toggle media sending for a match conversation. |
| 20 | `addReaction` | **Yes** | Yes (via wrapper) | No | None | Add emoji reaction to a message. |
| 21 | `removeReaction` | **Yes** | Yes (via wrapper) | No | None | Remove own reaction from a message. |
| 22 | `unmatch` | **Yes** | Yes (via wrapper) | **Yes** | None | End a match. Sends FCM notification to other user. |

**Input/Output Schemas -- Chat Functions:**

<details>
<summary>sendMessage</summary>

**Input:**
```typescript
{
  matchId: string;
  toUserId: string;
  content?: string;    // Max 5000 chars (default requireString limit)
  type?: string;       // Default "text"
  mediaUrl?: string;
}
```
**Output:** `{ ok: true, messageId: string }`
</details>

<details>
<summary>editMessage</summary>

**Input:** `{ matchId: string, messageId: string, content: string }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>unsendMessage</summary>

**Input:** `{ matchId: string, messageId: string }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>markMessagesRead</summary>

**Input:** `{ matchId: string }`
**Output:** `{ ok: true, markedCount: number }`
</details>

<details>
<summary>setTyping</summary>

**Input:** `{ matchId: string, isTyping: boolean }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>setMediaSendingEnabled</summary>

**Input:** `{ matchId: string, enabled: boolean }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>addReaction</summary>

**Input:** `{ matchId: string, messageId: string, emoji: string }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>removeReaction</summary>

**Input:** `{ matchId: string, messageId: string }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>unmatch</summary>

**Input:** `{ matchId: string }`
**Output:** `{ ok: true }`
</details>

---

### 1.4 Chat Settings & Retention

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 23 | `updateChatSettings` | **Yes** | Yes (via wrapper) | No | None | Update global chat retention settings. Free users: 1h (default) or 24h (extended). Plus users: always 7 days. Syncs to RTDB. |
| 24 | `updateMatchChatSettings` | **Yes** | Yes (via wrapper) | No | None | Update per-match chat retention settings. Must be match participant. Syncs to RTDB. |

**Input/Output Schemas -- Chat Settings:**

<details>
<summary>updateChatSettings</summary>

**Input:** `{ extendedRetention: boolean }`
**Output:** `{ success: true, extendedRetention: boolean, retentionHours: number, message: string }`
</details>

<details>
<summary>updateMatchChatSettings</summary>

**Input:** `{ matchId: string, extendedRetention: boolean }`
**Output:** `{ success: true, matchId: string, extendedRetention: boolean, retentionHours: number, message: string }`
</details>

---

### 1.5 Safety & Moderation

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 25 | `reportUser` | **Yes** | Yes (via wrapper) | **Yes** | **UID:** 10 reports / 1 hr (2 hr block) | Report a user. Cannot report self. Creates report doc. Auto-flags if 3+ reports in 7 days. Creates automated flag if 5+ reports. |
| 26 | `blockUser` | **Yes** | Yes (via wrapper) | **Yes** | **UID:** 20 blocks / 1 hr (1 hr block) | Block a user. Cannot block self. Creates block doc with deterministic ID. |
| 27 | `unblockUser` | **Yes** | Yes (via wrapper) | No | **UID:** 30 unblocks / 1 hr (30 min block) | Unblock a user. Deletes block doc. |
| 28 | `appealSafetyAction` | **Yes** | Yes (via wrapper) | No | None | Submit an appeal against a safety action. Creates appeal doc and updates user's safety flags. |
| 29 | `moderateTextContent` | No | Yes (via wrapper) | No | None | Check text content against banned terms list. Returns moderation decision: `clean`/`held`. |
| 30 | `moderateImageContent` | No | Yes (via wrapper) | No | None | Placeholder image moderation. Currently always returns `clean`. |

**Input/Output Schemas -- Safety Functions:**

<details>
<summary>reportUser</summary>

**Input:**
```typescript
{
  reportedId: string;    // Required
  reason: string;        // Required
  matchId?: string;
  messageId?: string;
  source?: string;
  description?: string;
}
```
**Output:** `{ ok: true }`
</details>

<details>
<summary>blockUser</summary>

**Input:** `{ blockedId: string, blockerId?: string }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>unblockUser</summary>

**Input:** `{ blockedId: string, blockerId?: string }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>appealSafetyAction</summary>

**Input:** `{ reason: string, targetType?: string, targetId?: string }`
**Output:** `{ ok: true }`
</details>

<details>
<summary>moderateTextContent</summary>

**Input:** `{ content: string }`
**Output:** `{ status: "clean"|"held", action: "allow"|"hold", reason: string|null, severity: "low"|"high" }`
</details>

<details>
<summary>moderateImageContent</summary>

**Input:** `{ imageUrl: string }`
**Output:** `{ status: "clean", action: "allow", reason: null, severity: "low" }` (placeholder)
</details>

---

### 1.6 Subscription & Payments

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 31 | `createCheckoutSession` | **Yes** | Yes (via wrapper) | **Yes** | None | Create a Stripe Checkout session for Plus subscription. Creates/reuses Stripe customer. Returns checkout URL. |
| 32 | `syncSubscriptionStatus` | **Yes** | Yes (via wrapper) | No | None | Sync subscription status from Stripe to Firestore. Returns current plan, status, period end, cancel status. |

**Input/Output Schemas -- Subscription Functions:**

<details>
<summary>createCheckoutSession</summary>

**Input:** `{ priceId: string, successUrl: string, cancelUrl: string }`
**Output:** `{ url: string }`
</details>

<details>
<summary>syncSubscriptionStatus</summary>

**Input:** None
**Output:** `{ plan: "free"|"plus", status: string, currentPeriodEnd?: number, cancelAtPeriodEnd?: boolean }`
</details>

---

### 1.7 Calls (Agora)

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 33 | `generateAgoraToken` | **Yes** | Yes (via wrapper) | No | None | Generate Agora RTC token for a channel. Uses provided numeric UID. Expires in 1 hour. |
| 34 | `getAgoraToken` | **Yes** | Yes (via wrapper) | No | None | Generate Agora RTC token using auth UID hash. Supports video/audio flag. Expires in 1 hour. |

**Input/Output Schemas -- Agora Functions:**

<details>
<summary>generateAgoraToken</summary>

**Input:** `{ channelName: string, uid?: number, isVideoCall?: boolean }`
**Output:** `{ token: string, appId: string, channelName: string, uid: number, expireTime: number }`
</details>

<details>
<summary>getAgoraToken</summary>

**Input:** `{ channelName: string, isVideoCall?: boolean }`
**Output:** `{ token: string, uid: number, appId: string, isVideoCall: boolean }`
</details>

---

### 1.8 Profile

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 35 | `checkProfileCompleteness` | **Yes** | Yes (via wrapper) | No | None | Evaluate profile completeness. Returns score (0-1), breakdown per category, missing items, and whether minimum thresholds are met. |
| 36 | `setPresenceStatus` | **Yes** | Yes (via wrapper) | No | None | Update user online/offline status and lastSeenAt timestamp. |

**Input/Output Schemas -- Profile Functions:**

<details>
<summary>checkProfileCompleteness</summary>

**Input:** `{ minimum?: "swipe" | "messaging" }`
**Output:**
```typescript
{
  score: number;              // 0.0-1.0
  breakdown: Record<string, number>;  // photos, bio, interests, location, prompts
  missing: string[];
  requiredMissing: string[];
  meetsSwipeMinimum: boolean;
  meetsMessagingMinimum: boolean;
  meetsRequiredFields: boolean;
  meetsMinimum: boolean;
  minimum: string;
  threshold: number;
}
```
</details>

<details>
<summary>setPresenceStatus</summary>

**Input:** `{ isOnline: boolean }`
**Output:** `{ ok: true }`
</details>

---

### 1.9 Email & Notifications

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 37 | `notifyDatePlanContact` | **Yes** | Yes (via wrapper) | No | **UID+contact:** 3 / 1 hr (2 hr block) | Send date plan safety email to emergency contact. Validates email, truncates strings. Uses Resend API. |

**Input/Output Schemas:**

<details>
<summary>notifyDatePlanContact</summary>

**Input:**
```typescript
{
  contactName: string;     // Max 80 chars
  contactEmail: string;    // Valid email
  matchName: string;       // Max 80 chars
  dateTimeMs: number;      // Timestamp in ms
  timeZoneOffsetMinutes?: number;
  location: string;        // Max 200 chars
  notes?: string;          // Max 500 chars
}
```
**Output:** `{ success: true }`
</details>

---

### 1.10 Account Deletion & Media

| # | Export Name | Auth Required? | App Check? | Email Verified? | Rate Limit | Description |
|---|-------------|---------------|------------|-----------------|------------|-------------|
| 38 | `requestAccountDeletion` | **Yes** | **Yes** (explicit call) | No | None | Request account deletion with 14-day grace period. Marks account pending, creates tracking record. Does NOT use `callable<T>()` wrapper -- calls `verifyAppCheck()` directly. |
| 39 | `cancelAccountDeletion` | **Yes** | **Yes** (explicit call) | No | None | Cancel a pending account deletion within grace period. Clears deletion flags. Does NOT use `callable<T>()` wrapper -- calls `verifyAppCheck()` directly. |
| 40 | `getChatMediaSignedUrl` | **Yes** | Yes (via wrapper) | **Yes** | None | Get a time-limited signed URL for chat media. Verifies match participation. Validates file path prefix. URL expires in 1 hour. |

**Input/Output Schemas:**

<details>
<summary>requestAccountDeletion</summary>

**Input:** `{ reason?: string }` -- Max 500 chars.
**Output:**
```typescript
{
  success: true;
  scheduledAt: string;       // ISO date
  gracePeriodDays: 14;
  message: string;
}
```
</details>

<details>
<summary>cancelAccountDeletion</summary>

**Input:** None
**Output:** `{ success: true, message: string }`
</details>

<details>
<summary>getChatMediaSignedUrl</summary>

**Input:** `{ matchId: string, filePath: string }` -- filePath max 500 chars, must start with `chat_media/{matchId}/` or `chats/{matchId}/`
**Output:** `{ url: string }`
</details>

---

## 2. HTTP Endpoints (onRequest -- Express REST API)

Exported as `api` via `functions.https.onRequest(app)`. All endpoints are prefixed with the function URL base path.

**Global middleware:**
- CORS: Whitelist-based via `corsOriginValidator` (env `CORS_ALLOWED_ORIGINS`)
- Body parser: `express.json()`
- Auth middleware (`authMiddleware`): Validates `Authorization: Bearer <idToken>` header via `admin.auth().verifyIdToken()`

### 2.1 Auth Endpoints

| # | Method | Path | Auth? | Rate Limit | Description |
|---|--------|------|-------|------------|-------------|
| 1 | POST | `/v1/auth/otp/send` | No | None (server-side) | Send phone OTP. Generates 6-digit code, stores bcrypt hash in `phone_verifications`. **Note: Currently logs OTP to console (dev mode).** |
| 2 | POST | `/v1/auth/otp/verify` | No | None (server-side) | Verify phone OTP. Creates user if new. Returns `customToken` + user data + tokens. |
| 3 | POST | `/v1/auth/token/refresh` | No | None | Refresh auth token. Verifies existing token, creates new custom token. |
| 4 | POST | `/v1/auth/logout` | **Yes** | None | Logout. Revokes all refresh tokens. |
| 5 | POST | `/v1/auth/password/change` | **Yes** | **IP:** 8 / 10 min (20 min block); **UID:** 8 / 10 min (20 min block) | Change password (REST version). Same logic as callable `changePassword`. |

**Input/Output Schemas -- Auth REST:**

<details>
<summary>POST /v1/auth/otp/send</summary>

**Input:** `{ phone_number: string }`
**Output:** `{ success: true, verification_id: string, message: "OTP sent successfully" }`
</details>

<details>
<summary>POST /v1/auth/otp/verify</summary>

**Input:** `{ phone_number: string, otp: string, verification_id?: string }`
**Output:**
```json
{
  "success": true,
  "message": "Phone verified successfully",
  "user": {
    "id": "string",
    "phone_number": "string",
    "email": "string|null",
    "username": "string|null",
    "is_email_verified": false,
    "is_phone_verified": true,
    "is_id_verified": false,
    "is_premium": false
  },
  "tokens": {
    "access_token": "string",
    "refresh_token": "string",
    "expires_in": 3600
  }
}
```
</details>

<details>
<summary>POST /v1/auth/token/refresh</summary>

**Input:** `{ refresh_token: string }`
**Output:** `{ access_token: string, refresh_token: string, expires_in: 3600 }`
</details>

<details>
<summary>POST /v1/auth/password/change</summary>

**Input:** `{ current_password: string, new_password: string }` (also accepts camelCase variants)
**Output:** `{ success: true, message: "Password changed successfully." }`
</details>

### 2.2 Profile Endpoints

| # | Method | Path | Auth? | Rate Limit | Description |
|---|--------|------|-------|------------|-------------|
| 6 | GET | `/v1/profile/me` | **Yes** | None | Get current user's full profile (formatted for API clients). |
| 7 | PATCH | `/v1/profile/me` | **Yes** | None | Update profile fields (display_name, bio, birth_date, gender, job_title, company, education, city, country, interests). |
| 8 | POST | `/v1/profile/photos` | **Yes** | None | Upload a profile photo (multipart/form-data, field: `photo`). Stored in Cloud Storage. Optional `is_primary` flag. |
| 9 | DELETE | `/v1/profile/photos/:photoId` | **Yes** | None | Delete a profile photo by index (photoId format: `photo_INDEX`). |
| 10 | PATCH | `/v1/profile/preferences` | **Yes** | None | Update user preferences (arbitrary JSON body). |
| 11 | GET | `/v1/profile/:userId` | **Yes** | None | Get another user's public profile. |

### 2.3 Discovery Endpoints

| # | Method | Path | Auth? | Rate Limit | Description |
|---|--------|------|-------|------------|-------------|
| 12 | GET | `/v1/discovery/deck` | **Yes** | None | Get discovery deck (up to 20 profiles). Filters by gender preference, excludes already-swiped users. |
| 13 | POST | `/v1/discovery/swipe` | **Yes** | None | Record a swipe (like/super_like/pass). Checks for mutual match. |
| 14 | POST | `/v1/discovery/boost` | **Yes** | None | Activate a 30-minute profile boost. |

**Input/Output Schemas -- Discovery REST:**

<details>
<summary>POST /v1/discovery/swipe</summary>

**Input:** `{ target_user_id: string, action: "like"|"super_like"|"pass", message?: string }`
**Output:** `{ success: true, is_match: boolean, match_id: string|null }`
</details>

### 2.4 Match Endpoints

| # | Method | Path | Auth? | Rate Limit | Description |
|---|--------|------|-------|------------|-------------|
| 15 | GET | `/v1/matches` | **Yes** | None | Get paginated matches. Query params: `offset` (default 0), `limit` (default 20). |
| 16 | POST | `/v1/matches/:matchId/unmatch` | **Yes** | None | Delete a match. Verifies user is participant. |

### 2.5 Chat Endpoints

| # | Method | Path | Auth? | Rate Limit | Description |
|---|--------|------|-------|------------|-------------|
| 17 | GET | `/v1/chat/conversations` | **Yes** | None | Get conversations (max 50) with participant info and last message. |
| 18 | GET | `/v1/chat/:conversationId/messages` | **Yes** | None | Get paginated messages. Query params: `limit` (default 50), `before` (cursor). |
| 19 | POST | `/v1/chat/:conversationId/send` | **Yes** | None | Send a message in a conversation. |
| 20 | POST | `/v1/chat/:conversationId/media` | **Yes** | None | Upload chat media (multipart/form-data, field: `media`). Returns public URL. |
| 21 | POST | `/v1/chat/:conversationId/read` | **Yes** | None | Mark conversation as read. |
| 22 | PUT | `/v1/chat/settings` | **Yes** | None | Update chat retention settings (`extended_retention: boolean`). |
| 23 | GET | `/v1/chat/settings` | **Yes** | None | Get chat retention settings (extended_retention, is_premium, retention_hours, retention_description). |

**Input/Output Schemas -- Chat REST:**

<details>
<summary>POST /v1/chat/:conversationId/send</summary>

**Input:** `{ type?: string, content?: string, media_url?: string }`
**Output:** `{ id: string, success: true }`
</details>

### 2.6 Subscription Endpoints

| # | Method | Path | Auth? | Rate Limit | Description |
|---|--------|------|-------|------------|-------------|
| 24 | GET | `/v1/subscription/plans` | No | None | Get available subscription plans. Returns defaults if none in DB (Free + CrushHour+). |
| 25 | POST | `/v1/subscription/checkout` | **Yes** | None | Create Stripe Checkout session for subscription. |
| 26 | GET | `/v1/subscription/current` | **Yes** | None | Get current subscription status (plan, expires_at, is_active). |

### 2.7 Safety Endpoints

| # | Method | Path | Auth? | Rate Limit | Description |
|---|--------|------|-------|------------|-------------|
| 27 | POST | `/v1/users/block` | **Yes** | **UID:** 20 blocks / 1 hr (1 hr block) | Block a user. |
| 28 | POST | `/v1/users/unblock` | **Yes** | **UID:** 30 unblocks / 1 hr (30 min block) | Unblock a user. |
| 29 | POST | `/v1/users/report` | **Yes** | **UID:** 10 reports / 1 hr (2 hr block) | Report a user. |

**Input/Output Schemas -- Safety REST:**

<details>
<summary>POST /v1/users/block</summary>

**Input:** `{ blocked_id: string }`
**Output:** `{ success: true }`
</details>

<details>
<summary>POST /v1/users/report</summary>

**Input:** `{ reported_id: string, reason: string, description?: string, match_id?: string, message_id?: string }`
**Output:** `{ success: true }`
</details>

---

## 3. Standalone HTTP Endpoints (onRequest)

| # | Export Name | Method | Auth? | Rate Limit | Description |
|---|------------|--------|-------|------------|-------------|
| 1 | `stripeWebhook` | POST | Stripe signature verification | None | Handles Stripe webhook events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`. Updates user plan in Firestore + RTDB. CORS headers set manually. |

**Stripe Webhook Events Handled:**

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Set user plan to `plus` with Stripe IDs |
| `customer.subscription.updated` | Set plan based on status (active/trialing/past_due = plus, else free) |
| `customer.subscription.deleted` | Set plan based on status |

---

## 4. Firestore Triggers

| # | Export Name | Trigger Type | Collection Path | Description |
|---|------------|-------------|-----------------|-------------|
| 1 | `onMessageCreated` | `onCreate` | `matches/{matchId}/messages/{messageId}` | Content moderation on new messages. Runs banned-term check on text messages, flags non-text for scan. If held, flags sender for review. Otherwise sends FCM push notification to recipient (respects notification prefs). |
| 2 | `onMatchCreated` | `onCreate` | `matches/{matchId}` | Auto-migrates pending message requests to match as first message. Sends FCM "new match" push to both users (respects notification prefs). |
| 3 | `onSubscriptionUpdated` | `onUpdate` | `users/{userId}` | Detects plan changes and sends FCM notification (upgrade/downgrade). Respects "subscriptions" notification preference. |
| 4 | `onMessageRead` | `onUpdate` | `matches/{matchId}/messages/{messageId}` | When a message transitions to `isRead=true`, schedules message deletion for both sender and reader based on their retention settings (1h/24h/7d). Writes to RTDB `message_deletion_queue`. |
| 5 | `onPlanChangeUpdateChatSettings` | `onUpdate` | `users/{userId}` | When user's plan changes, syncs chat settings to RTDB (retention hours, premium status). |

---

## 5. Scheduled Functions (Pub/Sub)

| # | Export Name | Schedule | Description |
|---|------------|----------|-------------|
| 1 | `processMessageDeletionQueue` | Every 15 minutes | Processes RTDB `message_deletion_queue`. Removes expired messages from users' `visibleTo` arrays. Deletes messages entirely when no users can see them. Cleans up queue entries. |
| 2 | `cleanupExpiredMessageRequests` | Every 1 hour | Deletes expired message requests (`expiresAt < now`). Processes up to 500 per run. |
| 3 | `processScheduledAccountDeletions` | Every 6 hours | Processes pending account deletions (14-day grace expired) and deactivated account auto-deletions (6-month). Cascade deletes: matches, messages, blocks, reports, likes, message_requests, auth_credentials, Storage files, RTDB data, user doc, Auth user. Max 50 per category per run. |

---

## 6. Constants and Rate Limit Reference

### 6.1 Profile Quality Thresholds

| Constant | Value | Usage |
|----------|-------|-------|
| `PROFILE_MIN_PHOTOS` | 1 | Minimum photos to swipe/send messages |
| `PROFILE_MIN_PROMPTS` | 0 | Prompts are optional |
| `PROFILE_MIN_BIO_LENGTH` | 10 | Minimum bio characters |
| `PROFILE_MIN_INTERESTS` | 3 | Minimum interests selected |
| `SWIPE_MIN_COMPLETENESS` | 0.8 | 80% completeness for swipe (used in `evaluateProfileCompleteness`) |
| `MESSAGING_MIN_COMPLETENESS` | 0.8 | 80% completeness for messaging (used in `evaluateProfileCompleteness`) |
| `DISCOVERY_PAGE_SIZE` | 120 | Max Firestore query results for discovery |

### 6.2 Like Limits

| Plan | Daily Limit | Hourly Limit |
|------|-------------|--------------|
| Free | 30 | 10 |
| Plus | 300 | 50 |

### 6.3 Auth Rate Limits

| Action | Limit | Window | Block Duration |
|--------|-------|--------|----------------|
| OTP Request (per IP) | 5 | 10 min | 20 min |
| OTP Request (per identifier) | 5 | 10 min | 20 min |
| OTP Verify (per IP) | 10 | 10 min | 20 min |
| OTP Verify (per identifier) | 10 | 10 min | 20 min |
| OTP Verify (per code) | 5 failed attempts | -- | 15 min lock |
| OTP Resend Cooldown | 1 per 60s | -- | -- |
| Signup (per IP) | 5 | 10 min | 20 min |
| Signup (per email) | 5 | 10 min | 20 min |
| Signup (per username) | 5 | 10 min | 20 min |
| Login (per IP) | 8 | 10 min | 20 min |
| Login (per identifier) | 8 | 10 min | 20 min |
| Change Password (per IP) | 8 | 10 min | 20 min |
| Change Password (per UID) | 8 | 10 min | 20 min |
| Password Reset (per IP) | 5 | 10 min | 20 min |
| Password Reset (per identifier) | 5 | 10 min | 20 min |
| Reset Finalize (per IP) | 5 | 10 min | 20 min |
| Reset Finalize (per identifier) | 5 | 10 min | 20 min |

### 6.4 Safety Rate Limits

| Action | Limit | Window | Block Duration |
|--------|-------|--------|----------------|
| Report (per UID) | 10 | 1 hr | 2 hr |
| Block (per UID) | 20 | 1 hr | 1 hr |
| Unblock (per UID) | 30 | 1 hr | 30 min |
| Date Plan Email (per UID+contact) | 3 | 1 hr | 2 hr |

### 6.5 Security Constants

| Constant | Value |
|----------|-------|
| `PASSWORD_MIN_LENGTH` | 8 |
| `PASSWORD_SALT_ROUNDS` | 12 |
| `OTP_DIGITS` | 6 |
| `OTP_TTL_MS` | 10 min |
| `RESET_TOKEN_TTL_MS` | 15 min |
| `DELETION_GRACE_PERIOD_DAYS` | 14 |

### 6.6 Message Retention

| Plan | Retention After Read |
|------|---------------------|
| Free (default) | 1 hour |
| Free (extended) | 24 hours |
| Plus | 7 days (168 hours) |

### 6.7 Input Validation Rules

| Field | Rule |
|-------|------|
| `requireString(value, field)` | Trimmed, non-empty, max 5000 chars (default) |
| `requireString(value, field, N)` | Trimmed, non-empty, max N chars |
| Username | `^[a-zA-Z0-9_]{3,20}$` |
| Email | `^[^@\s]+@[^@\s]+\.[^@\s]+$` |
| Password | Min 8 characters |
| OTP | Exactly 6 digits |
| Discovery limit | Clamped to 5-50 |

---

## Summary Statistics

| Category | Count |
|----------|-------|
| **Callable Functions (onCall)** | 40 |
| **HTTP Endpoints (Express REST)** | 29 |
| **Standalone HTTP (onRequest)** | 1 (stripeWebhook) |
| **Firestore Triggers** | 5 |
| **Scheduled Functions** | 3 |
| **Total Exported Functions** | 49 (+ `api` Express app + `__test__helpers`) |
