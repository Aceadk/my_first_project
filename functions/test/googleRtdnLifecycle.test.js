const { expect } = require("chai");

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: "demo-project",
  databaseURL: "https://demo-project.firebaseio.com",
});

const functions = require("../lib/index.js");

describe("google RTDN lifecycle helpers", () => {
  const {
    mapGoogleRtdnNotificationType,
    applyGoogleRtdnEntitlementOverride,
    decodeGoogleRtdnEnvelope,
    parseGoogleRtdnEventTime,
  } = functions.__test__helpers;

  it("maps on-hold notification type to forced free status", () => {
    const mapping = mapGoogleRtdnNotificationType(5);
    expect(mapping).to.deep.equal({
      status: "on_hold",
      forceFree: true,
    });
  });

  it("maps grace-period notification type to non-forced status", () => {
    const mapping = mapGoogleRtdnNotificationType(6);
    expect(mapping).to.deep.equal({
      status: "in_grace_period",
      forceFree: false,
    });
  });

  it("forces free entitlement for revoked subscriptions", () => {
    const now = Date.UTC(2026, 2, 8, 12, 0, 0);
    const entitlement = applyGoogleRtdnEntitlementOverride(
      {
        plan: "plus",
        status: "active",
        cancelAtPeriodEnd: false,
        currentPeriodEnd: Math.floor((now + 3600_000) / 1000),
        expiryTimeMillis: now + 3600_000,
      },
      {
        status: "revoked",
        forceFree: true,
      },
      now
    );

    expect(entitlement.plan).to.equal("free");
    expect(entitlement.status).to.equal("revoked");
    expect(entitlement.currentPeriodEnd).to.equal(null);
    expect(entitlement.expiryTimeMillis).to.equal(null);
  });

  it("keeps plus entitlement during canceled period-end window", () => {
    const now = Date.UTC(2026, 2, 8, 12, 0, 0);
    const entitlement = applyGoogleRtdnEntitlementOverride(
      {
        plan: "plus",
        status: "active",
        cancelAtPeriodEnd: false,
        currentPeriodEnd: Math.floor((now + 3600_000) / 1000),
        expiryTimeMillis: now + 3600_000,
      },
      {
        status: "canceled",
        forceFree: false,
      },
      now
    );

    expect(entitlement.plan).to.equal("plus");
    expect(entitlement.status).to.equal("canceled");
    expect(entitlement.cancelAtPeriodEnd).to.equal(true);
  });

  it("decodes RTDN Pub/Sub envelope payload", () => {
    const rawPayload = {
      packageName: "com.example.app",
      eventTimeMillis: "1700000000000",
      subscriptionNotification: {
        notificationType: 2,
        purchaseToken: "token-123",
        subscriptionId: "plus_monthly",
      },
    };
    const envelope = {
      message: {
        messageId: "msg-1",
        data: Buffer.from(JSON.stringify(rawPayload)).toString("base64"),
      },
    };

    const decoded = decodeGoogleRtdnEnvelope(envelope);
    expect(decoded.messageId).to.equal("msg-1");
    expect(decoded.payload.packageName).to.equal("com.example.app");
    expect(decoded.payload.subscriptionNotification.notificationType).to.equal(2);
  });

  it("accepts direct RTDN payloads", () => {
    const payload = {
      packageName: "com.example.app",
      subscriptionNotification: {
        notificationType: 4,
        purchaseToken: "token-xyz",
        subscriptionId: "plus_monthly",
      },
    };

    const decoded = decodeGoogleRtdnEnvelope(payload);
    expect(decoded.payload.subscriptionNotification.purchaseToken).to.equal(
      "token-xyz"
    );
    expect(decoded.messageId).to.equal(undefined);
  });

  it("parses event time with fallback", () => {
    const fallbackNow = Date.UTC(2026, 2, 8, 12, 0, 0);
    expect(parseGoogleRtdnEventTime("1700000000000", fallbackNow)).to.equal(
      1700000000000
    );
    expect(parseGoogleRtdnEventTime(undefined, fallbackNow)).to.equal(
      fallbackNow
    );
  });
});
