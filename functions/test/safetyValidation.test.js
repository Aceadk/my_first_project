const { expect } = require('chai');
const { https: httpsFns } = require('firebase-functions/v1');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('safety REST validation helpers', () => {
  const {
    validateSafetyTargetId,
    assertNotSelfSafetyAction,
    validateSafetyReportReason,
    validateOptionalSafetyDescription,
  } = functions.__test__helpers;

  it('validates and trims safety target ids', () => {
    expect(validateSafetyTargetId('  user-123  ', 'blocked_id')).to.equal('user-123');
  });

  it('rejects blank safety target ids', () => {
    try {
      validateSafetyTargetId('   ', 'reported_id');
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/reported_id is required/i);
    }
  });

  it('rejects self-target safety actions', () => {
    try {
      assertNotSelfSafetyAction('user-1', 'user-1', 'block');
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/cannot block yourself/i);
    }
  });

  it('sanitizes report reasons and enforces minimum length', () => {
    expect(validateSafetyReportReason('  <b>Scam profile</b>  ')).to.equal('Scam profile');

    try {
      validateSafetyReportReason('ok');
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/at least 3 characters/i);
    }
  });

  it('sanitizes optional safety descriptions and enforces max length', () => {
    expect(validateOptionalSafetyDescription('')).to.equal(null);
    expect(validateOptionalSafetyDescription('  ')).to.equal(null);
    expect(validateOptionalSafetyDescription(' <i>extra details</i> ')).to.equal('extra details');

    const tooLong = 'a'.repeat(2001);
    try {
      validateOptionalSafetyDescription(tooLong);
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/maximum length of 2000/i);
    }
  });
});
