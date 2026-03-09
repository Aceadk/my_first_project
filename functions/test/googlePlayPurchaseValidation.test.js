const { expect } = require("chai");

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: "demo-project",
  databaseURL: "https://demo-project.firebaseio.com",
});

const functions = require("../lib/index.js");

describe("google play purchase validation helpers", () => {
  const {
    normalizeGooglePlayPackageName,
    hashPurchaseToken,
    buildGoogleSubscriptionValidationUrl,
    fetchGoogleSubscriptionValidation,
    deriveGoogleSubscriptionEntitlement,
  } = functions.__test__helpers;

  it("normalizes package names", () => {
    expect(normalizeGooglePlayPackageName("  com.example.app  ")).to.equal(
      "com.example.app"
    );
    expect(normalizeGooglePlayPackageName("   ")).to.equal(null);
    expect(normalizeGooglePlayPackageName(null)).to.equal(null);
  });

  it("builds encoded androidpublisher validation URL", () => {
    const url = buildGoogleSubscriptionValidationUrl({
      packageName: "com.example.app",
      productId: "plus.monthly",
      purchaseToken: "tok/with?chars",
    });

    expect(url).to.equal(
      "https://androidpublisher.googleapis.com/androidpublisher/v3/" +
        "applications/com.example.app/purchases/subscriptions/" +
        "plus.monthly/tokens/tok%2Fwith%3Fchars"
    );
  });

  it("hashes purchase token deterministically", () => {
    const hashA = hashPurchaseToken("token-1");
    const hashB = hashPurchaseToken("token-1");
    const hashC = hashPurchaseToken("token-2");

    expect(hashA).to.equal(hashB);
    expect(hashA).to.not.equal(hashC);
    expect(hashA).to.match(/^[a-f0-9]{64}$/);
  });

  it("derives plus entitlement for active paid subscription", () => {
    const now = Date.UTC(2026, 2, 8, 12, 0, 0);
    const entitlement = deriveGoogleSubscriptionEntitlement(
      {
        expiryTimeMillis: String(now + 60 * 60 * 1000),
        paymentState: 1,
        autoRenewing: true,
      },
      now
    );

    expect(entitlement.plan).to.equal("plus");
    expect(entitlement.status).to.equal("active");
    expect(entitlement.cancelAtPeriodEnd).to.equal(false);
  });

  it("derives free entitlement for pending payment", () => {
    const now = Date.UTC(2026, 2, 8, 12, 0, 0);
    const entitlement = deriveGoogleSubscriptionEntitlement(
      {
        expiryTimeMillis: String(now + 60 * 60 * 1000),
        paymentState: 0,
        autoRenewing: true,
      },
      now
    );

    expect(entitlement.plan).to.equal("free");
    expect(entitlement.status).to.equal("pending");
  });

  it("fetches Google validation payload with bearer auth", async () => {
    let capturedUrl = null;
    let capturedAuth = null;
    const payload = {
      orderId: "GPA.1234-5678-9012-34567",
      expiryTimeMillis: "1700000000000",
      paymentState: 1,
    };

    const result = await fetchGoogleSubscriptionValidation(
      {
        packageName: "com.example.app",
        productId: "plus_monthly",
        purchaseToken: "purchase-token-123",
      },
      {
        accessTokenProvider: async () => "access-token-xyz",
        fetchImpl: async (url, init) => {
          capturedUrl = String(url);
          capturedAuth = init?.headers?.Authorization;
          return {
            ok: true,
            status: 200,
            json: async () => payload,
            text: async () => "",
          };
        },
      }
    );

    expect(capturedUrl).to.contain(
      "/applications/com.example.app/purchases/subscriptions/plus_monthly/tokens/purchase-token-123"
    );
    expect(capturedAuth).to.equal("Bearer access-token-xyz");
    expect(result.orderId).to.equal(payload.orderId);
  });

  it("maps 404 validation responses to not-found errors", async () => {
    try {
      await fetchGoogleSubscriptionValidation(
        {
          packageName: "com.example.app",
          productId: "plus_monthly",
          purchaseToken: "missing-token",
        },
        {
          accessTokenProvider: async () => "access-token-xyz",
          fetchImpl: async () => ({
            ok: false,
            status: 404,
            json: async () => ({}),
            text: async () => "missing",
          }),
        }
      );
      throw new Error("expected validation helper to throw");
    } catch (err) {
      expect(err).to.have.property("code", "not-found");
    }
  });
});
