const { expect } = require('chai');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('open discovery mode (temporary open discoverability)', () => {
  const {
    buildDiscoveryUserSnapshot,
    evaluateOpenDiscoveryCandidate,
    evaluateOpenDiscoveryEligibility,
    buildOpenDiscoveryQueryPlan,
  } = functions.__test__helpers;

  function exclusions(overrides = {}) {
    return {
      blockedByMe: new Set(),
      blockedMe: new Set(),
      reportedByMe: new Set(),
      reportedMe: new Set(),
      swiped: new Set(),
      liked: new Set(),
      matched: new Set(),
      combined: new Set(),
      ...overrides,
    };
  }

  function snapshot(id, overrides = {}) {
    const { status, ...profileOverrides } = overrides;
    return buildDiscoveryUserSnapshot(id, {
      profile: {
        name: id,
        birthDate: '1995-01-01',
        gender: 'male',
        photoUrls: [`https://img.example.com/${id}.jpg`],
        city: 'Denver',
        country: 'US',
        latitude: 39.7392,
        longitude: -104.9903,
        preferences: {
          minAge: 28,
          maxAge: 32,
          maxDistanceKm: 10,
          showMeGenders: ['male'],
          hideFromDiscovery: false,
          incognitoMode: false,
        },
        ...profileOverrides.profile,
      },
      onboardingComplete: true,
      profileComplete: true,
      updatedAt: '2026-03-13T01:00:00.000Z',
      lastActive: '2026-03-13T01:00:00.000Z',
      ...(status ? { status } : {}),
    });
  }

  // User A: man seeking men, Denver, ~30. User B: woman seeking women, Sydney,
  // ~46 — completely incompatible under the advanced filters (gender, age,
  // distance all mismatch). Open mode must still let them discover each other.
  const userA = snapshot('userA');
  const userB = buildDiscoveryUserSnapshot('userB', {
    profile: {
      name: 'B',
      birthDate: '1980-01-01',
      gender: 'female',
      photoUrls: ['https://img.example.com/b.jpg'],
      city: 'Sydney',
      country: 'AU',
      latitude: -33.8688,
      longitude: 151.2093,
      preferences: {
        minAge: 40,
        maxAge: 50,
        maxDistanceKm: 10,
        showMeGenders: ['female'],
        hideFromDiscovery: false,
        incognitoMode: false,
      },
    },
    onboardingComplete: true,
    profileComplete: true,
    updatedAt: '2026-03-13T02:00:00.000Z',
  });

  it('lets User A discover User B despite mismatched gender/age/distance', () => {
    const result = evaluateOpenDiscoveryCandidate({
      requester: userA,
      candidate: userB,
      exclusionSets: exclusions(),
    });
    expect(result.included).to.equal(true);
  });

  it('lets User B discover User A (mutual)', () => {
    const result = evaluateOpenDiscoveryCandidate({
      requester: userB,
      candidate: userA,
      exclusionSets: exclusions(),
    });
    expect(result.included).to.equal(true);
  });

  it('never shows a user their own profile', () => {
    const result = evaluateOpenDiscoveryCandidate({
      requester: userA,
      candidate: userA,
      exclusionSets: exclusions(),
    });
    expect(result.included).to.equal(false);
    expect(result.reasons[0].code).to.equal('self_excluded');
  });

  it('excludes terminal account states (banned/deleted/deactivated/disabled/pending)', () => {
    for (const status of ['banned', 'deleted', 'deactivated', 'disabled', 'pending']) {
      const candidate = snapshot('blocked-state', { status });
      const result = evaluateOpenDiscoveryCandidate({
        requester: userA,
        candidate,
        exclusionSets: exclusions(),
      });
      expect(result.included, `status=${status}`).to.equal(false);
      expect(result.reasons[0].code).to.equal('account_not_active');
    }
  });

  it('keeps blocked/reported exclusions in both directions', () => {
    expect(
      evaluateOpenDiscoveryCandidate({
        requester: userA,
        candidate: userB,
        exclusionSets: exclusions({ blockedByMe: new Set(['userB']) }),
      }).included,
    ).to.equal(false);
    expect(
      evaluateOpenDiscoveryCandidate({
        requester: userA,
        candidate: userB,
        exclusionSets: exclusions({ blockedMe: new Set(['userB']) }),
      }).included,
    ).to.equal(false);
    expect(
      evaluateOpenDiscoveryCandidate({
        requester: userA,
        candidate: userB,
        exclusionSets: exclusions({ reportedByMe: new Set(['userB']) }),
      }).included,
    ).to.equal(false);
  });

  it('excludes already-swiped profiles by default (swipe history)', () => {
    const result = evaluateOpenDiscoveryCandidate({
      requester: userA,
      candidate: userB,
      exclusionSets: exclusions({ swiped: new Set(['userB']) }),
    });
    expect(result.included).to.equal(false);
    expect(result.reasons[0].code).to.equal('already_swiped');
  });

  it('still shows profiles with an incomplete profile (no completion filter)', () => {
    const incomplete = buildDiscoveryUserSnapshot('incomplete', {
      profile: { name: 'C', gender: '', photoUrls: [] },
      onboardingComplete: false,
      profileComplete: false,
    });
    const result = evaluateOpenDiscoveryCandidate({
      requester: userA,
      candidate: incomplete,
      exclusionSets: exclusions(),
    });
    expect(result.included).to.equal(true);
  });

  it('open query plan applies no gender/completion/verification pre-filters', () => {
    const plan = buildOpenDiscoveryQueryPlan(120);
    expect(plan.filters).to.deep.equal([]);
    expect(plan.orderBy.fieldPath).to.equal('updatedAt');
    expect(plan.limit).to.equal(120);
  });

  it('open eligibility ignores profile completion but keeps account validity', () => {
    expect(
      evaluateOpenDiscoveryEligibility(
        buildDiscoveryUserSnapshot('bare', { profile: { name: '', photoUrls: [] } }),
      ).eligible,
    ).to.equal(true);
    expect(
      evaluateOpenDiscoveryEligibility(snapshot('banned-user', { status: 'banned' }))
        .eligible,
    ).to.equal(false);
  });
});
