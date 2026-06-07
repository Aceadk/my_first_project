# Firestore Rules Emulator Coverage

Security-rules tests that run `firestore.rules` against the Firestore emulator
using `@firebase/rules-unit-testing`. Part of Phase 3 (Reconcile Firestore Rules
And Data Models), Step 4.

## Run

```bash
cd firestore-tests
npm install
npm test          # starts the firestore emulator via firebase emulators:exec
```

Requires: Node 18+, Java (for the emulator), and the Firebase CLI
(`firebase-tools`) on PATH. The test loads `../firestore.rules` directly, so it
always tests the real shipped rules.

## What it covers

For each path: allowed reads/writes for authenticated **owners/participants**,
**denied** access for unauthenticated and **unrelated** users, and that
**protected fields cannot be modified** by clients.

## Collection / document path inventory (web + mobile)

| Path | Client access (per rules) |
|------|---------------------------|
| `users/{uid}` | Owner read/update own; signed-in read others if visible + not blocked. Create own with **nested `profile.*`** only (legacy flat keys rejected). Protected fields (`plan`, `isIdVerified`, `stripe*`, `isEmailVerified`, `emailVerified`, `createdAt`, `kycVerificationStatus`) are backend-only. Array bounds: `profile.photoUrls` ≤ 9, `profile.interests` ≤ 20. No client delete. |
| `users/{uid}/fcmTokens/{token}` | Owner read/write/delete own push tokens (web + mobile register here). No other client may read/enumerate. Backend reads via admin. |
| `usernames/{username}` | Server-only (read/write denied). |
| `auth_email_otps/{otpId}` | Server-only. |
| `auth_rate_limits/{key}` | Server-only. |
| `auth_audit_logs/{logId}` | Server-only. |
| `matches/{matchId}` | Participant read when `status == 'active'`. Create/update/delete backend-only. |
| `matches/{matchId}/messages/{messageId}` | Participant read when active + message `visibleTo` includes them. Create requires: sender == auth, both participants ID-verified, sender account-verified, valid type, content ≤ 5000, video = premium, `visibleTo` includes both. Recipient may set only `isRead`/`readAt`. No client delete. |
| `message_requests/{requestId}` | Participants read (no block). Sender creates (not self, no block). Participants delete. No update. |
| `likes/{likeId}` | Signed-in read. Creator creates (not self, `toUserId` required). Immutable (no update/delete). |
| `reports/{reportId}` | Reporter creates (not self, `reason` 1–1000 chars). No client read/update/delete. |
| `blocks/{blockId}` | Blocker creates (not self). No client read/update/delete. |
| `stories/{storyId}` | Signed-in read. Premium **or** female user creates own. Owner deletes own. No update. |
| `calls/{callId}` | Participant read. Premium caller creates. Participant updates (answer/end). No delete. |
| `presence/{uid}` | Owner read/write own. Others read only if premium. |
| Storage paths | Covered by `storage.rules` (not in this Firestore suite). |

### Web-only paths the rules currently reject (P0.3 follow-up)

The re-audit (P0.3) flags live web paths that conflict with these canonical
rules and must be migrated to backend commands or removed. They are intentionally
NOT granted here; reconciliation tests should be added as each is migrated:

- `conversations/*`, `typing_indicators/*` (legacy web chat — superseded by
  `matches/{matchId}/messages`)
- `users/{uid}/stories` (canonical is top-level `stories/{storyId}`)
- `user_streaks/*`, `promoCodes/*`, `promoCodeRedemptions/*`
- ~~`users/{uid}/blocked`~~ → migrated to top-level `blocks` + `getBlockedUsers` callable (done)
- ~~`users/{uid}/fcmTokens`~~ → owner-scoped nested rule added (done)
- ~~Web report shape~~ → routed through the `reportUser` callable (done)
- ~~Legacy flat `users/{uid}` profile writes~~ → builders write `profile.*` only (done)
- `users/{uid}/stories` (canonical is top-level `stories/{storyId}`) — pending
- `user_streaks/*`, `promoCodes/*`, `promoCodeRedemptions/*` — pending (server-owned)

## CI

Runs in `.github/workflows/ci.yml` (`firestore_rules` job) on push/PR.
