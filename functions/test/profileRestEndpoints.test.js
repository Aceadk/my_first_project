const { expect } = require('chai');
const http = require('http');
const admin = require('firebase-admin');

const users = new Map();
const matches = new Map();
const storageObjects = new Set();
const storageDeleteFailures = new Set();
const storageDeleteLog = [];
const storageSaveLog = [];
const storageMakePublicLog = [];
const DEFAULT_BUCKET = 'mock-bucket';

function storageKey(bucketName, objectPath) {
  return `${bucketName}/${objectPath}`;
}

function photoUrlForPath(objectPath, bucketName = DEFAULT_BUCKET) {
  return `https://storage.googleapis.com/${bucketName}/${objectPath}`;
}

function deepClone(value) {
  return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

// Sentinel returned by the mock FieldValue.delete() (mirrors admin
// FieldValue.delete()); the mock update() removes any key set to it.
const DELETE_SENTINEL = Symbol('firestore.delete');

function setByPath(target, path, value) {
  const parts = path.split('.');
  let cursor = target;
  for (let i = 0; i < parts.length - 1; i += 1) {
    const key = parts[i];
    if (typeof cursor[key] !== 'object' || cursor[key] === null) {
      cursor[key] = {};
    }
    cursor = cursor[key];
  }
  const leaf = parts[parts.length - 1];
  if (value === DELETE_SENTINEL) {
    delete cursor[leaf];
  } else {
    cursor[leaf] = value;
  }
}

class MockDocRef {
  constructor(collection, id) {
    this.collection = collection;
    this.id = id;
  }

  async get() {
    const data = this.collection.get(this.id);
    return {
      exists: data !== undefined,
      data: () => deepClone(data),
    };
  }

  async update(payload) {
    const current = this.collection.get(this.id);
    if (!current) {
      const err = new Error('Document not found');
      err.code = 5;
      throw err;
    }

    const next = deepClone(current) || {};
    Object.entries(payload || {}).forEach(([key, value]) => {
      if (key.includes('.')) {
        setByPath(next, key, value);
      } else if (value === DELETE_SENTINEL) {
        delete next[key];
      } else {
        next[key] = value;
      }
    });
    this.collection.set(this.id, next);
  }

  async set(payload, options = {}) {
    const current = this.collection.get(this.id);
    if (options.merge && current) {
      await this.update(payload);
      return;
    }
    this.collection.set(this.id, deepClone(payload) || {});
  }
}

class MockCollectionRef {
  constructor(name) {
    this.name = name;
  }

  doc(id) {
    if (this.name === 'users') {
      return new MockDocRef(users, id);
    }
    if (this.name === 'matches') {
      return new MockDocRef(matches, id);
    }
    throw new Error(`Unsupported collection in test mock: ${this.name}`);
  }
}

const mockFirestore = {
  collection(name) {
    return new MockCollectionRef(name);
  },
};

function buildStorageFile(bucketName, objectPath) {
  const key = storageKey(bucketName, objectPath);
  return {
    async save(data, options) {
      const size = Buffer.isBuffer(data) ? data.length : (data?.byteLength ?? 0);
      storageSaveLog.push({ key, size, metadata: options?.metadata || null });
      storageObjects.add(key);
    },
    async makePublic() {
      storageMakePublicLog.push(key);
    },
    async delete() {
      if (storageDeleteFailures.has(key)) {
        const err = new Error('Simulated storage delete failure');
        err.code = 'storage/internal-error';
        throw err;
      }
      storageDeleteLog.push(key);
      storageObjects.delete(key);
    },
  };
}

const mockStorage = {
  bucket(name = DEFAULT_BUCKET) {
    const bucketName = name;
    return {
      name: bucketName,
      file(objectPath) {
        return buildStorageFile(bucketName, objectPath);
      },
      async getFiles(options = {}) {
        const prefix = options.prefix || '';
        const files = Array.from(storageObjects)
          .filter((key) => key.startsWith(`${bucketName}/`))
          .map((key) => key.slice(bucketName.length + 1))
          .filter((objectPath) => objectPath.startsWith(prefix))
          .map((objectPath) => buildStorageFile(bucketName, objectPath));
        return [files];
      },
    };
  },
};

const decodedTokens = {
  'valid-token': {
    uid: 'user-1',
    email: 'user1@example.com',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  },
  'unverified-token': {
    uid: 'user-1',
    email: 'user1@example.com',
    email_verified: false,
    firebase: { sign_in_provider: 'password' },
  },
  'google-token': {
    uid: 'user-1',
    email: 'user1@example.com',
    email_verified: false,
    firebase: { sign_in_provider: 'google.com' },
  },
};

Object.defineProperty(admin, 'initializeApp', {
  configurable: true,
  writable: true,
  value: () => ({}),
});
const mockFirestoreAccessor = () => mockFirestore;
// index.ts reads admin.firestore.FieldValue.delete()/serverTimestamp(); expose a
// delete sentinel the mock update() honors. serverTimestamp is left unset so
// index.ts falls back to new Date() (unchanged behavior for other suites).
mockFirestoreAccessor.FieldValue = {
  delete: () => DELETE_SENTINEL,
};
Object.defineProperty(admin, 'firestore', {
  configurable: true,
  writable: true,
  value: mockFirestoreAccessor,
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
  value: () => mockStorage,
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

const functions = require('../lib/index.js');
const uploadTestHelpers = functions.__test__helpers;

describe('profile REST endpoints', () => {
  let server;
  let baseUrl;

  function detectMimeFromBytes(buffer) {
    if (!buffer || buffer.length === 0) return undefined;
    if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
      return { mime: 'image/jpeg', ext: 'jpg' };
    }
    if (
      buffer.length >= 8 &&
      buffer[0] === 0x89 &&
      buffer[1] === 0x50 &&
      buffer[2] === 0x4e &&
      buffer[3] === 0x47
    ) {
      return { mime: 'image/png', ext: 'png' };
    }
    if (
      buffer.length >= 6 &&
      String.fromCharCode(...buffer.slice(0, 6)) === 'GIF89a'
    ) {
      return { mime: 'image/gif', ext: 'gif' };
    }
    if (
      buffer.length >= 12 &&
      String.fromCharCode(...buffer.slice(4, 8)) === 'ftyp'
    ) {
      return { mime: 'video/mp4', ext: 'mp4' };
    }
    if (
      buffer.length >= 3 &&
      String.fromCharCode(...buffer.slice(0, 3)) === 'ID3'
    ) {
      return { mime: 'audio/mpeg', ext: 'mp3' };
    }
    return undefined;
  }

  function expectedAgeFor(dobIsoLike) {
    const dob = new Date(dobIsoLike);
    const now = new Date();
    let age = now.getFullYear() - dob.getFullYear();
    if (
      now.getMonth() < dob.getMonth() ||
      (now.getMonth() === dob.getMonth() && now.getDate() < dob.getDate())
    ) {
      age -= 1;
    }
    return age;
  }

  const defaultUserDoc = () => ({
    phoneNumber: '+15555550123',
    email: 'user1@example.com',
    emailVerified: true,
    plan: 'free',
    profile: {
      name: 'Test User',
      bio: 'Hello world',
      photoUrls: [],
      interests: [],
      prompts: [],
      preferences: {
        minAge: 18,
        maxAge: 50,
        showMyDistance: true,
      },
    },
  });

  const defaultMatchDoc = () => ({
    userIds: ['user-1', 'user-2'],
    createdAt: new Date().toISOString(),
  });

  async function sendRequest(method, path, options = {}) {
    const headers = {};
    if (options.token !== null) {
      headers.Authorization = `Bearer ${options.token || 'valid-token'}`;
    }
    if (options.body !== undefined) {
      headers['Content-Type'] = 'application/json';
    }

    const response = await fetch(`${baseUrl}${path}`, {
      method,
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });

    const text = await response.text();
    let json = null;
    if (text) {
      json = JSON.parse(text);
    }

    return { status: response.status, json };
  }

  async function sendMultipartRequest(path, options = {}) {
    const headers = {};
    if (options.token !== null) {
      headers.Authorization = `Bearer ${options.token || 'valid-token'}`;
    }

    const bytes = options.bytes || new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
    const mimeType = options.mimeType || 'image/jpeg';
    const fileName = options.fileName || 'photo.jpg';
    const fieldName = options.fieldName || 'photo';
    const form = new FormData();
    form.append(fieldName, new Blob([bytes], { type: mimeType }), fileName);
    if (options.isPrimary !== undefined) {
      form.append('is_primary', String(options.isPrimary));
    }
    Object.entries(options.fields || {}).forEach(([key, value]) => {
      form.append(key, String(value));
    });

    const response = await fetch(`${baseUrl}${path}`, {
      method: 'POST',
      headers,
      body: form,
    });

    const text = await response.text();
    let json = null;
    if (text) {
      json = JSON.parse(text);
    }

    return { status: response.status, json };
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
    users.clear();
    matches.clear();
    storageObjects.clear();
    storageDeleteFailures.clear();
    storageDeleteLog.length = 0;
    storageSaveLog.length = 0;
    storageMakePublicLog.length = 0;
    users.set('user-1', defaultUserDoc());
    matches.set('conversation-1', defaultMatchDoc());
    uploadTestHelpers.setUploadValidationTestOverrides({
      detectFileTypeFromBuffer: async (buffer) => detectMimeFromBytes(buffer),
      safeSearchImageContent: async () => [
        {
          safeSearchAnnotation: {
            adult: 'UNLIKELY',
            violence: 'UNLIKELY',
            medical: 'UNLIKELY',
            spoof: 'UNLIKELY',
          },
        },
      ],
      detectImageFaces: async () => [{ faceAnnotations: [{}] }],
    });
  });

  afterEach(() => {
    uploadTestHelpers.resetUploadValidationTestOverrides();
  });

  it('GET /v1/profile/me returns canonical nested profile.preferences', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      preferences: { minAge: 30, maxAge: 40 },
      profile: {
        ...defaultUserDoc().profile,
        preferences: { minAge: 21, maxAge: 35, showMyAge: true },
      },
    });

    const result = await sendRequest('GET', '/v1/profile/me');

    expect(result.status).to.equal(200);
    expect(result.json.preferences).to.deep.equal({
      minAge: 21,
      maxAge: 35,
      showMyAge: true,
    });
  });

  it('GET /v1/profile/me marks the canonical selected display photo', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        photoUrls: [
          'https://img.example.com/secondary.jpg',
          'https://img.example.com/main.jpg',
        ],
        primaryPhotoIndex: 1,
      },
    });

    const result = await sendRequest('GET', '/v1/profile/me');

    expect(result.status).to.equal(200);
    expect(result.json.photos).to.deep.equal([
      {
        id: 'photo_0',
        url: 'https://img.example.com/secondary.jpg',
        is_primary: false,
        order: 0,
      },
      {
        id: 'photo_1',
        url: 'https://img.example.com/main.jpg',
        is_primary: true,
        order: 1,
      },
    ]);
  });

  it('GET /v1/profile/me falls back to legacy top-level preferences', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      preferences: { minAge: 26, maxAge: 39 },
      profile: {
        ...defaultUserDoc().profile,
        preferences: {},
      },
    });

    const result = await sendRequest('GET', '/v1/profile/me');

    expect(result.status).to.equal(200);
    expect(result.json.preferences).to.deep.equal({
      minAge: 26,
      maxAge: 39,
    });
  });

  it('GET /v1/profile/me serializes birth_date from legacy dateOfBirth fallback', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        dateOfBirth: '1994-02-10T00:00:00.000Z',
      },
    });

    const result = await sendRequest('GET', '/v1/profile/me');

    expect(result.status).to.equal(200);
    expect(result.json.birth_date).to.equal('1994-02-10T00:00:00.000Z');
  });

  it('GET /v1/profile/me derives prompts from canonical profilePrompts', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        prompts: [],
        profilePrompts: [
          { questionId: 'looking_for', answer: 'Someone kind' },
          { questionId: 'perfect_date', answer: 'Coffee and bookstores' },
        ],
      },
    });

    const result = await sendRequest('GET', '/v1/profile/me');

    expect(result.status).to.equal(200);
    expect(result.json.prompts).to.deep.equal([
      'Someone kind',
      'Coffee and bookstores',
    ]);
  });

  it('GET /v1/profile/me returns canonical username separately from display_name', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      username: 'ace_handle',
      profile: {
        ...defaultUserDoc().profile,
        name: 'Ace Display',
      },
    });

    const result = await sendRequest('GET', '/v1/profile/me');

    expect(result.status).to.equal(200);
    expect(result.json.username).to.equal('ace_handle');
    expect(result.json.display_name).to.equal('Ace Display');
  });

  it('GET /v1/profile/me falls back username to legacy profile.username', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        username: 'legacy_profile_username',
      },
    });

    const result = await sendRequest('GET', '/v1/profile/me');

    expect(result.status).to.equal(200);
    expect(result.json.username).to.equal('legacy_profile_username');
  });

  it('GET /v1/profile/me requires authenticated access', async () => {
    const result = await sendRequest('GET', '/v1/profile/me', { token: null });

    expect(result.status).to.equal(401);
    expect(result.json.error).to.match(/missing authorization header/i);
  });

  it('PATCH /v1/profile/me rejects unsupported fields with 400', async () => {
    const result = await sendRequest('PATCH', '/v1/profile/me', {
      body: { unsupported_field: true },
    });

    expect(result.status).to.equal(400);
    expect(result.json.code).to.equal('invalid-argument');
  });

  it('PATCH /v1/profile/me maps underage DOB failure to 412', async () => {
    const recentDob = `${new Date().getFullYear()}-01-01`;
    const result = await sendRequest('PATCH', '/v1/profile/me', {
      body: { birth_date: recentDob },
    });

    expect(result.status).to.equal(412);
    expect(result.json.code).to.equal('failed-precondition');
  });

  it('PATCH /v1/profile/me applies validated updates', async () => {
    const result = await sendRequest('PATCH', '/v1/profile/me', {
      body: {
        display_name: '  Alice Example  ',
        gender: 'Female',
        interests: ['Music', 'Travel'],
        city: 'New York',
      },
    });

    expect(result.status).to.equal(200);
    expect(result.json.success).to.equal(true);

    const updated = users.get('user-1');
    expect(updated.profile.name).to.equal('Alice Example');
    expect(updated.profile.gender).to.equal('female');
    expect(updated.profile.interests).to.deep.equal(['Music', 'Travel']);
    expect(updated.profile.city).to.equal('New York');
  });

  it('PATCH /v1/profile/preferences merges with existing canonical preferences', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        preferences: {
          minAge: 20,
          maxAge: 45,
          showMyDistance: true,
        },
      },
    });

    const result = await sendRequest('PATCH', '/v1/profile/preferences', {
      body: { maxAge: 35, hideFromDiscovery: true },
    });

    expect(result.status).to.equal(200);
    expect(result.json.preferences).to.deep.equal({
      minAge: 20,
      maxAge: 35,
      showMyDistance: true,
      hideFromDiscovery: true,
    });

    const updated = users.get('user-1');
    expect(updated.profile.preferences).to.deep.equal(result.json.preferences);
    // Canonical behavior: the legacy top-level `preferences` mirror is removed.
    expect(updated.preferences).to.equal(undefined);
  });

  it('PATCH /v1/profile/preferences merges with legacy top-level preferences fallback', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      preferences: {
        minAge: 24,
        maxAge: 42,
        showMyDistance: true,
      },
      profile: {
        ...defaultUserDoc().profile,
        preferences: {},
      },
    });

    const result = await sendRequest('PATCH', '/v1/profile/preferences', {
      body: { showMyAge: false },
    });

    expect(result.status).to.equal(200);
    expect(result.json.preferences).to.deep.equal({
      minAge: 24,
      maxAge: 42,
      showMyDistance: true,
      showMyAge: false,
    });

    const updated = users.get('user-1');
    expect(updated.profile.preferences).to.deep.equal(result.json.preferences);
    // Canonical behavior: the legacy top-level `preferences` mirror is removed.
    expect(updated.preferences).to.equal(undefined);
  });

  it('PATCH /v1/profile/preferences rejects invalid merged min/max age', async () => {
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        preferences: {
          minAge: 30,
          maxAge: 50,
        },
      },
    });

    const result = await sendRequest('PATCH', '/v1/profile/preferences', {
      body: { maxAge: 25 },
    });

    expect(result.status).to.equal(400);
    expect(result.json.code).to.equal('invalid-argument');
  });

  it('PATCH /v1/profile/preferences rejects unsupported fields with 400', async () => {
    const result = await sendRequest('PATCH', '/v1/profile/preferences', {
      body: { unsupportedField: true },
    });

    expect(result.status).to.equal(400);
    expect(result.json.code).to.equal('invalid-argument');
  });

  it('PATCH /v1/profile/preferences requires authenticated access', async () => {
    const result = await sendRequest('PATCH', '/v1/profile/preferences', {
      token: null,
      body: { maxAge: 30 },
    });

    expect(result.status).to.equal(401);
    expect(result.json.error).to.match(/missing authorization header/i);
  });

  it('PATCH /v1/profile/preferences returns 404 when user is missing', async () => {
    users.delete('user-1');

    const result = await sendRequest('PATCH', '/v1/profile/preferences', {
      body: { maxAge: 30 },
    });

    expect(result.status).to.equal(404);
    expect(result.json.code).to.equal('not-found');
  });

  it('PATCH /v1/profile/me blocks unverified email/password users', async () => {
    const result = await sendRequest('PATCH', '/v1/profile/me', {
      token: 'unverified-token',
      body: { city: 'Boston' },
    });

    expect(result.status).to.equal(403);
    expect(result.json.error).to.match(/email verification required/i);
  });

  it('POST /v1/profile/photos uploads allowed image with randomized private filename', async () => {
    const result = await sendMultipartRequest('/v1/profile/photos', {
      mimeType: 'image/jpeg',
      fileName: 'my_profile_photo.jpg',
      isPrimary: true,
    });

    expect(result.status).to.equal(200);
    expect(result.json.url).to.match(
      /^https:\/\/firebasestorage\.googleapis\.com\/v0\/b\/mock-bucket\/o\/photos%2Fuser-1%2F/
    );
    expect(result.json.url).to.match(/token=/);
    expect(storageObjects.size).to.equal(1);
    const [savedObjectKey] = Array.from(storageObjects);
    expect(savedObjectKey).to.match(/^mock-bucket\/photos\/user-1\/\d+_[0-9a-f-]{36}\.jpg$/);
    expect(savedObjectKey).to.not.include('my_profile_photo');
    expect(storageMakePublicLog).to.deep.equal([]);
    expect(storageSaveLog).to.have.lengthOf(1);
    expect(storageSaveLog[0].metadata).to.have.nested.property('metadata.firebaseStorageDownloadTokens');
    const updated = users.get('user-1');
    expect(updated.profile.photoUrls).to.deep.equal([result.json.url]);
    expect(updated.profile.primaryPhotoIndex).to.equal(0);
  });

  it('POST /v1/profile/photos rejects unsupported mime types', async () => {
    const result = await sendMultipartRequest('/v1/profile/photos', {
      mimeType: 'text/plain',
      fileName: 'bad.txt',
      bytes: new TextEncoder().encode('hello'),
    });

    expect(result.status).to.equal(415);
    expect(result.json.error).to.match(/unsupported photo type/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
    expect(users.get('user-1').profile.photoUrls).to.deep.equal([]);
  });

  it('POST /v1/profile/photos rejects spoofed magic bytes even when client mime is allowed', async () => {
    const result = await sendMultipartRequest('/v1/profile/photos', {
      mimeType: 'image/jpeg',
      fileName: 'spoofed.jpg',
      bytes: new TextEncoder().encode('not-an-image'),
    });

    expect(result.status).to.equal(415);
    expect(result.json.error).to.match(/magic bytes/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
  });

  it('POST /v1/profile/photos rejects oversize uploads', async () => {
    const tooLarge = new Uint8Array(10 * 1024 * 1024 + 1);
    const result = await sendMultipartRequest('/v1/profile/photos', {
      mimeType: 'image/png',
      fileName: 'large.png',
      bytes: tooLarge,
    });

    expect(result.status).to.equal(413);
    expect(result.json.error).to.match(/exceeds maximum size/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
  });

  it('POST /v1/profile/photos requires authenticated access', async () => {
    const result = await sendMultipartRequest('/v1/profile/photos', {
      token: null,
      mimeType: 'image/jpeg',
      fileName: 'no-auth.jpg',
    });

    expect(result.status).to.equal(401);
    expect(result.json.error).to.match(/authorization/i);
  });

  it('POST /v1/profile/photos blocks unverified email/password users', async () => {
    const result = await sendMultipartRequest('/v1/profile/photos', {
      token: 'unverified-token',
      mimeType: 'image/jpeg',
      fileName: 'unverified.jpg',
    });

    expect(result.status).to.equal(403);
    expect(result.json.error).to.match(/email verification required/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
  });

  it('POST /v1/profile/photos returns 404 when user is missing', async () => {
    users.delete('user-1');

    const result = await sendMultipartRequest('/v1/profile/photos', {
      mimeType: 'image/jpeg',
      fileName: 'missing-user.jpg',
    });

    expect(result.status).to.equal(404);
    expect(result.json.error).to.match(/user not found/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
  });

  it('POST /v1/chat/:conversationId/media uploads allowed image for a match participant with private randomized storage path', async () => {
    const result = await sendMultipartRequest('/v1/chat/conversation-1/media', {
      fieldName: 'media',
      mimeType: 'image/jpeg',
      fileName: 'secret_photo.jpg',
      fields: { type: 'image' },
    });

    expect(result.status).to.equal(200);
    expect(result.json.url).to.match(
      /^https:\/\/firebasestorage\.googleapis\.com\/v0\/b\/mock-bucket\/o\/chat_media%2Fuser-1%2Fconversation-1%2F/
    );
    expect(result.json.url).to.match(/token=/);
    expect(storageObjects.size).to.equal(1);
    const [savedObjectKey] = Array.from(storageObjects);
    expect(savedObjectKey).to.match(
      /^mock-bucket\/chat_media\/user-1\/conversation-1\/\d+_[0-9a-f-]{36}\.jpg$/
    );
    expect(savedObjectKey).to.not.include('secret_photo');
    expect(storageMakePublicLog).to.deep.equal([]);
    expect(storageSaveLog).to.have.lengthOf(1);
    expect(storageSaveLog[0].metadata).to.have.nested.property(
      'metadata.firebaseStorageDownloadTokens'
    );
  });

  it('POST /v1/chat/:conversationId/media rejects users outside the match', async () => {
    matches.set('conversation-1', {
      ...defaultMatchDoc(),
      userIds: ['user-2', 'user-3'],
    });

    const result = await sendMultipartRequest('/v1/chat/conversation-1/media', {
      fieldName: 'media',
      mimeType: 'image/jpeg',
      fileName: 'blocked.jpg',
      fields: { type: 'image' },
    });

    expect(result.status).to.equal(403);
    expect(result.json.error).to.match(/not part of this match/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
  });

  it('POST /v1/chat/:conversationId/media rejects spoofed media payloads', async () => {
    const result = await sendMultipartRequest('/v1/chat/conversation-1/media', {
      fieldName: 'media',
      mimeType: 'image/jpeg',
      fileName: 'spoofed.jpg',
      bytes: new TextEncoder().encode('definitely-not-an-image'),
      fields: { type: 'image' },
    });

    expect(result.status).to.equal(415);
    expect(result.json.error).to.match(/magic bytes/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
  });

  it('POST /v1/chat/:conversationId/media rejects image uploads above the per-type size limit', async () => {
    const tooLarge = new Uint8Array(25 * 1024 * 1024 + 1);
    tooLarge[0] = 0xff;
    tooLarge[1] = 0xd8;
    tooLarge[2] = 0xff;

    const result = await sendMultipartRequest('/v1/chat/conversation-1/media', {
      fieldName: 'media',
      mimeType: 'image/jpeg',
      fileName: 'too-large.jpg',
      bytes: tooLarge,
      fields: { type: 'image' },
    });

    expect(result.status).to.equal(413);
    expect(result.json.error).to.match(/maximum size/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
  });

  it('POST /v1/chat/:conversationId/media rejects missing or unsupported media type fields', async () => {
    const result = await sendMultipartRequest('/v1/chat/conversation-1/media', {
      fieldName: 'media',
      mimeType: 'image/jpeg',
      fileName: 'bad-type.jpg',
      fields: { type: 'document' },
    });

    expect(result.status).to.equal(400);
    expect(result.json.error).to.match(/media type must be one of/i);
    expect(storageObjects.size).to.equal(0);
    expect(storageSaveLog).to.have.lengthOf(0);
  });

  it('DELETE /v1/profile/photos/:photoId deletes storage object and updates profile list', async () => {
    const firstPhotoPath = 'photos/user-1/first.jpg';
    const secondPhotoPath = 'photos/user-1/second.jpg';
    const firstPhotoUrl = photoUrlForPath(firstPhotoPath);
    const secondPhotoUrl = photoUrlForPath(secondPhotoPath);
    storageObjects.add(storageKey(DEFAULT_BUCKET, firstPhotoPath));
    storageObjects.add(storageKey(DEFAULT_BUCKET, secondPhotoPath));

    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        photoUrls: [firstPhotoUrl, secondPhotoUrl],
      },
    });

    const result = await sendRequest('DELETE', '/v1/profile/photos/photo_0');

    expect(result.status).to.equal(200);
    expect(result.json.success).to.equal(true);
    const updated = users.get('user-1');
    expect(updated.profile.photoUrls).to.deep.equal([secondPhotoUrl]);
    expect(storageDeleteLog).to.include(storageKey(DEFAULT_BUCKET, firstPhotoPath));
    expect(storageObjects.has(storageKey(DEFAULT_BUCKET, firstPhotoPath))).to.equal(false);
  });

  it('DELETE /v1/profile/photos/:photoId keeps the same primary photo selected', async () => {
    const photoPaths = [
      'photos/user-1/first.jpg',
      'photos/user-1/main.jpg',
      'photos/user-1/last.jpg',
    ];
    const photoUrls = photoPaths.map((path) => photoUrlForPath(path));
    photoPaths.forEach((path) =>
      storageObjects.add(storageKey(DEFAULT_BUCKET, path))
    );
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        photoUrls,
        primaryPhotoIndex: 1,
      },
    });

    const result = await sendRequest('DELETE', '/v1/profile/photos/photo_0');

    expect(result.status).to.equal(200);
    const updated = users.get('user-1');
    expect(updated.profile.photoUrls).to.deep.equal(photoUrls.slice(1));
    expect(updated.profile.primaryPhotoIndex).to.equal(0);
    expect(updated.profile.photoUrls[updated.profile.primaryPhotoIndex]).to.equal(
      photoUrls[1]
    );
  });

  it('DELETE /v1/profile/photos/:photoId rejects invalid photo indexes', async () => {
    const onlyPhotoPath = 'photos/user-1/only.jpg';
    const onlyPhotoUrl = photoUrlForPath(onlyPhotoPath);
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        photoUrls: [onlyPhotoUrl],
      },
    });

    const result = await sendRequest('DELETE', '/v1/profile/photos/photo_-1');

    expect(result.status).to.equal(400);
    expect(result.json.error).to.match(/invalid photoid format/i);
    expect(users.get('user-1').profile.photoUrls).to.deep.equal([onlyPhotoUrl]);
  });

  it('DELETE /v1/profile/photos/:photoId returns 404 for repeated deletes', async () => {
    const onlyPhotoPath = 'photos/user-1/once.jpg';
    const onlyPhotoUrl = photoUrlForPath(onlyPhotoPath);
    storageObjects.add(storageKey(DEFAULT_BUCKET, onlyPhotoPath));
    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        photoUrls: [onlyPhotoUrl],
      },
    });

    const firstDelete = await sendRequest('DELETE', '/v1/profile/photos/photo_0');
    const secondDelete = await sendRequest('DELETE', '/v1/profile/photos/photo_0');

    expect(firstDelete.status).to.equal(200);
    expect(secondDelete.status).to.equal(404);
    expect(secondDelete.json.error).to.match(/photo not found/i);
  });

  it('DELETE /v1/profile/photos/:photoId keeps firestore unchanged when storage delete fails', async () => {
    const failingPhotoPath = 'photos/user-1/fail.jpg';
    const secondPhotoPath = 'photos/user-1/keep.jpg';
    const failingPhotoUrl = photoUrlForPath(failingPhotoPath);
    const secondPhotoUrl = photoUrlForPath(secondPhotoPath);
    const failingStorageKey = storageKey(DEFAULT_BUCKET, failingPhotoPath);
    storageObjects.add(failingStorageKey);
    storageObjects.add(storageKey(DEFAULT_BUCKET, secondPhotoPath));
    storageDeleteFailures.add(failingStorageKey);

    users.set('user-1', {
      ...defaultUserDoc(),
      profile: {
        ...defaultUserDoc().profile,
        photoUrls: [failingPhotoUrl, secondPhotoUrl],
      },
    });

    const result = await sendRequest('DELETE', '/v1/profile/photos/photo_0');

    expect(result.status).to.equal(502);
    expect(result.json.error).to.match(/failed to delete photo from storage/i);
    const updated = users.get('user-1');
    expect(updated.profile.photoUrls).to.deep.equal([failingPhotoUrl, secondPhotoUrl]);
    expect(storageDeleteLog).to.not.include(failingStorageKey);
    expect(storageObjects.has(failingStorageKey)).to.equal(true);
  });

  it('DELETE /v1/profile/photos/:photoId requires authenticated access', async () => {
    const result = await sendRequest('DELETE', '/v1/profile/photos/photo_0', {
      token: null,
    });

    expect(result.status).to.equal(401);
    expect(result.json.error).to.match(/missing authorization header/i);
  });

  it('DELETE /v1/profile/photos/:photoId returns 404 when user is missing', async () => {
    users.delete('user-1');

    const result = await sendRequest('DELETE', '/v1/profile/photos/photo_0');

    expect(result.status).to.equal(404);
    expect(result.json.error).to.match(/user not found/i);
  });

  it('GET /v1/profile/:userId derives age from birthDate when stored age is stale', async () => {
    users.set('user-2', {
      phoneNumber: '+15555551234',
      email: 'user2@example.com',
      profile: {
        name: 'Bob',
        age: 99,
        birthDate: '1996-08-14T00:00:00.000Z',
        gender: 'male',
        city: 'Chicago',
        photoUrls: [],
        interests: ['music'],
        prompts: [],
      },
    });

    const result = await sendRequest('GET', '/v1/profile/user-2');

    expect(result.status).to.equal(200);
    expect(result.json.birth_date).to.equal('1996-08-14T00:00:00.000Z');
    expect(result.json.age).to.equal(expectedAgeFor('1996-08-14T00:00:00.000Z'));
  });

  it('GET /v1/profile/:userId derives prompts from canonical profilePrompts', async () => {
    users.set('user-2', {
      phoneNumber: '+15555551234',
      email: 'user2@example.com',
      profile: {
        name: 'Bob',
        gender: 'male',
        city: 'Chicago',
        photoUrls: [],
        interests: ['music'],
        prompts: [],
        profilePrompts: [
          { questionId: 'looking_for', answer: 'Curious minds' },
          { questionId: 'simple_pleasure', answer: 'Long walks' },
        ],
      },
    });

    const result = await sendRequest('GET', '/v1/profile/user-2');

    expect(result.status).to.equal(200);
    expect(result.json.prompts).to.deep.equal(['Curious minds', 'Long walks']);
  });

  it('GET /v1/profile/:userId serializes birth_date from legacy dateOfBirth fallback', async () => {
    users.set('user-2', {
      phoneNumber: '+15555551234',
      email: 'user2@example.com',
      profile: {
        name: 'Bob',
        age: 99,
        dateOfBirth: '1999-11-20T00:00:00.000Z',
        gender: 'male',
        city: 'Chicago',
        photoUrls: [],
        interests: ['music'],
        prompts: [],
      },
    });

    const result = await sendRequest('GET', '/v1/profile/user-2');

    expect(result.status).to.equal(200);
    expect(result.json.birth_date).to.equal('1999-11-20T00:00:00.000Z');
    expect(result.json.age).to.equal(expectedAgeFor('1999-11-20T00:00:00.000Z'));
  });

  it('GET /v1/profile/:userId falls back to legacy prompts', async () => {
    users.set('user-2', {
      phoneNumber: '+15555551234',
      email: 'user2@example.com',
      profile: {
        name: 'Bob',
        gender: 'male',
        city: 'Chicago',
        photoUrls: [],
        interests: ['music'],
        prompts: ['Legacy prompt one', 'Legacy prompt two'],
      },
    });

    const result = await sendRequest('GET', '/v1/profile/user-2');

    expect(result.status).to.equal(200);
    expect(result.json.prompts).to.deep.equal([
      'Legacy prompt one',
      'Legacy prompt two',
    ]);
  });

  it('GET /v1/profile/:userId requires authenticated access', async () => {
    const result = await sendRequest('GET', '/v1/profile/user-2', {
      token: null,
    });

    expect(result.status).to.equal(401);
    expect(result.json.error).to.match(/missing authorization header/i);
  });

  it('GET /v1/profile/:userId returns 404 for unknown users', async () => {
    const result = await sendRequest('GET', '/v1/profile/unknown-user');

    expect(result.status).to.equal(404);
    expect(result.json.error).to.match(/user not found/i);
  });
});
