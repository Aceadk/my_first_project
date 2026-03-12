const { expect } = require('chai');
const http = require('http');
const admin = require('firebase-admin');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});
process.env.ENFORCE_APP_CHECK = 'false';

let autoIdCounter = 0;
const collections = new Map();
const createdUsers = new Map();

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

  async update(payload) {
    const store = collectionStore(this.collectionName);
    const current = store.get(this.id);
    if (!current) {
      throw new Error(`Document not found: ${this.collectionName}/${this.id}`);
    }
    store.set(this.id, { ...clone(current), ...clone(payload) });
  }

  async delete() {
    collectionStore(this.collectionName).delete(this.id);
  }
}

class MockQuery {
  constructor(collectionName, filters = [], orderByField = null, orderDirection = 'asc', limitCount = null) {
    this.collectionName = collectionName;
    this.filters = filters;
    this.orderByField = orderByField;
    this.orderDirection = orderDirection;
    this.limitCount = limitCount;
  }

  where(field, op, value) {
    if (op !== '==') {
      throw new Error(`Unsupported query operator in mock: ${op}`);
    }
    return new MockQuery(
      this.collectionName,
      [...this.filters, { field, value }],
      this.orderByField,
      this.orderDirection,
      this.limitCount
    );
  }

  orderBy(field, direction = 'asc') {
    return new MockQuery(
      this.collectionName,
      this.filters,
      field,
      direction,
      this.limitCount
    );
  }

  limit(count) {
    return new MockQuery(
      this.collectionName,
      this.filters,
      this.orderByField,
      this.orderDirection,
      count
    );
  }

  async get() {
    const store = collectionStore(this.collectionName);
    let docs = Array.from(store.entries()).filter(([, data]) =>
      this.filters.every((filter) => data?.[filter.field] === filter.value)
    );

    if (this.orderByField) {
      docs.sort((left, right) => {
        const leftValue = left[1]?.[this.orderByField];
        const rightValue = right[1]?.[this.orderByField];
        const leftMillis =
          leftValue instanceof Date ? leftValue.getTime() : Number(leftValue ?? 0);
        const rightMillis =
          rightValue instanceof Date ? rightValue.getTime() : Number(rightValue ?? 0);
        const delta = leftMillis - rightMillis;
        return this.orderDirection === 'desc' ? -delta : delta;
      });
    }

    if (typeof this.limitCount === 'number') {
      docs = docs.slice(0, this.limitCount);
    }

    const mapped = docs.map(([id, data]) => ({
      id,
      exists: true,
      data: () => clone(data),
      ref: new MockDocRef(this.collectionName, id),
    }));

    return {
      empty: mapped.length === 0,
      size: mapped.length,
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

  orderBy(field, direction) {
    return new MockQuery(this.name).orderBy(field, direction);
  }
}

const mockFirestore = {
  collection(name) {
    return new MockCollectionRef(name);
  },
  async runTransaction(handler) {
    const transaction = {
      get: async (docRef) => docRef.get(),
      set: async (docRef, payload, options) => docRef.set(payload, options),
    };
    return handler(transaction);
  },
};

const decodedTokens = {
  'token-valid': {
    uid: 'user-valid',
    email: 'valid@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
  'token-unverified': {
    uid: 'user-unverified',
    email: 'unverified@example.com',
    email_verified: false,
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
    getUserByPhoneNumber: async (phoneNumber) => {
      const existing = createdUsers.get(phoneNumber);
      if (!existing) {
        throw new Error('User not found');
      }
      return existing;
    },
    createUser: async ({ phoneNumber }) => {
      const created = {
        uid: `created-${createdUsers.size + 1}`,
        phoneNumber,
        email: null,
        emailVerified: false,
      };
      createdUsers.set(phoneNumber, created);
      return created;
    },
    createCustomToken: async (uid) => `custom-token-for-${uid}`,
  }),
});

delete require.cache[require.resolve('../lib/index.js')];
const functions = require('../lib/index.js');

describe('security abuse regression lane', () => {
  let server;
  let baseUrl;

  async function sendRequest(path, options = {}) {
    const headers = { ...(options.headers || {}) };
    if (options.token !== null && options.token !== undefined) {
      headers.Authorization = `Bearer ${options.token}`;
    }
    if (options.body !== undefined) {
      headers['Content-Type'] = 'application/json';
    }

    const response = await fetch(`${baseUrl}${path}`, {
      method: options.method || 'POST',
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });

    const text = await response.text();
    return {
      status: response.status,
      headers: response.headers,
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

  after((done) => {
    server.close(done);
  });

  beforeEach(() => {
    autoIdCounter = 0;
    collections.clear();
    createdUsers.clear();
    functions.__test__helpers.clearExpressRateLimitStore();

    collectionStore('users').set('user-valid', {
      email: 'valid@example.com',
      profile: { name: 'Valid User' },
    });
    collectionStore('users').set('user-unverified', {
      email: 'unverified@example.com',
      profile: { name: 'Unverified User' },
    });
    collectionStore('users').set('user-target', {
      email: 'target@example.com',
      profile: { name: 'Target User' },
    });
  });

  it('rate limits repeated OTP send attempts on the REST auth lane', async function () {
    this.timeout(20000);

    for (let i = 0; i < 20; i += 1) {
      const attempt = await sendRequest('/v1/auth/otp/send', {
        body: { phone_number: `+15555550${String(i).padStart(2, '0')}` },
      });
      expect(attempt.status).to.equal(200);
      expect(attempt.json.success).to.equal(true);
      expect(attempt.json.verification_id).to.be.a('string');
    }

    const limited = await sendRequest('/v1/auth/otp/send', {
      body: { phone_number: '+15555559999' },
    });

    expect(limited.status).to.equal(429);
    expect(limited.json.error).to.equal('Too many requests. Please try again later.');
    expect(limited.json.retryAfter).to.be.a('number');
    expect(Number(limited.headers.get('retry-after'))).to.be.greaterThan(0);
  });

  it('rate limits repeated OTP verify attempts even with malformed payloads', async function () {
    this.timeout(10000);

    for (let i = 0; i < 20; i += 1) {
      const attempt = await sendRequest('/v1/auth/otp/verify', {
        body: {},
      });
      expect(attempt.status).to.equal(400);
      expect(attempt.json.error).to.equal('Phone number and OTP required');
    }

    const limited = await sendRequest('/v1/auth/otp/verify', {
      body: {},
    });

    expect(limited.status).to.equal(429);
    expect(limited.json.error).to.equal('Too many requests. Please try again later.');
    expect(limited.json.retryAfter).to.be.a('number');
  });

  it('rejects missing authorization headers on report endpoint', async () => {
    const result = await sendRequest('/v1/users/report', {
      token: null,
      body: {
        reported_id: 'user-target',
        reason: 'Spam profile',
      },
    });

    expect(result.status).to.equal(401);
    expect(result.json.error).to.equal('Missing authorization header');
  });

  it('rejects invalid bearer tokens on block endpoint', async () => {
    const result = await sendRequest('/v1/users/block', {
      token: 'bad-token',
      body: {
        blocked_id: 'user-target',
      },
    });

    expect(result.status).to.equal(401);
    expect(result.json.error).to.equal('Invalid or expired token');
  });

  it('rejects unverified email/password users on report endpoint', async () => {
    const result = await sendRequest('/v1/users/report', {
      token: 'token-unverified',
      body: {
        reported_id: 'user-target',
        reason: 'Spam profile',
      },
    });

    expect(result.status).to.equal(403);
    expect(result.json.error).to.equal('Email verification required');
  });

  it('rate limits repeated report abuse attempts', async function () {
    this.timeout(10000);

    for (let i = 0; i < 10; i += 1) {
      const attempt = await sendRequest('/v1/users/report', {
        token: 'token-valid',
        body: {
          reported_id: 'user-target',
          reason: `Spam profile ${i}`,
        },
      });
      expect(attempt.status).to.equal(200);
      expect(attempt.json).to.deep.equal({ success: true });
    }

    const limited = await sendRequest('/v1/users/report', {
      token: 'token-valid',
      body: {
        reported_id: 'user-target',
        reason: 'Spam profile overflow',
      },
    });

    expect(limited.status).to.equal(429);
    expect(limited.json.error).to.equal('Too many requests. Please try again later.');
    expect(limited.json.retryAfter).to.be.a('number');
  });

  it('rate limits repeated block abuse attempts at the configured block threshold', async function () {
    this.timeout(10000);

    for (let i = 0; i < 20; i += 1) {
      const attempt = await sendRequest('/v1/users/block', {
        token: 'token-valid',
        body: {
          blocked_id: 'user-target',
        },
      });
      expect(attempt.status).to.equal(200);
      expect(attempt.json).to.deep.equal({ success: true });
    }

    const limited = await sendRequest('/v1/users/block', {
      token: 'token-valid',
      body: {
        blocked_id: 'user-target',
      },
    });

    expect(limited.status).to.equal(429);
    expect(limited.json.error).to.equal('Too many requests. Please try again later.');
    expect(limited.json.retryAfter).to.be.a('number');
  });
});
