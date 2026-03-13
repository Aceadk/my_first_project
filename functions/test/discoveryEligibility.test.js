const { expect } = require('chai');
const functions = require('../lib/index.js');

describe('discovery eligibility helpers', () => {
  const {
    buildDiscoveryUserSnapshot,
    evaluateDiscoveryEligibility,
    evaluateDiscoveryCandidateForRequester,
  } = functions.__test__helpers;

  function buildExclusionSets(overrides = {}) {
    return {
      blockedByMe: new Set(),
      blockedMe: new Set(),
      swiped: new Set(),
      liked: new Set(),
      matched: new Set(),
      combined: new Set(),
      ...overrides,
    };
  }

  it('normalizes flat web user documents into eligible discovery snapshots', () => {
    const snapshot = buildDiscoveryUserSnapshot('web-user', {
      displayName: 'Alice Web',
      birthDate: '1998-05-10',
      gender: 'woman',
      bio: 'New on Crush',
      photos: ['https://img.example.com/alice.jpg'],
      interestedIn: ['man'],
      location: {
        city: 'Austin',
        country: 'US',
        latitude: 30.2672,
        longitude: -97.7431,
      },
      settings: {
        maxDistance: 25,
        ageRangeMin: 24,
        ageRangeMax: 34,
      },
      onboardingComplete: true,
      profileComplete: true,
      updatedAt: '2026-03-13T01:00:00.000Z',
    });

    expect(snapshot.sourceSchema).to.equal('legacy_flat');
    expect(snapshot.name).to.equal('Alice Web');
    expect(snapshot.gender).to.equal('female');
    expect(snapshot.photoUrls).to.deep.equal([
      'https://img.example.com/alice.jpg',
    ]);
    expect(snapshot.city).to.equal('Austin');
    expect(snapshot.country).to.equal('US');
    expect(snapshot.preferences.showMeGenders).to.deep.equal(['male']);
    expect(snapshot.preferences.minAge).to.equal(24);
    expect(snapshot.preferences.maxAge).to.equal(34);
    expect(snapshot.preferences.maxDistanceKm).to.equal(25);
    expect(evaluateDiscoveryEligibility(snapshot)).to.deep.equal({
      eligible: true,
      reasons: [],
    });
  });

  it('normalizes nested mobile user documents into eligible discovery snapshots', () => {
    const snapshot = buildDiscoveryUserSnapshot('mobile-user', {
      profile: {
        name: 'Ben App',
        birthDate: '1996-07-22',
        gender: 'male',
        bio: 'Hiking and coffee',
        photoUrls: ['https://img.example.com/ben.jpg'],
        interests: ['Hiking', 'Coffee'],
        city: 'Denver',
        country: 'US',
        latitude: 39.7392,
        longitude: -104.9903,
        preferences: {
          minAge: 23,
          maxAge: 33,
          maxDistanceKm: 40,
          showMeGenders: ['female'],
          hideFromDiscovery: false,
          incognitoMode: false,
        },
      },
      onboardingComplete: true,
      profileComplete: true,
      updatedAt: '2026-03-13T01:05:00.000Z',
      lastActive: '2026-03-13T01:05:00.000Z',
    });

    expect(snapshot.sourceSchema).to.equal('canonical_nested');
    expect(snapshot.name).to.equal('Ben App');
    expect(snapshot.gender).to.equal('male');
    expect(snapshot.preferences.showMeGenders).to.deep.equal(['female']);
    expect(snapshot.preferences.maxDistanceKm).to.equal(40);
    expect(evaluateDiscoveryEligibility(snapshot)).to.deep.equal({
      eligible: true,
      reasons: [],
    });
  });

  it('returns explicit discoverability reasons for hidden or incomplete users', () => {
    const snapshot = buildDiscoveryUserSnapshot('hidden-user', {
      displayName: 'Hidden',
      gender: 'female',
      interestedIn: ['male'],
      settings: {
        showInDiscovery: false,
      },
      profileComplete: false,
      onboardingComplete: false,
    });

    const result = evaluateDiscoveryEligibility(snapshot);

    expect(result.eligible).to.equal(false);
    expect(result.reasons.map((reason) => reason.code)).to.include.members([
      'missing_or_invalid_age',
      'missing_photos',
      'hidden_from_discovery',
    ]);
  });

  it('surfaces the exact relationship exclusion stage for already blocked users', () => {
    const requester = buildDiscoveryUserSnapshot('requester', {
      profile: {
        name: 'Requester',
        birthDate: '1994-04-10',
        gender: 'male',
        photoUrls: ['https://img.example.com/requester.jpg'],
        preferences: {
          showMeGenders: ['female'],
          minAge: 18,
          maxAge: 50,
          maxDistanceKm: 50,
        },
      },
      updatedAt: '2026-03-13T02:00:00.000Z',
    });
    const candidate = buildDiscoveryUserSnapshot('candidate', {
      displayName: 'Candidate',
      birthDate: '1995-08-15',
      gender: 'female',
      photos: ['https://img.example.com/candidate.jpg'],
      interestedIn: ['male'],
      updatedAt: '2026-03-13T02:00:00.000Z',
    });

    const result = evaluateDiscoveryCandidateForRequester({
      requester,
      candidate,
      request: {},
      exclusionSets: buildExclusionSets({
        blockedByMe: new Set(['candidate']),
        combined: new Set(['candidate']),
      }),
    });

    expect(result.included).to.equal(false);
    expect(result.reasons).to.deep.equal([
      {
        code: 'blocked_by_requester',
        stage: 'relationship',
        message: 'The requester has blocked this profile.',
      },
    ]);
  });

  it('includes eligible cross-platform candidates and reports distance', () => {
    const requester = buildDiscoveryUserSnapshot('mobile-user', {
      profile: {
        name: 'Ben App',
        birthDate: '1996-07-22',
        gender: 'male',
        photoUrls: ['https://img.example.com/ben.jpg'],
        interests: ['Hiking', 'Coffee'],
        city: 'Denver',
        country: 'US',
        latitude: 39.7392,
        longitude: -104.9903,
        preferences: {
          minAge: 23,
          maxAge: 33,
          maxDistanceKm: 100,
          showMeGenders: ['female'],
        },
      },
      updatedAt: '2026-03-13T01:05:00.000Z',
    });
    const candidate = buildDiscoveryUserSnapshot('web-user', {
      displayName: 'Alice Web',
      birthDate: '1998-05-10',
      gender: 'female',
      bio: 'New on Crush',
      photos: ['https://img.example.com/alice.jpg'],
      interests: ['Coffee'],
      interestedIn: ['male'],
      location: {
        city: 'Denver',
        country: 'US',
        latitude: 39.742,
        longitude: -104.991,
      },
      updatedAt: '2026-03-13T01:06:00.000Z',
    });

    const result = evaluateDiscoveryCandidateForRequester({
      requester,
      candidate,
      request: {},
      exclusionSets: buildExclusionSets(),
    });

    expect(result.included).to.equal(true);
    expect(result.reasons).to.deep.equal([]);
    expect(result.distanceKm).to.be.a('number');
    expect(result.score).to.be.greaterThan(1);
  });
});
