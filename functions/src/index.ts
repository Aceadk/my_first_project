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

// Swipe right (double opt-in + match creation)
export const swipeRight = functions.https.onCall(async (data: SwipeRequest, context) => {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in."
    );
  }

  const targetUserId = data.targetUserId;
  const attachedMessage = data.attachedMessage;

  if (!targetUserId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUserId is required."
    );
  }

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
  if (!me.profile) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Complete your profile before swiping."
    );
  }

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
export const swipeLeft = functions.https.onCall(async (data: SwipeRequest, context) => {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in."
    );
  }

  const targetUserId = data.targetUserId;

  if (!targetUserId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUserId is required."
    );
  }

  if (targetUserId === uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "You cannot like yourself."
    );
  }

  await ensureUserExists(targetUserId);
  await ensureNotBlocked(uid, targetUserId);

  const me = await getUser(uid);
  if (!me.profile) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Complete your profile before swiping."
    );
  }

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
export const sendPreMatchMessageRequest = functions.https.onCall(
  async (data: PreMatchRequest, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in."
      );
    }

    const targetUserId = data.targetUserId;
    const content = data.content;

    if (!targetUserId || !content) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUserId and content are required."
      );
    }

  if (targetUserId === uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Cannot message yourself."
    );
  }

  await ensureUserExists(targetUserId);
  await ensureNotBlocked(uid, targetUserId);

  const me = await getUser(uid);
  if (!me.profile) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Complete your profile before sending requests."
    );
  }

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
export const unsendMessage = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in to unsend messages."
    );
  }

  const matchId = data.matchId as string | undefined;
  const messageId = data.messageId as string | undefined;

  if (!matchId || !messageId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "matchId and messageId are required."
    );
  }

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
export const createCheckoutSession = functions.https.onCall(
  async (data: CheckoutSessionRequest, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in."
      );
    }

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

    const successUrl = data.successUrl;
    const cancelUrl = data.cancelUrl;
    if (!successUrl || !cancelUrl) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "successUrl and cancelUrl are required"
      );
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
          price: data.priceId || "price_YOUR_PLUS_PLAN_ID",
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
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, stripe-signature");
    res.status(204).send("");
    return;
  }

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
}

// Callable function to generate an Agora token for authenticated users
export const generateAgoraToken = functions.https.onCall(
  async (data: AgoraTokenRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in to start a call"
      );
    }

    const channelName = data?.channelName;
    const uid = typeof data?.uid === "number" ? data.uid : 0;

    if (!channelName) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "channelName is required"
      );
    }

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
export const getAgoraToken = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in."
    );
  }

  const channelName = data?.channelName as string | undefined;
  const isVideoCall = (data?.isVideoCall as boolean | undefined) ?? true;

  if (!channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "channelName is required."
    );
  }

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
