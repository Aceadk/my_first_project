import * as functions from "firebase-functions/v1";

export type CallableContext = functions.https.CallableContext;
type CallableHandler<TData> = (
  data: TData,
  context: CallableContext,
) => Promise<unknown>;

type CallableAppCheckOutcome = "valid" | "missing";

interface CallableAppCheckEvaluation {
  allowed: boolean;
  outcome: CallableAppCheckOutcome;
}

const isDevelopment = process.env.FUNCTIONS_EMULATOR === "true";
const isProductionRuntime =
  !isDevelopment &&
  (process.env.NODE_ENV === "production" || Boolean(process.env.K_SERVICE));
const enforceCallableAppCheck = isProductionRuntime;

export const isHttpsError = (
  err: unknown,
): err is functions.https.HttpsError => {
  return err instanceof functions.https.HttpsError;
};

export function evaluateCallableAppCheck(
  context: CallableContext,
  action: string,
  options?: {
    enforce?: boolean;
  },
): CallableAppCheckEvaluation {
  const appCheckToken = context.app;
  const enforce = options?.enforce ?? enforceCallableAppCheck;

  if (appCheckToken) {
    return {
      allowed: true,
      outcome: "valid",
    };
  }

  if (enforce) {
    console.warn("App Check: Rejected request without valid token", {
      action,
      uid: context.auth?.uid,
    });
    return {
      allowed: false,
      outcome: "missing",
    };
  }

  console.info("App Check: Request without token (enforcement disabled)", {
    action,
    uid: context.auth?.uid,
  });
  return {
    allowed: true,
    outcome: "missing",
  };
}

export function verifyCallableAppCheck(
  context: CallableContext,
  action: string,
  options?: {
    enforce?: boolean;
  },
): boolean {
  const result = evaluateCallableAppCheck(context, action, options);
  if (!result.allowed) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "App Check verification failed. Please update your app.",
    );
  }
  return result.outcome === "valid";
}

export function callable<TData>(
  handler: CallableHandler<TData>,
  options?: {
    action?: string;
  },
) {
  const actionName = options?.action ?? (handler.name || "callable");
  return functions.https.onCall(
    async (data: TData, context: CallableContext) => {
      try {
        verifyCallableAppCheck(context, actionName);
        return await handler(data, context);
      } catch (err) {
        if (isHttpsError(err)) {
          throw err;
        }
        console.error("Callable error", {
          name: actionName,
          uid: context.auth?.uid,
          error: err,
        });
        throw new functions.https.HttpsError(
          "internal",
          "Unexpected error. Please try again later.",
        );
      }
    },
  );
}
