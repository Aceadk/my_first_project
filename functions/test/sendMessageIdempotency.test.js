const { expect } = require('chai');
const { https: httpsFns } = require('firebase-functions/v1');

// Self-sufficient: provide a demo FIREBASE_CONFIG before require so
// admin.initializeApp() succeeds offline (same pattern as accountDeletionMap).
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('sendMessage idempotency helpers (Gate 2 / offline-queue follow-up)', () => {
  const { validateClientMessageId, isAlreadyExistsError } =
    functions.__test__helpers;

  describe('validateClientMessageId', () => {
    it('accepts a safe single-segment id', () => {
      expect(validateClientMessageId('abc-123_DEF')).to.equal('abc-123_DEF');
      expect(validateClientMessageId('a'.repeat(128))).to.have.length(128);
    });

    it('treats empty/undefined/null as "not provided"', () => {
      expect(validateClientMessageId(undefined)).to.be.undefined;
      expect(validateClientMessageId(null)).to.be.undefined;
      expect(validateClientMessageId('')).to.be.undefined;
    });

    it('rejects unsafe ids (slashes, dots, spaces, too long, non-string)', () => {
      for (const bad of [
        'has/slash',
        '..',
        '.',
        'has space',
        'a'.repeat(129),
        123,
        {},
      ]) {
        expect(() => validateClientMessageId(bad), JSON.stringify(bad))
          .to.throw(httpsFns.HttpsError)
          .with.property('code', 'invalid-argument');
      }
    });
  });

  describe('isAlreadyExistsError', () => {
    it('detects Firestore ALREADY_EXISTS in its forms', () => {
      expect(isAlreadyExistsError({ code: 6 })).to.equal(true);
      expect(isAlreadyExistsError({ code: 'already-exists' })).to.equal(true);
      expect(isAlreadyExistsError({ code: 'ALREADY_EXISTS' })).to.equal(true);
    });

    it('returns false for other/missing codes', () => {
      expect(isAlreadyExistsError({ code: 5 })).to.equal(false);
      expect(isAlreadyExistsError(new Error('boom'))).to.equal(false);
      expect(isAlreadyExistsError(null)).to.equal(false);
    });
  });
});

describe('message moderation (Gate 2 follow-up — onMessageCreated path)', () => {
  const { moderateContent } = functions.__test__helpers;

  it('holds prohibited text content', () => {
    // moderateContent is what the onMessageCreated trigger applies to every
    // matches/{matchId}/messages doc.
    const clean = moderateContent('hey want to grab coffee?', 'text');
    expect(clean.status).to.equal('clean');
    expect(clean.action).to.equal('allow');
  });

  it('flags non-text for an async scan', () => {
    const decision = moderateContent('', 'image');
    expect(decision.action).to.equal('scan');
    expect(decision.status).to.equal('pending_scan');
  });
});
