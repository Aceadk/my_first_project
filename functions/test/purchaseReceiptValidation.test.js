const { expect } = require("chai");
const { https: httpsFns } = require("firebase-functions/v1");

process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({
  projectId: "demo-project",
  databaseURL: "https://demo-project.firebaseio.com",
});

const functions = require("../lib/index.js");

describe("purchase receipt validation dispatch helpers", () => {
  const {
    normalizePurchaseValidationPlatform,
    verifyPurchaseReceiptForUser,
  } = functions.__test__helpers;

  it("normalizes receipt validation platform aliases", () => {
    expect(normalizePurchaseValidationPlatform("android")).to.equal(
      "google_play",
    );
    expect(normalizePurchaseValidationPlatform("google_play")).to.equal(
      "google_play",
    );
    expect(normalizePurchaseValidationPlatform("ios")).to.equal("app_store");
    expect(normalizePurchaseValidationPlatform("appstore")).to.equal(
      "app_store",
    );
    expect(normalizePurchaseValidationPlatform("stripe")).to.equal(null);
  });

  it("dispatches Google receipts to the Google validator", async () => {
    let captured = null;

    const result = await verifyPurchaseReceiptForUser(
      {
        uid: "user-1",
        platform: "android",
        productId: "plus_monthly",
        receiptData: "purchase-token-123",
        packageName: "com.example.app",
      },
      {
        verifyGooglePurchase: async (params) => {
          captured = params;
          return {
            plan: "plus",
            status: "active",
            provider: "google_play",
            productId: params.productId,
            orderId: "GPA.1234",
            currentPeriodEnd: 1767225600,
            cancelAtPeriodEnd: false,
          };
        },
        verifyApplePurchase: async () => {
          throw new Error("Apple validator should not run.");
        },
      },
    );

    expect(captured).to.deep.equal({
      uid: "user-1",
      productId: "plus_monthly",
      purchaseToken: "purchase-token-123",
      packageName: "com.example.app",
    });
    expect(result.provider).to.equal("google_play");
    expect(result.orderId).to.equal("GPA.1234");
  });

  it("dispatches Apple receipts to the Apple validator", async () => {
    let captured = null;

    const result = await verifyPurchaseReceiptForUser(
      {
        uid: "user-1",
        platform: "ios",
        productId: "plus_monthly",
        receiptData: "2000000123456789",
      },
      {
        verifyGooglePurchase: async () => {
          throw new Error("Google validator should not run.");
        },
        verifyApplePurchase: async (params) => {
          captured = params;
          return {
            plan: "plus",
            status: "active",
            provider: "app_store",
            productId: params.productId,
            transactionId: params.transactionId,
            originalTransactionId: "2000000111111111",
            currentPeriodEnd: 1767225600,
            cancelAtPeriodEnd: false,
          };
        },
      },
    );

    expect(captured).to.deep.equal({
      uid: "user-1",
      productId: "plus_monthly",
      transactionId: "2000000123456789",
    });
    expect(result.provider).to.equal("app_store");
    expect(result.transactionId).to.equal("2000000123456789");
  });

  it("rejects unsupported receipt validation platforms", async () => {
    try {
      await verifyPurchaseReceiptForUser({
        uid: "user-1",
        platform: "web",
        receiptData: "receipt",
      });
      throw new Error("expected helper to throw");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("invalid-argument");
    }
  });

  it("requires a productId for Google receipts", async () => {
    try {
      await verifyPurchaseReceiptForUser(
        {
          uid: "user-1",
          platform: "android",
          receiptData: "purchase-token-123",
        },
        {
          verifyGooglePurchase: async () => {
            throw new Error("Google validator should not run.");
          },
          verifyApplePurchase: async () => {
            throw new Error("Apple validator should not run.");
          },
        },
      );
      throw new Error("expected helper to throw");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("invalid-argument");
    }
  });
});
