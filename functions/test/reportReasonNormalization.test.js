const { expect } = require('chai');
const { https: httpsFns } = require('firebase-functions/v1');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('report reason taxonomy normalization', () => {
  const {
    inferReportCategoryFromReason,
    canonicalizeSafetyReportReason,
  } = functions.__test__helpers;

  it('maps chat/call/profile reason labels to canonical categories', () => {
    expect(inferReportCategoryFromReason('Spam or scams')).to.equal('scam');
    expect(inferReportCategoryFromReason('Scam or spam')).to.equal('scam');
    expect(inferReportCategoryFromReason('Harassment or hate')).to.equal('hate_speech');
    expect(inferReportCategoryFromReason('Inappropriate content')).to.equal('inappropriate_content');
    expect(inferReportCategoryFromReason('Inappropriate photos')).to.equal('inappropriate_content');
    expect(inferReportCategoryFromReason('Fake profile')).to.equal('fake_profile');
    expect(inferReportCategoryFromReason('Underage user')).to.equal('underage');
    expect(inferReportCategoryFromReason('Other')).to.equal('other');
  });

  it('canonicalizes reason text and returns inferred category', () => {
    const normalized = canonicalizeSafetyReportReason(' <b>Scam or spam</b> ', {
      maxLength: 280,
      minLength: 3,
    });

    expect(normalized).to.deep.equal({
      reasonText: 'Scam or spam',
      reasonCategory: 'scam',
    });
  });

  it('rejects reasons shorter than required min length', () => {
    try {
      canonicalizeSafetyReportReason('ok', { minLength: 3 });
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/at least 3 characters/i);
    }
  });
});
