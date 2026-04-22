const { expect } = require('chai');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('discovery eligibility helpers', () => {
  const {
    buildDiscoveryUserSnapshot,
    evaluateDiscoveryEligibility,
    buildLegacyDiscoveryMirrorPatch,
    buildDiscoveryExclusionSetsFromRecords,
    evaluateDiscoveryCandidateForRequester,
    buildDiscoveryCandidateQueryPlan,
    buildDiscoveryDeckRequestScope,
    encodeDiscoveryDeckCursor,
    decodeDiscoveryDeckCursor,
    paginateDiscoveryDeckCandidates,
  } = functions.__test__helpers;

  function buildExclusionSets(overrides = {}) {
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

  function buildDeckRequestScope(overrides = {}) {
    return buildDiscoveryDeckRequestScope({
      uid: 'requester',
      minAge: 24,
      maxAge: 34,
      maxDistanceKm: 50,
      showMeGenders: ['female'],
      interests: ['coffee'],
      requirePhotos: false,
      requireVerified: false,
      latitude: 39.7392,
      longitude: -104.9903,
      ...overrides,
    });
  }

  function buildDeckCandidate(id, { score, updatedAt }) {
    const user = buildDiscoveryUserSnapshot(id, {
      displayName: id,
      birthDate: '1996-07-22',
      gender: 'female',
      photos: [`https://img.example.com/${id}.jpg`],
      interestedIn: ['male'],
      updatedAt,
      lastActive: updatedAt,
    });

    return {
      user,
      score,
      distanceKm: 5,
      sortActivityMs: Date.parse(updatedAt),
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

  it('builds a legacy root-field mirror patch for canonical mobile users', () => {
    const userData = {
      profile: {
        name: 'Ben App',
        birthDate: '1996-07-22',
        gender: 'male',
        bio: 'Hiking and coffee',
        photoUrls: ['https://img.example.com/ben.jpg'],
        interests: ['Hiking', 'Coffee'],
        profilePrompts: [
          { question: 'Sunday', answer: 'Trail run' },
        ],
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
      updatedAt: '2026-03-13T01:05:00.000Z',
    };

    const snapshot = buildDiscoveryUserSnapshot('mobile-user', userData);
    const patch = buildLegacyDiscoveryMirrorPatch('mobile-user', userData);

    expect(patch.displayName).to.equal('Ben App');
    expect(patch.bio).to.equal('Hiking and coffee');
    expect(patch.birthDate).to.equal('1996-07-22T00:00:00.000Z');
    expect(patch.age).to.equal(snapshot.age);
    expect(patch.gender).to.equal('male');
    expect(patch.photos).to.deep.equal(['https://img.example.com/ben.jpg']);
    expect(patch.profilePhotoUrl).to.equal('https://img.example.com/ben.jpg');
    expect(patch.interests).to.deep.equal(['Hiking', 'Coffee']);
    expect(patch.prompts).to.deep.equal(['Trail run']);
    expect(patch.interestedIn).to.deep.equal(['female']);
    expect(patch.location).to.deep.equal({
      city: 'Denver',
      country: 'US',
      latitude: 39.7392,
      longitude: -104.9903,
    });
    expect(patch.settings).to.deep.equal({
      ageRangeMin: 23,
      ageRangeMax: 33,
      maxDistance: 40,
      showInDiscovery: true,
      incognitoMode: false,
    });
    expect(patch.lastActive.toDate().toISOString()).to.equal(
      '2026-03-13T01:05:00.000Z'
    );
    expect(patch.onboardingComplete).to.equal(true);
    expect(patch.profileComplete).to.equal(true);
  });

  it('returns an empty mirror patch once legacy root fields already match', () => {
    const userData = {
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
          maxDistanceKm: 40,
          showMeGenders: ['female'],
        },
      },
      updatedAt: '2026-03-13T01:05:00.000Z',
      lastActive: '2026-03-13T01:06:00.000Z',
    };

    const patch = buildLegacyDiscoveryMirrorPatch('mobile-user', userData);
    const hybridUserData = { ...userData, ...patch };

    expect(buildLegacyDiscoveryMirrorPatch('mobile-user', hybridUserData)).to.deep.equal({});
  });

  it('clears legacy discovery flags when a canonical user is no longer eligible', () => {
    const patch = buildLegacyDiscoveryMirrorPatch('hidden-user', {
      profile: {
        name: 'Hidden',
        birthDate: '1995-08-15',
        gender: 'female',
        photoUrls: ['https://img.example.com/hidden.jpg'],
        preferences: {
          showMeGenders: ['male'],
          hideFromDiscovery: true,
        },
      },
      onboardingComplete: true,
      profileComplete: true,
      settings: {
        showInDiscovery: true,
      },
    });

    expect(patch.settings).to.deep.equal({
      ageRangeMin: 18,
      ageRangeMax: 100,
      maxDistance: 100,
      showInDiscovery: false,
      incognitoMode: false,
    });
    expect(patch.onboardingComplete).to.equal(false);
    expect(patch.profileComplete).to.equal(false);
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

  it('normalizes canonical and legacy relation records into deterministic exclusion sets', () => {
    const exclusionSets = buildDiscoveryExclusionSetsFromRecords('requester', {
      blockedByMe: [
        { blockedId: 'blocked-a' },
        { blocked_id: 'blocked-b' },
        { blockedId: 'requester' },
      ],
      blockedMe: [
        { blockerId: 'blocker-a' },
        { blocker_id: 'blocker-b' },
      ],
      reportedByMe: [
        { reportedId: 'reported-a' },
        { reported_id: 'reported-b' },
      ],
      reportedMe: [
        { reporterId: 'reporter-a' },
        { reporter_id: 'reporter-b' },
      ],
      likes: [
        { toUserId: 'liked-a' },
        { to_user_id: 'liked-b' },
      ],
      swipes: [
        { targetId: 'swiped-a' },
        { swipedUserId: 'swiped-b' },
        { target_id: 'swiped-c' },
        { swiped_user_id: 'swiped-d' },
      ],
      matches: [
        { userIds: ['requester', 'match-a'] },
        { participants: ['requester', 'match-b'] },
      ],
    });

    expect([...exclusionSets.blockedByMe]).to.have.members([
      'blocked-a',
      'blocked-b',
    ]);
    expect([...exclusionSets.blockedMe]).to.have.members([
      'blocker-a',
      'blocker-b',
    ]);
    expect([...exclusionSets.reportedByMe]).to.have.members([
      'reported-a',
      'reported-b',
    ]);
    expect([...exclusionSets.reportedMe]).to.have.members([
      'reporter-a',
      'reporter-b',
    ]);
    expect([...exclusionSets.liked]).to.have.members([
      'liked-a',
      'liked-b',
    ]);
    expect([...exclusionSets.swiped]).to.have.members([
      'swiped-a',
      'swiped-b',
      'swiped-c',
      'swiped-d',
    ]);
    expect([...exclusionSets.matched]).to.have.members([
      'match-a',
      'match-b',
    ]);
    expect([...exclusionSets.combined]).to.include.members([
      'requester',
      'blocked-a',
      'blocker-a',
      'reported-a',
      'reporter-a',
      'liked-a',
      'swiped-a',
      'match-a',
    ]);
  });

  it('excludes users in safety review from discovery eligibility', () => {
    const snapshot = buildDiscoveryUserSnapshot('review-user', {
      displayName: 'Review User',
      birthDate: '1995-08-15',
      gender: 'female',
      photos: ['https://img.example.com/review-user.jpg'],
      interestedIn: ['male'],
      safetyFlags: {
        status: 'needs_review',
      },
    });

    const result = evaluateDiscoveryEligibility(snapshot);

    expect(snapshot.moderationStatus).to.equal('needs_review');
    expect(result.eligible).to.equal(false);
    expect(result.reasons).to.deep.include({
      code: 'moderation_hold',
      stage: 'eligibility',
      message:
        'Moderation state prevents the profile from appearing in discovery.',
    });
  });

  it('excludes reported profiles and keeps block precedence deterministic', () => {
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

    const reportedResult = evaluateDiscoveryCandidateForRequester({
      requester,
      candidate,
      request: {},
      exclusionSets: buildExclusionSets({
        reportedByMe: new Set(['candidate']),
        combined: new Set(['candidate']),
      }),
    });

    expect(reportedResult.included).to.equal(false);
    expect(reportedResult.reasons).to.deep.equal([
      {
        code: 'reported_by_requester',
        stage: 'relationship',
        message: 'The requester has reported this profile.',
      },
    ]);

    const precedenceResult = evaluateDiscoveryCandidateForRequester({
      requester,
      candidate,
      request: {},
      exclusionSets: buildExclusionSets({
        blockedByMe: new Set(['candidate']),
        reportedByMe: new Set(['candidate']),
        combined: new Set(['candidate']),
      }),
    });

    expect(precedenceResult.included).to.equal(false);
    expect(precedenceResult.reasons).to.deep.equal([
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

  it('builds an indexed discovery query plan from mirrored eligibility fields', () => {
    const plan = buildDiscoveryCandidateQueryPlan({
      showMeGenders: ['female'],
      requireVerified: true,
      limit: 480,
    });

    expect(plan).to.deep.equal({
      filters: [
        { fieldPath: 'onboardingComplete', op: '==', value: true },
        { fieldPath: 'profileComplete', op: '==', value: true },
        { fieldPath: 'gender', op: '==', value: 'female' },
        { fieldPath: 'isVerified', op: '==', value: true },
      ],
      orderBy: {
        fieldPath: 'updatedAt',
        direction: 'desc',
      },
      limit: 480,
    });
  });

  it('omits the gender filter when all canonical genders are allowed', () => {
    const plan = buildDiscoveryCandidateQueryPlan({
      showMeGenders: ['male', 'female', 'non_binary', 'other'],
      requireVerified: false,
      limit: 240,
    });

    expect(plan.filters).to.deep.equal([
      { fieldPath: 'onboardingComplete', op: '==', value: true },
      { fieldPath: 'profileComplete', op: '==', value: true },
    ]);
    expect(plan.orderBy).to.deep.equal({
      fieldPath: 'updatedAt',
      direction: 'desc',
    });
    expect(plan.limit).to.equal(240);
  });

  it('uses an in-filter when multiple target genders remain after normalization', () => {
    const plan = buildDiscoveryCandidateQueryPlan({
      showMeGenders: ['female', 'male', 'female'],
      requireVerified: false,
      limit: 300,
    });

    expect(plan.filters).to.deep.equal([
      { fieldPath: 'onboardingComplete', op: '==', value: true },
      { fieldPath: 'profileComplete', op: '==', value: true },
      { fieldPath: 'gender', op: 'in', value: ['female', 'male'] },
    ]);
  });

  it('encodes and decodes discovery cursors with the normalized request scope', () => {
    const scope = buildDeckRequestScope();
    const encoded = encodeDiscoveryDeckCursor({
      version: 1,
      uid: 'requester',
      scope,
      lastScore: 3.25,
      lastActivityMs: 1700000000000,
      lastUserId: 'candidate-b',
    });

    expect(decodeDiscoveryDeckCursor(encoded)).to.deep.equal({
      version: 1,
      uid: 'requester',
      scope,
      lastScore: 3.25,
      lastActivityMs: 1700000000000,
      lastUserId: 'candidate-b',
    });
  });

  it('rejects discovery cursors when the request scope changes', () => {
    const originalScope = buildDeckRequestScope();
    const changedScope = buildDeckRequestScope({ maxDistanceKm: 10 });
    const cursor = encodeDiscoveryDeckCursor({
      version: 1,
      uid: 'requester',
      scope: originalScope,
      lastScore: 4,
      lastActivityMs: Date.parse('2026-03-13T02:05:00.000Z'),
      lastUserId: 'candidate-b',
    });

    expect(() =>
      paginateDiscoveryDeckCandidates({
        uid: 'requester',
        scope: changedScope,
        candidates: [
          buildDeckCandidate('candidate-a', {
            score: 5,
            updatedAt: '2026-03-13T02:06:00.000Z',
          }),
        ],
        limit: 1,
        cursor,
      })
    ).to.throw('Discovery cursor does not match this request.');
  });

  it('paginates discovery candidates deterministically across retries and list churn', () => {
    const scope = buildDeckRequestScope();
    const orderedCandidates = [
      buildDeckCandidate('candidate-a', {
        score: 9,
        updatedAt: '2026-03-13T02:06:00.000Z',
      }),
      buildDeckCandidate('candidate-b', {
        score: 9,
        updatedAt: '2026-03-13T02:06:00.000Z',
      }),
      buildDeckCandidate('candidate-c', {
        score: 8,
        updatedAt: '2026-03-13T02:05:00.000Z',
      }),
      buildDeckCandidate('candidate-d', {
        score: 7,
        updatedAt: '2026-03-13T02:04:00.000Z',
      }),
    ];

    const firstPage = paginateDiscoveryDeckCandidates({
      uid: 'requester',
      scope,
      candidates: orderedCandidates,
      limit: 2,
    });

    expect(firstPage.page.map((candidate) => candidate.user.id)).to.deep.equal([
      'candidate-a',
      'candidate-b',
    ]);
    expect(firstPage.hasMore).to.equal(true);
    expect(firstPage.nextCursor).to.be.a('string');

    const retryPage = paginateDiscoveryDeckCandidates({
      uid: 'requester',
      scope,
      candidates: orderedCandidates,
      limit: 2,
      cursor: firstPage.nextCursor,
    });

    expect(retryPage.page.map((candidate) => candidate.user.id)).to.deep.equal([
      'candidate-c',
      'candidate-d',
    ]);
    expect(retryPage.hasMore).to.equal(false);

    const churnedCandidates = [
      buildDeckCandidate('candidate-aa', {
        score: 10,
        updatedAt: '2026-03-13T02:07:00.000Z',
      }),
      orderedCandidates[0],
      orderedCandidates[2],
      orderedCandidates[3],
    ];

    const churnedPage = paginateDiscoveryDeckCandidates({
      uid: 'requester',
      scope,
      candidates: churnedCandidates,
      limit: 2,
      cursor: firstPage.nextCursor,
    });

    expect(
      churnedPage.page.map((candidate) => candidate.user.id),
    ).to.deep.equal(['candidate-c', 'candidate-d']);
  });
});
