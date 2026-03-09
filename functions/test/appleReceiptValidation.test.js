const { expect } = require("chai");
const { generateKeyPairSync } = require("crypto");

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: "demo-project",
  databaseURL: "https://demo-project.firebaseio.com",
});

const functions = require("../lib/index.js");

function toBase64Url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function decodeBase64Url(input) {
  const normalized = input.replace(/-/g, "+").replace(/_/g, "/");
  const padding = normalized.length % 4;
  const padded = padding === 0 ? normalized : normalized + "=".repeat(4 - padding);
  return Buffer.from(padded, "base64").toString("utf8");
}

function signedTransactionFixture(payload) {
  const header = toBase64Url(
    JSON.stringify({ alg: "ES256", kid: "kid", typ: "JWT" })
  );
  const body = toBase64Url(JSON.stringify(payload));
  return `${header}.${body}.signature`;
}

describe("apple receipt validation helpers", () => {
  const {
    normalizeApplePrivateKey,
    buildAppleTransactionLookupUrl,
    createAppleServerAuthToken,
    decodeAppleSignedTransactionInfo,
    fetchAppleTransactionValidation,
    deriveAppleSubscriptionEntitlement,
  } = functions.__test__helpers;

  it("normalizes escaped Apple private keys", () => {
    expect(normalizeApplePrivateKey("line1\\nline2")).to.equal("line1\nline2");
    expect(normalizeApplePrivateKey("   ")).to.equal(null);
  });

  it("builds production and sandbox transaction lookup URLs", () => {
    expect(buildAppleTransactionLookupUrl("tx/abc", "PRODUCTION")).to.equal(
      "https://api.storekit.itunes.apple.com/inApps/v1/transactions/tx%2Fabc"
    );
    expect(buildAppleTransactionLookupUrl("tx/abc", "SANDBOX")).to.equal(
      "https://api.storekit-sandbox.itunes.apple.com/inApps/v1/transactions/tx%2Fabc"
    );
  });

  it("creates App Store auth JWT with expected claims", () => {
    const { privateKey } = generateKeyPairSync("ec", {
      namedCurve: "prime256v1",
    });
    const privateKeyPem = privateKey.export({
      type: "pkcs8",
      format: "pem",
    });

    const token = createAppleServerAuthToken(
      {
        issuerId: "issuer-123",
        keyId: "ABC123DEF4",
        privateKey: privateKeyPem,
        bundleId: "com.ace.crush",
      },
      Date.UTC(2026, 2, 8, 12, 0, 0)
    );

    const segments = token.split(".");
    expect(segments.length).to.equal(3);
    const payload = JSON.parse(decodeBase64Url(segments[1]));
    expect(payload.iss).to.equal("issuer-123");
    expect(payload.aud).to.equal("appstoreconnect-v1");
    expect(payload.bid).to.equal("com.ace.crush");
    expect(payload.exp).to.be.greaterThan(payload.iat);
  });

  it("decodes signed Apple transaction payload", () => {
    const signed = signedTransactionFixture({
      transactionId: "2000000123456789",
      originalTransactionId: "2000000111111111",
      bundleId: "com.ace.crush",
      productId: "plus_monthly",
      expiresDate: 1770000000000,
    });

    const decoded = decodeAppleSignedTransactionInfo(signed);
    expect(decoded.transactionId).to.equal("2000000123456789");
    expect(decoded.originalTransactionId).to.equal("2000000111111111");
    expect(decoded.bundleId).to.equal("com.ace.crush");
  });

  it("derives entitlement states from Apple transaction timestamps", () => {
    const now = Date.UTC(2026, 2, 8, 12, 0, 0);

    const active = deriveAppleSubscriptionEntitlement(
      { expiresDate: now + 3600_000 },
      now
    );
    expect(active.plan).to.equal("plus");
    expect(active.status).to.equal("active");

    const expired = deriveAppleSubscriptionEntitlement(
      { expiresDate: now - 1000 },
      now
    );
    expect(expired.plan).to.equal("free");
    expect(expired.status).to.equal("expired");

    const revoked = deriveAppleSubscriptionEntitlement(
      {
        expiresDate: now + 3600_000,
        revocationDate: now - 500,
      },
      now
    );
    expect(revoked.plan).to.equal("free");
    expect(revoked.status).to.equal("revoked");
  });

  it("falls back to sandbox when production transaction is not found", async () => {
    const signed = signedTransactionFixture({
      transactionId: "2000000123456789",
      originalTransactionId: "2000000111111111",
      bundleId: "com.ace.crush",
      productId: "plus_monthly",
      expiresDate: 1770000000000,
    });

    const urls = [];
    const authHeaders = [];
    const result = await fetchAppleTransactionValidation(
      { transactionId: "2000000123456789" },
      {
        config: {
          issuerId: "issuer",
          keyId: "key",
          privateKey: "unused",
          bundleId: "com.ace.crush",
        },
        authTokenProvider: async () => "apple-token-abc",
        fetchImpl: async (url, init) => {
          urls.push(String(url));
          authHeaders.push(init && init.headers && init.headers.Authorization);
          if (urls.length === 1) {
            return {
              ok: false,
              status: 404,
              json: async () => ({}),
              text: async () => "missing",
            };
          }
          return {
            ok: true,
            status: 200,
            json: async () => ({
              environment: "Sandbox",
              signedTransactionInfo: signed,
            }),
            text: async () => "",
          };
        },
      }
    );

    expect(urls[0]).to.contain("api.storekit.itunes.apple.com");
    expect(urls[1]).to.contain("api.storekit-sandbox.itunes.apple.com");
    expect(authHeaders[0]).to.equal("Bearer apple-token-abc");
    expect(result.environment).to.equal("SANDBOX");
    expect(result.transaction.originalTransactionId).to.equal(
      "2000000111111111"
    );
  });
});
