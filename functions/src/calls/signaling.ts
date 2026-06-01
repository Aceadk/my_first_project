import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { callable as makeCallable, type CallableContext } from "../shared/callable";

const CALLS_COLLECTION = "calls";
const RING_TIMEOUT_MS = 30_000;
const RATE_LIMIT_WINDOW_MS = 10_000;

interface InitiateCallRequest {
  receiverId?: string;
  type?: "audio" | "video" | string;
  offer?: Record<string, unknown>;
}

interface AnswerCallRequest {
  callId?: string;
  answer?: Record<string, unknown>;
}

interface EndCallRequest {
  callId?: string;
  reason?: string;
}

interface AddIceCandidateRequest {
  callId?: string;
  target?: "caller" | "receiver" | "all" | string;
  candidate?: Record<string, unknown>;
}

interface NotifyCallSafetyEventRequest {
  targetUserId?: string;
  eventType?: string;
  callId?: string;
  isVideoCall?: boolean;
}

interface IceServerConfig {
  urls: string | string[];
  username?: string;
  credential?: string;
}

const ALLOWED_SAFETY_EVENTS = [
  "screenshot",
  "recording_started",
  "recording_stopped",
] as const;

function requireAuth(context: CallableContext, action: string): string {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      `You must be logged in to ${action}.`
    );
  }
  return uid;
}

function requireString(value: unknown, field: string, maxLength = 256): string {
  const str = typeof value === "string" ? value.trim() : "";
  if (!str) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} is required.`
    );
  }
  if (str.length > maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} exceeds maximum length of ${maxLength} characters.`
    );
  }
  return str;
}

function parseCallType(value: unknown): "audio" | "video" {
  const normalized =
    typeof value === "string" ? value.trim().toLowerCase() : "audio";
  if (normalized === "audio" || normalized === "video") return normalized;
  throw new functions.https.HttpsError(
    "invalid-argument",
    "type must be either 'audio' or 'video'."
  );
}

function isRateLimitExceeded(lastInitiatedAtMs: number, nowMs: number): boolean {
  return nowMs - lastInitiatedAtMs < RATE_LIMIT_WINDOW_MS;
}

function parseIceServersFromEnv(): IceServerConfig[] {
  const parsedFromJson = process.env.TURN_SERVERS_JSON?.trim();
  if (parsedFromJson) {
    try {
      const list = JSON.parse(parsedFromJson) as unknown;
      if (Array.isArray(list)) {
        const validated = list
          .filter((item) => item && typeof item === "object")
          .map((item) => item as IceServerConfig)
          .filter((item) => Boolean(item.urls));
        if (validated.length > 0) return validated;
      }
    } catch (error) {
      console.warn("TURN_SERVERS_JSON parse failed. Falling back to params.", {
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  const turnUrls = process.env.TURN_URLS?.trim();
  const turnUsername = process.env.TURN_USERNAME?.trim();
  const turnCredential = process.env.TURN_CREDENTIAL?.trim();
  if (turnUrls && turnUsername && turnCredential) {
    return [
      {
        urls: turnUrls.split(",").map((v) => v.trim()).filter(Boolean),
        username: turnUsername,
        credential: turnCredential,
      },
    ];
  }

  return [];
}

function buildIceServers(): IceServerConfig[] {
  const stunDefaults: IceServerConfig[] = [
    { urls: ["stun:stun.l.google.com:19302"] },
    { urls: ["stun:stun1.l.google.com:19302"] },
  ];
  return [...parseIceServersFromEnv(), ...stunDefaults];
}

async function getFcmTokens(userId: string): Promise<string[]> {
  const snap = await admin
    .firestore()
    .collection("users")
    .doc(userId)
    .collection("fcmTokens")
    .get();

  if (snap.empty) return [];
  return snap.docs.map((d) => d.id).filter((token) => token.length > 0);
}

interface CallNotificationPrefs {
  push: boolean;
  mutedCalls: string[];
}

function normalizeMutedList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const normalized = new Set<string>();
  for (const item of value) {
    if (typeof item !== "string") continue;
    const trimmed = item.trim();
    if (trimmed.length > 0 && trimmed.length <= 128) {
      normalized.add(trimmed);
    }
  }
  return [...normalized];
}

function normalizeCallNotificationPrefs(
  rawPrefs: Record<string, unknown>
): CallNotificationPrefs {
  return {
    push: rawPrefs.push !== false,
    mutedCalls: normalizeMutedList(rawPrefs.mutedCalls),
  };
}

async function getCallNotificationPrefs(
  userId: string
): Promise<CallNotificationPrefs> {
  try {
    const doc = await admin.firestore().collection("users").doc(userId).get();
    const prefs =
      (doc.data()?.notificationPrefs as Record<string, unknown> | undefined) ?? {};
    return normalizeCallNotificationPrefs(prefs);
  } catch {
    return normalizeCallNotificationPrefs({});
  }
}

function isCallNotificationAllowed(
  prefs: CallNotificationPrefs,
  category: "calls" | "safetyAlerts",
  fromUserId?: string
): boolean {
  if (category === "safetyAlerts") return true;
  if (!prefs.push) return false;
  if (fromUserId && prefs.mutedCalls.includes(fromUserId)) return false;
  return true;
}

async function hasBlockingRelationship(
  recipientId: string,
  actorId: string
): Promise<boolean> {
  if (recipientId === actorId) return false;
  const db = admin.firestore();
  const [recipientBlockedActor, actorBlockedRecipient] = await Promise.all([
    db.collection("blocks").doc(`${recipientId}_${actorId}`).get(),
    db.collection("blocks").doc(`${actorId}_${recipientId}`).get(),
  ]);
  return recipientBlockedActor.exists || actorBlockedRecipient.exists;
}

function toStringMap(payload: Record<string, unknown>): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [key, value] of Object.entries(payload)) {
    if (value === null || value === undefined) continue;
    result[key] = String(value);
  }
  return result;
}

async function sendPushToUser(
  userId: string,
  payload: {
    title: string;
    body: string;
    data?: Record<string, unknown>;
    highPriority?: boolean;
    category?: "calls" | "safetyAlerts";
    fromUserId?: string;
  }
): Promise<number> {
  const category = payload.category ?? "calls";
  const prefs = await getCallNotificationPrefs(userId);
  if (!isCallNotificationAllowed(prefs, category, payload.fromUserId)) {
    return 0;
  }
  if (
    payload.fromUserId &&
    category !== "safetyAlerts" &&
    (await hasBlockingRelationship(userId, payload.fromUserId))
  ) {
    return 0;
  }

  const tokens = await getFcmTokens(userId);
  if (tokens.length === 0) return 0;

  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: toStringMap(payload.data ?? {}),
  };

  if (payload.highPriority) {
    message.android = {
      priority: "high",
      ttl: 0,
    };
    message.apns = {
      headers: {
        "apns-priority": "10",
      },
      payload: {
        aps: {
          sound: "default",
        },
      },
    };
  }

  await admin.messaging().sendEachForMulticast(message);
  return tokens.length;
}

function parseSafetyEventType(value: unknown): (typeof ALLOWED_SAFETY_EVENTS)[number] {
  const eventType =
    typeof value === "string" ? value.trim().toLowerCase() : "";
  if (ALLOWED_SAFETY_EVENTS.includes(eventType as (typeof ALLOWED_SAFETY_EVENTS)[number])) {
    return eventType as (typeof ALLOWED_SAFETY_EVENTS)[number];
  }
  throw new functions.https.HttpsError(
    "invalid-argument",
    `eventType must be one of: ${ALLOWED_SAFETY_EVENTS.join(", ")}`
  );
}

function assertCallParticipant(
  callData: FirebaseFirestore.DocumentData,
  uid: string
): void {
  const callerId = callData.callerId as string | undefined;
  const receiverId = callData.receiverId as string | undefined;
  if (uid !== callerId && uid !== receiverId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You are not a participant in this call."
    );
  }
}

export async function initiateCallForUser({
  callerId,
  receiverId,
  type,
  offer,
}: {
  callerId: string;
  receiverId: string;
  type: "audio" | "video";
  offer?: Record<string, unknown> | null;
}): Promise<{ callId: string; status: "ringing"; expiresAtMs: number }> {
  if (callerId === receiverId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You cannot call yourself."
    );
  }

  const db = admin.firestore();
  const nowMs = Date.now();
  const now = admin.firestore.Timestamp.fromMillis(nowMs);
  const expiresAt = admin.firestore.Timestamp.fromMillis(nowMs + RING_TIMEOUT_MS);

  const callerRateRef = db
    .collection("users")
    .doc(callerId)
    .collection("callLimits")
    .doc("initiate");

  await db.runTransaction(async (tx) => {
    const rateSnap = await tx.get(callerRateRef);
    const lastInitiatedAt = rateSnap.exists
      ? (rateSnap.data()?.lastInitiatedAt as FirebaseFirestore.Timestamp | undefined)
      : undefined;
    const lastInitiatedAtMs = lastInitiatedAt?.toMillis() ?? 0;

    if (isRateLimitExceeded(lastInitiatedAtMs, nowMs)) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "You can initiate only one call every 10 seconds."
      );
    }

    tx.set(
      callerRateRef,
      {
        lastInitiatedAt: now,
        updatedAt: now,
      },
      { merge: true }
    );
  });

  const callRef = db.collection(CALLS_COLLECTION).doc();
  await callRef.set({
    callId: callRef.id,
    callerId,
    receiverId,
    participants: [callerId, receiverId],
    type,
    status: "ringing",
    createdAt: now,
    updatedAt: now,
    expiresAt,
    answeredAt: null,
    endedAt: null,
    endReason: null,
    offer: offer ?? null,
  });

  try {
    await sendPushToUser(receiverId, {
      title: type === "video" ? "Incoming video call" : "Incoming audio call",
      body: "Open Crush to answer.",
      data: {
        type: "incoming_call",
        callId: callRef.id,
        callerId,
        receiverId,
        callType: type,
        isVideoCall: type === "video",
        targetRoute: "/incoming-call",
      },
      highPriority: true,
      category: "calls",
      fromUserId: callerId,
    });
  } catch (error) {
    console.warn("incoming_call_push_failed", {
      callId: callRef.id,
      receiverId,
      error: error instanceof Error ? error.message : String(error),
    });
  }

  return {
    callId: callRef.id,
    status: "ringing",
    expiresAtMs: nowMs + RING_TIMEOUT_MS,
  };
}

export async function endCallForUser({
  uid,
  callId,
  reason,
}: {
  uid: string;
  callId: string;
  reason?: string | null;
}): Promise<{ callId: string; status: "ended"; endReason: string }> {
  const normalizedReason = reason?.trim() || "userHangup";
  const db = admin.firestore();
  const callRef = db.collection(CALLS_COLLECTION).doc(callId);
  const now = admin.firestore.Timestamp.now();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(callRef);
    if (!snap.exists) {
      throw new functions.https.HttpsError("not-found", "Call not found.");
    }

    const callData = snap.data() ?? {};
    assertCallParticipant(callData, uid);

    const currentStatus = String(callData.status ?? "");
    if (currentStatus === "ended" || currentStatus === "missed") {
      return;
    }

    tx.update(callRef, {
      status: "ended",
      endedAt: now,
      endReason: normalizedReason,
      updatedAt: now,
    });
  });

  return {
    callId,
    status: "ended",
    endReason: normalizedReason,
  };
}

export const initiateCall = makeCallable<InitiateCallRequest>(
  async (data, context) => {
    const callerId = requireAuth(context, "initiate a call");
    const receiverId = requireString(data?.receiverId, "receiverId", 128);
    const type = parseCallType(data?.type);
    return initiateCallForUser({
      callerId,
      receiverId,
      type,
      offer: data?.offer ?? null,
    });
  },
  { action: "initiateCall" }
);

export const answerCall = makeCallable<AnswerCallRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "answer a call");
    const callId = requireString(data?.callId, "callId", 128);
    const db = admin.firestore();
    const callRef = db.collection(CALLS_COLLECTION).doc(callId);
    const now = admin.firestore.Timestamp.now();

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(callRef);
      if (!snap.exists) {
        throw new functions.https.HttpsError("not-found", "Call not found.");
      }

      const callData = snap.data() ?? {};
      assertCallParticipant(callData, uid);
      if ((callData.receiverId as string | undefined) !== uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only the receiver can answer this call."
        );
      }

      const currentStatus = String(callData.status ?? "");
      if (currentStatus !== "ringing") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Call is no longer in ringing state."
        );
      }

      tx.update(callRef, {
        status: "ongoing",
        answeredAt: now,
        updatedAt: now,
        answer: data?.answer ?? null,
      });
    });

    return {
      callId,
      status: "ongoing",
    };
  },
  { action: "answerCall" }
);

export const endCall = makeCallable<EndCallRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "end a call");
    const callId = requireString(data?.callId, "callId", 128);
    return endCallForUser({
      uid,
      callId,
      reason: data?.reason,
    });
  },
  { action: "endCall" }
);

export const addIceCandidate = makeCallable<AddIceCandidateRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "exchange ICE candidates");
    const callId = requireString(data?.callId, "callId", 128);
    const target = requireString(data?.target, "target", 24).toLowerCase();

    if (!["caller", "receiver", "all"].includes(target)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "target must be 'caller', 'receiver', or 'all'."
      );
    }

    if (!data?.candidate || typeof data.candidate !== "object") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "candidate is required."
      );
    }

    const db = admin.firestore();
    const callRef = db.collection(CALLS_COLLECTION).doc(callId);
    const callSnap = await callRef.get();

    if (!callSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Call not found.");
    }

    const callData = callSnap.data() ?? {};
    assertCallParticipant(callData, uid);

    const candidateRef = callRef.collection("iceCandidates").doc();
    await candidateRef.set({
      callId,
      senderId: uid,
      target,
      candidate: data.candidate,
      createdAt: admin.firestore.Timestamp.now(),
    });

    await callRef.set(
      {
        updatedAt: admin.firestore.Timestamp.now(),
      },
      { merge: true }
    );

    return {
      callId,
      candidateId: candidateRef.id,
    };
  },
  { action: "addIceCandidate" }
);

export const notifyCallSafetyEvent = makeCallable<NotifyCallSafetyEventRequest>(
  async (data, context) => {
    const actorId = requireAuth(context, "notify call safety event");
    const targetUserId = requireString(data?.targetUserId, "targetUserId", 128);
    const eventType = parseSafetyEventType(data?.eventType);
    const callId = data?.callId?.trim() || "unknown";
    const isVideoCall = data?.isVideoCall === true;

    if (actorId === targetUserId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUserId must be different from current user."
      );
    }

    const actorDoc = await admin.firestore().collection("users").doc(actorId).get();
    const actorProfile = (actorDoc.data()?.profile as Record<string, unknown> | undefined) ?? {};
    const actorName =
      (actorProfile.name as string | undefined)?.trim() ||
      (actorProfile.displayName as string | undefined)?.trim() ||
      "Your match";

    const body = eventType === "screenshot"
      ? `${actorName} took a screenshot during your call.`
      : eventType === "recording_started"
        ? `${actorName} started screen recording during your call.`
        : `${actorName} stopped screen recording during your call.`;

    const deliveredTo = await sendPushToUser(targetUserId, {
      title: "Call safety alert",
      body,
      data: {
        type: "call_safety_alert",
        eventType,
        callId,
        fromUserId: actorId,
        isVideoCall,
        targetRoute: "/safety",
      },
      highPriority: true,
      category: "safetyAlerts",
      fromUserId: actorId,
    });

    await admin
      .firestore()
      .collection("users")
      .doc(targetUserId)
      .collection("notifications")
      .add({
        type: "call_safety_alert",
        eventType,
        fromUserId: actorId,
        title: "Call safety alert",
        body,
        callId,
        createdAt: admin.firestore.Timestamp.now(),
      });

    return {
      eventType,
      deliveredTo,
    };
  },
  { action: "notifyCallSafetyEvent" }
);

export const getIceServers = makeCallable<Record<string, never>>(
  async (_data, context) => {
    requireAuth(context, "get ICE servers");
    return {
      iceServers: buildIceServers(),
      ttlSeconds: 3600,
    };
  },
  { action: "getIceServers" }
);

export const enforceCallRingTimeout = functions.firestore
  .document(`${CALLS_COLLECTION}/{callId}`)
  .onCreate(async (snapshot) => {
    const callData = snapshot.data();
    if (!callData || String(callData.status) !== "ringing") return null;
    const receiverId = (callData.receiverId as string | undefined) ?? "";
    const callerId = (callData.callerId as string | undefined) ?? "";
    const type = String(callData.type ?? "audio");

    await new Promise((resolve) => setTimeout(resolve, RING_TIMEOUT_MS));

    const db = admin.firestore();
    let timedOut = false;
    await db.runTransaction(async (tx) => {
      const latest = await tx.get(snapshot.ref);
      if (!latest.exists) return;
      const latestData = latest.data() ?? {};

      if (String(latestData.status) !== "ringing") return;

      tx.update(snapshot.ref, {
        status: "missed",
        endReason: "timeout",
        endedAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });
      timedOut = true;
    });

    if (timedOut && receiverId) {
      try {
        await sendPushToUser(receiverId, {
          title: "Missed call",
          body: `You missed a ${type} call.`,
          data: {
            type: "missed_call",
            callId: snapshot.id,
            callerId,
            receiverId,
            callType: type,
            targetRoute: "/call-history",
          },
          highPriority: false,
          category: "calls",
          fromUserId: callerId,
        });
      } catch (error) {
        console.warn("missed_call_fallback_push_failed", {
          callId: snapshot.id,
          receiverId,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }

    return null;
  });

export const __callSignalingTestHelpers = {
  parseCallType,
  parseSafetyEventType,
  isRateLimitExceeded,
  buildIceServers,
  normalizeCallNotificationPrefs,
  isCallNotificationAllowed,
};
