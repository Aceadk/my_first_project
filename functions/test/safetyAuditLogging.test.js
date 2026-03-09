const { expect } = require('chai');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('safety REST audit logging helpers', () => {
  const {
    getRestClientIp,
    safetyAuditOutcomeFromStatusCode,
    logSafetyRestAudit,
  } = functions.__test__helpers;

  it('extracts client ip from x-forwarded-for', () => {
    expect(
      getRestClientIp({
        headers: { 'x-forwarded-for': '203.0.113.5, 70.41.3.18' },
        ip: '10.0.0.1',
      })
    ).to.equal('203.0.113.5');
  });

  it('maps http status codes to audit outcomes', () => {
    expect(safetyAuditOutcomeFromStatusCode(200)).to.equal('success');
    expect(safetyAuditOutcomeFromStatusCode(404)).to.equal('invalid');
    expect(safetyAuditOutcomeFromStatusCode(429)).to.equal('rate_limited');
    expect(safetyAuditOutcomeFromStatusCode(500)).to.equal('error');
  });

  it('writes a structured safety audit entry', async () => {
    const writes = [];
    const fixedTimestamp = new Date('2026-03-07T12:00:00.000Z');

    await logSafetyRestAudit(
      {
        action: 'report',
        actorUid: 'user-1',
        targetUid: 'user-2',
        route: '/v1/users/report',
        method: 'post',
        statusCode: 429,
        reasonCategory: 'scam',
        metadata: { retryAfterMs: 1800000 },
        ip: '203.0.113.5',
        userAgent: 'test-agent',
      },
      {
        writer: async (entry) => {
          writes.push(entry);
        },
        timestampFactory: () => fixedTimestamp,
      }
    );

    expect(writes).to.have.length(1);
    expect(writes[0]).to.deep.equal({
      action: 'report',
      actorUid: 'user-1',
      targetUid: 'user-2',
      outcome: 'rate_limited',
      route: '/v1/users/report',
      method: 'POST',
      statusCode: 429,
      errorCode: null,
      reasonCategory: 'scam',
      metadata: { retryAfterMs: 1800000 },
      ip: '203.0.113.5',
      userAgent: 'test-agent',
      createdAt: fixedTimestamp,
    });
  });

  it('does not throw when the audit writer fails', async () => {
    await logSafetyRestAudit(
      {
        action: 'block',
        actorUid: 'user-1',
        targetUid: 'user-2',
        route: '/v1/users/block',
        statusCode: 200,
      },
      {
        writer: async () => {
          throw new Error('write failed');
        },
        timestampFactory: () => new Date('2026-03-07T12:00:00.000Z'),
      }
    );
  });
});
