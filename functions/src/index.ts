import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import bcrypt from "bcryptjs";
import { BigQuery } from "@google-cloud/bigquery";
import Stripe from "stripe";
import { RtcTokenBuilder, RtcRole } from "agora-access-token";
import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import multer from "multer";

const bigquery = new BigQuery();
const BQ_DATASET = "crushhour_ml";
const BQ_TABLE_INTERACTIONS = "interaction_events";

// Safe BigQuery insert - logs interaction events but doesn't fail the main operation
async function logInteractionEvent(eventData: Record<string, unknown>): Promise<void> {
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
const fieldValue = (admin.firestore as unknown as { FieldValue?: { serverTimestamp?: () => unknown; increment?: (n: number) => unknown; delete?: () => unknown } })
  ?.FieldValue;
const serverTimestamp = () =>
  fieldValue?.serverTimestamp ? fieldValue.serverTimestamp() : new Date();
const incrementBy = (value: number) =>
  fieldValue?.increment ? fieldValue.increment(value) : value;
const deleteField = () => (fieldValue?.delete ? fieldValue.delete() : null);

const config = ((functions as unknown as { config?: () => unknown }).config?.() ??
  {}) as {
    stripe?: { secret?: string; webhook_secret?: string };
    agora?: { appid?: string; certificate?: string };
    auth?: { otp_secret?: string };
    email?: { resend_key?: string; from?: string };
    cors?: { allowed_origins?: string };
  };

// CORS configuration - comma-separated list of allowed origins
// Set via: firebase functions:config:set cors.allowed_origins="https://crushhour.app,https://app.crushhour.app"
const corsAllowedOrigins = (
  config.cors?.allowed_origins ??
  process.env.CORS_ALLOWED_ORIGINS ??
  ""
).split(",").filter(Boolean);

// Default to strict CORS in production, allow localhost in development
const isDevelopment = process.env.FUNCTIONS_EMULATOR === "true";
const corsOriginValidator = (
  origin: string | undefined,
  callback: (err: Error | null, allow?: boolean) => void
) => {
  // Allow requests with no origin (mobile apps, curl, etc.)
  if (!origin) {
    callback(null, true);
    return;
  }
  // In development, allow localhost
  if (isDevelopment && (origin.includes("localhost") || origin.includes("127.0.0.1"))) {
    callback(null, true);
    return;
  }
  // Check against whitelist
  if (corsAllowedOrigins.length === 0 || corsAllowedOrigins.includes(origin)) {
    callback(null, true);
    return;
  }
  callback(new Error(`Origin ${origin} not allowed by CORS`), false);
};
const stripeSecret = config.stripe?.secret ?? "";
const stripeWebhookSecret = config.stripe?.webhook_secret ?? "";
const agoraAppId = config.agora?.appid ?? process.env.AGORA_APP_ID;
const agoraCertificate =
  config.agora?.certificate ?? process.env.AGORA_APP_CERTIFICATE;
const authOtpSecret = config.auth?.otp_secret ?? process.env.OTP_SECRET ?? "";
const emailResendKey = config.email?.resend_key ?? process.env.RESEND_API_KEY;
const emailFrom = config.email?.from ?? "CrushHour <no-reply@crushhour.app>";

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

const PROFILE_MIN_PHOTOS = 1;
const PROFILE_MIN_PROMPTS = 0; // Prompts are optional for swiping
const PROFILE_MIN_BIO_LENGTH = 10; // Only 10 characters needed
const PROFILE_MIN_INTERESTS = 3;
const DAILY_LIKE_LIMIT_FREE = 30;
const DAILY_LIKE_LIMIT_PLUS = 300;
const HOURLY_LIKE_LIMIT_FREE = 10; // Hourly throttle for free users
const HOURLY_LIKE_LIMIT_PLUS = 50; // Hourly throttle for plus users
const DISCOVERY_PAGE_SIZE = 120;

// Content moderation - comprehensive banned terms list
const BANNED_TERMS = [
  // Violence and threats
  "kill", "murder", "threat", "terror", "bomb", "attack", "weapon", "shoot",
  // Hate speech
  "hate", "racist", "nazi", "supremacist",
  // Explicit profanity (core)
  "shit", "fuck", "bitch", "cunt", "ass hole", "bastard",
  // Spam and scam indicators
  "spam", "scam", "wire money", "western union", "moneygram", "bitcoin wallet",
  "crypto investment", "forex trading", "click here", "act now",
  // Solicitation
  "escort", "prostitute", "pay for sex", "sugar daddy arrangement",
  // Contact info harvesting
  "whatsapp me", "telegram me", "kik me", "snapchat me",
  // Drugs
  "buy drugs", "sell drugs", "cocaine", "heroin", "meth",
];

type CallableContext = functions.https.CallableContext;
type CallableHandler<TData> = (
  data: TData,
  context: CallableContext
) => Promise<unknown>;

const isHttpsError = (err: unknown): err is functions.https.HttpsError => {
  return err instanceof functions.https.HttpsError;
};

function toAuthHttpsError(
  err: unknown
): functions.https.HttpsError | null {
  const code = (err as { code?: unknown })?.code;
  if (typeof code !== "string") return null;

  switch (code) {
    case "auth/email-already-exists":
      return new functions.https.HttpsError(
        "already-exists",
        "That email is already in use."
      );
    case "auth/invalid-email":
      return new functions.https.HttpsError(
        "invalid-argument",
        "Enter a valid email address."
      );
    case "auth/invalid-password":
      return new functions.https.HttpsError(
        "invalid-argument",
        `Use at least ${PASSWORD_MIN_LENGTH} characters.`
      );
    case "auth/uid-already-exists":
      return new functions.https.HttpsError(
        "already-exists",
        "Account already exists."
      );
    default:
      return null;
  }
}

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

const OTP_DIGITS = 6;
const OTP_TTL_MS = 10 * 60 * 1000;
const OTP_VERIFY_MAX_ATTEMPTS = 5;
const OTP_VERIFY_LOCK_MS = 15 * 60 * 1000;
const OTP_RESEND_COOLDOWN_MS = 60 * 1000;
const OTP_REQUEST_LIMIT = 5;
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
const PASSWORD_MIN_LENGTH = 8;
const PASSWORD_SALT_ROUNDS = 12;
const USERNAME_REGEX = /^[a-zA-Z0-9_]{3,20}$/;
const EMAIL_REGEX = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
// OTP secret is required - never fall back to a predictable value
const otpSecret = authOtpSecret;
if (!authOtpSecret) {
  console.error("CRITICAL: auth.otp_secret not configured. OTP functions will fail.");
}

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
  if (!otpSecret) {
    throw new functions.https.HttpsError(
      "internal",
      "OTP service not configured. Please contact support."
    );
  }
  return crypto.createHmac("sha256", otpSecret).update(`${salt}:${value}`).digest("hex");
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
  blockMs: number
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
      { merge: true }
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
    { retryAfterMs: retryAfterMs ?? 60000 }
  );
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
  if (!emailResendKey) {
    console.warn("RESEND_API_KEY not set; skipping email send.");
    return;
  }
  const subject = "Your CrushHour verification code";
  const text = [
    "Hello,",
    "",
    `Your CrushHour verification code is: ${params.otp}`,
    "This code expires in 10 minutes and can only be used once.",
    "",
    "If you did not request this, you can ignore this email.",
    "",
    "Thanks,",
    "CrushHour Security",
  ].join("\\n");
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${emailResendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: emailFrom,
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
  if (!emailResendKey) {
    console.warn("RESEND_API_KEY not set; skipping email send.");
    return;
  }
  const subject = "Your CrushHour password was changed";
  const methodText =
    params.method === "forgot_password"
      ? "using the forgot password feature"
      : "from within the app";
  const text = [
    "Hello,",
    "",
    `Your CrushHour account password was recently changed ${methodText}.`,
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
    "CrushHour Security Team",
  ].join("\\n");
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${emailResendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: emailFrom,
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
  if (!emailResendKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Email notifications are not configured."
    );
  }
  const subject = `${params.creatorName} shared a CrushHour date plan`;
  const lines = [
    `Hi ${params.contactName},`,
    "",
    `${params.creatorName} shared their date plan with you in CrushHour.`,
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
    "CrushHour Safety Team"
  );
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${emailResendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: emailFrom,
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
      "Invalid OTP purpose."
    );
  }
  return purpose as EmailOtpPurpose;
}

function hashIdentifier(identifier: string): string {
  if (!otpSecret) {
    throw new functions.https.HttpsError(
      "internal",
      "OTP service not configured. Please contact support."
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

async function verifyPassword(password: string, hash: string): Promise<boolean> {
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
    { merge: true }
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
        OTP_REQUEST_BLOCK_MS
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
      OTP_REQUEST_BLOCK_MS
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
          "Enter a valid email address."
        );
      }
      targetEmail = normalizeEmail(emailInput);
      resolvedUid = uid;
      try {
        const existing = await admin.auth().getUserByEmail(targetEmail);
        if (existing.uid !== uid) {
          targetEmail = undefined;
        }
      } catch (_) {}
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
  }
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
        "Enter the 6-digit code."
      );
    }

    if (ip) {
      const ipLimit = await applyRateLimit(
        `otp:verify:ip:${ip}`,
        OTP_VERIFY_LIMIT,
        OTP_VERIFY_WINDOW_MS,
        OTP_VERIFY_BLOCK_MS
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
      OTP_VERIFY_BLOCK_MS
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

    const now = Date.now();
    let matchedDoc:
      | FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
      | null = null;
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
        updates.lockedUntil = new Date(
          now + OTP_VERIFY_LOCK_MS
        );
      }
      await doc.ref.update(updates);
    }

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
        "Invalid or expired code."
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
          "Invalid or expired code."
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
          "Enter a valid email address."
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
            "Could not verify email. Try again."
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
        { merge: true }
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
          `Use at least ${PASSWORD_MIN_LENGTH} characters.`
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
            console.error("Failed to send password changed email:", err)
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
  }
);

export const claimUsername = callable<ClaimUsernameRequest>(
  async (data, context) => {
    const uid = requireAuth(context, "claim a username");
    const usernameRaw = requireString(data?.username, "username");
    const trimmed = usernameRaw.trim();
    if (!USERNAME_REGEX.test(trimmed)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Username must be 3-20 characters and use letters, numbers, or underscores."
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
            "That username is taken."
          );
        }
      }
      tx.set(
        usernameRef,
        {
          uid,
          createdAt: serverTimestamp(),
        },
        { merge: true }
      );
      tx.set(
        userRef,
        {
          username: trimmed,
          usernameLower,
        },
        { merge: true }
      );
    });

    await logAuthAudit({
      action: "claim_username",
      status: "ok",
      uid,
      metadata: { username: usernameLower },
    });

    return { status: "ok", username: trimmed };
  }
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
      "Username must be 3-20 characters and use letters, numbers, or underscores."
    );
  }
  if (!isEmailLike(email)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Enter a valid email address."
    );
  }
  if (passwordRaw.length < PASSWORD_MIN_LENGTH) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Use at least ${PASSWORD_MIN_LENGTH} characters.`
    );
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
      SIGNUP_ATTEMPT_BLOCK_MS
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
    SIGNUP_ATTEMPT_BLOCK_MS
  );
  const usernameLimit = await applyRateLimit(
    `signup:username:${usernameHash}`,
    SIGNUP_ATTEMPT_LIMIT,
    SIGNUP_ATTEMPT_WINDOW_MS,
    SIGNUP_ATTEMPT_BLOCK_MS
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
  } catch (_) {}

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
      "Could not create account. Check your details and try again."
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
          "Username is not available."
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
      "Could not create account. Please try again."
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
        OTP_REQUEST_BLOCK_MS
      )
    : { allowed: true };
  const idLimit = await applyRateLimit(
    `otp:req:id:${identifierHash}`,
    OTP_REQUEST_LIMIT,
    OTP_REQUEST_WINDOW_MS,
    OTP_REQUEST_BLOCK_MS
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
      "Invalid or expired code."
    );
  }

  const email = normalizeEmail(emailRaw);
  const identifierHash = hashIdentifier(email);
  const ipLimit = ip
    ? await applyRateLimit(
        `otp:verify:ip:${ip}`,
        OTP_VERIFY_LIMIT,
        OTP_VERIFY_WINDOW_MS,
        OTP_VERIFY_BLOCK_MS
      )
    : { allowed: true };
  const idLimit = await applyRateLimit(
    `otp:verify:id:${identifierHash}`,
    OTP_VERIFY_LIMIT,
    OTP_VERIFY_WINDOW_MS,
    OTP_VERIFY_BLOCK_MS
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

  const now = Date.now();
  let matchedDoc:
    | FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
    | null = null;
  let matchedData: FirebaseFirestore.DocumentData | undefined;
  for (const doc of candidates.docs) {
    const data = doc.data();
    const usedAt = toMillis(data.usedAt, 0);
    const expiresAt = toMillis(data.expiresAt, 0);
    const lockedUntil = toMillis(data.lockedUntil, 0);
    if (usedAt) continue;
    if (expiresAt && expiresAt < now) continue;
    if (lockedUntil && lockedUntil > now) continue;

    const computed = hashOtpValue(otpRaw, data.otpSalt as string);
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
      updates.lockedUntil = new Date(
        now + OTP_VERIFY_LOCK_MS
      );
    }
    await doc.ref.update(updates);
  }

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
      "Invalid or expired code."
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
    expiresAt: new Date(now + RESET_TOKEN_TTL_MS),
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
      "Invalid reset request."
    );
  }

  if (newPassword.length < PASSWORD_MIN_LENGTH) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Use at least ${PASSWORD_MIN_LENGTH} characters.`
    );
  }

  const email = normalizeEmail(emailRaw);
  const identifierHash = hashIdentifier(email);
  const ipLimit = ip
    ? await applyRateLimit(
        `reset:ip:${ip}`,
        RESET_ATTEMPT_LIMIT,
        RESET_ATTEMPT_WINDOW_MS,
        RESET_ATTEMPT_BLOCK_MS
      )
    : { allowed: true };
  const idLimit = await applyRateLimit(
    `reset:id:${identifierHash}`,
    RESET_ATTEMPT_LIMIT,
    RESET_ATTEMPT_WINDOW_MS,
    RESET_ATTEMPT_BLOCK_MS
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
  let matchedDoc:
    | FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
    | null = null;
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
      "Invalid reset request."
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
      console.error("Failed to send password changed email:", err)
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
  }
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
      LOGIN_ATTEMPT_BLOCK_MS
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
    LOGIN_ATTEMPT_BLOCK_MS
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
      "Invalid credentials."
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
  }
);

export const requestPasswordReset = callable<PasswordResetRequest>(
  async (data, context) => {
    const emailRaw =
      typeof data?.email === "string" ? data.email.trim() : "";
    const ip = getClientIp(context);
    const userAgent =
      context.rawRequest?.headers?.["user-agent"]?.toString() ?? undefined;
    return requestPasswordResetCore({
      emailRaw,
      ip,
      userAgent,
    });
  }
);

export const verifyPasswordResetOtp = callable<PasswordResetVerifyRequest>(
  async (data, context) => {
    const emailRaw =
      typeof data?.email === "string" ? data.email.trim() : "";
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
  }
);

export const resetPasswordWithToken = callable<PasswordResetFinalizeRequest>(
  async (data, context) => {
    const emailRaw =
      typeof data?.email === "string" ? data.email.trim() : "";
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
  }
);

export const changePassword = callable<ChangePasswordRequest>(
  async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to change your password."
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
        "Current password is required."
      );
    }

    if (newPassword.length < PASSWORD_MIN_LENGTH) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `New password must be at least ${PASSWORD_MIN_LENGTH} characters.`
      );
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
          LOGIN_ATTEMPT_BLOCK_MS
        )
      : { allowed: true };
    const idLimit = await applyRateLimit(
      `change_password:uid:${uid}`,
      LOGIN_ATTEMPT_LIMIT,
      LOGIN_ATTEMPT_WINDOW_MS,
      LOGIN_ATTEMPT_BLOCK_MS
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
        "No password set for this account."
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
        "Current password is incorrect."
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
        console.error("Failed to send password changed email:", err)
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
  }
);

type ProfileData = {
  name?: string;
  lastName?: string;
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

  // Update Firestore
  await db.collection("users").doc(uid).set(payload, { merge: true });

  // Sync premium status to RTDB for real-time feature access control
  // Premium users get: presence visibility, typing indicators, read receipts, last seen
  const isPremium = plan === "plus";
  await rtdb.ref(`premium_users/${uid}`).set(isPremium ? true : null);
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
      "You cannot interact with this user."
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

function setCorsHeaders(res: functions.Response, req?: functions.Request) {
  // Use whitelisted origin or default for server-to-server requests
  const origin = req?.headers?.origin;
  const allowedOrigin = origin && corsAllowedOrigins.includes(origin) ? origin : corsAllowedOrigins[0] || "";
  if (allowedOrigin) {
    res.set("Access-Control-Allow-Origin", allowedOrigin);
  }
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, stripe-signature");
}

function getRequestIp(req: functions.Request): string | undefined {
  const forwarded = req.headers["x-forwarded-for"];
  if (Array.isArray(forwarded)) {
    return forwarded[0]?.toString();
  }
  if (typeof forwarded === "string") {
    return forwarded.split(",")[0]?.trim();
  }
  return req.ip;
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
          lastFlaggedAt: serverTimestamp(),
          autoFlags: incrementBy(1),
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
    const dailyLikes = (data.dailyLikes as Record<string, number> | undefined) ?? {};
    const dailyCount = dailyLikes[todayKey] ?? 0;
    if (dailyCount >= dailyLimit) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        `Daily like limit reached (${dailyLimit}). Try again tomorrow.`
      );
    }

    // Check hourly limit (throttling)
    const hourlyLikes = (data.hourlyLikes as Record<string, number> | undefined) ?? {};
    const hourlyCount = hourlyLikes[hourKey] ?? 0;
    if (hourlyCount >= hourlyLimit) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        `Slow down! You've liked ${hourlyLimit} profiles this hour. Try again in a bit.`
      );
    }

    // Increment both counters
    dailyLikes[todayKey] = dailyCount + 1;
    hourlyLikes[hourKey] = hourlyCount + 1;

    // Clean up old hourly keys (keep only last 24 hours)
    const cutoffHour = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString().slice(0, 13);
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
      { merge: true }
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
        "Enter a valid contact email."
      );
    }
    const matchNameRaw = requireString(data?.matchName, "matchName");
    const locationRaw = requireString(data?.location, "location");
    const dateTimeMs = toNumber(data?.dateTimeMs);
    if (dateTimeMs == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "dateTimeMs is required."
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
      DATE_PLAN_EMAIL_BLOCK_MS
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
      "A CrushHour user";
    const creatorName = truncateString(creatorNameRaw, 80);

    const safeOffset = Math.max(-14 * 60, Math.min(14 * 60, timeZoneOffsetMinutes));
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
  }
);

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
    createdAt: serverTimestamp(),
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
          lastReportAt: serverTimestamp(),
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
      createdAt: serverTimestamp(),
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
      { typing: { [uid]: isTyping }, typingUpdatedAt: serverTimestamp() },
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
          lastSeenAt: serverTimestamp(),
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
        mediaUpdatedAt: serverTimestamp(),
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
        reactionsUpdatedAt: serverTimestamp(),
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
        reactions: { [uid]: deleteField() },
        reactionsUpdatedAt: serverTimestamp(),
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
        unmatchedAt: serverTimestamp(),
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
          reviewedAt: serverTimestamp(),
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

    // Build query - don't filter by hideFromDiscovery/incognitoMode in query
    // because new users may not have these fields set yet.
    // We'll filter them out in the candidate processing loop instead.
    let query: FirebaseFirestore.Query = db
      .collection("users")
      .limit(DISCOVERY_PAGE_SIZE);

    // Handle showMeGenders filter - skip filter for 'All', 'everyone', or empty
    // This allows users to see all genders when they haven't set a preference
    const skipGenderFilter =
      showMeGenders.length === 0 ||
      showMeGenders.some((g) =>
        ["all", "everyone", "any"].includes(g.toLowerCase())
      );

    if (!skipGenderFilter && showMeGenders.length <= 10) {
      query = query.where("profile.gender", "in", showMeGenders);
    }
    if (myCountry) {
      query = query.where("profile.country", "==", myCountry);
    }

    let snap: FirebaseFirestore.QuerySnapshot;
    try {
      snap = await query.get();
    } catch (err) {
      // Fallback to broader query if filters fail
      snap = await db
        .collection("users")
        .limit(DISCOVERY_PAGE_SIZE)
        .get();
    }

    const candidates: Array<{
      id: string;
      profile: ProfileData;
      username?: string;
      score: number;
      distanceKm?: number;
    }> = [];

    snap.forEach((doc) => {
      if (doc.id === uid) return;
      if (blockedIds.has(doc.id)) return;
      const data = doc.data() as Record<string, unknown>;
      const candidateProfile = (data.profile as ProfileData | undefined) ?? null;
      if (!candidateProfile) return;

      // Filter out users who have explicitly opted out of discovery
      const prefs = candidateProfile.preferences as Record<string, unknown> | undefined;
      if (prefs?.hideFromDiscovery === true) return;
      if (prefs?.incognitoMode === true) return;

      // Filter out incomplete profiles (must have at least 1 photo and a name)
      const photos = toStringArray(candidateProfile.photoUrls);
      const name = typeof candidateProfile.name === "string" ? candidateProfile.name : "";
      if (photos.length < 1 || !name) return;

      const age = toNumber((candidateProfile as any).age);
      if (age && (age < minAge || age > maxAge)) return;
      const lat = toNumber(candidateProfile.latitude);
      const lon = toNumber(candidateProfile.longitude);
      const distanceKm = haversineDistanceKm(myLat, myLon, lat, lon);

      // Distance filtering - be lenient for users without location
      // Users without location should still appear in discovery, just with lower priority
      let noLocationPenalty = 0;
      if (distanceKm !== undefined && distanceKm > maxDistanceKm + 5) {
        // Has location but too far - only exclude if really far (2x distance)
        if (distanceKm > maxDistanceKm * 2) {
          return;
        }
        // Between maxDistance and 2x maxDistance - keep but penalize score
        noLocationPenalty = 0.3;
      }

      // For users without location: use country as soft filter, not hard filter
      // This ensures new users appear in discovery even without location permission
      const candCountry =
        typeof candidateProfile.country === "string" ? candidateProfile.country : "";
      if (!lat || !lon) {
        // No location - apply penalty but DON'T exclude
        // Only exclude if both have different countries AND searching user has location
        if (myLat && myLon && myCountry && candCountry && candCountry !== myCountry) {
          // Different country and searcher has location - exclude only if really far
          // For now, include them with penalty to help new users get discovered
          noLocationPenalty = 0.4;
        } else if (!candCountry && !myCountry) {
          // Both have no country info - include with small penalty
          noLocationPenalty = 0.2;
        } else {
          // Same country or missing data - include with small penalty
          noLocationPenalty = 0.15;
        }
      }

      const interests = toStringArray(candidateProfile.interests);
      const sharedInterests = interests.filter((i) => myInterests.has(i)).length;
      const verifiedBoost =
        candidateProfile.verificationBadge || candidateProfile.isVerified ? 0.4 : 0;
      const distanceBoost =
        distanceKm !== undefined && maxDistanceKm > 0
          ? Math.max(0, (maxDistanceKm - distanceKm) / maxDistanceKm)
          : 0.1; // Give users without location a small distance boost
      const interestBoost = Math.min(sharedInterests * 0.05, 0.25);
      // Apply no-location penalty to score so users with location appear first
      const baseScore = 1 + verifiedBoost + distanceBoost + interestBoost - noLocationPenalty;

      // Get username from user document level (not nested in profile)
      const username = typeof data.username === "string" ? data.username : undefined;

      candidates.push({
        id: doc.id,
        profile: candidateProfile,
        username,
        score: baseScore,
        distanceKm,
      });
    });

    candidates.sort((a, b) => (b.score ?? 0) - (a.score ?? 0));

    const limited = candidates.slice(0, limit);
    return {
      // Return as 'candidates' with flattened profile data (client expects this format)
      candidates: limited.map((c) => ({
        id: c.id,
        userId: c.id, // Alternative key for compatibility
        ...c.profile, // Flatten profile fields to top level
        username: c.username, // Username from user document level
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
        lastRequestAt: serverTimestamp(),
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
    unsentAt: serverTimestamp(),
  });

  return { ok: true };
});

// Send message (for matched users)
export const sendMessage = callable<SendMessageRequest>(async (data, context) => {
  const uid = requireAuth(context, "send messages");
  const matchId = requireString(data?.matchId, "matchId");
  const toUserId = requireString(data?.toUserId, "toUserId");
  const content = optionalString(data?.content);
  const type = optionalString(data?.type) ?? "text";
  const mediaUrl = optionalString(data?.mediaUrl);

  // Validate content - must have content or mediaUrl
  if (!content && !mediaUrl) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Message must have content or media."
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
      "You are not part of this match."
    );
  }

  // Verify toUserId is the other participant
  if (!userIds.includes(toUserId)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Recipient is not part of this match."
    );
  }

  if (toUserId === uid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Cannot send message to yourself."
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
  await db.collection("matches").doc(matchId).update({
    lastMessageAt: serverTimestamp(),
    lastMessageContent: content ? truncateString(content, 100) : null,
    lastMessageType: type,
    lastMessageFromUserId: uid,
  });

  return {
    ok: true,
    messageId: messageRef.id,
  };
});

// Mark messages as read
export const markMessagesRead = callable<MarkMessagesReadRequest>(async (data, context) => {
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
      "You are not part of this match."
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
  await db.collection("matches").doc(matchId).update({
    [`readBy.${uid}`]: readAt,
  });

  return { ok: true, markedCount: unreadMessagesSnap.size };
});

// Edit message (sender only)
export const editMessage = callable<EditMessageRequest>(async (data, context) => {
  const uid = requireAuth(context, "edit messages");
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
      "You are not part of this match."
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
      "You can only edit your own messages."
    );
  }

  // Update the message
  await msgRef.update({
    content,
    isEdited: true,
    editedAt: serverTimestamp(),
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
    setCorsHeaders(res, req);
    res.status(204).send("");
    return;
  }

  setCorsHeaders(res, req);

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

    const photos = toStringArray(profile?.photoUrls);
    const prompts = toStringArray(profile?.prompts);
    const interests = toStringArray(profile?.interests);
    const bio =
      typeof profile?.bio === "string" ? (profile.bio as string).trim() : "";
    const country = typeof profile?.country === "string" ? profile.country : "";
    const city = typeof profile?.city === "string" ? profile.city : "";

    // Calculate breakdown scores (0-100 for each category)
    // Required: 1 photo, 10 char bio, 3 interests, city + country
    // Prompts are optional (recommended only)
    const photoScore = Math.min(100, (photos.length / PROFILE_MIN_PHOTOS) * 100);
    const bioScore = Math.min(100, (bio.length / PROFILE_MIN_BIO_LENGTH) * 100);
    const promptsScore = prompts.length > 0 ? 100 : 0; // Just for tracking, not required
    const interestsScore = Math.min(
      100,
      (interests.length / PROFILE_MIN_INTERESTS) * 100
    );
    const locationScore = city && country ? 100 : 0;

    const breakdown: Record<string, number> = {
      photos: photoScore,
      bio: bioScore,
      prompts: promptsScore,
      interests: interestsScore,
      location: locationScore,
    };

    // Calculate overall weighted score (prompts excluded - optional)
    const weights = {
      photos: 0.30,
      bio: 0.25,
      interests: 0.25,
      location: 0.20,
    };
    const score =
      photoScore * weights.photos +
      bioScore * weights.bio +
      interestsScore * weights.interests +
      locationScore * weights.location;

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

    // Thresholds - must complete all required fields (100%)
    const swipeThreshold = 100;
    const messagingThreshold = 100;

    const meetsSwipeMinimum = score >= swipeThreshold;
    const meetsMessagingMinimum = score >= messagingThreshold;
    const meetsRequiredFields = requiredMissing.length === 0;
    const threshold = minimum === "messaging" ? messagingThreshold : swipeThreshold;
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
  }
);

// ═══════════════════════════════════════════════════════════════════════════
// REST API
// ═══════════════════════════════════════════════════════════════════════════

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

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
  next: NextFunction
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

// Optional auth middleware (doesn't fail if no token)
async function optionalAuth(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith("Bearer ")) {
    const token = authHeader.split("Bearer ")[1];
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      req.uid = decoded.uid;
      req.user = decoded;
    } catch (err) {
      // Ignore auth errors for optional auth
    }
  }
  next();
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Send OTP
app.post("/v1/auth/otp/send", async (req: Request, res: Response) => {
  try {
    const { phone_number } = req.body;
    if (!phone_number) {
      return res.status(400).json({ error: "Phone number is required" });
    }

    // Generate and store OTP
    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const verificationId = crypto.randomUUID();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

    await db.collection("phone_verifications").doc(verificationId).set({
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
});

// Verify OTP
app.post("/v1/auth/otp/verify", async (req: Request, res: Response) => {
  try {
    const { phone_number, otp, verification_id } = req.body;
    if (!phone_number || !otp) {
      return res.status(400).json({ error: "Phone number and OTP required" });
    }

    // Find verification
    let verificationDoc;
    if (verification_id) {
      verificationDoc = await db.collection("phone_verifications").doc(verification_id).get();
    } else {
      const query = await db.collection("phone_verifications")
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
});

// Refresh token
app.post("/v1/auth/token/refresh", async (req: Request, res: Response) => {
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
});

// Logout
app.post("/v1/auth/logout", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    // Revoke refresh tokens
    await admin.auth().revokeRefreshTokens(req.uid!);
    res.json({ success: true });
  } catch (err) {
    console.error("Logout error:", err);
    return res.status(500).json({ error: "Failed to logout" });
  }
});

// Change password
app.post("/v1/auth/password/change", authMiddleware, async (req: AuthRequest, res: Response) => {
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
          LOGIN_ATTEMPT_BLOCK_MS
        )
      : { allowed: true };
    const idLimit = await applyRateLimit(
      `change_password:uid:${uid}`,
      LOGIN_ATTEMPT_LIMIT,
      LOGIN_ATTEMPT_WINDOW_MS,
      LOGIN_ATTEMPT_BLOCK_MS
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
      return res.status(400).json({ error: "No password set for this account." });
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
      return res.status(400).json({ error: "Current password is incorrect." });
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
        console.error("Failed to send password changed email:", err)
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
});

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get current user profile
app.get("/v1/profile/me", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const userDoc = await db.collection("users").doc(req.uid!).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: "User not found" });
    }

    const data = userDoc.data() || {};
    const profile = data.profile || {};

    res.json({
      id: req.uid,
      phone_number: data.phoneNumber,
      email: data.email,
      email_verified: data.emailVerified || false,
      phone_verified: true,
      is_premium: data.plan === "plus",
      display_name: profile.name || profile.displayName,
      bio: profile.bio,
      birth_date: profile.birthDate,
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
      prompts: profile.prompts || [],
      preferences: data.preferences || {},
    });
  } catch (err) {
    console.error("Get profile error:", err);
    return res.status(500).json({ error: "Failed to get profile" });
  }
});

// Update profile
app.patch("/v1/profile/me", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const updates: Record<string, unknown> = {};
    const profileUpdates: Record<string, unknown> = {};

    // Map request fields to profile fields
    const fieldMap: Record<string, string> = {
      display_name: "profile.name",
      bio: "profile.bio",
      birth_date: "profile.birthDate",
      gender: "profile.gender",
      job_title: "profile.jobTitle",
      company: "profile.company",
      education: "profile.education",
      city: "profile.city",
      country: "profile.country",
      interests: "profile.interests",
    };

    for (const [reqField, dbField] of Object.entries(fieldMap)) {
      if (req.body[reqField] !== undefined) {
        updates[dbField] = req.body[reqField];
      }
    }

    updates["profile.updatedAt"] = serverTimestamp();

    await db.collection("users").doc(req.uid!).update(updates);

    res.json({ success: true, message: "Profile updated" });
  } catch (err) {
    console.error("Update profile error:", err);
    return res.status(500).json({ error: "Failed to update profile" });
  }
});

// Upload photo
app.post(
  "/v1/profile/photos",
  authMiddleware,
  upload.single("photo"),
  async (req: AuthRequest, res: Response) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      const isPrimary = req.body.is_primary === "true";
      const bucket = admin.storage().bucket();
      const fileName = `photos/${req.uid}/${Date.now()}_${req.file.originalname}`;
      const file = bucket.file(fileName);

      await file.save(req.file.buffer, {
        metadata: { contentType: req.file.mimetype },
      });

      await file.makePublic();
      const url = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      // Update user's photo array
      const userDoc = await db.collection("users").doc(req.uid!).get();
      const userData = userDoc.data() || {};
      const profile = userData.profile || {};
      const photos = profile.photoUrls || [];

      if (isPrimary) {
        photos.unshift(url);
      } else {
        photos.push(url);
      }

      await db.collection("users").doc(req.uid!).update({
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
      return res.status(500).json({ error: "Failed to upload photo" });
    }
  }
);

// Delete photo
app.delete(
  "/v1/profile/photos/:photoId",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { photoId } = req.params;
      const userDoc = await db.collection("users").doc(req.uid!).get();
      const userData = userDoc.data() || {};
      const profile = userData.profile || {};
      const photos: string[] = profile.photoUrls || [];

      // Find and remove the photo (photoId format: photo_INDEX or contains URL)
      const index = parseInt(photoId.replace("photo_", ""));
      if (!isNaN(index) && index < photos.length) {
        photos.splice(index, 1);
      }

      await db.collection("users").doc(req.uid!).update({
        "profile.photoUrls": photos,
        "profile.updatedAt": serverTimestamp(),
      });

      res.json({ success: true });
    } catch (err) {
      console.error("Delete photo error:", err);
      return res.status(500).json({ error: "Failed to delete photo" });
    }
  }
);

// Update preferences
app.patch(
  "/v1/profile/preferences",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      await db.collection("users").doc(req.uid!).update({
        preferences: req.body,
        updatedAt: serverTimestamp(),
      });

      res.json({ success: true });
    } catch (err) {
      console.error("Update preferences error:", err);
      return res.status(500).json({ error: "Failed to update preferences" });
    }
  }
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
        age: profile.age,
        gender: profile.gender,
        city: profile.city,
        photos: (profile.photoUrls || []).map((url: string, i: number) => ({
          id: `photo_${i}`,
          url,
          is_primary: i === 0,
        })),
        interests: profile.interests || [],
        prompts: profile.prompts || [],
        is_verified: data.idVerified || false,
      });
    } catch (err) {
      console.error("Get profile error:", err);
      return res.status(500).json({ error: "Failed to get profile" });
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// DISCOVERY ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get discovery deck
app.get("/v1/discovery/deck", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const userDoc = await db.collection("users").doc(req.uid!).get();
    const userData = userDoc.data() || {};
    const preferences = userData.preferences || {};

    // Get users the current user has already swiped on
    const swipesSnap = await db.collection("swipes")
      .where("swiperId", "==", req.uid)
      .get();
    const swipedUserIds = new Set(swipesSnap.docs.map(doc => doc.data().targetId));
    swipedUserIds.add(req.uid!); // Exclude self

    // Query potential matches
    let query = db.collection("users")
      .where("profile.isComplete", "==", true)
      .limit(DISCOVERY_PAGE_SIZE);

    // Apply gender filter if set
    if (preferences.genderPreference && preferences.genderPreference !== "all") {
      query = query.where("profile.gender", "==", preferences.genderPreference);
    }

    const usersSnap = await query.get();

    const profiles = usersSnap.docs
      .filter(doc => !swipedUserIds.has(doc.id))
      .slice(0, 20) // Limit to 20 for the deck
      .map(doc => {
        const data = doc.data();
        const profile = data.profile || {};
        return {
          id: doc.id,
          display_name: profile.name || profile.displayName,
          age: profile.age,
          bio: profile.bio,
          city: profile.city,
          photos: (profile.photoUrls || []).map((url: string, i: number) => ({
            url,
            is_primary: i === 0,
          })),
          interests: profile.interests || [],
          prompts: profile.prompts || [],
          is_verified: data.idVerified || false,
          distance_km: null, // Would calculate based on location
        };
      });

    res.json({
      profiles,
      total_count: profiles.length,
      has_more: profiles.length >= 20,
    });
  } catch (err) {
    console.error("Get deck error:", err);
    return res.status(500).json({ error: "Failed to get discovery deck" });
  }
});

// Swipe
app.post("/v1/discovery/swipe", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { target_user_id, action, message } = req.body;
    if (!target_user_id || !action) {
      return res.status(400).json({ error: "target_user_id and action required" });
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
      const mutualSwipe = await db.collection("swipes")
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
});

// Activate boost
app.post("/v1/discovery/boost", authMiddleware, async (req: AuthRequest, res: Response) => {
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
});

// ─────────────────────────────────────────────────────────────────────────────
// MATCHES ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get matches
app.get("/v1/matches", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const offset = parseInt(req.query.offset as string) || 0;
    const limit = parseInt(req.query.limit as string) || 20;

    const matchesSnap = await db.collection("matches")
      .where("users", "array-contains", req.uid)
      .orderBy("lastMessageAt", "desc")
      .offset(offset)
      .limit(limit)
      .get();

    const matches = await Promise.all(
      matchesSnap.docs.map(async (doc) => {
        const data = doc.data();
        const otherUserId = data.users.find((id: string) => id !== req.uid);
        const otherUserDoc = await db.collection("users").doc(otherUserId).get();
        const otherUserData = otherUserDoc.data() || {};
        const profile = otherUserData.profile || {};

        return {
          id: doc.id,
          matched_user_id: otherUserId,
          matched_user_name: profile.name || profile.displayName,
          matched_user_photo: (profile.photoUrls || [])[0],
          created_at: data.createdAt?.toDate?.()?.toISOString(),
          last_message_at: data.lastMessageAt?.toDate?.()?.toISOString(),
        };
      })
    );

    res.json({
      matches,
      total_count: matches.length,
      has_more: matches.length >= limit,
    });
  } catch (err) {
    console.error("Get matches error:", err);
    return res.status(500).json({ error: "Failed to get matches" });
  }
});

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
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// CHAT ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Get conversations
app.get("/v1/chat/conversations", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const matchesSnap = await db.collection("matches")
      .where("users", "array-contains", req.uid)
      .orderBy("lastMessageAt", "desc")
      .limit(50)
      .get();

    const conversations = await Promise.all(
      matchesSnap.docs.map(async (doc) => {
        const data = doc.data();
        const otherUserId = data.users.find((id: string) => id !== req.uid);
        const otherUserDoc = await db.collection("users").doc(otherUserId).get();
        const otherUserData = otherUserDoc.data() || {};
        const profile = otherUserData.profile || {};

        // Get last message
        const lastMsgSnap = await db.collection("matches").doc(doc.id)
          .collection("messages")
          .orderBy("createdAt", "desc")
          .limit(1)
          .get();
        const lastMsg = lastMsgSnap.docs[0]?.data();

        return {
          id: doc.id,
          participant: {
            id: otherUserId,
            name: profile.name || profile.displayName,
            photo_url: (profile.photoUrls || [])[0],
          },
          last_message: lastMsg ? {
            content: lastMsg.content,
            type: lastMsg.type || "text",
            sent_at: lastMsg.createdAt?.toDate?.()?.toISOString(),
          } : null,
          updated_at: data.lastMessageAt?.toDate?.()?.toISOString(),
        };
      })
    );

    res.json({ conversations });
  } catch (err) {
    console.error("Get conversations error:", err);
    return res.status(500).json({ error: "Failed to get conversations" });
  }
});

// Get messages
app.get(
  "/v1/chat/:conversationId/messages",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { conversationId } = req.params;
      const limit = parseInt(req.query.limit as string) || 50;
      const before = req.query.before as string;

      let query = db.collection("matches").doc(conversationId)
        .collection("messages")
        .orderBy("createdAt", "desc")
        .limit(limit);

      if (before) {
        const beforeDoc = await db.collection("matches").doc(conversationId)
          .collection("messages").doc(before).get();
        if (beforeDoc.exists) {
          query = query.startAfter(beforeDoc);
        }
      }

      const messagesSnap = await query.get();

      const messages = messagesSnap.docs.map((doc) => {
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
      }).reverse();

      res.json({ messages });
    } catch (err) {
      console.error("Get messages error:", err);
      return res.status(500).json({ error: "Failed to get messages" });
    }
  }
);

// Send message
app.post(
  "/v1/chat/:conversationId/send",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { conversationId } = req.params;
      const { type, content, media_url } = req.body;

      const messageRef = await db.collection("matches").doc(conversationId)
        .collection("messages")
        .add({
          senderId: req.uid,
          content: content || null,
          type: type || "text",
          mediaUrl: media_url || null,
          createdAt: serverTimestamp(),
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
      console.error("Send message error:", err);
      return res.status(500).json({ error: "Failed to send message" });
    }
  }
);

// Upload media for chat
app.post(
  "/v1/chat/:conversationId/media",
  authMiddleware,
  upload.single("media"),
  async (req: AuthRequest, res: Response) => {
    try {
      const { conversationId } = req.params;
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      const bucket = admin.storage().bucket();
      const fileName = `chat/${conversationId}/${Date.now()}_${req.file.originalname}`;
      const file = bucket.file(fileName);

      await file.save(req.file.buffer, {
        metadata: { contentType: req.file.mimetype },
      });

      await file.makePublic();
      const url = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      res.json({ url });
    } catch (err) {
      console.error("Upload media error:", err);
      return res.status(500).json({ error: "Failed to upload media" });
    }
  }
);

// Mark messages as read
app.post(
  "/v1/chat/:conversationId/read",
  authMiddleware,
  async (req: AuthRequest, res: Response) => {
    try {
      const { conversationId } = req.params;

      // Update read status
      await db.collection("matches").doc(conversationId).update({
        [`readBy.${req.uid}`]: serverTimestamp(),
      });

      res.json({ success: true });
    } catch (err) {
      console.error("Mark read error:", err);
      return res.status(500).json({ error: "Failed to mark as read" });
    }
  }
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
            name: "CrushHour+",
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

      if (!customerId && stripeSecret) {
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
      if (stripeSecret) {
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
      return res.status(500).json({ error: "Failed to create checkout session" });
    }
  }
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
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// SAFETY ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// Block user
app.post("/v1/users/block", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { blocked_id } = req.body;
    if (!blocked_id) {
      return res.status(400).json({ error: "blocked_id required" });
    }

    await db.collection("blocks").add({
      blockerId: req.uid,
      blockedId: blocked_id,
      createdAt: serverTimestamp(),
    });

    res.json({ success: true });
  } catch (err) {
    console.error("Block error:", err);
    return res.status(500).json({ error: "Failed to block user" });
  }
});

// Unblock user
app.post("/v1/users/unblock", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { blocked_id } = req.body;
    if (!blocked_id) {
      return res.status(400).json({ error: "blocked_id required" });
    }

    const blockSnap = await db.collection("blocks")
      .where("blockerId", "==", req.uid)
      .where("blockedId", "==", blocked_id)
      .limit(1)
      .get();

    if (!blockSnap.empty) {
      await blockSnap.docs[0].ref.delete();
    }

    res.json({ success: true });
  } catch (err) {
    console.error("Unblock error:", err);
    return res.status(500).json({ error: "Failed to unblock user" });
  }
});

// Report user
app.post("/v1/users/report", authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { reported_id, reason, description, match_id, message_id } = req.body;
    if (!reported_id || !reason) {
      return res.status(400).json({ error: "reported_id and reason required" });
    }

    await db.collection("reports").add({
      reporterId: req.uid,
      reportedId: reported_id,
      reason,
      description: description || null,
      matchId: match_id || null,
      messageId: message_id || null,
      status: "pending",
      createdAt: serverTimestamp(),
    });

    res.json({ success: true });
  } catch (err) {
    console.error("Report error:", err);
    return res.status(500).json({ error: "Failed to report user" });
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
  const extendedRetention = userData?.profile?.chatSettings?.extendedRetention === true;

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
  readAt: Date
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

      console.log(`Processed ${Object.keys(deletions).length} message deletions`);
      return null;
    } catch (error) {
      console.error("Error processing deletion queue:", error);
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
        "extendedRetention must be a boolean"
      );
    }

    // Update Firestore
    await db.collection("users").doc(uid).set(
      {
        profile: {
          chatSettings: {
            extendedRetention,
          },
        },
      },
      { merge: true }
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
  }
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
      "matchId is required"
    );
  }

  if (typeof extendedRetention !== "boolean") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "extendedRetention must be a boolean"
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
      "You are not part of this match"
    );
  }

  // Store per-user chat settings for this match
  // Each user in the match can have their own retention settings
  await db.collection("matches").doc(matchId).set(
    {
      chatSettings: {
        [uid]: {
          extendedRetention,
          updatedAt: Date.now(),
        },
      },
    },
    { merge: true }
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
        return res.status(400).json({ error: "extended_retention must be a boolean" });
      }

      // Update Firestore
      await db.collection("users").doc(req.uid!).set(
        {
          profile: {
            chatSettings: {
              extendedRetention: extended_retention,
            },
          },
        },
        { merge: true }
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
  }
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
  }
);
