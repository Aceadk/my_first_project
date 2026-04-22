const { expect } = require('chai');
const http = require('http');
const admin = require('firebase-admin');

const likes = new Map();
const matches = new Map();
const messagesByMatch = new Map();
const swipes = new Map();
const users = new Map();
const decodedTokens = {
  'valid-token': {
    uid: 'user-1',
    email: 'user1@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
  'other-token': {
    uid: 'user-9',
    email: 'user9@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
};

function clone(value) {
  return value;
}

function timestamp(isoString) {
  const date = new Date(isoString);
  return {
    toDate: () => new Date(date),
    toMillis: () => date.getTime(),
  };
}

function snapshot(id, data) {
  return {
    id,
    exists: data !== undefined,
    data: () => clone(data),
  };
}

class MockMessagesQuery {
  constructor(matchId) {
    this.matchId = matchId;
    this._beforeDate = null;
    this._startAfterDoc = null;
    this._limit = null;
  }

  orderBy() {
    return this;
  }

  where(field, op, value) {
    if (field === 'createdAt' && op === '<') {
      this._beforeDate =
        typeof value?.toDate === 'function' ? value.toDate() : new Date(value);
    }
    return this;
  }

  startAfter(doc) {
    this._startAfterDoc = doc;
    return this;
  }

  limit(value) {
    this._limit = value;
    return this;
  }

  doc(id) {
    const matchMessages = messagesByMatch.get(this.matchId) || new Map();
    return {
      get: async () => snapshot(id, matchMessages.get(id)),
    };
  }

  async get() {
    const matchMessages = messagesByMatch.get(this.matchId) || new Map();
    let docs = Array.from(matchMessages.entries()).map(([id, data]) =>
      snapshot(id, data),
    );

    docs.sort(
      (a, b) =>
        b.data().createdAt.toMillis() - a.data().createdAt.toMillis(),
    );

    if (this._beforeDate) {
      docs = docs.filter((doc) => doc.data().createdAt.toDate() < this._beforeDate);
    }

    if (this._startAfterDoc) {
      const cutoff = this._startAfterDoc.data().createdAt.toDate();
      docs = docs.filter((doc) => doc.data().createdAt.toDate() < cutoff);
    }

    if (typeof this._limit === 'number') {
      docs = docs.slice(0, this._limit);
    }

    return {
      empty: docs.length === 0,
      docs,
    };
  }
}

class MockMatchesQuery {
  constructor() {
    this._uid = null;
    this._beforeDate = null;
    this._limit = null;
  }

  where(field, op, value) {
    if (field === 'users' && op === 'array-contains') {
      this._uid = value;
    }
    if (field === 'lastMessageAt' && op === '<') {
      this._beforeDate =
        typeof value?.toDate === 'function' ? value.toDate() : new Date(value);
    }
    return this;
  }

  count() {
    return {
      get: async () => ({
        data: () => ({
          count: Array.from(matches.values()).filter((match) =>
            Array.isArray(match.users) && match.users.includes(this._uid),
          ).length,
        }),
      }),
    };
  }

  orderBy() {
    return this;
  }

  offset() {
    return this;
  }

  limit(value) {
    this._limit = value;
    return this;
  }

  async get() {
    let docs = Array.from(matches.entries()).map(([id, data]) =>
      snapshot(id, data),
    );

    if (this._uid) {
      docs = docs.filter((doc) => {
        const usersList = doc.data().users;
        return Array.isArray(usersList) && usersList.includes(this._uid);
      });
    }

    docs.sort(
      (a, b) =>
        b.data().lastMessageAt.toMillis() - a.data().lastMessageAt.toMillis(),
    );

    if (this._beforeDate) {
      docs = docs.filter((doc) => doc.data().lastMessageAt.toDate() < this._beforeDate);
    }

    if (typeof this._limit === 'number') {
      docs = docs.slice(0, this._limit);
    }

    return { empty: docs.length === 0, docs, size: docs.length };
  }
}

class MockUsersQuery {
  constructor() {
    this._ids = [];
  }

  where(field, op, value) {
    if (field === '__name__' && op === 'in' && Array.isArray(value)) {
      this._ids = value;
    }
    return this;
  }

  async get() {
    const docs = this._ids
      .filter((id) => users.has(id))
      .map((id) => snapshot(id, users.get(id)));

    return {
      empty: docs.length === 0,
      docs,
      size: docs.length,
    };
  }
}

class MockDiscoveryRelationsQuery {
  constructor(source) {
    this.source = source;
    this._filters = [];
  }

  where(field, op, value) {
    this._filters.push({ field, op, value });
    return this;
  }

  async get() {
    const sourceMap = this.source === 'likes' ? likes : swipes;
    let docs = Array.from(sourceMap.entries()).map(([id, data]) =>
      snapshot(id, data),
    );

    for (const filter of this._filters) {
      if (filter.op !== '==') {
        continue;
      }

      docs = docs.filter((doc) => doc.data()[filter.field] === filter.value);
    }

    return {
      empty: docs.length === 0,
      docs,
      size: docs.length,
    };
  }
}

class MockMatchDocRef {
  constructor(id) {
    this.id = id;
  }

  async get() {
    return snapshot(this.id, matches.get(this.id));
  }

  collection(name) {
    if (name !== 'messages') {
      throw new Error(`Unsupported subcollection: ${name}`);
    }
    return new MockMessagesQuery(this.id);
  }
}

const mockFirestore = {
  collection(name) {
    if (name === 'matches') {
      return {
        doc: (id) => new MockMatchDocRef(id),
        where: (...args) => new MockMatchesQuery().where(...args),
      };
    }

    if (name === 'likes' || name === 'swipes') {
      return {
        where: (...args) => new MockDiscoveryRelationsQuery(name).where(...args),
      };
    }

    if (name === 'users') {
      return {
        where: (...args) => new MockUsersQuery().where(...args),
      };
    }

    throw new Error(`Unsupported collection: ${name}`);
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
Object.defineProperty(admin.firestore, 'FieldPath', {
  configurable: true,
  writable: true,
  value: {
    documentId: () => '__name__',
  },
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
Object.defineProperty(admin, 'database', {
  configurable: true,
  writable: true,
  value: () => ({
    ref: () => ({
      set: async () => {},
      remove: async () => {},
    }),
  }),
});
Object.defineProperty(admin, 'storage', {
  configurable: true,
  writable: true,
  value: () => ({
    bucket: () => ({
      file: () => ({
        save: async () => {},
        makePublic: async () => {},
        delete: async () => {},
      }),
      getFiles: async () => [[]],
    }),
  }),
});
Object.defineProperty(admin, 'appCheck', {
  configurable: true,
  writable: true,
  value: () => ({
    verifyToken: async () => ({ appId: 'demo-app' }),
  }),
});
Object.defineProperty(admin, 'auth', {
  configurable: true,
  writable: true,
  value: () => ({
    verifyIdToken: async (token) => {
      const decoded = decodedTokens[token];
      if (!decoded) {
        throw new Error('Invalid token');
      }
      return decoded;
    },
  }),
});

delete require.cache[require.resolve('../lib/index.js')];
const functions = require('../lib/index.js');

describe('chat REST pagination contract', () => {
  let server;
  let baseUrl;

  async function sendRequest(path, token = 'valid-token') {
    const response = await fetch(`${baseUrl}${path}`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    const text = await response.text();
    return {
      status: response.status,
      json: text ? JSON.parse(text) : null,
    };
  }

  before((done) => {
    server = http.createServer((req, res) => functions.api(req, res));
    server.listen(0, () => {
      const { port } = server.address();
      baseUrl = `http://127.0.0.1:${port}`;
      done();
    });
  });

  beforeEach(() => {
    likes.clear();
    matches.clear();
    messagesByMatch.clear();
    swipes.clear();
    users.clear();

    users.set('user-2', {
      profile: {
        name: 'Ava',
        photoUrls: ['https://example.com/ava.jpg'],
      },
    });
    users.set('user-3', {
      profile: {
        displayName: 'Jules',
        photoUrls: ['https://example.com/jules.jpg'],
      },
    });
    users.set('user-4', {
      profile: {
        name: 'Riley',
        bio: 'Coffee and long walks.',
        city: 'Kathmandu',
        interests: ['coffee', 'travel'],
        photoUrls: ['https://example.com/riley.jpg'],
      },
      idVerified: true,
    });
    users.set('user-6', {
      profile: {
        displayName: 'Morgan',
        bio: 'Always planning the next hike.',
        city: 'Pokhara',
        interests: ['hiking'],
        photoUrls: ['https://example.com/morgan.jpg'],
      },
    });

    matches.set('match-1', {
      users: ['user-1', 'user-2'],
      lastMessageAt: timestamp('2026-03-08T02:00:00.000Z'),
    });
    matches.set('match-2', {
      users: ['user-1', 'user-3'],
      lastMessageAt: timestamp('2026-03-08T04:00:00.000Z'),
    });
    messagesByMatch.set(
      'match-1',
      new Map([
        [
          'msg-1',
          {
            senderId: 'user-1',
            content: 'oldest',
            type: 'text',
            createdAt: timestamp('2026-03-08T00:00:00.000Z'),
            reactions: [],
          },
        ],
        [
          'msg-2',
          {
            senderId: 'user-2',
            content: 'older',
            type: 'text',
            createdAt: timestamp('2026-03-08T01:00:00.000Z'),
            reactions: [],
          },
        ],
        [
          'msg-3',
          {
            senderId: 'user-1',
            content: 'newer',
            type: 'text',
            createdAt: timestamp('2026-03-08T02:00:00.000Z'),
            reactions: [],
          },
        ],
      ]),
    );
    messagesByMatch.set(
      'match-2',
      new Map([
        [
          'msg-4',
          {
            senderId: 'user-3',
            content: 'latest',
            type: 'text',
            createdAt: timestamp('2026-03-08T04:00:00.000Z'),
            reactions: [],
          },
        ],
      ]),
    );

    likes.set('like-1', {
      fromUserId: 'user-4',
      toUserId: 'user-1',
      createdAt: timestamp('2026-03-08T05:00:00.000Z'),
    });
    likes.set('like-2', {
      fromUserId: 'user-6',
      toUserId: 'user-1',
      createdAt: timestamp('2026-03-08T01:30:00.000Z'),
    });
    swipes.set('swipe-1', {
      swiperId: 'user-2',
      targetId: 'user-1',
      action: 'super_like',
      createdAt: timestamp('2026-03-08T04:30:00.000Z'),
    });
    swipes.set('swipe-2', {
      swiperId: 'user-4',
      targetId: 'user-1',
      action: 'like',
      createdAt: timestamp('2026-03-08T03:00:00.000Z'),
    });
    swipes.set('swipe-3', {
      swiperId: 'user-5',
      targetId: 'user-1',
      action: 'pass',
      createdAt: timestamp('2026-03-08T06:00:00.000Z'),
    });
  });

  after((done) => {
    server.close(done);
  });

  it('returns has_more and next_cursor for the first page', async () => {
    const response = await sendRequest('/v1/chat/match-1/messages?limit=2');

    expect(response.status).to.equal(200);
    expect(response.json.messages).to.have.length(2);
    expect(response.json.messages.map((message) => message.id)).to.deep.equal([
      'msg-2',
      'msg-3',
    ]);
    expect(response.json.has_more).to.equal(true);
    expect(response.json.next_cursor).to.equal('2026-03-08T01:00:00.000Z');
  });

  it('accepts an ISO timestamp cursor for older messages', async () => {
    const response = await sendRequest(
      '/v1/chat/match-1/messages?limit=2&before=2026-03-08T01:00:00.000Z',
    );

    expect(response.status).to.equal(200);
    expect(response.json.messages).to.have.length(1);
    expect(response.json.messages[0].id).to.equal('msg-1');
    expect(response.json.has_more).to.equal(false);
    expect(response.json.next_cursor).to.equal(null);
  });

  it('rejects users who are not participants in the match', async () => {
    const response = await sendRequest(
      '/v1/chat/match-1/messages?limit=2',
      'other-token',
    );

    expect(response.status).to.equal(403);
    expect(response.json.error).to.equal('Not authorized');
  });

  it('returns conversation pagination metadata for the first page', async () => {
    const response = await sendRequest('/v1/chat/conversations?limit=1');

    expect(response.status).to.equal(200);
    expect(response.json.conversations).to.have.length(1);
    expect(response.json.total_count).to.equal(2);
    expect(response.json.has_more).to.equal(true);
    expect(response.json.next_cursor).to.equal('2026-03-08T04:00:00.000Z');

    const [conversation] = response.json.conversations;
    expect(conversation.id).to.equal('match-2');
    expect(conversation.match_id).to.equal('match-2');
    expect(conversation.participant).to.deep.equal({
      id: 'user-3',
      name: 'Jules',
      photo_url: 'https://example.com/jules.jpg',
    });
    expect(conversation.participants).to.deep.equal([
      {
        user_id: 'user-3',
        display_name: 'Jules',
        photo_url: 'https://example.com/jules.jpg',
      },
    ]);
    expect(conversation.last_message.id).to.equal('msg-4');
    expect(conversation.last_message.conversation_id).to.equal('match-2');
    expect(conversation.last_message.sender_id).to.equal('user-3');
    expect(conversation.last_message.created_at).to.equal(
      '2026-03-08T04:00:00.000Z',
    );
    expect(conversation.last_message.sent_at).to.equal(
      '2026-03-08T04:00:00.000Z',
    );
  });

  it('accepts an ISO timestamp cursor for older conversations', async () => {
    const response = await sendRequest(
      '/v1/chat/conversations?limit=1&before=2026-03-08T04:00:00.000Z',
    );

    expect(response.status).to.equal(200);
    expect(response.json.conversations).to.have.length(1);
    expect(response.json.conversations[0].id).to.equal('match-1');
    expect(response.json.total_count).to.equal(2);
    expect(response.json.has_more).to.equal(false);
    expect(response.json.next_cursor).to.equal(null);
  });

  it('rejects an invalid conversations before cursor', async () => {
    const response = await sendRequest(
      '/v1/chat/conversations?before=not-a-date',
    );

    expect(response.status).to.equal(400);
    expect(response.json.error).to.equal('Invalid before cursor');
  });

  it('returns likes-you pagination metadata for an explicit page size', async () => {
    const response = await sendRequest('/v1/discovery/likes-you?limit=2');

    expect(response.status).to.equal(200);
    expect(response.json.total_count).to.equal(3);
    expect(response.json.has_more).to.equal(true);
    expect(response.json.next_offset).to.equal(2);
    expect(response.json.profiles.map((profile) => profile.id)).to.deep.equal([
      'user-4',
      'user-2',
    ]);
    expect(response.json.candidates.map((profile) => profile.id)).to.deep.equal([
      'user-4',
      'user-2',
    ]);
    expect(response.json.profiles[0].display_name).to.equal('Riley');
    expect(response.json.profiles[0].is_verified).to.equal(true);
  });

  it('supports offset pagination for likes-you after merged deduplication', async () => {
    const response = await sendRequest('/v1/discovery/likes-you?offset=2&limit=2');

    expect(response.status).to.equal(200);
    expect(response.json.total_count).to.equal(3);
    expect(response.json.has_more).to.equal(false);
    expect(response.json.next_offset).to.equal(null);
    expect(response.json.profiles.map((profile) => profile.id)).to.deep.equal([
      'user-6',
    ]);
  });

  it('keeps likes-you backward compatible when no explicit limit is provided', async () => {
    const response = await sendRequest('/v1/discovery/likes-you');

    expect(response.status).to.equal(200);
    expect(response.json.total_count).to.equal(3);
    expect(response.json.has_more).to.equal(false);
    expect(response.json.next_offset).to.equal(null);
    expect(response.json.profiles.map((profile) => profile.id)).to.deep.equal([
      'user-4',
      'user-2',
      'user-6',
    ]);
  });

  it('returns next_cursor metadata for the first matches page', async () => {
    const response = await sendRequest('/v1/matches?limit=1');

    expect(response.status).to.equal(200);
    expect(response.json.matches).to.have.length(1);
    expect(response.json.matches[0].id).to.equal('match-2');
    expect(response.json.total_count).to.equal(2);
    expect(response.json.has_more).to.equal(true);
    expect(response.json.next_cursor).to.equal('2026-03-08T04:00:00.000Z');
  });

  it('accepts an ISO timestamp cursor for older matches', async () => {
    const response = await sendRequest(
      '/v1/matches?limit=1&before=2026-03-08T04:00:00.000Z',
    );

    expect(response.status).to.equal(200);
    expect(response.json.matches).to.have.length(1);
    expect(response.json.matches[0].id).to.equal('match-1');
    expect(response.json.total_count).to.equal(2);
    expect(response.json.has_more).to.equal(false);
    expect(response.json.next_cursor).to.equal(null);
  });

  it('rejects an invalid matches before cursor', async () => {
    const response = await sendRequest('/v1/matches?before=not-a-date');

    expect(response.status).to.equal(400);
    expect(response.json.error).to.equal('Invalid before cursor');
  });
});
