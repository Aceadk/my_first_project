# Web Chat/Match Migration Plan - 2026-06-05

**Purpose:** Decide and document the canonical chat/match model for web, then plan the migration from direct Firestore writes to backend-managed mutation calls.

**Status:** Decision required. This document presents three options; **Option B (Recommended)** is proposed.

---

## Current State: Data Model Mismatch

### Mobile/Backend Model (Source of Truth)
**Matches:**
```
matches/{matchId}
├── matchId: string (sorted uid1_uid2)
├── userIds: [uid1, uid2]
├── status: 'active' | 'archived' | 'cancelled'
├── createdAt: Timestamp
├── updatedAt: Timestamp
├── participants: {
│   [uid]: { swipedAt, lastMessageAt, unreadCount, lastReadTimestamp }
│ }
└── settings: { extendedRetention: boolean, ... }

matches/{matchId}/messages (subcollection)
├── messageId: string (auto-generated)
├── senderId: string
├── type: 'text' | 'image' | 'video' | 'audio' | 'gift' | 'voice'
├── content: string
├── mediaUrl?: string
├── visibleTo: [uid1, uid2]
├── isRead: boolean
├── readAt?: Timestamp
├── reactions?: { emoji: [uid, ...] }
├── createdAt: Timestamp
├── editedAt?: Timestamp
└── deletedAt?: Timestamp (soft delete)
```

**Firestore Rules Expectations:**
- Only match participants can read/update own messages
- Only message sender can edit/unsend own message
- **Direct client writes to messages are restricted**; mutations via backend callables (`sendMessage`, `unsendMessage`, `editMessage`, `markMessagesRead`)

**Backend Services (Callables & REST):**
- `sendMessage(matchId, type, content, mediaUrl)`
- `unsendMessage(matchId, messageId)`
- `editMessage(matchId, messageId, content)`
- `markMessagesRead(matchId, upToTimestamp)`
- `setTyping(matchId, isTyping)`

---

### Web Current Model (Direct Firestore)
**Matches:**
```
matches/{matchId}
├── userId: string (unidirectional)
├── otherUserId: string
├── status: 'mutual' | 'pending' | ...
├── createdAt: Timestamp
├── updatedAt: Timestamp
├── unreadCount: number
├── preMatchMessageRequestsCount: number
└── [other denormalized fields]

swipes/{swiperId_swipedUserId}
├── swiperId: string
├── swipedUserId: string
├── action: 'like' | 'pass' | 'superlike'
└── timestamp: Timestamp
```

**Conversations & Messages:**
```
conversations/{conversationId}
├── matchId: string
├── participants: [uid1, uid2]
├── unreadCount: number
├── createdAt: Timestamp
├── updatedAt: Timestamp
└── isBlocked: boolean

conversations/{conversationId}/messages (subcollection)
├── id: string (auto-generated)
├── senderId: string
├── type: 'text' | 'image' | 'video' | ...
├── content: string
├── status: 'pending' | 'sent' | 'read'
├── timestamp: Timestamp
└── reactions?: { emoji: [uid, ...] }

typing_indicators/{typingId}
└── [presence tracking]
```

**Direct Firestore Client Writes:**
- Web directly writes to `conversations/` and `messages/` collections
- Web directly updates `matches/{matchId}` for unread count, status
- No backend validation of chat state

---

## Schema Comparison Matrix

| Aspect | Mobile/Backend | Web Current | Mismatch Severity |
|--------|----------------|-------------|-------------------|
| Match ID format | sorted uid1_uid2 | unidirectional uid_otherid | High |
| Match participants | userIds array | userId + otherUserId | High |
| Match status values | 'active', 'archived', 'cancelled' | 'mutual', 'pending', ... | Medium |
| Messages location | matches/{matchId}/messages | conversations/{convoId}/messages | High |
| Typing indicator | callable + match doc | top-level typing_indicators | High |
| Message sender visibility | visibleTo array | implicit participant | Medium |
| Message read state | isRead boolean + readAt | status: 'read' | Low |
| Message edit/delete | editedAt, deletedAt | not supported | Medium |

**Risk:** Web rules don't restrict direct writes; if deployed to prod, firestore.rules will reject web mutations with permission denied.

---

## Migration Options

### Option A: Keep Web's `conversations/` Model (Not Recommended)
**Approach:** Migrate backend to support dual models — keep `conversations/` for web, `matches/{matchId}/messages` for mobile.

**Pros:**
- Minimal web code changes
- Existing web queries continue working
- Parallel support reduces immediate migration burden

**Cons:**
- Backend complexity doubles (two message schemas, two rule sets)
- Rules become harder to maintain (conditional logic for both models)
- Replication/sync complexity between models
- Testing burden multiplies
- Future features require dual implementation

**Verdict:** ❌ **Rejected** — unacceptable backend complexity.

---

### Option B: Migrate Web to Backend Match/Message Model (Recommended)
**Approach:** Web adopts the same `matches/{matchId}` and `matches/{matchId}/messages` structure as mobile; all mutations go through backend callables/REST.

**Pros:**
- Single canonical schema; rules are simpler and more maintainable
- No backend dual-schema complexity
- Web mutations automatically validated by rules
- Easier to add new features (one implementation path)
- Aligns teams on contract
- Enables shared E2E tests (web + mobile against same backend)

**Cons:**
- Requires significant web data layer refactor (~400 lines of service code)
- Requires data migration script (for existing conversations in staging/prod)
- Testing must cover new callable usage patterns

**Migration Effort:** Medium (estimated 2-3 days of focused work)

**Verdict:** ✅ **Recommended** — Best long-term maintainability.

---

### Option C: New Shared REST API Layer (Partially Hybrid)
**Approach:** Create a new REST endpoint set (`/v1/chat/messages`, `/v1/matches`) that normalizes both web and mobile inputs; backend translates to canonical schema.

**Pros:**
- Clear contract boundary (REST vs. SDK)
- Easier for web to adopt (REST is familiar)
- Can deprecate callables later if desired

**Cons:**
- Still requires web code refactor (different API calls, same effort)
- Additional REST endpoint maintenance
- Adds latency for web (one more API layer)

**Verdict:** ⚠️ **Defer** — Option B is simpler; REST can be added in Phase 2 if web team prefers.

---

## Recommended Migration Plan: Option B

### Phase 0.5 — Preparation (Week 1)

#### Task 1: Data Audit & Backward Compatibility Analysis
```
What existing conversations/matches exist in production?
- Count `conversations/` docs by status, age
- Count `matches/` docs by status
- Identify pinned/important conversations that must preserve metadata

What denormalized fields in web's matches/ are not in backend model?
- Example: preMatchMessageRequestsCount, pinnedForUser, otherUserName, otherUserPhotoUrl
- Decision: Keep in participant metadata or read from user doc?

Do any messages have reactions, edits, deletes that can't migrate?
- Validate message statuses against backend expectations
```

#### Task 2: Test Plan
```
Write Firestore emulator tests for:
1. Web queries against canonical schema
2. Callable request/response validation
3. Message visibility rules (visibleTo)
4. Read state consistency (multiple devices)
5. Typing indicator subscriptions

Write contract tests:
1. validateSendMessageRequest(matchId, content) → matches backend signature
2. validateMessageDTO(dto) → matches mobile DTO expectations
```

#### Task 3: Feature Parity Check
```
Web features that depend on conversations/ directly:
- Unread message count (move to match doc participants.*.unreadCount)
- Typing indicators (move to callable + real-time listener)
- Block/report from chat (already callable; no migration needed)
- Message reactions (backend supports; web adds if needed)
- Message edit/delete (backend supports; web adds if needed)
```

---

### Phase 1.0 — Web Service Layer Refactor (Week 2)

#### Step 1: Create New Message Service Using Callables
**File:** `packages/core/src/services/message_v2.ts`

```typescript
import { callable } from '../api/functions'; // Use backend callables

class MessageServiceV2 {
  // Use backend callables instead of direct Firestore
  
  async sendMessage(
    matchId: string,
    type: MessageType,
    content: string,
    mediaUrl?: string
  ): Promise<Message> {
    const result = await callable<SendMessageRequest>('sendMessage')({
      matchId,
      type,
      content,
      mediaUrl,
    });
    return result.message; // Backend returns Message DTO
  }

  async unsendMessage(matchId: string, messageId: string): Promise<void> {
    await callable<UnsendRequest>('unsendMessage')({
      matchId,
      messageId,
    });
  }

  async editMessage(matchId: string, messageId: string, content: string): Promise<Message> {
    const result = await callable<EditMessageRequest>('editMessage')({
      matchId,
      messageId,
      content,
    });
    return result.message;
  }

  async markMessagesRead(matchId: string, upToTimestamp: number): Promise<void> {
    await callable<MarkMessagesReadRequest>('markMessagesRead')({
      matchId,
      upToTimestamp,
    });
  }

  subscribeToMessages(matchId: string, callback: (messages: Message[]) => void): Unsubscribe {
    const db = getFirebaseDb();
    const q = query(
      collection(db, 'matches', matchId, 'messages'),
      orderBy('createdAt', 'desc'),
      limit(MESSAGES_PER_PAGE)
    );
    return onSnapshot(q, (snapshot) => {
      const messages = snapshot.docs.map(doc => this.mapDocToMessage(doc.id, doc.data()));
      callback(messages);
    });
  }

  subscribeToTyping(matchId: string, callback: (typingUserIds: string[]) => void): Unsubscribe {
    const db = getFirebaseDb();
    // Subscribe to match doc's presence/typing field
    const matchRef = doc(db, 'matches', matchId);
    return onSnapshot(matchRef, (snapshot) => {
      const data = snapshot.data();
      const typing = data?.typing || {};
      callback(Object.keys(typing));
    });
  }

  async setTyping(matchId: string, isTyping: boolean): Promise<void> {
    await callable<{ matchId: string; isTyping: boolean }>('setTyping')({
      matchId,
      isTyping,
    });
  }
}
```

#### Step 2: Create New Match Service Using Backend
**File:** `packages/core/src/services/match_v2.ts`

```typescript
class MatchServiceV2 {
  async swipeRight(candidateId: string, message?: string): Promise<Match | null> {
    const result = await callable<SwipeRequest>('swipeRight')({
      candidateId,
      message,
    });
    return result.match || null; // null if no mutual match yet
  }

  async swipeLeft(candidateId: string): Promise<void> {
    await callable<SwipeRequest>('swipeLeft')({
      candidateId,
    });
  }

  async unmatch(matchId: string): Promise<void> {
    await callable<{ matchId: string }>('unmatch')({
      matchId,
    });
  }

  subscribeToMatches(callback: (matches: Match[]) => void): Unsubscribe {
    const db = getFirebaseDb();
    const auth = getFirebaseAuth();
    const userId = auth.currentUser?.uid;
    if (!userId) throw new Error('User not authenticated');

    const q = query(
      collection(db, 'matches'),
      where('userIds', 'array-contains', userId),
      where('status', '==', 'active'),
      orderBy('updatedAt', 'desc')
    );

    return onSnapshot(q, (snapshot) => {
      const matches = snapshot.docs.map(doc => this.mapDocToMatch(doc.id, doc.data()));
      callback(matches);
    });
  }

  async getMatch(matchId: string): Promise<Match | null> {
    const db = getFirebaseDb();
    const matchDoc = await getDoc(doc(db, 'matches', matchId));
    if (!matchDoc.exists()) return null;
    return this.mapDocToMatch(matchDoc.id, matchDoc.data());
  }

  private mapDocToMatch(id: string, data: Record<string, unknown>): Match {
    // Convert from Firestore doc to Match DTO
    // Handle both userIds array and nested participants
    const userIds = data.userIds as string[] || [];
    const userId = // get from auth
    const otherUserId = userIds.find(id => id !== userId);

    return {
      id,
      userId,
      otherUserId: otherUserId || '',
      status: data.status as MatchStatus,
      createdAt: (data.createdAt as Timestamp).toDate().toISOString(),
      updatedAt: (data.updatedAt as Timestamp).toDate().toISOString(),
      unreadCount: data.participants?.[userId]?.unreadCount || 0,
      // Map denormalized fields from participants
    };
  }
}
```

---

### Phase 1.5 — Data Migration (Week 2-3)

#### Migration Script
**File:** `packages/scripts/migrate_web_conversations.ts`

```typescript
import { getFirestore, collection, getDocs, writeBatch } from 'firebase/firestore';

async function migrateWebConversations() {
  const db = getFirestore();
  
  // 1. Read all conversations/
  const conversationDocs = await getDocs(collection(db, 'conversations'));
  
  for (const convoDoc of conversationDocs.docs) {
    const convoData = convoDoc.data();
    const matchId = convoData.matchId;
    const participants = convoData.participants as string[];
    
    // 2. Read all messages in conversations/{convoId}/messages
    const messageDocs = await getDocs(
      collection(db, 'conversations', convoDoc.id, 'messages')
    );
    
    // 3. Migrate messages to matches/{matchId}/messages
    const batch = writeBatch(db);
    
    for (const msgDoc of messageDocs.docs) {
      const msgData = msgDoc.data();
      // Create new message doc in matches/{matchId}/messages
      const newMsgRef = doc(
        db,
        'matches',
        matchId,
        'messages',
        msgDoc.id // Preserve messageId
      );
      batch.set(newMsgRef, {
        senderId: msgData.senderId,
        type: msgData.type,
        content: msgData.content,
        mediaUrl: msgData.mediaUrl,
        visibleTo: participants, // Both participants see all messages
        isRead: msgData.status === 'read',
        readAt: msgData.status === 'read' ? new Date() : null,
        createdAt: msgData.timestamp,
        // reactions: msgData.reactions, // if present
      });
    }
    
    // 4. Archive old conversation (don't delete for audit trail)
    const convoRef = doc(db, 'conversations', convoDoc.id);
    batch.update(convoRef, { archived: true, migratedAt: new Date() });
    
    await batch.commit();
  }
  
  console.log(`Migrated ${conversationDocs.size} conversations`);
}
```

**Execution:** ✅ **Implemented** as
`crush-web/apps/web/scripts/migrate-conversations-to-matches.mjs`
(commit on `codex/auth-storage-cleanup`). It is a self-contained
`firebase-admin` ESM script — dry-run by default, idempotent, and
non-destructive (legacy conversations are marked `archived`/`migratedToMatchId`,
never deleted). It lives under `apps/web/` so `firebase-admin` resolves via the
pnpm workspace symlink.

```bash
# 0. Auth: point at a service account with Firestore access.
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/staging-sa.json
#   (or)  export FIREBASE_SERVICE_ACCOUNT="$(cat staging-sa.json)"

cd crush-web/apps/web

# 1. DRY RUN against staging — reports what WOULD change, writes nothing.
pnpm migrate:conversations --project crush-265f7-staging
#   optionally: --limit 5   (process only the first 5 conversations)

# 2. Review the summary: conversations processed, matches created/reused,
#    messages migrated, errors. Confirm counts look right.

# 3. EXECUTE against staging.
pnpm migrate:conversations:execute --project crush-265f7-staging

# 4. Verify in Firebase Console (staging):
#    - conversations/* have archived=true + migratedToMatchId
#    - matches/{matchId}/messages contain the migrated docs
#      (fromUserId/toUserId/sentAt/visibleTo populated)
#    - message counts match the source

# 5. After verification window, repeat for production (with approval):
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/prod-sa.json
pnpm migrate:conversations --project crush-265f7            # dry run
pnpm migrate:conversations:execute --project crush-265f7    # execute
```

**Field mapping applied by the script** (verified canonical schema):

| Legacy (conversations) | Canonical (matches/{id}/messages) |
|------------------------|-----------------------------------|
| `senderId` | `fromUserId` |
| *(derived: other participant)* | `toUserId` |
| `timestamp` | `sentAt` |
| `status === 'read'` | `isRead: true` |
| `metadata.{image,video,audio,gif}Url` | `mediaUrl` |
| `reactions[]` (array) | `reactions: { [uid]: emoji }` |
| `isDeleted` | `isDeletedForSender` |
| *(participants)* | `visibleTo: [uidA, uidB]` |

Idempotency: a target message that already exists (same source doc id) is
skipped; an existing canonical match for the pair is reused rather than
duplicated. Re-running is safe.

---

### Phase 2.0 — Component/Page Migration (Week 3)

#### Update Chat Component
**File:** `packages/app/src/features/chat/ChatPage.tsx`

```typescript
import { MessageServiceV2 } from '@core/services/message_v2';
import { useRealtime } from '@core/hooks/useRealtime';

export const ChatPage = ({ matchId }: { matchId: string }) => {
  const messageService = new MessageServiceV2();
  const [messages, setMessages] = useState<Message[]>([]);
  const [typing, setTyping] = useState<string[]>([]);

  useEffect(() => {
    // Subscribe to messages in matches/{matchId}/messages
    const unsub = messageService.subscribeToMessages(matchId, setMessages);
    return unsub;
  }, [matchId]);

  useEffect(() => {
    // Subscribe to typing indicators
    const unsub = messageService.subscribeToTyping(matchId, setTyping);
    return unsub;
  }, [matchId]);

  const handleSendMessage = async (content: string) => {
    try {
      // This now calls backend 'sendMessage' callable
      await messageService.sendMessage(matchId, 'text', content);
    } catch (error) {
      // Handle error
    }
  };

  const handleSetTyping = async (isTyping: boolean) => {
    try {
      // This now calls backend 'setTyping' callable
      await messageService.setTyping(matchId, isTyping);
    } catch (error) {
      // Silent fail for typing indicator
    }
  };

  // Rest of component...
};
```

#### Update Matches/Discovery Component
**File:** `packages/app/src/features/discovery/DiscoveryPage.tsx`

```typescript
import { MatchServiceV2 } from '@core/services/match_v2';

export const DiscoveryPage = () => {
  const matchService = new MatchServiceV2();

  const handleSwipeRight = async (candidateId: string) => {
    try {
      // This now calls backend 'swipeRight' callable
      const match = await matchService.swipeRight(candidateId);
      if (match) {
        // It's a match! Navigate to chat
        navigate(`/messages/${match.id}`);
      }
    } catch (error) {
      // Handle error
    }
  };

  const handleSwipeLeft = async (candidateId: string) => {
    try {
      // This now calls backend 'swipeLeft' callable
      await matchService.swipeLeft(candidateId);
    } catch (error) {
      // Handle error
    }
  };

  // Rest of component...
};
```

---

### Phase 2.5 — Cutover & Cleanup (Week 4)

#### Step 1: Enable New Services
```bash
# Set feature flag or environment variable
NEXT_PUBLIC_USE_V2_SERVICES=true

# Deploy web app with both v1 and v2 services
# Initially route to v1 (current); prepare to switch
```

#### Step 2: Dual-Write Testing
```typescript
// Temporary: write to both v1 (old) and v2 (new) simultaneously
// Compare results; verify no data loss

async function sendMessageDualWrite(matchId: string, content: string) {
  // Write to old conversations/ (will be archived eventually)
  const oldResult = await messageServiceV1.sendMessage(matchId, content);
  
  // Write to new matches/{matchId}/messages via callable
  const newResult = await messageServiceV2.sendMessage(matchId, 'text', content);
  
  // Assert results are equivalent
  console.assert(oldResult.id === newResult.id);
  
  return newResult;
}
```

#### Step 3: Cutover (Canary → Full)
```
1. Deploy v2 services to staging
2. Run smoke tests (E2E) against staging
3. Deploy v2 services to production (initially with feature flag OFF)
4. Run monitoring for errors (30 min)
5. Switch feature flag: NEXT_PUBLIC_USE_V2_SERVICES=true for 10% of users
6. Monitor error rate; if OK, increase to 100% over 1 hour
7. Disable v1 services; archive old code
```

#### Step 4: Cleanup
```bash
# After 1-2 weeks in production (after all conversations archived):
# 1. Delete conversations/ collection
# 2. Delete typing_indicators/ collection
# 3. Remove messageServiceV1 code
# 4. Update documentation

# Delete old swipes collection (optional; can keep for audit trail)
```

---

## Firestore Rules Impact

### Current Rules (Restrict Web Writes)
```
match /matches/{matchId} {
  allow read: if isSignedIn() && resource.data.userIds.hasAny([request.auth.uid]);
  allow create, update, delete: if false; // Backend-only
}

match /matches/{matchId}/messages/{messageId} {
  allow read: if isSignedIn() && resource.data.visibleTo.hasAny([request.auth.uid]);
  allow create, update, delete: if false; // Backend-only via callable
}
```

### After Migration
Web will no longer violate these rules because:
1. Web reads from `matches/{matchId}` and `matches/{matchId}/messages` (rules allow)
2. Web mutations go through backend callables (rules allow for backend auth context)
3. Direct web writes are gone

---

## Success Criteria

- [ ] New `MessageServiceV2` and `MatchServiceV2` classes created and unit-tested
- [ ] All chat mutations route through backend callables (no direct Firestore writes)
- [ ] Data migration script successfully migrates conversations/ → matches/
- [ ] Staging environment tested end-to-end (send message, receive, read state, typing)
- [ ] Production cutover successful (feature flag enabled, no error spike)
- [ ] Old `conversations/` and `typing_indicators/` collections archived/deleted
- [ ] Cross-repo contract tests pass (web + mobile against same backend)

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Data loss in migration | Low | Critical | Backup before migration; dual-write during cutover |
| Unread count loss | Low | Medium | Map `conversations.unreadCount` → `participants.unreadCount` |
| Typing indicator latency | Medium | Low | Acceptable (presence via callable + polling) |
| Realtime subscription complexity | Medium | Medium | Use Firestore `onSnapshot` consistently; add tests |
| Breaking change for users | Low | High | Feature flag enables gradual rollout; short cutover window |

---

## Timeline

| Phase | Duration | Owner | Deliverable |
|-------|----------|-------|-------------|
| Phase 0.5 | 1 week | Web team | Data audit, test plan, feature parity analysis |
| Phase 1.0 | 1 week | Web team | New v2 service classes, callable integration |
| Phase 1.5 | 1 week | DevOps + Web | Data migration script, staging test |
| Phase 2.0 | 1 week | Web team | Component/page updates, dual-write testing |
| Phase 2.5 | 1 week | DevOps + Web | Staging validation, production cutover, cleanup |
| **Total** | **~5 weeks** | — | Web migrated to canonical backend contract |

---

## Dependencies & Blockers

- ✅ Backend Contract Matrix (completed 2026-06-05)
- ✅ Firestore Rules (already restrict direct writes; enable migration)
- ⏳ Backend Callables Stability (must be tested against web consumer)
- ⏳ Domain/Environment Matrix (for correct API URLs in migration)

---

## Decision Required

**Question for developer/web team:**

> Do you approve Option B (recommended): Migrate web to canonical `matches/{matchId}` and `matches/{matchId}/messages` schema, routing all mutations through backend callables?

**Alternatives:**
- Option A: Keep web's `conversations/` model (not recommended; backend complexity)
- Option C: Defer to Phase 2 and create REST API layer instead (simpler for web, more work for backend)

**Expected decision impact:**
- Approval → Proceed with Phase 0.5 (data audit) next week
- Rejection → Revisit Option C or A; may extend alignment timeline by 2+ weeks

---

## Revision History

| Date | Changes |
|------|---------|
| 2026-06-05 | Initial migration plan. Option B recommended. 5-week timeline with phased rollout. |
