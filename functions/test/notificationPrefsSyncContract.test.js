const { expect } = require('chai');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('notification preference sync contract helpers', () => {
  const {
    normalizeNotificationPrefs,
    isInQuietHours,
    isNotificationCategoryAllowed,
  } = functions.__test__helpers;

  it('normalizes sparse notification preference payloads with safe defaults', () => {
    const normalized = normalizeNotificationPrefs(
      {
        push: false,
        messages: true,
        quietHoursEnabled: true,
        quietHoursStart: 21,
        quietHoursEnd: 6,
      },
      'America/New_York'
    );

    expect(normalized).to.deep.equal({
      push: false,
      calls: true,
      messages: true,
      matches: true,
      subscriptions: true,
      likes: true,
      profileViews: true,
      promotions: true,
      safetyAlerts: true,
      mutedMessages: [],
      mutedCalls: [],
      quietHoursEnabled: true,
      quietHoursStart: 21,
      quietHoursEnd: 6,
      timezone: 'America/New_York',
    });
  });

  it('disables quiet-hour suppression when quietHoursEnabled is false', () => {
    const inQuietHours = isInQuietHours({
      push: true,
      calls: true,
      messages: true,
      matches: true,
      subscriptions: true,
      likes: true,
      profileViews: true,
      promotions: true,
      safetyAlerts: true,
      mutedMessages: [],
      mutedCalls: [],
      quietHoursEnabled: false,
      quietHoursStart: 0,
      quietHoursEnd: 23,
      timezone: 'UTC',
    });

    expect(inQuietHours).to.equal(false);
  });

  it('keeps safety alerts deliverable while suppressing muted senders', () => {
    const prefs = normalizeNotificationPrefs(
      {
        push: false,
        mutedMessages: ['sender-1', ' ', 'sender-1'],
        mutedCalls: ['caller-1'],
      },
      'UTC'
    );

    expect(prefs.mutedMessages).to.deep.equal(['sender-1']);
    expect(
      isNotificationCategoryAllowed(prefs, 'safetyAlerts', {
        fromUserId: 'sender-1',
      })
    ).to.equal(true);
    expect(
      isNotificationCategoryAllowed(
        { ...prefs, push: true },
        'messages',
        { fromUserId: 'sender-1' }
      )
    ).to.equal(false);
    expect(
      isNotificationCategoryAllowed(
        { ...prefs, push: true },
        'calls',
        { fromUserId: 'caller-1' }
      )
    ).to.equal(false);
  });
});
