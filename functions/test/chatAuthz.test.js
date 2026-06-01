// CHAT-BE-001 — message authorization & visibility regression coverage.
//
// Exercises the REST send / read handlers with malicious fixtures to prove that
// only valid, unblocked participants of an active match can write conversation
// data, and that REST-sent messages carry the fields the moderation + retention
// pipeline depends on (CHAT-BE-003).
const { expect } = require('chai');
const http = require('http');
const admin = require('firebase-admin');

const matches = new Map();
const messagesByMatch = new Map();
const blocks = new Map();

const decodedTokens = {
  // user-1 and user-2 are participants of match-1.
  'token-user-1': {
    uid: 'user-1',
    email: 'user1@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
  'token-user-2': {
    uid: 'user-2',
    email: 'user2@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
  // user-9 is NOT a participant of any match (the attacker).
  'token-user-9': {
    uid: 'user-9',
    email: 'user9@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
};

function snapshot(id, data) {
  return { id, exists: data !== undefined, data: () => data };
}

// Minimal Firestore mock covering the collections the chat handlers touch.
class MessagesCollection {
  constructor(matchId) {
    this.matchId = matchId;
  }

  async add(doc) {
    const map = messagesByMatch.get(this.matchId) || new Map();
    const id = `msg-${map.size + 1}`;
    map.set(id, doc);
    messagesByMatch.set(this.matchId, map);
    return { id };
  }

  orderBy() {
    return this;
  }

  limit() {
    return this;
  }

  async get() {
    const map = messagesByMatch.get(this.matchId) || new Map();
    const docs = Array.from(map.entries()).map(([id, data]) =>
      snapshot(id, data),
    );
    return { empty: docs.length === 0, docs };
  }
}

class MatchDocRef {
  constructor(id) {
    this.id = id;
  }

  async get() {
    return snapshot(this.id, matches.get(this.id));
  }

  async update(patch) {
    const existing = matches.get(this.id) || {};
    matches.set(this.id, { ...existing, ...patch });
    return {};
  }

  collection(name) {
    if (name !== 'messages') {
      throw new Error(`Unsupported subcollection: ${name}`);
    }
    return new MessagesCollection(this.id);
  }
}

class BlockDocRef {
  constructor(id) {
    this.id = id;
  }

  async get() {
    return snapshot(this.id, blocks.get(this.id));
  }
}

// hasBlockingRelationship first checks blocks/{a_b} + blocks/{b_a} by doc id,
// then falls back to a legacy where('blocker_id')/where('blocked_id') query.
// The query mock matches against the same `blocks` map so both paths agree.
class BlockQuery {
  constructor() {
    this._filters = [];
  }

  where(field, op, value) {
    this._filters.push({ field, value });
    return this;
  }

  limit() {
    return this;
  }

  async get() {
    const docs = Array.from(blocks.entries())
      .filter(([, data]) =>
        this._filters.every((f) => data[f.field] === f.value),
      )
      .map(([id, data]) => snapshot(id, data));
    return { empty: docs.length === 0, docs };
  }
}

const mockFirestore = {
  collection(name) {
    if (name === 'matches') {
      return { doc: (id) => new MatchDocRef(id) };
    }
    if (name === 'blocks') {
      return {
        doc: (id) => new BlockDocRef(id),
        where: (...args) => new BlockQuery().where(...args),
      };
    }
    if (name === 'rate_limits') {
      // The rate limiter just needs an opaque ref; the transaction below
      // always reports the request as allowed.
      return { doc: () => ({}) };
    }
    throw new Error(`Unsupported collection: ${name}`);
  },
  // Used by createRateLimiter — report an empty window so requests pass.
  async runTransaction(fn) {
    return fn({
      get: async () => ({ exists: false, data: () => null }),
      set: () => {},
    });
  },
};

Object.defineProperty(admin, 'initializeApp', {
  configurable: true,
  writable: true,
  value: () => ({}),
});
Object.defineProperty(admin, 'firestore', {
  configurable: true,
  writable: true,
  value: () => mockFirestore,
});
Object.defineProperty(admin.firestore, 'FieldValue', {
  configurable: true,
  writable: true,
  value: { serverTimestamp: () => ({ __serverTimestamp: true }) },
});
Object.defineProperty(admin.firestore, 'Timestamp', {
  configurable: true,
  writable: true,
  value: {
    fromDate: (date) => ({
      toDate: () => new Date(date),
      toMillis: () => new Date(date).getTime(),
    }),
  },
});
Object.defineProperty(admin, 'auth', {
  configurable: true,
  writable: true,
  value: () => ({
    verifyIdToken: async (token) => {
      const decoded = decodedTokens[token];
      if (!decoded) throw new Error('Invalid token');
      return decoded;
    },
  }),
});
Object.defineProperty(admin, 'appCheck', {
  configurable: true,
  writable: true,
  value: () => ({ verifyToken: async () => ({ appId: 'demo-app' }) }),
});
// index.js calls admin.database() at module load; stub it so requiring the
// module does not throw (matches chatRestPagination.test.js).
Object.defineProperty(admin, 'database', {
  configurable: true,
  writable: true,
  value: () => ({
    ref: () => ({ set: async () => {}, remove: async () => {} }),
  }),
});

delete require.cache[require.resolve('../lib/index.js')];
const functions = require('../lib/index.js');

describe('chat message authorization (CHAT-BE-001)', () => {
  let server;
  let baseUrl;

  async function send(path, token, body) {
    const response = await fetch(`${baseUrl}${path}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body || {}),
    });
    const text = await response.text();
    return { status: response.status, json: text ? JSON.parse(text) : null };
  }

  before((done) => {
    server = http.createServer((req, res) => functions.api(req, res));
    server.listen(0, () => {
      baseUrl = `http://127.0.0.1:${server.address().port}`;
      done();
    });
  });

  beforeEach(() => {
    matches.clear();
    messagesByMatch.clear();
    blocks.clear();
    matches.set('match-1', { users: ['user-1', 'user-2'], status: 'active' });
  });

  after((done) => {
    server.close(done);
  });

  describe('POST /v1/chat/:id/send', () => {
    it('allows a participant to send and persists moderation/retention fields', async () => {
      const response = await send('/v1/chat/match-1/send', 'token-user-1', {
        type: 'text',
        content: 'hello there',
      });

      expect(response.status).to.equal(200);
      expect(response.json.success).to.equal(true);

      const stored = Array.from(messagesByMatch.get('match-1').values())[0];
      // Legacy field preserved for the read path.
      expect(stored.senderId).to.equal('user-1');
      // CHAT-BE-003: fields the moderation trigger + retention require.
      expect(stored.fromUserId).to.equal('user-1');
      expect(stored.toUserId).to.equal('user-2');
      expect(stored.visibleTo).to.have.members(['user-1', 'user-2']);
    });

    it('rejects a non-participant with 403 and writes nothing', async () => {
      const response = await send('/v1/chat/match-1/send', 'token-user-9', {
        type: 'text',
        content: 'let me in',
      });

      expect(response.status).to.equal(403);
      expect(messagesByMatch.has('match-1')).to.equal(false);
    });

    it('returns 404 for a non-existent conversation', async () => {
      const response = await send('/v1/chat/missing/send', 'token-user-1', {
        type: 'text',
        content: 'anybody home',
      });
      expect(response.status).to.equal(404);
    });

    it('blocks sending when a block relationship exists (either direction)', async () => {
      blocks.set('user-2_user-1', {
        blockerId: 'user-2',
        blockedId: 'user-1',
      });

      const response = await send('/v1/chat/match-1/send', 'token-user-1', {
        type: 'text',
        content: 'still here',
      });

      expect(response.status).to.equal(403);
      expect(messagesByMatch.has('match-1')).to.equal(false);
    });

    it('refuses to write to an inactive (unmatched) conversation', async () => {
      matches.set('match-1', {
        users: ['user-1', 'user-2'],
        status: 'unmatched',
      });

      const response = await send('/v1/chat/match-1/send', 'token-user-1', {
        type: 'text',
        content: 'come back',
      });

      expect(response.status).to.equal(403);
      expect(messagesByMatch.has('match-1')).to.equal(false);
    });

    it('rejects empty content with 400 before persisting', async () => {
      const response = await send('/v1/chat/match-1/send', 'token-user-1', {
        type: 'text',
        content: '   ',
      });

      expect(response.status).to.equal(400);
      expect(messagesByMatch.has('match-1')).to.equal(false);
    });
  });

  describe('POST /v1/chat/:id/read', () => {
    it('allows a participant to mark read', async () => {
      const response = await send('/v1/chat/match-1/read', 'token-user-2');
      expect(response.status).to.equal(200);
      expect(response.json.success).to.equal(true);
    });

    it('rejects a non-participant marking read with 403', async () => {
      const response = await send('/v1/chat/match-1/read', 'token-user-9');
      expect(response.status).to.equal(403);
    });

    it('returns 404 when the conversation does not exist', async () => {
      const response = await send('/v1/chat/missing/read', 'token-user-1');
      expect(response.status).to.equal(404);
    });
  });
});
