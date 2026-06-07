/**
 * Firestore security-rules emulator coverage (Phase 3 Step 4).
 *
 * Exercises every collection/document path used by the web and mobile clients
 * against the real `firestore.rules`, asserting:
 *  - allowed reads/writes for authenticated owners and participants,
 *  - denied access for unauthenticated and unrelated users,
 *  - protected fields cannot be modified by clients.
 *
 * Path inventory lives in README.md. Run: `npm test` (starts the emulator via
 * firebase emulators:exec and loads ../firestore.rules).
 */

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  setLogLevel,
} from 'firebase/firestore';

// Silence the expected PERMISSION_DENIED gRPC noise from assertFails cases.
setLogLevel('silent');

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'demo-crush';

let testEnv;

/** Seed a document bypassing rules (admin context). */
async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const segments = path.split('/');
    await setDoc(doc(db, ...segments), data);
  });
}

/** Firestore handle for an authenticated user. */
function as(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}
/** Firestore handle for an unauthenticated visitor. */
function anon() {
  return testEnv.unauthenticatedContext().firestore();
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  // Canonical users used across suites.
  await seed('users/alice', {
    isIdVerified: true,
    isEmailVerified: true,
    plan: 'free',
    profile: { gender: 'female', privacySettings: { isProfileVisible: true } },
  });
  await seed('users/bob', {
    isIdVerified: true,
    isEmailVerified: true,
    plan: 'free',
    profile: { gender: 'male', privacySettings: { isProfileVisible: true } },
  });
  await seed('users/carol', { isIdVerified: true, isEmailVerified: true, plan: 'free' });
  await seed('users/dave', { isIdVerified: true, isEmailVerified: true, plan: 'plus' });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('users/{uid}', () => {
  it('owner can read own document', async () => {
    await assertSucceeds(getDoc(doc(as('alice'), 'users/alice')));
  });
  it('signed-in user can read a visible, non-blocked profile', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'users/alice')));
  });
  it('unauthenticated user cannot read profiles', async () => {
    await assertFails(getDoc(doc(anon(), 'users/alice')));
  });

  it('owner can create own document with nested profile (no legacy flat keys)', async () => {
    await assertSucceeds(
      setDoc(doc(as('newuser'), 'users/newuser'), {
        isEmailVerified: false,
        profile: { name: 'New', gender: 'female' },
      })
    );
  });
  it('rejects create that writes legacy flat profile keys', async () => {
    await assertFails(
      setDoc(doc(as('newuser'), 'users/newuser'), {
        age: 25, // legacy flat field
        profile: { name: 'New' },
      })
    );
  });

  it('owner can update a nested profile field', async () => {
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'users/alice'), { 'profile.bio': 'hello' })
    );
  });
  it('canonical web-shaped create passes (nested profile + allowed root only)', async () => {
    // Mirrors buildUserProfileCreateData output: demographics under profile.*,
    // only allowed identity/lifecycle fields at root.
    await assertSucceeds(
      setDoc(doc(as('canonuser'), 'users/canonuser'), {
        email: 'c@example.com',
        displayName: 'Canon User',
        photos: ['p1.jpg'],
        interestedIn: ['male'],
        onboardingComplete: true,
        profileComplete: true,
        profile: {
          name: 'Canon User',
          birthDate: '1998-05-10',
          gender: 'female',
          bio: 'hi',
          interests: ['Hiking'],
          photoUrls: ['p1.jpg'],
        },
      })
    );
  });
  it('canonical profile.* multi-field update passes', async () => {
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'users/alice'), {
        displayName: 'Alice A',
        'profile.name': 'Alice A',
        'profile.bio': 'updated',
        'profile.gender': 'female',
        'profile.interests': ['Coffee'],
      })
    );
  });
  it('owner CANNOT change protected field plan', async () => {
    await assertFails(updateDoc(doc(as('alice'), 'users/alice'), { plan: 'plus' }));
  });
  it('owner CANNOT change protected field isIdVerified', async () => {
    // alice is seeded isIdVerified:true; flipping the value is a real mutation.
    await assertFails(
      updateDoc(doc(as('alice'), 'users/alice'), { isIdVerified: false })
    );
  });
  it('owner CANNOT change stripe/customer fields', async () => {
    await assertFails(
      updateDoc(doc(as('alice'), 'users/alice'), { stripeCustomerId: 'cus_x' })
    );
  });
  it('owner CANNOT self-grant a boost by editing boost.*', async () => {
    await assertFails(
      updateDoc(doc(as('alice'), 'users/alice'), {
        boost: { expiresAt: Date.now() + 3600000, totalActivations: 99 },
      })
    );
  });
  it('owner CANNOT self-grant premium via entitlement fields', async () => {
    await assertFails(
      updateDoc(doc(as('alice'), 'users/alice'), {
        subscriptionExpiresAt: new Date(Date.now() + 9e9),
      })
    );
    await assertFails(
      updateDoc(doc(as('alice'), 'users/alice'), { subscriptionTier: 'plus' })
    );
    await assertFails(
      updateDoc(doc(as('alice'), 'users/alice'), { isPremium: true })
    );
  });
  it('rejects update that introduces a legacy flat profile field', async () => {
    await assertFails(updateDoc(doc(as('alice'), 'users/alice'), { bio: 'flat' }));
  });
  it('enforces photoUrls array bound (<=9)', async () => {
    const tenPhotos = Array.from({ length: 10 }, (_, i) => `p${i}.jpg`);
    await assertFails(
      updateDoc(doc(as('alice'), 'users/alice'), { 'profile.photoUrls': tenPhotos })
    );
  });
  it('non-owner cannot update another user', async () => {
    await assertFails(updateDoc(doc(as('bob'), 'users/alice'), { 'profile.bio': 'x' }));
  });
  it('clients cannot delete user documents', async () => {
    await assertFails(deleteDoc(doc(as('alice'), 'users/alice')));
  });

  describe('users/{uid}/fcmTokens/{token}', () => {
    it('owner can register, read, and delete own push token', async () => {
      await assertSucceeds(
        setDoc(doc(as('alice'), 'users/alice/fcmTokens/tok1'), {
          platform: 'web',
          createdAt: new Date(),
        })
      );
      await assertSucceeds(getDoc(doc(as('alice'), 'users/alice/fcmTokens/tok1')));
      await assertSucceeds(
        deleteDoc(doc(as('alice'), 'users/alice/fcmTokens/tok1'))
      );
    });
    it('cannot write another user push token', async () => {
      await assertFails(
        setDoc(doc(as('bob'), 'users/alice/fcmTokens/tok1'), { platform: 'web' })
      );
    });
    it('cannot read another user push tokens', async () => {
      await seed('users/alice/fcmTokens/tok1', { platform: 'web' });
      await assertFails(getDoc(doc(as('bob'), 'users/alice/fcmTokens/tok1')));
    });
    it('unauthenticated cannot write a push token', async () => {
      await assertFails(
        setDoc(doc(anon(), 'users/alice/fcmTokens/tok1'), { platform: 'web' })
      );
    });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('server-only collections', () => {
  const paths = [
    'usernames/alice',
    'auth_email_otps/otp1',
    'auth_rate_limits/key1',
    'auth_audit_logs/log1',
  ];
  for (const path of paths) {
    it(`${path} is not client-readable`, async () => {
      await assertFails(getDoc(doc(as('alice'), path)));
    });
    it(`${path} is not client-writable`, async () => {
      await assertFails(setDoc(doc(as('alice'), path), { x: 1 }));
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
describe('matches/{matchId}', () => {
  beforeEach(async () => {
    await seed('matches/m1', { userIds: ['alice', 'bob'], status: 'active' });
    await seed('matches/m2', { userIds: ['alice', 'bob'], status: 'unmatched' });
  });

  it('participant can read an active match', async () => {
    await assertSucceeds(getDoc(doc(as('alice'), 'matches/m1')));
  });
  it('non-participant cannot read a match', async () => {
    await assertFails(getDoc(doc(as('carol'), 'matches/m1')));
  });
  it('unauthenticated cannot read a match', async () => {
    await assertFails(getDoc(doc(anon(), 'matches/m1')));
  });
  it('participant cannot read an unmatched (inactive) match', async () => {
    await assertFails(getDoc(doc(as('alice'), 'matches/m2')));
  });
  it('clients cannot create matches (backend-managed)', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'matches/m3'), { userIds: ['alice', 'bob'], status: 'active' })
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('matches/{matchId}/messages/{messageId}', () => {
  beforeEach(async () => {
    await seed('matches/m1', { userIds: ['alice', 'bob'], status: 'active' });
    // Inbound message to alice from bob.
    await seed('matches/m1/messages/msg1', {
      fromUserId: 'bob',
      toUserId: 'alice',
      type: 'text',
      content: 'hi',
      isRead: false,
      visibleTo: ['alice', 'bob'],
    });
  });

  it('participant can read a visible message', async () => {
    await assertSucceeds(getDoc(doc(as('alice'), 'matches/m1/messages/msg1')));
  });
  it('non-participant cannot read messages', async () => {
    await assertFails(getDoc(doc(as('carol'), 'matches/m1/messages/msg1')));
  });
  it('participant can create a valid message', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'matches/m1/messages/msg2'), {
        fromUserId: 'alice',
        toUserId: 'bob',
        type: 'text',
        content: 'hello',
        isRead: false,
        visibleTo: ['alice', 'bob'],
      })
    );
  });
  it('cannot spoof another user as sender', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'matches/m1/messages/msg3'), {
        fromUserId: 'bob', // spoofed
        toUserId: 'alice',
        type: 'text',
        content: 'spoof',
        isRead: false,
        visibleTo: ['alice', 'bob'],
      })
    );
  });
  it('recipient can mark a message read', async () => {
    await assertSucceeds(
      updateDoc(doc(as('alice'), 'matches/m1/messages/msg1'), {
        isRead: true,
        readAt: new Date(),
      })
    );
  });
  it('recipient cannot edit message content via update', async () => {
    await assertFails(
      updateDoc(doc(as('alice'), 'matches/m1/messages/msg1'), { content: 'tampered' })
    );
  });
  it('clients cannot delete messages', async () => {
    await assertFails(deleteDoc(doc(as('alice'), 'matches/m1/messages/msg1')));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('message_requests/{requestId}', () => {
  beforeEach(async () => {
    await seed('message_requests/r1', { fromUserId: 'alice', toUserId: 'bob', content: 'hey' });
  });
  it('participant can read their request', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'message_requests/r1')));
  });
  it('unrelated user cannot read a request', async () => {
    await assertFails(getDoc(doc(as('carol'), 'message_requests/r1')));
  });
  it('sender can create a request', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'message_requests/r2'), { fromUserId: 'alice', toUserId: 'bob' })
    );
  });
  it('cannot create a request spoofing the sender', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'message_requests/r3'), { fromUserId: 'bob', toUserId: 'carol' })
    );
  });
  it('updates are not allowed', async () => {
    await assertFails(updateDoc(doc(as('alice'), 'message_requests/r1'), { content: 'x' }));
  });
  it('participant can delete (cleanup)', async () => {
    await assertSucceeds(deleteDoc(doc(as('bob'), 'message_requests/r1')));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('likes/{likeId}', () => {
  it('signed-in user can read likes', async () => {
    await seed('likes/l1', { fromUserId: 'bob', toUserId: 'alice' });
    await assertSucceeds(getDoc(doc(as('alice'), 'likes/l1')));
  });
  it('unauthenticated cannot read likes', async () => {
    await seed('likes/l1', { fromUserId: 'bob', toUserId: 'alice' });
    await assertFails(getDoc(doc(anon(), 'likes/l1')));
  });
  it('creator can create a like', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'likes/l2'), { fromUserId: 'alice', toUserId: 'bob' })
    );
  });
  it('cannot like yourself', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'likes/l3'), { fromUserId: 'alice', toUserId: 'alice' })
    );
  });
  it('cannot create a like as another user', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'likes/l4'), { fromUserId: 'bob', toUserId: 'carol' })
    );
  });
  it('likes are immutable (no update/delete)', async () => {
    await seed('likes/l1', { fromUserId: 'alice', toUserId: 'bob' });
    await assertFails(updateDoc(doc(as('alice'), 'likes/l1'), { toUserId: 'carol' }));
    await assertFails(deleteDoc(doc(as('alice'), 'likes/l1')));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('reports/{reportId}', () => {
  it('reporter can file a report', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'reports/rep1'), {
        reporterId: 'alice',
        reportedId: 'bob',
        reason: 'spam',
      })
    );
  });
  it('cannot report yourself', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'reports/rep2'), {
        reporterId: 'alice',
        reportedId: 'alice',
        reason: 'spam',
      })
    );
  });
  it('rejects an empty reason', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'reports/rep3'), {
        reporterId: 'alice',
        reportedId: 'bob',
        reason: '',
      })
    );
  });
  it('reports are not client-readable', async () => {
    await seed('reports/rep1', { reporterId: 'alice', reportedId: 'bob', reason: 'spam' });
    await assertFails(getDoc(doc(as('alice'), 'reports/rep1')));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('blocks/{blockId}', () => {
  it('blocker can create a block', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'blocks/alice_bob'), { blockerId: 'alice', blockedId: 'bob' })
    );
  });
  it('cannot block yourself', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'blocks/alice_alice'), { blockerId: 'alice', blockedId: 'alice' })
    );
  });
  it('cannot create a block as another user', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'blocks/bob_carol'), { blockerId: 'bob', blockedId: 'carol' })
    );
  });
  it('blocks are not client-readable', async () => {
    await seed('blocks/alice_bob', { blockerId: 'alice', blockedId: 'bob' });
    await assertFails(getDoc(doc(as('alice'), 'blocks/alice_bob')));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('stories/{storyId}', () => {
  it('female user can create a story', async () => {
    await assertSucceeds(
      setDoc(doc(as('alice'), 'stories/s1'), { userId: 'alice', mediaUrl: 'x' })
    );
  });
  it('premium user can create a story', async () => {
    await assertSucceeds(
      setDoc(doc(as('dave'), 'stories/s2'), { userId: 'dave', mediaUrl: 'x' })
    );
  });
  it('non-premium male user cannot create a story', async () => {
    await assertFails(
      setDoc(doc(as('bob'), 'stories/s3'), { userId: 'bob', mediaUrl: 'x' })
    );
  });
  it('signed-in user can read stories', async () => {
    await seed('stories/s1', { userId: 'alice', mediaUrl: 'x' });
    await assertSucceeds(getDoc(doc(as('bob'), 'stories/s1')));
  });
  it('owner can delete own story; others cannot', async () => {
    await seed('stories/s1', { userId: 'alice', mediaUrl: 'x' });
    await assertFails(deleteDoc(doc(as('bob'), 'stories/s1')));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'stories/s1')));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('calls/{callId}', () => {
  it('premium user can initiate a call', async () => {
    await assertSucceeds(
      setDoc(doc(as('dave'), 'calls/c1'), {
        callerId: 'dave',
        participants: ['dave', 'alice'],
      })
    );
  });
  it('non-premium user cannot initiate a call', async () => {
    await assertFails(
      setDoc(doc(as('alice'), 'calls/c2'), {
        callerId: 'alice',
        participants: ['alice', 'bob'],
      })
    );
  });
  it('participant can read a call; non-participant cannot', async () => {
    await seed('calls/c1', { callerId: 'dave', participants: ['dave', 'alice'] });
    await assertSucceeds(getDoc(doc(as('alice'), 'calls/c1')));
    await assertFails(getDoc(doc(as('bob'), 'calls/c1')));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
describe('presence/{uid}', () => {
  it('owner can read/write own presence', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'presence/alice'), { isOnline: true }));
    await assertSucceeds(getDoc(doc(as('alice'), 'presence/alice')));
  });
  it('cannot write another user presence', async () => {
    await assertFails(setDoc(doc(as('bob'), 'presence/alice'), { isOnline: false }));
  });
  it('non-premium user cannot read others presence', async () => {
    await seed('presence/alice', { isOnline: true });
    await assertFails(getDoc(doc(as('bob'), 'presence/alice')));
  });
  it('premium user can read others presence', async () => {
    await seed('presence/alice', { isOnline: true });
    await assertSucceeds(getDoc(doc(as('dave'), 'presence/alice')));
  });
});

// Entitlement-adjacent collections must not be client-writable (no rule →
// deny-by-default). Proves a client cannot self-grant promos/streaks/boost
// eligibility outside the server-owned commands.
describe('server-owned entitlement collections (deny client writes)', () => {
  const paths = [
    'promoCodes/code1',
    'promoCodeRedemptions/r1',
    'user_streaks/alice',
  ];
  for (const path of paths) {
    it(`${path} rejects client writes`, async () => {
      await assertFails(setDoc(doc(as('alice'), path), { x: 1 }));
    });
  }
});

// Sanity: the harness wired up (keeps mocha happy if a filter excludes all).
describe('harness', () => {
  it('loaded the test environment', () => {
    assert.ok(testEnv, 'test environment initialized');
  });
});
