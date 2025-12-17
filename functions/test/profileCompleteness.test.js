const { expect } = require('chai');
const { https: httpsFns } = require('firebase-functions/v1');
const functions = require('../lib/index.js');

describe('profile completeness helpers', () => {
  const { evaluateProfileCompleteness, ensureProfileQuality } =
    functions.__test__helpers;

  it('returns full score for a complete profile', () => {
    const profile = {
      photoUrls: ['a.jpg', 'b.jpg'],
      bio: 'This is a long enough bio that easily clears forty characters.',
      prompts: ['Prompt answer 1', 'Prompt answer 2'],
      interests: ['music', 'travel', 'food'],
      jobTitle: 'Engineer',
      country: 'US',
      city: 'New York',
      latitude: 0,
      longitude: 0,
    };

    const result = evaluateProfileCompleteness(profile);
    expect(result.score).to.equal(1);
    expect(result.missing).to.be.empty;
    expect(result.requiredMissing).to.be.empty;
    expect(result.meetsSwipeMinimum).to.be.true;
    expect(result.meetsMessagingMinimum).to.be.true;
    expect(result.meetsRequiredFields).to.be.true;
  });

  it('captures optional fields without blocking messaging', () => {
    const profile = {
      photoUrls: ['one.jpg'],
      bio: 'This is a sufficiently long bio for gating checks.',
      prompts: ['Prompt answer 1', 'Prompt answer 2'],
      interests: [],
      jobTitle: null,
      company: null,
      school: null,
      country: 'US',
      city: 'NYC',
    };

    const result = evaluateProfileCompleteness(profile);
    expect(result.score).to.be.greaterThan(0.79);
    expect(result.score).to.be.lessThan(0.9);
    expect(result.requiredMissing).to.be.empty;
    expect(result.missing).to.include('Add at least 3 interests.');
    expect(result.missing).to.include('Add work or school.');
    expect(result.meetsMessagingMinimum).to.be.true;
  });

  it('throws with a failed-precondition error when required pieces are missing', () => {
    const incomplete = {
      photoUrls: [],
      bio: 'too short',
      prompts: ['one'],
      interests: [],
      country: '',
      city: '',
    };

    try {
      ensureProfileQuality(incomplete, 'swiping', 'swipe');
      throw new Error('expected ensureProfileQuality to throw');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('failed-precondition');
      expect(err.message).to.match(/Complete your profile before swiping/i);
      expect(err.message).to.match(/Add at least 1 photo/i);
      expect(err.message).to.match(/Write a bio/i);
    }
  });
});
