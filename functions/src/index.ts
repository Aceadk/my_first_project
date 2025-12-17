import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { BigQuery } from "@google-cloud/bigquery";
import Stripe from "stripe";
import { RtcTokenBuilder, RtcRole } from "agora-access-token";

const bigquery = new BigQuery();
const BQ_DATASET = "crushhour_ml";
const BQ_TABLE_INTERACTIONS = "interaction_events";

admin.initializeApp();
const db = admin.firestore();

const config = ((functions as unknown as { config?: () => unknown }).config?.() ??
  {}) as {
    stripe?: { secret?: string; webhook_secret?: string };
    agora?: { appid?: string; certificate?: string };
  };
const stripeSecret = config.stripe?.secret ?? "";
const stripeWebhookSecret = config.stripe?.webhook_secret ?? "";
const agoraAppId = config.agora?.appid ?? process.env.AGORA_APP_ID;
const agoraCertificate =
  config.agora?.certificate ?? process.env.AGORA_APP_CERTIFICATE;

const stripe = new Stripe(stripeSecret, {
  apiVersion: "2024-06-20",
});

type UserDoc = {
  id: string;
  email?: string;
  phoneNumber?: string;
  profile?: unknown;
  plan?: string;
  stripeCustomerId?: string;
  stripeSubscriptionId?: string;
  notificationPrefs?: Record<string, unknown>;
};

interface SwipeRequest {
  targetUserId?: string;
  attachedMessage?: string;
}

interface PreMatchRequest {
  targetUserId?: string;
  content?: string;
}

interface CheckoutSessionRequest {
  priceId?: string;
  successUrl?: string;
  cancelUrl?: string;
}

interface UnsendRequest {
  matchId?: string;
  messageId?: string;
}

interface ReportRequest {
  reporterId?: string;
  reportedId?: string;
  reason?: string;
  matchId?: string;
  messageId?: string;
  source?: string;
  description?: string;
}

interface BlockRequest {
  blockerId?: string;
  blockedId?: string;
}

interface AppealRequest {
  reason?: string;
  targetType?: string;
  targetId?: string;
}

const PROFILE_MIN_PHOTOS = 1;
const PROFILE_MIN_PROMPTS = 2;
const PROFILE_MIN_BIO_LENGTH = 40;
const PROFILE_MIN_INTERESTS = 3;
const DAILY_LIKE_LIMIT_FREE = 30;
const DAILY_LIKE_LIMIT_PLUS = 300;
const DISCOVERY_PAGE_SIZE = 120;
const BANNED_TERMS = ["kill", "terror", "hate", "shit", "fuck", "bitch", "spam", ];

type CallableContext = functions.https.CallableContext;
type CallableHandler<TData> = (
  data: TData,
  context: CallableContext
) => Promise<unknown>;

const isHttpsError = (err: unknown): err is functions.https.HttpsError => {
  return err instanceof functions.https.HttpsError;
};

function callable<TData>(handler: CallableHandler<TData>) {
  return functions.https.onCall(async (data: TData, context: CallableContext) => {
    try {
      return await handler(data, context);
    } catch (err) {
      if (isHttpsError(err)) {
        throw err;
      }
      console.error("Callable error", {
        name: handler.name || "anonymous",
        uid: context.auth?.uid,
        error: err,
      });
      throw new functions.https.HttpsError(
        "internal",
        "Unexpected error. Please try again later."
      );
    }
  });
}

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

function requireString(value: unknown, field: string): string {
  const str = typeof value === "string" ? value.trim() : "";
  if (!str) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} is required.`
    );
  }
  return str;
}

function optionalString(value: unknown): string | undefined {
  const str = typeof value === "string" ? value.trim() : "";
  return str.length > 0 ? str : undefined;
}

function toNumber(value: unknown): number | undefined {
  if (typeof value === "number" && !isNaN(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (!isNaN(parsed)) return parsed;
  }
  return undefined;
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return (value as unknown[])
    .map((v) => (typeof v === "string" ? v.trim() : ""))
    .filter((v) => v.length > 0);
}

type ProfileData = {
  bio?: unknown;
  photoUrls?: unknown;
  prompts?: unknown;
  interests?: unknown;
  jobTitle?: unknown;
  company?: unknown;
  school?: unknown;
  verificationBadge?: unknown;
  drinking?: unknown;
  smoking?: unknown;
  diet?: unknown;
  exercise?: unknown;
  gender?: unknown;
  age?: unknown;
  sexualOrientation?: unknown;
  preferences?: unknown;
  isVerified?: unknown;
  country?: unknown;
  city?: unknown;
  latitude?: unknown;
  longitude?: unknown;
};

interface DiscoveryRequest {
  limit?: number;
}

type ModerationDecision =
  | { status: "clean"; action: "allow"; reason?: string; severity: "low" }
  | {
      status: "flagged" | "held" | "pending_scan";
      action: "hold" | "scan";
      reason?: string;
      severity: "medium" | "high";
    };

function moderateContent(content: string, type: string): ModerationDecision {
  if (type !== "text") {
    return { status: "pending_scan", action: "scan", severity: "medium" };
  }
  const lower = content.toLowerCase();
  const hit = BANNED_TERMS.find((term) => lower.includes(term));
  if (hit) {
    return {
      status: "held",
      action: "hold",
      reason: `Prohibited content (${hit})`,
      severity: "high",
    };
  }
  return { status: "clean", action: "allow", severity: "low" };
}

function ensureProfileQuality(profile: ProfileData | null, action: string) {
  const photos = toStringArray(profile?.photoUrls);
  const prompts = toStringArray(profile?.prompts);
  const interests = toStringArray(profile?.interests);
  const bio =
    typeof profile?.bio === "string" ? (profile?.bio as string).trim() : "";
  const country = typeof profile?.country === "string" ? profile?.country : "";
  const city = typeof profile?.city === "string" ? profile?.city : "";

  const missing: string[] = [];
  if (photos.length < PROFILE_MIN_PHOTOS) {
    missing.push(`Add at least ${PROFILE_MIN_PHOTOS} photo(s).`);
  }
  if (bio.length < PROFILE_MIN_BIO_LENGTH) {
    missing.push(
      `Write a bio with at least ${PROFILE_MIN_BIO_LENGTH} characters.`
    );
  }
  if (prompts.length < PROFILE_MIN_PROMPTS) {
    missing.push(`Answer at least ${PROFILE_MIN_PROMPTS} prompts.`);
  }
  if (interests.length < PROFILE_MIN_INTERESTS) {
    missing.push(`Add at least ${PROFILE_MIN_INTERESTS} interests.`);
  }
  if (!city || !country) {
    missing.push("Add your city and country.");
  }

  if (missing.length > 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Complete your profile before ${action}: ${missing.join(" ")}`
    );
  }
}

// Helpers
async function getUser(uid: string): Promise<UserDoc> {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "User document not found."
    );
  }
  const data = snap.data() || {};
  return { id: snap.id, ...data } as UserDoc;
}

async function setUserPlan(
  uid: string,
  plan: "free" | "plus",
  extra?: { stripeCustomerId?: string; stripeSubscriptionId?: string }
) {
  const payload: Record<string, unknown> = { plan };
  if (extra?.stripeCustomerId) payload.stripeCustomerId = extra.stripeCustomerId;
  if (extra?.stripeSubscriptionId) {
    payload.stripeSubscriptionId = extra.stripeSubscriptionId;
  }
  await db.collection("users").doc(uid).set(payload, { merge: true });
}

async function ensureUserExists(uid: string): Promise<UserDoc> {
  return getUser(uid);
}

async function ensureNotBlocked(uid: string, targetUserId: string) {
  const blockedSnap = await db
    .collection("blocks")
    .where("blockerId", "in", [uid, targetUserId])
    .where("blockedId", "in", [uid, targetUserId])
    .limit(1)
    .get();

  if (!blockedSnap.empty) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You cannot interact with this user."
    );
  }
}

async function blockedUserIds(uid: string): Promise<Set<string>> {
  const snap = await db
    .collection("blocks")
    .where("blockerId", "==", uid)
    .get();
  const ids = new Set<string>();
  snap.forEach((doc) => {
    const data = doc.data();
    if (typeof data.blockedId === "string") {
      ids.add(data.blockedId);
    }
  });
  return ids;
}

function setCorsHeaders(res: functions.Response) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, stripe-signature");
}

async function ensureUserInMatch(matchId: string, uid: string) {
  const matchSnap = await db.collection("matches").doc(matchId).get();
  if (!matchSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Match not found.");
  }
  const matchData = matchSnap.data() as FirebaseFirestore.DocumentData;
  const userIds = (matchData.userIds || []) as string[];
  if (!userIds.includes(uid)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You are not part of this match."
    );
  }
  const otherUserId = userIds.find((id) => id !== uid);
  return { matchData, otherUserId };
}

async function flagUserForReview(userId: string, reason: string) {
  await db
    .collection("users")
    .doc(userId)
    .set(
      {
        safetyFlags: {
          status: "needs_review",
          lastReason: reason,
          lastFlaggedAt: admin.firestore.FieldValue.serverTimestamp(),
          autoFlags: admin.firestore.FieldValue.increment(1),
        },
      },
      { merge: true }
    );
}

async function getFcmTokens(userId: string): Promise<string[]> {
  const snap = await db
    .collection("users")
    .doc(userId)
    .collection("fcmTokens")
    .get();

  if (snap.empty) return [];
  return snap.docs.map((d) => d.id).filter((t) => !!t);
}

type NotificationCategory = "messages" | "matches" | "subscriptions";

async function getNotificationPrefs(userId: string): Promise<{
  push: boolean;
  messages: boolean;
  matches: boolean;
  subscriptions: boolean;
}> {
  try {
    const doc = await db.collection("users").doc(userId).get();
    const prefs = (doc.data()?.notificationPrefs as Record<string, unknown>) ?? {};
    const push = prefs.push !== false; // default true
    const messages = prefs.messages !== false;
    const matches = prefs.matches !== false;
    const subscriptions = prefs.subscriptions !== false;
    return { push, messages, matches, subscriptions };
  } catch (err) {
    console.warn("Failed to load notification prefs", { userId, err });
    return { push: true, messages: true, matches: true, subscriptions: true };
  }
}

async function getPushTokensFor(
  userId: string,
  category: NotificationCategory
): Promise<string[]> {
  const prefs = await getNotificationPrefs(userId);
  const allowed =
    prefs.push &&
    ((category === "messages" && prefs.messages) ||
      (category === "matches" && prefs.matches) ||
      (category === "subscriptions" && prefs.subscriptions));
  if (!allowed) return [];
  return getFcmTokens(userId);
}

async function sendNotification(message: admin.messaging.MulticastMessage) {
  if (!message.tokens || message.tokens.length === 0) return;
  await admin.messaging().sendEachForMulticast(message);
}

function haversineDistanceKm(
  lat1?: number,
  lon1?: number,
  lat2?: number,
  lon2?: number
): number | undefined {
  if (
    lat1 === undefined ||
    lon1 === undefined ||
    lat2 === undefined ||
    lon2 === undefined
  ) {
    return undefined;
  }
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

async function enforceDailyLikeLimit(uid: string, plan?: string) {
  const limit =
    (plan ?? "").toLowerCase() === "plus"
      ? DAILY_LIKE_LIMIT_PLUS
      : DAILY_LIKE_LIMIT_FREE;
  const todayKey = new Date().toISOString().slice(0, 10);
  const ref = db.collection("rateLimits").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? (snap.data() as Record<string, unknown>) : {};
    const dailyLikes = (data.dailyLikes as Record<string, number> | undefined) ?? {};
    const count = dailyLikes[todayKey] ?? 0;
    if (count >= limit) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        `Daily like limit reached (${limit}). Try again tomorrow.`
      );
    }
    dailyLikes[todayKey] = count + 1;
    tx.set(
      ref,
      {
        dailyLikes,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

export const reportUser = callable<ReportRequest>(async (data, context) => {
  const reporterId = requireAuth(context, "report a user");
  const reportedId = requireString(data?.reportedId, "reportedId");
  const reason = requireString(data?.reason, "reason");
  const matchId = optionalString(data?.matchId);
  const messageId = optionalString(data?.messageId);
  const source = optionalString(data?.source);
  const description = optionalString(data?.description);

  if (reportedId === reporterId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You cannot report yourself."
    );
  }

  await ensureUserExists(reportedId);

  await db.collection("reports").add({
    reporterId,
    reportedId,
    reason,
    matchId: matchId ?? null,
    messageId: messageId ?? null,
    source: source ?? null,
    description: description ?? null,
    status: "open",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
  );
  const openReportsSnap = await db
    .collection("reports")
    .where("reportedId", "==", reportedId)
    .where("createdAt", ">=", sevenDaysAgo)
    .get();

  await db
    .collection("users")
    .doc(reportedId)
    .set(
      {
        safetyFlags: {
          openReports: openReportsSnap.size,
          lastReportAt: admin.firestore.FieldValue.serverTimestamp(),
          lastReason: reason,
          status: openReportsSnap.size >= 3 ? "needs_review" : "watch",
        },
      },
      { merge: true }
    );

  if (openReportsSnap.size >= 5) {
    await db.collection("automatedFlags").add({
      userId: reportedId,
      reason: "multiple_reports",
      reportCount: openReportsSnap.size,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "open",
    });
  }

  return { ok: true };
});

export const blockUser = callable<BlockRequest>(async (data, context) => {
  const blockerId = requireAuth(context, "block a user");
  const blockedId = requireString(data?.blockedId, "blockedId");
  const blockerIdFromClient = optionalString(data?.blockerId);

  if (blockedId === blockerId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You cannot block yourself."
    );
  }
  if (blockerIdFromClient && blockerIdFromClient !== blockerId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Blocker mismatch."
    );
  }

  const docId = `${blockerId}_${blockedId}`;
  await db.collection("blocks").doc(docId).set({
    blockerId,
    blockedId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

export const unblockUser = callable<BlockRequest>(async (data, context) => {
  const blockerId = requireAuth(context, "unblock a user");
  const blockedId = requireString(data?.blockedId, "blockedId");
  const blockerIdFromClient = optionalString(data?.blockerId);

  if (blockerIdFromClient && blockerIdFromClient !== blockerId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Blocker mismatch."
    );
  }

  const docId = `${blockerId}_${blockedId}`;
  await db.collection("blocks").doc(docId).delete();
  return { ok: true };
});

export const appealSafetyAction = callable<AppealRequest>(async (data, context) => {
  const uid = requireAuth(context, "submit an appeal");
  const reason = requireString(data?.reason, "reason");
  const targetType = optionalString(data?.targetType) ?? "account";
  const targetId = optionalString(data?.targetId) ?? null;

  await db.collection("appeals").add({
    userId: uid,
    reason,
    targetType,
    targetId,
    status: "open",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db
    .collection("users")
    .doc(uid)
    .set(
      {
        safetyFlags: {
          appealOpen: true,
          lastAppealAt: admin.firestore.FieldValue.serverTimestamp(),
          lastReason: reason,
        },
      },
      { merge: true }
    );

  return { ok: true };
});

export const setTyping = callable<{
  matchId?: string;
  isTyping?: boolean;
}>(async (data, context) => {
  const uid = requireAuth(context, "update typing status");
  const matchId = requireString(data?.matchId, "matchId");
  const isTyping = !!data?.isTyping;

  await ensureUserInMatch(matchId, uid);
  await db
    .collection("matches")
    .doc(matchId)
    .set(
      { typing: { [uid]: isTyping }, typingUpdatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
  return { ok: true };
});

export const setPresenceStatus = callable<{ isOnline?: boolean }>(
  async (data, context) => {
    const uid = requireAuth(context, "update presence");
    const isOnline = !!data?.isOnline;
    await db
      .collection("users")
      .doc(uid)
      .set(
        {
          isOnline,
          lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    return { ok: true };
  }
);

export const setMediaSendingEnabled = callable<{
  matchId?: string;
  enabled?: boolean;
}>(async (data, context) => {
  const uid = requireAuth(context, "toggle media sending");
  const matchId = requireString(data?.matchId, "matchId");
  const enabled = !!data?.enabled;

  await ensureUserInMatch(matchId, uid);
  await db
    .collection("matches")
    .doc(matchId)
    .set(
      {
        mediaSendingEnabled: enabled,
        mediaUpdatedBy: uid,
        mediaUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  return { ok: true };
});

export const addReaction = callable<{
  matchId?: string;
  messageId?: string;
  emoji?: string;
}>(async (data, context) => {
  const uid = requireAuth(context, "add reaction");
  const matchId = requireString(data?.matchId, "matchId");
  const messageId = requireString(data?.messageId, "messageId");
  const emoji = requireString(data?.emoji, "emoji");

  await ensureUserInMatch(matchId, uid);
  await db
    .collection("matches")
    .doc(matchId)
    .collection("messages")
    .doc(messageId)
    .set(
      {
        reactions: { [uid]: emoji },
        reactionsUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  return { ok: true };
});

export const removeReaction = callable<{
  matchId?: string;
  messageId?: string;
}>(async (data, context) => {
  const uid = requireAuth(context, "remove reaction");
  const matchId = requireString(data?.matchId, "matchId");
  const messageId = requireString(data?.messageId, "messageId");

  await ensureUserInMatch(matchId, uid);
  await db
    .collection("matches")
    .doc(matchId)
    .collection("messages")
    .doc(messageId)
    .set(
      {
        reactions: { [uid]: admin.firestore.FieldValue.delete() },
        reactionsUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  return { ok: true };
});

export const unmatch = callable<{ matchId?: string }>(async (data, context) => {
  const uid = requireAuth(context, "unmatch");
  const matchId = requireString(data?.matchId, "matchId");
  const { otherUserId } = await ensureUserInMatch(matchId, uid);

  await db
    .collection("matches")
    .doc(matchId)
    .set(
      {
        status: "unmatched",
        unmatchedBy: uid,
        unmatchedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  if (otherUserId) {
    const tokens = await getFcmTokens(otherUserId);
    await sendNotification({
      tokens,
      notification: {
        title: "Match ended",
        body: "Someone unmatched this chat.",
      },
      data: { matchId, status: "unmatched" },
    });
  }

  return { ok: true };
});

export const onMessageCreated = functions.firestore
  .document("matches/{matchId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const toUserId = data?.toUserId as string | undefined;
    const fromUserId = data?.fromUserId as string | undefined;
    const type = (data?.type as string | undefined) ?? "text";
    const content = typeof data?.content === "string" ? data.content : "";
    if (!toUserId || !fromUserId) return;

    const decision = moderateContent(content, type);
    await snap.ref.set(
      {
        moderation: {
          status: decision.status,
          action: decision.action,
          reason: decision.reason ?? null,
          severity: decision.severity,
          flagged: decision.action !== "allow",
          reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      { merge: true }
    );

    if (decision.action === "hold") {
      await flagUserForReview(fromUserId, "message_moderation");
      return;
    }

    const tokens = await getPushTokensFor(toUserId, "messages");
    if (tokens.length === 0) return;

    await sendNotification({
      tokens,
      notification: {
        title: "New message",
        body: data?.content ? String(data.content).slice(0, 80) : "You have a new message.",
      },
      data: {
        matchId: context.params.matchId,
        fromUserId,
        type: data?.type ?? "text",
      },
    });
  });

export const onMatchCreated = functions.firestore
  .document("matches/{matchId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userIds = (data?.userIds as string[] | undefined) ?? [];
    if (userIds.length !== 2) return;

    const tokensByUser = await Promise.all(
      userIds.map(async (uid) => ({
        uid,
        tokens: await getPushTokensFor(uid, "matches"),
      }))
    );

    await Promise.all(
      tokensByUser.map(({ uid, tokens }) =>
        sendNotification({
          tokens,
          notification: {
            title: "You have a new match!",
            body: "Open CrushHour to start chatting.",
          },
          data: {
            matchId: context.params.matchId,
            userId: uid,
          },
        })
      )
    );
  });

export const onSubscriptionUpdated = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const beforePlan = change.before.data()?.plan;
    const afterPlan = change.after.data()?.plan;
    if (!afterPlan || beforePlan === afterPlan) return;

    const tokens = await getPushTokensFor(context.params.userId, "subscriptions");
    if (tokens.length === 0) return;

    const upgraded = beforePlan !== afterPlan && afterPlan === "plus";
    const downgraded = beforePlan === "plus" && afterPlan !== "plus";

    const title = upgraded
      ? "Thanks for upgrading!"
      : downgraded
      ? "Your subscription changed"
      : "Plan updated";
    const body = upgraded
      ? "Plus benefits are now active."
      : downgraded
      ? "Plus benefits are no longer active."
      : `Plan set to ${afterPlan}.`;

    await sendNotification({
      tokens,
      notification: { title, body },
      data: { plan: afterPlan },
    });
  });

export const fetchDiscoveryCandidates = callable<DiscoveryRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "fetch discovery candidates");
    const limitRaw = typeof data?.limit === "number" ? data.limit : 30;
    const limit = Math.min(Math.max(limitRaw, 5), 50);

    const me = await getUser(uid);
    const profile = (me.profile as ProfileData | null) ?? null;
    ensureProfileQuality(profile, "browsing");

    const prefs = (profile?.preferences as Record<string, unknown> | undefined) ?? {};
    const maxDistanceKm =
      toNumber(prefs.maxDistanceKm) !== undefined
        ? (toNumber(prefs.maxDistanceKm) as number)
        : 50;
    const minAge = toNumber(prefs.minAge) ?? 18;
    const maxAge = toNumber(prefs.maxAge) ?? 100;
    const showMeGenders = toStringArray(prefs.showMeGenders);

    const myLat = toNumber(profile?.latitude);
    const myLon = toNumber(profile?.longitude);
    const myCountry = typeof profile?.country === "string" ? profile?.country : "";
    const myCity = typeof profile?.city === "string" ? profile?.city : "";
    const myInterests = new Set(toStringArray(profile?.interests));

    const blockedIds = await blockedUserIds(uid);

    let query: FirebaseFirestore.Query = db
      .collection("users")
      .where("profile.preferences.hideFromDiscovery", "==", false)
      .where("profile.preferences.incognitoMode", "==", false)
      .limit(DISCOVERY_PAGE_SIZE);

    if (showMeGenders.length > 0 && showMeGenders.length <= 10) {
      query = query.where("profile.gender", "in", showMeGenders);
    }
    if (myCountry) {
      query = query.where("profile.country", "==", myCountry);
    }

    let snap: FirebaseFirestore.QuerySnapshot;
    try {
      snap = await query.get();
    } catch (err) {
      // Fallback to broader query if index/gender filters fail
      snap = await db
        .collection("users")
        .where("profile.preferences.hideFromDiscovery", "==", false)
        .limit(DISCOVERY_PAGE_SIZE)
        .get();
    }

    const candidates: Array<{
      id: string;
      profile: ProfileData;
      score: number;
      distanceKm?: number;
    }> = [];

    snap.forEach((doc) => {
      if (doc.id === uid) return;
      if (blockedIds.has(doc.id)) return;
      const data = doc.data() as Record<string, unknown>;
      const candidateProfile = (data.profile as ProfileData | undefined) ?? null;
      if (!candidateProfile) return;
      if (candidateProfile.preferences && (candidateProfile.preferences as any).hideFromDiscovery) {
        return;
      }
      const age = toNumber((candidateProfile as any).age);
      if (age && (age < minAge || age > maxAge)) return;
      const lat = toNumber(candidateProfile.latitude);
      const lon = toNumber(candidateProfile.longitude);
      const distanceKm = haversineDistanceKm(myLat, myLon, lat, lon);
      if (distanceKm !== undefined && distanceKm > maxDistanceKm + 5) {
        return;
      }
      if (!lat || !lon) {
        // Fall back to country/city match if location missing
        const candCountry =
          typeof candidateProfile.country === "string" ? candidateProfile.country : "";
        if (myCountry && candCountry && candCountry !== myCountry) return;
        const candCity = typeof candidateProfile.city === "string" ? candidateProfile.city : "";
        if (myCity && candCity && candCity !== myCity) return;
      }
      const interests = toStringArray(candidateProfile.interests);
      const sharedInterests = interests.filter((i) => myInterests.has(i)).length;
      const verifiedBoost =
        candidateProfile.verificationBadge || candidateProfile.isVerified ? 0.4 : 0;
      const distanceBoost =
        distanceKm !== undefined && maxDistanceKm > 0
          ? Math.max(0, (maxDistanceKm - distanceKm) / maxDistanceKm)
          : 0.1;
      const interestBoost = Math.min(sharedInterests * 0.05, 0.25);
      const baseScore = 1 + verifiedBoost + distanceBoost + interestBoost;

      candidates.push({
        id: doc.id,
        profile: candidateProfile,
        score: baseScore,
        distanceKm,
      });
    });

    candidates.sort((a, b) => (b.score ?? 0) - (a.score ?? 0));

    const limited = candidates.slice(0, limit);
    return {
      profiles: limited.map((c) => ({
        id: c.id,
        profile: c.profile,
        distanceKm: c.distanceKm,
        score: c.score,
      })),
      total: candidates.length,
    };
  }
);


// Swipe right (double opt-in + match creation)
export const swipeRight = callable<SwipeRequest>(async (data, context) => {
  const uid = requireAuth(context, "swipe right");
  const targetUserId = requireString(data?.targetUserId, "targetUserId");
  const attachedMessage = optionalString(data?.attachedMessage);

  if (targetUserId === uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "You cannot like yourself."
    );
  }

  await ensureUserExists(targetUserId);
  await ensureNotBlocked(uid, targetUserId);

  // Ensure current user has a profile
  const me = await getUser(uid);
  ensureProfileQuality(me.profile as ProfileData | null, "swiping");
  await enforceDailyLikeLimit(uid, (me.plan as string | undefined) ?? "free");

  // 1. Write like record
  const likeRef = db.collection("likes").doc();
  await likeRef.set({
    fromUserId: uid,
    toUserId: targetUserId,
    attachedMessage: attachedMessage ?? null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await bigquery
    .dataset(BQ_DATASET)
    .table(BQ_TABLE_INTERACTIONS)
    .insert({
      event_timestamp: new Date().toISOString(),
      event_type: "SWIPE_RIGHT",
      user_id: uid,
      other_user_id: targetUserId,
      liked: true,
      matched: false, // will update or log MATCH_CREATED later
    });

  // 2. Check for reverse like
  const reverseLikeSnap = await db
    .collection("likes")
    .where("fromUserId", "==", targetUserId)
    .where("toUserId", "==", uid)
    .limit(1)
    .get();

  if (reverseLikeSnap.empty) {
    // no mutual yet
    return { matched: false };
  }

  // 3. Mutual like → create (or reuse) match
  const existingMatchSnap = await db
    .collection("matches")
    .where("userIds", "array-contains", uid)
    .get();

  const existingDoc = existingMatchSnap.docs.find((doc) => {
    const userIds = doc.data().userIds as string[];
    return userIds.includes(targetUserId);
  });
  let existing: FirebaseFirestore.DocumentSnapshot | undefined = existingDoc;
  let matchId: string | undefined;

  if (!existing) {
    const matchRef = db.collection("matches").doc();
    await matchRef.set({
      userIds: [uid, targetUserId],
      status: "mutual",
      preMatchRequests: {
        [uid]: 0,
        [targetUserId]: 0,
      },
      pinnedForUser: {
        [uid]: false,
        [targetUserId]: false,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    existing = await matchRef.get();
    matchId = matchRef.id;
  } else {
    matchId = existing.id;
  }

  await bigquery
    .dataset(BQ_DATASET)
    .table(BQ_TABLE_INTERACTIONS)
    .insert({
      event_timestamp: new Date().toISOString(),
      event_type: "MATCH_CREATED",
      user_id: uid,
      other_user_id: targetUserId,
      match_id: matchId,
      matched: true,
    });

  return { matched: true, matchId };
});

// Swipe left (log only)
export const swipeLeft = callable<SwipeRequest>(async (data, context) => {
  const uid = requireAuth(context, "swipe left");
  const targetUserId = requireString(data?.targetUserId, "targetUserId");

  if (targetUserId === uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "You cannot like yourself."
    );
  }

  await ensureUserExists(targetUserId);
  await ensureNotBlocked(uid, targetUserId);

  const me = await getUser(uid);
  ensureProfileQuality(me.profile as ProfileData | null, "swiping");

  await bigquery
    .dataset(BQ_DATASET)
    .table(BQ_TABLE_INTERACTIONS)
    .insert({
      event_timestamp: new Date().toISOString(),
      event_type: "SWIPE_LEFT",
      user_id: uid,
      other_user_id: targetUserId,
      liked: false,
      matched: false,
    });

  return { ok: true };
});

// Pre-match message request (3 requests per sender until reply)
export const sendPreMatchMessageRequest = callable<PreMatchRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "send a pre-match message");
    const targetUserId = requireString(data?.targetUserId, "targetUserId");
    const content = requireString(data?.content, "content");

    if (targetUserId === uid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Cannot message yourself."
      );
    }

    await ensureUserExists(targetUserId);
    await ensureNotBlocked(uid, targetUserId);

    const me = await getUser(uid);
    ensureProfileQuality(me.profile as ProfileData | null, "sending requests");

    // Find or create a "pending match-like" doc for this pair
    const pairId =
      uid < targetUserId ? `${uid}_${targetUserId}` : `${targetUserId}_${uid}`;

    const preRef = db.collection("preMatchPairs").doc(pairId);
    const preSnap = await preRef.get();

    if (!preSnap.exists) {
      await preRef.set({
        users: [uid, targetUserId],
        requests: {
          [uid]: 0,
          [targetUserId]: 0,
        },
        lastRequestAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    const preData = (await preRef.get()).data()!;
    const requests = preData.requests || {};
    const myCount = (requests[uid] as number | undefined) ?? 0;

    if (myCount >= 3) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "You have reached the maximum of 3 message requests. Wait for a reply."
      );
    }

    // Increment my counter
    requests[uid] = myCount + 1;
    await preRef.update({
      requests,
      lastRequestAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Store the request message (optional UI for receiver)
    await preRef.collection("requests").add({
      fromUserId: uid,
      toUserId: targetUserId,
      content,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ok: true };
  }
);

// Unsend message (Plus only, sender-only)
export const unsendMessage = callable<UnsendRequest>(async (data, context) => {
  const uid = requireAuth(context, "unsend messages");
  const matchId = requireString(data?.matchId, "matchId");
  const messageId = requireString(data?.messageId, "messageId");

  // Plan check: Plus required
  const user = await getUser(uid);
  if ((user.plan || "").toLowerCase() !== "plus") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Unsend is only available on the Plus plan."
    );
  }

  // Load message
  const msgRef = db
    .collection("matches")
    .doc(matchId)
    .collection("messages")
    .doc(messageId);
  const msgSnap = await msgRef.get();

  if (!msgSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Message not found.");
  }

  const msgData = msgSnap.data() as FirebaseFirestore.DocumentData;

  // Ownership check
  if (msgData.fromUserId !== uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You can only unsend your own messages."
    );
  }

  // Ensure user is part of the match
  const matchSnap = await db.collection("matches").doc(matchId).get();
  if (!matchSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Match not found.");
  }
  const matchData = matchSnap.data() as FirebaseFirestore.DocumentData;
  const userIds = (matchData.userIds || []) as string[];
  if (!userIds.includes(uid)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You are not part of this match."
    );
  }
  const otherUserId = userIds.find((id) => id !== uid);
  if (!otherUserId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Match participants missing."
    );
  }
  await ensureNotBlocked(uid, otherUserId);

  // Soft delete for sender
  await msgRef.update({
    isDeletedForSender: true,
    unsentAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

// Create Stripe Checkout session for Plus plan
export const createCheckoutSession = callable<CheckoutSessionRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "start checkout");
    const priceId = requireString(data?.priceId, "priceId");
    const successUrl = requireString(data?.successUrl, "successUrl");
    const cancelUrl = requireString(data?.cancelUrl, "cancelUrl");

    const user = await getUser(uid);

    // Reuse existing Stripe customer if present on the user document.
    let customerId = (user.stripeCustomerId as string | undefined) || undefined;
    if (!customerId) {
      const customer = await stripe.customers.create({
        metadata: {
          firebaseUid: uid,
        },
        email: user.email || undefined,
        phone: user.phoneNumber || undefined,
      });
      customerId = customer.id;
      await setUserPlan(uid, "free", { stripeCustomerId: customerId });
    }

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      payment_method_types: ["card"],
      customer: customerId,
      client_reference_id: uid,
      metadata: { firebaseUid: uid },
      subscription_data: {
        metadata: { firebaseUid: uid },
      },
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: successUrl, // e.g. https://yourapp.com/success
      cancel_url: cancelUrl, // e.g. https://yourapp.com/cancel
    });

    return { url: session.url };
  }
);

export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  // Basic CORS handling for browser preflight and requests
  if (req.method === "OPTIONS") {
    setCorsHeaders(res);
    res.status(204).send("");
    return;
  }

  setCorsHeaders(res);

  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const signature = req.headers["stripe-signature"];
  if (!signature || Array.isArray(signature) || !stripeWebhookSecret) {
    res.status(400).send("Missing webhook signature or secret");
    return;
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      signature,
      stripeWebhookSecret
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Webhook signature verification failed", message);
    res.status(400).send(`Webhook Error: ${message}`);
    return;
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const uid =
          (session.metadata?.firebaseUid as string | undefined) ||
          (session.client_reference_id as string | undefined);
        const subscriptionId = session.subscription as string | undefined;
        const customerId = session.customer as string | undefined;
        if (uid) {
          await setUserPlan(uid, "plus", {
            stripeCustomerId: customerId,
            stripeSubscriptionId: subscriptionId,
          });
        }
        break;
      }
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        const uid = subscription.metadata?.firebaseUid as string | undefined;
        const status = subscription.status;
        const isActive =
          status === "active" ||
          status === "trialing" ||
          status === "past_due";
        if (uid) {
          await setUserPlan(uid, isActive ? "plus" : "free", {
            stripeCustomerId:
              (subscription.customer as string | undefined) || undefined,
            stripeSubscriptionId: subscription.id,
          });
        }
        break;
      }
      default:
        // Ignore other events for now.
        break;
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Error handling webhook", event.type, message);
    res.status(500).send("Webhook handler failed");
    return;
  }

  res.json({ received: true });
});

interface AgoraTokenRequest {
  channelName?: string;
  uid?: number;
  isVideoCall?: boolean;
}

// Sync subscription against Stripe and update Firestore if needed.
export const syncSubscriptionStatus = callable(async (_data, context) => {
  const uid = requireAuth(context, "sync subscription");
  if (!stripeSecret) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Stripe not configured."
    );
  }
  const user = await getUser(uid);
  const subscriptionId = optionalString(user.stripeSubscriptionId);
  const customerId = optionalString(user.stripeCustomerId);

  if (!subscriptionId && !customerId) {
    await setUserPlan(uid, "free");
    return { plan: "free", status: "none" };
  }

  let subscription: Stripe.Subscription | undefined;
  try {
    if (subscriptionId) {
      subscription = await stripe.subscriptions.retrieve(subscriptionId);
    } else if (customerId) {
      const list = await stripe.subscriptions.list({
        customer: customerId,
        status: "all",
        limit: 1,
      });
      subscription = list.data[0];
    }
  } catch (err) {
    console.error("syncSubscriptionStatus.retrieve_failed", err);
    throw new functions.https.HttpsError(
      "internal",
      "Could not verify subscription."
    );
  }

  if (!subscription) {
    await setUserPlan(uid, "free");
    return { plan: "free", status: "none" };
  }

  const status = subscription.status;
  const isActive =
    status === "active" || status === "trialing" || status === "past_due";
  const plan = isActive ? "plus" : "free";
  await setUserPlan(uid, plan, {
    stripeCustomerId:
      (subscription.customer as string | undefined) ?? customerId ?? undefined,
    stripeSubscriptionId: subscription.id,
  });

  return {
    plan,
    status,
    currentPeriodEnd: subscription.current_period_end,
    cancelAtPeriodEnd: subscription.cancel_at_period_end ?? false,
  };
});

// Expose helpers for testing
export const __test__helpers = {
  requireAuth,
  requireString,
  optionalString,
};

// Callable function to generate an Agora token for authenticated users
export const generateAgoraToken = callable<AgoraTokenRequest>(
  async (data, context) => {
    requireAuth(context, "start a call");

    const channelName = requireString(data?.channelName, "channelName");
    const uid = typeof data?.uid === "number" ? data.uid : 0;

    if (!agoraAppId || !agoraCertificate) {
      throw new functions.https.HttpsError(
        "internal",
        "Agora credentials not configured"
      );
    }

    const expirationSeconds = 3600;
    const currentTs = Math.floor(Date.now() / 1000);
    const privilegeExpireTime = currentTs + expirationSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      agoraAppId,
      agoraCertificate,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      privilegeExpireTime
    );

    return {
      token,
      appId: agoraAppId,
      channelName,
      uid,
      expireTime: privilegeExpireTime,
    };
  }
);

// HTTP endpoint for local testing (not authenticated)
export const testAgoraToken = functions.https.onRequest((req, res) => {
  // Basic CORS handling for browser preflight and requests
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.status(204).send("");
    return;
  }

  if (!agoraAppId || !agoraCertificate) {
    res.status(500).json({ error: "Agora credentials not configured" });
    return;
  }

  const channelNameParam = req.query.channel;
  const channelNameRaw = Array.isArray(channelNameParam)
    ? channelNameParam[0]
    : channelNameParam;
  const channelName =
    typeof channelNameRaw === "string" ? channelNameRaw : "test-channel";

  const uidParam = req.query.uid;
  const uidRaw = Array.isArray(uidParam) ? uidParam[0] : uidParam;
  const uid =
    (typeof uidRaw === "string" ? parseInt(uidRaw, 10) : NaN) || 123;

  const token = RtcTokenBuilder.buildTokenWithUid(
    agoraAppId,
    agoraCertificate,
    channelName,
    uid,
    RtcRole.PUBLISHER,
    Math.floor(Date.now() / 1000) + 3600
  );

  res.json({
    success: true,
    appId: agoraAppId,
    token,
    channelName,
    uid,
    note: "This is for testing only. Use generateAgoraToken for production.",
  });
});

// Callable function to return an Agora token for a call (uses auth UID)
export const getAgoraToken = callable<AgoraTokenRequest>(async (data, context) => {
  const uid = requireAuth(context, "get an Agora token");

  const channelName = requireString(data?.channelName, "channelName");
  const isVideoCall = (data?.isVideoCall as boolean | undefined) ?? true;

  if (!agoraAppId || !agoraCertificate) {
    throw new functions.https.HttpsError(
      "internal",
      "Agora credentials not configured"
    );
  }

  // Use the user's UID as Agora UID (convert to int hash from first bytes)
  const agoraUid = Number.parseInt(uid.slice(0, 8), 16) || 0;
  const role = RtcRole.PUBLISHER;
  const expireSeconds = 60 * 60; // 1 hour
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expireSeconds;

  const token = RtcTokenBuilder.buildTokenWithUid(
    agoraAppId,
    agoraCertificate,
    channelName,
    agoraUid,
    role,
    privilegeExpiredTs
  );

  return {
    token,
    uid: agoraUid,
    appId: agoraAppId,
    isVideoCall,
  };
});
