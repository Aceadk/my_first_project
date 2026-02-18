# TODO: Subscription & Billing Module
**Priority:** P0 – Critical (Store Compliance Blocker)
**Estimated Effort:** 80-120 hours
**Dependencies:** Apple Developer Program (StoreKit 2), Google Play Console (Billing Library v6+), Backend webhook endpoints
**Assigned:** AI + Developer

---

## SUB-001: Integrate in_app_purchase Package into pubspec.yaml
**Files:** `pubspec.yaml`, `lib/core/di.dart`
**Description:** The `in_app_purchase` package (or `purchases_flutter` / RevenueCat) is completely absent from `pubspec.yaml`. No native billing SDK is wired. The checkout flow currently uses a mock Stripe web checkout (`lib/features/subscription/data/services/checkout_service.dart`) that returns fake URLs. Add the official `in_app_purchase` Flutter plugin (or RevenueCat wrapper) as a dependency and configure platform-specific setup files.
**Acceptance Criteria:**
- [ ] `in_app_purchase: ^3.x` (or `purchases_flutter`) added to `pubspec.yaml`
- [ ] iOS: StoreKit 2 configuration added to `ios/Runner/Runner.entitlements` (in-app purchase capability)
- [ ] Android: Google Play Billing library dependency resolved (auto via plugin)
- [ ] `flutter pub get` succeeds with no conflicts
- [ ] Platform initialization code added to `lib/main.dart` or a dedicated service
**Testing:** `flutter pub get` completes; `flutter analyze` clean; app launches on both platforms without crash.

---

## SUB-002: Create Native Billing Service (StoreKit 2 + Google Play Billing)
**Files:** `lib/features/subscription/data/services/native_billing_service.dart` (new), `lib/features/subscription/data/services/checkout_service.dart` (replace)
**Description:** Replace the mock `CheckoutService` (which returns `https://checkout.example.com/...`) with a real `NativeBillingService` that wraps `in_app_purchase` for both platforms. Must handle product queries, purchase flows, transaction verification, and error states.
**Acceptance Criteria:**
- [ ] `NativeBillingService` created with: `initialize()`, `fetchProducts()`, `purchaseProduct(productId)`, `verifyPurchase(receipt)`, `dispose()`
- [ ] iOS uses StoreKit 2 APIs via `in_app_purchase_storekit`
- [ ] Android uses Google Play Billing v6+ via `in_app_purchase_android`
- [ ] Transaction listener handles: purchased, failed, restored, deferred, pending states
- [ ] Proper error mapping: network errors, billing unavailable, user cancelled, item already owned
**Testing:** Unit tests with mocked `InAppPurchase` instance; widget test for purchase flow states; manual sandbox testing on both platforms.

---

## SUB-003: Update SubscriptionRepository to Support Native Purchases
**Files:** `lib/features/subscription/domain/repositories/subscription_repository.dart`, `lib/features/subscription/data/repositories/impl/firebase_subscription_repository.dart`
**Description:** The current `SubscriptionRepository` interface has methods designed for web Stripe checkout. Refactor to support native IAP: add `fetchAvailableProducts()`, `purchaseProduct(productId)`, `verifyReceipt(receiptData)`, `restorePurchases()`. The Firebase implementation must validate receipts server-side via Cloud Functions.
**Acceptance Criteria:**
- [ ] `SubscriptionRepository` interface extended with IAP methods
- [ ] `FirebaseSubscriptionRepository` calls Cloud Function `verifyPurchaseReceipt` for server-side validation
- [ ] `StubSubscriptionRepository` returns mock products for development
- [ ] Platform-aware logic: native IAP on iOS/Android, Stripe on web
**Testing:** Unit tests for each repository implementation; integration test for receipt verification flow.

---

## SUB-004: Implement Server-Side Receipt Validation Cloud Function
**Files:** `functions/src/index.ts` (new callable: `verifyPurchaseReceipt`), `functions/src/subscription/` (new folder)
**Description:** Apple and Google require server-side receipt validation to prevent fraud. Create a Cloud Function that validates purchase receipts against Apple's App Store Server API (v2) and Google Play Developer API.
**Acceptance Criteria:**
- [ ] `verifyPurchaseReceipt` callable function created accepting `{platform, receiptData, productId}`
- [ ] Apple receipt validation via App Store Server API v2 (JWT-based)
- [ ] Google receipt validation via `androidpublisher.purchases.subscriptions.get`
- [ ] Subscription status written to `users/{uid}/subscription` document
- [ ] Server Notifications: webhook endpoints for Apple S2S v2 and Google RTDN
- [ ] Fraud detection: duplicate transaction IDs, mismatched user IDs
**Testing:** Cloud Function unit tests with mocked Apple/Google API responses; integration test with sandbox receipts.

---

## SUB-005: Update SubscriptionBloc for Native Purchase Flow
**Files:** `lib/features/subscription/presentation/bloc/subscription_bloc.dart`, `subscription_event.dart`, `subscription_state.dart`
**Description:** Refactor SubscriptionBloc to handle native IAP flow: product loading, purchase initiation, transaction processing, receipt verification, and state updates.
**Acceptance Criteria:**
- [ ] New events: `SubscriptionProductsRequested`, `SubscriptionPurchaseInitiated(productId)`, `SubscriptionTransactionUpdated(transaction)`
- [ ] New state fields: `availableProducts`, `purchaseInProgress`, `transactionStatus`
- [ ] Transaction listener integrated: handles purchased, failed, restored, pending
- [ ] Analytics events: `checkout_started`, `purchase_completed`, `purchase_failed`, `purchase_restored`
**Testing:** BLoC unit tests for each event handler; state transition verification; error scenario tests.

---

## SUB-006: Build Restore Purchases UI and Flow
**Files:** `lib/features/subscription/presentation/widgets/restore_purchases_button.dart` (new), `lib/features/settings/presentation/screens/settings_screen.dart`
**Description:** Settings screen "Restore" button currently just calls `refreshStatus()`. Must call native `restorePurchases()`, verify each restored transaction server-side, and show proper feedback.
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
**Acceptance Criteria:**
- [ ] New `SubscriptionManagementScreen` with sections: Current Plan, Billing History, Manage
- [ ] "Cancel Subscription" navigates to platform subscription settings
- [ ] "Change Plan" shows available upgrade/downgrade options
- [ ] Route registered at `/settings/subscription`
**Testing:** Widget test for screen layout; navigation test for route; BLoC integration test.

---

## SUB-008: Implement Subscription Paywall Screen
**Files:** `lib/features/subscription/presentation/screens/paywall_screen.dart` (new)
**Description:** Create a premium paywall screen shown when free users attempt gated features. Must comply with Apple App Store guidelines.
**Acceptance Criteria:**
- [ ] Paywall with: feature comparison grid, dynamic pricing from StoreKit/Play, purchase CTA, restore link
- [ ] Prices fetched dynamically (localized currency and amount)
- [ ] Supports multiple products: monthly, annual
- [ ] Apple compliance: no mention of web checkout on iOS builds
- [ ] Terms of Service and Privacy Policy links visible
**Testing:** Widget test for layout and dynamic pricing; screenshot test for store submission.

---

## SUB-009: Handle Subscription Webhooks (Server-to-Server Notifications)
**Files:** `functions/src/subscription/apple_s2s_handler.ts` (new), `functions/src/subscription/google_rtdn_handler.ts` (new)
**Description:** Implement webhook handlers for subscription lifecycle events (renewal, cancellation, billing retry, grace period, refund).
**Acceptance Criteria:**
- [ ] Apple S2S v2 webhook: handles DID_RENEW, DID_FAIL_TO_RENEW, EXPIRED, REFUND, GRACE_PERIOD_EXPIRED
- [ ] Google RTDN webhook: handles SUBSCRIPTION_RENEWED, SUBSCRIPTION_CANCELED, SUBSCRIPTION_ON_HOLD
- [ ] JWT signature verification for Apple notifications
- [ ] Firestore subscription document updated on each event
- [ ] Grace period and refund handling implemented
**Testing:** Cloud Function unit tests with sample webhook payloads; integration test with sandbox.

---

## SUB-010: Add Subscription Entitlement Checks Across App
**Files:** `lib/features/subscription/domain/usecases/check_entitlement.dart` (new), various feature screens
**Description:** Premium features must be gated behind subscription entitlement checks. Add a `CheckEntitlement` use case with feature-specific checks and paywall trigger.
**Acceptance Criteria:**
- [ ] `CheckEntitlement` use case with feature-specific checks
- [ ] Entitlement cache with configurable TTL
- [ ] Free tier limits enforced: daily like limit, no rewinds, blurred likes-you
- [ ] Plus tier unlocked: unlimited likes, rewinds, clear likes-you, passport
- [ ] Paywall shown automatically when free user hits a gated feature
**Testing:** Unit tests for each entitlement check; widget test for paywall trigger.
