const { expect } = require("chai");
const functionsTest = require("firebase-functions-test")();
const { https: httpsFns } = require("firebase-functions/v1");
const functions = require("../lib/index.js");

describe("call signaling", () => {
  after(() => functionsTest.cleanup());

  it("parseCallType allows audio/video only", () => {
    const { parseCallType } = functions.__test__helpers;

    expect(parseCallType("audio")).to.equal("audio");
    expect(parseCallType("video")).to.equal("video");
    expect(() => parseCallType("screen")).to.throw(httpsFns.HttpsError).with.property(
      "code",
      "invalid-argument"
    );
  });

  it("parseSafetyEventType allows only supported capture events", () => {
    const { parseSafetyEventType } = functions.__test__helpers;
    expect(parseSafetyEventType("screenshot")).to.equal("screenshot");
    expect(parseSafetyEventType("recording_started")).to.equal(
      "recording_started"
    );
    expect(() => parseSafetyEventType("other")).to.throw(httpsFns.HttpsError).with.property(
      "code",
      "invalid-argument"
    );
  });

  it("rate limit helper enforces a 10-second interval", () => {
    const { isRateLimitExceeded } = functions.__test__helpers;

    expect(isRateLimitExceeded(1000, 9000)).to.equal(true);
    expect(isRateLimitExceeded(1000, 11000)).to.equal(false);
  });

  it("buildIceServers always includes default STUN servers", () => {
    const { buildIceServers } = functions.__test__helpers;
    const previous = process.env.TURN_SERVERS_JSON;
    delete process.env.TURN_SERVERS_JSON;
    delete process.env.TURN_URLS;
    delete process.env.TURN_USERNAME;
    delete process.env.TURN_CREDENTIAL;

    const servers = buildIceServers();
    const urls = servers.flatMap((s) =>
      Array.isArray(s.urls) ? s.urls : [s.urls]
    );

    expect(urls).to.include("stun:stun.l.google.com:19302");
    expect(urls).to.include("stun:stun1.l.google.com:19302");

    if (previous !== undefined) process.env.TURN_SERVERS_JSON = previous;
  });

  it("initiateCall rejects unauthenticated requests", async () => {
    const wrapped = functionsTest.wrap(functions.initiateCall);

    try {
      await wrapped({ receiverId: "user-2", type: "audio" }, { auth: null });
      throw new Error("expected unauthenticated");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("unauthenticated");
    }
  });

  it("initiateCall validates receiverId", async () => {
    const wrapped = functionsTest.wrap(functions.initiateCall);

    try {
      await wrapped({ receiverId: " " }, { auth: { uid: "user-1" } });
      throw new Error("expected invalid-argument");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("invalid-argument");
    }
  });

  it("endCall validates callId", async () => {
    const wrapped = functionsTest.wrap(functions.endCall);

    try {
      await wrapped({}, { auth: { uid: "user-1" } });
      throw new Error("expected invalid-argument");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("invalid-argument");
    }
  });

  it("addIceCandidate validates target and candidate before backend access", async () => {
    const wrapped = functionsTest.wrap(functions.addIceCandidate);

    try {
      await wrapped(
        { callId: "call-1", target: "invalid", candidate: { candidate: "x" } },
        { auth: { uid: "user-1" } }
      );
      throw new Error("expected invalid-argument");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("invalid-argument");
    }

    try {
      await wrapped(
        { callId: "call-1", target: "caller" },
        { auth: { uid: "user-1" } }
      );
      throw new Error("expected invalid-argument");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("invalid-argument");
    }
  });

  it("getIceServers requires auth", async () => {
    const wrapped = functionsTest.wrap(functions.getIceServers);

    try {
      await wrapped({}, { auth: null });
      throw new Error("expected unauthenticated");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("unauthenticated");
    }
  });

  it("notifyCallSafetyEvent requires auth", async () => {
    const wrapped = functionsTest.wrap(functions.notifyCallSafetyEvent);

    try {
      await wrapped(
        {
          targetUserId: "user-2",
          eventType: "screenshot",
          callId: "call-1",
        },
        { auth: null }
      );
      throw new Error("expected unauthenticated");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("unauthenticated");
    }
  });

  it("notifyCallSafetyEvent validates event type", async () => {
    const wrapped = functionsTest.wrap(functions.notifyCallSafetyEvent);

    try {
      await wrapped(
        {
          targetUserId: "user-2",
          eventType: "invalid_event",
          callId: "call-1",
        },
        { auth: { uid: "user-1" } }
      );
      throw new Error("expected invalid-argument");
    } catch (err) {
      expect(err).to.be.instanceOf(httpsFns.HttpsError);
      expect(err.code).to.equal("invalid-argument");
    }
  });
});
