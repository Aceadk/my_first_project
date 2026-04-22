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

function clone(value) {
  if (value === null || value === undefined) return value;
  if (value instanceof Date) return new Date(value.getTime());
  if (Array.isArray(value)) return value.map((item) => clone(item));
  if (typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, nested]) => [key, clone(nested)]),
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

function timestampFromMillis(ms) {
  const date = new Date(ms);
  return {
    toDate: () => new Date(date),
    toMillis: () => date.getTime(),
  };
}

function snapshot(collectionName, id, data, ref) {
  return {
    id,
    exists: data !== undefined,
    data: () => clone(data),
    ref: ref ?? new MockDocRef(collectionName, id),
  };
}

class MockDocRef {
  constructor(collectionName, id) {
    this.collectionName = collectionName;
    this.id = id;
  }

  collection(name) {
    return new MockCollectionRef(`${this.collectionName}/${this.id}/${name}`);
  }

  async get() {
    const store = collectionStore(this.collectionName);
    return snapshot(this.collectionName, this.id, store.get(this.id), this);
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
}

class MockCollectionRef {
  constructor(name) {
    this.name = name;
  }

  doc(id) {
    const resolvedId = id && String(id).trim().length > 0
      ? String(id).trim()
      : `auto_${++autoIdCounter}`;
    return new MockDocRef(this.name, resolvedId);
  }

  async get() {
    const store = collectionStore(this.name);
    const docs = Array.from(store.entries()).map(([id, data]) =>
      snapshot(this.name, id, data),
    );
    return {
      empty: docs.length === 0,
      size: docs.length,
      docs,
      forEach: (fn) => docs.forEach(fn),
    };
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
Object.defineProperty(admin.firestore, 'Timestamp', {
  configurable: true,
  writable: true,
  value: {
    fromMillis: (ms) => timestampFromMillis(ms),
    now: () => timestampFromMillis(Date.now()),
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
Object.defineProperty(admin, 'messaging', {
  configurable: true,
  writable: true,
  value: () => ({
    sendEachForMulticast: async () => ({ successCount: 0, failureCount: 0 }),
  }),
});

delete require.cache[require.resolve('../lib/index.js')];
const functions = require('../lib/index.js');

describe('REST call start rate limit contract', () => {
  let server;
  let baseUrl;

  async function sendRequest(path, options = {}) {
    const headers = { ...(options.headers || {}) };
    if (options.token !== null && options.token !== undefined) {
      headers.Authorization = `Bearer ${options.token ?? 'token-valid'}`;
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
    functions.__test__helpers.clearExpressRateLimitStore();

    collectionStore('users').set('user-valid', {
      email: 'valid@example.com',
      profile: { name: 'Valid User' },
    });
    collectionStore('users').set('user-target', {
      email: 'target@example.com',
      profile: { name: 'Target User' },
    });
    collectionStore('matches').set('match-1', {
      users: ['user-valid', 'user-target'],
    });
  });

  it('surfaces the shared 10-second initiation throttle on the REST lane', async () => {
    const first = await sendRequest('/v1/calls/start', {
      token: 'token-valid',
      body: {
        match_id: 'match-1',
        is_video: false,
      },
    });

    expect(first.status).to.equal(200);
    expect(first.json.call_id).to.be.a('string');
    expect(first.json.channel_name).to.equal(first.json.call_id);
    expect(first.json.local_uid).to.equal(0);
    expect(first.json.is_video).to.equal(false);
    expect(first.json.status).to.equal('ringing');
    expect(first.json.expires_at_ms).to.be.a('number');
    expect(collectionStore('calls').size).to.equal(1);
    expect(collectionStore('users/user-valid/callLimits').get('initiate')).to.not.equal(
      undefined,
    );

    const second = await sendRequest('/v1/calls/start', {
      token: 'token-valid',
      body: {
        match_id: 'match-1',
        is_video: true,
      },
    });

    expect(second.status).to.equal(429);
    expect(second.json.code).to.equal('resource-exhausted');
    expect(second.json.error).to.equal(
      'You can initiate only one call every 10 seconds.',
    );
    expect(collectionStore('calls').size).to.equal(1);
  });
});
