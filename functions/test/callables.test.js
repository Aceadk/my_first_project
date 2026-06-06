const { expect } = require('chai');
const functionsTest = require('firebase-functions-test')();
const { https: httpsFns } = require('firebase-functions/v1');

// Use compiled functions output
const functions = require('../lib/index.js');

describe('callables auth/args', () => {
  after(() => functionsTest.cleanup());

  it('requireAuth rejects missing auth', () => {
    const { requireAuth } = functions.__test__helpers;
    expect(() => requireAuth({}, 'do something')).to.throw(httpsFns.HttpsError).with.property('code', 'unauthenticated');
  });

  it('requireAuth returns uid when present', () => {
    const { requireAuth } = functions.__test__helpers;
    const uid = requireAuth({ auth: { uid: 'user-1' } }, 'test');
    expect(uid).to.equal('user-1');
  });

  it('requireString enforces non-empty values', () => {
    const { requireString, optionalString } = functions.__test__helpers;
    expect(() => requireString('   ', 'field')).to.throw(httpsFns.HttpsError).with.property('code', 'invalid-argument');
    expect(requireString(' value ', 'field')).to.equal('value');
    expect(optionalString('  ')).to.be.undefined;
    expect(optionalString(' hi ')).to.equal('hi');
  });

  it('swipeLeft rejects unauthenticated calls', async () => {
    const wrapped = functionsTest.wrap(functions.swipeLeft);
    try {
      await wrapped({ targetUserId: 'other' }, { auth: null });
      throw new Error('Expected unauthenticated error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('unauthenticated');
    }
  });

  it('unsendMessage validates required ids before hitting backend', async () => {
    const wrapped = functionsTest.wrap(functions.unsendMessage);
    try {
      await wrapped({}, { auth: { uid: 'user-1' } });
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
    }
  });

  it('createCheckoutSession requires auth', async () => {
    const wrapped = functionsTest.wrap(functions.createCheckoutSession);
    try {
      await wrapped({}, { auth: null });
      throw new Error('Expected unauthenticated error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('unauthenticated');
    }
  });

  it('requestAccountDeletion requires auth before scheduling deletion', async () => {
    const wrapped = functionsTest.wrap(functions.requestAccountDeletion);
    try {
      await wrapped({ reason: 'privacy' }, { auth: null });
      throw new Error('Expected unauthenticated error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('unauthenticated');
    }
  });

  it('requestDataExport requires auth before creating an export job', async () => {
    const wrapped = functionsTest.wrap(functions.requestDataExport);
    try {
      await wrapped({}, { auth: null });
      throw new Error('Expected unauthenticated error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('unauthenticated');
    }
  });

  it('requestDataExport requires verified email for password users', async () => {
    const wrapped = functionsTest.wrap(functions.requestDataExport);
    try {
      await wrapped({}, {
        auth: {
          uid: 'user-1',
          token: {
            email: 'user@example.com',
            email_verified: false,
            firebase: { sign_in_provider: 'password' },
          },
        },
      });
      throw new Error('Expected permission-denied error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('permission-denied');
    }
  });

  it('verifyPurchaseReceipt requires auth', async () => {
    const wrapped = functionsTest.wrap(functions.verifyPurchaseReceipt);
    try {
      await wrapped({ platform: 'ios', receiptData: 'tx-1' }, { auth: null });
      throw new Error('Expected unauthenticated error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('unauthenticated');
    }
  });

  it('getAgoraToken requires auth', async () => {
    const wrapped = functionsTest.wrap(functions.getAgoraToken);
    try {
      await wrapped({ channelName: 'room-1' }, { auth: null });
      throw new Error('Expected unauthenticated error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('unauthenticated');
    }
  });

  it('setMatchPinned rejects unauthenticated calls', async () => {
    const wrapped = functionsTest.wrap(functions.setMatchPinned);
    try {
      await wrapped({ matchId: 'm-1', pinned: true }, { auth: null });
      throw new Error('Expected unauthenticated error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('unauthenticated');
    }
  });

  it('setMatchPinned validates required matchId', async () => {
    const wrapped = functionsTest.wrap(functions.setMatchPinned);
    try {
      await wrapped({ pinned: true }, { auth: { uid: 'user-1' } });
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
    }
  });
});
