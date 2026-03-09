const { expect } = require('chai');

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: 'demo-project',
  databaseURL: 'https://demo-project.firebaseio.com',
});

const functions = require('../lib/index.js');

describe('REST App Check helpers', () => {
  const { getRestAppCheckToken, evaluateRestAppCheck } = functions.__test__helpers;

  it('extracts and trims X-Firebase-AppCheck header', () => {
    const token = getRestAppCheckToken({
      header: (name) => (name === 'X-Firebase-AppCheck' ? '  abc123  ' : undefined),
    });
    expect(token).to.equal('abc123');

    const missing = getRestAppCheckToken({
      header: () => undefined,
    });
    expect(missing).to.equal(undefined);

    const blank = getRestAppCheckToken({
      header: () => '   ',
    });
    expect(blank).to.equal(undefined);
  });

  it('allows missing token when enforcement is disabled', async () => {
    const result = await evaluateRestAppCheck(undefined, 'auth.otp.send', {
      enforce: false,
      verifyToken: async () => {
        throw new Error('should not be called');
      },
    });

    expect(result).to.deep.equal({ allowed: true, outcome: 'missing' });
  });

  it('rejects missing token when enforcement is enabled', async () => {
    const result = await evaluateRestAppCheck(undefined, 'auth.otp.send', {
      enforce: true,
      verifyToken: async () => {
        throw new Error('should not be called');
      },
    });

    expect(result).to.deep.equal({ allowed: false, outcome: 'missing' });
  });

  it('accepts valid token', async () => {
    const result = await evaluateRestAppCheck('valid-token', 'auth.otp.verify', {
      enforce: true,
      verifyToken: async (token) => {
        expect(token).to.equal('valid-token');
        return { appId: 'app-1' };
      },
    });

    expect(result).to.deep.equal({ allowed: true, outcome: 'valid' });
  });

  it('allows invalid token when enforcement is disabled', async () => {
    const result = await evaluateRestAppCheck('bad-token', 'auth.token.refresh', {
      enforce: false,
      verifyToken: async () => {
        throw new Error('invalid');
      },
    });

    expect(result).to.deep.equal({ allowed: true, outcome: 'invalid' });
  });

  it('rejects invalid token when enforcement is enabled', async () => {
    const result = await evaluateRestAppCheck('bad-token', 'auth.token.refresh', {
      enforce: true,
      verifyToken: async () => {
        throw new Error('invalid');
      },
    });

    expect(result).to.deep.equal({ allowed: false, outcome: 'invalid' });
  });
});
