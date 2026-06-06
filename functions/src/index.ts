import { BigQuery } from "@google-cloud/bigquery";
import vision from "@google-cloud/vision";
import { RtcRole, RtcTokenBuilder } from "agora-access-token";
import bcrypt from "bcryptjs";
import cors from "cors";
import * as crypto from "crypto";
import express, { NextFunction, Request, Response } from "express";
import * as fileType from "file-type";
import * as admin from "firebase-admin";
import { defineString } from "firebase-functions/params";
import * as functions from "firebase-functions/v1";
import { GoogleAuth } from "google-auth-library";
import multer from "multer";
import Stripe from "stripe";

const visionClient = new vision.ImageAnnotatorClient();

import {
  __callSignalingTestHelpers,
  addIceCandidate as addIceCandidateSignaling,
  answerCall as answerCallSignaling,
  endCallForUser,
  endCall as endCallSignaling,
  enforceCallRingTimeout as enforceCallRingTimeoutSignaling,
  getIceServers as getIceServersSignaling,
  initiateCallForUser,
  initiateCall as initiateCallSignaling,
  notifyCallSafetyEvent as notifyCallSafetyEventSignaling,
} from "./calls/signaling";
import {
  callable,
  evaluateCallableAppCheck,
  isHttpsError,
  type CallableContext,
  verifyCallableAppCheck,
} from "./shared/callable";

const bigquery = new BigQuery();
const BQ_DATASET = "crushhour_ml";
const BQ_TABLE_INTERACTIONS = "interaction_events";

// Safe BigQuery insert - logs interaction events but doesn't fail the main operation
async function logInteractionEvent(
  eventData: Record<string, unknown>,
): Promise<void> {
  try {
    await bigquery
      .dataset(BQ_DATASET)
      .table(BQ_TABLE_INTERACTIONS)
      .insert(eventData);
  } catch (error) {
    // Log the error but don't throw - analytics shouldn't break core functionality
    console.error("BigQuery insert failed (non-critical):", {
      error: error instanceof Error ? error.message : String(error),
      eventData,
    });
  }
}

admin.initializeApp();
const db = admin.firestore();
const rtdb = admin.database();
const fieldValue = (
  admin.firestore as unknown as {
    FieldValue?: {
      serverTimestamp?: () => unknown;
      increment?: (n: number) => unknown;
      delete?: () => unknown;
    };
  }
)?.FieldValue;
const serverTimestamp = () =>
  fieldValue?.serverTimestamp ? fieldValue.serverTimestamp() : new Date();
const incrementBy = (value: number) =>
  fieldValue?.increment ? fieldValue.increment(value) : value;
const deleteField = () => (fieldValue?.delete ? fieldValue.delete() : null);

// =============================================================================
// ENVIRONMENT VARIABLES CONFIGURATION
// Uses Firebase params (.env-backed) to avoid functions.config() deprecation
// =============================================================================

const corsAllowedOriginsParam = defineString("CORS_ALLOWED_ORIGINS", {
  default: "",
});
const stripeSecretParam = defineString("STRIPE_SECRET", { default: "" });
const stripeWebhookSecretParam = defineString("STRIPE_WEBHOOK_SECRET", {
  default: "",
});
const googlePlayPackageNameParam = defineString("GOOGLE_PLAY_PACKAGE_NAME", {
  default: "",
});
const appleIssuerIdParam = defineString("APPLE_ISSUER_ID", { default: "" });
const appleKeyIdParam = defineString("APPLE_KEY_ID", { default: "" });
const applePrivateKeyParam = defineString("APPLE_PRIVATE_KEY", { default: "" });
const appleBundleIdParam = defineString("APPLE_BUNDLE_ID", { default: "" });
const googleRtdnVerificationTokenParam = defineString(
  "GOOGLE_RTDN_VERIFICATION_TOKEN",
  { default: "" },
);
const agoraAppIdParam = defineString("AGORA_APP_ID", { default: "" });
const agoraCertificateParam = defineString("AGORA_APP_CERTIFICATE", {
  default: "",
});
const otpSecretParam = defineString("OTP_SECRET");
const resendApiKeyParam = defineString("RESEND_API_KEY", { default: "" });
const emailFromParam = defineString("EMAIL_FROM", {
  default: "Crush <no-reply@crushhour.app>",
});
const profilePreferencesLegacyFallbackCutoffParam = defineString(
  "PROFILE_PREFERENCES_LEGACY_FALLBACK_CUTOFF",
  {
    // Cutoff for retiring legacy top-level `preferences` read fallback.
    default: "2026-06-30T00:00:00.000Z",
  },
);

const getCorsAllowedOrigins = () =>
  corsAllowedOriginsParam.value().split(",").filter(Boolean);
const getStripeSecret = () => stripeSecretParam.value();
const getStripeWebhookSecret = () => stripeWebhookSecretParam.value();
const getGooglePlayPackageName = () => googlePlayPackageNameParam.value();
const getAppleIssuerId = () => appleIssuerIdParam.value();
const getAppleKeyId = () => appleKeyIdParam.value();
const getApplePrivateKey = () => applePrivateKeyParam.value();
const getAppleBundleId = () => appleBundleIdParam.value();
const getGoogleRtdnVerificationToken = () =>
  googleRtdnVerificationTokenParam.value();
const getAgoraAppId = () => agoraAppIdParam.value();
const getAgoraCertificate = () => agoraCertificateParam.value();
const getOtpSecret = () => otpSecretParam.value();
const getEmailResendKey = () => resendApiKeyParam.value();
const getEmailFrom = () => emailFromParam.value();
const getProfilePreferencesLegacyFallbackCutoffRaw = () =>
  profilePreferencesLegacyFallbackCutoffParam.value().trim();
const getEmailConfig = () => ({
  resendKey: getEmailResendKey(),
  from: getEmailFrom(),
});

let stripeClient: Stripe | null = null;
let stripeClientSecret = "";
const getStripeClient = (secret: string) => {
  if (!stripeClient || stripeClientSecret !== secret) {
    stripeClientSecret = secret;
    stripeClient = new Stripe(secret, {
      apiVersion: "2024-06-20",
    });
  }
  return stripeClient;
};

// Default to strict CORS/App Check in production runtimes.
const isDevelopment = process.env.FUNCTIONS_EMULATOR === "true";
const isProductionRuntime =
  !isDevelopment &&
  (process.env.NODE_ENV === "production" || Boolean(process.env.K_SERVICE));
const corsOriginValidator = (
  origin: string | undefined,
  callback: (err: Error | null, allow?: boolean) => void,
) => {
  // Allow requests with no origin (mobile apps, curl, etc.)
  if (!origin) {
    callback(null, true);
    return;
  }
  // In development, allow localhost
  if (
    isDevelopment &&
    (origin.includes("localhost") || origin.includes("127.0.0.1"))
  ) {
    callback(null, true);
    return;
  }
  const corsAllowedOrigins = getCorsAllowedOrigins();
  // In production, fail closed if allowlist isn't configured.
  if (corsAllowedOrigins.length === 0) {
    if (isDevelopment) {
      callback(null, true);
      return;
    }
    callback(new Error("CORS allowlist not configured"), false);
    return;
  }
  // Check against whitelist
  if (corsAllowedOrigins.includes(origin)) {
    callback(null, true);
    return;
  }
  callback(new Error(`Origin ${origin} not allowed by CORS`), false);
};

// Configuration values are resolved at runtime via getters above.

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

interface VerifyGooglePurchaseTokenRequest {
  packageName?: string;
  productId?: string;
  purchaseToken?: string;
}

interface VerifyAppleTransactionRequest {
  productId?: string;
  transactionId?: string;
}

interface VerifyPurchaseReceiptRequest {
  platform?: string;
  productId?: string;
  receiptData?: string;
  packageName?: string;
}

interface GoogleSubscriptionPurchaseResponse {
  orderId?: string;
  expiryTimeMillis?: string;
  autoRenewing?: boolean;
  acknowledgementState?: number;
  paymentState?: number;
  cancelReason?: number;
  linkedPurchaseToken?: string;
}

interface GoogleSubscriptionEntitlement {
  plan: "free" | "plus";
  status: string;
  cancelAtPeriodEnd: boolean;
  currentPeriodEnd: number | null;
  expiryTimeMillis: number | null;
}

type PurchaseValidationProvider = "google_play" | "app_store";

interface PurchaseReceiptVerificationResult {
  plan: "free" | "plus";
  status: string;
  provider: PurchaseValidationProvider;
  productId?: string | null;
  orderId?: string | null;
  transactionId?: string | null;
  originalTransactionId?: string | null;
  currentPeriodEnd: number | null;
  cancelAtPeriodEnd: boolean;
}

type AppleServerEnvironment = "PRODUCTION" | "SANDBOX";

interface AppleServerApiConfig {
  issuerId: string;
  keyId: string;
  privateKey: string;
  bundleId: string;
}

interface AppleTransactionLookupResponse {
  signedTransactionInfo?: string;
  environment?: string;
}

interface AppleTransactionInfoPayload {
  transactionId?: string;
  originalTransactionId?: string;
  webOrderLineItemId?: string;
  bundleId?: string;
  productId?: string;
  purchaseDate?: number | string;
  expiresDate?: number | string;
  revocationDate?: number | string;
  inAppOwnershipType?: string;
  transactionReason?: string;
}

interface AppleTransactionValidationResult {
  environment: AppleServerEnvironment;
  signedTransactionInfo: string;
  transaction: AppleTransactionInfoPayload;
}

interface AppleSubscriptionEntitlement {
  plan: "free" | "plus";
  status: string;
  cancelAtPeriodEnd: boolean;
  currentPeriodEnd: number | null;
  expiryTimeMillis: number | null;
}

interface AppleServerNotificationData {
  appAppleId?: number;
  bundleId?: string;
  bundleVersion?: string;
  environment?: string;
  signedRenewalInfo?: string;
  signedTransactionInfo?: string;
}

interface AppleServerNotificationPayload {
  notificationType?: string;
  subtype?: string;
  notificationUUID?: string;
  version?: string;
  signedDate?: number | string;
  data?: AppleServerNotificationData;
}

interface AppleServerNotificationMapping {
  status: string;
  forceFree: boolean;
}

interface GoogleRtdnSubscriptionNotification {
  version?: string;
  notificationType?: number;
  purchaseToken?: string;
  subscriptionId?: string;
}

interface GoogleRtdnPayload {
  version?: string;
  packageName?: string;
  eventTimeMillis?: string;
  subscriptionNotification?: GoogleRtdnSubscriptionNotification;
}

interface GooglePubSubPushEnvelope {
  message?: {
    data?: string;
    messageId?: string;
    publishTime?: string;
    attributes?: Record<string, string>;
  };
  subscription?: string;
}

interface GoogleRtdnDecodeResult {
  payload: GoogleRtdnPayload;
  messageId?: string;
}

interface GoogleRtdnNotificationMapping {
  status: string;
  forceFree: boolean;
}

interface UnsendRequest {
  matchId?: string;
  messageId?: string;
}

interface SendMessageRequest {
  matchId?: string;
  toUserId?: string;
  content?: string;
  type?: string;
  mediaUrl?: string;
}

interface MarkMessagesReadRequest {
  matchId?: string;
}

interface EditMessageRequest {
  matchId?: string;
  messageId?: string;
  content?: string;
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

interface DatePlanEmailRequest {
  contactName?: string;
  contactEmail?: string;
  matchName?: string;
  dateTimeMs?: number;
  timeZoneOffsetMinutes?: number;
  location?: string;
  notes?: string;
}

interface DataExportRequest {}

const PROFILE_MIN_PHOTOS = 1;
const PROFILE_MIN_PROMPTS = 0; // Prompts are optional for swiping
const PROFILE_MIN_BIO_LENGTH = 10; // Only 10 characters needed
const PROFILE_MIN_INTERESTS = 3;
const DAILY_LIKE_LIMIT_FREE = 30;
const DAILY_LIKE_LIMIT_PLUS = 300;
const HOURLY_LIKE_LIMIT_FREE = 10; // Hourly throttle for free users
const HOURLY_LIKE_LIMIT_PLUS = 50; // Hourly throttle for plus users
const DISCOVERY_PAGE_SIZE = 120;
const DISCOVERY_QUERY_SCAN_LIMIT = 1000;
const DISCOVERY_DECK_CURSOR_VERSION = 1;

// Content moderation - comprehensive banned terms list
// Includes leetspeak and common substitution variations
const BANNED_TERMS = [
  // Violence and threats (+ leetspeak)
  "kill",
  "k1ll",
  "murder",
  "threat",
  "terror",
  "bomb",
  "attack",
  "weapon",
  "shoot",
  "sh00t",
  "stab",
  "strangle",
  // Hate speech (+ variations)
  "hate",
  "racist",
  "rac1st",
  "nazi",
  "naz1",
  "supremacist",
  "bigot",
  // Explicit profanity (core + common substitutions)
  "shit",
  "sh1t",
  "sh!t",
  "fuck",
  "f*ck",
  "fck",
  "fuk",
  "fuq",
  "bitch",
  "b1tch",
  "b!tch",
  "cunt",
  "c*nt",
  "ass hole",
  "a$$hole",
  "bastard",
  "d1ck",
  "stfu",
  "gtfo",
  // Spam and scam indicators
  "spam",
  "scam",
  "wire money",
  "western union",
  "moneygram",
  "bitcoin wallet",
  "crypto investment",
  "forex trading",
  "click here",
  "act now",
  "free money",
  "guaranteed profit",
  "double your",
  // Solicitation
  "escort",
  "prostitute",
  "pay for sex",
  "sugar daddy arrangement",
  "onlyfans",
  "cashapp me",
  // Contact info harvesting (push to off-platform)
  "whatsapp me",
  "telegram me",
  "kik me",
  "snapchat me",
  "add me on",
  "text me at",
  "call me at",
  // Drugs
  "buy drugs",
  "sell drugs",
  "cocaine",
  "heroin",
  "meth",
  "mdma",
  "ecstasy",
  "fentanyl",
];

function toAuthHttpsError(err: unknown): functions.https.HttpsError | null {
  const code = (err as { code?: unknown })?.code;
  if (typeof code !== "string") return null;

  switch (code) {
    case "auth/email-already-exists":
      return new functions.https.HttpsError(
        "already-exists",
        "That email is already in use.",
      );
    case "auth/invalid-email":
      return new functions.https.HttpsError(
        "invalid-argument",
        "Enter a valid email address.",
      );
    case "auth/invalid-password":
      return new functions.https.HttpsError(
        "invalid-argument",
        `Use at least ${PASSWORD_MIN_LENGTH} characters.`,
      );
    case "auth/uid-already-exists":
      return new functions.https.HttpsError(
        "already-exists",
        "Account already exists.",
      );
    default:
      return null;
  }
}

type RestAppCheckOutcome = "valid" | "missing" | "invalid";

interface RestAppCheckEvaluation {
  allowed: boolean;
  outcome: RestAppCheckOutcome;
}

const ENFORCE_APP_CHECK = isProductionRuntime;

function getRestAppCheckToken(req: Request): string | undefined {
  const headerValue = req.header("X-Firebase-AppCheck");
  if (typeof headerValue !== "string") return undefined;
  const token = headerValue.trim();
  return token.length > 0 ? token : undefined;
}

async function evaluateRestAppCheck(
  token: string | undefined,
  action: string,
  options?: {
    enforce?: boolean;
    verifyToken?: (value: string) => Promise<unknown>;
  },
): Promise<RestAppCheckEvaluation> {
  const enforce = options?.enforce ?? ENFORCE_APP_CHECK;
  const verifyToken =
    options?.verifyToken ??
    ((value: string) => admin.appCheck().verifyToken(value));

  if (!token) {
    if (enforce) {
      console.warn("App Check REST: Rejected request without token", {
        action,
      });
      return { allowed: false, outcome: "missing" };
    }
    console.info(
      "App Check REST: Request without token (enforcement disabled)",
      {
        action,
      },
    );
    return { allowed: true, outcome: "missing" };
  }

  try {
    await verifyToken(token);
    return { allowed: true, outcome: "valid" };
  } catch {
    if (enforce) {
      console.warn("App Check REST: Rejected request with invalid token", {
        action,
      });
      return { allowed: false, outcome: "invalid" };
    }
    console.info("App Check REST: Invalid token (enforcement disabled)", {
      action,
    });
    return { allowed: true, outcome: "invalid" };
  }
}

function appCheckRestMiddleware(action: string) {
  return async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const evaluation = await evaluateRestAppCheck(
      getRestAppCheckToken(req),
      action,
    );
    if (evaluation.allowed) {
      next();
      return;
    }
    res.status(412).json({
      error: "App Check verification failed. Please update your app.",
      code: "failed-precondition",
    });
  };
}

function requireAuth(context: CallableContext, action: string): string {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      `You must be logged in to ${action}.`,
    );
  }
  return uid;
}

/**
 * Require email verification for sensitive operations (CR-AUD-031).
 * Blocks unverified users from chat, discovery, and other sensitive actions.
 * Phone-auth users are exempt (no email to verify).
 */
function requireEmailVerified(context: CallableContext, action: string): void {
  const token = context.auth?.token;
  if (!token) return; // Already handled by requireAuth

  // Phone-auth users don't have an email to verify — exempt them
  const signInProvider = token.firebase?.sign_in_provider;
  if (signInProvider === "phone") return;

  // Apple/Google sign-in providers are inherently verified
  if (signInProvider === "apple.com" || signInProvider === "google.com") return;

  // For email/password users, check email_verified
  if (token.email && !token.email_verified) {
    throw new functions.https.HttpsError(
      "permission-denied",
      `Email verification required to ${action}. Please verify your email first.`,
    );
  }
}

function requireString(
  value: unknown,
  field: string,
  maxLength = 5000,
): string {
  const str = typeof value === "string" ? value.trim() : "";
  if (!str) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} is required.`,
    );
  }
  if (str.length > maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} exceeds maximum length of ${maxLength} characters.`,
    );
  }
  return str;
}

function optionalString(value: unknown): string | undefined {
  const str = typeof value === "string" ? value.trim() : "";
  return str.length > 0 ? str : undefined;
}

function truncateString(value: string, maxLength: number): string {
  if (value.length <= maxLength) return value;
  return value.slice(0, maxLength).trim();
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

function toMillis(value: unknown, fallback: number): number {
  if (typeof value === "number") return value;
  if (value instanceof Date) return value.getTime();
  const millis = (value as { toMillis?: () => number })?.toMillis?.();
  return typeof millis === "number" ? millis : fallback;
}

// ─────────────────────────────────────────────────────────────────────────────
// CENTRALIZED INPUT VALIDATORS (SEC-BE-007)
// ─────────────────────────────────────────────────────────────────────────────

/** Strip HTML tags from input to prevent XSS. */
function stripHtml(input: string): string {
  return (
    input
      // Remove complete HTML/XML tags.
      .replace(/<[^>]*>/g, "")
      // Remove a trailing, unterminated tag start the tag regex leaves behind
      // (e.g. "hi <img src=x onerror=alert(1)") which a browser would still
      // parse once more markup follows. The letter/"/" guard avoids stripping
      // benign "<" usage like "3 < 5" or the "<3" emoticon.
      .replace(/<\/?[a-zA-Z][^>]*$/g, "")
  );
}

/** Validate message content: 1-2000 chars, no script injection. */
function validateMessageContent(content: unknown, field = "content"): string {
  const str = requireString(content, field, 2000);
  return stripHtml(str);
}

/** Validate profile name: 2-50 chars, no HTML. */
function validateProfileName(name: unknown, field = "name"): string {
  const str = requireString(name, field, 50);
  // Enforce the minimum on the sanitized value so markup cannot pad a name that
  // renders as a single character (consistent with validateProfileTextField).
  const sanitized = stripHtml(str);
  if (sanitized.length < 2) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be at least 2 characters.`,
    );
  }
  return sanitized;
}

/** Validate profile bio: 0-500 chars, no HTML. */
function validateBio(bio: unknown): string {
  if (bio === undefined || bio === null || bio === "") return "";
  const str = typeof bio === "string" ? bio.trim() : "";
  if (str.length > 500) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Bio exceeds maximum length of 500 characters.",
    );
  }
  return stripHtml(str);
}

function requireObjectRecord(
  value: unknown,
  field: string,
): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be an object.`,
    );
  }
  return value as Record<string, unknown>;
}

function validateProfileTextField(
  value: unknown,
  field: string,
  options: { maxLength: number; allowEmpty?: boolean; lowerCase?: boolean },
): string {
  if (typeof value !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be a string.`,
    );
  }

  const allowEmpty = options.allowEmpty ?? true;
  const sanitized = stripHtml(value.trim());
  if (!allowEmpty && sanitized.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} cannot be empty.`,
    );
  }
  if (sanitized.length > options.maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} exceeds maximum length of ${options.maxLength} characters.`,
    );
  }
  return options.lowerCase ? sanitized.toLowerCase() : sanitized;
}

function validateProfileInterests(value: unknown): string[] {
  if (!Array.isArray(value)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "interests must be an array of strings.",
    );
  }
  if (value.length > 20) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "interests cannot contain more than 20 items.",
    );
  }

  const normalized: string[] = [];
  for (const item of value) {
    if (typeof item !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Each interest must be a string.",
      );
    }
    const cleaned = stripHtml(item.trim());
    if (!cleaned) continue;
    if (cleaned.length > 40) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Each interest must be 40 characters or fewer.",
      );
    }
    normalized.push(cleaned);
  }

  return normalized;
}

const PROFILE_PATCH_ALLOWED_FIELDS = new Set([
  "display_name",
  "bio",
  "birth_date",
  "gender",
  "job_title",
  "company",
  "education",
  "city",
  "country",
  "interests",
]);

const CANONICAL_DISCOVERY_GENDERS = [
  "male",
  "female",
  "non_binary",
  "other",
] as const;
const CANONICAL_DISCOVERY_GENDER_SET = new Set(CANONICAL_DISCOVERY_GENDERS);
const DISCOVERY_GENDER_PREFERENCE_TOKEN_SET = new Set([
  ...CANONICAL_DISCOVERY_GENDERS,
  "men",
  "women",
  "man",
  "woman",
  "non-binary",
  "nonbinary",
  "nb",
  "all",
  "any",
  "everyone",
]);

function normalizeProfileGender(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = stripHtml(value.trim().toLowerCase()).replace(
    /[\s-]+/g,
    "_",
  );

  switch (normalized) {
    case "male":
    case "man":
    case "men":
      return "male";
    case "female":
    case "woman":
    case "women":
      return "female";
    case "non_binary":
    case "nonbinary":
    case "nb":
      return "non_binary";
    case "other":
      return "other";
    default:
      return null;
  }
}

function normalizeDiscoveryPreferenceTokens(value: unknown): string[] {
  if (typeof value === "string") {
    return normalizeDiscoveryPreferenceTokens([value]);
  }
  if (!Array.isArray(value)) return [];

  const normalized = new Set<string>();
  for (const item of value) {
    if (typeof item !== "string") continue;
    const token = stripHtml(item.trim().toLowerCase()).replace(/[\s-]+/g, "_");
    switch (token) {
      case "male":
      case "man":
      case "men":
        normalized.add("male");
        break;
      case "female":
      case "woman":
      case "women":
        normalized.add("female");
        break;
      case "non_binary":
      case "nonbinary":
      case "nb":
        normalized.add("non_binary");
        break;
      case "other":
        normalized.add("other");
        break;
      case "all":
      case "any":
      case "everyone":
        for (const gender of CANONICAL_DISCOVERY_GENDERS) {
          normalized.add(gender);
        }
        break;
      default:
        break;
    }
  }

  return Array.from(normalized);
}

function validateProfilePatchPayload(
  payload: unknown,
): Record<string, unknown> {
  const body = requireObjectRecord(payload, "body");
  const keys = Object.keys(body);

  if (keys.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Request body must include at least one updatable profile field.",
    );
  }

  for (const key of keys) {
    if (!PROFILE_PATCH_ALLOWED_FIELDS.has(key)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Unsupported profile field: ${key}.`,
      );
    }
  }

  const updates: Record<string, unknown> = {};

  if (body.display_name !== undefined) {
    updates["profile.name"] = validateProfileName(
      body.display_name,
      "display_name",
    );
  }
  if (body.bio !== undefined) {
    updates["profile.bio"] = validateBio(body.bio);
  }
  if (body.birth_date !== undefined) {
    const birthDate = validateProfileTextField(body.birth_date, "birth_date", {
      maxLength: 64,
      allowEmpty: false,
    });
    validateMinimumAge(birthDate);
    const normalizedBirthDate = new Date(birthDate).toISOString();
    updates["profile.birthDate"] = normalizedBirthDate;
  }
  if (body.gender !== undefined) {
    const gender = normalizeProfileGender(body.gender);
    if (!gender) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `gender must be one of: ${Array.from(CANONICAL_DISCOVERY_GENDER_SET).join(", ")}`,
      );
    }
    updates["profile.gender"] = gender;
  }
  if (body.job_title !== undefined) {
    updates["profile.jobTitle"] = validateProfileTextField(
      body.job_title,
      "job_title",
      { maxLength: 100 },
    );
  }
  if (body.company !== undefined) {
    updates["profile.company"] = validateProfileTextField(
      body.company,
      "company",
      { maxLength: 100 },
    );
  }
  if (body.education !== undefined) {
    updates["profile.education"] = validateProfileTextField(
      body.education,
      "education",
      { maxLength: 120 },
    );
  }
  if (body.city !== undefined) {
    updates["profile.city"] = validateProfileTextField(body.city, "city", {
      maxLength: 100,
    });
  }
  if (body.country !== undefined) {
    updates["profile.country"] = validateProfileTextField(
      body.country,
      "country",
      { maxLength: 100 },
    );
  }
  if (body.interests !== undefined) {
    updates["profile.interests"] = validateProfileInterests(body.interests);
  }

  if (Object.keys(updates).length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "No valid profile updates were provided.",
    );
  }

  return updates;
}

const PROFILE_PREFERENCES_ALLOWED_FIELDS = new Set([
  "minAge",
  "maxAge",
  "maxDistanceKm",
  "showMeGenders",
  "showMyDistance",
  "showMyAge",
  "hideFromDiscovery",
  "incognitoMode",
  "country",
  "city",
  "genderPreference",
]);

function validateBooleanField(value: unknown, field: string): boolean {
  if (typeof value !== "boolean") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be a boolean.`,
    );
  }
  return value;
}

function validatePreferenceNumber(
  value: unknown,
  field: string,
  min: number,
  max: number,
): number {
  const parsed = toNumber(value);
  if (parsed === undefined || !Number.isFinite(parsed)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be a number.`,
    );
  }
  if (parsed < min || parsed > max) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be between ${min} and ${max}.`,
    );
  }
  return Math.round(parsed);
}

function validateShowMeGenders(value: unknown): string[] {
  if (!Array.isArray(value)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "showMeGenders must be an array of strings.",
    );
  }
  if (value.length > 10) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "showMeGenders cannot contain more than 10 values.",
    );
  }

  return value
    .map((item) => {
      if (typeof item !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "showMeGenders entries must be strings.",
        );
      }
      const normalized = stripHtml(item.trim().toLowerCase());
      if (!normalized) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "showMeGenders entries cannot be empty.",
        );
      }
      if (!DISCOVERY_GENDER_PREFERENCE_TOKEN_SET.has(normalized)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "showMeGenders entries must be canonical discovery genders or men/women/everyone aliases.",
        );
      }
      return normalized;
    })
    .flatMap((token) => normalizeDiscoveryPreferenceTokens([token]));
}

function validateProfilePreferencesPayload(
  payload: unknown,
): Record<string, unknown> {
  const preferences = requireObjectRecord(payload, "preferences");
  const keys = Object.keys(preferences);

  if (keys.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "preferences payload cannot be empty.",
    );
  }

  for (const key of keys) {
    if (!PROFILE_PREFERENCES_ALLOWED_FIELDS.has(key)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Unsupported preferences field: ${key}.`,
      );
    }
  }

  const normalized: Record<string, unknown> = {};
  let minAge: number | undefined;
  let maxAge: number | undefined;

  if (preferences.minAge !== undefined) {
    minAge = validatePreferenceNumber(preferences.minAge, "minAge", 18, 100);
    normalized.minAge = minAge;
  }
  if (preferences.maxAge !== undefined) {
    maxAge = validatePreferenceNumber(preferences.maxAge, "maxAge", 18, 100);
    normalized.maxAge = maxAge;
  }
  if (minAge !== undefined && maxAge !== undefined && minAge > maxAge) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "minAge cannot be greater than maxAge.",
    );
  }

  if (preferences.maxDistanceKm !== undefined) {
    normalized.maxDistanceKm = validatePreferenceNumber(
      preferences.maxDistanceKm,
      "maxDistanceKm",
      1,
      1000,
    );
  }
  if (preferences.showMeGenders !== undefined) {
    normalized.showMeGenders = validateShowMeGenders(preferences.showMeGenders);
  }
  if (preferences.showMyDistance !== undefined) {
    normalized.showMyDistance = validateBooleanField(
      preferences.showMyDistance,
      "showMyDistance",
    );
  }
  if (preferences.showMyAge !== undefined) {
    normalized.showMyAge = validateBooleanField(
      preferences.showMyAge,
      "showMyAge",
    );
  }
  if (preferences.hideFromDiscovery !== undefined) {
    normalized.hideFromDiscovery = validateBooleanField(
      preferences.hideFromDiscovery,
      "hideFromDiscovery",
    );
  }
  if (preferences.incognitoMode !== undefined) {
    normalized.incognitoMode = validateBooleanField(
      preferences.incognitoMode,
      "incognitoMode",
    );
  }
  if (preferences.country !== undefined) {
    normalized.country = validateProfileTextField(
      preferences.country,
      "country",
      { maxLength: 100 },
    );
  }
  if (preferences.city !== undefined) {
    normalized.city = validateProfileTextField(preferences.city, "city", {
      maxLength: 100,
    });
  }
  if (preferences.genderPreference !== undefined) {
    const value = validateProfileTextField(
      preferences.genderPreference,
      "genderPreference",
      { maxLength: 30, allowEmpty: false, lowerCase: true },
    );
    if (!DISCOVERY_GENDER_PREFERENCE_TOKEN_SET.has(value)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "genderPreference must be a canonical discovery gender or men/women/everyone alias.",
      );
    }
    const normalizedTokens = normalizeDiscoveryPreferenceTokens([value]);
    normalized.genderPreference =
      normalizedTokens.length === CANONICAL_DISCOVERY_GENDERS.length
        ? "everyone"
        : normalizedTokens[0] ?? "everyone";
  }

  if (Object.keys(normalized).length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "No valid preferences updates were provided.",
    );
  }

  return normalized;
}

type CanonicalProfilePreferencesOptions = {
  uid?: string | null;
  source?: string;
  now?: Date;
  legacyFallbackCutoff?: Date | null;
};

const LEGACY_PROFILE_PREFERENCES_FALLBACK_LOG_CACHE_LIMIT = 2000;
const loggedLegacyProfilePreferencesFallbackKeys = new Set<string>();
const loggedLegacyProfilePreferencesCutoffBlockedKeys = new Set<string>();
let hasLoggedInvalidLegacyProfilePreferencesFallbackCutoff = false;

function rememberLegacyProfilePreferencesLogKey(
  cache: Set<string>,
  key: string,
): boolean {
  if (cache.has(key)) {
    return false;
  }
  if (cache.size >= LEGACY_PROFILE_PREFERENCES_FALLBACK_LOG_CACHE_LIMIT) {
    cache.clear();
  }
  cache.add(key);
  return true;
}

function buildLegacyProfilePreferencesFallbackLogKey(
  uid?: string | null,
  source?: string,
): string {
  const normalizedUid =
    typeof uid === "string" && uid.trim().length > 0 ? uid.trim() : "unknown";
  const normalizedSource =
    typeof source === "string" && source.trim().length > 0
      ? source.trim()
      : "unknown";
  return `${normalizedUid}|${normalizedSource}`;
}

function resolveLegacyPreferencesFallbackCutoff(
  options: CanonicalProfilePreferencesOptions,
): Date | null {
  if (options.legacyFallbackCutoff instanceof Date) {
    if (!Number.isNaN(options.legacyFallbackCutoff.getTime())) {
      return options.legacyFallbackCutoff;
    }
    return null;
  }
  if (options.legacyFallbackCutoff === null) {
    return null;
  }

  const cutoffRaw = getProfilePreferencesLegacyFallbackCutoffRaw();
  if (!cutoffRaw) {
    return null;
  }

  const parsedCutoff = new Date(cutoffRaw);
  if (!Number.isNaN(parsedCutoff.getTime())) {
    return parsedCutoff;
  }

  if (!hasLoggedInvalidLegacyProfilePreferencesFallbackCutoff) {
    hasLoggedInvalidLegacyProfilePreferencesFallbackCutoff = true;
    console.error(
      "Invalid PROFILE_PREFERENCES_LEGACY_FALLBACK_CUTOFF; keeping fallback enabled.",
      { cutoffRaw },
    );
  }
  return null;
}

function logLegacyProfilePreferencesFallback(params: {
  uid?: string | null;
  source?: string;
  now: Date;
  legacyFallbackCutoff: Date | null;
  isFallbackEnabled: boolean;
}): void {
  const logKey = buildLegacyProfilePreferencesFallbackLogKey(
    params.uid,
    params.source,
  );
  const nowIso = params.now.toISOString();
  const cutoffIso = params.legacyFallbackCutoff
    ? params.legacyFallbackCutoff.toISOString()
    : null;

  if (params.isFallbackEnabled) {
    if (
      !rememberLegacyProfilePreferencesLogKey(
        loggedLegacyProfilePreferencesFallbackKeys,
        logKey,
      )
    ) {
      return;
    }
    console.warn("legacy_profile_preferences_fallback_read", {
      uid: params.uid ?? null,
      source: params.source ?? null,
      nowIso,
      cutoffIso,
    });
    return;
  }

  if (
    !rememberLegacyProfilePreferencesLogKey(
      loggedLegacyProfilePreferencesCutoffBlockedKeys,
      logKey,
    )
  ) {
    return;
  }
  console.warn("legacy_profile_preferences_fallback_blocked_after_cutoff", {
    uid: params.uid ?? null,
    source: params.source ?? null,
    nowIso,
    cutoffIso,
  });
}

function getCanonicalProfilePreferences(
  userData: Record<string, unknown>,
  options: CanonicalProfilePreferencesOptions = {},
): Record<string, unknown> {
  const profile = asRecord(userData.profile);
  const nestedPreferences = asRecord(profile.preferences);
  if (Object.keys(nestedPreferences).length > 0) {
    return nestedPreferences;
  }

  const legacyPreferences = asRecord(userData.preferences);
  if (Object.keys(legacyPreferences).length === 0) {
    return legacyPreferences;
  }

  const now = options.now ?? new Date();
  const legacyFallbackCutoff = resolveLegacyPreferencesFallbackCutoff(options);
  const isFallbackEnabled =
    !legacyFallbackCutoff || now.getTime() < legacyFallbackCutoff.getTime();

  logLegacyProfilePreferencesFallback({
    uid: options.uid,
    source: options.source,
    now,
    legacyFallbackCutoff,
    isFallbackEnabled,
  });

  if (!isFallbackEnabled) {
    return {};
  }

  return legacyPreferences;
}

function httpStatusFromHttpsErrorCode(code: string): number {
  switch (code) {
    case "invalid-argument":
      return 400;
    case "unauthenticated":
      return 401;
    case "permission-denied":
      return 403;
    case "not-found":
      return 404;
    case "already-exists":
      return 409;
    case "failed-precondition":
      return 412;
    case "resource-exhausted":
      return 429;
    default:
      return 500;
  }
}

interface StorageObjectLocation {
  bucketName: string;
  objectPath: string;
}

function parseProfilePhotoIndex(photoId: string): number | null {
  const match = /^photo_(\d+)$/.exec(photoId);
  if (!match) return null;
  const parsed = Number(match[1]);
  if (!Number.isInteger(parsed) || parsed < 0) return null;
  return parsed;
}

function safeDecodeUriComponent(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function parseStorageObjectLocationFromUrl(
  photoUrl: string,
): StorageObjectLocation | null {
  const trimmed = typeof photoUrl === "string" ? photoUrl.trim() : "";
  if (!trimmed) return null;

  if (trimmed.startsWith("gs://")) {
    const withoutPrefix = trimmed.slice("gs://".length);
    const slashIndex = withoutPrefix.indexOf("/");
    if (slashIndex <= 0) return null;
    const bucketName = withoutPrefix.slice(0, slashIndex);
    const objectPath = withoutPrefix.slice(slashIndex + 1);
    if (!bucketName || !objectPath) return null;
    return { bucketName, objectPath };
  }

  let parsedUrl: URL;
  try {
    parsedUrl = new URL(trimmed);
  } catch {
    return null;
  }

  if (parsedUrl.hostname === "storage.googleapis.com") {
    const normalizedPath = parsedUrl.pathname.replace(/^\/+/, "");
    const slashIndex = normalizedPath.indexOf("/");
    if (slashIndex <= 0) return null;
    const bucketName = normalizedPath.slice(0, slashIndex);
    const objectPath = safeDecodeUriComponent(
      normalizedPath.slice(slashIndex + 1),
    );
    if (!bucketName || !objectPath) return null;
    return { bucketName, objectPath };
  }

  if (parsedUrl.hostname === "firebasestorage.googleapis.com") {
    const match = /^\/v0\/b\/([^/]+)\/o\/(.+)$/.exec(parsedUrl.pathname);
    if (!match) return null;
    const bucketName = match[1];
    const objectPath = safeDecodeUriComponent(match[2]);
    if (!bucketName || !objectPath) return null;
    return { bucketName, objectPath };
  }

  return null;
}

function isStorageNotFoundError(error: unknown): boolean {
  const code = (error as { code?: unknown })?.code;
  if (
    code === 404 ||
    code === "404" ||
    code === "ENOENT" ||
    code === "storage/object-not-found"
  ) {
    return true;
  }
  const message = (error as { message?: unknown })?.message;
  return (
    typeof message === "string" &&
    message.toLowerCase().includes("no such object")
  );
}

async function deleteProfilePhotoStorageObject(
  photoUrl: string,
): Promise<void> {
  const location = parseStorageObjectLocationFromUrl(photoUrl);
  if (!location) {
    // Legacy/external URLs may not map to Firebase Storage object paths.
    console.warn("Skipping storage delete for unmanaged profile photo URL", {
      photoUrl,
    });
    return;
  }

  try {
    await admin
      .storage()
      .bucket(location.bucketName)
      .file(location.objectPath)
      .delete();
  } catch (error) {
    if (isStorageNotFoundError(error)) return;
    throw error;
  }
}

/** Valid report reason categories. */
const VALID_REPORT_CATEGORIES = [
  "harassment",
  "inappropriate_content",
  "spam",
  "fake_profile",
  "underage",
  "scam",
  "threatening",
  "hate_speech",
  "impersonation",
  "other",
] as const;

type ReportCategory = (typeof VALID_REPORT_CATEGORIES)[number];

function normalizeReportReasonToken(reason: string): string {
  return reason
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function inferReportCategoryFromReason(reason: string): ReportCategory {
  const normalized = normalizeReportReasonToken(reason);
  if (!normalized) return "other";
  if (normalized.includes("underage")) return "underage";
  if (normalized.includes("impersonat")) return "impersonation";
  if (normalized.includes("threat")) return "threatening";
  if (normalized.includes("hate")) return "hate_speech";
  if (normalized.includes("harass")) return "harassment";
  if (
    normalized.includes("fake profile") ||
    normalized.includes("catfish") ||
    normalized.includes("fake")
  ) {
    return "fake_profile";
  }
  if (
    normalized.includes("inappropriate") ||
    normalized.includes("explicit") ||
    normalized.includes("nudity") ||
    normalized.includes("photo")
  ) {
    return "inappropriate_content";
  }
  if (
    normalized.includes("scam") ||
    normalized.includes("fraud") ||
    normalized.includes("phish")
  ) {
    return "scam";
  }
  if (normalized.includes("spam")) return "spam";
  return "other";
}

function canonicalizeSafetyReportReason(
  reason: unknown,
  options?: { field?: string; maxLength?: number; minLength?: number },
): { reasonText: string; reasonCategory: ReportCategory } {
  const field = options?.field ?? "reason";
  const maxLength = options?.maxLength ?? 1000;
  const minLength = options?.minLength ?? 1;
  const str = requireString(reason, field, maxLength);
  const reasonText = stripHtml(str);
  if (reasonText.length < minLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be at least ${minLength} characters.`,
    );
  }
  return {
    reasonText,
    reasonCategory: inferReportCategoryFromReason(reasonText),
  };
}

type SafetySelfAction = "block" | "unblock" | "report";
type SafetyRestAuditOutcome = "success" | "rate_limited" | "invalid" | "error";

interface SafetyRestAuditLogParams {
  action: SafetySelfAction;
  actorUid?: string;
  targetUid?: string;
  route: string;
  method?: string;
  statusCode: number;
  errorCode?: string | null;
  reasonCategory?: ReportCategory | null;
  metadata?: Record<string, unknown>;
  ip?: string | null;
  userAgent?: string | null;
}

type SafetyRestAuditWriter = (
  entry: Record<string, unknown>,
) => Promise<unknown>;

function getRestClientIp(req: Request): string | null {
  const forwarded = req.headers["x-forwarded-for"];
  if (Array.isArray(forwarded)) {
    const first = forwarded[0]?.split(",")[0]?.trim();
    return first || null;
  }
  if (typeof forwarded === "string") {
    const first = forwarded.split(",")[0]?.trim();
    return first || null;
  }
  const ip = typeof req.ip === "string" ? req.ip.trim() : "";
  return ip.length > 0 ? ip : null;
}

function safetyAuditOutcomeFromStatusCode(
  statusCode: number,
): SafetyRestAuditOutcome {
  if (statusCode >= 500) return "error";
  if (statusCode === 429) return "rate_limited";
  if (statusCode >= 400) return "invalid";
  return "success";
}

async function logSafetyRestAudit(
  params: SafetyRestAuditLogParams,
  options?: {
    writer?: SafetyRestAuditWriter;
    timestampFactory?: () => unknown;
  },
): Promise<void> {
  const writer =
    options?.writer ??
    ((entry: Record<string, unknown>) =>
      db.collection("safety_rest_audit_logs").add(entry));
  const timestampFactory = options?.timestampFactory ?? serverTimestamp;
  const entry = {
    action: params.action,
    actorUid: params.actorUid ?? null,
    targetUid: params.targetUid ?? null,
    outcome: safetyAuditOutcomeFromStatusCode(params.statusCode),
    route: params.route,
    method: (params.method ?? "POST").toUpperCase(),
    statusCode: params.statusCode,
    errorCode: params.errorCode ?? null,
    reasonCategory: params.reasonCategory ?? null,
    metadata: params.metadata ?? {},
    ip: params.ip ?? null,
    userAgent: params.userAgent ?? null,
    createdAt: timestampFactory(),
  };

  try {
    await writer(entry);
  } catch (err) {
    console.error("Safety audit log write failed", {
      action: params.action,
      route: params.route,
      error: err instanceof Error ? err.message : String(err),
    });
  }
}

/** Validate target user IDs for safety REST endpoints. */
function validateSafetyTargetId(value: unknown, field: string): string {
  return requireString(value, field, 128);
}

/** Prevent users from applying safety actions against themselves. */
function assertNotSelfSafetyAction(
  actorId: string,
  targetId: string,
  action: SafetySelfAction,
): void {
  if (actorId !== targetId) return;
  throw new functions.https.HttpsError(
    "invalid-argument",
    `You cannot ${action} yourself.`,
  );
}

/** Validate and sanitize REST safety report reason text. */
function validateSafetyReportReason(reason: unknown): string {
  return canonicalizeSafetyReportReason(reason, {
    field: "reason",
    maxLength: 280,
    minLength: 3,
  }).reasonText;
}

/** Validate and sanitize optional REST safety report description text. */
function validateOptionalSafetyDescription(
  description: unknown,
): string | null {
  const raw = optionalString(description);
  if (!raw) return null;
  if (raw.length > 2000) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "description exceeds maximum length of 2000 characters.",
    );
  }
  const sanitized = stripHtml(raw);
  return sanitized.length > 0 ? sanitized : null;
}

const OTP_DIGITS = 6;
const OTP_TTL_MS = 10 * 60 * 1000;
const OTP_VERIFY_MAX_ATTEMPTS = 5;
const OTP_VERIFY_LOCK_MS = 15 * 60 * 1000;
const OTP_RESEND_COOLDOWN_MS = 30 * 1000;
const OTP_REQUEST_LIMIT = 10;
const OTP_REQUEST_WINDOW_MS = 10 * 60 * 1000;
const OTP_REQUEST_BLOCK_MS = 20 * 60 * 1000;
const OTP_VERIFY_LIMIT = 10;
const OTP_VERIFY_WINDOW_MS = 10 * 60 * 1000;
const OTP_VERIFY_BLOCK_MS = 20 * 60 * 1000;
const SIGNUP_EMAIL_FLOW = "signup";
const RESET_TOKEN_TTL_MS = 15 * 60 * 1000;
const RESET_ATTEMPT_LIMIT = 5;
const RESET_ATTEMPT_WINDOW_MS = 10 * 60 * 1000;
const RESET_ATTEMPT_BLOCK_MS = 20 * 60 * 1000;
const LOGIN_ATTEMPT_LIMIT = 8;
const LOGIN_ATTEMPT_WINDOW_MS = 10 * 60 * 1000;
const LOGIN_ATTEMPT_BLOCK_MS = 20 * 60 * 1000;
const SIGNUP_ATTEMPT_LIMIT = 5;
const SIGNUP_ATTEMPT_WINDOW_MS = 10 * 60 * 1000;
const SIGNUP_ATTEMPT_BLOCK_MS = 20 * 60 * 1000;
const DATE_PLAN_EMAIL_LIMIT = 3;
const DATE_PLAN_EMAIL_WINDOW_MS = 60 * 60 * 1000;
const DATE_PLAN_EMAIL_BLOCK_MS = 2 * 60 * 60 * 1000;

// ─────────────────────────────────────────────────────────────────────────────
// SAFETY ACTION RATE LIMITS
// Prevents abuse of report/block features
// ─────────────────────────────────────────────────────────────────────────────
const REPORT_LIMIT = 10; // Max 10 reports per window
const REPORT_WINDOW_MS = 60 * 60 * 1000; // 1 hour window
const REPORT_BLOCK_MS = 2 * 60 * 60 * 1000; // 2 hour block after exceeding
const BLOCK_LIMIT = 20; // Max 20 blocks per window
const BLOCK_WINDOW_MS = 60 * 60 * 1000; // 1 hour window
const BLOCK_BLOCK_MS = 60 * 60 * 1000; // 1 hour block after exceeding
const UNBLOCK_LIMIT = 30; // Max 30 unblocks per window
const UNBLOCK_WINDOW_MS = 60 * 60 * 1000; // 1 hour window
const UNBLOCK_BLOCK_MS = 30 * 60 * 1000; // 30 min block after exceeding

const PASSWORD_MIN_LENGTH = 8;
const PASSWORD_SALT_ROUNDS = 12;
const USERNAME_REGEX = /^[a-zA-Z0-9_]{3,20}$/;
const EMAIL_REGEX = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const MIN_AGE_YEARS = 18;

/**
 * Validate password strength server-side.
 * Requires: min 8 chars, at least 1 uppercase, 1 lowercase, 1 digit.
 */
function validatePasswordStrength(password: string): string | null {
  if (password.length < PASSWORD_MIN_LENGTH) {
    return `Password must be at least ${PASSWORD_MIN_LENGTH} characters.`;
  }
  if (!/[A-Z]/.test(password)) {
    return "Password must contain at least one uppercase letter.";
  }
  if (!/[a-z]/.test(password)) {
    return "Password must contain at least one lowercase letter.";
  }
  if (!/[0-9]/.test(password)) {
    return "Password must contain at least one digit.";
  }
  return null;
}

/**
 * Calculate age from a date of birth string (ISO 8601 or YYYY-MM-DD).
 * Returns the age in years, or null if the date is invalid.
 */
function calculateAgeFromDob(dobString: string): number | null {
  const dob = new Date(dobString);
  if (isNaN(dob.getTime())) return null;
  const now = new Date();
  let age = now.getFullYear() - dob.getFullYear();
  const monthDiff = now.getMonth() - dob.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

/**
 * Validate that a date of birth makes the user at least MIN_AGE_YEARS old.
 * Throws HttpsError if underage or invalid.
 */
function validateMinimumAge(dobString: string | undefined | null): void {
  if (!dobString || typeof dobString !== "string") return; // DOB not provided; skip
  const age = calculateAgeFromDob(dobString);
  if (age === null) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid date of birth.",
    );
  }
  if (age < MIN_AGE_YEARS) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `You must be ${MIN_AGE_YEARS} or older to use Crush.`,
    );
  }
}

function profileBirthDate(profile: Record<string, unknown>): Date | null {
  const dobRaw = profile.birthDate ?? profile.dateOfBirth;
  return normalizeDate(dobRaw);
}

function profileBirthDateIso(profile: Record<string, unknown>): string | null {
  const dob = profileBirthDate(profile);
  return dob ? dob.toISOString() : null;
}

function deriveProfileAge(profile: Record<string, unknown>): number | null {
  const dob = profileBirthDate(profile);
  if (dob) {
    const age = calculateAgeFromDob(dob.toISOString());
    if (age !== null && age >= 0 && age <= 120) {
      return age;
    }
  }

  const fallbackAge = toNumber(profile.age);
  if (fallbackAge === undefined || fallbackAge < 0 || fallbackAge > 120) {
    return null;
  }
  return Math.floor(fallbackAge);
}

function profilePromptAnswers(profile: Record<string, unknown>): string[] {
  const structuredPrompts = profile.profilePrompts;
  if (Array.isArray(structuredPrompts)) {
    const answers = structuredPrompts
      .map((entry) => {
        if (typeof entry === "string") {
          return stripHtml(entry.trim());
        }
        const promptData = asRecord(entry);
        const answer = promptData.answer;
        if (typeof answer !== "string") return "";
        return stripHtml(answer.trim());
      })
      .filter((answer) => answer.length > 0);
    if (answers.length > 0) {
      return answers;
    }
  }
  return toStringArray(profile.prompts);
}

type DiscoveryDebugStage =
  | "schema"
  | "eligibility"
  | "relationship"
  | "filter";

interface DiscoveryDebugReason {
  code: string;
  stage: DiscoveryDebugStage;
  message: string;
}

type DiscoverySourceSchema = "canonical_nested" | "legacy_flat" | "hybrid";

interface DiscoveryPreferenceSnapshot {
  minAge: number;
  maxAge: number;
  maxDistanceKm: number;
  showMeGenders: string[];
  hideFromDiscovery: boolean;
  incognitoMode: boolean;
}

interface DiscoveryUserSnapshot {
  id: string;
  sourceSchema: DiscoverySourceSchema;
  username: string | null;
  name: string;
  bio: string;
  age: number | null;
  birthDateIso: string | null;
  gender: string | null;
  photoUrls: string[];
  interests: string[];
  prompts: string[];
  isVerified: boolean;
  city: string;
  country: string;
  latitude: number | null;
  longitude: number | null;
  preferences: DiscoveryPreferenceSnapshot;
  onboardingComplete: boolean;
  profileComplete: boolean;
  status: string | null;
  moderationStatus: string | null;
  updatedAtMs: number | null;
  lastActiveMs: number | null;
}

interface DiscoveryEligibilityResult {
  eligible: boolean;
  reasons: DiscoveryDebugReason[];
}

interface DiscoveryCandidateEvaluationResult {
  included: boolean;
  reasons: DiscoveryDebugReason[];
  distanceKm?: number;
  score?: number;
}

interface DiscoveryExclusionSets {
  blockedByMe: Set<string>;
  blockedMe: Set<string>;
  reportedByMe: Set<string>;
  reportedMe: Set<string>;
  swiped: Set<string>;
  liked: Set<string>;
  matched: Set<string>;
  combined: Set<string>;
}

interface DiscoveryDeckCandidate {
  user: DiscoveryUserSnapshot;
  score: number;
  distanceKm?: number;
  sortActivityMs: number;
}

interface DiscoveryDeckCursorPayload {
  version: number;
  uid: string;
  scope: string;
  lastScore: number;
  lastActivityMs: number;
  lastUserId: string;
}

interface DiscoveryDeckPaginationResult {
  page: DiscoveryDeckCandidate[];
  hasMore: boolean;
  nextCursor: string | null;
}

type DiscoveryCandidateQueryOperator = "==" | "in";

interface DiscoveryCandidateQueryFilter {
  fieldPath: string;
  op: DiscoveryCandidateQueryOperator;
  value: boolean | string | string[];
}

interface DiscoveryCandidateQueryPlan {
  filters: DiscoveryCandidateQueryFilter[];
  orderBy: {
    fieldPath: string;
    direction: FirebaseFirestore.OrderByDirection;
  };
  limit: number;
}

function normalizeTimestampMillis(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : parsed;
  }
  if (value instanceof Date) {
    const parsed = value.getTime();
    return Number.isNaN(parsed) ? null : parsed;
  }
  if (
    typeof value === "object" &&
    value !== null &&
    "toDate" in value &&
    typeof (value as { toDate?: unknown }).toDate === "function"
  ) {
    const parsed = (value as { toDate: () => Date }).toDate().getTime();
    return Number.isNaN(parsed) ? null : parsed;
  }
  if (
    typeof value === "object" &&
    value !== null &&
    "_seconds" in value &&
    typeof (value as { _seconds?: unknown })._seconds === "number"
  ) {
    const seconds = (value as { _seconds: number })._seconds;
    const firestoreTimestamp = value as {
      _nanoseconds?: unknown;
    };
    const nanos =
      typeof firestoreTimestamp._nanoseconds === "number"
        ? firestoreTimestamp._nanoseconds
        : 0;
    return seconds * 1000 + Math.floor(nanos / 1000000);
  }
  return null;
}

function buildDiscoveryReasons(
  reasons: Array<DiscoveryDebugReason | null | undefined>,
): DiscoveryDebugReason[] {
  return reasons.filter((reason): reason is DiscoveryDebugReason =>
    Boolean(reason),
  );
}

function toNonEmptyString(value: unknown): string {
  return typeof value === "string" ? stripHtml(value.trim()) : "";
}

function inferDiscoverySourceSchema(
  userData: Record<string, unknown>,
  profile: Record<string, unknown>,
): DiscoverySourceSchema {
  const hasNestedProfile = Object.keys(profile).length > 0;
  const hasLegacyFlatProfileFields =
    typeof userData.displayName === "string" ||
    typeof userData.gender === "string" ||
    Array.isArray(userData.photos) ||
    userData.location !== undefined;
  if (hasNestedProfile && hasLegacyFlatProfileFields) {
    return "hybrid";
  }
  if (hasNestedProfile) {
    return "canonical_nested";
  }
  return "legacy_flat";
}

function buildDiscoveryPreferenceSnapshot(
  userData: Record<string, unknown>,
  profile: Record<string, unknown>,
  options: CanonicalProfilePreferencesOptions = {},
): DiscoveryPreferenceSnapshot {
  const canonicalPreferences = getCanonicalProfilePreferences(userData, options);
  const settings = asRecord(userData.settings);
  const explicitShowMeGenders = normalizeDiscoveryPreferenceTokens(
    canonicalPreferences.showMeGenders,
  );
  const legacyInterestedIn = normalizeDiscoveryPreferenceTokens(
    userData.interestedIn,
  );
  const showMeGenders =
    explicitShowMeGenders.length > 0
      ? explicitShowMeGenders
      : legacyInterestedIn.length > 0
        ? legacyInterestedIn
        : [...CANONICAL_DISCOVERY_GENDERS];

  const minAge = Math.max(
    18,
    Math.round(
      toNumber(canonicalPreferences.minAge) ??
        toNumber(settings.ageRangeMin) ??
        18,
    ),
  );
  const maxAge = Math.min(
    100,
    Math.round(
      toNumber(canonicalPreferences.maxAge) ??
        toNumber(settings.ageRangeMax) ??
        100,
    ),
  );
  const maxDistanceKm = Math.max(
    1,
    Math.round(
      toNumber(canonicalPreferences.maxDistanceKm) ??
        toNumber(settings.maxDistance) ??
        100,
    ),
  );
  const hideFromDiscovery =
    canonicalPreferences.hideFromDiscovery === true ||
    settings.showInDiscovery === false;
  const incognitoMode =
    canonicalPreferences.incognitoMode === true ||
    settings.incognitoMode === true;

  return {
    minAge: Math.min(minAge, maxAge),
    maxAge: Math.max(minAge, maxAge),
    maxDistanceKm,
    showMeGenders,
    hideFromDiscovery,
    incognitoMode,
  };
}

function buildDiscoveryUserSnapshot(
  uid: string,
  userData: Record<string, unknown>,
  options: CanonicalProfilePreferencesOptions = {},
): DiscoveryUserSnapshot {
  const profile = asRecord(userData.profile);
  const location = asRecord(userData.location);
  const mergedProfile = { ...profile };

  if (!mergedProfile.name && typeof userData.displayName === "string") {
    mergedProfile.name = userData.displayName;
  }
  if (mergedProfile.birthDate === undefined && userData.birthDate !== undefined) {
    mergedProfile.birthDate = userData.birthDate;
  }
  if (mergedProfile.age === undefined && userData.age !== undefined) {
    mergedProfile.age = userData.age;
  }
  if (mergedProfile.gender === undefined && userData.gender !== undefined) {
    mergedProfile.gender = userData.gender;
  }
  if (mergedProfile.bio === undefined && userData.bio !== undefined) {
    mergedProfile.bio = userData.bio;
  }
  if (mergedProfile.interests === undefined && userData.interests !== undefined) {
    mergedProfile.interests = userData.interests;
  }
  if (mergedProfile.photoUrls === undefined && userData.photos !== undefined) {
    mergedProfile.photoUrls = userData.photos;
  }
  if (mergedProfile.latitude === undefined && location.latitude !== undefined) {
    mergedProfile.latitude = location.latitude;
  }
  if (
    mergedProfile.longitude === undefined &&
    location.longitude !== undefined
  ) {
    mergedProfile.longitude = location.longitude;
  }
  if (mergedProfile.city === undefined && location.city !== undefined) {
    mergedProfile.city = location.city;
  }
  if (mergedProfile.country === undefined && location.country !== undefined) {
    mergedProfile.country = location.country;
  }

  const photoUrls = toStringArray(mergedProfile.photoUrls);
  const fallbackPrimaryPhoto = toNonEmptyString(userData.profilePhotoUrl);
  if (photoUrls.length === 0 && fallbackPrimaryPhoto) {
    photoUrls.push(fallbackPrimaryPhoto);
  }

  const preferences = buildDiscoveryPreferenceSnapshot(
    userData,
    mergedProfile,
    options,
  );
  const moderationStatus = resolveDiscoveryModerationStatus(userData);

  return {
    id: uid,
    sourceSchema: inferDiscoverySourceSchema(userData, profile),
    username:
      toNonEmptyString(userData.username) ||
      toNonEmptyString(userData.usernameLower) ||
      null,
    name:
      toNonEmptyString(mergedProfile.name) ||
      toNonEmptyString(mergedProfile.displayName) ||
      "",
    bio: toNonEmptyString(mergedProfile.bio),
    age: deriveProfileAge(mergedProfile),
    birthDateIso: profileBirthDateIso(mergedProfile),
    gender: normalizeProfileGender(mergedProfile.gender),
    photoUrls,
    interests: toStringArray(mergedProfile.interests),
    prompts: profilePromptAnswers(mergedProfile),
    isVerified:
      mergedProfile.isVerified === true ||
      mergedProfile.verificationBadge === true ||
      userData.isVerified === true ||
      userData.idVerified === true,
    city: toNonEmptyString(mergedProfile.city),
    country: toNonEmptyString(mergedProfile.country),
    latitude: toNumber(mergedProfile.latitude) ?? null,
    longitude: toNumber(mergedProfile.longitude) ?? null,
    preferences,
    onboardingComplete: userData.onboardingComplete === true,
    profileComplete: userData.profileComplete === true,
    status: toNonEmptyString(userData.status).toLowerCase() || null,
    moderationStatus,
    updatedAtMs:
      normalizeTimestampMillis(userData.updatedAt) ??
      normalizeTimestampMillis(userData.createdAt),
    lastActiveMs:
      normalizeTimestampMillis(userData.lastActive) ??
      normalizeTimestampMillis(userData.updatedAt) ??
      normalizeTimestampMillis(userData.createdAt),
  };
}

function discoveryModerationPriority(status: string): number {
  switch (status) {
  case "banned":
    return 50;
  case "held":
    return 40;
  case "needs_review":
    return 35;
  case "suspended":
    return 30;
  case "watch":
    return 10;
  default:
    return 0;
  }
}

function resolveDiscoveryModerationStatus(
  userData: Record<string, unknown>,
): string | null {
  const moderation = asRecord(userData.moderation);
  const safetyFlags = asRecord(userData.safetyFlags);
  const candidates = [
    toNonEmptyString(moderation.status).toLowerCase(),
    toNonEmptyString(userData.moderationStatus).toLowerCase(),
    toNonEmptyString(safetyFlags.status).toLowerCase(),
  ].filter((status): status is string => status.length > 0);

  if (candidates.length === 0) {
    return null;
  }

  let selectedStatus = candidates[0];
  let selectedPriority = discoveryModerationPriority(selectedStatus);
  for (const candidateStatus of candidates.slice(1)) {
    const candidatePriority = discoveryModerationPriority(candidateStatus);
    if (candidatePriority > selectedPriority) {
      selectedStatus = candidateStatus;
      selectedPriority = candidatePriority;
    }
  }

  return selectedStatus;
}

function evaluateDiscoveryEligibility(
  user: DiscoveryUserSnapshot,
): DiscoveryEligibilityResult {
  const reasons = buildDiscoveryReasons([
    !user.name
      ? {
          code: "missing_name",
          stage: "eligibility",
          message: "Profile name is missing.",
        }
      : null,
    user.age === null || user.age < MIN_AGE_YEARS
      ? {
          code: "missing_or_invalid_age",
          stage: "eligibility",
          message: "A valid adult birth date or age is required.",
        }
      : null,
    !user.gender
      ? {
          code: "missing_gender",
          stage: "eligibility",
          message: "Gender is required for discovery.",
        }
      : null,
    user.photoUrls.length === 0
      ? {
          code: "missing_photos",
          stage: "eligibility",
          message: "At least one photo is required for discovery.",
        }
      : null,
    user.preferences.showMeGenders.length === 0
      ? {
          code: "missing_preferences",
          stage: "eligibility",
          message: "Discovery preferences are missing.",
        }
      : null,
    user.preferences.hideFromDiscovery
      ? {
          code: "hidden_from_discovery",
          stage: "eligibility",
          message: "The profile is hidden from discovery.",
        }
      : null,
    user.preferences.incognitoMode
      ? {
          code: "incognito_mode_enabled",
          stage: "eligibility",
          message: "The profile is in incognito mode.",
        }
      : null,
    user.status === "deactivated" ||
    user.status === "pending" ||
    user.status === "disabled" ||
    user.status === "deleted" ||
    user.status === "banned"
      ? {
          code: "account_not_active",
          stage: "eligibility",
          message: `Account status ${user.status} prevents discovery.`,
        }
      : null,
    user.moderationStatus === "held" ||
    user.moderationStatus === "needs_review" ||
    user.moderationStatus === "banned"
      ? {
          code: "moderation_hold",
          stage: "eligibility",
          message:
            "Moderation state prevents the profile from appearing in discovery.",
        }
      : null,
  ]);

  return {
    eligible: reasons.length === 0,
    reasons,
  };
}

function buildDiscoveryDebugSummary(user: DiscoveryUserSnapshot): Record<string, unknown> {
  return {
    sourceSchema: user.sourceSchema,
    username: user.username,
    name: user.name,
    age: user.age,
    birthDateIso: user.birthDateIso,
    gender: user.gender,
    photoCount: user.photoUrls.length,
    interestsCount: user.interests.length,
    city: user.city,
    country: user.country,
    onboardingComplete: user.onboardingComplete,
    profileComplete: user.profileComplete,
    status: user.status,
    moderationStatus: user.moderationStatus,
    preferences: user.preferences,
    updatedAtMs: user.updatedAtMs,
    lastActiveMs: user.lastActiveMs,
  };
}

function sameStringArray(a: string[], b: string[]): boolean {
  if (a.length !== b.length) return false;
  return a.every((value, index) => value === b[index]);
}

function rootBirthDateIso(userData: Record<string, unknown>): string | null {
  const millis = normalizeTimestampMillis(userData.birthDate);
  if (millis === null) return null;
  return new Date(millis).toISOString();
}

function normalizedLegacyLocation(
  value: unknown,
): {
  city?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
} | null {
  const location = asRecord(value);
  const city = toNonEmptyString(location.city);
  const country = toNonEmptyString(location.country);
  const latitude = toNumber(location.latitude) ?? undefined;
  const longitude = toNumber(location.longitude) ?? undefined;
  if (!city && !country && latitude === undefined && longitude === undefined) {
    return null;
  }
  return {
    ...(city ? { city } : {}),
    ...(country ? { country } : {}),
    ...(latitude !== undefined ? { latitude } : {}),
    ...(longitude !== undefined ? { longitude } : {}),
  };
}

function sameLegacyLocation(
  a: ReturnType<typeof normalizedLegacyLocation>,
  b: ReturnType<typeof normalizedLegacyLocation>,
): boolean {
  if (a === null && b === null) return true;
  if (a === null || b === null) return false;
  return (
    a.city === b.city &&
    a.country === b.country &&
    a.latitude === b.latitude &&
    a.longitude === b.longitude
  );
}

function buildLegacyDiscoverySettingsPatch(
  currentValue: unknown,
  preferences: DiscoveryPreferenceSnapshot,
): Record<string, unknown> | null {
  const current = asRecord(currentValue);
  const desired = {
    ageRangeMin: preferences.minAge,
    ageRangeMax: preferences.maxAge,
    maxDistance: preferences.maxDistanceKm,
    showInDiscovery: !preferences.hideFromDiscovery,
    incognitoMode: preferences.incognitoMode,
  };

  if (
    toNumber(current.ageRangeMin) === desired.ageRangeMin &&
    toNumber(current.ageRangeMax) === desired.ageRangeMax &&
    toNumber(current.maxDistance) === desired.maxDistance &&
    current.showInDiscovery === desired.showInDiscovery &&
    current.incognitoMode === desired.incognitoMode
  ) {
    return null;
  }

  return desired;
}

function buildLegacyDiscoveryMirrorPatch(
  uid: string,
  userData: Record<string, unknown>,
): Record<string, unknown> {
  const snapshot = buildDiscoveryUserSnapshot(uid, userData);
  const eligibility = evaluateDiscoveryEligibility(snapshot);
  const patch: Record<string, unknown> = {};

  if (snapshot.name && snapshot.name !== toNonEmptyString(userData.displayName)) {
    patch.displayName = snapshot.name;
  }

  if (snapshot.bio && snapshot.bio !== toNonEmptyString(userData.bio)) {
    patch.bio = snapshot.bio;
  }

  if (snapshot.birthDateIso && snapshot.birthDateIso !== rootBirthDateIso(userData)) {
    patch.birthDate = snapshot.birthDateIso;
  }

  if (
    snapshot.age !== null &&
    Math.round(toNumber(userData.age) ?? Number.NaN) !== snapshot.age
  ) {
    patch.age = snapshot.age;
  }

  if (
    snapshot.gender &&
    normalizeProfileGender(userData.gender) !== snapshot.gender
  ) {
    patch.gender = snapshot.gender;
  }

  const currentPhotos = toStringArray(userData.photos);
  if (
    snapshot.photoUrls.length > 0 &&
    !sameStringArray(currentPhotos, snapshot.photoUrls)
  ) {
    patch.photos = snapshot.photoUrls;
  }

  const desiredPrimaryPhoto = snapshot.photoUrls[0];
  if (
    desiredPrimaryPhoto &&
    desiredPrimaryPhoto !== toNonEmptyString(userData.profilePhotoUrl)
  ) {
    patch.profilePhotoUrl = desiredPrimaryPhoto;
  }

  if (
    snapshot.interests.length > 0 &&
    !sameStringArray(toStringArray(userData.interests), snapshot.interests)
  ) {
    patch.interests = snapshot.interests;
  }

  if (!sameStringArray(toStringArray(userData.prompts), snapshot.prompts)) {
    patch.prompts = snapshot.prompts;
  }

  if (
    !sameStringArray(
      normalizeDiscoveryPreferenceTokens(userData.interestedIn),
      snapshot.preferences.showMeGenders,
    )
  ) {
    patch.interestedIn = snapshot.preferences.showMeGenders;
  }

  const desiredSettings = buildLegacyDiscoverySettingsPatch(
    userData.settings,
    snapshot.preferences,
  );
  if (desiredSettings) {
    patch.settings = desiredSettings;
  }

  if (userData.isVerified === true !== snapshot.isVerified) {
    patch.isVerified = snapshot.isVerified;
  }

  const desiredLocation = normalizedLegacyLocation({
    city: snapshot.city,
    country: snapshot.country,
    latitude: snapshot.latitude,
    longitude: snapshot.longitude,
  });
  const currentLocation = normalizedLegacyLocation(userData.location);
  if (desiredLocation && !sameLegacyLocation(currentLocation, desiredLocation)) {
    patch.location = desiredLocation;
  }

  if (
    snapshot.lastActiveMs !== null &&
    normalizeTimestampMillis(userData.lastActive) !== snapshot.lastActiveMs
  ) {
    patch.lastActive = admin.firestore.Timestamp.fromMillis(snapshot.lastActiveMs);
  }

  const legacyDiscoveryReady = eligibility.eligible;
  if (userData.onboardingComplete !== legacyDiscoveryReady) {
    patch.onboardingComplete = legacyDiscoveryReady;
  }

  if (userData.profileComplete !== legacyDiscoveryReady) {
    patch.profileComplete = legacyDiscoveryReady;
  }

  return patch;
}

function recentDiscoveryBoost(updatedAtMs: number | null): number {
  if (updatedAtMs === null) return 0;
  const hoursOld = Math.max(0, (Date.now() - updatedAtMs) / (1000 * 60 * 60));
  if (hoursOld <= 1) return 0.4;
  if (hoursOld <= 24) return 0.25;
  if (hoursOld <= 72) return 0.1;
  return 0;
}

function buildDiscoveryProfileResponse(
  user: DiscoveryUserSnapshot,
  score: number,
  distanceKm: number | undefined,
): Record<string, unknown> {
  return {
    id: user.id,
    userId: user.id,
    username: user.username,
    name: user.name,
    age: user.age,
    gender: user.gender,
    bio: user.bio,
    photoUrls: user.photoUrls,
    interests: user.interests,
    prompts: user.prompts,
    country: user.country,
    city: user.city,
    latitude: user.latitude,
    longitude: user.longitude,
    isVerified: user.isVerified,
    distanceKm,
    score,
    sourceSchema: user.sourceSchema,
  };
}

function normalizeDiscoveryDeckSortScore(score: number): number {
  if (!Number.isFinite(score)) return 0;
  return Number(score.toFixed(6));
}

function buildDiscoveryDeckRequestScope(params: {
  uid: string;
  minAge: number;
  maxAge: number;
  maxDistanceKm: number;
  showMeGenders: string[];
  interests: string[];
  requirePhotos: boolean;
  requireVerified: boolean;
  latitude: number | null;
  longitude: number | null;
}): string {
  const roundedLatitude =
    params.latitude === null ? null : Number(params.latitude.toFixed(6));
  const roundedLongitude =
    params.longitude === null ? null : Number(params.longitude.toFixed(6));

  const payload = {
    uid: params.uid,
    minAge: params.minAge,
    maxAge: params.maxAge,
    maxDistanceKm: params.maxDistanceKm,
    showMeGenders: [...params.showMeGenders].sort(),
    interests: [...params.interests].sort(),
    requirePhotos: params.requirePhotos,
    requireVerified: params.requireVerified,
    latitude: roundedLatitude,
    longitude: roundedLongitude,
  };

  return crypto
    .createHash("sha256")
    .update(JSON.stringify(payload))
    .digest("hex");
}

function encodeDiscoveryDeckCursor(
  payload: DiscoveryDeckCursorPayload,
): string {
  return Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
}

function decodeDiscoveryDeckCursor(cursor: string): DiscoveryDeckCursorPayload {
  if (cursor.trim().length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Discovery cursor cannot be empty.",
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(Buffer.from(cursor, "base64url").toString("utf8"));
  } catch {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Discovery cursor is malformed.",
    );
  }

  const payload = parsed as Partial<DiscoveryDeckCursorPayload>;
  if (
    payload.version !== DISCOVERY_DECK_CURSOR_VERSION ||
    typeof payload.uid !== "string" ||
    typeof payload.scope !== "string" ||
    typeof payload.lastScore !== "number" ||
    !Number.isFinite(payload.lastScore) ||
    typeof payload.lastActivityMs !== "number" ||
    !Number.isFinite(payload.lastActivityMs) ||
    typeof payload.lastUserId !== "string" ||
    payload.lastUserId.length === 0
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Discovery cursor payload is invalid.",
    );
  }

  return payload as DiscoveryDeckCursorPayload;
}

function compareDiscoveryDeckCandidates(
  a: DiscoveryDeckCandidate,
  b: DiscoveryDeckCandidate,
): number {
  if (a.score !== b.score) {
    return b.score - a.score;
  }
  if (a.sortActivityMs !== b.sortActivityMs) {
    return b.sortActivityMs - a.sortActivityMs;
  }
  return a.user.id.localeCompare(b.user.id);
}

function isDiscoveryDeckCandidateAfterCursor(
  candidate: DiscoveryDeckCandidate,
  cursor: DiscoveryDeckCursorPayload,
): boolean {
  if (candidate.score < cursor.lastScore) return true;
  if (candidate.score > cursor.lastScore) return false;
  if (candidate.sortActivityMs < cursor.lastActivityMs) return true;
  if (candidate.sortActivityMs > cursor.lastActivityMs) return false;
  return candidate.user.id.localeCompare(cursor.lastUserId) > 0;
}

function paginateDiscoveryDeckCandidates(params: {
  uid: string;
  scope: string;
  candidates: DiscoveryDeckCandidate[];
  limit: number;
  cursor?: string;
}): DiscoveryDeckPaginationResult {
  let filteredCandidates = params.candidates;

  if (typeof params.cursor === "string" && params.cursor.trim().length > 0) {
    const cursor = decodeDiscoveryDeckCursor(params.cursor);
    if (cursor.uid !== params.uid || cursor.scope !== params.scope) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Discovery cursor does not match this request.",
      );
    }

    filteredCandidates = params.candidates.filter((candidate) =>
      isDiscoveryDeckCandidateAfterCursor(candidate, cursor),
    );
  }

  const page = filteredCandidates.slice(0, params.limit);
  const hasMore = filteredCandidates.length > page.length;
  const lastCandidate = page.length > 0 ? page[page.length - 1] : undefined;
  const nextCursor =
    hasMore && lastCandidate
      ? encodeDiscoveryDeckCursor({
          version: DISCOVERY_DECK_CURSOR_VERSION,
          uid: params.uid,
          scope: params.scope,
          lastScore: lastCandidate.score,
          lastActivityMs: lastCandidate.sortActivityMs,
          lastUserId: lastCandidate.user.id,
        })
      : null;

  return {
    page,
    hasMore,
    nextCursor,
  };
}

function areAllCanonicalDiscoveryGendersSelected(
  genders: string[],
): boolean {
  if (genders.length !== CANONICAL_DISCOVERY_GENDERS.length) {
    return false;
  }

  const selected = new Set(genders);
  return CANONICAL_DISCOVERY_GENDERS.every((gender) => selected.has(gender));
}

function buildDiscoveryCandidateQueryPlan(params: {
  showMeGenders: string[];
  requireVerified: boolean;
  limit: number;
}): DiscoveryCandidateQueryPlan {
  const filters: DiscoveryCandidateQueryFilter[] = [
    { fieldPath: "onboardingComplete", op: "==", value: true },
    { fieldPath: "profileComplete", op: "==", value: true },
  ];

  const normalizedGenders = [...new Set(params.showMeGenders)].sort();
  if (
    normalizedGenders.length > 0 &&
    !areAllCanonicalDiscoveryGendersSelected(normalizedGenders)
  ) {
    filters.push({
      fieldPath: "gender",
      op: normalizedGenders.length === 1 ? "==" : "in",
      value:
        normalizedGenders.length === 1
          ? normalizedGenders[0]
          : normalizedGenders,
    });
  }

  if (params.requireVerified) {
    filters.push({ fieldPath: "isVerified", op: "==", value: true });
  }

  return {
    filters,
    orderBy: {
      fieldPath: "updatedAt",
      direction: "desc",
    },
    limit: params.limit,
  };
}

async function fetchDiscoveryCandidateSnapshotWithFallback(params: {
  uid: string;
  source: string;
  plan: DiscoveryCandidateQueryPlan;
}): Promise<FirebaseFirestore.QuerySnapshot> {
  try {
    let query: FirebaseFirestore.Query = db.collection("users");
    for (const filter of params.plan.filters) {
      query = query.where(
        filter.fieldPath,
        filter.op as FirebaseFirestore.WhereFilterOp,
        filter.value as string | string[] | boolean,
      );
    }

    return await query
      .orderBy(params.plan.orderBy.fieldPath, params.plan.orderBy.direction)
      .limit(params.plan.limit)
      .get();
  } catch (err) {
    console.warn("discovery_prefilter_query_fallback", {
      uid: params.uid,
      source: params.source,
      filters: params.plan.filters.map((filter) => ({
        fieldPath: filter.fieldPath,
        op: filter.op,
      })),
      error: err instanceof Error ? err.message : String(err),
    });

    try {
      return await db
        .collection("users")
        .orderBy("updatedAt", "desc")
        .limit(params.plan.limit)
        .get();
    } catch (fallbackErr) {
      console.warn("discovery_query_order_fallback", {
        uid: params.uid,
        source: params.source,
        error:
          fallbackErr instanceof Error
            ? fallbackErr.message
            : String(fallbackErr),
      });
      try {
        return await db
          .collection("users")
          .orderBy("createdAt", "desc")
          .limit(params.plan.limit)
          .get();
      } catch {
        return db.collection("users").limit(params.plan.limit).get();
      }
    }
  }
}

function evaluateDiscoveryCandidateForRequester(params: {
  requester: DiscoveryUserSnapshot;
  candidate: DiscoveryUserSnapshot;
  request: DiscoveryRequest;
  exclusionSets: DiscoveryExclusionSets;
}): DiscoveryCandidateEvaluationResult {
  const { requester, candidate, request, exclusionSets } = params;

  if (candidate.id === requester.id) {
    return {
      included: false,
      reasons: [
        {
          code: "self_excluded",
          stage: "relationship",
          message: "The current user is excluded from their own discovery deck.",
        },
      ],
    };
  }
  if (exclusionSets.blockedByMe.has(candidate.id)) {
    return {
      included: false,
      reasons: [
        {
          code: "blocked_by_requester",
          stage: "relationship",
          message: "The requester has blocked this profile.",
        },
      ],
    };
  }
  if (exclusionSets.blockedMe.has(candidate.id)) {
    return {
      included: false,
      reasons: [
        {
          code: "blocked_requester",
          stage: "relationship",
          message: "This profile has blocked the requester.",
        },
      ],
    };
  }
  if (exclusionSets.reportedByMe.has(candidate.id)) {
    return {
      included: false,
      reasons: [
        {
          code: "reported_by_requester",
          stage: "relationship",
          message: "The requester has reported this profile.",
        },
      ],
    };
  }
  if (exclusionSets.reportedMe.has(candidate.id)) {
    return {
      included: false,
      reasons: [
        {
          code: "reported_requester",
          stage: "relationship",
          message: "This profile has reported the requester.",
        },
      ],
    };
  }
  if (exclusionSets.matched.has(candidate.id)) {
    return {
      included: false,
      reasons: [
        {
          code: "already_matched",
          stage: "relationship",
          message: "This profile is already matched with the requester.",
        },
      ],
    };
  }
  if (exclusionSets.liked.has(candidate.id)) {
    return {
      included: false,
      reasons: [
        {
          code: "already_liked",
          stage: "relationship",
          message: "The requester has already liked this profile.",
        },
      ],
    };
  }
  if (exclusionSets.swiped.has(candidate.id)) {
    return {
      included: false,
      reasons: [
        {
          code: "already_swiped",
          stage: "relationship",
          message: "The requester has already swiped on this profile.",
        },
      ],
    };
  }

  const eligibility = evaluateDiscoveryEligibility(candidate);
  if (!eligibility.eligible) {
    return {
      included: false,
      reasons: eligibility.reasons,
    };
  }

  const requestedShowMeGenders = normalizeDiscoveryPreferenceTokens(
    request.showMeGenders,
  );
  const showMeGenders =
    requestedShowMeGenders.length > 0
      ? requestedShowMeGenders
      : requester.preferences.showMeGenders;
  if (
    showMeGenders.length > 0 &&
    (!candidate.gender || !showMeGenders.includes(candidate.gender))
  ) {
    return {
      included: false,
      reasons: [
        {
          code: "gender_filtered",
          stage: "filter",
          message: "The candidate does not match the requester's gender filter.",
        },
      ],
    };
  }

  const minAge = Math.max(
    18,
    Math.round(toNumber(request.minAge) ?? requester.preferences.minAge),
  );
  const maxAge = Math.min(
    100,
    Math.round(toNumber(request.maxAge) ?? requester.preferences.maxAge),
  );
  if (
    candidate.age === null ||
    candidate.age < minAge ||
    candidate.age > maxAge
  ) {
    return {
      included: false,
      reasons: [
        {
          code: "age_filtered",
          stage: "filter",
          message: "The candidate does not match the requester's age range.",
        },
      ],
    };
  }

  const requirePhotos = request.requirePhotos === true;
  if (requirePhotos && candidate.photoUrls.length === 0) {
    return {
      included: false,
      reasons: [
        {
          code: "photos_required",
          stage: "filter",
          message: "The candidate is missing photos required by the request.",
        },
      ],
    };
  }

  const requireVerified = request.requireVerified === true;
  if (requireVerified && !candidate.isVerified) {
    return {
      included: false,
      reasons: [
        {
          code: "verification_required",
          stage: "filter",
          message: "The candidate is not verified.",
        },
      ],
    };
  }

  const requiredInterests = new Set(
    toStringArray(request.interests).map((interest) => interest.toLowerCase()),
  );
  if (requiredInterests.size > 0) {
    const candidateInterests = candidate.interests.map((interest) =>
      interest.toLowerCase(),
    );
    const hasSharedInterest = candidateInterests.some((interest) =>
      requiredInterests.has(interest),
    );
    if (!hasSharedInterest) {
      return {
        included: false,
        reasons: [
          {
            code: "interest_filtered",
            stage: "filter",
            message:
              "The candidate does not share any interests required by the request.",
          },
        ],
      };
    }
  }

  const maxDistanceKm = Math.max(
    1,
    Math.round(
      toNumber(request.maxDistanceKm) ?? requester.preferences.maxDistanceKm,
    ),
  );
  const myLat =
    toNumber(request.latitude) ??
    (requester.latitude === null ? undefined : requester.latitude);
  const myLon =
    toNumber(request.longitude) ??
    (requester.longitude === null ? undefined : requester.longitude);
  const distanceKm = haversineDistanceKm(
    myLat,
    myLon,
    candidate.latitude === null ? undefined : candidate.latitude,
    candidate.longitude === null ? undefined : candidate.longitude,
  );
  let noLocationPenalty = 0;

  if (distanceKm !== undefined && distanceKm > maxDistanceKm + 5) {
    if (distanceKm > maxDistanceKm * 2) {
      return {
        included: false,
        reasons: [
          {
            code: "distance_filtered",
            stage: "filter",
            message:
              "The candidate is outside the requester's discovery distance.",
          },
        ],
      };
    }
    noLocationPenalty = 0.3;
  }

  if (candidate.latitude === null || candidate.longitude === null) {
    if (
      myLat !== null &&
      myLat !== undefined &&
      myLon !== null &&
      myLon !== undefined &&
      requester.country &&
      candidate.country &&
      candidate.country !== requester.country
    ) {
      noLocationPenalty = 0.4;
    } else if (!candidate.country && !requester.country) {
      noLocationPenalty = 0.2;
    } else {
      noLocationPenalty = 0.15;
    }
  }

  const requesterInterests = new Set(
    requester.interests.map((interest) => interest.toLowerCase()),
  );
  const sharedInterests = candidate.interests.filter((interest) =>
    requesterInterests.has(interest.toLowerCase()),
  ).length;
  const verifiedBoost = candidate.isVerified ? 0.4 : 0;
  const distanceBoost =
    distanceKm !== undefined && maxDistanceKm > 0
      ? Math.max(0, (maxDistanceKm - distanceKm) / maxDistanceKm)
      : 0.1;
  const interestBoost = Math.min(sharedInterests * 0.05, 0.25);
  const recencyBoost = recentDiscoveryBoost(
    candidate.updatedAtMs ?? candidate.lastActiveMs,
  );

  return {
    included: true,
    reasons: [],
    distanceKm,
    score:
      1 +
      verifiedBoost +
      distanceBoost +
      interestBoost +
      recencyBoost -
      noLocationPenalty,
  };
}

function readDiscoveryRelationUserId(
  record: Record<string, unknown>,
  fieldNames: string[],
): string | null {
  for (const fieldName of fieldNames) {
    const value = optionalString(record[fieldName]);
    if (value) {
      return value;
    }
  }
  return null;
}

function addDiscoveryRelationSet(params: {
  uid: string;
  records: Array<Record<string, unknown>>;
  fieldNames: string[];
}): Set<string> {
  const result = new Set<string>();

  for (const record of params.records) {
    const targetId = readDiscoveryRelationUserId(record, params.fieldNames);
    if (targetId && targetId !== params.uid) {
      result.add(targetId);
    }
  }

  return result;
}

function buildDiscoveryExclusionSetsFromRecords(
  uid: string,
  sources: {
    blockedByMe?: Array<Record<string, unknown>>;
    blockedMe?: Array<Record<string, unknown>>;
    reportedByMe?: Array<Record<string, unknown>>;
    reportedMe?: Array<Record<string, unknown>>;
    likes?: Array<Record<string, unknown>>;
    swipes?: Array<Record<string, unknown>>;
    matches?: Array<Record<string, unknown>>;
  },
): DiscoveryExclusionSets {
  const blockedByMe = addDiscoveryRelationSet({
    uid,
    records: sources.blockedByMe ?? [],
    fieldNames: ["blockedId", "blocked_id"],
  });

  const blockedMe = addDiscoveryRelationSet({
    uid,
    records: sources.blockedMe ?? [],
    fieldNames: ["blockerId", "blocker_id"],
  });

  const reportedByMe = addDiscoveryRelationSet({
    uid,
    records: sources.reportedByMe ?? [],
    fieldNames: ["reportedId", "reported_id"],
  });

  const reportedMe = addDiscoveryRelationSet({
    uid,
    records: sources.reportedMe ?? [],
    fieldNames: ["reporterId", "reporter_id"],
  });

  const liked = addDiscoveryRelationSet({
    uid,
    records: sources.likes ?? [],
    fieldNames: ["toUserId", "to_user_id"],
  });

  const swiped = addDiscoveryRelationSet({
    uid,
    records: sources.swipes ?? [],
    fieldNames: ["targetId", "swipedUserId", "target_id", "swiped_user_id"],
  });

  const matched = new Set<string>();
  for (const record of sources.matches ?? []) {
    const userIds = Array.isArray(record.userIds)
      ? record.userIds
      : Array.isArray(record.participants)
        ? record.participants
        : [];
    for (const otherId of userIds) {
      if (typeof otherId === "string" && otherId && otherId !== uid) {
        matched.add(otherId);
      }
    }
  }

  const combined = new Set<string>([
    uid,
    ...blockedByMe,
    ...blockedMe,
    ...reportedByMe,
    ...reportedMe,
    ...liked,
    ...swiped,
    ...matched,
  ]);

  return {
    blockedByMe,
    blockedMe,
    reportedByMe,
    reportedMe,
    swiped,
    liked,
    matched,
    combined,
  };
}
// OTP secret is required - never fall back to a predictable value
const getOtpSecretChecked = () => {
  const otpSecret = getOtpSecret();
  if (!otpSecret) {
    console.error(
      "CRITICAL: OTP_SECRET not configured in .env file. OTP functions will fail.",
    );
  }
  return otpSecret;
};

type RateLimitResult = {
  allowed: boolean;
  retryAfterMs?: number;
};

function normalizeEmail(value: string): string {
  return value.trim().toLowerCase();
}

function normalizeUsername(value: string): string {
  return value.trim().toLowerCase();
}

function isEmailLike(value: string): boolean {
  return EMAIL_REGEX.test(value.trim());
}

function generateOtp(): string {
  const min = Math.pow(10, OTP_DIGITS - 1);
  const max = Math.pow(10, OTP_DIGITS) - 1;
  const code = crypto.randomInt(min, max + 1);
  return `${code}`;
}

function hashWithSecret(value: string, salt: string): string {
  const otpSecret = getOtpSecretChecked();
  if (!otpSecret) {
    throw new functions.https.HttpsError(
      "internal",
      "OTP service not configured. Please contact support.",
    );
  }
  return crypto
    .createHmac("sha256", otpSecret)
    .update(`${salt}:${value}`)
    .digest("hex");
}

function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  const aBuf = Buffer.from(a, "hex");
  const bBuf = Buffer.from(b, "hex");
  return crypto.timingSafeEqual(aBuf, bBuf);
}

function getClientIp(context: CallableContext): string | undefined {
  const raw = context.rawRequest;
  const forwarded = raw?.headers?.["x-forwarded-for"];
  if (Array.isArray(forwarded)) {
    return forwarded[0]?.toString();
  }
  if (typeof forwarded === "string") {
    return forwarded.split(",")[0]?.trim();
  }
  return raw?.ip;
}

async function applyRateLimit(
  key: string,
  limit: number,
  windowMs: number,
  blockMs: number,
): Promise<RateLimitResult> {
  const ref = db.collection("auth_rate_limits").doc(key);
  const now = Date.now();
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    let attempts = 0;
    let windowStart = now;
    let blockedUntil = 0;
    if (snap.exists) {
      const data = snap.data() || {};
      windowStart = toMillis(data.windowStart, now);
      blockedUntil = toMillis(data.blockedUntil, 0);
      attempts = typeof data.attempts === "number" ? data.attempts : 0;
    }

    if (blockedUntil > now) {
      return { allowed: false, retryAfterMs: blockedUntil - now };
    }

    if (now - windowStart > windowMs) {
      windowStart = now;
      attempts = 0;
    }

    attempts += 1;
    if (attempts > limit) {
      blockedUntil = now + blockMs;
    }

    tx.set(
      ref,
      {
        key,
        attempts,
        windowStart: new Date(windowStart),
        blockedUntil: blockedUntil ? new Date(blockedUntil) : null,
      },
      { merge: true },
    );

    if (blockedUntil > now) {
      return { allowed: false, retryAfterMs: blockedUntil - now };
    }
    return { allowed: true };
  });

  return result;
}

// Format retry time for user-friendly message
function formatRetryTime(ms?: number): string {
  if (!ms) return "a few moments";
  const seconds = Math.ceil(ms / 1000);
  if (seconds < 60) return `${seconds} seconds`;
  const minutes = Math.ceil(seconds / 60);
  if (minutes < 60) return `${minutes} minute${minutes > 1 ? "s" : ""}`;
  const hours = Math.ceil(minutes / 60);
  return `${hours} hour${hours > 1 ? "s" : ""}`;
}

// Throw a standardized rate limit error with retry timing
function throwRateLimitError(retryAfterMs?: number): never {
  const retryTime = formatRetryTime(retryAfterMs);
  throw new functions.https.HttpsError(
    "resource-exhausted",
    `Too many attempts. Please try again in ${retryTime}.`,
    { retryAfterMs: retryAfterMs ?? 60000 },
  );
}

function parseBoundedIntQueryParam(
  value: unknown,
  {
    fallback,
    min,
    max,
  }: {
    fallback: number;
    min: number;
    max: number;
  },
): number {
  if (typeof value !== "string") return fallback;
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(Math.max(parsed, min), max);
}

function parseChatMessagesBeforeCursor(value: unknown): {
  beforeTimestamp?: Date;
  beforeMessageId?: string;
} {
  const raw = typeof value === "string" ? value.trim() : "";
  if (raw.length === 0) {
    return {};
  }

  const parsedDate = new Date(raw);
  if (!Number.isNaN(parsedDate.getTime())) {
    return { beforeTimestamp: parsedDate };
  }

  return { beforeMessageId: raw };
}

/**
 * Parse a `before` ISO-timestamp pagination cursor shared by the
 * `lastMessageAt`-ordered list endpoints (matches, conversations).
 * Returns `invalid: true` for a present-but-unparseable cursor so callers can
 * answer 400 consistently; an absent cursor is valid with no timestamp.
 */
function parseBeforeTimestampCursor(value: unknown): {
  invalid: boolean;
  timestamp?: Date;
} {
  const raw = typeof value === "string" ? value.trim() : "";
  if (raw.length === 0) {
    return { invalid: false };
  }

  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) {
    return { invalid: true };
  }

  return { invalid: false, timestamp: parsed };
}

async function logAuthAudit(params: {
  action: string;
  status: "ok" | "blocked" | "invalid" | "error";
  uid?: string;
  identifierHash?: string;
  ip?: string;
  userAgent?: string;
  metadata?: Record<string, unknown>;
}) {
  await db.collection("auth_audit_logs").add({
    action: params.action,
    status: params.status,
    uid: params.uid ?? null,
    identifierHash: params.identifierHash ?? null,
    ip: params.ip ?? null,
    userAgent: params.userAgent ?? null,
    metadata: params.metadata ?? {},
    createdAt: serverTimestamp(),
  });
}

async function sendOtpEmail(params: {
  to: string;
  otp: string;
  purpose: string;
}) {
  const { resendKey, from } = getEmailConfig();
  if (!resendKey) {
    console.warn("RESEND_API_KEY not set; skipping email send.");
    return;
  }
  const subject = "Your Crush verification code";
  const text = [
    "Hello,",
    "",
    `Your Crush verification code is: ${params.otp}`,
    "This code expires in 10 minutes and can only be used once.",
    "",
    "If you did not request this, you can ignore this email.",
    "",
    "Thanks,",
    "Crush Security",
  ].join("\\n");
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [params.to],
      subject,
      text,
      tags: [{ name: "purpose", value: params.purpose }],
    }),
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Resend error: ${response.status} ${body}`);
  }
}

async function sendPasswordChangedEmail(params: {
  to: string;
  method: "in_app" | "forgot_password";
}) {
  const { resendKey, from } = getEmailConfig();
  if (!resendKey) {
    console.warn("RESEND_API_KEY not set; skipping email send.");
    return;
  }
  const subject = "Your Crush password was changed";
  const methodText =
    params.method === "forgot_password"
      ? "using the forgot password feature"
      : "from within the app";
  const text = [
    "Hello,",
    "",
    `Your Crush account password was recently changed ${methodText}.`,
    "",
    "If you made this change, you can safely ignore this email.",
    "",
    "If you did NOT change your password, please secure your account immediately:",
    "1. Reset your password using the 'Forgot Password' option in the app",
    "2. Review your account activity",
    "3. Contact our support team if you need assistance",
    "",
    "Your account security is important to us.",
    "",
    "Thanks,",
    "Crush Security Team",
  ].join("\\n");
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [params.to],
      subject,
      text,
      tags: [{ name: "purpose", value: "password_changed" }],
    }),
  });
  if (!response.ok) {
    const body = await response.text();
    console.error(`Password changed email failed: ${response.status} ${body}`);
  }
}

async function sendDatePlanEmail(params: {
  to: string;
  contactName: string;
  creatorName: string;
  matchName: string;
  dateLabel: string;
  timeLabel: string;
  location: string;
  notes?: string;
}) {
  const { resendKey, from } = getEmailConfig();
  if (!resendKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Email notifications are not configured.",
    );
  }
  const subject = `${params.creatorName} shared a Crush date plan`;
  const lines = [
    `Hi ${params.contactName},`,
    "",
    `${params.creatorName} shared their date plan with you in Crush.`,
    "",
    `Who: ${params.matchName}`,
    `When: ${params.dateLabel} at ${params.timeLabel}`,
    `Where: ${params.location}`,
  ];
  if (params.notes) {
    lines.push(`Notes: ${params.notes}`);
  }
  lines.push(
    "",
    "You are listed as an emergency contact.",
    "If you are concerned about their safety, please contact them directly.",
    "",
    "Crush Safety Team",
  );
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [params.to],
      subject,
      text: lines.join("\\n"),
      tags: [{ name: "purpose", value: "date_plan_created" }],
    }),
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Resend error: ${response.status} ${body}`);
  }
}

async function resolveUserByIdentifier(identifier: string): Promise<{
  uid?: string;
  emailLower?: string;
  email?: string;
  usernameLower?: string;
} | null> {
  const trimmed = identifier.trim();
  if (!trimmed) return null;

  if (isEmailLike(trimmed)) {
    const emailLower = normalizeEmail(trimmed);
    try {
      const user = await admin.auth().getUserByEmail(emailLower);
      return {
        uid: user.uid,
        emailLower,
        email: user.email ?? emailLower,
      };
    } catch (err) {
      return { emailLower, email: emailLower };
    }
  }

  const usernameLower = normalizeUsername(trimmed);
  const usernameDoc = await db.collection("usernames").doc(usernameLower).get();
  if (!usernameDoc.exists) {
    return { usernameLower };
  }
  const uid = usernameDoc.data()?.uid as string | undefined;
  if (!uid) return { usernameLower };
  const userDoc = await db.collection("users").doc(uid).get();
  const email = (userDoc.data()?.email as string | undefined) ?? undefined;
  const emailLower = email ? normalizeEmail(email) : undefined;
  return { uid, emailLower, email, usernameLower };
}

type EmailOtpPurpose =
  | "login"
  | "add_email"
  | "change_email"
  | "reset_password"
  | "new_device"
  | "sensitive_action";

const EMAIL_OTP_PURPOSES = new Set<EmailOtpPurpose>([
  "login",
  "add_email",
  "change_email",
  "reset_password",
  "new_device",
  "sensitive_action",
]);

interface EmailOtpRequest {
  identifier?: string;
  purpose?: EmailOtpPurpose;
  email?: string;
}

interface EmailOtpVerifyRequest {
  identifier?: string;
  purpose?: EmailOtpPurpose;
  otp?: string;
  newEmail?: string;
  newPassword?: string;
}

interface ClaimUsernameRequest {
  username?: string;
}

interface SignUpWithPasswordRequest {
  username?: string;
  email?: string;
  password?: string;
}

interface LoginWithPasswordRequest {
  identifier?: string;
  password?: string;
}

interface PasswordResetRequest {
  email?: string;
}

interface PasswordResetVerifyRequest {
  email?: string;
  otp?: string;
}

interface PasswordResetFinalizeRequest {
  email?: string;
  resetToken?: string;
  reset_token?: string;
  newPassword?: string;
  new_password?: string;
}

interface ChangePasswordRequest {
  currentPassword?: string;
  current_password?: string;
  newPassword?: string;
  new_password?: string;
}

function parseEmailOtpPurpose(value: unknown): EmailOtpPurpose {
  const purpose = typeof value === "string" ? value.trim() : "";
  if (!EMAIL_OTP_PURPOSES.has(purpose as EmailOtpPurpose)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid OTP purpose.",
    );
  }
  return purpose as EmailOtpPurpose;
}

function hashIdentifier(identifier: string): string {
  const otpSecret = getOtpSecretChecked();
  if (!otpSecret) {
    throw new functions.https.HttpsError(
      "internal",
      "OTP service not configured. Please contact support.",
    );
  }
  return crypto
    .createHmac("sha256", otpSecret)
    .update(`identifier:${identifier}`)
    .digest("hex");
}

function hashOtpValue(otp: string, salt: string): string {
  return hashWithSecret(otp, salt);
}

function isValidOtp(otp: string): boolean {
  return new RegExp(`^\\d{${OTP_DIGITS}}$`).test(otp);
}

/**
 * Find the matching, still-valid OTP among recent candidates using a
 * constant-time hash compare. Skips used/expired/locked candidates and records
 * a failed attempt on every non-matching candidate, locking that OTP once it
 * reaches OTP_VERIFY_MAX_ATTEMPTS to bound brute-force of a single code.
 *
 * Shared by email-OTP and password-reset-OTP verification so both paths get
 * identical timing-safe matching and lockout behavior.
 */
async function matchOtpCandidate(
  candidates: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>,
  otp: string,
): Promise<{
  matchedDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null;
  matchedData: FirebaseFirestore.DocumentData | undefined;
}> {
  const now = Date.now();
  let matchedDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null =
    null;
  let matchedData: FirebaseFirestore.DocumentData | undefined;
  for (const doc of candidates.docs) {
    const data = doc.data();
    const usedAt = toMillis(data.usedAt, 0);
    const expiresAt = toMillis(data.expiresAt, 0);
    const lockedUntil = toMillis(data.lockedUntil, 0);
    if (usedAt) continue;
    if (expiresAt && expiresAt < now) continue;
    if (lockedUntil && lockedUntil > now) continue;

    const computed = hashOtpValue(otp, data.otpSalt as string);
    if (timingSafeEqualHex(computed, data.otpHash as string)) {
      matchedDoc = doc;
      matchedData = data;
      break;
    }
    const failedAttempts = (data.failedAttempts as number | undefined) ?? 0;
    const nextAttempts = failedAttempts + 1;
    const updates: Record<string, unknown> = {
      failedAttempts: nextAttempts,
    };
    if (nextAttempts >= OTP_VERIFY_MAX_ATTEMPTS) {
      updates.lockedUntil = new Date(now + OTP_VERIFY_LOCK_MS);
    }
    await doc.ref.update(updates);
  }
  return { matchedDoc, matchedData };
}

function generateResetToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

function hashResetToken(token: string, salt: string): string {
  return hashWithSecret(token, salt);
}

let dummyPasswordHash: string | null = null;

async function getDummyPasswordHash(): Promise<string> {
  if (dummyPasswordHash) return dummyPasswordHash;
  dummyPasswordHash = await bcrypt.hash("dummy-password", PASSWORD_SALT_ROUNDS);
  return dummyPasswordHash;
}

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, PASSWORD_SALT_ROUNDS);
}

async function verifyPassword(
  password: string,
  hash: string,
): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

async function getPasswordHash(uid: string): Promise<string | undefined> {
  const snap = await db.collection("auth_credentials").doc(uid).get();
  if (!snap.exists) return undefined;
  const data = snap.data();
  return typeof data?.passwordHash === "string" ? data.passwordHash : undefined;
}

async function setPasswordHash(uid: string, password: string) {
  const passwordHash = await hashPassword(password);
  await db.collection("auth_credentials").doc(uid).set(
    {
      passwordHash,
      passwordUpdatedAt: serverTimestamp(),
    },
    { merge: true },
  );
}

async function ensureUserDoc(params: {
  uid: string;
  email?: string;
  phoneNumber?: string;
}) {
  const userRef = db.collection("users").doc(params.uid);
  const doc = await userRef.get();
  if (doc.exists) return;

  const emailLower = params.email ? normalizeEmail(params.email) : null;
  await userRef.set({
    phoneNumber: params.phoneNumber ?? "",
    email: params.email ?? null,
    emailLower,
    isEmailVerified: !!params.email,
    isPhoneVerified: !!params.phoneNumber,
    isIdVerified: false,
    plan: "free",
  });
}

export const requestEmailOtp = callable<EmailOtpRequest>(
  async (data, context) => {
    const identifierRaw = requireString(data?.identifier, "identifier");
    const purpose = parseEmailOtpPurpose(data?.purpose);
    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;
    const normalizedIdentifier = isEmailLike(identifierRaw)
      ? normalizeEmail(identifierRaw)
      : normalizeUsername(identifierRaw);
    const identifierHash = hashIdentifier(normalizedIdentifier);

    if (ip) {
      const ipLimit = await applyRateLimit(
        `otp:req:ip:${ip}`,
        OTP_REQUEST_LIMIT,
        OTP_REQUEST_WINDOW_MS,
        OTP_REQUEST_BLOCK_MS,
      );
      if (!ipLimit.allowed) {
        await logAuthAudit({
          action: "request_email_otp",
          status: "blocked",
          identifierHash,
          ip,
          userAgent,
          metadata: { purpose },
        });
        return { status: "ok" };
      }
    }

    const idLimit = await applyRateLimit(
      `otp:req:id:${identifierHash}`,
      OTP_REQUEST_LIMIT,
      OTP_REQUEST_WINDOW_MS,
      OTP_REQUEST_BLOCK_MS,
    );
    if (!idLimit.allowed) {
      await logAuthAudit({
        action: "request_email_otp",
        status: "blocked",
        identifierHash,
        ip,
        userAgent,
        metadata: { purpose },
      });
      return { status: "ok" };
    }

    const otp = generateOtp();
    const salt = crypto.randomBytes(16).toString("hex");
    const otpHash = hashOtpValue(otp, salt);
    const now = Date.now();

    let targetEmail: string | undefined;
    let resolvedUid: string | undefined;

    if (purpose === "add_email" || purpose === "change_email") {
      const uid = requireAuth(context, "update your email");
      const emailInput = data?.email ?? identifierRaw;
      if (!isEmailLike(emailInput)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Enter a valid email address.",
        );
      }
      targetEmail = normalizeEmail(emailInput);
      resolvedUid = uid;
      try {
        const existing = await admin.auth().getUserByEmail(targetEmail);
        if (existing.uid !== uid) {
          targetEmail = undefined;
        }
      } catch (_) {
        // Ignore: email does not exist yet.
      }
    } else {
      const resolved = await resolveUserByIdentifier(identifierRaw);
      resolvedUid = resolved?.uid;
      targetEmail = resolved?.emailLower;
      if (!targetEmail && isEmailLike(identifierRaw)) {
        targetEmail = normalizeEmail(identifierRaw);
      }

      if (purpose === "reset_password") {
        if (!resolvedUid) {
          targetEmail = undefined;
        } else {
          const hasPassword = await getPasswordHash(resolvedUid);
          if (!hasPassword) {
            targetEmail = undefined;
          }
        }
      }
    }

    await db.collection("auth_email_otps").add({
      identifierHash,
      uid: resolvedUid ?? null,
      purpose,
      otpHash,
      otpSalt: salt,
      failedAttempts: 0,
      usedAt: null,
      lockedUntil: null,
      createdAt: serverTimestamp(),
      expiresAt: new Date(now + OTP_TTL_MS),
    });

    if (targetEmail) {
      try {
        await sendOtpEmail({ to: targetEmail, otp, purpose });
        await logAuthAudit({
          action: "request_email_otp",
          status: "ok",
          identifierHash,
          uid: resolvedUid,
          ip,
          userAgent,
          metadata: { purpose },
        });
      } catch (err) {
        console.error("OTP email send failed", err);
        await logAuthAudit({
          action: "request_email_otp",
          status: "error",
          identifierHash,
          uid: resolvedUid,
          ip,
          userAgent,
          metadata: { purpose },
        });
      }
    } else {
      await logAuthAudit({
        action: "request_email_otp",
        status: "ok",
        identifierHash,
        uid: resolvedUid,
        ip,
        userAgent,
        metadata: { purpose, skippedSend: true },
      });
    }

    return { status: "ok" };
  },
);

export const verifyEmailOtp = callable<EmailOtpVerifyRequest>(
  async (data, context) => {
    const identifierRaw = requireString(data?.identifier, "identifier");
    const otp = requireString(data?.otp, "otp");
    const purpose = parseEmailOtpPurpose(data?.purpose);
    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;

    if (!isValidOtp(otp)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Enter the 6-digit code.",
      );
    }

    if (ip) {
      const ipLimit = await applyRateLimit(
        `otp:verify:ip:${ip}`,
        OTP_VERIFY_LIMIT,
        OTP_VERIFY_WINDOW_MS,
        OTP_VERIFY_BLOCK_MS,
      );
      if (!ipLimit.allowed) {
        await logAuthAudit({
          action: "verify_email_otp",
          status: "blocked",
          ip,
          userAgent,
          metadata: { purpose },
        });
        throwRateLimitError(ipLimit.retryAfterMs);
      }
    }

    const normalizedIdentifier = isEmailLike(identifierRaw)
      ? normalizeEmail(identifierRaw)
      : normalizeUsername(identifierRaw);
    const identifierHash = hashIdentifier(normalizedIdentifier);
    const idLimit = await applyRateLimit(
      `otp:verify:id:${identifierHash}`,
      OTP_VERIFY_LIMIT,
      OTP_VERIFY_WINDOW_MS,
      OTP_VERIFY_BLOCK_MS,
    );
    if (!idLimit.allowed) {
      await logAuthAudit({
        action: "verify_email_otp",
        status: "blocked",
        identifierHash,
        ip,
        userAgent,
        metadata: { purpose },
      });
      throwRateLimitError(idLimit.retryAfterMs);
    }

    const candidates = await db
      .collection("auth_email_otps")
      .where("identifierHash", "==", identifierHash)
      .where("purpose", "==", purpose)
      .orderBy("createdAt", "desc")
      .limit(5)
      .get();

    const { matchedDoc, matchedData } = await matchOtpCandidate(candidates, otp);

    if (!matchedDoc || !matchedData) {
      await logAuthAudit({
        action: "verify_email_otp",
        status: "invalid",
        identifierHash,
        ip,
        userAgent,
        metadata: { purpose },
      });
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Invalid or expired code.",
      );
    }

    await matchedDoc.ref.update({
      usedAt: serverTimestamp(),
    });

    if (purpose === "login") {
      const resolved = await resolveUserByIdentifier(identifierRaw);
      let uid = matchedData.uid as string | undefined;
      const emailLower = resolved?.emailLower ?? undefined;
      if (!uid && resolved?.uid) {
        uid = resolved.uid;
      }
      if (!uid && emailLower) {
        try {
          const existing = await admin.auth().getUserByEmail(emailLower);
          uid = existing.uid;
        } catch (_) {
          const created = await admin.auth().createUser({
            email: emailLower,
            emailVerified: true,
          });
          uid = created.uid;
        }
      }
      if (!uid) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Invalid or expired code.",
        );
      }
      await ensureUserDoc({ uid, email: emailLower });
      const customToken = await admin.auth().createCustomToken(uid);
      await logAuthAudit({
        action: "verify_email_otp",
        status: "ok",
        identifierHash,
        uid,
        ip,
        userAgent,
        metadata: { purpose },
      });
      return { status: "ok", customToken };
    }

    if (purpose === "add_email" || purpose === "change_email") {
      const uid = requireAuth(context, "verify your email");
      const newEmailRaw = data?.newEmail ?? identifierRaw;
      if (!isEmailLike(newEmailRaw)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Enter a valid email address.",
        );
      }
      const newEmail = normalizeEmail(newEmailRaw);
      try {
        const existing = await admin.auth().getUserByEmail(newEmail);
        if (existing.uid !== uid) {
          throw new Error("email_in_use");
        }
      } catch (err) {
        if (err instanceof Error && err.message === "email_in_use") {
          await logAuthAudit({
            action: "verify_email_otp",
            status: "invalid",
            identifierHash,
            uid,
            ip,
            userAgent,
            metadata: { purpose },
          });
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Could not verify email. Try again.",
          );
        }
      }

      await admin.auth().updateUser(uid, {
        email: newEmail,
        emailVerified: true,
      });
      await db.collection("users").doc(uid).set(
        {
          email: newEmail,
          emailLower: newEmail,
          isEmailVerified: true,
        },
        { merge: true },
      );
      await logAuthAudit({
        action: "verify_email_otp",
        status: "ok",
        identifierHash,
        uid,
        ip,
        userAgent,
        metadata: { purpose },
      });
      return { status: "ok" };
    }

    if (purpose === "reset_password") {
      const newPassword = data?.newPassword ?? "";
      if (newPassword.length < PASSWORD_MIN_LENGTH) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `Use at least ${PASSWORD_MIN_LENGTH} characters.`,
        );
      }
      const resolved = await resolveUserByIdentifier(identifierRaw);
      const uid = resolved?.uid;
      const userEmail = resolved?.emailLower || resolved?.email;
      if (uid) {
        await setPasswordHash(uid, newPassword);
        // Send password changed email notification
        if (userEmail) {
          sendPasswordChangedEmail({
            to: userEmail,
            method: "forgot_password",
          }).catch((err) =>
            console.error("Failed to send password changed email:", err),
          );
        }
      }
      await logAuthAudit({
        action: "verify_email_otp",
        status: uid ? "ok" : "invalid",
        identifierHash,
        uid,
        ip,
        userAgent,
        metadata: { purpose },
      });
      return { status: "ok" };
    }

    await logAuthAudit({
      action: "verify_email_otp",
      status: "ok",
      identifierHash,
      ip,
      userAgent,
      metadata: { purpose },
    });
    return { status: "ok" };
  },
);

export const claimUsername = callable<ClaimUsernameRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "claim a username");
    const usernameRaw = requireString(data?.username, "username");
    const trimmed = usernameRaw.trim();
    if (!USERNAME_REGEX.test(trimmed)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Username must be 3-20 characters and use letters, numbers, or underscores.",
      );
    }
    const usernameLower = normalizeUsername(trimmed);
    const usernameRef = db.collection("usernames").doc(usernameLower);
    const userRef = db.collection("users").doc(uid);

    await db.runTransaction(async (tx) => {
      const nameSnap = await tx.get(usernameRef);
      if (nameSnap.exists) {
        const existingUid = nameSnap.data()?.uid;
        if (existingUid && existingUid !== uid) {
          throw new functions.https.HttpsError(
            "already-exists",
            "That username is taken.",
          );
        }
      }
      tx.set(
        usernameRef,
        {
          uid,
          createdAt: serverTimestamp(),
        },
        { merge: true },
      );
      tx.set(
        userRef,
        {
          username: trimmed,
          usernameLower,
        },
        { merge: true },
      );
    });

    await logAuthAudit({
      action: "claim_username",
      status: "ok",
      uid,
      metadata: { username: usernameLower },
    });

    return { status: "ok", username: trimmed };
  },
);

async function signUpWithPasswordCore(params: {
  usernameRaw: string;
  emailRaw: string;
  passwordRaw: string;
  ip?: string;
  userAgent?: string;
}): Promise<{
  uid: string;
  emailLower: string;
  usernameLower: string;
  customToken: string;
}> {
  const username = params.usernameRaw.trim();
  const email = normalizeEmail(params.emailRaw);
  const passwordRaw = params.passwordRaw;
  const ip = params.ip;
  const userAgent = params.userAgent;

  if (!USERNAME_REGEX.test(username)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Username must be 3-20 characters and use letters, numbers, or underscores.",
    );
  }
  if (!isEmailLike(email)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Enter a valid email address.",
    );
  }
  const passwordError = validatePasswordStrength(passwordRaw);
  if (passwordError) {
    throw new functions.https.HttpsError("invalid-argument", passwordError);
  }

  const usernameLower = normalizeUsername(username);
  const emailLower = normalizeEmail(email);
  const emailHash = hashIdentifier(emailLower);
  const usernameHash = hashIdentifier(usernameLower);

  if (ip) {
    const ipLimit = await applyRateLimit(
      `signup:ip:${ip}`,
      SIGNUP_ATTEMPT_LIMIT,
      SIGNUP_ATTEMPT_WINDOW_MS,
      SIGNUP_ATTEMPT_BLOCK_MS,
    );
    if (!ipLimit.allowed) {
      await logAuthAudit({
        action: "signup_password",
        status: "blocked",
        identifierHash: emailHash,
        ip,
        userAgent,
        metadata: { username: usernameLower },
      });
      throwRateLimitError(ipLimit.retryAfterMs);
    }
  }

  const emailLimit = await applyRateLimit(
    `signup:id:${emailHash}`,
    SIGNUP_ATTEMPT_LIMIT,
    SIGNUP_ATTEMPT_WINDOW_MS,
    SIGNUP_ATTEMPT_BLOCK_MS,
  );
  const usernameLimit = await applyRateLimit(
    `signup:username:${usernameHash}`,
    SIGNUP_ATTEMPT_LIMIT,
    SIGNUP_ATTEMPT_WINDOW_MS,
    SIGNUP_ATTEMPT_BLOCK_MS,
  );
  if (!emailLimit.allowed || !usernameLimit.allowed) {
    await logAuthAudit({
      action: "signup_password",
      status: "blocked",
      identifierHash: emailHash,
      ip,
      userAgent,
      metadata: { username: usernameLower },
    });
    const retryMs = emailLimit.retryAfterMs || usernameLimit.retryAfterMs;
    throwRateLimitError(retryMs);
  }

  let emailInUse = false;
  try {
    await admin.auth().getUserByEmail(emailLower);
    emailInUse = true;
  } catch (_) {
    // Ignore: email is available.
  }

  const usernameRef = db.collection("usernames").doc(usernameLower);
  const usernameSnap = await usernameRef.get();
  const usernameInUse = usernameSnap.exists;

  if (emailInUse || usernameInUse) {
    await logAuthAudit({
      action: "signup_password",
      status: "invalid",
      identifierHash: emailHash,
      ip,
      userAgent,
      metadata: { username: usernameLower },
    });
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Could not create account. Check your details and try again.",
    );
  }

  let createdUid: string | undefined;
  try {
    const created = await admin.auth().createUser({
      email: emailLower,
      emailVerified: false,
    });
    createdUid = created.uid;
    const uid = createdUid; // Capture for closure

    await db.runTransaction(async (tx) => {
      const nameSnap = await tx.get(usernameRef);
      if (nameSnap.exists) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Username is not available.",
        );
      }
      tx.set(usernameRef, {
        uid: uid,
        createdAt: serverTimestamp(),
      });
      tx.set(db.collection("users").doc(uid), {
        username,
        usernameLower,
        email: emailLower,
        emailLower,
        isEmailVerified: false,
        phoneNumber: "",
        isPhoneVerified: false,
        isIdVerified: false,
        plan: "free",
      });
    });

    await setPasswordHash(createdUid, passwordRaw);

    const otp = generateOtp();
    const salt = crypto.randomBytes(16).toString("hex");
    const otpHash = hashOtpValue(otp, salt);
    const now = Date.now();

    await db.collection("auth_email_otps").add({
      identifierHash: emailHash,
      uid: createdUid,
      emailLower,
      purpose: "add_email",
      flow: SIGNUP_EMAIL_FLOW,
      otpHash,
      otpSalt: salt,
      failedAttempts: 0,
      usedAt: null,
      lockedUntil: null,
      createdAt: serverTimestamp(),
      expiresAt: new Date(now + OTP_TTL_MS),
    });

    try {
      await sendOtpEmail({ to: emailLower, otp, purpose: "signup" });
      await logAuthAudit({
        action: "signup_email_otp",
        status: "ok",
        uid: createdUid,
        identifierHash: emailHash,
        ip,
        userAgent,
        metadata: { username: usernameLower },
      });
    } catch (err) {
      console.error("Signup OTP email failed", err);
      await logAuthAudit({
        action: "signup_email_otp",
        status: "error",
        uid: createdUid,
        identifierHash: emailHash,
        ip,
        userAgent,
        metadata: { username: usernameLower },
      });
    }

    const customToken = await admin.auth().createCustomToken(createdUid);
    await logAuthAudit({
      action: "signup_password",
      status: "ok",
      uid: createdUid,
      identifierHash: emailHash,
      ip,
      userAgent,
      metadata: { username: usernameLower },
    });
    return {
      uid: createdUid,
      emailLower,
      usernameLower,
      customToken,
    };
  } catch (err) {
    const authError = toAuthHttpsError(err);
    if (authError) {
      throw authError;
    }
    if (createdUid) {
      try {
        await admin.auth().deleteUser(createdUid);
        const userRef = db.collection("users").doc(createdUid);
        const credRef = db.collection("auth_credentials").doc(createdUid);
        await Promise.all([userRef.delete(), credRef.delete()]);
        const nameSnap = await usernameRef.get();
        if (nameSnap.exists && nameSnap.data()?.uid === createdUid) {
          await usernameRef.delete();
        }
      } catch (cleanupErr) {
        console.error("Signup cleanup failed", cleanupErr);
      }
    }
    if (isHttpsError(err)) {
      throw err;
    }
    console.error("Signup error", err);
    throw new functions.https.HttpsError(
      "internal",
      "Could not create account. Please try again.",
    );
  }
}

const FORGOT_PASSWORD_RESPONSE = {
  status: "ok",
  message: "If the email is registered, a verification code will be sent.",
};

async function requestPasswordResetCore(params: {
  emailRaw: string;
  ip?: string;
  userAgent?: string;
}) {
  const emailRaw = params.emailRaw.trim();
  const ip = params.ip;
  const userAgent = params.userAgent;

  if (!emailRaw || !isEmailLike(emailRaw)) {
    return FORGOT_PASSWORD_RESPONSE;
  }

  const email = normalizeEmail(emailRaw);
  const identifierHash = hashIdentifier(email);
  const ipLimit = ip
    ? await applyRateLimit(
        `otp:req:ip:${ip}`,
        OTP_REQUEST_LIMIT,
        OTP_REQUEST_WINDOW_MS,
        OTP_REQUEST_BLOCK_MS,
      )
    : { allowed: true };
  const idLimit = await applyRateLimit(
    `otp:req:id:${identifierHash}`,
    OTP_REQUEST_LIMIT,
    OTP_REQUEST_WINDOW_MS,
    OTP_REQUEST_BLOCK_MS,
  );

  if (!ipLimit.allowed || !idLimit.allowed) {
    await logAuthAudit({
      action: "forgot_password_request",
      status: "blocked",
      identifierHash,
      ip,
      userAgent,
    });
    return FORGOT_PASSWORD_RESPONSE;
  }

  const recent = await db
    .collection("auth_email_otps")
    .where("identifierHash", "==", identifierHash)
    .where("purpose", "==", "forgot_password")
    .orderBy("createdAt", "desc")
    .limit(1)
    .get();
  if (!recent.empty) {
    const data = recent.docs[0].data();
    const createdAt = toMillis(data.createdAt, 0);
    if (createdAt && Date.now() - createdAt < OTP_RESEND_COOLDOWN_MS) {
      await logAuthAudit({
        action: "forgot_password_request",
        status: "blocked",
        identifierHash,
        ip,
        userAgent,
        metadata: { cooldown: true },
      });
      return FORGOT_PASSWORD_RESPONSE;
    }
  }

  let userRecord: admin.auth.UserRecord | null = null;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (_) {
    userRecord = null;
  }

  if (!userRecord || !userRecord.emailVerified) {
    await logAuthAudit({
      action: "forgot_password_request",
      status: "ok",
      identifierHash,
      ip,
      userAgent,
      metadata: { skippedSend: true },
    });
    return FORGOT_PASSWORD_RESPONSE;
  }

  const passwordHash = await getPasswordHash(userRecord.uid);
  if (!passwordHash) {
    await logAuthAudit({
      action: "forgot_password_request",
      status: "ok",
      identifierHash,
      ip,
      userAgent,
      metadata: { skippedSend: true, noPassword: true },
    });
    return FORGOT_PASSWORD_RESPONSE;
  }

  const otp = generateOtp();
  const salt = crypto.randomBytes(16).toString("hex");
  const otpHash = hashOtpValue(otp, salt);
  const now = Date.now();

  await db.collection("auth_email_otps").add({
    identifierHash,
    uid: userRecord.uid,
    emailLower: email,
    purpose: "forgot_password",
    otpHash,
    otpSalt: salt,
    failedAttempts: 0,
    usedAt: null,
    lockedUntil: null,
    createdAt: serverTimestamp(),
    expiresAt: new Date(now + OTP_TTL_MS),
  });

  try {
    await sendOtpEmail({ to: email, otp, purpose: "forgot_password" });
    await logAuthAudit({
      action: "forgot_password_request",
      status: "ok",
      identifierHash,
      uid: userRecord.uid,
      ip,
      userAgent,
    });
  } catch (err) {
    console.error("Forgot password email failed", err);
    await logAuthAudit({
      action: "forgot_password_request",
      status: "error",
      identifierHash,
      uid: userRecord.uid,
      ip,
      userAgent,
    });
  }

  return FORGOT_PASSWORD_RESPONSE;
}

async function verifyPasswordResetOtpCore(params: {
  emailRaw: string;
  otpRaw: string;
  ip?: string;
  userAgent?: string;
}): Promise<string> {
  const emailRaw = params.emailRaw.trim();
  const otpRaw = params.otpRaw.trim();
  const ip = params.ip;
  const userAgent = params.userAgent;

  if (!emailRaw || !isEmailLike(emailRaw) || !isValidOtp(otpRaw)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid or expired code.",
    );
  }

  const email = normalizeEmail(emailRaw);
  const identifierHash = hashIdentifier(email);
  const ipLimit = ip
    ? await applyRateLimit(
        `otp:verify:ip:${ip}`,
        OTP_VERIFY_LIMIT,
        OTP_VERIFY_WINDOW_MS,
        OTP_VERIFY_BLOCK_MS,
      )
    : { allowed: true };
  const idLimit = await applyRateLimit(
    `otp:verify:id:${identifierHash}`,
    OTP_VERIFY_LIMIT,
    OTP_VERIFY_WINDOW_MS,
    OTP_VERIFY_BLOCK_MS,
  );

  if (!ipLimit.allowed || !idLimit.allowed) {
    await logAuthAudit({
      action: "forgot_password_verify",
      status: "blocked",
      identifierHash,
      ip,
      userAgent,
    });
    const retryMs = ipLimit.retryAfterMs || idLimit.retryAfterMs;
    throwRateLimitError(retryMs);
  }

  const candidates = await db
    .collection("auth_email_otps")
    .where("identifierHash", "==", identifierHash)
    .where("purpose", "==", "forgot_password")
    .orderBy("createdAt", "desc")
    .limit(5)
    .get();

  const { matchedDoc, matchedData } = await matchOtpCandidate(
    candidates,
    otpRaw,
  );

  if (!matchedDoc || !matchedData) {
    await logAuthAudit({
      action: "forgot_password_verify",
      status: "invalid",
      identifierHash,
      ip,
      userAgent,
    });
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid or expired code.",
    );
  }

  await matchedDoc.ref.update({
    usedAt: serverTimestamp(),
  });

  const resetToken = generateResetToken();
  const resetSalt = crypto.randomBytes(16).toString("hex");
  const resetHash = hashResetToken(resetToken, resetSalt);
  const uid = matchedData.uid as string | undefined;

  await db.collection("auth_password_resets").add({
    identifierHash,
    uid: uid ?? null,
    emailLower: email,
    resetTokenHash: resetHash,
    resetTokenSalt: resetSalt,
    usedAt: null,
    createdAt: serverTimestamp(),
    expiresAt: new Date(Date.now() + RESET_TOKEN_TTL_MS),
  });

  await logAuthAudit({
    action: "forgot_password_verify",
    status: "ok",
    identifierHash,
    uid,
    ip,
    userAgent,
  });

  return resetToken;
}

async function resetPasswordWithTokenCore(params: {
  emailRaw: string;
  resetToken: string;
  newPassword: string;
  ip?: string;
  userAgent?: string;
}): Promise<void> {
  const emailRaw = params.emailRaw.trim();
  const resetToken = params.resetToken.trim();
  const newPassword = params.newPassword;
  const ip = params.ip;
  const userAgent = params.userAgent;

  if (!emailRaw || !isEmailLike(emailRaw) || !resetToken) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid reset request.",
    );
  }

  const passwordError = validatePasswordStrength(newPassword);
  if (passwordError) {
    throw new functions.https.HttpsError("invalid-argument", passwordError);
  }

  const email = normalizeEmail(emailRaw);
  const identifierHash = hashIdentifier(email);
  const ipLimit = ip
    ? await applyRateLimit(
        `reset:ip:${ip}`,
        RESET_ATTEMPT_LIMIT,
        RESET_ATTEMPT_WINDOW_MS,
        RESET_ATTEMPT_BLOCK_MS,
      )
    : { allowed: true };
  const idLimit = await applyRateLimit(
    `reset:id:${identifierHash}`,
    RESET_ATTEMPT_LIMIT,
    RESET_ATTEMPT_WINDOW_MS,
    RESET_ATTEMPT_BLOCK_MS,
  );

  if (!ipLimit.allowed || !idLimit.allowed) {
    await logAuthAudit({
      action: "forgot_password_reset",
      status: "blocked",
      identifierHash,
      ip,
      userAgent,
    });
    const retryMs = ipLimit.retryAfterMs || idLimit.retryAfterMs;
    throwRateLimitError(retryMs);
  }

  const candidates = await db
    .collection("auth_password_resets")
    .where("identifierHash", "==", identifierHash)
    .orderBy("createdAt", "desc")
    .limit(5)
    .get();

  const now = Date.now();
  let matchedDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null =
    null;
  let matchedData: FirebaseFirestore.DocumentData | undefined;
  for (const doc of candidates.docs) {
    const data = doc.data();
    const usedAt = toMillis(data.usedAt, 0);
    const expiresAt = toMillis(data.expiresAt, 0);
    if (usedAt) continue;
    if (expiresAt && expiresAt < now) continue;

    const computed = hashResetToken(resetToken, data.resetTokenSalt as string);
    if (timingSafeEqualHex(computed, data.resetTokenHash as string)) {
      matchedDoc = doc;
      matchedData = data;
      break;
    }
  }

  if (!matchedDoc || !matchedData) {
    await logAuthAudit({
      action: "forgot_password_reset",
      status: "invalid",
      identifierHash,
      ip,
      userAgent,
    });
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid reset request.",
    );
  }

  const uid = matchedData.uid as string | undefined;
  if (uid) {
    await setPasswordHash(uid, newPassword);
    await admin.auth().revokeRefreshTokens(uid);
    // Send password changed email notification
    sendPasswordChangedEmail({
      to: email,
      method: "forgot_password",
    }).catch((err) =>
      console.error("Failed to send password changed email:", err),
    );
  }

  await matchedDoc.ref.update({
    usedAt: serverTimestamp(),
  });

  await logAuthAudit({
    action: "forgot_password_reset",
    status: "ok",
    identifierHash,
    uid,
    ip,
    userAgent,
  });
}

export const signUpWithPassword = callable<SignUpWithPasswordRequest>(
  async (data, context) => {
    const usernameRaw = requireString(data?.username, "username");
    const emailRaw = requireString(data?.email, "email");
    const passwordRaw = requireString(data?.password, "password");
    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;
    const result = await signUpWithPasswordCore({
      usernameRaw,
      emailRaw,
      passwordRaw,
      ip,
      userAgent,
    });
    return { status: "ok", customToken: result.customToken };
  },
);

async function loginWithPasswordCore(params: {
  identifier: string;
  password: string;
  ip?: string;
  userAgent?: string;
}) {
  const identifierRaw = params.identifier.trim();
  const password = params.password;
  const ip = params.ip;
  const userAgent = params.userAgent;

  const normalizedIdentifier = isEmailLike(identifierRaw)
    ? normalizeEmail(identifierRaw)
    : normalizeUsername(identifierRaw);
  const identifierHash = hashIdentifier(normalizedIdentifier);

  if (ip) {
    const ipLimit = await applyRateLimit(
      `login:ip:${ip}`,
      LOGIN_ATTEMPT_LIMIT,
      LOGIN_ATTEMPT_WINDOW_MS,
      LOGIN_ATTEMPT_BLOCK_MS,
    );
    if (!ipLimit.allowed) {
      await logAuthAudit({
        action: "login_password",
        status: "blocked",
        identifierHash,
        ip,
        userAgent,
      });
      throwRateLimitError(ipLimit.retryAfterMs);
    }
  }

  const idLimit = await applyRateLimit(
    `login:id:${identifierHash}`,
    LOGIN_ATTEMPT_LIMIT,
    LOGIN_ATTEMPT_WINDOW_MS,
    LOGIN_ATTEMPT_BLOCK_MS,
  );
  if (!idLimit.allowed) {
    await logAuthAudit({
      action: "login_password",
      status: "blocked",
      identifierHash,
      ip,
      userAgent,
    });
    throwRateLimitError(idLimit.retryAfterMs);
  }

  const resolved = await resolveUserByIdentifier(identifierRaw);
  const uid = resolved?.uid;
  const passwordHash = uid ? await getPasswordHash(uid) : undefined;
  const dummyHash = await getDummyPasswordHash();
  const hashToCheck = passwordHash ?? dummyHash;
  const isValid = await verifyPassword(password, hashToCheck);

  if (!uid || !passwordHash || !isValid) {
    await logAuthAudit({
      action: "login_password",
      status: "invalid",
      identifierHash,
      uid,
      ip,
      userAgent,
    });
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Invalid credentials.",
    );
  }

  const customToken = await admin.auth().createCustomToken(uid);
  await logAuthAudit({
    action: "login_password",
    status: "ok",
    identifierHash,
    uid,
    ip,
    userAgent,
  });
  return { status: "ok", customToken };
}

export const loginWithPassword = callable<LoginWithPasswordRequest>(
  async (data, context) => {
    const identifierRaw = requireString(data?.identifier, "identifier");
    const password = requireString(data?.password, "password");
    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;
    return loginWithPasswordCore({
      identifier: identifierRaw,
      password,
      ip,
      userAgent,
    });
  },
);

export const requestPasswordReset = callable<PasswordResetRequest>(
  async (data, context) => {
    const emailRaw = typeof data?.email === "string" ? data.email.trim() : "";
    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;
    return requestPasswordResetCore({
      emailRaw,
      ip,
      userAgent,
    });
  },
);

export const verifyPasswordResetOtp = callable<PasswordResetVerifyRequest>(
  async (data, context) => {
    const emailRaw = typeof data?.email === "string" ? data.email.trim() : "";
    const otpRaw = typeof data?.otp === "string" ? data.otp.trim() : "";
    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;
    const resetToken = await verifyPasswordResetOtpCore({
      emailRaw,
      otpRaw,
      ip,
      userAgent,
    });
    return { status: "ok", resetToken };
  },
);

export const resetPasswordWithToken = callable<PasswordResetFinalizeRequest>(
  async (data, context) => {
    const emailRaw = typeof data?.email === "string" ? data.email.trim() : "";
    const resetToken =
      typeof data?.resetToken === "string"
        ? data.resetToken.trim()
        : typeof data?.reset_token === "string"
          ? data.reset_token.trim()
          : "";
    const newPassword =
      typeof data?.newPassword === "string"
        ? data.newPassword
        : typeof data?.new_password === "string"
          ? data.new_password
          : "";
    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;
    await resetPasswordWithTokenCore({
      emailRaw,
      resetToken,
      newPassword,
      ip,
      userAgent,
    });
    return { status: "ok" };
  },
);

export const changePassword = callable<ChangePasswordRequest>(
  async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to change your password.",
      );
    }

    const currentPassword =
      typeof data?.currentPassword === "string"
        ? data.currentPassword
        : typeof data?.current_password === "string"
          ? data.current_password
          : "";
    const newPassword =
      typeof data?.newPassword === "string"
        ? data.newPassword
        : typeof data?.new_password === "string"
          ? data.new_password
          : "";

    if (!currentPassword) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Current password is required.",
      );
    }

    const passwordError = validatePasswordStrength(newPassword);
    if (passwordError) {
      throw new functions.https.HttpsError("invalid-argument", passwordError);
    }

    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;

    // Rate limiting
    const ipLimit = ip
      ? await applyRateLimit(
          `change_password:ip:${ip}`,
          LOGIN_ATTEMPT_LIMIT,
          LOGIN_ATTEMPT_WINDOW_MS,
          LOGIN_ATTEMPT_BLOCK_MS,
        )
      : { allowed: true };
    const idLimit = await applyRateLimit(
      `change_password:uid:${uid}`,
      LOGIN_ATTEMPT_LIMIT,
      LOGIN_ATTEMPT_WINDOW_MS,
      LOGIN_ATTEMPT_BLOCK_MS,
    );

    if (!ipLimit.allowed || !idLimit.allowed) {
      await logAuthAudit({
        action: "change_password",
        status: "blocked",
        uid,
        ip,
        userAgent,
      });
      const retryMs = ipLimit.retryAfterMs || idLimit.retryAfterMs;
      throwRateLimitError(retryMs);
    }

    // Verify current password
    const passwordHash = await getPasswordHash(uid);
    if (!passwordHash) {
      await logAuthAudit({
        action: "change_password",
        status: "error",
        uid,
        ip,
        userAgent,
        metadata: { reason: "no_password_set" },
      });
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No password set for this account.",
      );
    }

    const isValid = await verifyPassword(currentPassword, passwordHash);
    if (!isValid) {
      await logAuthAudit({
        action: "change_password",
        status: "invalid",
        uid,
        ip,
        userAgent,
      });
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Current password is incorrect.",
      );
    }

    // Set new password
    await setPasswordHash(uid, newPassword);

    // Revoke existing sessions
    await admin.auth().revokeRefreshTokens(uid);

    // Get user's email for notification
    const userDoc = await db.collection("users").doc(uid).get();
    const userEmail =
      userDoc.data()?.emailLower || userDoc.data()?.email || null;

    // Send password changed email notification
    if (userEmail) {
      sendPasswordChangedEmail({
        to: userEmail,
        method: "in_app",
      }).catch((err) =>
        console.error("Failed to send password changed email:", err),
      );
    }

    await logAuthAudit({
      action: "change_password",
      status: "ok",
      uid,
      ip,
      userAgent,
    });

    return { status: "ok" };
  },
);

type ProfileData = {
  name?: string;
  lastName?: string;
  bio?: unknown;
  birthDate?: unknown;
  dateOfBirth?: unknown; // Legacy fallback
  photoUrls?: unknown;
  prompts?: unknown;
  profilePrompts?: unknown; // Canonical structured prompts
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
  cursor?: string;
  minAge?: number;
  maxAge?: number;
  maxDistanceKm?: number;
  showMeGenders?: string[];
  interests?: string[];
  requirePhotos?: boolean;
  requireVerified?: boolean;
  latitude?: number;
  longitude?: number;
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

type ProfileCompletenessSummary = {
  score: number;
  breakdown: Record<string, number>;
  missing: string[];
  requiredMissing: string[];
  recommended: string[];
  meetsSwipeMinimum: boolean;
  meetsMessagingMinimum: boolean;
  meetsRequiredFields: boolean;
};

const SWIPE_MIN_COMPLETENESS = 0.8;
const MESSAGING_MIN_COMPLETENESS = 0.8;
const PROFILE_RECOMMENDED_PROMPTS = 2;

function evaluateProfileCompleteness(
  profile: ProfileData | null,
): ProfileCompletenessSummary {
  if (!profile) {
    const requiredMissing = [
      `Add at least ${PROFILE_MIN_PHOTOS} photo.`,
      `Write a bio with at least ${PROFILE_MIN_BIO_LENGTH} characters.`,
      "Add your city and country.",
    ];
    return {
      score: 0,
      breakdown: {},
      missing: [
        ...requiredMissing,
        `Add at least ${PROFILE_MIN_INTERESTS} interests.`,
        "Add work or school.",
      ],
      requiredMissing,
      recommended: ["Answer prompts to stand out."],
      meetsSwipeMinimum: false,
      meetsMessagingMinimum: false,
      meetsRequiredFields: false,
    };
  }

  const normalizedProfile = profile as unknown as Record<string, unknown>;
  const photos = toStringArray(profile.photoUrls);
  const prompts = profilePromptAnswers(normalizedProfile);
  const interests = toStringArray(profile.interests);
  const bio = typeof profile.bio === "string" ? profile.bio.trim() : "";
  const country =
    typeof profile.country === "string" ? profile.country.trim() : "";
  const city = typeof profile.city === "string" ? profile.city.trim() : "";
  const jobTitle =
    typeof profile.jobTitle === "string" ? profile.jobTitle.trim() : "";
  const company =
    typeof profile.company === "string" ? profile.company.trim() : "";
  const school =
    typeof profile.school === "string" ? profile.school.trim() : "";
  const hasWorkOrSchool = Boolean(jobTitle || company || school);

  const breakdown: Record<string, number> = {};
  const missing: string[] = [];
  const requiredMissing: string[] = [];
  const recommended: string[] = [];

  // Required core fields.
  const photosScore = Math.min(1, photos.length / PROFILE_MIN_PHOTOS);
  breakdown.photos = photosScore * 0.35;
  if (photos.length < PROFILE_MIN_PHOTOS) {
    const msg = `Add at least ${PROFILE_MIN_PHOTOS} photo.`;
    missing.push(msg);
    requiredMissing.push(msg);
  }

  const bioScore = Math.min(1, bio.length / PROFILE_MIN_BIO_LENGTH);
  breakdown.bio = bioScore * 0.25;
  if (bio.length < PROFILE_MIN_BIO_LENGTH) {
    const msg = `Write a bio with at least ${PROFILE_MIN_BIO_LENGTH} characters.`;
    missing.push(msg);
    requiredMissing.push(msg);
  }

  const hasLocation = country.length > 0 && city.length > 0;
  breakdown.location = hasLocation ? 0.1 : 0;
  if (!hasLocation) {
    const msg = "Add your city and country.";
    missing.push(msg);
    requiredMissing.push(msg);
  }

  // Optional quality boosts.
  const interestsScore = Math.min(1, interests.length / PROFILE_MIN_INTERESTS);
  breakdown.interests = interestsScore * 0.1;
  if (interests.length < PROFILE_MIN_INTERESTS) {
    missing.push(`Add at least ${PROFILE_MIN_INTERESTS} interests.`);
  }

  breakdown.workEducation = hasWorkOrSchool ? 0.1 : 0;
  if (!hasWorkOrSchool) {
    missing.push("Add work or school.");
  }

  const promptsScore = Math.min(
    1,
    prompts.length / PROFILE_RECOMMENDED_PROMPTS,
  );
  breakdown.prompts = promptsScore * 0.1;
  if (prompts.length < PROFILE_RECOMMENDED_PROMPTS) {
    recommended.push("Answer prompts to stand out.");
  }

  const rawScore = Object.values(breakdown).reduce(
    (acc, value) => acc + value,
    0,
  );
  const score = Math.round(rawScore * 1000) / 1000;
  const meetsRequiredFields = requiredMissing.length === 0;
  const meetsSwipeMinimum = score >= SWIPE_MIN_COMPLETENESS;
  const meetsMessagingMinimum = score >= MESSAGING_MIN_COMPLETENESS;

  return {
    score,
    breakdown,
    missing,
    requiredMissing,
    recommended,
    meetsSwipeMinimum,
    meetsMessagingMinimum,
    meetsRequiredFields,
  };
}

function ensureProfileQuality(profile: ProfileData | null, action: string) {
  const normalizedProfile = (profile ?? {}) as Record<string, unknown>;
  const photos = toStringArray(profile?.photoUrls);
  const prompts = profilePromptAnswers(normalizedProfile);
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
      `Write a bio with at least ${PROFILE_MIN_BIO_LENGTH} characters.`,
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
      `Complete your profile before ${action}: ${missing.join(" ")}`,
    );
  }
}

// Helpers
async function getUser(uid: string): Promise<UserDoc> {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "User document not found.",
    );
  }
  const data = snap.data() || {};
  return { id: snap.id, ...data } as UserDoc;
}

async function setUserPlan(
  uid: string,
  plan: "free" | "plus",
  extra?: { stripeCustomerId?: string; stripeSubscriptionId?: string },
) {
  const payload: Record<string, unknown> = { plan };
  if (extra?.stripeCustomerId)
    payload.stripeCustomerId = extra.stripeCustomerId;
  if (extra?.stripeSubscriptionId) {
    payload.stripeSubscriptionId = extra.stripeSubscriptionId;
  }

  // Update Firestore
  await db.collection("users").doc(uid).set(payload, { merge: true });

  // Sync premium status to RTDB for real-time feature access control
  // Premium users get: presence visibility, typing indicators, read receipts, last seen
  const isPremium = plan === "plus";
  await rtdb.ref(`premium_users/${uid}`).set(isPremium ? true : null);
}

const ANDROID_PUBLISHER_SCOPE =
  "https://www.googleapis.com/auth/androidpublisher";

function normalizeGooglePlayPackageName(
  packageName: string | null | undefined,
): string | null {
  const normalized = packageName?.trim();
  return normalized ? normalized : null;
}

function normalizePurchaseValidationPlatform(
  platform: string | null | undefined,
): PurchaseValidationProvider | null {
  const normalized = optionalString(platform)?.toLowerCase();
  switch (normalized) {
    case "android":
    case "google":
    case "google_play":
    case "play":
      return "google_play";
    case "ios":
    case "apple":
    case "app_store":
    case "appstore":
      return "app_store";
    default:
      return null;
  }
}

function hashPurchaseToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}

const APPLE_SERVER_AUDIENCE = "appstoreconnect-v1";
const APPLE_SERVER_BASE_URL = "https://api.storekit.itunes.apple.com";
const APPLE_SERVER_SANDBOX_BASE_URL =
  "https://api.storekit-sandbox.itunes.apple.com";

function normalizeApplePrivateKey(
  value: string | null | undefined,
): string | null {
  const normalized = value?.trim();
  if (!normalized) return null;
  return normalized.includes("\\n")
    ? normalized.replace(/\\n/g, "\n")
    : normalized;
}

function normalizeAppleServerEnvironment(
  value: string | undefined,
): AppleServerEnvironment | null {
  const normalized = value?.trim().toUpperCase();
  if (normalized === "PRODUCTION") return "PRODUCTION";
  if (normalized === "SANDBOX") return "SANDBOX";
  return null;
}

function getAppleServerApiConfig(): AppleServerApiConfig {
  const issuerId = optionalString(getAppleIssuerId());
  const keyId = optionalString(getAppleKeyId());
  const privateKey = normalizeApplePrivateKey(getApplePrivateKey());
  const bundleId = optionalString(getAppleBundleId());

  if (!issuerId || !keyId || !privateKey || !bundleId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Apple server API credentials are not fully configured.",
    );
  }

  return { issuerId, keyId, privateKey, bundleId };
}

function base64UrlEncode(value: Buffer | string): string {
  const buffer = Buffer.isBuffer(value) ? value : Buffer.from(value, "utf8");
  return buffer
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function base64UrlDecode(value: string): Buffer {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padding = normalized.length % 4;
  const padded =
    padding === 0 ? normalized : normalized + "=".repeat(4 - padding);
  return Buffer.from(padded, "base64");
}

function createAppleServerAuthToken(
  config: AppleServerApiConfig,
  nowMs = Date.now(),
): string {
  const issuedAt = Math.floor(nowMs / 1000);
  const expiresAt = issuedAt + 15 * 60;
  const header = base64UrlEncode(
    JSON.stringify({
      alg: "ES256",
      kid: config.keyId,
      typ: "JWT",
    }),
  );
  const payload = base64UrlEncode(
    JSON.stringify({
      iss: config.issuerId,
      iat: issuedAt,
      exp: expiresAt,
      aud: APPLE_SERVER_AUDIENCE,
      bid: config.bundleId,
    }),
  );
  const unsignedToken = `${header}.${payload}`;
  const signature = crypto.sign("sha256", Buffer.from(unsignedToken, "utf8"), {
    key: config.privateKey,
    dsaEncoding: "ieee-p1363",
  });

  return `${unsignedToken}.${base64UrlEncode(signature)}`;
}

function buildAppleTransactionLookupUrl(
  transactionId: string,
  environment: AppleServerEnvironment,
): string {
  const encodedTransactionId = encodeURIComponent(transactionId);
  const baseUrl =
    environment === "SANDBOX"
      ? APPLE_SERVER_SANDBOX_BASE_URL
      : APPLE_SERVER_BASE_URL;
  return `${baseUrl}/inApps/v1/transactions/${encodedTransactionId}`;
}

function decodeAppleSignedTransactionInfo(
  signedTransactionInfo: string,
): AppleTransactionInfoPayload {
  const parts = signedTransactionInfo.split(".");
  if (parts.length < 2) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid signed transaction payload.",
    );
  }

  try {
    const payloadJson = base64UrlDecode(parts[1]).toString("utf8");
    return JSON.parse(payloadJson) as AppleTransactionInfoPayload;
  } catch {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Could not decode Apple transaction payload.",
    );
  }
}

function certificateDerToPem(base64Der: string): string {
  const lines = base64Der.match(/.{1,64}/g) ?? [base64Der];
  return [
    "-----BEGIN CERTIFICATE-----",
    ...lines,
    "-----END CERTIFICATE-----",
  ].join("\n");
}

function verifyAppleSignedPayloadSignature(signedPayload: string): void {
  const parts = signedPayload.split(".");
  if (parts.length !== 3) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid Apple signed payload format.",
    );
  }

  let header: Record<string, unknown>;
  try {
    const headerJson = base64UrlDecode(parts[0]).toString("utf8");
    header = JSON.parse(headerJson) as Record<string, unknown>;
  } catch {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid Apple signed payload header.",
    );
  }

  if (header.alg !== "ES256") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Unsupported Apple payload signing algorithm.",
    );
  }

  const x5c = Array.isArray(header.x5c)
    ? header.x5c.filter((item): item is string => typeof item === "string")
    : [];
  if (x5c.length === 0) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Apple payload certificate chain is missing.",
    );
  }

  const signingInput = `${parts[0]}.${parts[1]}`;
  const signature = base64UrlDecode(parts[2]);
  const certificatePem = certificateDerToPem(x5c[0]);
  const isValid = crypto.verify(
    "sha256",
    Buffer.from(signingInput, "utf8"),
    { key: certificatePem, dsaEncoding: "ieee-p1363" },
    signature,
  );

  if (!isValid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Apple payload signature verification failed.",
    );
  }
}

function decodeAppleServerNotificationPayload(
  signedPayload: string,
  deps?: { verifySignature?: (payload: string) => void },
): AppleServerNotificationPayload {
  try {
    (deps?.verifySignature ?? verifyAppleSignedPayloadSignature)(signedPayload);
  } catch (err) {
    if (err instanceof functions.https.HttpsError) {
      throw err;
    }
    throw new functions.https.HttpsError(
      "permission-denied",
      "Apple payload signature verification failed.",
    );
  }

  const parts = signedPayload.split(".");
  if (parts.length < 2) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid Apple signed payload.",
    );
  }

  try {
    const payloadJson = base64UrlDecode(parts[1]).toString("utf8");
    return JSON.parse(payloadJson) as AppleServerNotificationPayload;
  } catch {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Could not decode Apple notification payload.",
    );
  }
}

function parseAppleMillis(value: number | string | undefined): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function deriveAppleSubscriptionEntitlement(
  payload: AppleTransactionInfoPayload,
  nowMs: number,
): AppleSubscriptionEntitlement {
  const expiryTimeMillis = parseAppleMillis(payload.expiresDate);
  const revocationDateMillis = parseAppleMillis(payload.revocationDate);

  if (revocationDateMillis != null && revocationDateMillis <= nowMs) {
    return {
      plan: "free",
      status: "revoked",
      cancelAtPeriodEnd: false,
      currentPeriodEnd: null,
      expiryTimeMillis: null,
    };
  }

  if (expiryTimeMillis == null) {
    return {
      plan: "free",
      status: "unknown",
      cancelAtPeriodEnd: false,
      currentPeriodEnd: null,
      expiryTimeMillis: null,
    };
  }

  if (expiryTimeMillis <= nowMs) {
    return {
      plan: "free",
      status: "expired",
      cancelAtPeriodEnd: false,
      currentPeriodEnd: Math.floor(expiryTimeMillis / 1000),
      expiryTimeMillis,
    };
  }

  return {
    plan: "plus",
    status: "active",
    cancelAtPeriodEnd: false,
    currentPeriodEnd: Math.floor(expiryTimeMillis / 1000),
    expiryTimeMillis,
  };
}

async function fetchAppleTransactionValidation(
  params: { transactionId: string },
  deps?: {
    fetchImpl?: typeof fetch;
    authTokenProvider?: (config: AppleServerApiConfig) => Promise<string>;
    config?: AppleServerApiConfig;
  },
): Promise<AppleTransactionValidationResult> {
  const fetchImpl = deps?.fetchImpl ?? fetch;
  const config = deps?.config ?? getAppleServerApiConfig();
  const authTokenProvider =
    deps?.authTokenProvider ??
    (async (resolvedConfig: AppleServerApiConfig) =>
      createAppleServerAuthToken(resolvedConfig));
  const authToken = await authTokenProvider(config);
  const environments: AppleServerEnvironment[] = ["PRODUCTION", "SANDBOX"];

  for (const environment of environments) {
    const url = buildAppleTransactionLookupUrl(
      params.transactionId,
      environment,
    );
    const response = await fetchImpl(url, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${authToken}`,
        Accept: "application/json",
      },
    });

    if (response.status === 404) {
      continue;
    }

    if (response.status === 401 || response.status === 403) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Apple server validation permission denied.",
      );
    }

    if (!response.ok) {
      const bodyText = await response.text().catch(() => "");
      console.error("apple_transaction_validation_failed", {
        status: response.status,
        environment,
        bodyText,
      });
      throw new functions.https.HttpsError(
        "internal",
        "Apple transaction validation failed.",
      );
    }

    const body = (await response.json()) as AppleTransactionLookupResponse;
    const signedTransactionInfo = optionalString(body.signedTransactionInfo);
    if (!signedTransactionInfo) {
      throw new functions.https.HttpsError(
        "internal",
        "Apple validation response missing transaction info.",
      );
    }

    const transaction = decodeAppleSignedTransactionInfo(signedTransactionInfo);
    if (transaction.bundleId && transaction.bundleId !== config.bundleId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Apple purchase bundle identifier does not match this app.",
      );
    }

    return {
      environment:
        normalizeAppleServerEnvironment(body.environment) ?? environment,
      signedTransactionInfo,
      transaction,
    };
  }

  throw new functions.https.HttpsError(
    "not-found",
    "Apple transaction not found.",
  );
}

function buildGoogleSubscriptionValidationUrl(params: {
  packageName: string;
  productId: string;
  purchaseToken: string;
}): string {
  const encodedPackageName = encodeURIComponent(params.packageName);
  const encodedProductId = encodeURIComponent(params.productId);
  const encodedPurchaseToken = encodeURIComponent(params.purchaseToken);
  return (
    "https://androidpublisher.googleapis.com/androidpublisher/v3/" +
    `applications/${encodedPackageName}/purchases/subscriptions/` +
    `${encodedProductId}/tokens/${encodedPurchaseToken}`
  );
}

async function getAndroidPublisherAccessToken(
  authFactory: () => GoogleAuth = () =>
    new GoogleAuth({ scopes: [ANDROID_PUBLISHER_SCOPE] }),
): Promise<string> {
  const auth = authFactory();
  const client = await auth.getClient();
  const tokenValue = await client.getAccessToken();
  const token = typeof tokenValue === "string" ? tokenValue : tokenValue?.token;
  if (!token) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Could not obtain Google Play access token.",
    );
  }
  return token;
}

async function fetchGoogleSubscriptionValidation(
  params: { packageName: string; productId: string; purchaseToken: string },
  deps?: {
    fetchImpl?: typeof fetch;
    accessTokenProvider?: () => Promise<string>;
  },
): Promise<GoogleSubscriptionPurchaseResponse> {
  const fetchImpl = deps?.fetchImpl ?? fetch;
  const accessTokenProvider =
    deps?.accessTokenProvider ?? (() => getAndroidPublisherAccessToken());

  const url = buildGoogleSubscriptionValidationUrl(params);
  const accessToken = await accessTokenProvider();
  const response = await fetchImpl(url, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
    },
  });

  if (response.status === 404) {
    throw new functions.https.HttpsError(
      "not-found",
      "Google Play purchase token not found.",
    );
  }

  if (response.status === 401 || response.status === 403) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Google Play validation permission denied.",
    );
  }

  if (!response.ok) {
    const bodyText = await response.text().catch(() => "");
    console.error("google_play_validation_failed", {
      status: response.status,
      bodyText,
    });
    throw new functions.https.HttpsError(
      "internal",
      "Google Play validation failed.",
    );
  }

  return (await response.json()) as GoogleSubscriptionPurchaseResponse;
}

function parseMillisString(value: string | undefined): number | null {
  if (!value) return null;
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return null;
  return parsed;
}

function deriveGoogleSubscriptionEntitlement(
  payload: GoogleSubscriptionPurchaseResponse,
  nowMs: number,
): GoogleSubscriptionEntitlement {
  const expiryTimeMillis = parseMillisString(payload.expiryTimeMillis);
  const hasFutureAccess = expiryTimeMillis != null && expiryTimeMillis > nowMs;
  const paymentState =
    typeof payload.paymentState === "number" ? payload.paymentState : null;
  const isPendingPayment = paymentState === 0;
  const cancelAtPeriodEnd = payload.autoRenewing === false && hasFutureAccess;

  let status = "unknown";
  if (expiryTimeMillis == null) {
    status = "unknown";
  } else if (expiryTimeMillis <= nowMs) {
    status = "expired";
  } else if (isPendingPayment) {
    status = "pending";
  } else if (paymentState === 2) {
    status = "trialing";
  } else if (cancelAtPeriodEnd) {
    status = "active_until_period_end";
  } else {
    status = "active";
  }

  const plan: "free" | "plus" =
    hasFutureAccess && !isPendingPayment ? "plus" : "free";

  return {
    plan,
    status,
    cancelAtPeriodEnd,
    currentPeriodEnd:
      expiryTimeMillis == null ? null : Math.floor(expiryTimeMillis / 1000),
    expiryTimeMillis,
  };
}

async function ensureGooglePurchaseNotAlreadyLinked(
  uid: string,
  purchaseTokenHash: string,
  orderId?: string,
): Promise<void> {
  const tokenSnap = await db
    .collection("users")
    .where("googlePlayPurchase.purchaseTokenHash", "==", purchaseTokenHash)
    .limit(1)
    .get();

  if (!tokenSnap.empty && tokenSnap.docs[0].id !== uid) {
    throw new functions.https.HttpsError(
      "already-exists",
      "Purchase token is already linked to another account.",
    );
  }

  const normalizedOrderId = orderId?.trim();
  if (!normalizedOrderId) return;

  const orderSnap = await db
    .collection("users")
    .where("googlePlayPurchase.orderId", "==", normalizedOrderId)
    .limit(1)
    .get();

  if (!orderSnap.empty && orderSnap.docs[0].id !== uid) {
    throw new functions.https.HttpsError(
      "already-exists",
      "Purchase order is already linked to another account.",
    );
  }
}

async function ensureAppleTransactionNotAlreadyLinked(
  uid: string,
  identifiers: {
    originalTransactionId?: string;
    latestTransactionId?: string;
    webOrderLineItemId?: string;
  },
): Promise<void> {
  const checks = [
    {
      field: "applePurchase.originalTransactionId",
      value: optionalString(identifiers.originalTransactionId),
      message:
        "Apple original transaction is already linked to another account.",
    },
    {
      field: "applePurchase.latestTransactionId",
      value: optionalString(identifiers.latestTransactionId),
      message: "Apple transaction is already linked to another account.",
    },
    {
      field: "applePurchase.webOrderLineItemId",
      value: optionalString(identifiers.webOrderLineItemId),
      message: "Apple order line item is already linked to another account.",
    },
  ];

  for (const check of checks) {
    if (!check.value) continue;

    const snapshot = await db
      .collection("users")
      .where(check.field, "==", check.value)
      .limit(1)
      .get();

    if (!snapshot.empty && snapshot.docs[0].id !== uid) {
      throw new functions.https.HttpsError("already-exists", check.message);
    }
  }
}

async function verifyGooglePurchaseTokenForUser(params: {
  uid: string;
  productId: string;
  purchaseToken: string;
  packageName?: string;
}): Promise<PurchaseReceiptVerificationResult> {
  const packageName =
    normalizeGooglePlayPackageName(optionalString(params.packageName)) ??
    normalizeGooglePlayPackageName(getGooglePlayPackageName());

  if (!packageName) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "GOOGLE_PLAY_PACKAGE_NAME is not configured.",
    );
  }

  const validation = await fetchGoogleSubscriptionValidation({
    packageName,
    productId: params.productId,
    purchaseToken: params.purchaseToken,
  });

  const purchaseTokenHash = hashPurchaseToken(params.purchaseToken);
  await ensureGooglePurchaseNotAlreadyLinked(
    params.uid,
    purchaseTokenHash,
    validation.orderId,
  );

  const entitlement = deriveGoogleSubscriptionEntitlement(validation, Date.now());

  await setUserPlan(params.uid, entitlement.plan);

  const payload: Record<string, unknown> = {
    googlePlayPurchase: {
      packageName,
      productId: params.productId,
      orderId: validation.orderId ?? null,
      purchaseTokenHash,
      linkedPurchaseToken: validation.linkedPurchaseToken ?? null,
      paymentState:
        typeof validation.paymentState === "number"
          ? validation.paymentState
          : null,
      acknowledgementState:
        typeof validation.acknowledgementState === "number"
          ? validation.acknowledgementState
          : null,
      autoRenewing:
        typeof validation.autoRenewing === "boolean"
          ? validation.autoRenewing
          : null,
      cancelReason:
        typeof validation.cancelReason === "number"
          ? validation.cancelReason
          : null,
      expiryTimeMillis: entitlement.expiryTimeMillis,
      lastValidatedAt: serverTimestamp(),
    },
    subscriptionLifecycle: {
      provider: "google_play",
      status: entitlement.status,
      currentPeriodEnd: entitlement.currentPeriodEnd,
      cancelAtPeriodEnd: entitlement.cancelAtPeriodEnd,
      lastValidatedAt: serverTimestamp(),
    },
  };

  if (entitlement.expiryTimeMillis != null) {
    payload.subscriptionExpiresAt = new Date(entitlement.expiryTimeMillis);
  } else if (entitlement.plan === "free") {
    payload.subscriptionExpiresAt = deleteField();
  }

  await db.collection("users").doc(params.uid).set(payload, { merge: true });

  return {
    plan: entitlement.plan,
    status: entitlement.status,
    provider: "google_play",
    productId: params.productId,
    orderId: validation.orderId ?? null,
    currentPeriodEnd: entitlement.currentPeriodEnd,
    cancelAtPeriodEnd: entitlement.cancelAtPeriodEnd,
  };
}

async function verifyAppleTransactionForUser(params: {
  uid: string;
  transactionId: string;
  productId?: string;
}): Promise<PurchaseReceiptVerificationResult> {
  const expectedProductId = optionalString(params.productId);
  const validation = await fetchAppleTransactionValidation({
    transactionId: params.transactionId,
  });
  const transaction = validation.transaction;

  if (
    expectedProductId &&
    transaction.productId &&
    transaction.productId !== expectedProductId
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Apple transaction product does not match requested product.",
    );
  }

  await ensureAppleTransactionNotAlreadyLinked(params.uid, {
    originalTransactionId: transaction.originalTransactionId,
    latestTransactionId: transaction.transactionId ?? params.transactionId,
    webOrderLineItemId: transaction.webOrderLineItemId,
  });

  const entitlement = deriveAppleSubscriptionEntitlement(transaction, Date.now());
  const purchaseDateMillis = parseAppleMillis(transaction.purchaseDate);
  const revocationDateMillis = parseAppleMillis(transaction.revocationDate);

  await setUserPlan(params.uid, entitlement.plan);

  const payload: Record<string, unknown> = {
    applePurchase: {
      environment: validation.environment,
      bundleId: transaction.bundleId ?? null,
      productId: transaction.productId ?? expectedProductId ?? null,
      originalTransactionId: transaction.originalTransactionId ?? null,
      latestTransactionId: transaction.transactionId ?? params.transactionId,
      webOrderLineItemId: transaction.webOrderLineItemId ?? null,
      inAppOwnershipType: transaction.inAppOwnershipType ?? null,
      transactionReason: transaction.transactionReason ?? null,
      purchaseDateMillis,
      expiresDateMillis: entitlement.expiryTimeMillis,
      revocationDateMillis,
      signedTransactionHash: hashPurchaseToken(
        validation.signedTransactionInfo,
      ),
      lastValidatedAt: serverTimestamp(),
    },
    subscriptionLifecycle: {
      provider: "app_store",
      status: entitlement.status,
      currentPeriodEnd: entitlement.currentPeriodEnd,
      cancelAtPeriodEnd: entitlement.cancelAtPeriodEnd,
      lastValidatedAt: serverTimestamp(),
    },
  };

  if (entitlement.expiryTimeMillis != null) {
    payload.subscriptionExpiresAt = new Date(entitlement.expiryTimeMillis);
  } else if (entitlement.plan === "free") {
    payload.subscriptionExpiresAt = deleteField();
  }

  await db.collection("users").doc(params.uid).set(payload, { merge: true });

  return {
    plan: entitlement.plan,
    status: entitlement.status,
    provider: "app_store",
    productId: transaction.productId ?? expectedProductId ?? null,
    transactionId: transaction.transactionId ?? params.transactionId,
    originalTransactionId: transaction.originalTransactionId ?? null,
    currentPeriodEnd: entitlement.currentPeriodEnd,
    cancelAtPeriodEnd: entitlement.cancelAtPeriodEnd,
  };
}

async function verifyPurchaseReceiptForUser(
  params: {
    uid: string;
    platform: string;
    receiptData: string;
    productId?: string;
    packageName?: string;
  },
  deps?: {
    verifyGooglePurchase?: typeof verifyGooglePurchaseTokenForUser;
    verifyApplePurchase?: typeof verifyAppleTransactionForUser;
  },
): Promise<PurchaseReceiptVerificationResult> {
  const provider = normalizePurchaseValidationPlatform(params.platform);
  if (!provider) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Unsupported purchase validation platform.",
    );
  }

  if (provider === "google_play") {
    return (deps?.verifyGooglePurchase ?? verifyGooglePurchaseTokenForUser)({
      uid: params.uid,
      productId: requireString(params.productId, "productId"),
      purchaseToken: params.receiptData,
      packageName: params.packageName,
    });
  }

  return (deps?.verifyApplePurchase ?? verifyAppleTransactionForUser)({
    uid: params.uid,
    transactionId: params.receiptData,
    productId: optionalString(params.productId),
  });
}

async function findUserByAppleTransactionIdentifiers(identifiers: {
  originalTransactionId?: string;
  latestTransactionId?: string;
  webOrderLineItemId?: string;
}): Promise<FirebaseFirestore.QueryDocumentSnapshot | null> {
  const checks = [
    {
      field: "applePurchase.originalTransactionId",
      value: optionalString(identifiers.originalTransactionId),
    },
    {
      field: "applePurchase.latestTransactionId",
      value: optionalString(identifiers.latestTransactionId),
    },
    {
      field: "applePurchase.webOrderLineItemId",
      value: optionalString(identifiers.webOrderLineItemId),
    },
  ];

  for (const check of checks) {
    if (!check.value) continue;

    const snapshot = await db
      .collection("users")
      .where(check.field, "==", check.value)
      .limit(1)
      .get();
    if (!snapshot.empty) {
      return snapshot.docs[0];
    }
  }

  return null;
}

function mapAppleServerNotificationType(
  notificationType: string,
  subtype?: string,
): AppleServerNotificationMapping {
  const normalizedType = notificationType.trim().toUpperCase();
  const normalizedSubtype = subtype?.trim().toUpperCase();

  switch (normalizedType) {
    case "SUBSCRIBED":
    case "DID_RENEW":
    case "DID_RECOVER":
    case "OFFER_REDEEMED":
    case "RENEWAL_EXTENDED":
      return { status: "active", forceFree: false };
    case "DID_FAIL_TO_RENEW":
      return { status: "billing_retry", forceFree: false };
    case "DID_CHANGE_RENEWAL_STATUS":
      return {
        status:
          normalizedSubtype === "AUTO_RENEW_DISABLED"
            ? "canceled"
            : "renewal_status_changed",
        forceFree: false,
      };
    case "GRACE_PERIOD_EXPIRED":
      return { status: "grace_period_expired", forceFree: true };
    case "EXPIRED":
      return { status: "expired", forceFree: true };
    case "REFUND":
      return { status: "refunded", forceFree: true };
    case "REVOKE":
      return { status: "revoked", forceFree: true };
    default:
      return { status: "unknown", forceFree: false };
  }
}

function applyAppleServerNotificationEntitlementOverride(
  entitlement: AppleSubscriptionEntitlement,
  mapping: AppleServerNotificationMapping,
  nowMs: number,
): AppleSubscriptionEntitlement {
  const hasFutureExpiry =
    entitlement.expiryTimeMillis != null &&
    entitlement.expiryTimeMillis > nowMs;
  const shouldForceFree =
    mapping.forceFree ||
    mapping.status === "expired" ||
    mapping.status === "revoked";
  const keepAccessUntilPeriodEnd =
    (mapping.status === "canceled" || mapping.status === "billing_retry") &&
    hasFutureExpiry;

  if (shouldForceFree) {
    return {
      plan: "free",
      status: mapping.status,
      cancelAtPeriodEnd: false,
      currentPeriodEnd: null,
      expiryTimeMillis: null,
    };
  }

  if (keepAccessUntilPeriodEnd) {
    return {
      ...entitlement,
      plan: "plus",
      status: mapping.status,
      cancelAtPeriodEnd:
        mapping.status === "canceled" || entitlement.cancelAtPeriodEnd,
    };
  }

  return {
    ...entitlement,
    status: mapping.status,
  };
}

function parseAppleNotificationSignedDate(
  value: number | string | undefined,
  fallbackNowMs: number,
): number {
  const parsed = parseAppleMillis(value);
  return parsed == null ? fallbackNowMs : parsed;
}

function mapGoogleRtdnNotificationType(
  notificationType: number,
): GoogleRtdnNotificationMapping {
  switch (notificationType) {
    case 1: // SUBSCRIPTION_RECOVERED
    case 2: // SUBSCRIPTION_RENEWED
    case 4: // SUBSCRIPTION_PURCHASED
    case 7: // SUBSCRIPTION_RESTARTED
      return { status: "active", forceFree: false };
    case 3: // SUBSCRIPTION_CANCELED
      return { status: "canceled", forceFree: false };
    case 5: // SUBSCRIPTION_ON_HOLD
      return { status: "on_hold", forceFree: true };
    case 6: // SUBSCRIPTION_IN_GRACE_PERIOD
      return { status: "in_grace_period", forceFree: false };
    case 8: // SUBSCRIPTION_PRICE_CHANGE_CONFIRMED
      return { status: "price_change_confirmed", forceFree: false };
    case 9: // SUBSCRIPTION_DEFERRED
      return { status: "deferred", forceFree: false };
    case 10: // SUBSCRIPTION_PAUSED
      return { status: "paused", forceFree: true };
    case 11: // SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED
      return { status: "pause_schedule_changed", forceFree: false };
    case 12: // SUBSCRIPTION_REVOKED
      return { status: "revoked", forceFree: true };
    case 13: // SUBSCRIPTION_EXPIRED
      return { status: "expired", forceFree: true };
    default:
      return { status: "unknown", forceFree: false };
  }
}

function applyGoogleRtdnEntitlementOverride(
  entitlement: GoogleSubscriptionEntitlement,
  mapping: GoogleRtdnNotificationMapping,
  nowMs: number,
): GoogleSubscriptionEntitlement {
  const hasFutureExpiry =
    entitlement.expiryTimeMillis != null &&
    entitlement.expiryTimeMillis > nowMs;
  const shouldForceFree =
    mapping.forceFree ||
    mapping.status === "expired" ||
    mapping.status === "revoked";
  const keepAccessUntilPeriodEnd =
    (mapping.status === "canceled" || mapping.status === "in_grace_period") &&
    hasFutureExpiry;

  if (shouldForceFree) {
    return {
      plan: "free",
      status: mapping.status,
      cancelAtPeriodEnd: false,
      currentPeriodEnd: null,
      expiryTimeMillis: null,
    };
  }

  if (keepAccessUntilPeriodEnd) {
    return {
      ...entitlement,
      plan: "plus",
      status: mapping.status,
      cancelAtPeriodEnd:
        mapping.status === "canceled" || entitlement.cancelAtPeriodEnd,
    };
  }

  return {
    ...entitlement,
    status: mapping.status,
  };
}

function decodeGoogleRtdnEnvelope(body: unknown): GoogleRtdnDecodeResult {
  const directPayload = body as GoogleRtdnPayload | null;
  if (
    directPayload &&
    typeof directPayload === "object" &&
    directPayload.subscriptionNotification
  ) {
    return { payload: directPayload };
  }

  const envelope = body as GooglePubSubPushEnvelope | null;
  const base64Data = envelope?.message?.data;
  if (!base64Data) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing Pub/Sub message data.",
    );
  }

  let parsed: unknown;
  try {
    const decoded = Buffer.from(base64Data, "base64").toString("utf8");
    parsed = JSON.parse(decoded);
  } catch (_err) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid Pub/Sub message payload.",
    );
  }

  return {
    payload: parsed as GoogleRtdnPayload,
    messageId: envelope?.message?.messageId,
  };
}

function parseGoogleRtdnEventTime(
  value: string | undefined,
  fallbackNowMs: number,
): number {
  const parsed = parseMillisString(value);
  if (parsed == null) return fallbackNowMs;
  return parsed;
}

async function ensureUserExists(uid: string): Promise<UserDoc> {
  return getUser(uid);
}

async function ensureNotBlocked(uid: string, targetUserId: string) {
  // Check if uid blocked targetUserId
  const uidBlockedTarget = await db
    .collection("blocks")
    .where("blockerId", "==", uid)
    .where("blockedId", "==", targetUserId)
    .limit(1)
    .get();

  if (!uidBlockedTarget.empty) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You cannot interact with this user.",
    );
  }

  // Check if targetUserId blocked uid
  const targetBlockedUid = await db
    .collection("blocks")
    .where("blockerId", "==", targetUserId)
    .where("blockedId", "==", uid)
    .limit(1)
    .get();

  if (!targetBlockedUid.empty) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You cannot interact with this user.",
    );
  }
}

async function getDiscoveryExclusionSets(
  uid: string,
): Promise<DiscoveryExclusionSets> {
  const [
    blockedByMeSnap,
    legacyBlockedByMeSnap,
    blockedMeSnap,
    legacyBlockedMeSnap,
    reportedByMeSnap,
    legacyReportedByMeSnap,
    reportedMeSnap,
    legacyReportedMeSnap,
    likesSnap,
    swipesSnap,
    matchesSnap,
    legacyMatchesSnap,
  ] = await Promise.all([
    db.collection("blocks").where("blockerId", "==", uid).get(),
    db.collection("blocks").where("blocker_id", "==", uid).get(),
    db.collection("blocks").where("blockedId", "==", uid).get(),
    db.collection("blocks").where("blocked_id", "==", uid).get(),
    db.collection("reports").where("reporterId", "==", uid).get(),
    db.collection("reports").where("reporter_id", "==", uid).get(),
    db.collection("reports").where("reportedId", "==", uid).get(),
    db.collection("reports").where("reported_id", "==", uid).get(),
    db.collection("likes").where("fromUserId", "==", uid).limit(1000).get(),
    db.collection("swipes").where("swiperId", "==", uid).limit(1000).get(),
    db.collection("matches").where("userIds", "array-contains", uid).get(),
    db.collection("matches").where("participants", "array-contains", uid).get(),
  ]);

  const records = (snapshots: FirebaseFirestore.QuerySnapshot[]) =>
    snapshots.flatMap((snapshot) =>
      snapshot.docs.map((doc) => asRecord(doc.data())),
    );

  return buildDiscoveryExclusionSetsFromRecords(uid, {
    blockedByMe: records([blockedByMeSnap, legacyBlockedByMeSnap]),
    blockedMe: records([blockedMeSnap, legacyBlockedMeSnap]),
    reportedByMe: records([reportedByMeSnap, legacyReportedByMeSnap]),
    reportedMe: records([reportedMeSnap, legacyReportedMeSnap]),
    likes: records([likesSnap]),
    swipes: records([swipesSnap]),
    matches: records([matchesSnap, legacyMatchesSnap]),
  });
}

function setCorsHeaders(res: functions.Response, req?: functions.Request) {
  // Use whitelisted origin or default for server-to-server requests
  const origin = req?.headers?.origin;
  const corsAllowedOrigins = getCorsAllowedOrigins();
  const allowedOrigin =
    origin && corsAllowedOrigins.includes(origin)
      ? origin
      : corsAllowedOrigins[0] || "";
  if (allowedOrigin) {
    res.set("Access-Control-Allow-Origin", allowedOrigin);
  }
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, stripe-signature");
}

async function ensureUserInMatch(matchId: string, uid: string) {
  const matchSnap = await db.collection("matches").doc(matchId).get();
  if (!matchSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Match not found.");
  }
  const matchData = matchSnap.data() as FirebaseFirestore.DocumentData;
  const userIds = (
    Array.isArray(matchData.userIds)
      ? matchData.userIds
      : Array.isArray(matchData.users)
        ? matchData.users
        : Array.isArray(matchData.participants)
          ? matchData.participants
          : []
  ) as string[];
  if (!userIds.includes(uid)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You are not part of this match.",
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
          lastFlaggedAt: serverTimestamp(),
          autoFlags: incrementBy(1),
        },
      },
      { merge: true },
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

type NotificationCategory =
  | "calls"
  | "messages"
  | "matches"
  | "subscriptions"
  | "likes"
  | "profileViews"
  | "promotions"
  | "safetyAlerts";

const NOTIFICATION_CATEGORIES: readonly NotificationCategory[] = [
  "calls",
  "messages",
  "matches",
  "subscriptions",
  "likes",
  "profileViews",
  "promotions",
  "safetyAlerts",
];

function parseNotificationCategory(value: unknown): NotificationCategory | null {
  if (typeof value !== "string") return null;
  return NOTIFICATION_CATEGORIES.includes(value as NotificationCategory)
    ? (value as NotificationCategory)
    : null;
}

interface NotificationPrefs {
  push: boolean;
  calls: boolean;
  messages: boolean;
  matches: boolean;
  subscriptions: boolean;
  likes: boolean;
  profileViews: boolean;
  promotions: boolean;
  safetyAlerts: boolean;
  mutedMessages: string[];
  mutedCalls: string[];
  quietHoursEnabled: boolean;
  quietHoursStart: number; // hour 0-23, default 22
  quietHoursEnd: number; // hour 0-23, default 8
  timezone: string; // IANA timezone, default "UTC"
}

function normalizeNotificationPrefs(
  rawPrefs: Record<string, unknown>,
  timezoneFallback: string,
): NotificationPrefs {
  const quietHoursStart =
    typeof rawPrefs.quietHoursStart === "number"
      ? rawPrefs.quietHoursStart
      : 22;
  const quietHoursEnd =
    typeof rawPrefs.quietHoursEnd === "number" ? rawPrefs.quietHoursEnd : 8;
  const quietHoursEnabled =
    typeof rawPrefs.quietHoursEnabled === "boolean"
      ? rawPrefs.quietHoursEnabled
      : false;

  return {
    push: rawPrefs.push !== false,
    calls: rawPrefs.calls !== false,
    messages: rawPrefs.messages !== false,
    matches: rawPrefs.matches !== false,
    subscriptions: rawPrefs.subscriptions !== false,
    likes: rawPrefs.likes !== false,
    profileViews: rawPrefs.profileViews !== false,
    promotions: rawPrefs.promotions !== false,
    safetyAlerts: true, // Always on — cannot be disabled
    mutedMessages: normalizeNotificationMutedList(rawPrefs.mutedMessages),
    mutedCalls: normalizeNotificationMutedList(rawPrefs.mutedCalls),
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
    timezone:
      typeof rawPrefs.timezone === "string"
        ? rawPrefs.timezone
        : timezoneFallback,
  };
}

function normalizeNotificationMutedList(value: unknown): string[] {
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

async function getNotificationPrefs(
  userId: string,
): Promise<NotificationPrefs> {
  try {
    const doc = await db.collection("users").doc(userId).get();
    const data = doc.data() ?? {};
    const prefs = (data.notificationPrefs as Record<string, unknown>) ?? {};
    const timezoneFallback =
      typeof data.timezone === "string" ? data.timezone : "UTC";
    return normalizeNotificationPrefs(prefs, timezoneFallback);
  } catch (err) {
    console.warn("Failed to load notification prefs", { userId, err });
    return normalizeNotificationPrefs({}, "UTC");
  }
}

async function getPushTokensFor(
  userId: string,
  category: NotificationCategory,
  options: { fromUserId?: string } = {},
): Promise<string[]> {
  const prefs = await getNotificationPrefs(userId);
  const allowed = isNotificationCategoryAllowed(prefs, category, options);
  if (!allowed) return [];
  if (
    options.fromUserId &&
    category !== "safetyAlerts" &&
    (await hasBlockingRelationship(userId, options.fromUserId))
  ) {
    return [];
  }
  return getFcmTokens(userId);
}

function isNotificationCategoryAllowed(
  prefs: NotificationPrefs,
  category: NotificationCategory,
  options: { fromUserId?: string } = {},
): boolean {
  if (category === "safetyAlerts") return true;
  if (!prefs.push) return false;

  const fromUserId = options.fromUserId;
  if (
    fromUserId &&
    category === "messages" &&
    prefs.mutedMessages.includes(fromUserId)
  ) {
    return false;
  }
  if (
    fromUserId &&
    category === "calls" &&
    prefs.mutedCalls.includes(fromUserId)
  ) {
    return false;
  }

  return (
    (category === "calls" && prefs.calls) ||
    (category === "messages" && prefs.messages) ||
    (category === "matches" && prefs.matches) ||
    (category === "subscriptions" && prefs.subscriptions) ||
    (category === "likes" && prefs.likes) ||
    (category === "profileViews" && prefs.profileViews) ||
    (category === "promotions" && prefs.promotions)
  );
}

async function hasBlockingRelationship(
  recipientId: string,
  actorId: string,
): Promise<boolean> {
  if (recipientId === actorId) return false;
  const [recipientBlockedActor, actorBlockedRecipient] = await Promise.all([
    db.collection("blocks").doc(`${recipientId}_${actorId}`).get(),
    db.collection("blocks").doc(`${actorId}_${recipientId}`).get(),
  ]);
  if (recipientBlockedActor.exists || actorBlockedRecipient.exists) return true;

  const [legacyRecipientBlockedActor, legacyActorBlockedRecipient] =
    await Promise.all([
      db
        .collection("blocks")
        .where("blocker_id", "==", recipientId)
        .where("blocked_id", "==", actorId)
        .limit(1)
        .get(),
      db
        .collection("blocks")
        .where("blocker_id", "==", actorId)
        .where("blocked_id", "==", recipientId)
        .limit(1)
        .get(),
    ]);

  return !legacyRecipientBlockedActor.empty || !legacyActorBlockedRecipient.empty;
}

// ---------------------------------------------------------------------------
// Smart Notification Scheduling
// ---------------------------------------------------------------------------

/** Check whether it's currently within the user's quiet hours. */
function isInQuietHours(prefs: NotificationPrefs): boolean {
  if (!prefs.quietHoursEnabled) return false;

  const now = new Date();
  // Get current hour in user's timezone
  let hour: number;
  try {
    hour = parseInt(
      now.toLocaleString("en-US", {
        timeZone: prefs.timezone,
        hour: "numeric",
        hour12: false,
      }),
      10,
    );
  } catch {
    hour = now.getUTCHours();
  }
  const start = prefs.quietHoursStart;
  const end = prefs.quietHoursEnd;
  if (start < end) {
    return hour >= start && hour < end;
  }
  // Wraps midnight (e.g. 22-8)
  return hour >= start || hour < end;
}

/** Frequency cap: max 10 non-message notifications per day per user. */
const DAILY_NON_MESSAGE_CAP = 10;

async function isDailyCapReached(userId: string): Promise<boolean> {
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const snap = await db
    .collection("users")
    .doc(userId)
    .collection("notificationLog")
    .where("sentAt", ">=", admin.firestore.Timestamp.fromDate(todayStart))
    .where("isMessage", "==", false)
    .get();
  return snap.size >= DAILY_NON_MESSAGE_CAP;
}

async function logNotificationSent(
  userId: string,
  category: NotificationCategory,
): Promise<void> {
  await db
    .collection("users")
    .doc(userId)
    .collection("notificationLog")
    .add({
      category,
      isMessage: category === "messages",
      sentAt: admin.firestore.Timestamp.now(),
    });
}

/**
 * Queue a notification for later delivery (after quiet hours end).
 * Writes to users/{userId}/notificationQueue.
 */
async function queueNotification(
  userId: string,
  category: NotificationCategory,
  payload: {
    title: string;
    body: string;
    data?: Record<string, string>;
    imageUrl?: string;
  },
): Promise<void> {
  await db
    .collection("users")
    .doc(userId)
    .collection("notificationQueue")
    .add({
      category,
      title: payload.title,
      body: payload.body,
      data: payload.data ?? {},
      imageUrl: payload.imageUrl ?? null,
      queuedAt: admin.firestore.Timestamp.now(),
    });
}

/**
 * Smart send: respects quiet hours, frequency cap, and category prefs.
 * Messages are always delivered immediately (no batching/delay).
 */
async function smartSendNotification(
  userId: string,
  category: NotificationCategory,
  payload: {
    title: string;
    body: string;
    data?: Record<string, string>;
    imageUrl?: string;
  },
): Promise<void> {
  const tokens = await getPushTokensFor(userId, category);
  if (tokens.length === 0) return;

  const prefs = await getNotificationPrefs(userId);

  // Messages always delivered immediately
  if (category !== "messages") {
    // Check quiet hours — queue for later
    if (isInQuietHours(prefs)) {
      await queueNotification(userId, category, payload);
      return;
    }

    // Check daily frequency cap
    if (await isDailyCapReached(userId)) {
      return; // Drop silently when cap reached
    }
  }

  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: { title: payload.title, body: payload.body },
    data: payload.data,
  };

  if (payload.imageUrl) {
    message.notification!.imageUrl = payload.imageUrl;
  }

  await sendNotification(message);
  await logNotificationSent(userId, category);
}

/**
 * Scheduled function: flush queued notifications after quiet hours.
 * Runs every hour; delivers queued notifications for users whose quiet hours ended.
 */
export const flushNotificationQueue = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    // Query all users who have queued notifications
    const usersSnap = await db
      .collectionGroup("notificationQueue")
      .limit(500)
      .get();
    if (usersSnap.empty) return;

    // Group by userId
    const byUser = new Map<string, admin.firestore.QueryDocumentSnapshot[]>();
    for (const doc of usersSnap.docs) {
      const userId = doc.ref.parent.parent?.id;
      if (!userId) continue;
      const existing = byUser.get(userId) ?? [];
      existing.push(doc);
      byUser.set(userId, existing);
    }

    for (const [userId, docs] of byUser.entries()) {
      const prefs = await getNotificationPrefs(userId);
      if (isInQuietHours(prefs)) continue; // Still in quiet hours

      const hasAnyToken = (await getFcmTokens(userId)).length > 0;
      if (!hasAnyToken) {
        // Clean up queue for users with no tokens
        const batch = db.batch();
        for (const doc of docs) batch.delete(doc.ref);
        await batch.commit();
        continue;
      }

      // Batch like notifications: "You have N new likes"
      const likeDocs = docs.filter((d) => d.data().category === "likes");
      const otherDocs = docs.filter((d) => d.data().category !== "likes");
      const likeTokens = await getPushTokensFor(userId, "likes");

      if (likeDocs.length > 1 && likeTokens.length > 0) {
        await sendNotification({
          tokens: likeTokens,
          notification: {
            title: "New Likes",
            body: `You have ${likeDocs.length} new likes!`,
          },
          data: { type: "like", targetRoute: "/likes-you" },
        });
      } else if (likeDocs.length === 1 && likeTokens.length > 0) {
        const data = likeDocs[0].data();
        await sendNotification({
          tokens: likeTokens,
          notification: { title: data.title, body: data.body },
          data: data.data ?? {},
        });
      }

      // Send other queued notifications individually
      for (const doc of otherDocs) {
        const data = doc.data();
        const category = parseNotificationCategory(data.category);
        if (!category) continue;
        const tokens = await getPushTokensFor(userId, category, {
          fromUserId:
            typeof data.data?.fromUserId === "string"
              ? data.data.fromUserId
              : undefined,
        });
        if (tokens.length === 0) continue;
        const msg: admin.messaging.MulticastMessage = {
          tokens,
          notification: { title: data.title, body: data.body },
          data: data.data ?? {},
        };
        if (data.imageUrl) msg.notification!.imageUrl = data.imageUrl;
        await sendNotification(msg);
      }

      // Delete processed queue items
      const batch = db.batch();
      for (const doc of docs) batch.delete(doc.ref);
      await batch.commit();
    }
  });

async function sendNotification(message: admin.messaging.MulticastMessage) {
  if (!message.tokens || message.tokens.length === 0) return;
  await admin.messaging().sendEachForMulticast(message);
}

function haversineDistanceKm(
  lat1?: number,
  lon1?: number,
  lat2?: number,
  lon2?: number,
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
  const isPlus = (plan ?? "").toLowerCase() === "plus";
  const dailyLimit = isPlus ? DAILY_LIKE_LIMIT_PLUS : DAILY_LIKE_LIMIT_FREE;
  const hourlyLimit = isPlus ? HOURLY_LIKE_LIMIT_PLUS : HOURLY_LIKE_LIMIT_FREE;

  const now = new Date();
  const todayKey = now.toISOString().slice(0, 10);
  const hourKey = `${todayKey}T${now.getUTCHours().toString().padStart(2, "0")}`;
  const ref = db.collection("rateLimits").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? (snap.data() as Record<string, unknown>) : {};

    // Check daily limit
    const dailyLikes =
      (data.dailyLikes as Record<string, number> | undefined) ?? {};
    const dailyCount = dailyLikes[todayKey] ?? 0;
    if (dailyCount >= dailyLimit) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        `Daily like limit reached (${dailyLimit}). Try again tomorrow.`,
      );
    }

    // Check hourly limit (throttling)
    const hourlyLikes =
      (data.hourlyLikes as Record<string, number> | undefined) ?? {};
    const hourlyCount = hourlyLikes[hourKey] ?? 0;
    if (hourlyCount >= hourlyLimit) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        `Slow down! You've liked ${hourlyLimit} profiles this hour. Try again in a bit.`,
      );
    }

    // Increment both counters
    dailyLikes[todayKey] = dailyCount + 1;
    hourlyLikes[hourKey] = hourlyCount + 1;

    // Clean up old hourly keys (keep only last 24 hours)
    const cutoffHour = new Date(now.getTime() - 24 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 13);
    for (const key of Object.keys(hourlyLikes)) {
      if (key < cutoffHour) delete hourlyLikes[key];
    }

    tx.set(
      ref,
      {
        dailyLikes,
        hourlyLikes,
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );
  });
}

export const notifyDatePlanContact = callable<DatePlanEmailRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "share a date plan");
    const contactNameRaw = requireString(data?.contactName, "contactName");
    const contactEmailRaw = requireString(data?.contactEmail, "contactEmail");
    if (!isEmailLike(contactEmailRaw)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Enter a valid contact email.",
      );
    }
    const matchNameRaw = requireString(data?.matchName, "matchName");
    const locationRaw = requireString(data?.location, "location");
    const dateTimeMs = toNumber(data?.dateTimeMs);
    if (dateTimeMs == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "dateTimeMs is required.",
      );
    }
    const timeZoneOffsetMinutes = toNumber(data?.timeZoneOffsetMinutes) ?? 0;

    const contactEmail = normalizeEmail(contactEmailRaw);
    const contactName = truncateString(contactNameRaw, 80);
    const matchName = truncateString(matchNameRaw, 80);
    const location = truncateString(locationRaw, 200);
    const notesRaw = optionalString(data?.notes);
    const notes = notesRaw ? truncateString(notesRaw, 500) : undefined;

    const identifierHash = hashIdentifier(contactEmail);
    const rateLimit = await applyRateLimit(
      `date_plan_email:${uid}:${identifierHash}`,
      DATE_PLAN_EMAIL_LIMIT,
      DATE_PLAN_EMAIL_WINDOW_MS,
      DATE_PLAN_EMAIL_BLOCK_MS,
    );
    if (!rateLimit.allowed) {
      throwRateLimitError(rateLimit.retryAfterMs);
    }

    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data() || {};
    const profile = (userData.profile as { name?: string } | undefined) ?? {};
    const creatorNameRaw =
      (typeof profile.name === "string" && profile.name.trim()) ||
      (typeof userData.username === "string" && userData.username.trim()) ||
      "A Crush user";
    const creatorName = truncateString(creatorNameRaw, 80);

    const safeOffset = Math.max(
      -14 * 60,
      Math.min(14 * 60, timeZoneOffsetMinutes),
    );
    const localMillis = dateTimeMs + safeOffset * 60 * 1000;
    const localDate = new Date(localMillis);
    const dateLabel = localDate.toLocaleDateString("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric",
      year: "numeric",
      timeZone: "UTC",
    });
    const timeLabel = localDate.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
      timeZone: "UTC",
    });

    await sendDatePlanEmail({
      to: contactEmail,
      contactName,
      creatorName,
      matchName,
      dateLabel,
      timeLabel,
      location,
      notes,
    });

    return { success: true };
  },
);

export const moderateTextContent = callable<{
  content?: string;
}>(async (data) => {
  const content = requireString(data?.content, "content");
  const decision = moderateContent(content, "text");
  return {
    status: decision.status,
    action: decision.action,
    reason: decision.reason ?? null,
    severity: decision.severity,
  };
});

export const moderateImageContent = callable<{
  imageUrl?: string;
}>(async (data) => {
  requireString(data?.imageUrl, "imageUrl");

  // In a real implementation, you would call an image moderation API here.
  // For example, Google Cloud Vision API, AWS Rekognition, etc.
  // For now, we'll just return a "clean" status as a placeholder.

  return {
    status: "clean",
    action: "allow",
    reason: null,
    severity: "low",
  };
});

export const reportUser = callable<ReportRequest>(async (data, context) => {
  const reporterId = requireAuth(context, "report a user");
  requireEmailVerified(context, "report a user");
  const reportedId = requireString(data?.reportedId, "reportedId");
  const { reasonText: reason, reasonCategory } = canonicalizeSafetyReportReason(
    data?.reason,
    { field: "reason", maxLength: 1000, minLength: 1 },
  );
  const matchId = optionalString(data?.matchId);
  const messageId = optionalString(data?.messageId);
  const source = optionalString(data?.source);
  const description = optionalString(data?.description);

  if (reportedId === reporterId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You cannot report yourself.",
    );
  }

  // Rate limiting: prevent report spam/abuse
  const reportLimit = await applyRateLimit(
    `report:uid:${reporterId}`,
    REPORT_LIMIT,
    REPORT_WINDOW_MS,
    REPORT_BLOCK_MS,
  );
  if (!reportLimit.allowed) {
    throwRateLimitError(reportLimit.retryAfterMs);
  }

  await ensureUserExists(reportedId);

  await db.collection("reports").add({
    reporterId,
    reportedId,
    reason,
    reasonCategory,
    matchId: matchId ?? null,
    messageId: messageId ?? null,
    source: source ?? null,
    description: description ?? null,
    status: "open",
    createdAt: serverTimestamp(),
  });

  const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
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
          lastReportAt: serverTimestamp(),
          lastReason: reason,
          lastReasonCategory: reasonCategory,
          status: openReportsSnap.size >= 3 ? "needs_review" : "watch",
        },
      },
      { merge: true },
    );

  if (openReportsSnap.size >= 5) {
    await db.collection("automatedFlags").add({
      userId: reportedId,
      reason: "multiple_reports",
      reportCount: openReportsSnap.size,
      createdAt: serverTimestamp(),
      status: "open",
    });
  }

  return { ok: true };
});

export const blockUser = callable<BlockRequest>(async (data, context) => {
  const blockerId = requireAuth(context, "block a user");
  requireEmailVerified(context, "block a user");
  const blockedId = requireString(data?.blockedId, "blockedId");
  const blockerIdFromClient = optionalString(data?.blockerId);

  if (blockedId === blockerId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You cannot block yourself.",
    );
  }
  if (blockerIdFromClient && blockerIdFromClient !== blockerId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Blocker mismatch.",
    );
  }

  // Rate limiting: prevent block abuse
  const blockLimit = await applyRateLimit(
    `block:uid:${blockerId}`,
    BLOCK_LIMIT,
    BLOCK_WINDOW_MS,
    BLOCK_BLOCK_MS,
  );
  if (!blockLimit.allowed) {
    throwRateLimitError(blockLimit.retryAfterMs);
  }

  const docId = `${blockerId}_${blockedId}`;
  await db.collection("blocks").doc(docId).set({
    blockerId,
    blockedId,
    createdAt: serverTimestamp(),
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
      "Blocker mismatch.",
    );
  }

  // Rate limiting: prevent unblock abuse (less restrictive)
  const unblockLimit = await applyRateLimit(
    `unblock:uid:${blockerId}`,
    UNBLOCK_LIMIT,
    UNBLOCK_WINDOW_MS,
    UNBLOCK_BLOCK_MS,
  );
  if (!unblockLimit.allowed) {
    throwRateLimitError(unblockLimit.retryAfterMs);
  }

  const docId = `${blockerId}_${blockedId}`;
  await db.collection("blocks").doc(docId).delete();
  return { ok: true };
});

export const appealSafetyAction = callable<AppealRequest>(
  async (data, context) => {
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
      createdAt: serverTimestamp(),
    });

    await db
      .collection("users")
      .doc(uid)
      .set(
        {
          safetyFlags: {
            appealOpen: true,
            lastAppealAt: serverTimestamp(),
            lastReason: reason,
          },
        },
        { merge: true },
      );

    return { ok: true };
  },
);

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
      { typing: { [uid]: isTyping }, typingUpdatedAt: serverTimestamp() },
      { merge: true },
    );
  return { ok: true };
});

// Pin/unpin a match for the calling user. Writes the per-user pin flag on the
// match doc (pinnedForUser.{uid}); each participant pins independently.
export const setMatchPinned = callable<{
  matchId?: string;
  pinned?: boolean;
}>(async (data, context) => {
  const uid = requireAuth(context, "pin a match");
  const matchId = requireString(data?.matchId, "matchId");
  const pinned = !!data?.pinned;

  await ensureUserInMatch(matchId, uid);
  await db
    .collection("matches")
    .doc(matchId)
    .set(
      { pinnedForUser: { [uid]: pinned }, pinnedUpdatedAt: serverTimestamp() },
      { merge: true },
    );
  return { ok: true };
});

export const setPresenceStatus = callable<{ isOnline?: boolean }>(
  async (data, context) => {
    const uid = requireAuth(context, "update presence");
    const isOnline = !!data?.isOnline;
    await db.collection("users").doc(uid).set(
      {
        isOnline,
        lastSeenAt: serverTimestamp(),
      },
      { merge: true },
    );
    return { ok: true };
  },
);

export const setMediaSendingEnabled = callable<{
  matchId?: string;
  enabled?: boolean;
}>(async (data, context) => {
  const uid = requireAuth(context, "toggle media sending");
  const matchId = requireString(data?.matchId, "matchId");
  const enabled = !!data?.enabled;

  await ensureUserInMatch(matchId, uid);
  await db.collection("matches").doc(matchId).set(
    {
      mediaSendingEnabled: enabled,
      mediaUpdatedBy: uid,
      mediaUpdatedAt: serverTimestamp(),
    },
    { merge: true },
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
        reactionsUpdatedAt: serverTimestamp(),
      },
      { merge: true },
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
        reactions: { [uid]: deleteField() },
        reactionsUpdatedAt: serverTimestamp(),
      },
      { merge: true },
    );
  return { ok: true };
});

export const unmatch = callable<{ matchId?: string }>(async (data, context) => {
  const uid = requireAuth(context, "unmatch");
  requireEmailVerified(context, "unmatch");
  const matchId = requireString(data?.matchId, "matchId");
  const { otherUserId } = await ensureUserInMatch(matchId, uid);

  await db.collection("matches").doc(matchId).set(
    {
      status: "unmatched",
      unmatchedBy: uid,
      unmatchedAt: serverTimestamp(),
    },
    { merge: true },
  );

  if (otherUserId) {
    const tokens = await getPushTokensFor(otherUserId, "matches", {
      fromUserId: uid,
    });
    await sendNotification({
      tokens,
      notification: {
        title: "Match ended",
        body: "Someone unmatched this chat.",
      },
      data: {
        type: "match_ended",
        matchId,
        status: "unmatched",
        targetRoute: "/notifications",
      },
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
          reviewedAt: serverTimestamp(),
        },
      },
      { merge: true },
    );

    if (decision.action === "hold") {
      await flagUserForReview(fromUserId, "message_moderation");
      return;
    }

    const tokens = await getPushTokensFor(toUserId, "messages", {
      fromUserId,
    });
    if (tokens.length === 0) return;

    await sendNotification({
      tokens,
      notification: {
        title: "New message",
        body: data?.content
          ? String(data.content).slice(0, 80)
          : "You have a new message.",
      },
      data: {
        type: "message",
        matchId: context.params.matchId,
        targetId: context.params.matchId,
        targetRoute: `/chat/${context.params.matchId}`,
        fromUserId,
        messageType: type,
      },
    });
  });

export const onMatchCreated = functions.firestore
  .document("matches/{matchId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userIds = (data?.userIds as string[] | undefined) ?? [];
    if (userIds.length !== 2) return;

    const matchId = context.params.matchId;
    const [userA, userB] = userIds;

    // ─────────────────────────────────────────────────────────────────────────
    // AUTO-MIGRATE PENDING MESSAGE REQUESTS (R-113 fix)
    // When a match is created, check if there's a pending message request
    // between these users and migrate it to the match as the first message.
    // ─────────────────────────────────────────────────────────────────────────
    try {
      const pairKey =
        userA.localeCompare(userB) <= 0
          ? `${userA}|${userB}`
          : `${userB}|${userA}`;

      const requestDoc = await db
        .collection("message_requests")
        .doc(pairKey)
        .get();

      if (requestDoc.exists) {
        const requestData = requestDoc.data();
        const expiresAt = requestData?.expiresAt?.toDate?.() ?? new Date(0);
        const isExpired = new Date() > expiresAt;

        if (!isExpired && requestData?.content) {
          // Migrate the message request to the match's messages collection
          const messageRef = db
            .collection("matches")
            .doc(matchId)
            .collection("messages")
            .doc();

          await messageRef.set({
            matchId,
            fromUserId: requestData.fromUserId,
            toUserId: requestData.toUserId,
            content: requestData.content,
            type: requestData.type ?? "text",
            sentAt: requestData.sentAt ?? serverTimestamp(),
            isRead: false,
            isMigrated: true, // Flag to indicate this was a pre-match request
            reactions: {},
          });

          // Update match metadata
          await snap.ref.update({
            hasPreMatchMessage: true,
            lastMessageAt: serverTimestamp(),
            lastMessagePreview: String(requestData.content).slice(0, 50),
          });

          console.log(
            `Migrated message request ${pairKey} to match ${matchId}`,
          );
        }

        // Delete the message request regardless of whether it was migrated
        await db.collection("message_requests").doc(pairKey).delete();
        console.log(`Deleted message request ${pairKey}`);
      }
    } catch (err) {
      // Don't fail the entire match creation if migration fails
      console.error("Failed to migrate message request:", err);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SEND PUSH NOTIFICATIONS
    // ─────────────────────────────────────────────────────────────────────────
    const tokensByUser = await Promise.all(
      userIds.map(async (uid) => ({
        uid,
        tokens: await getPushTokensFor(uid, "matches"),
      })),
    );

    await Promise.all(
      tokensByUser.map(({ uid, tokens }) =>
        sendNotification({
          tokens,
          notification: {
            title: "You have a new match!",
            body: "Open Crush to start chatting.",
          },
          data: {
            type: "match",
            matchId: context.params.matchId,
            targetId: context.params.matchId,
            targetRoute: `/chat/${context.params.matchId}`,
            userId: uid,
          },
        }),
      ),
    );
  });

export const onSubscriptionUpdated = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const beforePlan = change.before.data()?.plan;
    const afterPlan = change.after.data()?.plan;
    if (!afterPlan || beforePlan === afterPlan) return;

    const tokens = await getPushTokensFor(
      context.params.userId,
      "subscriptions",
    );
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
      data: {
        type: "subscription",
        plan: afterPlan,
        targetRoute: "/settings/subscription",
      },
    });
  });

export const syncLegacyDiscoveryFields = functions.firestore
  .document("users/{userId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return;

    const patch = buildLegacyDiscoveryMirrorPatch(
      context.params.userId,
      (change.after.data() ?? {}) as Record<string, unknown>,
    );

    if (Object.keys(patch).length === 0) return;

    console.log("sync_legacy_discovery_fields", {
      uid: context.params.userId,
      fields: Object.keys(patch),
    });

    await change.after.ref.set(patch, { merge: true });
  });

async function buildDiscoveryDeckPayload(params: {
  uid: string;
  request: DiscoveryRequest;
  source: string;
}): Promise<Record<string, unknown>> {
  const limitRaw =
    typeof params.request.limit === "number" ? params.request.limit : 30;
  const limit = Math.min(Math.max(limitRaw, 5), 50);

  const me = await getUser(params.uid);
  const meSnapshot = buildDiscoveryUserSnapshot(
    params.uid,
    me as Record<string, unknown>,
    {
      uid: params.uid,
      source: params.source,
    },
  );
  const requesterStatus = evaluateDiscoveryEligibility(meSnapshot);
  const exclusionSets = await getDiscoveryExclusionSets(params.uid);

  const requestedShowMeGenders = normalizeDiscoveryPreferenceTokens(
    params.request.showMeGenders,
  );
  const showMeGenders =
    requestedShowMeGenders.length > 0
      ? requestedShowMeGenders
      : meSnapshot.preferences.showMeGenders;
  const minAge = Math.max(
    18,
    Math.round(
      toNumber(params.request.minAge) ?? meSnapshot.preferences.minAge,
    ),
  );
  const maxAge = Math.min(
    100,
    Math.round(
      toNumber(params.request.maxAge) ?? meSnapshot.preferences.maxAge,
    ),
  );
  const maxDistanceKm = Math.max(
    1,
    Math.round(
      toNumber(params.request.maxDistanceKm) ??
        meSnapshot.preferences.maxDistanceKm,
    ),
  );
  const requiredInterests = new Set(
    toStringArray(params.request.interests).map((interest) =>
      interest.toLowerCase(),
    ),
  );
  const requirePhotos = params.request.requirePhotos === true;
  const requireVerified = params.request.requireVerified === true;
  const requestScope = buildDiscoveryDeckRequestScope({
    uid: params.uid,
    minAge,
    maxAge,
    maxDistanceKm,
    showMeGenders,
    interests: Array.from(requiredInterests),
    requirePhotos,
    requireVerified,
    latitude: toNumber(params.request.latitude) ?? null,
    longitude: toNumber(params.request.longitude) ?? null,
  });

  const queryLimit = Math.min(
    DISCOVERY_QUERY_SCAN_LIMIT,
    Math.max(DISCOVERY_PAGE_SIZE * 4, limit * 20),
  );
  const queryPlan = buildDiscoveryCandidateQueryPlan({
    showMeGenders,
    requireVerified,
    limit: queryLimit,
  });
  const snap = await fetchDiscoveryCandidateSnapshotWithFallback({
    uid: params.uid,
    source: params.source,
    plan: queryPlan,
  });

  const candidates: DiscoveryDeckCandidate[] = [];

  snap.forEach((doc) => {
    const candidate = buildDiscoveryUserSnapshot(
      doc.id,
      doc.data() as Record<string, unknown>,
    );
    const evaluation = evaluateDiscoveryCandidateForRequester({
      requester: meSnapshot,
      candidate,
      request: {
        ...params.request,
        minAge,
        maxAge,
        maxDistanceKm,
        showMeGenders,
        interests: Array.from(requiredInterests),
        requirePhotos,
        requireVerified,
      },
      exclusionSets,
    });
    if (!evaluation.included) return;

    const score = normalizeDiscoveryDeckSortScore(evaluation.score ?? 0);
    candidates.push({
      user: candidate,
      score,
      distanceKm: evaluation.distanceKm,
      sortActivityMs: candidate.updatedAtMs ?? candidate.lastActiveMs ?? 0,
    });
  });

  candidates.sort(compareDiscoveryDeckCandidates);

  const pagination = paginateDiscoveryDeckCandidates({
    uid: params.uid,
    scope: requestScope,
    candidates,
    limit,
    cursor: params.request.cursor,
  });

  return {
    candidates: pagination.page
      .map((candidate) =>
        buildDiscoveryProfileResponse(
          candidate.user,
          candidate.score,
          candidate.distanceKm,
        ),
      ),
    total: candidates.length,
    hasMore: pagination.hasMore,
    nextCursor: pagination.nextCursor,
    requesterStatus: {
      eligible: requesterStatus.eligible,
      reasons: requesterStatus.reasons,
      summary: buildDiscoveryDebugSummary(meSnapshot),
    },
  };
}

export const fetchDiscoveryCandidates = callable<DiscoveryRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "fetch discovery candidates");
    return buildDiscoveryDeckPayload({
      uid,
      request: data ?? {},
      source: "callable:fetchDiscoveryCandidates",
    });
  },
);

export const getMyDiscoveryStatus = callable<Record<string, never>>(
  async (_data, context) => {
    const uid = requireAuth(context, "inspect discovery status");
    const me = await getUser(uid);
    const snapshot = buildDiscoveryUserSnapshot(
      uid,
      me as Record<string, unknown>,
      {
        uid,
        source: "callable:getMyDiscoveryStatus",
      },
    );
    const eligibility = evaluateDiscoveryEligibility(snapshot);

    return {
      eligible: eligibility.eligible,
      reasons: eligibility.reasons,
      summary: buildDiscoveryDebugSummary(snapshot),
    };
  },
);

// Swipe right (double opt-in + match creation)
export const swipeRight = callable<SwipeRequest>(async (data, context) => {
  const uid = requireAuth(context, "swipe right");
  requireEmailVerified(context, "swipe right");
  const targetUserId = requireString(data?.targetUserId, "targetUserId");
  const attachedMessage = optionalString(data?.attachedMessage);

  if (targetUserId === uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "You cannot like yourself.",
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
    createdAt: serverTimestamp(),
  });

  // Log swipe event (non-blocking, won't fail the operation)
  logInteractionEvent({
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
      status: "active", // Must be 'active' to match Firestore security rules
      preMatchRequests: {
        [uid]: 0,
        [targetUserId]: 0,
      },
      pinnedForUser: {
        [uid]: false,
        [targetUserId]: false,
      },
      createdAt: serverTimestamp(),
    });
    existing = await matchRef.get();
    matchId = matchRef.id;

    // Get profiles for real-time notification data
    const [myProfile, theirProfile] = await Promise.all([
      getUser(uid),
      getUser(targetUserId),
    ]);
    const myData = myProfile.profile as ProfileData | null;
    const theirData = theirProfile.profile as ProfileData | null;

    // Write to RTDB for real-time match notifications
    // Both users get notified instantly
    const matchNotification = {
      matchId: matchRef.id,
      createdAt: Date.now(),
      status: "active",
    };

    // Notify target user (they just got matched!)
    await rtdb.ref(`users/${targetUserId}/newMatches/${matchRef.id}`).set({
      ...matchNotification,
      otherUserId: uid,
      otherUserName: myData?.name ?? "Someone",
      otherUserPhotoUrl: toStringArray(myData?.photoUrls)[0] ?? null,
    });

    // Notify current user (immediate feedback in case they navigate away)
    await rtdb.ref(`users/${uid}/newMatches/${matchRef.id}`).set({
      ...matchNotification,
      otherUserId: targetUserId,
      otherUserName: theirData?.name ?? "Someone",
      otherUserPhotoUrl: toStringArray(theirData?.photoUrls)[0] ?? null,
    });
  } else {
    matchId = existing.id;
  }

  // Log match event (non-blocking, won't fail the operation)
  logInteractionEvent({
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
  requireEmailVerified(context, "swipe left");
  const targetUserId = requireString(data?.targetUserId, "targetUserId");

  if (targetUserId === uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "You cannot like yourself.",
    );
  }

  await ensureUserExists(targetUserId);
  await ensureNotBlocked(uid, targetUserId);

  const me = await getUser(uid);
  ensureProfileQuality(me.profile as ProfileData | null, "swiping");

  // Log swipe event (non-blocking, won't fail the operation)
  logInteractionEvent({
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
    requireEmailVerified(context, "send a pre-match message");
    const targetUserId = requireString(data?.targetUserId, "targetUserId");
    const content = requireString(data?.content, "content");

    if (targetUserId === uid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Cannot message yourself.",
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
        lastRequestAt: serverTimestamp(),
      });
    }

    const preData = (await preRef.get()).data()!;
    const requests = preData.requests || {};
    const myCount = (requests[uid] as number | undefined) ?? 0;

    if (myCount >= 3) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "You have reached the maximum of 3 message requests. Wait for a reply.",
      );
    }

    // Increment my counter
    requests[uid] = myCount + 1;
    await preRef.update({
      requests,
      lastRequestAt: serverTimestamp(),
    });

    // Store the request message (optional UI for receiver)
    await preRef.collection("requests").add({
      fromUserId: uid,
      toUserId: targetUserId,
      content,
      createdAt: serverTimestamp(),
    });

    return { ok: true };
  },
);

// Unsend message (Plus only, sender-only)
export const unsendMessage = callable<UnsendRequest>(async (data, context) => {
  const uid = requireAuth(context, "unsend messages");
  requireEmailVerified(context, "unsend messages");
  const matchId = requireString(data?.matchId, "matchId");
  const messageId = requireString(data?.messageId, "messageId");

  // Plan check: Plus required
  const user = await getUser(uid);
  if ((user.plan || "").toLowerCase() !== "plus") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Unsend is only available on the Plus plan.",
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
      "You can only unsend your own messages.",
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
      "You are not part of this match.",
    );
  }
  const otherUserId = userIds.find((id) => id !== uid);
  if (!otherUserId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Match participants missing.",
    );
  }
  await ensureNotBlocked(uid, otherUserId);

  // Soft delete for sender
  await msgRef.update({
    isDeletedForSender: true,
    unsentAt: serverTimestamp(),
  });

  return { ok: true };
});

// Send message (for matched users)
export const sendMessage = callable<SendMessageRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "send messages");
    requireEmailVerified(context, "send messages");
    const matchId = requireString(data?.matchId, "matchId");
    const toUserId = requireString(data?.toUserId, "toUserId");
    const content = optionalString(data?.content);
    const type = optionalString(data?.type) ?? "text";
    const mediaUrl = optionalString(data?.mediaUrl);

    // Validate content - must have content or mediaUrl
    if (!content && !mediaUrl) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Message must have content or media.",
      );
    }

    // Validate user is part of the match
    const matchSnap = await db.collection("matches").doc(matchId).get();
    if (!matchSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Match not found.");
    }

    const matchData = matchSnap.data() as FirebaseFirestore.DocumentData;
    const userIds = (matchData.userIds || []) as string[];
    if (!userIds.includes(uid)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You are not part of this match.",
      );
    }

    // Verify toUserId is the other participant
    if (!userIds.includes(toUserId)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Recipient is not part of this match.",
      );
    }

    if (toUserId === uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Cannot send message to yourself.",
      );
    }

    // Check if blocked
    await ensureNotBlocked(uid, toUserId);

    // Create the message document
    const messageRef = await db
      .collection("matches")
      .doc(matchId)
      .collection("messages")
      .add({
        matchId,
        fromUserId: uid,
        toUserId,
        content: content ?? null,
        type,
        mediaUrl: mediaUrl ?? null,
        sentAt: serverTimestamp(),
        isRead: false,
        isDeletedForSender: false,
        isDeletedForRecipient: false,
        reactions: {},
        visibleTo: [uid, toUserId],
      });

    // Update match with last message info
    await db
      .collection("matches")
      .doc(matchId)
      .update({
        lastMessageAt: serverTimestamp(),
        lastMessageContent: content ? truncateString(content, 100) : null,
        lastMessageType: type,
        lastMessageFromUserId: uid,
      });

    return {
      ok: true,
      messageId: messageRef.id,
    };
  },
);

// Mark messages as read
export const markMessagesRead = callable<MarkMessagesReadRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "mark messages as read");
    const matchId = requireString(data?.matchId, "matchId");

    // Validate user is part of the match
    const matchSnap = await db.collection("matches").doc(matchId).get();
    if (!matchSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Match not found.");
    }

    const matchData = matchSnap.data() as FirebaseFirestore.DocumentData;
    const userIds = (matchData.userIds || []) as string[];
    if (!userIds.includes(uid)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You are not part of this match.",
      );
    }

    // Get unread messages sent TO this user
    const unreadMessagesSnap = await db
      .collection("matches")
      .doc(matchId)
      .collection("messages")
      .where("toUserId", "==", uid)
      .where("isRead", "==", false)
      .get();

    if (unreadMessagesSnap.empty) {
      return { ok: true, markedCount: 0 };
    }

    // Batch update to mark as read
    const batch = db.batch();
    const readAt = serverTimestamp();

    unreadMessagesSnap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        isRead: true,
        readAt,
        readBy: uid,
      });
    });

    await batch.commit();

    // Update match read status
    await db
      .collection("matches")
      .doc(matchId)
      .update({
        [`readBy.${uid}`]: readAt,
      });

    return { ok: true, markedCount: unreadMessagesSnap.size };
  },
);

// Edit message (sender only)
export const editMessage = callable<EditMessageRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "edit messages");
    requireEmailVerified(context, "edit messages");
    const matchId = requireString(data?.matchId, "matchId");
    const messageId = requireString(data?.messageId, "messageId");
    const content = requireString(data?.content, "content");

    // Validate user is part of the match
    const matchSnap = await db.collection("matches").doc(matchId).get();
    if (!matchSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Match not found.");
    }

    const matchData = matchSnap.data() as FirebaseFirestore.DocumentData;
    const userIds = (matchData.userIds || []) as string[];
    if (!userIds.includes(uid)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You are not part of this match.",
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

    // Ownership check - only sender can edit
    if (msgData.fromUserId !== uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You can only edit your own messages.",
      );
    }

    // Update the message
    await msgRef.update({
      content,
      isEdited: true,
      editedAt: serverTimestamp(),
    });

    return { ok: true };
  },
);

// Create Stripe Checkout session for Plus plan
export const createCheckoutSession = callable<CheckoutSessionRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "start checkout");
    requireEmailVerified(context, "start checkout");
    const priceId = requireString(data?.priceId, "priceId");
    const successUrl = requireString(data?.successUrl, "successUrl");
    const cancelUrl = requireString(data?.cancelUrl, "cancelUrl");
    const stripeSecret = getStripeSecret();
    if (!stripeSecret) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Stripe not configured.",
      );
    }
    const stripe = getStripeClient(stripeSecret);

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
  },
);

// Validate a Google Play subscription purchase token and sync plan state.
export const verifyGooglePurchaseToken =
  callable<VerifyGooglePurchaseTokenRequest>(async (data, context) => {
    const uid = requireAuth(context, "verify Google Play purchase");
    requireEmailVerified(context, "verify Google Play purchase");

    return verifyGooglePurchaseTokenForUser({
      uid,
      productId: requireString(data?.productId, "productId"),
      purchaseToken: requireString(data?.purchaseToken, "purchaseToken"),
      packageName: optionalString(data?.packageName),
    });
  });

// Validate an App Store transaction and sync plan state from Apple authoritative data.
export const verifyAppleTransaction = callable<VerifyAppleTransactionRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "verify Apple purchase");
    requireEmailVerified(context, "verify Apple purchase");

    return verifyAppleTransactionForUser({
      uid,
      transactionId: requireString(data?.transactionId, "transactionId"),
      productId: optionalString(data?.productId),
    });
  },
);

// Unified mobile receipt validation entrypoint used by newer repository paths.
export const verifyPurchaseReceipt = callable<VerifyPurchaseReceiptRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "verify purchase receipt");
    requireEmailVerified(context, "verify purchase receipt");

    return verifyPurchaseReceiptForUser({
      uid,
      platform: requireString(data?.platform, "platform"),
      receiptData: requireString(data?.receiptData, "receiptData"),
      productId: optionalString(data?.productId),
      packageName: optionalString(data?.packageName),
    });
  },
);

// Handle Apple App Store Server Notifications (v2) for subscription lifecycle sync.
export const appleSubscriptionWebhook = functions.https.onRequest(
  async (req, res) => {
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    let signedPayloadCandidate: string | undefined;
    const bodyAsRecord = req.body as { signedPayload?: unknown } | null;
    if (typeof bodyAsRecord?.signedPayload === "string") {
      signedPayloadCandidate = bodyAsRecord.signedPayload;
    } else if (typeof req.body === "string") {
      const trimmedBody = req.body.trim();
      if (trimmedBody.startsWith("{")) {
        try {
          const parsed = JSON.parse(trimmedBody) as {
            signedPayload?: unknown;
          };
          if (typeof parsed.signedPayload === "string") {
            signedPayloadCandidate = parsed.signedPayload;
          }
        } catch {
          signedPayloadCandidate = undefined;
        }
      } else {
        signedPayloadCandidate = trimmedBody;
      }
    }

    const signedPayload = optionalString(signedPayloadCandidate);
    if (!signedPayload) {
      res.status(400).send("Missing Apple signed payload.");
      return;
    }

    let payload: AppleServerNotificationPayload;
    try {
      payload = decodeAppleServerNotificationPayload(signedPayload);
    } catch (err) {
      if (err instanceof functions.https.HttpsError) {
        const statusCode = err.code === "permission-denied" ? 401 : 400;
        res.status(statusCode).send(err.message);
        return;
      }
      res.status(400).send("Invalid Apple notification payload.");
      return;
    }

    const notificationType = optionalString(payload.notificationType);
    if (!notificationType) {
      res.status(400).send("Missing Apple notification type.");
      return;
    }

    const data = payload.data;
    const signedTransactionInfo = optionalString(data?.signedTransactionInfo);
    if (!signedTransactionInfo) {
      res.status(200).json({
        received: true,
        ignored: "missing_transaction_info",
        notificationType,
      });
      return;
    }

    let transaction: AppleTransactionInfoPayload;
    try {
      transaction = decodeAppleSignedTransactionInfo(signedTransactionInfo);
    } catch (err) {
      const message =
        err instanceof functions.https.HttpsError
          ? err.message
          : "Invalid Apple transaction payload.";
      res.status(400).send(message);
      return;
    }

    const configuredBundleId = optionalString(getAppleBundleId());
    if (
      configuredBundleId &&
      transaction.bundleId &&
      transaction.bundleId !== configuredBundleId
    ) {
      res.status(403).send("Apple bundle identifier mismatch.");
      return;
    }

    const userDoc = await findUserByAppleTransactionIdentifiers({
      originalTransactionId: transaction.originalTransactionId,
      latestTransactionId: transaction.transactionId,
      webOrderLineItemId: transaction.webOrderLineItemId,
    });

    if (!userDoc) {
      console.warn("apple_s2s_unknown_transaction", {
        notificationType,
        originalTransactionId: transaction.originalTransactionId ?? null,
        transactionId: transaction.transactionId ?? null,
      });
      res.status(202).json({
        received: true,
        ignored: "unknown_transaction",
        notificationType,
      });
      return;
    }

    const uid = userDoc.id;
    const nowMs = Date.now();
    const mapping = mapAppleServerNotificationType(
      notificationType,
      optionalString(payload.subtype),
    );
    const entitlement = applyAppleServerNotificationEntitlementOverride(
      deriveAppleSubscriptionEntitlement(transaction, nowMs),
      mapping,
      nowMs,
    );

    await setUserPlan(uid, entitlement.plan);

    const signedDateMs = parseAppleNotificationSignedDate(
      payload.signedDate,
      nowMs,
    );
    const purchaseDateMillis = parseAppleMillis(transaction.purchaseDate);
    const revocationDateMillis = parseAppleMillis(transaction.revocationDate);
    const environment = normalizeAppleServerEnvironment(data?.environment);
    const payloadUpdate: Record<string, unknown> = {
      applePurchase: {
        environment: environment ?? null,
        bundleId: transaction.bundleId ?? data?.bundleId ?? null,
        productId: transaction.productId ?? null,
        originalTransactionId: transaction.originalTransactionId ?? null,
        latestTransactionId: transaction.transactionId ?? null,
        webOrderLineItemId: transaction.webOrderLineItemId ?? null,
        inAppOwnershipType: transaction.inAppOwnershipType ?? null,
        transactionReason: transaction.transactionReason ?? null,
        purchaseDateMillis,
        expiresDateMillis: entitlement.expiryTimeMillis,
        revocationDateMillis,
        signedTransactionHash: hashPurchaseToken(signedTransactionInfo),
        lastNotificationType: notificationType,
        lastNotificationSubtype: optionalString(payload.subtype) ?? null,
        lastNotificationUuid: optionalString(payload.notificationUUID) ?? null,
        lastNotificationSignedDateMs: signedDateMs,
        lastValidatedAt: serverTimestamp(),
      },
      subscriptionLifecycle: {
        provider: "app_store",
        status: entitlement.status,
        currentPeriodEnd: entitlement.currentPeriodEnd,
        cancelAtPeriodEnd: entitlement.cancelAtPeriodEnd,
        lastNotificationType: notificationType,
        lastNotificationSubtype: optionalString(payload.subtype) ?? null,
        lastNotificationUuid: optionalString(payload.notificationUUID) ?? null,
        lastNotificationSignedDateMs: signedDateMs,
        lastNotificationReceivedAt: serverTimestamp(),
      },
    };

    if (entitlement.expiryTimeMillis != null) {
      payloadUpdate.subscriptionExpiresAt = new Date(
        entitlement.expiryTimeMillis,
      );
    } else if (entitlement.plan === "free") {
      payloadUpdate.subscriptionExpiresAt = deleteField();
    }

    await db.collection("users").doc(uid).set(payloadUpdate, { merge: true });

    res.status(200).json({
      received: true,
      uid,
      status: entitlement.status,
      plan: entitlement.plan,
      notificationType,
    });
  },
);

// Handle Google Real-time Developer Notifications (RTDN) for subscriptions.
export const googleRtdnWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const expectedToken = optionalString(getGoogleRtdnVerificationToken());
  if (expectedToken) {
    const queryToken = optionalString(
      typeof req.query.token === "string" ? req.query.token : undefined,
    );
    const headerToken = optionalString(req.header("x-rtdn-token"));
    const providedToken = headerToken ?? queryToken;
    if (!providedToken || providedToken !== expectedToken) {
      res.status(401).send("Unauthorized");
      return;
    }
  }

  let decoded: GoogleRtdnDecodeResult;
  try {
    decoded = decodeGoogleRtdnEnvelope(req.body);
  } catch (err) {
    const message =
      err instanceof functions.https.HttpsError
        ? err.message
        : "Invalid RTDN payload.";
    res.status(400).send(message);
    return;
  }

  const payload = decoded.payload;
  const notification = payload.subscriptionNotification;
  if (!notification) {
    res.status(200).json({ received: true, ignored: "missing_notification" });
    return;
  }

  const purchaseToken = optionalString(notification.purchaseToken);
  const productId = optionalString(notification.subscriptionId);
  const notificationType = notification.notificationType;
  const packageName =
    normalizeGooglePlayPackageName(payload.packageName) ??
    normalizeGooglePlayPackageName(getGooglePlayPackageName());

  if (
    !packageName ||
    !purchaseToken ||
    !productId ||
    notificationType == null
  ) {
    res.status(400).send("Invalid RTDN subscription payload.");
    return;
  }

  const purchaseTokenHash = hashPurchaseToken(purchaseToken);
  const userSnap = await db
    .collection("users")
    .where("googlePlayPurchase.purchaseTokenHash", "==", purchaseTokenHash)
    .limit(1)
    .get();

  if (userSnap.empty) {
    console.warn("google_rtdn_unknown_token", {
      messageId: decoded.messageId,
      notificationType,
      productId,
    });
    res.status(202).json({ received: true, ignored: "unknown_purchase_token" });
    return;
  }

  const uid = userSnap.docs[0].id;
  const nowMs = Date.now();
  const mapping = mapGoogleRtdnNotificationType(notificationType);
  let entitlement: GoogleSubscriptionEntitlement;
  let validation: GoogleSubscriptionPurchaseResponse | null = null;

  try {
    validation = await fetchGoogleSubscriptionValidation({
      packageName,
      productId,
      purchaseToken,
    });
    entitlement = applyGoogleRtdnEntitlementOverride(
      deriveGoogleSubscriptionEntitlement(validation, nowMs),
      mapping,
      nowMs,
    );
  } catch (err) {
    const isNotFoundErr =
      err instanceof functions.https.HttpsError && err.code === "not-found";
    if (!isNotFoundErr || !mapping.forceFree) {
      const message = err instanceof Error ? err.message : String(err);
      console.error("google_rtdn_validation_failed", {
        uid,
        notificationType,
        message,
      });
      res.status(500).send("RTDN validation failed");
      return;
    }

    entitlement = {
      plan: "free",
      status: mapping.status,
      cancelAtPeriodEnd: false,
      currentPeriodEnd: null,
      expiryTimeMillis: null,
    };
  }

  await setUserPlan(uid, entitlement.plan);

  const payloadUpdate: Record<string, unknown> = {
    googlePlayPurchase: {
      packageName,
      productId,
      purchaseTokenHash,
      orderId: validation?.orderId ?? null,
      linkedPurchaseToken: validation?.linkedPurchaseToken ?? null,
      paymentState:
        typeof validation?.paymentState === "number"
          ? validation.paymentState
          : null,
      acknowledgementState:
        typeof validation?.acknowledgementState === "number"
          ? validation.acknowledgementState
          : null,
      autoRenewing:
        typeof validation?.autoRenewing === "boolean"
          ? validation.autoRenewing
          : null,
      cancelReason:
        typeof validation?.cancelReason === "number"
          ? validation.cancelReason
          : null,
      expiryTimeMillis: entitlement.expiryTimeMillis,
      lastRtdnType: notificationType,
      lastRtdnMessageId: decoded.messageId ?? null,
      lastRtdnEventAt: serverTimestamp(),
    },
    subscriptionLifecycle: {
      provider: "google_play",
      status: entitlement.status,
      currentPeriodEnd: entitlement.currentPeriodEnd,
      cancelAtPeriodEnd: entitlement.cancelAtPeriodEnd,
      lastRtdnType: notificationType,
      lastRtdnEventTime: parseGoogleRtdnEventTime(
        payload.eventTimeMillis,
        nowMs,
      ),
      lastRtdnUpdatedAt: serverTimestamp(),
    },
  };

  if (entitlement.expiryTimeMillis != null) {
    payloadUpdate.subscriptionExpiresAt = new Date(
      entitlement.expiryTimeMillis,
    );
  } else if (entitlement.plan === "free") {
    payloadUpdate.subscriptionExpiresAt = deleteField();
  }

  await db.collection("users").doc(uid).set(payloadUpdate, { merge: true });

  res.status(200).json({
    received: true,
    uid,
    status: entitlement.status,
    plan: entitlement.plan,
  });
});

export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  // Basic CORS handling for browser preflight and requests
  if (req.method === "OPTIONS") {
    setCorsHeaders(res, req);
    res.status(204).send("");
    return;
  }

  setCorsHeaders(res, req);

  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const stripe = getStripeClient(getStripeSecret());
  const stripeWebhookSecret = getStripeWebhookSecret();
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
      stripeWebhookSecret,
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
          status === "active" || status === "trialing" || status === "past_due";
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
  const stripeSecret = getStripeSecret();
  if (!stripeSecret) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Stripe not configured.",
    );
  }
  const stripe = getStripeClient(stripeSecret);
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
      "Could not verify subscription.",
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
  clearExpressRateLimitStore: () => rateLimitStore.clear(),
  setUploadValidationTestOverrides,
  resetUploadValidationTestOverrides,
  evaluateCallableAppCheck,
  parseChatMessagesBeforeCursor,
  parseBeforeTimestampCursor,
  stripHtml,
  validateMessageContent,
  validateProfileName,
  validateBio,
  userRelationDeletionTargets,
  userStorageDeletionPrefixes,
  matchMembershipFields: () => MATCH_MEMBERSHIP_FIELDS,
  messageRequestParticipantFields: () => MESSAGE_REQUEST_PARTICIPANT_FIELDS,
  requireAuth,
  requireString,
  optionalString,
  getRestAppCheckToken,
  evaluateRestAppCheck,
  inferReportCategoryFromReason,
  canonicalizeSafetyReportReason,
  getRestClientIp,
  safetyAuditOutcomeFromStatusCode,
  logSafetyRestAudit,
  validateSafetyTargetId,
  assertNotSelfSafetyAction,
  validateSafetyReportReason,
  validateOptionalSafetyDescription,
  validateProfilePatchPayload,
  validateProfilePreferencesPayload,
  getCanonicalProfilePreferences,
  normalizeNotificationPrefs,
  isNotificationCategoryAllowed,
  isInQuietHours,
  profileBirthDateIso,
  deriveProfileAge,
  profilePromptAnswers,
  normalizeProfileGender,
  normalizeDiscoveryPreferenceTokens,
  buildDiscoveryUserSnapshot,
  evaluateDiscoveryEligibility,
  buildDiscoveryDebugSummary,
  buildLegacyDiscoveryMirrorPatch,
  buildDiscoveryExclusionSetsFromRecords,
  evaluateDiscoveryCandidateForRequester,
  buildDiscoveryDeckRequestScope,
  encodeDiscoveryDeckCursor,
  decodeDiscoveryDeckCursor,
  paginateDiscoveryDeckCandidates,
  buildDiscoveryCandidateQueryPlan,
  buildDiscoveryDeckPayload,
  evaluateProfileCompleteness,
  ensureProfileQuality,
  normalizeGooglePlayPackageName,
  normalizePurchaseValidationPlatform,
  hashPurchaseToken,
  normalizeApplePrivateKey,
  verifyAppleSignedPayloadSignature,
  decodeAppleServerNotificationPayload,
  mapAppleServerNotificationType,
  applyAppleServerNotificationEntitlementOverride,
  parseAppleNotificationSignedDate,
  buildAppleTransactionLookupUrl,
  createAppleServerAuthToken,
  decodeAppleSignedTransactionInfo,
  fetchAppleTransactionValidation,
  deriveAppleSubscriptionEntitlement,
  buildGoogleSubscriptionValidationUrl,
  fetchGoogleSubscriptionValidation,
  deriveGoogleSubscriptionEntitlement,
  verifyPurchaseReceiptForUser,
  mapGoogleRtdnNotificationType,
  applyGoogleRtdnEntitlementOverride,
  decodeGoogleRtdnEnvelope,
  parseGoogleRtdnEventTime,
  ...__callSignalingTestHelpers,
};

export const initiateCall = initiateCallSignaling;
export const answerCall = answerCallSignaling;
export const endCall = endCallSignaling;
export const addIceCandidate = addIceCandidateSignaling;
export const getIceServers = getIceServersSignaling;
export const enforceCallRingTimeout = enforceCallRingTimeoutSignaling;
export const notifyCallSafetyEvent = notifyCallSafetyEventSignaling;

// Callable function to generate an Agora token for authenticated users
export const generateAgoraToken = callable<AgoraTokenRequest>(
  async (data, context) => {
    requireAuth(context, "start a call");

    const channelName = requireString(data?.channelName, "channelName");
    const uid = typeof data?.uid === "number" ? data.uid : 0;
    const agoraAppId = getAgoraAppId();
    const agoraCertificate = getAgoraCertificate();

    if (!agoraAppId || !agoraCertificate) {
      throw new functions.https.HttpsError(
        "internal",
        "Agora credentials not configured",
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
      privilegeExpireTime,
    );

    return {
      token,
      appId: agoraAppId,
      channelName,
      uid,
      expireTime: privilegeExpireTime,
    };
  },
);

// Callable function to return an Agora token for a call (uses auth UID)
export const getAgoraToken = callable<AgoraTokenRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "get an Agora token");

    const channelName = requireString(data?.channelName, "channelName");
    const isVideoCall = (data?.isVideoCall as boolean | undefined) ?? true;
    const agoraAppId = getAgoraAppId();
    const agoraCertificate = getAgoraCertificate();

    if (!agoraAppId || !agoraCertificate) {
      throw new functions.https.HttpsError(
        "internal",
        "Agora credentials not configured",
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
      privilegeExpiredTs,
    );

    return {
      token,
      uid: agoraUid,
      appId: agoraAppId,
      isVideoCall,
    };
  },
);

// Profile completeness check
interface ProfileCompletenessRequest {
  minimum?: "swipe" | "messaging";
}

export const checkProfileCompleteness = callable<ProfileCompletenessRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "check profile completeness");
    const minimum = (data?.minimum as string) ?? "swipe";

    const user = await getUser(uid);
    const profile = (user as unknown as { profile?: ProfileData }).profile;

    const normalizedProfile = (profile ?? {}) as Record<string, unknown>;
    const photos = toStringArray(profile?.photoUrls);
    const prompts = profilePromptAnswers(normalizedProfile);
    const interests = toStringArray(profile?.interests);
    const bio =
      typeof profile?.bio === "string" ? (profile.bio as string).trim() : "";
    const country = typeof profile?.country === "string" ? profile.country : "";
    const city = typeof profile?.city === "string" ? profile.city : "";

    // Calculate breakdown scores (0.0-1.0 normalized, matching client-side)
    // Required: 1 photo, 10 char bio, 3 interests, city + country
    // Prompts are optional (recommended only)
    // Weights: photos 30%, bio 25%, interests 25%, location 20%
    const weights = {
      photos: 0.3,
      bio: 0.25,
      interests: 0.25,
      location: 0.2,
    };

    const photoRatio = Math.min(1.0, photos.length / PROFILE_MIN_PHOTOS);
    const bioRatio = Math.min(1.0, bio.length / PROFILE_MIN_BIO_LENGTH);
    const interestsRatio = Math.min(
      1.0,
      interests.length / PROFILE_MIN_INTERESTS,
    );
    const locationRatio = city && country ? 1.0 : 0.0;
    const promptsRatio = prompts.length > 0 ? 1.0 : 0.0; // Just for tracking

    // Breakdown stores weighted scores (matching client-side format)
    const breakdown: Record<string, number> = {
      photos: photoRatio * weights.photos,
      bio: bioRatio * weights.bio,
      interests: interestsRatio * weights.interests,
      location: locationRatio * weights.location,
      prompts: promptsRatio, // Not weighted, just for tracking
    };

    // Calculate overall score (0.0-1.0, sum of weighted components)
    const score =
      breakdown.photos +
      breakdown.bio +
      breakdown.interests +
      breakdown.location;

    // Build missing list
    const missing: string[] = [];
    const requiredMissing: string[] = [];

    if (photos.length < PROFILE_MIN_PHOTOS) {
      const msg = `Add at least ${PROFILE_MIN_PHOTOS} photo.`;
      missing.push(msg);
      requiredMissing.push(msg);
    }
    if (bio.length < PROFILE_MIN_BIO_LENGTH) {
      const msg = `Write a bio (at least ${PROFILE_MIN_BIO_LENGTH} characters).`;
      missing.push(msg);
      requiredMissing.push(msg);
    }
    if (interests.length < PROFILE_MIN_INTERESTS) {
      const msg = `Add at least ${PROFILE_MIN_INTERESTS} interests.`;
      missing.push(msg);
      requiredMissing.push(msg);
    }
    if (!city || !country) {
      const msg = "Add your city and country.";
      missing.push(msg);
      requiredMissing.push(msg);
    }
    // Prompts are optional - just a recommendation
    if (prompts.length < 2) {
      missing.push("Answer prompts to stand out (optional).");
    }

    // Thresholds - must complete all required fields (1.0 = 100%)
    const swipeThreshold = 1.0;
    const messagingThreshold = 1.0;

    const meetsSwipeMinimum = score >= swipeThreshold;
    const meetsMessagingMinimum = score >= messagingThreshold;
    const meetsRequiredFields = requiredMissing.length === 0;
    const threshold =
      minimum === "messaging" ? messagingThreshold : swipeThreshold;
    const meetsMinimum =
      minimum === "messaging" ? meetsMessagingMinimum : meetsSwipeMinimum;

    return {
      score,
      breakdown,
      missing,
      requiredMissing,
      meetsSwipeMinimum,
      meetsMessagingMinimum,
      meetsRequiredFields,
      meetsMinimum: meetsMinimum && meetsRequiredFields,
      minimum,
      threshold,
    };
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// REST API
// ═══════════════════════════════════════════════════════════════════════════

const app = express();
const PROFILE_PHOTO_MAX_BYTES = 10 * 1024 * 1024; // 10MB
const PROFILE_PHOTO_ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
]);
const PROFILE_PHOTO_EXTENSION_BY_MIME: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heif",
};
type ChatMediaUploadKind = "image" | "video" | "audio";
const CHAT_MEDIA_MAX_BYTES_BY_KIND: Record<ChatMediaUploadKind, number> = {
  image: 25 * 1024 * 1024,
  video: 100 * 1024 * 1024,
  audio: 25 * 1024 * 1024,
};
const CHAT_MEDIA_ALLOWED_MIME_TYPES_BY_KIND: Record<
  ChatMediaUploadKind,
  Set<string>
> = {
  image: new Set([
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "image/heic",
    "image/heif",
  ]),
  video: new Set([
    "video/mp4",
    "video/quicktime",
    "video/x-msvideo",
    "video/webm",
  ]),
  audio: new Set([
    "audio/mpeg",
    "audio/mp4",
    "audio/aac",
    "audio/wav",
    "audio/ogg",
  ]),
};
const CHAT_MEDIA_EXTENSION_BY_MIME: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/gif": "gif",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heif",
  "video/mp4": "mp4",
  "video/quicktime": "mov",
  "video/x-msvideo": "avi",
  "video/webm": "webm",
  "audio/mpeg": "mp3",
  "audio/mp4": "m4a",
  "audio/aac": "aac",
  "audio/wav": "wav",
  "audio/ogg": "ogg",
};
const CHAT_MEDIA_MAX_BYTES = Math.max(
  ...Object.values(CHAT_MEDIA_MAX_BYTES_BY_KIND),
);
const profilePhotoUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: PROFILE_PHOTO_MAX_BYTES },
});
const chatMediaUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: CHAT_MEDIA_MAX_BYTES },
});

type FileTypeDetectionResult = { mime: string; ext: string };
type FileTypeDetector = (
  buffer: Buffer,
) => Promise<FileTypeDetectionResult | undefined>;
type SafeSearchDetector = (
  buffer: Buffer,
) => Promise<Array<{ safeSearchAnnotation?: unknown }>>;
type FaceDetectionDetector = (
  buffer: Buffer,
) => Promise<Array<{ faceAnnotations?: unknown[] | null }>>;

let detectFileTypeFromBuffer: FileTypeDetector = async (buffer) =>
  fileType.fromBuffer(buffer);
let safeSearchImageContent: SafeSearchDetector = async (buffer) =>
  visionClient.safeSearchDetection(buffer);
let detectImageFaces: FaceDetectionDetector = async (buffer) =>
  visionClient.faceDetection(buffer);

function setUploadValidationTestOverrides(overrides: {
  detectFileTypeFromBuffer?: FileTypeDetector;
  safeSearchImageContent?: SafeSearchDetector;
  detectImageFaces?: FaceDetectionDetector;
}): void {
  if (overrides.detectFileTypeFromBuffer) {
    detectFileTypeFromBuffer = overrides.detectFileTypeFromBuffer;
  }
  if (overrides.safeSearchImageContent) {
    safeSearchImageContent = overrides.safeSearchImageContent;
  }
  if (overrides.detectImageFaces) {
    detectImageFaces = overrides.detectImageFaces;
  }
}

function resetUploadValidationTestOverrides(): void {
  detectFileTypeFromBuffer = async (buffer) => fileType.fromBuffer(buffer);
  safeSearchImageContent = async (buffer) =>
    visionClient.safeSearchDetection(buffer);
  detectImageFaces = async (buffer) => visionClient.faceDetection(buffer);
}

class UploadValidationError extends Error {
  constructor(
    readonly statusCode: number,
    message: string,
  ) {
    super(message);
    this.name = "UploadValidationError";
  }
}

function profilePhotoUploadMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  profilePhotoUpload.single("photo")(req, res, (err: unknown) => {
    if (!err) {
      next();
      return;
    }

    if (err instanceof multer.MulterError && err.code === "LIMIT_FILE_SIZE") {
      res.status(413).json({
        error: `Photo exceeds maximum size of ${Math.round(PROFILE_PHOTO_MAX_BYTES / (1024 * 1024))}MB.`,
      });
      return;
    }

    console.error("Profile photo upload middleware error:", err);
    res.status(400).json({ error: "Invalid photo upload payload." });
  });
}

function chatMediaUploadMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  chatMediaUpload.single("media")(req, res, (err: unknown) => {
    if (!err) {
      next();
      return;
    }

    if (err instanceof multer.MulterError && err.code === "LIMIT_FILE_SIZE") {
      res.status(413).json({
        error: `Media exceeds maximum size of ${Math.round(CHAT_MEDIA_MAX_BYTES / (1024 * 1024))}MB.`,
      });
      return;
    }

    console.error("Chat media upload middleware error:", err);
    res.status(400).json({ error: "Invalid media upload payload." });
  });
}

function normalizeUploadedMimeType(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  if (!normalized) return null;

  switch (normalized) {
    case "image/jpg":
      return "image/jpeg";
    case "image/x-png":
      return "image/png";
    case "audio/x-wav":
    case "audio/vnd.wave":
      return "audio/wav";
    case "audio/x-m4a":
      return "audio/mp4";
    default:
      return normalized;
  }
}

function bytesToMb(bytes: number): number {
  return Math.round(bytes / (1024 * 1024));
}

function allowedMimeTypesMessage(allowedMimeTypes: Set<string>): string {
  return Array.from(allowedMimeTypes).sort().join(", ");
}

function parseChatMediaUploadKind(value: unknown): ChatMediaUploadKind | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  switch (normalized) {
    case "image":
      return "image";
    case "video":
      return "video";
    case "audio":
    case "voice":
      return "audio";
    default:
      return null;
  }
}

async function validateBinaryUpload(params: {
  file: Express.Multer.File | undefined;
  fieldLabel: string;
  maxBytes: number;
  allowedMimeTypes: Set<string>;
  extensionByMime: Record<string, string>;
  unsupportedTypeMessage: string;
}): Promise<{
  mimeType: string;
  extension: string;
  sizeBytes: number;
}> {
  const { file } = params;
  if (!file) {
    throw new UploadValidationError(400, "No file uploaded");
  }

  const sizeBytes =
    typeof file.size === "number" ? file.size : file.buffer?.length ?? 0;
  if (!Buffer.isBuffer(file.buffer) || file.buffer.length === 0 || sizeBytes <= 0) {
    throw new UploadValidationError(
      400,
      `${params.fieldLabel} upload payload is empty.`,
    );
  }

  if (sizeBytes > params.maxBytes) {
    throw new UploadValidationError(
      413,
      `${params.fieldLabel} exceeds maximum size of ${bytesToMb(params.maxBytes)}MB.`,
    );
  }

  const claimedMimeType = normalizeUploadedMimeType(file.mimetype);
  if (
    !claimedMimeType ||
    !params.allowedMimeTypes.has(claimedMimeType)
  ) {
    throw new UploadValidationError(415, params.unsupportedTypeMessage);
  }

  const detectedType = await detectFileTypeFromBuffer(file.buffer);
  const detectedMimeType = normalizeUploadedMimeType(detectedType?.mime);
  if (
    !detectedMimeType ||
    !params.allowedMimeTypes.has(detectedMimeType)
  ) {
    throw new UploadValidationError(
      415,
      "Invalid file magic bytes. File appears to be spoofed or unsupported.",
    );
  }

  const extension = params.extensionByMime[detectedMimeType];
  if (!extension) {
    throw new UploadValidationError(415, params.unsupportedTypeMessage);
  }

  return {
    mimeType: detectedMimeType,
    extension,
    sizeBytes,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// IN-MEMORY RATE LIMITER FOR EXPRESS ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const rateLimitStore = new Map<string, RateLimitEntry>();

// Clean up expired entries every 5 minutes
setInterval(
  () => {
    const now = Date.now();
    for (const [key, entry] of rateLimitStore) {
      if (entry.resetAt <= now) rateLimitStore.delete(key);
    }
  },
  5 * 60 * 1000,
);

/**
 * Creates an Express rate-limiting middleware.
 * @param maxRequests Maximum requests allowed in the window.
 * @param windowMs Time window in milliseconds.
 * @param keyFn Function to extract rate-limit key from request (defaults to UID or IP).
 */
function createRateLimiter(
  maxRequests: number,
  windowMs: number,
  keyFn?: (req: Request) => string,
) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const authReq = req as AuthRequest;
    const key = keyFn ? keyFn(req) : authReq.uid || req.ip || "unknown";
    const bucketKey = `${req.path}:${key}`;
    const now = Date.now();

    let entry = rateLimitStore.get(bucketKey);
    if (!entry || entry.resetAt <= now) {
      entry = { count: 0, resetAt: now + windowMs };
      rateLimitStore.set(bucketKey, entry);
    }

    entry.count += 1;

    if (entry.count > maxRequests) {
      const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
      res.set("Retry-After", String(retryAfter));
      res.status(429).json({
        error: "Too many requests. Please try again later.",
        retryAfter,
      });
      return;
    }

    next();
  };
}

// Pre-configured rate limiters for different endpoint categories
const rateLimitSwipe = createRateLimiter(100, 60 * 60 * 1000); // 100/hour
const rateLimitMessage = createRateLimiter(60, 60 * 1000); // 60/minute
const rateLimitReport = createRateLimiter(10, 60 * 60 * 1000); // 10/hour
const rateLimitBlock = createRateLimiter(BLOCK_LIMIT, BLOCK_WINDOW_MS); // 20/hour
const rateLimitDiscovery = createRateLimiter(30, 60 * 60 * 1000); // 30/hour
const rateLimitAuth = createRateLimiter(20, 10 * 60 * 1000); // 20/10min
const rateLimitDefault = createRateLimiter(60, 60 * 1000); // 60/minute

// Middleware - use CORS whitelist for security
app.use(cors({ origin: corsOriginValidator }));
app.use(express.json());

// Auth middleware
interface AuthRequest extends Request {
  uid?: string;
  user?: admin.auth.DecodedIdToken;
}

async function authMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing authorization header" });
    return;
  }

  const token = authHeader.split("Bearer ")[1];
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.uid = decoded.uid;
    req.user = decoded;
    next();
  } catch (err) {
    console.error("Auth error:", err);
    res.status(401).json({ error: "Invalid or expired token" });
  }
}

/**
 * Email verification middleware for Express write endpoints.
 * Mirrors the callable `requireEmailVerified()` logic:
 * - Phone-auth users exempt (no email)
 * - Apple/Google users inherently verified
 * - Email/password users must have email_verified
 */
async function requireVerifiedEmail(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const token = req.user;
  if (!token) {
    res.status(401).json({ error: "Authentication required" });
    return;
  }

  const provider = token.firebase?.sign_in_provider;
  // Phone, Apple, Google users are exempt
  if (
    provider === "phone" ||
    provider === "apple.com" ||
    provider === "google.com"
  ) {
    next();
    return;
  }

  // Email/password users must be verified
  if (token.email && !token.email_verified) {
    res.status(403).json({ error: "Email verification required" });
    return;
  }

  next();
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Send OTP
app.post(
  "/v1/auth/otp/send",
  appCheckRestMiddleware("auth.otp.send"),
  rateLimitAuth,
  async (req: Request, res: Response) => {
    try {
      const { phone_number } = req.body;
      if (!phone_number) {
        return res.status(400).json({ error: "Phone number is required" });
      }

      // Generate and store OTP
      const otp = String(Math.floor(100000 + Math.random() * 900000));
      const verificationId = crypto.randomUUID();
      const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

      await db
        .collection("phone_verifications")
        .doc(verificationId)
        .set({
          phoneNumber: phone_number,
          otp: await bcrypt.hash(otp, 10),
          expiresAt,
          verified: false,
          createdAt: serverTimestamp(),
        });

      // In production, send SMS. For now, log it.
      console.log(`OTP for ${phone_number}: ${otp}`);

      res.json({
        success: true,
        verification_id: verificationId,
        message: "OTP sent successfully",
      });
    } catch (err) {
      console.error("Send OTP error:", err);
      return res.status(500).json({ error: "Failed to send OTP" });
    }
  },
);

// Verify OTP
app.post(
  "/v1/auth/otp/verify",
  appCheckRestMiddleware("auth.otp.verify"),
  rateLimitAuth,
  async (req: Request, res: Response) => {
    try {
      const { phone_number, otp, verification_id } = req.body;
      if (!phone_number || !otp) {
        return res.status(400).json({ error: "Phone number and OTP required" });
      }

      // Find verification
      let verificationDoc;
      if (verification_id) {
        verificationDoc = await db
          .collection("phone_verifications")
          .doc(verification_id)
          .get();
      } else {
        const query = await db
          .collection("phone_verifications")
          .where("phoneNumber", "==", phone_number)
          .where("verified", "==", false)
          .orderBy("createdAt", "desc")
          .limit(1)
          .get();
        verificationDoc = query.docs[0];
      }

      if (!verificationDoc?.exists) {
        return res.status(400).json({ error: "Invalid verification" });
      }

      const verification = verificationDoc.data();
      if (!verification || verification.expiresAt < Date.now()) {
        return res.status(400).json({ error: "OTP expired" });
      }

      const otpValid = await bcrypt.compare(otp, verification.otp);
      if (!otpValid) {
        return res.status(400).json({ error: "Invalid OTP" });
      }

      // Mark as verified
      await verificationDoc.ref.update({ verified: true });

      // Find or create user
      let user;
      try {
        user = await admin.auth().getUserByPhoneNumber(phone_number);
      } catch {
        user = await admin.auth().createUser({
          phoneNumber: phone_number,
        });
        // Create user document
        await db.collection("users").doc(user.uid).set({
          phoneNumber: phone_number,
          createdAt: serverTimestamp(),
          plan: "free",
        });
      }

      // Generate custom token
      const customToken = await admin.auth().createCustomToken(user.uid);

      // Get user data
      const userDoc = await db.collection("users").doc(user.uid).get();
      const userData = userDoc.data() || {};

      res.json({
        success: true,
        message: "Phone verified successfully",
        user: {
          id: user.uid,
          phone_number: user.phoneNumber,
          email: user.email,
          username: userData.username,
          is_email_verified: user.emailVerified,
          is_phone_verified: true,
          is_id_verified: userData.idVerified || false,
          is_premium: userData.plan === "plus",
        },
        tokens: {
          access_token: customToken,
          refresh_token: customToken, // Use same token for simplicity
          expires_in: 3600,
        },
      });
    } catch (err) {
      console.error("Verify OTP error:", err);
      return res.status(500).json({ error: "Failed to verify OTP" });
    }
  },
);

// Refresh token
app.post(
  "/v1/auth/token/refresh",
  appCheckRestMiddleware("auth.token.refresh"),
  async (req: Request, res: Response) => {
    try {
      const { refresh_token } = req.body;
      if (!refresh_token) {
        return res.status(400).json({ error: "Refresh token required" });
      }

      // Verify the token
      const decoded = await admin.auth().verifyIdToken(refresh_token);
      const newToken = await admin.auth().createCustomToken(decoded.uid);

      res.json({
        access_token: newToken,
        refresh_token: newToken,
        expires_in: 3600,
      });
    } catch (err) {
      console.error("Refresh token error:", err);
      return res.status(401).json({ error: "Invalid refresh token" });
    }
  },
);

// Logout
app.post(
  "/v1/auth/logout",
  appCheckRestMiddleware("auth.logout"),
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      // Revoke refresh tokens
      await admin.auth().revokeRefreshTokens(req.uid!);
      res.json({ success: true });
    } catch (err) {
      console.error("Logout error:", err);
      return res.status(500).json({ error: "Failed to logout" });
    }
  },
);

// Change password
app.post(
  "/v1/auth/password/change",
  appCheckRestMiddleware("auth.password.change"),
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const uid = req.uid!;
      const currentPassword =
        typeof req.body?.current_password === "string"
          ? req.body.current_password
          : typeof req.body?.currentPassword === "string"
            ? req.body.currentPassword
            : "";
      const newPassword =
        typeof req.body?.new_password === "string"
          ? req.body.new_password
          : typeof req.body?.newPassword === "string"
            ? req.body.newPassword
            : "";

      if (!currentPassword) {
        return res.status(400).json({ error: "Current password is required." });
      }

      if (newPassword.length < PASSWORD_MIN_LENGTH) {
        return res.status(400).json({
          error: `New password must be at least ${PASSWORD_MIN_LENGTH} characters.`,
        });
      }

      const ip =
        (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ||
        req.socket?.remoteAddress ||
        undefined;
      const userAgent = req.headers["user-agent"]?.toString() ?? undefined;

      // Rate limiting
      const ipLimit = ip
        ? await applyRateLimit(
            `change_password:ip:${ip}`,
            LOGIN_ATTEMPT_LIMIT,
            LOGIN_ATTEMPT_WINDOW_MS,
            LOGIN_ATTEMPT_BLOCK_MS,
          )
        : { allowed: true };
      const idLimit = await applyRateLimit(
        `change_password:uid:${uid}`,
        LOGIN_ATTEMPT_LIMIT,
        LOGIN_ATTEMPT_WINDOW_MS,
        LOGIN_ATTEMPT_BLOCK_MS,
      );

      if (!ipLimit.allowed || !idLimit.allowed) {
        await logAuthAudit({
          action: "change_password",
          status: "blocked",
          uid,
          ip,
          userAgent,
        });
        const retryMs = ipLimit.retryAfterMs || idLimit.retryAfterMs;
        return res.status(429).json({
          error: "Too many attempts. Please try again later.",
          retryAfterMs: retryMs,
        });
      }

      // Verify current password
      const passwordHash = await getPasswordHash(uid);
      if (!passwordHash) {
        await logAuthAudit({
          action: "change_password",
          status: "error",
          uid,
          ip,
          userAgent,
          metadata: { reason: "no_password_set" },
        });
        return res
          .status(400)
          .json({ error: "No password set for this account." });
      }

      const isValid = await verifyPassword(currentPassword, passwordHash);
      if (!isValid) {
        await logAuthAudit({
          action: "change_password",
          status: "invalid",
          uid,
          ip,
          userAgent,
        });
        return res
          .status(400)
          .json({ error: "Current password is incorrect." });
      }

      // Set new password
      await setPasswordHash(uid, newPassword);

      // Revoke existing sessions
      await admin.auth().revokeRefreshTokens(uid);

      // Get user's email for notification
      const userDoc = await db.collection("users").doc(uid).get();
      const userEmail =
        userDoc.data()?.emailLower || userDoc.data()?.email || null;

      // Send password changed email notification
      if (userEmail) {
        sendPasswordChangedEmail({
          to: userEmail,
          method: "in_app",
        }).catch((err) =>
          console.error("Failed to send password changed email:", err),
        );
      }

      await logAuthAudit({
        action: "change_password",
        status: "ok",
        uid,
        ip,
        userAgent,
      });

      res.json({ success: true, message: "Password changed successfully." });
    } catch (err) {
      console.error("Change password error:", err);
      return res.status(500).json({ error: "Failed to change password." });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get current user profile
app.get(
  "/v1/profile/me",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const userDoc = await db.collection("users").doc(req.uid!).get();
      if (!userDoc.exists) {
        return res.status(404).json({ error: "User not found" });
      }

      const data = userDoc.data() || {};
      const profile = data.profile || {};
      const preferences = getCanonicalProfilePreferences(data, {
        uid: req.uid,
        source: "rest:/v1/profile/me",
      });
      const username =
        (typeof data.username === "string" && data.username.trim()) ||
        (typeof profile.username === "string" && profile.username.trim()) ||
        (typeof data.usernameLower === "string" && data.usernameLower.trim()) ||
        null;

      res.json({
        id: req.uid,
        username,
        phone_number: data.phoneNumber,
        email: data.email,
        email_verified: data.emailVerified || false,
        phone_verified: true,
        is_premium: data.plan === "plus",
        display_name: profile.name || profile.displayName,
        bio: profile.bio,
        birth_date: profileBirthDateIso(profile as Record<string, unknown>),
        gender: profile.gender,
        job_title: profile.jobTitle,
        company: profile.company,
        education: profile.education || profile.school,
        city: profile.city,
        country: profile.country,
        photos: (profile.photoUrls || []).map((url: string, i: number) => ({
          id: `photo_${i}`,
          url,
          is_primary: i === 0,
          order: i,
        })),
        interests: profile.interests || [],
        prompts: profilePromptAnswers(profile as Record<string, unknown>),
        preferences,
      });
    } catch (err) {
      console.error("Get profile error:", err);
      return res.status(500).json({ error: "Failed to get profile" });
    }
  },
);

// Update profile
app.patch(
  "/v1/profile/me",
  authMiddleware,
  requireVerifiedEmail,
  async (req: AuthRequest, res: Response) => {
    try {
      const updates = validateProfilePatchPayload(req.body);
      updates["profile.updatedAt"] = serverTimestamp();
      updates.updatedAt = serverTimestamp();

      await db.collection("users").doc(req.uid!).update(updates);

      res.json({ success: true, message: "Profile updated" });
    } catch (err) {
      console.error("Update profile error:", err);
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      const firestoreCode = (err as { code?: unknown })?.code;
      if (firestoreCode === 5 || firestoreCode === "not-found") {
        return res
          .status(404)
          .json({ error: "User not found", code: "not-found" });
      }
      return res.status(500).json({ error: "Failed to update profile" });
    }
  },
);

// Upload photo
app.post(
  "/v1/profile/photos",
  authMiddleware,
  requireVerifiedEmail,
  profilePhotoUploadMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const isPrimary = req.body.is_primary === "true";
      const userRef = db.collection("users").doc(req.uid!);
      const userDoc = await userRef.get();
      if (!userDoc.exists) {
        return res.status(404).json({ error: "User not found" });
      }

      const validatedUpload = await validateBinaryUpload({
        file: req.file,
        fieldLabel: "Photo",
        maxBytes: PROFILE_PHOTO_MAX_BYTES,
        allowedMimeTypes: PROFILE_PHOTO_ALLOWED_MIME_TYPES,
        extensionByMime: PROFILE_PHOTO_EXTENSION_BY_MIME,
        unsupportedTypeMessage: `Unsupported photo type. Allowed types: ${allowedMimeTypesMessage(PROFILE_PHOTO_ALLOWED_MIME_TYPES)}.`,
      });

      // Google Cloud Vision Moderation
      try {
        const [result] = await safeSearchImageContent(req.file!.buffer);
        const detections =
          result.safeSearchAnnotation &&
          typeof result.safeSearchAnnotation === "object"
            ? (result.safeSearchAnnotation as Record<string, unknown>)
            : null;
        if (detections) {
          const likelihoodValues = [
            detections.adult,
            detections.violence,
            detections.medical,
            detections.spoof,
          ].map((likelihood) =>
            typeof likelihood === "string" ? likelihood : null,
          );
          const isExplicit = likelihoodValues.some(
            (likelihood) =>
              likelihood === "LIKELY" || likelihood === "VERY_LIKELY",
          );
          if (isExplicit) {
            return res.status(400).json({
              error: "Image rejected by moderation filter.",
            });
          }
        }

        // Face Detection for primary photos
        if (isPrimary) {
          const [faceResult] = await detectImageFaces(req.file!.buffer);
          const faces = faceResult.faceAnnotations;
          if (!faces || faces.length === 0) {
            return res.status(400).json({
              error: "Primary photo must contain at least one visible face.",
            });
          }
        }
      } catch (visionError) {
        console.error("Cloud Vision Error:", visionError);
        return res.status(500).json({
          error: "Failed to process image moderation.",
        });
      }

      const bucket = admin.storage().bucket();
      const fileName = `photos/${req.uid}/${Date.now()}_${crypto.randomUUID()}.${validatedUpload.extension}`;
      const file = bucket.file(fileName);
      const downloadToken = crypto.randomUUID();

      await file.save(req.file!.buffer, {
        metadata: {
          contentType: validatedUpload.mimeType,
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
          },
        },
        resumable: false,
      });

      const encodedPath = encodeURIComponent(fileName);
      const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;

      // Update user's photo array
      const userData = userDoc.data() || {};
      const profile = userData.profile || {};
      const photos = profile.photoUrls || [];

      if (isPrimary) {
        photos.unshift(url);
      } else {
        photos.push(url);
      }

      await userRef.update({
        "profile.photoUrls": photos,
        "profile.updatedAt": serverTimestamp(),
      });

      res.json({
        id: `photo_${Date.now()}`,
        url,
        is_primary: isPrimary,
      });
    } catch (err) {
      console.error("Upload photo error:", err);
      if (err instanceof UploadValidationError) {
        return res.status(err.statusCode).json({ error: err.message });
      }
      return res.status(500).json({ error: "Failed to upload photo" });
    }
  },
);

// Delete photo
app.delete(
  "/v1/profile/photos/:photoId",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { photoId } = req.params;
      const photoIndex = parseProfilePhotoIndex(photoId);
      if (photoIndex === null) {
        return res.status(400).json({
          error: "Invalid photoId format. Use photo_<index>.",
        });
      }

      const userRef = db.collection("users").doc(req.uid!);
      const userDoc = await userRef.get();
      if (!userDoc.exists) {
        return res.status(404).json({ error: "User not found" });
      }

      const userData = userDoc.data() || {};
      const profile = userData.profile || {};
      const photos: string[] = profile.photoUrls || [];

      if (photoIndex >= photos.length) {
        return res.status(404).json({ error: "Photo not found" });
      }

      const photoUrl = photos[photoIndex];
      try {
        await deleteProfilePhotoStorageObject(photoUrl);
      } catch (storageError) {
        console.error("Delete photo storage error:", storageError, {
          uid: req.uid,
          photoId,
          photoUrl,
        });
        return res.status(502).json({
          error: "Failed to delete photo from storage",
        });
      }

      const remainingPhotos = photos.filter((_, index) => index !== photoIndex);

      await userRef.update({
        "profile.photoUrls": remainingPhotos,
        "profile.updatedAt": serverTimestamp(),
      });

      res.json({ success: true });
    } catch (err) {
      console.error("Delete photo error:", err);
      return res.status(500).json({ error: "Failed to delete photo" });
    }
  },
);

// Reorder photos
app.post(
  "/v1/profile/photos/reorder",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const photoIds = Array.isArray(req.body?.photo_ids)
        ? (req.body.photo_ids as unknown[]).map((value) => String(value))
        : [];
      if (photoIds.length === 0) {
        return res.status(400).json({ error: "photo_ids must be a non-empty array." });
      }

      const userRef = db.collection("users").doc(req.uid!);
      const userDoc = await userRef.get();
      if (!userDoc.exists) {
        return res.status(404).json({ error: "User not found" });
      }

      const profile = (userDoc.data()?.profile ?? {}) as Record<string, unknown>;
      const currentPhotos = toStringArray(profile.photoUrls);
      if (currentPhotos.length !== photoIds.length) {
        return res.status(400).json({
          error: "photo_ids must include every current photo exactly once.",
        });
      }

      const requestedIndexes = photoIds.map((photoId) => parseProfilePhotoIndex(photoId));
      if (requestedIndexes.some((index) => index == null)) {
        return res.status(400).json({
          error: "Each photo id must use the format photo_<index>.",
        });
      }

      const normalizedIndexes = requestedIndexes.map((index) => index as number);
      const uniqueIndexes = new Set(normalizedIndexes);
      if (
        uniqueIndexes.size !== currentPhotos.length ||
        normalizedIndexes.some((index) => index < 0 || index >= currentPhotos.length)
      ) {
        return res.status(400).json({
          error: "photo_ids must reference each existing photo exactly once.",
        });
      }

      const reorderedPhotos = normalizedIndexes.map((index) => currentPhotos[index]);
      await userRef.update({
        "profile.photoUrls": reorderedPhotos,
        "profile.updatedAt": serverTimestamp(),
      });

      return res.json({
        success: true,
        photos: reorderedPhotos.map((url, index) => ({
          id: `photo_${index}`,
          url,
          is_primary: index === 0,
        })),
      });
    } catch (err) {
      console.error("Reorder photos error:", err);
      return res.status(500).json({ error: "Failed to reorder photos" });
    }
  },
);

// Update preferences
app.patch(
  "/v1/profile/preferences",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const normalizedPreferences = validateProfilePreferencesPayload(req.body);
      const userRef = db.collection("users").doc(req.uid!);
      const userDoc = await userRef.get();
      if (!userDoc.exists) {
        return res
          .status(404)
          .json({ error: "User not found", code: "not-found" });
      }

      const currentData = userDoc.data() || {};
      const existingPreferences = getCanonicalProfilePreferences(currentData, {
        uid: req.uid,
        source: "rest:/v1/profile/preferences",
      });
      const mergedPreferences = {
        ...existingPreferences,
        ...normalizedPreferences,
      };

      const minAge = toNumber(mergedPreferences.minAge);
      const maxAge = toNumber(mergedPreferences.maxAge);
      if (minAge !== undefined && maxAge !== undefined && minAge > maxAge) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "minAge cannot be greater than maxAge.",
        );
      }

      await userRef.update({
        "profile.preferences": mergedPreferences,
        // Remove legacy flat mirror to keep canonical nested profile schema.
        preferences: deleteField(),
        "profile.updatedAt": serverTimestamp(),
        updatedAt: serverTimestamp(),
      });

      res.json({ success: true, preferences: mergedPreferences });
    } catch (err) {
      console.error("Update preferences error:", err);
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      const firestoreCode = (err as { code?: unknown })?.code;
      if (firestoreCode === 5 || firestoreCode === "not-found") {
        return res
          .status(404)
          .json({ error: "User not found", code: "not-found" });
      }
      return res.status(500).json({ error: "Failed to update preferences" });
    }
  },
);

// Get profile by ID
app.get(
  "/v1/profile/:userId",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { userId } = req.params;
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        return res.status(404).json({ error: "User not found" });
      }

      const data = userDoc.data() || {};
      const profile = data.profile || {};

      res.json({
        id: userId,
        display_name: profile.name || profile.displayName,
        bio: profile.bio,
        age: deriveProfileAge(profile as Record<string, unknown>),
        birth_date: profileBirthDateIso(profile as Record<string, unknown>),
        gender: profile.gender,
        city: profile.city,
        photos: (profile.photoUrls || []).map((url: string, i: number) => ({
          id: `photo_${i}`,
          url,
          is_primary: i === 0,
        })),
        interests: profile.interests || [],
        prompts: profilePromptAnswers(profile as Record<string, unknown>),
        is_verified: data.idVerified || false,
      });
    } catch (err) {
      console.error("Get profile error:", err);
      return res.status(500).json({ error: "Failed to get profile" });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// DISCOVERY ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get discovery deck
app.get(
  "/v1/discovery/deck",
  authMiddleware,
  rateLimitDiscovery,
  async (req: AuthRequest, res: Response) => {
    try {
      const payload = await buildDiscoveryDeckPayload({
        uid: req.uid!,
        source: "rest:/v1/discovery/deck",
        request: {
          limit:
            typeof req.query.limit === "string"
              ? Number(req.query.limit)
              : undefined,
          cursor:
            typeof req.query.cursor === "string" ? req.query.cursor : undefined,
          minAge:
            typeof req.query.minAge === "string"
              ? Number(req.query.minAge)
              : undefined,
          maxAge:
            typeof req.query.maxAge === "string"
              ? Number(req.query.maxAge)
              : undefined,
          maxDistanceKm:
            typeof req.query.maxDistanceKm === "string"
              ? Number(req.query.maxDistanceKm)
              : undefined,
          showMeGenders:
            typeof req.query.showMeGenders === "string"
              ? req.query.showMeGenders.split(",")
              : undefined,
          interests:
            typeof req.query.interests === "string"
              ? req.query.interests.split(",")
              : undefined,
          requirePhotos: req.query.requirePhotos === "true",
          requireVerified: req.query.requireVerified === "true",
          latitude:
            typeof req.query.latitude === "string"
              ? Number(req.query.latitude)
              : undefined,
          longitude:
            typeof req.query.longitude === "string"
              ? Number(req.query.longitude)
              : undefined,
        },
      });
      const candidates = Array.isArray(payload.candidates)
        ? (payload.candidates as Record<string, unknown>[])
        : [];
      const profiles = candidates.map((candidate) => ({
        id: candidate.id,
        display_name: candidate.name,
        age: candidate.age,
        birth_date: null,
        bio: candidate.bio,
        city: candidate.city,
        photos: toStringArray(candidate.photoUrls).map((url, index) => ({
          url,
          is_primary: index === 0,
        })),
        interests: candidate.interests ?? [],
        prompts: candidate.prompts ?? [],
        is_verified: candidate.isVerified === true,
        distance_km:
          typeof candidate.distanceKm === "number" ? candidate.distanceKm : null,
        source_schema: candidate.sourceSchema ?? null,
      }));

      res.json({
        candidates: profiles, // Renamed from 'profiles' to match callable function
        profiles, // Keep for backward compatibility
        total:
          typeof payload.total === "number" ? payload.total : profiles.length,
        total_count:
          typeof payload.total === "number"
            ? payload.total
            : profiles.length, // Keep for backward compatibility
        has_more: payload.hasMore === true,
        hasMore: payload.hasMore === true,
        next_cursor:
          typeof payload.nextCursor === "string" ? payload.nextCursor : null,
        nextCursor:
          typeof payload.nextCursor === "string" ? payload.nextCursor : null,
        requester_status: payload.requesterStatus ?? null,
      });
    } catch (err) {
      console.error("Get deck error:", err);
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      return res.status(500).json({ error: "Failed to get discovery deck" });
    }
  },
);

// People who liked the current user
app.get(
  "/v1/discovery/likes-you",
  authMiddleware,
  rateLimitDiscovery,
  async (req: AuthRequest, res: Response) => {
    try {
      const offset = parseBoundedIntQueryParam(req.query.offset, {
        fallback: 0,
        min: 0,
        max: 5000,
      });
      const hasExplicitLimit =
        typeof req.query.limit === "string" && req.query.limit.trim().length > 0;
      const limit = hasExplicitLimit
        ? parseBoundedIntQueryParam(req.query.limit, {
          fallback: 25,
          min: 1,
          max: 100,
        })
        : null;

      const [likesSnap, swipesSnap] = await Promise.all([
        db.collection("likes").where("toUserId", "==", req.uid!).get(),
        db.collection("swipes").where("targetId", "==", req.uid!).get(),
      ]);

      const relations: Array<{
        likerId: string;
        createdAt: Date | null;
        source: "likes" | "swipes";
      }> = [];

      likesSnap.docs.forEach((doc) => {
        const data = doc.data();
        const likerId = optionalString(data.fromUserId) ?? "";
        if (!likerId || likerId === req.uid) {
          return;
        }

        relations.push({
          likerId,
          createdAt: normalizeDate(data.createdAt),
          source: "likes",
        });
      });

      swipesSnap.docs.forEach((doc) => {
        const data = doc.data();
        const action = typeof data.action === "string" ? data.action : "";
        if (action === "like" || action === "super_like") {
          const likerId = optionalString(data.swiperId) ?? "";
          if (!likerId || likerId === req.uid) {
            return;
          }

          relations.push({
            likerId,
            createdAt: normalizeDate(data.createdAt),
            source: "swipes",
          });
        }
      });

      relations.sort((left, right) => {
        const timeDiff =
          (right.createdAt?.getTime() ?? 0) - (left.createdAt?.getTime() ?? 0);
        if (timeDiff !== 0) {
          return timeDiff;
        }

        const likerDiff = left.likerId.localeCompare(right.likerId);
        if (likerDiff !== 0) {
          return likerDiff;
        }

        return left.source.localeCompare(right.source);
      });

      const likerIds: string[] = [];
      const seenLikerIds = new Set<string>();
      for (const relation of relations) {
        if (seenLikerIds.has(relation.likerId)) {
          continue;
        }

        seenLikerIds.add(relation.likerId);
        likerIds.push(relation.likerId);
      }

      const totalCount = likerIds.length;
      if (totalCount === 0) {
        return res.json({
          candidates: [],
          profiles: [],
          total_count: 0,
          has_more: false,
          next_offset: null,
        });
      }

      const safeOffset = Math.min(offset, totalCount);
      const pageSize = limit ?? Math.max(totalCount - safeOffset, 0);
      const pageLikerIds = likerIds.slice(safeOffset, safeOffset + pageSize);
      const hasMore = safeOffset + pageLikerIds.length < totalCount;
      const nextOffset = hasMore ? safeOffset + pageLikerIds.length : null;

      const userDocs = new Map<string, FirebaseFirestore.DocumentData>();
      for (let i = 0; i < pageLikerIds.length; i += 30) {
        const chunk = pageLikerIds.slice(i, i + 30);
        const usersSnap = await db
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", chunk)
          .get();
        usersSnap.docs.forEach((doc) => userDocs.set(doc.id, doc.data()));
      }

      const profiles = pageLikerIds.map((likerId) => {
        const userData = userDocs.get(likerId) ?? {};
        const profile = (userData.profile ?? {}) as Record<string, unknown>;
        return {
          id: likerId,
          display_name:
            optionalString(profile.name) ??
            optionalString(profile.displayName) ??
            "Someone",
          age: deriveProfileAge(profile),
          bio: optionalString(profile.bio) ?? null,
          city: optionalString(profile.city) ?? null,
          photos: toStringArray(profile.photoUrls).map((url, index) => ({
            id: `photo_${index}`,
            url,
            is_primary: index === 0,
          })),
          interests: toStringArray(profile.interests),
          is_verified: userData.idVerified === true,
        };
      });

      return res.json({
        candidates: profiles,
        profiles,
        total_count: totalCount,
        has_more: hasMore,
        next_offset: nextOffset,
      });
    } catch (err) {
      console.error("Get likes-you error:", err);
      return res.status(500).json({ error: "Failed to get likes-you profiles" });
    }
  },
);

// Swipe
app.post(
  "/v1/discovery/swipe",
  authMiddleware,
  requireVerifiedEmail,
  rateLimitSwipe,
  async (req: AuthRequest, res: Response) => {
    try {
      const { target_user_id, action, message } = req.body;
      if (!target_user_id || !action) {
        return res
          .status(400)
          .json({ error: "target_user_id and action required" });
      }

      const isLike = action === "like" || action === "super_like";

      // Record the swipe
      await db.collection("swipes").add({
        swiperId: req.uid,
        targetId: target_user_id,
        action,
        message: message || null,
        createdAt: serverTimestamp(),
      });

      let isMatch = false;
      let matchId = null;

      // Check for mutual like (match)
      if (isLike) {
        const mutualSwipe = await db
          .collection("swipes")
          .where("swiperId", "==", target_user_id)
          .where("targetId", "==", req.uid)
          .where("action", "in", ["like", "super_like"])
          .limit(1)
          .get();

        if (!mutualSwipe.empty) {
          isMatch = true;
          // Create match document
          const matchRef = await db.collection("matches").add({
            users: [req.uid, target_user_id],
            createdAt: serverTimestamp(),
            lastMessageAt: null,
          });
          matchId = matchRef.id;
        }
      }

      res.json({
        success: true,
        is_match: isMatch,
        match_id: matchId,
      });
    } catch (err) {
      console.error("Swipe error:", err);
      return res.status(500).json({ error: "Failed to record swipe" });
    }
  },
);

// Activate boost
app.post(
  "/v1/discovery/boost",
  authMiddleware,
  requireVerifiedEmail,
  rateLimitSwipe,
  async (req: AuthRequest, res: Response) => {
    try {
      const boostDuration = 30 * 60 * 1000; // 30 minutes
      const boostExpiresAt = Date.now() + boostDuration;

      await db.collection("users").doc(req.uid!).update({
        "boost.expiresAt": boostExpiresAt,
        "boost.activatedAt": serverTimestamp(),
      });

      res.json({
        success: true,
        expires_at: new Date(boostExpiresAt).toISOString(),
      });
    } catch (err) {
      console.error("Boost error:", err);
      return res.status(500).json({ error: "Failed to activate boost" });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// MATCHES ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get matches
app.get(
  "/v1/matches",
  authMiddleware,
  rateLimitDefault,
  async (req: AuthRequest, res: Response) => {
    try {
      const offset = parseBoundedIntQueryParam(req.query.offset, {
        fallback: 0,
        min: 0,
        max: 5000,
      });
      const limit = parseBoundedIntQueryParam(req.query.limit, {
        fallback: 20,
        min: 1,
        max: 50,
      });
      const beforeCursor = parseBeforeTimestampCursor(req.query.before);
      if (beforeCursor.invalid) {
        return res.status(400).json({ error: "Invalid before cursor" });
      }
      const beforeTimestamp = beforeCursor.timestamp;

      let matchesQuery = db
        .collection("matches")
        .where("users", "array-contains", req.uid)
        .orderBy("lastMessageAt", "desc");

      if (beforeTimestamp) {
        matchesQuery = matchesQuery.where(
          "lastMessageAt",
          "<",
          admin.firestore.Timestamp.fromDate(beforeTimestamp),
        );
      } else if (offset > 0) {
        matchesQuery = matchesQuery.offset(offset);
      }

      const matchesSnap = await matchesQuery.limit(limit + 1).get();

      if (matchesSnap.empty) {
        return res.json({
          matches: [],
          total_count: 0,
          has_more: false,
          next_cursor: null,
        });
      }

      const totalCountSnap = await db
        .collection("matches")
        .where("users", "array-contains", req.uid)
        .count()
        .get();
      const totalCount = totalCountSnap.data().count ?? matchesSnap.size;
      const hasMore = matchesSnap.docs.length > limit;
      const pageDocs =
        hasMore ? matchesSnap.docs.slice(0, limit) : matchesSnap.docs;

      // Collect all other user IDs
      const otherUserIds = pageDocs
        .map((doc) => doc.data().users.find((id: string) => id !== req.uid))
        .filter(Boolean);

      // Batch fetch users (max 30 per 'in' query)
      const usersMap = new Map<string, admin.firestore.DocumentData>();
      if (otherUserIds.length > 0) {
        const uniqueIds = [...new Set(otherUserIds)];
        const chunks = [];
        for (let i = 0; i < uniqueIds.length; i += 30) {
          chunks.push(uniqueIds.slice(i, i + 30));
        }

        await Promise.all(
          chunks.map(async (chunk) => {
            const usersSnap = await db
              .collection("users")
              .where(admin.firestore.FieldPath.documentId(), "in", chunk)
              .get();
            usersSnap.docs.forEach((doc) => usersMap.set(doc.id, doc.data()));
          }),
        );
      }

      const matches = pageDocs.map((doc) => {
        const data = doc.data();
        const otherUserId = data.users.find((id: string) => id !== req.uid);
        const otherUserData = usersMap.get(otherUserId) || {};
        const profile = otherUserData.profile || {};

        return {
          id: doc.id,
          matched_user_id: otherUserId,
          matched_user_name: profile.name || profile.displayName,
          matched_user_photo: (profile.photoUrls || [])[0],
          created_at: data.createdAt?.toDate?.()?.toISOString(),
          last_message_at: data.lastMessageAt?.toDate?.()?.toISOString(),
        };
      });

      const nextCursorDate =
        hasMore && pageDocs.length > 0
          ? pageDocs[pageDocs.length - 1].data().lastMessageAt?.toDate?.()
          : null;

      res.json({
        matches,
        total_count: totalCount,
        has_more: hasMore,
        next_cursor: nextCursorDate ? nextCursorDate.toISOString() : null,
      });
    } catch (err) {
      console.error("Get matches error:", err);
      return res.status(500).json({ error: "Failed to get matches" });
    }
  },
);

// Unmatch
app.post(
  "/v1/matches/:matchId/unmatch",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { matchId } = req.params;
      const matchDoc = await db.collection("matches").doc(matchId).get();

      if (!matchDoc.exists) {
        return res.status(404).json({ error: "Match not found" });
      }

      const matchData = matchDoc.data();
      if (!matchData?.users?.includes(req.uid)) {
        return res.status(403).json({ error: "Not authorized" });
      }

      await db.collection("matches").doc(matchId).delete();

      res.json({ success: true });
    } catch (err) {
      console.error("Unmatch error:", err);
      return res.status(500).json({ error: "Failed to unmatch" });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CHAT ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get conversations
app.get(
  "/v1/chat/conversations",
  authMiddleware,
  rateLimitDefault,
  async (req: AuthRequest, res: Response) => {
    try {
      const limit = parseBoundedIntQueryParam(req.query.limit, {
        fallback: 50,
        min: 1,
        max: 100,
      });
      const beforeCursor = parseBeforeTimestampCursor(req.query.before);
      if (beforeCursor.invalid) {
        return res.status(400).json({ error: "Invalid before cursor" });
      }
      const beforeTimestamp = beforeCursor.timestamp;

      const totalCountPromise = db
        .collection("matches")
        .where("users", "array-contains", req.uid)
        .count()
        .get();

      let matchesQuery = db
        .collection("matches")
        .where("users", "array-contains", req.uid)
        .orderBy("lastMessageAt", "desc");

      if (beforeTimestamp) {
        matchesQuery = matchesQuery.where(
          "lastMessageAt",
          "<",
          admin.firestore.Timestamp.fromDate(beforeTimestamp),
        );
      }

      const [totalCountSnap, matchesSnap] = await Promise.all([
        totalCountPromise,
        matchesQuery.limit(limit + 1).get(),
      ]);
      const totalCount = totalCountSnap.data().count ?? matchesSnap.size;

      if (matchesSnap.empty) {
        return res.json({
          conversations: [],
          total_count: totalCount,
          has_more: false,
          next_cursor: null,
        });
      }

      const hasMore = matchesSnap.docs.length > limit;
      const pageDocs = hasMore ? matchesSnap.docs.slice(0, limit) : matchesSnap.docs;

      const otherUserIds = pageDocs
        .map((doc) => doc.data().users.find((id: string) => id !== req.uid))
        .filter(Boolean);

      const usersMap = new Map<string, admin.firestore.DocumentData>();
      if (otherUserIds.length > 0) {
        const uniqueIds = [...new Set(otherUserIds)];
        const chunks = [];
        for (let i = 0; i < uniqueIds.length; i += 30) {
          chunks.push(uniqueIds.slice(i, i + 30));
        }

        await Promise.all(
          chunks.map(async (chunk) => {
            const usersSnap = await db
              .collection("users")
              .where(admin.firestore.FieldPath.documentId(), "in", chunk)
              .get();
            usersSnap.docs.forEach((doc) => usersMap.set(doc.id, doc.data()));
          }),
        );
      }

      const conversations = await Promise.all(
        pageDocs.map(async (doc) => {
          const data = doc.data();
          const otherUserId = data.users.find((id: string) => id !== req.uid);
          const otherUserData = usersMap.get(otherUserId) || {};
          const profile = otherUserData.profile || {};
          const participantPayload = otherUserId
            ? {
                id: otherUserId,
                name: profile.name || profile.displayName,
                photo_url: (profile.photoUrls || [])[0],
              }
            : null;

          // Get last message (still per-match, but profiles are batched)
          const lastMsgSnap = await db
            .collection("matches")
            .doc(doc.id)
            .collection("messages")
            .orderBy("createdAt", "desc")
            .limit(1)
            .get();
          const lastMsgDoc = lastMsgSnap.docs[0];
          const lastMsg = lastMsgDoc?.data();
          const lastMessageTimestamp = lastMsg?.createdAt?.toDate?.();
          const updatedAt = data.lastMessageAt?.toDate?.();

          return {
            id: doc.id,
            match_id: doc.id,
            participants: participantPayload
              ? [
                  {
                    user_id: participantPayload.id,
                    display_name: participantPayload.name,
                    photo_url: participantPayload.photo_url,
                  },
                ]
              : [],
            participant: participantPayload,
            last_message: lastMsg
              ? {
                  id: lastMsgDoc.id,
                  conversation_id: doc.id,
                  sender_id:
                    typeof lastMsg.senderId === "string"
                      ? lastMsg.senderId
                      : typeof lastMsg.fromUserId === "string"
                        ? lastMsg.fromUserId
                        : "",
                  content: lastMsg.content,
                  type: lastMsg.type || "text",
                  created_at: lastMessageTimestamp?.toISOString() ?? null,
                  sent_at: lastMessageTimestamp?.toISOString() ?? null,
                }
              : null,
            updated_at: updatedAt?.toISOString(),
          };
        }),
      );

      const nextCursorDate =
        hasMore && pageDocs.length > 0
          ? pageDocs[pageDocs.length - 1].data().lastMessageAt?.toDate?.()
          : null;

      res.json({
        conversations,
        total_count: totalCount,
        has_more: hasMore,
        next_cursor: nextCursorDate ? nextCursorDate.toISOString() : null,
      });
    } catch (err) {
      console.error("Get conversations error:", err);
      return res.status(500).json({ error: "Failed to get conversations" });
    }
  },
);

// Get messages
app.get(
  "/v1/chat/:conversationId/messages",
  authMiddleware,
  rateLimitDefault,
  async (req: AuthRequest, res: Response) => {
    try {
      const { conversationId } = req.params;
      const limit = parseBoundedIntQueryParam(req.query.limit, {
        fallback: 50,
        min: 1,
        max: 100,
      });
      const beforeCursor = parseChatMessagesBeforeCursor(req.query.before);

      const matchDoc = await db.collection("matches").doc(conversationId).get();
      if (!matchDoc.exists) {
        return res.status(404).json({ error: "Conversation not found" });
      }

      const matchData = matchDoc.data();
      if (!Array.isArray(matchData?.users) || !matchData.users.includes(req.uid)) {
        return res.status(403).json({ error: "Not authorized" });
      }

      let query = db
        .collection("matches")
        .doc(conversationId)
        .collection("messages")
        .orderBy("createdAt", "desc")
        .limit(limit + 1);

      if (beforeCursor.beforeTimestamp != null) {
        query = query.where(
          "createdAt",
          "<",
          admin.firestore.Timestamp.fromDate(beforeCursor.beforeTimestamp),
        );
      } else if (beforeCursor.beforeMessageId != null) {
        const beforeDoc = await db
          .collection("matches")
          .doc(conversationId)
          .collection("messages")
          .doc(beforeCursor.beforeMessageId)
          .get();
        if (beforeDoc.exists) {
          query = query.startAfter(beforeDoc);
        }
      }

      const messagesSnap = await query.get();
      const hasMore = messagesSnap.docs.length > limit;
      const pageDocs =
        hasMore ? messagesSnap.docs.slice(0, limit) : messagesSnap.docs;

      const messages = pageDocs
        .map((doc) => {
          const data = doc.data();
          return {
            id: doc.id,
            sender_id: data.senderId,
            content: data.content,
            type: data.type || "text",
            media_url: data.mediaUrl,
            created_at: data.createdAt?.toDate?.()?.toISOString(),
            reactions: data.reactions || [],
          };
        })
        .reverse();

      const oldestPageTimestamp =
        pageDocs.length > 0
          ? pageDocs[pageDocs.length - 1].data().createdAt?.toDate?.()
          : null;

      res.json({
        messages,
        has_more: hasMore,
        next_cursor:
          hasMore && oldestPageTimestamp instanceof Date
            ? oldestPageTimestamp.toISOString()
            : null,
      });
    } catch (err) {
      console.error("Get messages error:", err);
      return res.status(500).json({ error: "Failed to get messages" });
    }
  },
);

// Send message
app.post(
  "/v1/chat/:conversationId/send",
  authMiddleware,
  rateLimitMessage,
  async (req: AuthRequest, res: Response) => {
    try {
      const { conversationId } = req.params;
      const { type, content, media_url } = req.body;

      // CHAT-BE-001: enforce participant authorization server-side. Previously
      // this handler wrote to any match's messages subcollection with no
      // membership/block check, so any authenticated user could inject messages
      // into conversations they were not part of. ensureUserInMatch verifies
      // membership and throws not-found / permission-denied (mapped to 404 / 403
      // below).
      const { matchData, otherUserId } = await ensureUserInMatch(
        conversationId,
        req.uid!,
      );

      // The participant set drives the message's visibleTo array (per-user
      // retention). otherUserId is guaranteed for a normal 2-person match;
      // fall back to just the sender if a malformed match has no second party.
      const participants = otherUserId
        ? [req.uid!, otherUserId]
        : [req.uid!];

      // Blocked or removed relationships cannot continue chatting.
      if (
        otherUserId &&
        (await hasBlockingRelationship(req.uid!, otherUserId))
      ) {
        return res
          .status(403)
          .json({ error: "Messaging is unavailable for this conversation." });
      }
      // If the match carries a status, only an active match may be written to.
      if (
        typeof matchData.status === "string" &&
        matchData.status !== "active"
      ) {
        return res
          .status(403)
          .json({ error: "This conversation is no longer active." });
      }

      const sanitizedContent = content ? validateMessageContent(content) : null;

      // CHAT-BE-003: write fromUserId / toUserId / visibleTo alongside the
      // legacy senderId so the onMessageCreated moderation+notification trigger
      // (which early-returns without fromUserId/toUserId) and the per-user
      // retention model (driven by visibleTo) both apply to REST-sent messages,
      // exactly as they do for messages written directly via the SDK.
      const messageRef = await db
        .collection("matches")
        .doc(conversationId)
        .collection("messages")
        .add({
          senderId: req.uid,
          fromUserId: req.uid,
          toUserId: otherUserId,
          content: sanitizedContent || null,
          type: type || "text",
          mediaUrl: media_url || null,
          createdAt: serverTimestamp(),
          isRead: false,
          visibleTo: participants,
          reactions: [],
        });

      // Update last message timestamp
      await db.collection("matches").doc(conversationId).update({
        lastMessageAt: serverTimestamp(),
      });

      res.json({
        id: messageRef.id,
        success: true,
      });
    } catch (err) {
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      console.error("Send message error:", err);
      return res.status(500).json({ error: "Failed to send message" });
    }
  },
);

// Upload media for chat
app.post(
  "/v1/chat/:conversationId/media",
  authMiddleware,
  requireVerifiedEmail,
  rateLimitMessage,
  chatMediaUploadMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { conversationId } = req.params;
      const mediaKind = parseChatMediaUploadKind(req.body?.type);
      if (!mediaKind) {
        return res.status(400).json({
          error: "Media type must be one of: image, video, audio.",
        });
      }

      await ensureUserInMatch(conversationId, req.uid!);

      const validatedUpload = await validateBinaryUpload({
        file: req.file,
        fieldLabel: "Media",
        maxBytes: CHAT_MEDIA_MAX_BYTES_BY_KIND[mediaKind],
        allowedMimeTypes: CHAT_MEDIA_ALLOWED_MIME_TYPES_BY_KIND[mediaKind],
        extensionByMime: CHAT_MEDIA_EXTENSION_BY_MIME,
        unsupportedTypeMessage: `Unsupported ${mediaKind} upload type. Allowed types: ${allowedMimeTypesMessage(CHAT_MEDIA_ALLOWED_MIME_TYPES_BY_KIND[mediaKind])}.`,
      });

      const bucket = admin.storage().bucket();
      const fileName = `chat_media/${req.uid}/${conversationId}/${Date.now()}_${crypto.randomUUID()}.${validatedUpload.extension}`;
      const file = bucket.file(fileName);
      const downloadToken = crypto.randomUUID();

      await file.save(req.file!.buffer, {
        metadata: {
          contentType: validatedUpload.mimeType,
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
          },
        },
        resumable: false,
      });

      const encodedPath = encodeURIComponent(fileName);
      const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;

      res.json({ url });
    } catch (err) {
      console.error("Upload media error:", err);
      if (err instanceof UploadValidationError) {
        return res.status(err.statusCode).json({ error: err.message });
      }
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      return res.status(500).json({ error: "Failed to upload media" });
    }
  },
);

// Mark messages as read
app.post(
  "/v1/chat/:conversationId/read",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { conversationId } = req.params;

      // CHAT-BE-001: only a participant may mark a conversation as read.
      await ensureUserInMatch(conversationId, req.uid!);

      // Update read status
      await db
        .collection("matches")
        .doc(conversationId)
        .update({
          [`readBy.${req.uid}`]: serverTimestamp(),
        });

      res.json({ success: true });
    } catch (err) {
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      console.error("Mark read error:", err);
      return res.status(500).json({ error: "Failed to mark as read" });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CALLS ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

app.post(
  "/v1/calls/start",
  authMiddleware,
  requireVerifiedEmail,
  async (req: AuthRequest, res: Response) => {
    try {
      const matchId = optionalString(req.body?.match_id);
      if (!matchId) {
        return res.status(400).json({ error: "match_id required" });
      }

      const { otherUserId } = await ensureUserInMatch(matchId, req.uid!);
      if (!otherUserId) {
        return res.status(400).json({ error: "Could not resolve the other match participant." });
      }

      const isVideoCall = req.body?.is_video === true || req.body?.is_video === "true";
      const result = await initiateCallForUser({
        callerId: req.uid!,
        receiverId: otherUserId,
        type: isVideoCall ? "video" : "audio",
      });

      return res.json({
        call_id: result.callId,
        channel_name: result.callId,
        local_uid: 0,
        is_video: isVideoCall,
        status: result.status,
        expires_at_ms: result.expiresAtMs,
      });
    } catch (err) {
      console.error("Start call error:", err);
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      return res.status(500).json({ error: "Failed to start call" });
    }
  },
);

app.post(
  "/v1/calls/end",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const callId = optionalString(req.body?.call_id);
      if (!callId) {
        return res.status(400).json({ error: "call_id required" });
      }

      const result = await endCallForUser({
        uid: req.uid!,
        callId,
        reason: optionalString(req.body?.reason),
      });

      return res.json({
        success: true,
        call_id: result.callId,
        status: result.status,
        end_reason: result.endReason,
      });
    } catch (err) {
      console.error("End call error:", err);
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      return res.status(500).json({ error: "Failed to end call" });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get subscription plans
app.get("/v1/subscription/plans", async (req: Request, res: Response) => {
  try {
    const plansSnap = await db.collection("subscription_plans").get();

    const plans = plansSnap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        price_monthly: data.priceMonthly,
        price_yearly: data.priceYearly,
        features: data.features || [],
        stripe_price_id_monthly: data.stripePriceIdMonthly,
        stripe_price_id_yearly: data.stripePriceIdYearly,
      };
    });

    // If no plans in DB, return defaults
    if (plans.length === 0) {
      res.json({
        plans: [
          {
            id: "free",
            name: "Free",
            price_monthly: 0,
            features: ["30 likes per day", "Basic filters"],
          },
          {
            id: "plus",
            name: "Crush+",
            price_monthly: 9.99,
            price_yearly: 59.99,
            features: [
              "Unlimited likes",
              "See who likes you",
              "Rewind last swipe",
              "5 Super Likes per day",
              "1 Boost per month",
              "Advanced filters",
            ],
          },
        ],
      });
    } else {
      res.json({ plans });
    }
  } catch (err) {
    console.error("Get plans error:", err);
    return res.status(500).json({ error: "Failed to get plans" });
  }
});

// Create checkout session
app.post(
  "/v1/subscription/checkout",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { price_id, success_url, cancel_url } = req.body;
      if (!price_id) {
        return res.status(400).json({ error: "price_id required" });
      }

      // Get or create Stripe customer
      const userDoc = await db.collection("users").doc(req.uid!).get();
      const userData = userDoc.data() || {};
      let customerId = userData.stripeCustomerId;
      const stripeSecret = getStripeSecret();
      const stripe = stripeSecret ? getStripeClient(stripeSecret) : null;

      if (!customerId && stripe) {
        const customer = await stripe.customers.create({
          metadata: { firebaseUid: req.uid! },
          email: userData.email,
          phone: userData.phoneNumber,
        });
        customerId = customer.id;
        await db.collection("users").doc(req.uid!).update({
          stripeCustomerId: customerId,
        });
      }

      // Create checkout session
      if (stripe) {
        const session = await stripe.checkout.sessions.create({
          customer: customerId,
          payment_method_types: ["card"],
          line_items: [{ price: price_id, quantity: 1 }],
          mode: "subscription",
          success_url: success_url || "https://crushhour.app/success",
          cancel_url: cancel_url || "https://crushhour.app/cancel",
        });

        res.json({
          session_id: session.id,
          url: session.url,
        });
      } else {
        return res.status(500).json({ error: "Stripe not configured" });
      }
    } catch (err) {
      console.error("Checkout error:", err);
      return res
        .status(500)
        .json({ error: "Failed to create checkout session" });
    }
  },
);

// Get current subscription
app.get(
  "/v1/subscription/current",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const userDoc = await db.collection("users").doc(req.uid!).get();
      const userData = userDoc.data() || {};

      res.json({
        plan: userData.plan || "free",
        expires_at: userData.subscriptionExpiresAt?.toDate?.()?.toISOString(),
        is_active: userData.plan === "plus",
      });
    } catch (err) {
      console.error("Get subscription error:", err);
      return res.status(500).json({ error: "Failed to get subscription" });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// SAFETY ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Submit an appeal for a safety action
app.post(
  "/v1/safety/appeal",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const reason = requireString(req.body?.reason, "reason");
      const targetType = optionalString(req.body?.target_type) ?? "account";
      const targetId = optionalString(req.body?.target_id) ?? null;

      await db.collection("appeals").add({
        userId: req.uid!,
        reason,
        targetType,
        targetId,
        status: "open",
        createdAt: serverTimestamp(),
      });

      await db.collection("users").doc(req.uid!).set(
        {
          safetyFlags: {
            appealOpen: true,
            lastAppealAt: serverTimestamp(),
            lastReason: reason,
          },
        },
        { merge: true },
      );

      return res.json({ success: true });
    } catch (err) {
      console.error("Submit safety appeal error:", err);
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      return res.status(500).json({ error: "Failed to submit appeal" });
    }
  },
);

// Block user
app.post(
  "/v1/users/block",
  authMiddleware,
  requireVerifiedEmail,
  rateLimitBlock,
  async (req: AuthRequest, res: Response) => {
    const route = req.path || "/v1/users/block";
    const method = req.method || "POST";
    const actorUid = req.uid;
    const ip = getRestClientIp(req);
    const userAgent = req.header("user-agent") ?? null;
    let blockedId: string | undefined;

    try {
      const blockerId = req.uid!;
      blockedId = validateSafetyTargetId(req.body?.blocked_id, "blocked_id");
      assertNotSelfSafetyAction(blockerId, blockedId, "block");
      await ensureUserExists(blockedId);

      // Rate limiting
      const blockLimit = await applyRateLimit(
        `block:uid:${blockerId}`,
        BLOCK_LIMIT,
        BLOCK_WINDOW_MS,
        BLOCK_BLOCK_MS,
      );
      if (!blockLimit.allowed) {
        const retryTime = formatRetryTime(blockLimit.retryAfterMs);
        await logSafetyRestAudit({
          action: "block",
          actorUid: blockerId,
          targetUid: blockedId,
          route,
          method,
          statusCode: 429,
          metadata: { retryAfterMs: blockLimit.retryAfterMs ?? null },
          ip,
          userAgent,
        });
        return res.status(429).json({
          error: "Too many block requests",
          retry_after_ms: blockLimit.retryAfterMs,
          message: `Please try again ${retryTime}`,
        });
      }

      const docId = `${blockerId}_${blockedId}`;
      await db.collection("blocks").doc(docId).set(
        {
          blockerId,
          blockedId,
          createdAt: serverTimestamp(),
        },
        { merge: true },
      );

      await logSafetyRestAudit({
        action: "block",
        actorUid: blockerId,
        targetUid: blockedId,
        route,
        method,
        statusCode: 200,
        ip,
        userAgent,
      });
      res.json({ success: true });
    } catch (err) {
      console.error("Block error:", err);
      const statusCode = isHttpsError(err)
        ? httpStatusFromHttpsErrorCode(err.code)
        : 500;
      await logSafetyRestAudit({
        action: "block",
        actorUid,
        targetUid: blockedId,
        route,
        method,
        statusCode,
        errorCode: isHttpsError(err) ? err.code : "internal",
        ip,
        userAgent,
      });
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      return res.status(500).json({ error: "Failed to block user" });
    }
  },
);

// Unblock user
app.post(
  "/v1/users/unblock",
  authMiddleware,
  requireVerifiedEmail,
  async (req: AuthRequest, res: Response) => {
    const route = req.path || "/v1/users/unblock";
    const method = req.method || "POST";
    const actorUid = req.uid;
    const ip = getRestClientIp(req);
    const userAgent = req.header("user-agent") ?? null;
    let blockedId: string | undefined;

    try {
      const blockerId = req.uid!;
      blockedId = validateSafetyTargetId(req.body?.blocked_id, "blocked_id");
      assertNotSelfSafetyAction(blockerId, blockedId, "unblock");

      // Rate limiting
      const unblockLimit = await applyRateLimit(
        `unblock:uid:${blockerId}`,
        UNBLOCK_LIMIT,
        UNBLOCK_WINDOW_MS,
        UNBLOCK_BLOCK_MS,
      );
      if (!unblockLimit.allowed) {
        const retryTime = formatRetryTime(unblockLimit.retryAfterMs);
        await logSafetyRestAudit({
          action: "unblock",
          actorUid: blockerId,
          targetUid: blockedId,
          route,
          method,
          statusCode: 429,
          metadata: { retryAfterMs: unblockLimit.retryAfterMs ?? null },
          ip,
          userAgent,
        });
        return res.status(429).json({
          error: "Too many unblock requests",
          retry_after_ms: unblockLimit.retryAfterMs,
          message: `Please try again ${retryTime}`,
        });
      }

      const docId = `${blockerId}_${blockedId}`;
      await db.collection("blocks").doc(docId).delete();

      // Backward-compat cleanup for legacy random-id block documents.
      const legacyBlocksSnap = await db
        .collection("blocks")
        .where("blockerId", "==", blockerId)
        .where("blockedId", "==", blockedId)
        .get();
      if (!legacyBlocksSnap.empty) {
        await Promise.all(legacyBlocksSnap.docs.map((doc) => doc.ref.delete()));
      }

      await logSafetyRestAudit({
        action: "unblock",
        actorUid: blockerId,
        targetUid: blockedId,
        route,
        method,
        statusCode: 200,
        ip,
        userAgent,
      });
      res.json({ success: true });
    } catch (err) {
      console.error("Unblock error:", err);
      const statusCode = isHttpsError(err)
        ? httpStatusFromHttpsErrorCode(err.code)
        : 500;
      await logSafetyRestAudit({
        action: "unblock",
        actorUid,
        targetUid: blockedId,
        route,
        method,
        statusCode,
        errorCode: isHttpsError(err) ? err.code : "internal",
        ip,
        userAgent,
      });
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      return res.status(500).json({ error: "Failed to unblock user" });
    }
  },
);

// Report user
app.post(
  "/v1/users/report",
  authMiddleware,
  requireVerifiedEmail,
  rateLimitReport,
  async (req: AuthRequest, res: Response) => {
    const route = req.path || "/v1/users/report";
    const method = req.method || "POST";
    const actorUid = req.uid;
    const ip = getRestClientIp(req);
    const userAgent = req.header("user-agent") ?? null;
    let reportedId: string | undefined;
    let reasonCategory: ReportCategory | undefined;

    try {
      const reporterId = req.uid!;
      reportedId = validateSafetyTargetId(req.body?.reported_id, "reported_id");
      assertNotSelfSafetyAction(reporterId, reportedId, "report");
      const reasonParsed = canonicalizeSafetyReportReason(req.body?.reason, {
        field: "reason",
        maxLength: 280,
        minLength: 3,
      });
      const reason = reasonParsed.reasonText;
      reasonCategory = reasonParsed.reasonCategory;
      const description = validateOptionalSafetyDescription(
        req.body?.description,
      );
      const matchId = optionalString(req.body?.match_id) ?? null;
      const messageId = optionalString(req.body?.message_id) ?? null;
      await ensureUserExists(reportedId);

      // Rate limiting
      const reportLimit = await applyRateLimit(
        `report:uid:${reporterId}`,
        REPORT_LIMIT,
        REPORT_WINDOW_MS,
        REPORT_BLOCK_MS,
      );
      if (!reportLimit.allowed) {
        const retryTime = formatRetryTime(reportLimit.retryAfterMs);
        await logSafetyRestAudit({
          action: "report",
          actorUid: reporterId,
          targetUid: reportedId,
          route,
          method,
          statusCode: 429,
          reasonCategory: reasonCategory ?? null,
          metadata: { retryAfterMs: reportLimit.retryAfterMs ?? null },
          ip,
          userAgent,
        });
        return res.status(429).json({
          error: "Too many report requests",
          retry_after_ms: reportLimit.retryAfterMs,
          message: `Please try again ${retryTime}`,
        });
      }

      await db.collection("reports").add({
        reporterId,
        reportedId,
        reason,
        reasonCategory,
        description,
        matchId,
        messageId,
        status: "pending",
        createdAt: serverTimestamp(),
      });

      await logSafetyRestAudit({
        action: "report",
        actorUid: reporterId,
        targetUid: reportedId,
        route,
        method,
        statusCode: 200,
        reasonCategory,
        ip,
        userAgent,
      });
      res.json({ success: true });
    } catch (err) {
      console.error("Report error:", err);
      const statusCode = isHttpsError(err)
        ? httpStatusFromHttpsErrorCode(err.code)
        : 500;
      await logSafetyRestAudit({
        action: "report",
        actorUid,
        targetUid: reportedId,
        route,
        method,
        statusCode,
        errorCode: isHttpsError(err) ? err.code : "internal",
        reasonCategory: reasonCategory ?? null,
        ip,
        userAgent,
      });
      if (isHttpsError(err)) {
        return res
          .status(httpStatusFromHttpsErrorCode(err.code))
          .json({ error: err.message, code: err.code });
      }
      return res.status(500).json({ error: "Failed to report user" });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// APPLE CREDENTIAL REVOCATION WEBHOOK (AUTH-SEC-007)
// Apple requires apps to handle credential revocation notifications.
// When a user removes your app from their Apple ID settings, Apple sends
// a server-to-server notification to this endpoint.
// ─────────────────────────────────────────────────────────────────────────────
app.post("/v1/auth/apple/revocation", async (req: Request, res: Response) => {
  try {
    // Apple sends the payload as application/x-www-form-urlencoded with 'payload' field
    const payload = req.body?.payload;
    if (!payload || typeof payload !== "string") {
      return res.status(400).json({ error: "Missing payload" });
    }

    // Decode the JWT payload (middle segment) — we trust Apple's server-to-server call
    const parts = payload.split(".");
    if (parts.length !== 3) {
      return res.status(400).json({ error: "Invalid token format" });
    }

    let claims: { sub?: string; events?: string; email?: string };
    try {
      const decoded = Buffer.from(parts[1], "base64url").toString("utf8");
      claims = JSON.parse(decoded);
    } catch {
      return res.status(400).json({ error: "Invalid token payload" });
    }

    // Parse the events field (Apple sends it as a JSON string within the JWT)
    let events: { type?: string; sub?: string; email?: string };
    if (typeof claims.events === "string") {
      events = JSON.parse(claims.events);
    } else {
      events = (claims.events as unknown as typeof events) || {};
    }

    const appleUserId = events.sub || claims.sub;
    if (!appleUserId) {
      return res.status(400).json({ error: "Missing user identifier" });
    }

    // Find the Firebase user linked to this Apple ID
    let uid: string | undefined;
    try {
      const userRecord = await admin
        .auth()
        .getUserByProviderUid("apple.com", appleUserId);
      uid = userRecord.uid;
    } catch {
      // User may have already been deleted or never existed
      console.warn(
        `Apple revocation: No user found for Apple ID ${appleUserId.substring(0, 8)}...`,
      );
      return res
        .status(200)
        .json({ success: true, message: "No matching user" });
    }

    // Revoke refresh tokens (signs out all devices)
    await admin.auth().revokeRefreshTokens(uid);

    // Mark the account as deactivated
    await db.collection("users").doc(uid).update({
      isDeactivated: true,
      deactivatedAt: serverTimestamp(),
      deactivationReason: "apple_credential_revoked",
    });

    // Audit log
    await logAuthAudit({
      action: "apple_credential_revoked",
      status: "ok",
      uid,
      metadata: { appleUserId: appleUserId.substring(0, 8) + "..." },
    });

    console.log(
      `Apple revocation: Deactivated user ${uid} (Apple ID: ${appleUserId.substring(0, 8)}...)`,
    );
    res.status(200).json({ success: true });
  } catch (err) {
    console.error("Apple revocation webhook error:", err);
    res.status(500).json({ error: "Internal error" });
  }
});

// Export the Express app as a Cloud Function
export const api = functions.https.onRequest(app);

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE RETENTION & AUTO-DELETE
// ═══════════════════════════════════════════════════════════════════════════════

// Retention durations in hours
const RETENTION_FREE_DEFAULT = 1; // 1 hour after read
const RETENTION_FREE_EXTENDED = 24; // 24 hours if user enables extended retention
const RETENTION_PLUS = 168; // 7 days for Plus users

/**
 * Get user's message retention hours based on their settings and plan.
 */
async function getUserRetentionHours(uid: string): Promise<number> {
  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.data();
  if (!userData) return RETENTION_FREE_DEFAULT;

  const isPremium = userData.plan === "plus";
  if (isPremium) return RETENTION_PLUS;

  const chatSettings = userData.profile?.chatSettings;
  const extendedRetention = chatSettings?.extendedRetention === true;
  return extendedRetention ? RETENTION_FREE_EXTENDED : RETENTION_FREE_DEFAULT;
}

/**
 * Sync user's chat settings to RTDB for quick access.
 */
async function syncChatSettingsToRtdb(uid: string): Promise<void> {
  const retentionHours = await getUserRetentionHours(uid);
  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.data();
  const isPremium = userData?.plan === "plus";
  const extendedRetention =
    userData?.profile?.chatSettings?.extendedRetention === true;

  await rtdb.ref(`chat_settings/${uid}`).set({
    extendedRetention,
    isPremium,
    retentionHours,
  });
}

/**
 * Schedule a message for deletion for a specific user.
 */
async function scheduleMessageDeletion(
  matchId: string,
  messageId: string,
  userId: string,
  readAt: Date,
): Promise<void> {
  const retentionHours = await getUserRetentionHours(userId);
  const deleteAt = new Date(readAt.getTime() + retentionHours * 60 * 60 * 1000);

  const queueId = `${matchId}_${messageId}_${userId}`;
  await rtdb.ref(`message_deletion_queue/${queueId}`).set({
    matchId,
    messageId,
    userId,
    deleteAt: deleteAt.getTime(),
    retentionHours,
    createdAt: Date.now(),
  });
}

/**
 * Trigger when a message is marked as read.
 * Schedules deletion based on the reader's retention settings.
 */
export const onMessageRead = functions.firestore
  .document("matches/{matchId}/messages/{messageId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { matchId, messageId } = context.params;

    // Check if message was just marked as read
    if (before.isRead === after.isRead) return;
    if (!after.isRead) return;

    const readerId = after.toUserId;
    const readAt = after.readAt?.toDate?.() || new Date();

    try {
      // Schedule deletion for the reader based on their retention settings
      await scheduleMessageDeletion(matchId, messageId, readerId, readAt);

      // Also schedule for the sender (they see it based on their settings too)
      const senderId = after.fromUserId;
      await scheduleMessageDeletion(matchId, messageId, senderId, readAt);

      console.log(`Scheduled message deletion: ${matchId}/${messageId}`);
    } catch (error) {
      console.error("Failed to schedule message deletion:", error);
    }
  });

/**
 * Scheduled function to process the message deletion queue.
 * Runs every 15 minutes to remove expired messages from users' visibility.
 */
export const processMessageDeletionQueue = functions.pubsub
  .schedule("every 15 minutes")
  .onRun(async () => {
    const now = Date.now();

    try {
      // Get all deletion entries that are due
      const snapshot = await rtdb
        .ref("message_deletion_queue")
        .orderByChild("deleteAt")
        .endAt(now)
        .once("value");

      if (!snapshot.exists()) {
        console.log("No messages to delete");
        return null;
      }

      const deletions: Record<string, unknown> = snapshot.val();
      const batch = db.batch();
      const rtdbUpdates: Record<string, null> = {};

      for (const [queueId, data] of Object.entries(deletions)) {
        const { matchId, messageId, userId } = data as {
          matchId: string;
          messageId: string;
          userId: string;
        };

        try {
          // Remove user from visibleTo array in Firestore
          const messageRef = db
            .collection("matches")
            .doc(matchId)
            .collection("messages")
            .doc(messageId);

          const messageDoc = await messageRef.get();
          if (messageDoc.exists) {
            const visibleTo: string[] = messageDoc.data()?.visibleTo || [];
            const newVisibleTo = visibleTo.filter((uid) => uid !== userId);

            if (newVisibleTo.length === 0) {
              // No one can see it anymore, delete the message entirely
              batch.delete(messageRef);
            } else {
              // Update visibleTo to remove this user
              batch.update(messageRef, { visibleTo: newVisibleTo });
            }
          }

          // Mark for removal from queue
          rtdbUpdates[`message_deletion_queue/${queueId}`] = null;
        } catch (err) {
          console.error(`Failed to process deletion ${queueId}:`, err);
        }
      }

      // Execute Firestore batch
      await batch.commit();

      // Remove processed entries from RTDB queue
      if (Object.keys(rtdbUpdates).length > 0) {
        await rtdb.ref().update(rtdbUpdates);
      }

      console.log(
        `Processed ${Object.keys(deletions).length} message deletions`,
      );
      return null;
    } catch (error) {
      console.error("Error processing deletion queue:", error);
      return null;
    }
  });

/**
 * Scheduled function to cleanup expired message requests. (R-113 fix)
 * Runs every hour to delete message_requests past their 48-hour expiration.
 * This ensures expired requests are cleaned up even if neither user fetches them.
 */
export const cleanupExpiredMessageRequests = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const now = new Date();

    try {
      // Query all message_requests where expiresAt is in the past
      const snapshot = await db
        .collection("message_requests")
        .where("expiresAt", "<", now)
        .limit(500) // Process in batches to avoid timeout
        .get();

      if (snapshot.empty) {
        console.log("No expired message requests to cleanup");
        return null;
      }

      // Delete expired requests in a batch
      const batch = db.batch();
      let count = 0;

      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        count++;
      }

      await batch.commit();
      console.log(`Cleaned up ${count} expired message requests`);

      // If we hit the limit, there might be more - log for monitoring
      if (count === 500) {
        console.log("Hit batch limit - more expired requests may exist");
      }

      return null;
    } catch (error) {
      console.error("Error cleaning up expired message requests:", error);
      return null;
    }
  });

/**
 * Callable function for users to update their chat settings.
 */
export const updateChatSettings = callable<{ extendedRetention: boolean }>(
  async (request, context) => {
    const uid = requireAuth(context, "update chat settings");
    const { extendedRetention } = request;

    if (typeof extendedRetention !== "boolean") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "extendedRetention must be a boolean",
      );
    }

    // Update Firestore
    await db
      .collection("users")
      .doc(uid)
      .set(
        {
          profile: {
            chatSettings: {
              extendedRetention,
            },
          },
        },
        { merge: true },
      );

    // Sync to RTDB
    await syncChatSettingsToRtdb(uid);

    const retentionHours = extendedRetention
      ? RETENTION_FREE_EXTENDED
      : RETENTION_FREE_DEFAULT;

    return {
      success: true,
      extendedRetention,
      retentionHours,
      message: extendedRetention
        ? "Messages will be deleted 24 hours after being read"
        : "Messages will be deleted 1 hour after being read",
    };
  },
);

/**
 * Callable function for users to update chat settings for a specific match.
 * This allows per-conversation message retention settings.
 */
export const updateMatchChatSettings = callable<{
  matchId: string;
  extendedRetention: boolean;
}>(async (request, context) => {
  const uid = requireAuth(context, "update match chat settings");
  const { matchId, extendedRetention } = request;

  if (typeof matchId !== "string" || !matchId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "matchId is required",
    );
  }

  if (typeof extendedRetention !== "boolean") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "extendedRetention must be a boolean",
    );
  }

  // Verify user is part of this match
  const matchDoc = await db.collection("matches").doc(matchId).get();
  if (!matchDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Match not found");
  }

  const matchData = matchDoc.data();
  const userIds: string[] = matchData?.userIds || [];
  if (!userIds.includes(uid)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You are not part of this match",
    );
  }

  // Store per-user chat settings for this match
  // Each user in the match can have their own retention settings
  await db
    .collection("matches")
    .doc(matchId)
    .set(
      {
        chatSettings: {
          [uid]: {
            extendedRetention,
            updatedAt: Date.now(),
          },
        },
      },
      { merge: true },
    );

  // Also sync to RTDB for real-time access
  await rtdb.ref(`matches/${matchId}/chatSettings/${uid}`).set({
    extendedRetention,
    updatedAt: Date.now(),
  });

  const retentionHours = extendedRetention
    ? RETENTION_FREE_EXTENDED
    : RETENTION_FREE_DEFAULT;

  return {
    success: true,
    matchId,
    extendedRetention,
    retentionHours,
    message: extendedRetention
      ? "Messages in this chat will be deleted 24 hours after being read"
      : "Messages in this chat will be deleted 1 hour after being read",
  };
});

/**
 * Trigger when user's plan changes to sync chat settings.
 * Plus users automatically get 7-day retention.
 */
export const onPlanChangeUpdateChatSettings = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { userId } = context.params;

    // Check if plan changed
    if (before.plan === after.plan) return;

    // Sync chat settings to RTDB
    await syncChatSettingsToRtdb(userId);
    console.log(`Synced chat settings for ${userId} after plan change`);
  });

// Chat settings HTTP endpoint
app.put(
  "/v1/chat/settings",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { extended_retention } = req.body;

      if (typeof extended_retention !== "boolean") {
        return res
          .status(400)
          .json({ error: "extended_retention must be a boolean" });
      }

      // Update Firestore
      await db
        .collection("users")
        .doc(req.uid!)
        .set(
          {
            profile: {
              chatSettings: {
                extendedRetention: extended_retention,
              },
            },
          },
          { merge: true },
        );

      // Sync to RTDB
      await syncChatSettingsToRtdb(req.uid!);

      // Get user's actual retention hours (considers Plus status)
      const retentionHours = await getUserRetentionHours(req.uid!);

      res.json({
        success: true,
        extended_retention,
        retention_hours: retentionHours,
        message: extended_retention
          ? "Messages will be deleted 24 hours after being read"
          : "Messages will be deleted 1 hour after being read",
      });
    } catch (err) {
      console.error("Update chat settings error:", err);
      return res.status(500).json({ error: "Failed to update chat settings" });
    }
  },
);

// Get chat settings
app.get(
  "/v1/chat/settings",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const userDoc = await db.collection("users").doc(req.uid!).get();
      const userData = userDoc.data();
      const isPremium = userData?.plan === "plus";
      const extendedRetention =
        userData?.profile?.chatSettings?.extendedRetention === true;

      let retentionHours: number;
      if (isPremium) {
        retentionHours = RETENTION_PLUS;
      } else {
        retentionHours = extendedRetention
          ? RETENTION_FREE_EXTENDED
          : RETENTION_FREE_DEFAULT;
      }

      res.json({
        extended_retention: extendedRetention,
        is_premium: isPremium,
        retention_hours: retentionHours,
        retention_description: isPremium
          ? "Messages are kept for 7 days after being read (Plus benefit)"
          : extendedRetention
            ? "Messages are deleted 24 hours after being read"
            : "Messages are deleted 1 hour after being read",
      });
    } catch (err) {
      console.error("Get chat settings error:", err);
      return res.status(500).json({ error: "Failed to get chat settings" });
    }
  },
);

// =============================================================================
// ACCOUNT DELETION — Scheduled + Callable (CR-AUD-010)
// =============================================================================

const DELETION_GRACE_PERIOD_DAYS = 14;

/**
 * Membership fields a match document may use across the codebase. Account
 * deletion must query all of them — matches are created with `users`/`userIds`,
 * so querying only `participants` would leave a deleted user's matches and chat
 * history behind.
 */
const MATCH_MEMBERSHIP_FIELDS = ["users", "userIds", "participants"] as const;

/**
 * Participant fields a top-level `message_requests` document is keyed by. These
 * MUST match how the document is written: the mobile client and security rules
 * store the sender/recipient as `fromUserId`/`toUserId` (NOT
 * `senderId`/`recipientId`). Account deletion queries both so a deleted user's
 * pre-match request content and PII are scrubbed regardless of direction.
 */
const MESSAGE_REQUEST_PARTICIPANT_FIELDS = ["fromUserId", "toUserId"] as const;

/**
 * Top-level relation collections (equality-keyed by user id) that an account
 * deletion must scrub. Outgoing records are the user's own personal data;
 * inbound like/swipe pointers are removed to avoid orphaned references. Inbound
 * blocks/reports ABOUT the user are intentionally omitted so abuse history
 * survives the deletion.
 */
function userRelationDeletionTargets(): Array<{
  collection: string;
  field: string;
  label: string;
}> {
  return [
    { collection: "likes", field: "fromUserId", label: "likes(fromUserId)" },
    { collection: "swipes", field: "swiperId", label: "swipes(swiperId)" },
    { collection: "blocks", field: "blockerId", label: "blocks(blockerId)" },
    { collection: "reports", field: "reporterId", label: "reports(reporterId)" },
    { collection: "likes", field: "toUserId", label: "likes(toUserId)" },
    { collection: "swipes", field: "targetId", label: "swipes(targetId)" },
  ];
}

/**
 * Cloud Storage prefixes an account deletion must sweep for [uid]. Covers BOTH
 * the production Firebase-client paths and the legacy REST backend paths so no
 * user media is orphaned:
 *   - users/{uid}/...                profile photos, videos, stories, media (prod)
 *   - verification/{uid}/...         ID verification documents (sensitive PII)
 *   - photos/{uid}/...               legacy REST profile photos
 *   - chat_media/{uid}/...           legacy/REST chat media
 *   - chat_media/{matchId}/{uid}/... chat media this user uploaded (prod)
 */
function userStorageDeletionPrefixes(
  uid: string,
  matchIds: Iterable<string>,
): string[] {
  return [
    `users/${uid}/`,
    `verification/${uid}/`,
    `photos/${uid}/`,
    `chat_media/${uid}/`,
    ...[...matchIds].map((matchId) => `chat_media/${matchId}/${uid}/`),
  ];
}

/**
 * Delete every document matched by [query] in paginated batches, recording the
 * outcome into [deleted]/[errors]. Firestore batches cap at 500 ops, so this
 * pages until the query is drained.
 */
async function deleteDocsByQuery(
  query: FirebaseFirestore.Query,
  label: string,
  deleted: string[],
  errors: string[],
): Promise<void> {
  try {
    let total = 0;
    for (;;) {
      const snap = await query.limit(400).get();
      if (snap.empty) break;
      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      total += snap.size;
      if (snap.size < 400) break;
    }
    if (total > 0) {
      deleted.push(`${label} (${total} docs)`);
    }
  } catch (error) {
    errors.push(
      `${label}: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

/**
 * Helper: Cascading deletion of all user data across Firestore, RTDB, Storage, and Auth.
 * This is the nuclear option — permanently removes all traces of a user.
 */
async function cascadeDeleteUserData(uid: string): Promise<{
  deleted: string[];
  errors: string[];
}> {
  const deleted: string[] = [];
  const errors: string[] = [];
  // Match ids this user belonged to, captured so we can also delete the chat
  // media they uploaded under `chat_media/{matchId}/{uid}/` (step 6).
  const userMatchIds = new Set<string>();

  // 1. Delete user's matches and related subcollections. Matches are keyed by
  // one of several membership fields across the codebase, so query all of them
  // and dedupe by document id before deleting.
  try {
    const matchSnapshots = await Promise.all(
      MATCH_MEMBERSHIP_FIELDS.map((field) =>
        db.collection("matches").where(field, "array-contains", uid).get(),
      ),
    );
    const matchDocs = new Map<
      string,
      FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
    >();
    for (const snap of matchSnapshots) {
      for (const doc of snap.docs) {
        matchDocs.set(doc.id, doc);
      }
    }

    for (const matchDoc of matchDocs.values()) {
      userMatchIds.add(matchDoc.id);
      // Delete messages subcollection
      const messagesSnapshot = await matchDoc.ref
        .collection("messages")
        .limit(500)
        .get();
      const batch = db.batch();
      messagesSnapshot.docs.forEach((msgDoc) => batch.delete(msgDoc.ref));
      if (messagesSnapshot.size > 0) {
        await batch.commit();
        deleted.push(
          `matches/${matchDoc.id}/messages (${messagesSnapshot.size} docs)`,
        );
      }

      // Delete the match document itself
      await matchDoc.ref.delete();
      deleted.push(`matches/${matchDoc.id}`);
    }
  } catch (error) {
    errors.push(
      `matches cleanup: ${error instanceof Error ? error.message : String(error)}`,
    );
  }

  // 2. Delete user's blocks, reports, likes
  for (const subcollection of [
    "blocked",
    "reports",
    "likes_given",
    "likes_received",
  ]) {
    try {
      const subcollRef = db
        .collection("users")
        .doc(uid)
        .collection(subcollection);
      const snapshot = await subcollRef.limit(500).get();
      if (snapshot.size > 0) {
        const batch = db.batch();
        snapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        deleted.push(`users/${uid}/${subcollection} (${snapshot.size} docs)`);
      }
    } catch (error) {
      errors.push(
        `${subcollection}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // 3. Delete message_requests involving this user
  try {
    const [sentField, receivedField] = MESSAGE_REQUEST_PARTICIPANT_FIELDS;
    const sentRequests = await db
      .collection("message_requests")
      .where(sentField, "==", uid)
      .get();
    const receivedRequests = await db
      .collection("message_requests")
      .where(receivedField, "==", uid)
      .get();
    const batch = db.batch();
    sentRequests.docs.forEach((doc) => batch.delete(doc.ref));
    receivedRequests.docs.forEach((doc) => batch.delete(doc.ref));
    const total = sentRequests.size + receivedRequests.size;
    if (total > 0) {
      await batch.commit();
      deleted.push(`message_requests (${total} docs)`);
    }
  } catch (error) {
    errors.push(
      `message_requests: ${error instanceof Error ? error.message : String(error)}`,
    );
  }

  // 3b. Scrub the user's footprint in top-level relation collections (likes,
  // swipes, blocks, reports). These are equality-keyed by user id and are not
  // stored under users/{uid}, so the subcollection cleanup above misses them.
  for (const target of userRelationDeletionTargets()) {
    await deleteDocsByQuery(
      db.collection(target.collection).where(target.field, "==", uid),
      target.label,
      deleted,
      errors,
    );
  }

  // 4. Delete account tracking records
  for (const collection of ["account_deletions", "account_deactivations"]) {
    try {
      const docRef = db.collection(collection).doc(uid);
      const docSnap = await docRef.get();
      if (docSnap.exists) {
        await docRef.delete();
        deleted.push(`${collection}/${uid}`);
      }
    } catch (error) {
      errors.push(
        `${collection}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // 5. Delete auth credentials
  try {
    const credRef = db.collection("auth_credentials").doc(uid);
    const credSnap = await credRef.get();
    if (credSnap.exists) {
      await credRef.delete();
      deleted.push(`auth_credentials/${uid}`);
    }
  } catch (error) {
    errors.push(
      `auth_credentials: ${error instanceof Error ? error.message : String(error)}`,
    );
  }

  // 6. Delete Cloud Storage files. Cover ALL paths the user's media can live
  // under, across the production Firebase client and the legacy REST backend:
  //   - users/{uid}/...           profile photos, videos, stories, media (prod)
  //   - verification/{uid}/...    ID verification documents (sensitive PII)
  //   - photos/{uid}/...          legacy REST profile photos
  //   - chat_media/{uid}/...      legacy/REST chat media
  //   - chat_media/{matchId}/{uid}/...  chat media this user uploaded (prod)
  // Each prefix is swept independently so one failure cannot orphan the rest.
  const bucket = admin.storage().bucket();
  const storagePrefixes = userStorageDeletionPrefixes(uid, userMatchIds);
  for (const prefix of storagePrefixes) {
    try {
      const [files] = await bucket.getFiles({ prefix });
      for (const file of files) {
        await file.delete();
      }
      if (files.length > 0) {
        deleted.push(`storage:${prefix} (${files.length} files)`);
      }
    } catch (error) {
      errors.push(
        `storage ${prefix}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  // 7. Delete RTDB data (presence, typing indicators, etc.)
  try {
    await rtdb.ref(`presence/${uid}`).remove();
    await rtdb.ref(`typing/${uid}`).remove();
    await rtdb.ref(`last_seen/${uid}`).remove();
    deleted.push("rtdb:presence,typing,last_seen");
  } catch (error) {
    errors.push(
      `rtdb: ${error instanceof Error ? error.message : String(error)}`,
    );
  }

  // 8. Delete the user document from Firestore
  try {
    await db.collection("users").doc(uid).delete();
    deleted.push(`users/${uid}`);
  } catch (error) {
    errors.push(
      `users doc: ${error instanceof Error ? error.message : String(error)}`,
    );
  }

  // 9. Delete Firebase Auth user (last step — no recovery after this)
  try {
    await admin.auth().deleteUser(uid);
    deleted.push(`auth:${uid}`);
  } catch (error) {
    // auth/user-not-found is OK — user may have already been deleted
    const authError = error as { code?: string; message?: string };
    if (authError?.code !== "auth/user-not-found") {
      errors.push(
        `auth delete: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  return { deleted, errors };
}

/**
 * Scheduled function: Process pending account deletions.
 * Runs every 6 hours. Finds accounts where:
 * - isPendingDeletion=true AND deletionScheduledAt has passed
 * - isDeactivated=true AND scheduledDeletionAt has passed (6-month auto-delete)
 */
export const processScheduledAccountDeletions = functions.pubsub
  .schedule("every 6 hours")
  .onRun(async () => {
    const now = new Date();
    let processedCount = 0;
    let errorCount = 0;

    // Process pending deletions (14-day grace period expired)
    try {
      const pendingSnapshot = await db
        .collection("users")
        .where("isPendingDeletion", "==", true)
        .where("deletionScheduledAt", "<", now)
        .limit(50)
        .get();

      for (const userDoc of pendingSnapshot.docs) {
        const uid = userDoc.id;
        console.log(`Processing scheduled deletion for user: ${uid}`);

        const result = await cascadeDeleteUserData(uid);

        if (result.errors.length > 0) {
          console.error(`Deletion errors for ${uid}:`, result.errors);
          errorCount++;
        } else {
          console.log(
            `Successfully deleted all data for user: ${uid}`,
            result.deleted,
          );
          processedCount++;
        }
      }
    } catch (error) {
      console.error("Error processing pending deletions:", error);
    }

    // Process deactivated accounts (6-month auto-delete)
    try {
      const deactivatedSnapshot = await db
        .collection("users")
        .where("isDeactivated", "==", true)
        .where("scheduledDeletionAt", "<", now)
        .limit(50)
        .get();

      for (const userDoc of deactivatedSnapshot.docs) {
        const uid = userDoc.id;
        console.log(`Processing auto-deletion for deactivated user: ${uid}`);

        const result = await cascadeDeleteUserData(uid);

        if (result.errors.length > 0) {
          console.error(`Auto-deletion errors for ${uid}:`, result.errors);
          errorCount++;
        } else {
          console.log(
            `Successfully auto-deleted deactivated user: ${uid}`,
            result.deleted,
          );
          processedCount++;
        }
      }
    } catch (error) {
      console.error("Error processing deactivated account deletions:", error);
    }

    console.log(
      `Account deletion run complete: ${processedCount} processed, ${errorCount} errors`,
    );
    return null;
  });

/**
 * Callable: Request account deletion (with 14-day grace period).
 * Called from both web and mobile apps.
 * Sets isPendingDeletion=true and schedules deletion for 14 days later.
 */
export const requestAccountDeletion = functions.https.onCall(
  async (data, context) => {
    verifyCallableAppCheck(context, "requestAccountDeletion");
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be signed in to delete account.",
      );
    }

    const uid = context.auth.uid;
    const reason =
      typeof data?.reason === "string"
        ? data.reason.slice(0, 500)
        : "Not specified";

    const deletionDate = new Date();
    deletionDate.setDate(deletionDate.getDate() + DELETION_GRACE_PERIOD_DAYS);

    try {
      // Mark account for scheduled deletion
      await db.collection("users").doc(uid).update({
        isPendingDeletion: true,
        deletionRequestedAt: serverTimestamp(),
        deletionScheduledAt: deletionDate,
        deletionReason: reason,
      });

      // Create tracking record
      await db.collection("account_deletions").doc(uid).set({
        uid,
        reason,
        requestedAt: serverTimestamp(),
        scheduledAt: deletionDate,
        status: "pending",
      });

      console.log(
        `Account deletion requested for ${uid}, scheduled for ${deletionDate.toISOString()}`,
      );

      return {
        success: true,
        scheduledAt: deletionDate.toISOString(),
        gracePeriodDays: DELETION_GRACE_PERIOD_DAYS,
        message: `Your account is scheduled for deletion on ${deletionDate.toLocaleDateString()}. Sign back in within ${DELETION_GRACE_PERIOD_DAYS} days to cancel.`,
      };
    } catch (error) {
      console.error("requestAccountDeletion error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to process deletion request.",
      );
    }
  },
);

/**
 * Callable: Cancel a pending account deletion (recovery within grace period).
 * Called when a user signs in while their account is pending deletion.
 */
export const cancelAccountDeletion = functions.https.onCall(
  async (_data, context) => {
    verifyCallableAppCheck(context, "cancelAccountDeletion");
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be signed in.",
      );
    }

    const uid = context.auth.uid;

    try {
      const userDoc = await db.collection("users").doc(uid).get();
      const userData = userDoc.data();

      if (!userData?.isPendingDeletion) {
        return { success: true, message: "No pending deletion to cancel." };
      }

      // Check if still within grace period
      const scheduledAt =
        userData.deletionScheduledAt?.toDate?.() ||
        userData.deletionScheduledAt;
      if (scheduledAt && new Date() > new Date(scheduledAt)) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Grace period has expired. Account deletion cannot be cancelled.",
        );
      }

      // Clear deletion flags
      await db.collection("users").doc(uid).update({
        isPendingDeletion: false,
        deletionRequestedAt: deleteField(),
        deletionScheduledAt: deleteField(),
        deletionReason: deleteField(),
      });

      // Update tracking record
      await db.collection("account_deletions").doc(uid).update({
        status: "cancelled",
        cancelledAt: serverTimestamp(),
      });

      console.log(`Account deletion cancelled for ${uid}`);

      return {
        success: true,
        message: "Account deletion has been cancelled. Welcome back!",
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      console.error("cancelAccountDeletion error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to cancel deletion.",
      );
    }
  },
);

const DATA_EXPORT_COOLDOWN_DAYS = 7;
const DATA_EXPORT_URL_TTL_MS = 7 * 24 * 60 * 60 * 1000;

function asRecord(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null
    ? (value as Record<string, unknown>)
    : {};
}

function toIsoString(value: unknown): string | null {
  if (!value) return null;
  const timestampCtor = (
    admin.firestore as unknown as {
      Timestamp?: { new (...args: unknown[]): { toDate: () => Date } };
    }
  )?.Timestamp;
  if (typeof timestampCtor === "function" && value instanceof timestampCtor) {
    return value.toDate().toISOString();
  }
  if (
    typeof value === "object" &&
    value !== null &&
    typeof (value as { toDate?: unknown }).toDate === "function"
  ) {
    const date = (value as { toDate: () => Date }).toDate();
    return date instanceof Date && !Number.isNaN(date.getTime())
      ? date.toISOString()
      : null;
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value === "string") {
    return value;
  }
  return null;
}

function normalizeDate(value: unknown): Date | null {
  if (!value) return null;
  const timestampCtor = (
    admin.firestore as unknown as {
      Timestamp?: { new (...args: unknown[]): { toDate: () => Date } };
    }
  )?.Timestamp;
  if (typeof timestampCtor === "function" && value instanceof timestampCtor) {
    return value.toDate();
  }
  if (
    typeof value === "object" &&
    value !== null &&
    typeof (value as { toDate?: unknown }).toDate === "function"
  ) {
    const date = (value as { toDate: () => Date }).toDate();
    return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null;
  }
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

/**
 * GDPR Art.20: User can request a portable copy of personal data.
 * Creates an async export job document, processed by Firestore trigger below.
 */
export const requestDataExport = callable<DataExportRequest>(
  async (_data, context) => {
    const uid = requireAuth(context, "request data export");
    requireEmailVerified(context, "request data export");

    const requestsRef = db
      .collection("users")
      .doc(uid)
      .collection("dataExportRequests");
    const latestRequest = await requestsRef
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();

    if (!latestRequest.empty) {
      const latestData = latestRequest.docs[0].data();
      const lastCreatedAt = normalizeDate(latestData.createdAt);
      if (lastCreatedAt) {
        const nextAllowedAt = new Date(lastCreatedAt.getTime());
        nextAllowedAt.setDate(
          nextAllowedAt.getDate() + DATA_EXPORT_COOLDOWN_DAYS,
        );
        if (nextAllowedAt.getTime() > Date.now()) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Data export can only be requested once every 7 days.",
            { nextAllowedAt: nextAllowedAt.toISOString() },
          );
        }
      }
    }

    const requestRef = requestsRef.doc();
    await requestRef.set({
      userId: uid,
      status: "queued",
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    return {
      requestId: requestRef.id,
      status: "queued",
    };
  },
);

/**
 * Async export worker.
 * Triggered on users/{uid}/dataExportRequests/{requestId} create.
 */
export const processDataExportRequest = functions.firestore
  .document("users/{userId}/dataExportRequests/{requestId}")
  .onCreate(async (snapshot, context) => {
    const userId = context.params.userId;
    const requestId = context.params.requestId;
    const requestRef = snapshot.ref;

    try {
      await requestRef.set(
        {
          status: "processing",
          startedAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        },
        { merge: true },
      );

      const userSnap = await db.collection("users").doc(userId).get();
      const userData = asRecord(userSnap.data());
      const profileData = asRecord(userData.profile);
      const preferencesData = asRecord(profileData.preferences);

      let matchesSnap = await db
        .collection("matches")
        .where("userIds", "array-contains", userId)
        .get();
      if (matchesSnap.empty) {
        matchesSnap = await db
          .collection("matches")
          .where("participants", "array-contains", userId)
          .get();
      }

      const matches = matchesSnap.docs.map((doc) => {
        const data = asRecord(doc.data());
        return {
          id: doc.id,
          userIds: Array.isArray(data.userIds)
            ? data.userIds
            : Array.isArray(data.participants)
              ? data.participants
              : [],
          status: data.status ?? "unknown",
          createdAt: toIsoString(data.createdAt),
          updatedAt: toIsoString(data.updatedAt),
        };
      });

      const likesGivenSnap = await db
        .collection("likes")
        .where("fromUserId", "==", userId)
        .limit(2000)
        .get();
      const likesReceivedSnap = await db
        .collection("likes")
        .where("toUserId", "==", userId)
        .limit(2000)
        .get();

      const likesGiven = likesGivenSnap.docs.map((doc) => {
        const data = asRecord(doc.data());
        return {
          id: doc.id,
          toUserId: data.toUserId ?? null,
          attachedMessage: data.attachedMessage ?? null,
          createdAt: toIsoString(data.createdAt),
        };
      });

      const likesReceived = likesReceivedSnap.docs.map((doc) => {
        const data = asRecord(doc.data());
        return {
          id: doc.id,
          fromUserId: data.fromUserId ?? null,
          attachedMessage: data.attachedMessage ?? null,
          createdAt: toIsoString(data.createdAt),
        };
      });

      const messages: Array<Record<string, unknown>> = [];
      for (const matchDoc of matchesSnap.docs) {
        const messagesSnap = await matchDoc.ref
          .collection("messages")
          .limit(3000)
          .get();
        for (const messageDoc of messagesSnap.docs) {
          const messageData = asRecord(messageDoc.data());
          messages.push({
            id: messageDoc.id,
            matchId: matchDoc.id,
            fromUserId: messageData.fromUserId ?? null,
            toUserId: messageData.toUserId ?? null,
            content: messageData.content ?? "",
            type: messageData.type ?? "text",
            sentAt: toIsoString(messageData.sentAt),
            isRead: Boolean(messageData.isRead),
          });
        }
      }

      const stats = {
        matchesCount: matches.length,
        likesGivenCount: likesGiven.length,
        likesReceivedCount: likesReceived.length,
        messagesCount: messages.length,
      };

      const exportPayload: Record<string, unknown> = {
        exportDate: new Date().toISOString(),
        exportVersion: "2.0-cloud",
        userId,
        account: {
          email: userData.email ?? null,
          phoneNumber: userData.phoneNumber ?? null,
          username: userData.username ?? null,
          plan: userData.plan ?? "free",
          isEmailVerified: Boolean(userData.isEmailVerified),
          isPhoneVerified: Boolean(userData.isPhoneVerified),
          createdAt: toIsoString(userData.createdAt),
        },
        profile: profileData,
        preferences: preferencesData,
        matches,
        likesGiven,
        likesReceived,
        messages,
        stats,
      };

      const bucket = admin.storage().bucket();
      const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
      const filePath = `exports/${userId}/export_${timestamp}_${requestId}.json`;
      const file = bucket.file(filePath);

      const downloadToken = crypto.randomUUID();
      await file.save(JSON.stringify(exportPayload, null, 2), {
        metadata: {
          contentType: "application/json",
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
          },
        },
      });

      let downloadUrl: string;
      try {
        const [signedUrl] = await file.getSignedUrl({
          action: "read",
          expires: Date.now() + DATA_EXPORT_URL_TTL_MS,
        });
        downloadUrl = signedUrl;
      } catch (signedUrlError) {
        // Fallback for environments where the runtime service account
        // cannot sign blobs (iam.serviceAccounts.signBlob).
        const encodedPath = encodeURIComponent(filePath);
        downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;
        console.warn("Falling back to token-based download URL", {
          userId,
          requestId,
          error:
            signedUrlError instanceof Error
              ? signedUrlError.message
              : String(signedUrlError),
        });
      }

      await requestRef.set(
        {
          status: "completed",
          completedAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
          filePath,
          downloadUrl,
          stats,
        },
        { merge: true },
      );

      await smartSendNotification(userId, "subscriptions", {
        title: "Your data export is ready",
        body: "Tap to download your export package.",
        data: {
          type: "data_export_ready",
          targetRoute: "/settings/account-actions",
          requestId,
        },
      });
    } catch (error) {
      console.error("processDataExportRequest failed", {
        userId,
        requestId,
        error,
      });
      await requestRef.set(
        {
          status: "failed",
          failedAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
          error: error instanceof Error ? error.message : String(error),
        },
        { merge: true },
      );
    }
  });

// =============================================================================
// CR-AUD-030: Chat media signed URL endpoint
// Verifies match participation before returning a time-limited signed URL
// =============================================================================

interface ChatMediaUrlRequest {
  matchId?: string;
  filePath?: string;
}

export const getChatMediaSignedUrl = callable<ChatMediaUrlRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "access chat media");
    requireEmailVerified(context, "access chat media");
    const matchId = requireString(data?.matchId, "matchId");
    const filePath = requireString(data?.filePath, "filePath", 500);

    // Verify the user is a participant in this match
    const matchDoc = await db.collection("matches").doc(matchId).get();
    if (!matchDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Match not found.");
    }

    const matchData = matchDoc.data();
    const participants: string[] =
      matchData?.users ?? matchData?.participants ?? [];
    if (!participants.includes(uid)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You are not a participant in this match.",
      );
    }

    // Validate the file path is within the expected chat media paths
    const isValidPath =
      filePath.startsWith(`chat_media/${matchId}/`) ||
      filePath.startsWith(`chats/${matchId}/`);
    if (!isValidPath) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid file path for this match.",
      );
    }

    // Generate a signed URL (1 hour expiry)
    const bucket = admin.storage().bucket();
    const file = bucket.file(filePath);

    const [exists] = await file.exists();
    if (!exists) {
      throw new functions.https.HttpsError("not-found", "File not found.");
    }

    const [signedUrl] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + 60 * 60 * 1000, // 1 hour
    });

    return { url: signedUrl };
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// SEC-BE-008: AUTOMATED FIRESTORE BACKUP
// Daily export to Cloud Storage with 30-day retention.
// Bucket lifecycle must be configured manually:
//   gsutil lifecycle set '{"rule":[{"action":{"type":"Delete"},"condition":{"age":30}}]}' gs://BACKUP_BUCKET
// ═══════════════════════════════════════════════════════════════════════════

export const scheduledFirestoreBackup = functions.pubsub
  .schedule("every 24 hours")
  .timeZone("UTC")
  .onRun(async () => {
    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!projectId) {
      console.error("FirestoreBackup: Could not determine project ID");
      return null;
    }

    const bucketName = `${projectId}-firestore-backups`;
    const timestamp = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    const outputUri = `gs://${bucketName}/${timestamp}`;

    try {
      const client = new admin.firestore.v1.FirestoreAdminClient();
      const databaseName = client.databasePath(projectId, "(default)");

      const [operation] = await client.exportDocuments({
        name: databaseName,
        outputUriPrefix: outputUri,
        collectionIds: [], // Empty = all collections
      });

      console.log(
        `FirestoreBackup: Export started to ${outputUri}`,
        `Operation: ${operation.name}`,
      );

      return null;
    } catch (error) {
      console.error("FirestoreBackup: Export failed:", error);
      return null;
    }
  });
