const { expect } = require('chai');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('account deletion map (AUTH-SEC-005)', () => {
  const { userRelationDeletionTargets, matchMembershipFields } =
    functions.__test__helpers;

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
});
