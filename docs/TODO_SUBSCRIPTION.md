# TODO: Subscription & Billing Module
**Priority:** P0 – Critical (Store Compliance Blocker)
**Estimated Effort:** 80-120 hours
**Dependencies:** Apple Developer Program (StoreKit 2), Google Play Console (Billing Library v6+), Backend webhook endpoints
**Assigned:** AI + Developer

---

## SUB-001: Integrate in_app_purchase Package into pubspec.yaml
**Files:** `pubspec.yaml`, `lib/core/di.dart`
**Description:** The `in_app_purchase` package (or `purchases_flutter` / RevenueCat) is completely absent from `pubspec.yaml`. No native billing SDK is wired. The checkout flow currently uses a mock Stripe web checkout (`lib/features/subscription/data/services/checkout_service.dart`) that returns fake URLs. Add the official `in_app_purchase` Flutter plugin (or RevenueCat wrapper) as a dependency and configure platform-specific setup files.
**Status:** Completed (2026-03-12)
**Acceptance Criteria:**
- [x] `in_app_purchase: ^3.x` (or `purchases_flutter`) added to `pubspec.yaml`
- [x] iOS: Runner target records the In-App Purchase capability in `ios/Runner.xcodeproj/project.pbxproj` (Apple does not add a dedicated entitlements key for this capability)
- [x] Android: Google Play Billing library dependency resolved (auto via plugin)
- [x] `flutter pub get` succeeds with no conflicts
- [x] Platform initialization code added via `CrushDI.initializePlatformServices()` and the startup task in `lib/main.dart`
**Testing:** `flutter pub get` completes; targeted `flutter analyze` / `flutter test test/core/di_test.dart` pass; `xcodebuild -list -project ios/Runner.xcodeproj` validates the Xcode project after capability wiring.

---

## SUB-002: Create Native Billing Service (StoreKit 2 + Google Play Billing)
**Files:** `lib/features/subscription/data/services/native_billing_service.dart` (new), `lib/features/subscription/data/services/checkout_service.dart` (replace)
**Description:** Replace the mock `CheckoutService` (which returns `https://checkout.example.com/...`) with a real `NativeBillingService` that wraps `in_app_purchase` for both platforms. Must handle product queries, purchase flows, transaction verification, and error states.
**Status:** Completed (2026-03-12)
**Acceptance Criteria:**
- [x] `NativeBillingService` created with: `initialize()`, `fetchProducts()`, `purchaseProduct(productId)`, `verifyPurchase(receipt)`, `dispose()`
- [x] iOS uses StoreKit 2 APIs via `in_app_purchase_storekit`
- [x] Android uses Google Play Billing v6+ via `in_app_purchase_android`
- [x] Transaction listener handles: purchased, failed, restored, and pending states (Flutter IAP does not surface a separate deferred enum)
- [x] Proper error mapping: network errors, billing unavailable, user cancelled, item already owned
**Testing:** Unit tests with a fake `NativeBillingClient` / StoreKit delegate configurer; repository path tests; manual sandbox testing on both platforms remains available for live-store verification.

---

## SUB-003: Update SubscriptionRepository to Support Native Purchases
**Files:** `lib/features/subscription/domain/repositories/subscription_repository.dart`, `lib/features/subscription/data/repositories/impl/firebase_subscription_repository.dart`
**Description:** The current `SubscriptionRepository` interface has methods designed for web Stripe checkout. Refactor to support native IAP: add `fetchAvailableProducts()`, `purchaseProduct(productId)`, `verifyReceipt(receiptData)`, `restorePurchases()`. The Firebase implementation must validate receipts server-side via Cloud Functions.
**Status:** Completed (2026-03-12)
**Acceptance Criteria:**
- [x] `SubscriptionRepository` interface extended with IAP methods
- [x] `FirebaseSubscriptionRepository` calls Cloud Function `verifyPurchaseReceipt` for server-side validation
- [x] `StubSubscriptionRepository` returns mock products for development
- [x] Platform-aware logic: native IAP on iOS/Android, Stripe on web
**Testing:** Unit tests for each repository implementation and focused repository receipt-flow coverage are in place; live sandbox store validation remains available through the later restore / end-to-end store passes.

---

## SUB-004: Implement Server-Side Receipt Validation Cloud Function
**Files:** `functions/src/index.ts` (new callable: `verifyPurchaseReceipt`), `functions/src/subscription/` (new folder)
**Description:** Apple and Google require server-side receipt validation to prevent fraud. Create a Cloud Function that validates purchase receipts against Apple's App Store Server API (v2) and Google Play Developer API.
**Status:** Completed (2026-03-12)
**Acceptance Criteria:**
- [x] `verifyPurchaseReceipt` callable function created accepting `{platform, receiptData, productId}`
- [x] Apple receipt validation via App Store Server API v2 (JWT-based)
- [x] Google receipt validation via `androidpublisher.purchases.subscriptions.get`
- [x] Subscription status written to the existing `users/{uid}` subscription metadata fields (`plan`, `applePurchase`, `googlePlayPurchase`, `subscriptionLifecycle`)
- [x] Server Notifications: webhook endpoints for Apple S2S v2 and Google RTDN
- [x] Fraud detection: duplicate transaction IDs, mismatched user IDs
**Testing:** Cloud Function unit tests with mocked Apple/Google API responses; sandbox receipt integration remains available for live-store verification.

---

## SUB-005: Update SubscriptionBloc for Native Purchase Flow
**Files:** `lib/features/subscription/presentation/bloc/subscription_bloc.dart`, `subscription_event.dart`, `subscription_state.dart`
**Description:** Refactor SubscriptionBloc to handle native IAP flow: product loading, purchase initiation, transaction processing, receipt verification, and state updates.
**Status:** Completed (2026-03-12)
**Acceptance Criteria:**
- [x] New events: `SubscriptionProductsRequested`, `SubscriptionPurchaseInitiated(productId)`, `SubscriptionTransactionUpdated(transaction)`
- [x] New state fields: `availableProducts`, `purchaseInProgress`, `transactionStatus`
- [x] Transaction listener integrated: handles purchased, failed, restored, pending
- [x] Analytics events: `checkout_started`, `purchase_completed`, `purchase_failed`, `purchase_restored`
**Testing:** BLoC unit tests for each event handler; state transition verification; error scenario tests.

---

## SUB-006: Build Restore Purchases UI and Flow
**Files:** `lib/features/subscription/presentation/widgets/restore_purchases_button.dart` (new), `lib/features/settings/presentation/screens/settings_screen.dart`
**Description:** Settings screen "Restore" button currently just calls `refreshStatus()`. Must call native `restorePurchases()`, verify each restored transaction server-side, and show proper feedback.
**Status:** In Progress (2026-03-12; restore UI/test coverage landed, sandbox verification still pending)
**Acceptance Criteria:**
- [ ] Restore flow calls native `restorePurchases()` on the IAP plugin
- [ ] Each restored transaction verified server-side
- [ ] UI shows: loading, success with plan details, "No purchases found", or error
- [ ] Apple App Review requirement: restore button accessible without login wall
- [ ] Handles expired subscriptions gracefully
**Testing:** Widget test for restore button states; BLoC test for restore event handling; manual test on sandbox.

---

## SUB-007: Build Subscription Management Screen
**Files:** `lib/features/subscription/presentation/screens/subscription_management_screen.dart` (new), `lib/core/routing/settings_routes.dart`
**Description:** No dedicated subscription management screen exists. Create one showing: current plan details, next renewal date, cancel/resubscribe options, and platform subscription management links.
**Status:** Completed (2026-03-12)
**Acceptance Criteria:**
- [x] New `SubscriptionManagementScreen` with sections: Current Plan, Billing History, Manage
- [x] "Cancel Subscription" navigates to platform subscription settings
- [x] "Change Plan" shows available upgrade/downgrade options
- [x] Route registered at `/settings/subscription`
**Testing:** Widget test for screen layout; navigation test for route; BLoC integration test.

---

## SUB-008: Implement Subscription Paywall Screen
**Files:** `lib/features/subscription/presentation/screens/paywall_screen.dart` (new)
**Description:** Create a premium paywall screen shown when free users attempt gated features. Must comply with Apple App Store guidelines.
**Status:** Completed (2026-03-12)
**Acceptance Criteria:**
- [x] Paywall with: feature comparison grid, dynamic pricing from StoreKit/Play, purchase CTA, restore link
- [x] Prices fetched dynamically (localized currency and amount)
- [x] Supports multiple products: monthly, annual
- [x] Apple compliance: no mention of web checkout on iOS builds
- [x] Terms of Service and Privacy Policy links visible
**Testing:** Widget test for layout and dynamic pricing; golden screenshot test for store submission.

---

## SUB-009: Handle Subscription Webhooks (Server-to-Server Notifications)
**Files:** `functions/src/index.ts`, `functions/test/googleRtdnLifecycle.test.js`, `functions/test/appleS2sLifecycle.test.js`
**Description:** Implement webhook handlers for subscription lifecycle events (renewal, cancellation, billing retry, grace period, refund).
**Status:** Completed (2026-03-08)
**Acceptance Criteria:**
- [x] Apple S2S v2 webhook: handles DID_RENEW, DID_FAIL_TO_RENEW, EXPIRED, REFUND, GRACE_PERIOD_EXPIRED
- [x] Google RTDN webhook: handles SUBSCRIPTION_RENEWED, SUBSCRIPTION_CANCELED, SUBSCRIPTION_ON_HOLD
- [x] JWT signature verification for Apple notifications
- [x] Firestore user subscription metadata updated on each event (`users/{uid}` with `subscriptionLifecycle`)
- [x] Grace period and refund handling implemented
**Testing:** Cloud Function unit tests with sample webhook payloads; integration test with sandbox.

---

## SUB-010: Add Subscription Entitlement Checks Across App
**Files:** `lib/features/subscription/domain/usecases/check_entitlement.dart` (new), various feature screens
**Description:** Premium features must be gated behind subscription entitlement checks. Add a `CheckEntitlement` use case with feature-specific checks and paywall trigger.
**Status:** Completed (2026-03-12)
**Acceptance Criteria:**
- [x] `CheckEntitlement` use case with feature-specific checks
- [x] Entitlement cache with configurable TTL
- [x] Free tier limits enforced: daily like limit, no rewinds, blurred likes-you
- [x] Plus tier unlocked: unlimited likes, rewinds, clear likes-you, passport
- [x] Paywall shown automatically when free user hits a gated feature
**Testing:** Unit tests for each entitlement check; widget test for paywall trigger.
