const { expect } = require('chai');
const { https: httpsFns } = require('firebase-functions/v1');
const functions = require('../lib/index.js');

describe('profile REST validation helpers', () => {
  const {
    validateProfilePatchPayload,
    validateProfilePreferencesPayload,
    getCanonicalProfilePreferences,
    deriveProfileAge,
    profileBirthDateIso,
    profilePromptAnswers,
  } = functions.__test__helpers;

  it('uses nested profile.preferences over legacy top-level preferences', () => {
    const canonical = getCanonicalProfilePreferences({
      preferences: { minAge: 30, maxAge: 45 },
      profile: {
        preferences: { minAge: 21, maxAge: 35, showMyAge: true },
      },
    });

    expect(canonical).to.deep.equal({
      minAge: 21,
      maxAge: 35,
      showMyAge: true,
    });
  });

  it('falls back to top-level preferences when nested preferences are absent', () => {
    const canonical = getCanonicalProfilePreferences({
      preferences: { minAge: 25, maxAge: 40 },
      profile: {},
    });

    expect(canonical).to.deep.equal({ minAge: 25, maxAge: 40 });
  });

  it('rejects unsupported profile patch fields', () => {
    try {
      validateProfilePatchPayload({
        display_name: 'Alice',
        unsafe_field: 'oops',
      });
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/unsupported profile field/i);
    }
  });

  it('validates and maps profile patch payload fields', () => {
    const updates = validateProfilePatchPayload({
      display_name: 'Alice Example',
      bio: 'Hello there!',
      birth_date: '1995-04-30',
      gender: 'Female',
      interests: ['Music', 'Travel'],
      city: 'New York',
      country: 'US',
    });

    expect(updates['profile.name']).to.equal('Alice Example');
    expect(updates['profile.bio']).to.equal('Hello there!');
    expect(updates['profile.birthDate']).to.equal('1995-04-30T00:00:00.000Z');
    expect(updates['profile.gender']).to.equal('female');
    expect(updates['profile.interests']).to.deep.equal(['Music', 'Travel']);
    expect(updates['profile.city']).to.equal('New York');
    expect(updates['profile.country']).to.equal('US');
  });

  it('rejects invalid interests payloads in profile patch', () => {
    try {
      validateProfilePatchPayload({
        interests: ['ok', 42],
      });
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/interest/i);
    }
  });

  it('rejects unsupported preferences fields', () => {
    try {
      validateProfilePreferencesPayload({
        maxDistanceKm: 100,
        unsupported: true,
      });
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/unsupported preferences field/i);
    }
  });

  it('rejects preferences where minAge is greater than maxAge', () => {
    try {
      validateProfilePreferencesPayload({
        minAge: 35,
        maxAge: 25,
      });
      throw new Error('Expected invalid-argument error');
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal('invalid-argument');
      expect(err.message).to.match(/minage cannot be greater than maxage/i);
    }
  });

  it('normalizes valid preferences payload values', () => {
    const normalized = validateProfilePreferencesPayload({
      minAge: 24.2,
      maxAge: 41.7,
      maxDistanceKm: 55.3,
      showMeGenders: ['Female', 'non_binary'],
      showMyDistance: true,
      showMyAge: false,
      hideFromDiscovery: false,
      incognitoMode: true,
      city: 'Austin',
      country: 'US',
      genderPreference: 'All',
    });

    expect(normalized).to.deep.equal({
      minAge: 24,
      maxAge: 42,
      maxDistanceKm: 55,
      showMeGenders: ['female', 'non_binary'],
      showMyDistance: true,
      showMyAge: false,
      hideFromDiscovery: false,
      incognitoMode: true,
      city: 'Austin',
      country: 'US',
      genderPreference: 'all',
    });
  });

  it('derives profile age from canonical birthDate over stale age field', () => {
    const age = deriveProfileAge({
      birthDate: '1998-01-15T00:00:00.000Z',
      age: 99,
    });

    const dob = new Date('1998-01-15T00:00:00.000Z');
    const now = new Date();
    let expected = now.getFullYear() - dob.getFullYear();
    if (
      now.getMonth() < dob.getMonth() ||
      (now.getMonth() === dob.getMonth() && now.getDate() < dob.getDate())
    ) {
      expected -= 1;
    }
    expect(age).to.equal(expected);
  });

  it('falls back to legacy dateOfBirth for birth date ISO formatting', () => {
    const iso = profileBirthDateIso({
      dateOfBirth: '1992-07-01T00:00:00.000Z',
    });
    expect(iso).to.equal('1992-07-01T00:00:00.000Z');
  });

  it('derives prompt answers from canonical profilePrompts before legacy prompts', () => {
    const prompts = profilePromptAnswers({
      profilePrompts: [
        { questionId: 'looking_for', answer: 'Someone kind' },
        { questionId: 'perfect_date', answer: 'Coffee + bookstore' },
      ],
      prompts: ['legacy one'],
    });

    expect(prompts).to.deep.equal(['Someone kind', 'Coffee + bookstore']);
  });

  it('falls back to legacy prompts when canonical profilePrompts are absent', () => {
    const prompts = profilePromptAnswers({
      prompts: ['legacy one', 'legacy two'],
    });

    expect(prompts).to.deep.equal(['legacy one', 'legacy two']);
  });
});
