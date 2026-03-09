const { expect } = require('chai');
const http = require('http');
const admin = require('firebase-admin');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

let autoIdCounter = 0;
const collections = new Map();

function clone(value) {
  if (value === null || value === undefined) return value;
  if (value instanceof Date) return new Date(value.getTime());
  if (Array.isArray(value)) return value.map((item) => clone(item));
  if (typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, nested]) => [key, clone(nested)])
    );
  }
  return value;
}

function collectionStore(name) {
  if (!collections.has(name)) {
    collections.set(name, new Map());
  }
  return collections.get(name);
}

class MockDocRef {
  constructor(collectionName, id) {
    this.collectionName = collectionName;
    this.id = id;
  }

  async get() {
    const store = collectionStore(this.collectionName);
    const data = store.get(this.id);
    return {
      id: this.id,
      exists: data !== undefined,
      data: () => clone(data),
      ref: this,
    };
  }

  async set(payload, options = {}) {
    const store = collectionStore(this.collectionName);
    if (options.merge) {
      const current = store.get(this.id) || {};
      store.set(this.id, { ...clone(current), ...clone(payload) });
      return;
    }
    store.set(this.id, clone(payload));
  }

  async delete() {
    const store = collectionStore(this.collectionName);
    store.delete(this.id);
  }
}

class MockQuery {
  constructor(collectionName, filters = [], limitCount = null) {
    this.collectionName = collectionName;
    this.filters = filters;
    this.limitCount = limitCount;
  }

  where(field, op, value) {
    if (op !== '==') {
      throw new Error(`Unsupported query operator in mock: ${op}`);
    }
    return new MockQuery(
      this.collectionName,
      [...this.filters, { field, value }],
      this.limitCount
    );
  }

  limit(count) {
    return new MockQuery(this.collectionName, this.filters, count);
  }

  async get() {
    const store = collectionStore(this.collectionName);
    let docs = Array.from(store.entries()).filter(([, data]) =>
      this.filters.every((filter) => data?.[filter.field] === filter.value)
    );
    if (typeof this.limitCount === 'number') {
      docs = docs.slice(0, this.limitCount);
    }

    const mapped = docs.map(([id, data]) => ({
      id,
      data: () => clone(data),
      ref: new MockDocRef(this.collectionName, id),
    }));

    return {
      empty: mapped.length === 0,
      docs: mapped,
      forEach: (fn) => mapped.forEach(fn),
    };
  }
}

class MockCollectionRef {
  constructor(name) {
    this.name = name;
  }

  doc(id) {
    return new MockDocRef(this.name, id);
  }

  async add(payload) {
    autoIdCounter += 1;
    const id = `auto_${autoIdCounter}`;
    const ref = new MockDocRef(this.name, id);
    await ref.set(payload);
    return ref;
  }

  where(field, op, value) {
    return new MockQuery(this.name).where(field, op, value);
  }
}

const mockFirestore = {
  collection(name) {
    return new MockCollectionRef(name);
  },
  async runTransaction(handler) {
    const tx = {
      get: async (docRef) => docRef.get(),
      set: async (docRef, payload, options) => docRef.set(payload, options),
    };
    return handler(tx);
  },
};

const decodedTokens = {
  'token-self': {
    uid: 'user-self',
    email: 'self@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
  'token-invalid': {
    uid: 'user-invalid',
    email: 'invalid@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
  'token-rate-limit': {
    uid: 'user-rate-limit',
    email: 'ratelimit@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
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

describe('safety REST endpoint regressions', () => {
  let server;
  let baseUrl;

  async function sendRequest(path, body, token) {
    const response = await fetch(`${baseUrl}${path}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const text = await response.text();
    return {
      status: response.status,
      headers: response.headers,
      json: text ? JSON.parse(text) : null,
    };
  }

  function latestSafetyAuditLog() {
    const store = collectionStore('safety_rest_audit_logs');
    const entries = Array.from(store.values());
    return entries[entries.length - 1] || null;
  }

  before((done) => {
    server = http.createServer((req, res) => functions.api(req, res));
    server.listen(0, () => {
      const { port } = server.address();
      baseUrl = `http://127.0.0.1:${port}`;
      done();
    });
  });

  after((done) => {
    server.close(done);
  });

  beforeEach(() => {
    autoIdCounter = 0;
    collections.clear();

    collectionStore('users').set('user-self', {
      email: 'self@example.com',
      profile: { name: 'Self' },
    });
    collectionStore('users').set('user-invalid', {
      email: 'invalid@example.com',
      profile: { name: 'Invalid' },
    });
    collectionStore('users').set('user-rate-limit', {
      email: 'ratelimit@example.com',
      profile: { name: 'Rate Limit' },
    });
    collectionStore('users').set('user-target', {
      email: 'target@example.com',
      profile: { name: 'Target' },
    });
  });

  it('rejects self-target block attempts with machine-readable validation code', async () => {
    const result = await sendRequest(
      '/v1/users/block',
      { blocked_id: 'user-self' },
      'token-self'
    );

    expect(result.status).to.equal(400);
    expect(result.json.code).to.equal('invalid-argument');
    expect(result.json.error).to.match(/cannot block yourself/i);

    const auditLog = latestSafetyAuditLog();
    expect(auditLog).to.include({
      action: 'block',
      actorUid: 'user-self',
      targetUid: 'user-self',
      outcome: 'invalid',
      statusCode: 400,
      errorCode: 'invalid-argument',
      route: '/v1/users/block',
    });
  });

  it('rejects invalid report payloads with mapped validation error', async () => {
    const result = await sendRequest(
      '/v1/users/report',
      {
        reported_id: 'user-target',
        reason: '  ',
      },
      'token-invalid'
    );

    expect(result.status).to.equal(400);
    expect(result.json.code).to.equal('invalid-argument');
    expect(result.json.error).to.match(/reason is required/i);

    const auditLog = latestSafetyAuditLog();
    expect(auditLog).to.include({
      action: 'report',
      actorUid: 'user-invalid',
      targetUid: 'user-target',
      outcome: 'invalid',
      statusCode: 400,
      errorCode: 'invalid-argument',
      route: '/v1/users/report',
    });
  });

  it('returns structured unblock rate-limit responses at boundary', async function () {
    this.timeout(10000);

    for (let i = 0; i < 30; i += 1) {
      const attempt = await sendRequest(
        '/v1/users/unblock',
        { blocked_id: 'user-target' },
        'token-rate-limit'
      );
      expect(attempt.status).to.equal(200);
      expect(attempt.json).to.deep.equal({ success: true });
    }

    const limited = await sendRequest(
      '/v1/users/unblock',
      { blocked_id: 'user-target' },
      'token-rate-limit'
    );

    expect(limited.status).to.equal(429);
    expect(limited.json.error).to.equal('Too many unblock requests');
    expect(limited.json).to.have.property('retry_after_ms');
    expect(limited.json.retry_after_ms).to.be.a('number');
    expect(limited.json.retry_after_ms).to.be.greaterThan(0);
    expect(limited.json.message).to.match(/please try again/i);

    const auditLog = latestSafetyAuditLog();
    expect(auditLog).to.include({
      action: 'unblock',
      actorUid: 'user-rate-limit',
      targetUid: 'user-target',
      outcome: 'rate_limited',
      statusCode: 429,
      route: '/v1/users/unblock',
    });
    expect(auditLog.metadata.retryAfterMs).to.be.a('number');
    expect(auditLog.metadata.retryAfterMs).to.be.greaterThan(0);
  });
});
