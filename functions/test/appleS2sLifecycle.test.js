const { expect } = require("chai");

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

function buildUnsignedApplePayload(payload) {
  const header = toBase64Url(
    JSON.stringify({ alg: "ES256", x5c: ["dummy-certificate"] })
  );
  const body = toBase64Url(JSON.stringify(payload));
  return `${header}.${body}.signature`;
}

describe("apple server notification lifecycle helpers", () => {
  const {
    decodeAppleServerNotificationPayload,
    mapAppleServerNotificationType,
    applyAppleServerNotificationEntitlementOverride,
    parseAppleNotificationSignedDate,
    verifyAppleSignedPayloadSignature,
  } = functions.__test__helpers;

  it("maps DID_FAIL_TO_RENEW to billing retry status", () => {
    const mapping = mapAppleServerNotificationType("DID_FAIL_TO_RENEW");
    expect(mapping).to.deep.equal({
      status: "billing_retry",
      forceFree: false,
    });
  });

  it("maps EXPIRED to force-free status", () => {
    const mapping = mapAppleServerNotificationType("EXPIRED");
    expect(mapping).to.deep.equal({
      status: "expired",
      forceFree: true,
    });
  });

  it("keeps plus during billing retry before expiry", () => {
    const now = Date.UTC(2026, 2, 8, 12, 0, 0);
    const entitlement = applyAppleServerNotificationEntitlementOverride(
      {
        plan: "plus",
        status: "active",
        cancelAtPeriodEnd: false,
        currentPeriodEnd: Math.floor((now + 3600_000) / 1000),
        expiryTimeMillis: now + 3600_000,
      },
      {
        status: "billing_retry",
        forceFree: false,
      },
      now
    );

    expect(entitlement.plan).to.equal("plus");
    expect(entitlement.status).to.equal("billing_retry");
  });

  it("forces free entitlement for expired notifications", () => {
    const now = Date.UTC(2026, 2, 8, 12, 0, 0);
    const entitlement = applyAppleServerNotificationEntitlementOverride(
      {
        plan: "plus",
        status: "active",
        cancelAtPeriodEnd: false,
        currentPeriodEnd: Math.floor((now + 3600_000) / 1000),
        expiryTimeMillis: now + 3600_000,
      },
      {
        status: "expired",
        forceFree: true,
      },
      now
    );

    expect(entitlement.plan).to.equal("free");
    expect(entitlement.currentPeriodEnd).to.equal(null);
    expect(entitlement.expiryTimeMillis).to.equal(null);
  });

  it("decodes signed payload with injected signature verifier", () => {
    const signed = buildUnsignedApplePayload({
      notificationType: "DID_RENEW",
      subtype: "",
      data: {
        environment: "Sandbox",
        signedTransactionInfo: "txn.payload.sig",
      },
    });

    const decoded = decodeAppleServerNotificationPayload(signed, {
      verifySignature: () => {},
    });

    expect(decoded.notificationType).to.equal("DID_RENEW");
    expect(decoded.data.environment).to.equal("Sandbox");
  });

  it("rejects malformed signed payloads", () => {
    expect(() => verifyAppleSignedPayloadSignature("bad-payload")).to.throw();
  });

  it("parses signed date with fallback", () => {
    const fallback = Date.UTC(2026, 2, 8, 12, 0, 0);
    expect(parseAppleNotificationSignedDate("1700000000000", fallback)).to.equal(
      1700000000000
    );
    expect(parseAppleNotificationSignedDate(undefined, fallback)).to.equal(
      fallback
    );
  });
});
