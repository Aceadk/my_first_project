const { expect } = require('chai');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('account deletion map (AUTH-SEC-005)', () => {
  const {
    userRelationDeletionTargets,
    matchMembershipFields,
    messageRequestParticipantFields,
    userStorageDeletionPrefixes,
  } = functions.__test__helpers;

  it('queries every match membership field so matches are not missed', () => {
    // Matches are created with `users`/`userIds`; deletion must not query only
    // `participants`.
    expect([...matchMembershipFields()]).to.have.members([
      'users',
      'userIds',
      'participants',
    ]);
  });

  it('scrubs the user outgoing relation records (their personal data)', () => {
    const targets = userRelationDeletionTargets().map(
      (t) => `${t.collection}.${t.field}`,
    );

    expect(targets).to.include.members([
      'likes.fromUserId',
      'swipes.swiperId',
      'blocks.blockerId',
      'reports.reporterId',
    ]);
  });

  it('removes inbound like/swipe pointers to avoid orphaned references', () => {
    const targets = userRelationDeletionTargets().map(
      (t) => `${t.collection}.${t.field}`,
    );

    expect(targets).to.include.members(['likes.toUserId', 'swipes.targetId']);
  });

  it('retains inbound blocks/reports about the user for abuse history', () => {
    const targets = userRelationDeletionTargets().map(
      (t) => `${t.collection}.${t.field}`,
    );

    expect(targets).to.not.include('reports.reportedId');
    expect(targets).to.not.include('blocks.blockedId');
  });

  it('scrubs message_requests by the fields they are actually written with', () => {
    // Top-level `message_requests` docs are keyed by `fromUserId`/`toUserId`
    // (mobile client + security rules). Querying `senderId`/`recipientId` would
    // silently match nothing and leave request content/PII behind on deletion.
    expect([...messageRequestParticipantFields()]).to.have.members([
      'fromUserId',
      'toUserId',
    ]);
  });

  describe('storage deletion prefixes (PROF-BE-003)', () => {
    const prefixes = userStorageDeletionPrefixes('u1', ['m1', 'm2']);

    it('sweeps the production Firebase-client media paths', () => {
      // Profile photos/videos/stories/media all live under users/{uid}/.
      expect(prefixes).to.include('users/u1/');
      // ID verification documents are sensitive PII and must be removed.
      expect(prefixes).to.include('verification/u1/');
    });

    it('sweeps chat media this user uploaded in each of their matches', () => {
      // Production chat media path is chat_media/{matchId}/{uploaderUid}/.
      expect(prefixes).to.include('chat_media/m1/u1/');
      expect(prefixes).to.include('chat_media/m2/u1/');
    });

    it('still sweeps the legacy REST backend paths', () => {
      expect(prefixes).to.include('photos/u1/');
      expect(prefixes).to.include('chat_media/u1/');
    });
  });
});
