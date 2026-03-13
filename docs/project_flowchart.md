# Project Flowchart — CrushHour Dating App

*Last updated: 2026-03-08*

---

## 1) App Initialization Flow

```mermaid
flowchart TD
  A[App Launch] --> B[Splash Screen]
  B --> C{Auth Status}
  C -->|Unknown| B
  C -->|Unauthenticated| D[Auth Gateway]
  D --> D1[Login]
  D --> D2[Sign Up]
  D1 --> D1a[Email/Password]
  D1 --> D1b[Phone + OTP]
  D1 --> D1c[Forgot Password]
  D2 --> D2a[Username + Email + Password]
  D2 --> D2b[Phone + OTP]
  C -->|Authenticated| E{Onboarding Status}
  E -->|Terms not accepted| T[Terms & Conditions]
  E -->|Basic info incomplete| BI[Basic Info - Step 3/6]
  E -->|Profile setup incomplete| PS[Profile Setup - Step 5/6]
  E -->|Email not verified| EV[Email Verification]
  E -->|All complete| H[Home Screen]
  T --> BI
  BI --> ID[ID Verification - Step 4/5]
  ID --> PS
  PS --> EV
  EV --> H
```

---

## 2) Authentication Flow

```mermaid
flowchart TD
  AG[Auth Gateway] --> L[Login]
  AG --> S[Sign Up]

  L --> L1[Email/Username + Password]
  L --> L2[Phone + OTP]
  L --> L3[Forgot Password]

  L1 --> AUTH[Authenticated]
  L2 --> OTP1[OTP Screen]
  OTP1 --> AUTH
  L3 --> FP[Forgot Password Screen]
  FP --> OTP2[OTP Verification]
  OTP2 --> RP[Reset Password]
  RP --> L

  S --> S1[Enter Username]
  S1 --> S2[Enter Email]
  S2 --> S3[Enter Password]
  S3 --> AUTH

  AUTH --> ONBOARD[Onboarding Flow]
```

---

## 3) Onboarding Flow (Sequential)

```mermaid
flowchart TD
  AUTH[Authenticated] --> T[Step 2: Terms & Conditions]
  T -->|Accept| BI[Step 3: Basic Info]
  BI --> ID[Step 4: ID Verification]
  ID -->|Optional| PS[Step 5: Profile Setup]
  PS --> EV{Step 6: Email Verified?}
  EV -->|No| EVS[Step 6: Email Verification Screen]
  EV -->|Yes| H[Home Screen]
  EVS --> H

  subgraph "Basic Info Fields"
    BI1[Username]
    BI2[First Name]
    BI3[Last Name]
    BI4[Name Visibility (private by default)]
    BI5[Date of Birth]
    BI6[Gender]
    BI7[Sexual Orientation]
  end

  subgraph "Profile Setup Fields"
    PS1[Photos]
    PS2[Bio]
    PS3[Location]
    PS4[Work & Education]
    PS5[Interests]
    PS6[Favorites]
  end
```

---

## 4) Home Screen - Bottom Navigation

```mermaid
flowchart TD
  H[Home Screen] --> T1[Tab 1: Discover]
  H --> T2[Tab 2: Matches]
  H --> T3[Tab 3: Chats]
  H --> T4[Tab 4: Profile]

  T1 --> D1[Swipe Deck]
  T1 --> D2[Weekly Picks]
  T1 --> D3[Likes You]

  T2 --> M0[Matches Screen]
  M0 --> M1[Matched With You]
  M0 --> M2[Likes You (Blurred)]
  M1 --> M3[Chat Screen]
  M2 --> M4[Upgrade to Plus]

  T3 --> C1[Conversations List]
  C1 --> MR[Message Requests]
  MR --> MRS[Message Requests Screen]
  C1 --> C2[Chat Screen]
  MRS --> C2
  C2 --> C3[Audio Call]
  C2 --> C4[Video Call]

  T4 --> P1[Profile View]
  P1 --> P2[Profile Edit]
  P1 --> P3[Profile Media]
  P1 --> P4[Settings]
```

---

## 4.1) Chat Transport Adapter Flow

```mermaid
flowchart LR
  UI[Chat UI + BLoCs] --> REPO[ChatRepository]
  REPO --> ADAPTER[ChatTransportAdapter<br/>Domain Interface]
  ADAPTER --> HTTP[HTTP API Transport]
  ADAPTER --> RT[Realtime Transport<br/>WebSocket]
```

---

## 5) Discovery Feature Flow

```mermaid
flowchart LR
  D[Discovery Deck] -->|Swipe Left| PASS[Pass/Dislike]
  D -->|Swipe Right| LIKE[Like]
  D -->|Super Like| SUPER[Super Like ⭐]
  D -->|Tap Story Badge| STORY[Story Viewer]

  LIKE --> M{Mutual Match?}
  SUPER --> M

  M -->|Yes| CELEBRATE[Match Celebration]
  M -->|No| D

  CELEBRATE --> CHAT[Start Chatting]
  CELEBRATE --> CONTINUE[Keep Swiping]

  PASS --> D
  CONTINUE --> D
```

---

## 6) Settings Structure

```mermaid
flowchart TD
  S[Settings Screen] --> S1[Privacy]
  S --> S2[Notifications]
  S --> S3[Discovery Filters]
  S --> S4[Language & Region]
  S --> S5[Data & Storage]
  S --> S6[Account Security]
  S --> S7[Account Actions]
  S --> S8[Safety & Blocking]

  S1 --> S1a[Hide Profile]
  S1 --> S1b[Incognito Mode]

  S2 --> S2a[Push Notifications]
  S2 --> S2b[Email Notifications]
  S2 --> S2c[Sound]
  S2 --> S2d[Vibration]

  S3 --> S3a[Distance Range]
  S3 --> S3b[Age Range]

  S6 --> S6a[Change Password]
  S6 --> S6b[Change Email]

  S7 --> S7a[Deactivate Account]
  S7 --> S7b[Delete Account]
  S7 --> S7c[Logout]

  S8 --> S8a[Blocked Users]
  S8 --> S8b[Report User]
```

---

## 7) Safety & Date Plan Flow

```mermaid
flowchart TD
  SAF[Safety Screen] --> CDP[Create Date Plan]
  CDP --> FORM[Enter match, date/time, location, contact]
  FORM --> SAVE[Create Plan]
  SAVE --> EMAIL[Email emergency contact via Resend]
  EMAIL --> LIST[Date plan listed in Safety]
```

---

## 8) Complete Route Map

### Authentication Routes
| Route | Screen | Description |
|-------|--------|-------------|
| `/auth` | Auth Gateway | Entry point (login/signup options) |
| `/auth/login` | Login Screen | Email/username login |
| `/auth/signup` | Sign Up Screen | Multi-step registration |
| `/auth/otp` | OTP Screen | OTP verification |
| `/auth/forgot` | Forgot Password | Password recovery |
| `/auth/reset` | Reset Password | Set new password |
| `/auth/phone` | Phone Auth | Phone number login |
| `/auth/email` | Email Auth | Email link login |

### Onboarding Routes
| Route | Screen | Progress |
|-------|--------|----------|
| `/terms-conditions` | Terms & Conditions | Step 1 |
| `/basic-info` | Basic Info | Step 2 (60%) |
| `/id-verification` | ID Verification | Step 3 (80%) |
| `/profile-setup` | Profile Setup | Step 4 (100%) |
| `/email-verification` | Email Verification | Final check |

### Main App Routes
| Route | Screen | Description |
|-------|--------|-------------|
| `/home` | Home Screen | Bottom navigation hub |
| `/profile` | Profile View | User's own profile |
| `/profile/edit` | Profile Edit | Edit profile details |
| `/profile/media` | Profile Media | Photo gallery & management |
| `/user-profile` | Other User Profile | View other profiles |
| `/user-profile/:userId` | Other User Profile (deep link) | Deep link to user profile |
| `/chat/:matchId` | Chat Screen | Individual conversation |
| `/message-requests` | Message Requests | Pending message requests |
| `/call` | Call Screen | Audio/video call |
| `/video-call` | Video Call Screen | WebRTC video call |
| `/story-viewer` | Story Viewer | View user stories |

### Discovery Routes
| Route | Screen | Description |
|-------|--------|-------------|
| `/likes-you` | Likes You | Profiles that liked user |
| `/weekly-picks` | Weekly Picks | Curated recommendations |
| `/date-ideas` | Date Ideas | Date suggestions |
| `/compatibility-quiz` | Compatibility Quiz | Match assessment |
| `/profile-insights` | Profile Insights | Analytics & stats |

### Settings Routes
| Route | Screen | Description |
|-------|--------|-------------|
| `/settings` | Settings Hub | Main settings |
| `/settings/appearance` | Appearance | Theme & display |
| `/settings/privacy` | Privacy | Profile visibility |
| `/settings/notifications` | Notifications | Push, email, sound, vibration |
| `/settings/discovery` | Discovery Filters | Distance, age filters |
| `/settings/language` | Language & Region | Localization |
| `/settings/storage` | Data & Storage | Cache management |
| `/settings/security` | Account Security | Password, email |
| `/settings/account` | Account Actions | Delete, deactivate |
| `/settings/chat` | Chat Settings | Chat preferences |
| `/settings/id-verification` | ID Verification | Re-verify identity |

### Other Routes
| Route | Screen | Description |
|-------|--------|-------------|
| `/safety` | Safety | Safety settings & blocking |
| `/logout` | Logout | Logout confirmation |
| `/safety-guidelines` | Community Guidelines | Rules |
| `/community-guidelines` | Community Guidelines | Rules |
| `/privacy-policy` | Privacy Policy | Legal |
| `/terms-of-service` | Terms of Service | Legal |
| `/support` | Support | Help & support |
| `/product-features` | Product Features | Feature showcase |
| `/pricing` | Pricing | Subscription plans |

---

## 8) User State Flags

```mermaid
flowchart TD
  U[CrushUser] --> F1{hasAcceptedTerms?}
  F1 -->|No| T[→ Terms Screen]
  F1 -->|Yes| F2{hasCompletedBasicInfo?}
  F2 -->|No| BI[→ Basic Info Screen]
  F2 -->|Yes| F3{hasCompletedProfileSetup?}
  F3 -->|No| PS[→ Profile Setup Screen]
  F3 -->|Yes| F4{isEmailVerified?}
  F4 -->|No| EV[→ Email Verification]
  F4 -->|Yes| H[→ Home Screen ✓]
```

| Flag | Description | Required For |
|------|-------------|--------------|
| `hasAcceptedTerms` | User accepted T&C | Basic Info access |
| `hasCompletedBasicInfo` | Basic info filled | Profile Setup access |
| `hasCompletedProfileSetup` | Profile complete | Main app access |
| `isEmailVerified` | Email verified | Full access |
| `isAccountVerified` | Phone OR email verified | Full access |

---

## 9) Architecture and Data Flow (Clean Architecture)

```mermaid
flowchart LR
  APP[main.dart] --> DI[CrushDI - di.dart]
  DI --> ROUTER[GoRouter - router.dart]
  ROUTER --> UI[Screens / Widgets]

  subgraph "Presentation Layer"
    UI --> BL[BLoC / Cubit]
  end

  subgraph "Domain Layer"
    BL --> UC[Use Cases]
    UC --> REPO["Repository Interfaces<br/>(abstract classes)"]
  end

  subgraph "Data Layer"
    REPO --> IMPL{Implementation}
    IMPL --> FB[Firebase Repos]
    IMPL --> HTTP[HTTP Repos]
    IMPL --> STUB[Stub / Local Repos]
    IMPL --> SVC["Singleton Services<br/>(Quiz, DateIdea, Insights)"]
  end

  BL --> CORE[Core Services]
  CORE --> CACHE[Cache / Offline Queue]
  CORE --> SEC[Security / Input Sanitizer]
  CORE --> ANALYTICS[Analytics / Feature Flags]
  CORE --> NOTIF[Push Notifications]
```

**Dependency rule:** Presentation → Domain → Data. Presentation never imports from Data directly. All cubits receive abstract repository interfaces via constructor injection. DI (di.dart) wires concrete implementations to abstract interfaces via `RepositoryProvider<AbstractType>`.

---

## 10) Backend Modes (Runtime Switch)

```mermaid
flowchart TD
  MODE[Backend Mode] --> F[Firebase]
  MODE --> H[HTTP]
  MODE --> S[Stub]

  subgraph "Domain Interfaces (lib/features/*/domain/repositories/)"
    AUTH_I[AuthRepository]
    PROF_I[ProfileRepository]
    DISC_I[DiscoveryRepository]
    CHAT_I[ChatRepository]
    SUB_I[SubscriptionRepository]
    CALL_I[CallRepository]
    BOOST_I[BoostRepository]
    FF_I[FeatureFlagRepository]
    QUIZ_I[CompatibilityQuizRepository]
    DATE_I[DateIdeaRepository]
    INS_I[ProfileInsightsRepository]
  end

  F --> AUTHF[FirebaseAuthRepository]
  F --> PROF[FirebaseProfileRepository]
  F --> DISC[FirebaseDiscoveryRepository]
  F --> CHATF[FirebaseChatRepository]

  H --> AUTHH[HttpAuthRepository]
  H --> PROH[HttpProfileRepository]

  S --> AUTHS[StubAuthRepository]
  S --> PROS[StubProfileRepository]
```

All concrete implementations live in `lib/features/*/data/repositories/impl/` or `lib/features/*/data/services/`. Social/analytics features use singleton services that implement domain interfaces.

---

## 11) Feature Modules

```
lib/features/
├── auth/                    → Authentication & Sign-up
│   ├── domain/repositories/   → AuthRepository (abstract)
│   ├── data/repositories/impl/→ FirebaseAuthRepository, StubAuthRepository
│   └── presentation/bloc/     → AuthBloc, SessionBloc
├── discovery/               → Swiping, Likes You, Weekly Picks
│   ├── domain/repositories/   → DiscoveryRepository, BoostRepository (abstract)
│   ├── data/repositories/impl/→ FirebaseDiscoveryRepository
│   └── presentation/bloc/     → DiscoveryBloc, BoostCubit, WeeklyPicksCubit
├── chat/                    → Messaging & Matches
│   ├── domain/repositories/   → ChatRepository (abstract)
│   ├── data/repositories/impl/→ FirebaseChatRepository
│   └── presentation/bloc/     → ChatBloc (facade), sub-BLoCs
├── profile/                 → User Profile Management
│   ├── domain/repositories/   → ProfileRepository (abstract)
│   ├── data/repositories/impl/→ FirebaseProfileRepository
│   └── presentation/bloc/     → ProfileBloc
├── settings/                → App Settings & Preferences
│   └── presentation/bloc/     → ThemeCubit, SafetyCubit, LocaleCubit
├── calls/                   → Video Calling (Agora)
│   ├── domain/repositories/   → CallRepository (abstract)
│   └── presentation/bloc/     → CallBloc
├── social/                  → Date Ideas, Compatibility Quiz
│   ├── domain/repositories/   → DateIdeaRepository, CompatibilityQuizRepository (abstract)
│   ├── data/services/         → DateIdeaService, CompatibilityQuizService (impl)
│   └── presentation/bloc/     → DateIdeasCubit, CompatibilityQuizCubit
├── analytics/               → Profile Insights & Stats
│   ├── domain/repositories/   → ProfileInsightsRepository (abstract)
│   ├── data/services/         → ProfileInsightsService (impl)
│   └── presentation/bloc/     → ProfileInsightsCubit
├── subscription/            → Premium/Plus Management
│   ├── domain/repositories/   → SubscriptionRepository (abstract)
│   └── presentation/bloc/     → SubscriptionBloc
├── safety/                  → Safety & Blocking
├── verification/            → Email/Phone Verification
└── feature_flags/           → Feature Toggle Management
    ├── domain/repositories/   → FeatureFlagRepository (abstract)
    └── presentation/bloc/     → FeatureFlagCubit
```

---

## 12) Summary Statistics

| Metric | Count |
|--------|-------|
| Total Screens | 55+ |
| Feature Modules | 12 |
| Domain Repository Interfaces | 11 |
| Onboarding Steps | 4-5 |
| Bottom Nav Tabs | 4 |
| Settings Sub-screens | 10 |
| Auth Methods | 3 (Email, Phone, Username) |
| Routes | 50+ |
| BLoCs/Cubits | 24+ |
| Unit Tests | 900+ |

---

## Notes

- **Onboarding gating order**: Terms → Basic Info → ID Verification (optional) → Profile Setup → Email Verification (if needed) → Home
- **ID Verification** is part of the onboarding UX but is not a hard gate in router redirects
- **Weekly Picks** route is accessible from all onboarding stages (special exception)
- **Safety** route is accessible from all onboarding stages (special exception)
- The router enforces auth state and onboarding status to prevent accessing protected routes when incomplete
- **Password change** triggers email notification to user for security
- **2026-03-08 Settings Refactor (Preference Sync):** Notification preference writes/hydration are centralized in `NotificationPreferenceSyncService` + `PreferenceSyncEngine` (timestamp-aware local/remote merge), and UI handlers no longer perform direct remote sync writes.
- **2026-02-23 Web update**: Discovery now includes profile stories with upload from Discover, story tray preview, card story badges, and full-screen story viewer with view tracking.
- **2026-03-08 Discovery Refactor**: `StoryUpdate` event contract moved to `domain/repositories/story_repository.dart`, removing domain-layer dependency on discovery data services.
- **2026-03-08 Discovery Refactor (Matching Engine):** Discovery deck distance/passport filtering and top-picks scoring decisions are now centralized in `domain/usecases/matching_decision_engine.dart`; stub/fake repositories delegate to this pure engine for deterministic behavior.
- **2026-03-08 Settings Refactor (Account Commands):** Destructive account actions now flow through `settings/domain/commands/account_action_commands.dart` and `settings/data/commands/default_account_action_commands.dart`, keeping account action orchestration/error mapping out of `AccountActionsSettingsScreen`.
- **2026-03-08 Store Mobile (Checkout Routing):** `SubscriptionBloc` now executes checkout through `SubscriptionRepository.purchasePlusPlan()` so repository implementations own platform-specific billing; Firebase mobile paths (iOS/Android) use native billing service and block Stripe URL checkout on mobile.
- **2026-03-08 Store Google (Server Validation):** Added callable backend validation for Google Play subscription purchase tokens (`verifyGooglePurchaseToken`) with duplicate token/order safeguards and subscription state reconciliation to Firestore/RTDB plan fields.
- **2026-03-08 Store Google (RTDN Lifecycle):** Added `googleRtdnWebhook` push endpoint to process Google Real-time Developer Notifications and reconcile lifecycle statuses (`renewed`, `canceled`, `on_hold`, `in_grace_period`, `revoked`, `expired`) into user subscription metadata + plan sync.
- **2026-03-08 Store Google (Restore + Acknowledgement):** Subscription restore now runs through native billing restore flow; restored Play purchases are acknowledged via `completePurchase`, verified through `verifyGooglePurchaseToken`, and mapped to explicit restore outcomes (`active`/`none`) in subscription state.
- **2026-03-08 Store Apple (Server Validation):** Added callable backend Apple transaction validation (`verifyAppleTransaction`) using App Store Server API lookup (production + sandbox fallback), duplicate transaction-link protection, and plan/lifecycle reconciliation to Firestore/RTDB.
- **2026-03-08 Store Apple (Restore Compliance):** iOS restore flow now validates each restored transaction via `verifyAppleTransaction` (transaction ID from native purchase details), returns explicit no-purchase states, and surfaces restore failures when Apple verification cannot be completed.
- **2026-03-08 Store Apple (S2S Lifecycle):** Added `appleSubscriptionWebhook` endpoint to ingest App Store Server Notifications v2, verify signed payloads, map lifecycle events (`DID_RENEW`, `DID_FAIL_TO_RENEW`, `EXPIRED`, `REFUND`, `GRACE_PERIOD_EXPIRED`), and reconcile user subscription metadata + plan state.
- **2026-03-12 Subscription entitlement gating:** Premium feature decisions now flow through `subscription/domain/usecases/check_entitlement.dart`; discovery like limits, rewind/paywall routing, passport upsells, and paid-tier unlock checks are centralized instead of being split across feature-local `plus` checks.
- **2026-03-12 Store receipt validation callable:** Mobile purchase verification now has a unified `verifyPurchaseReceipt` callable that routes `platform` + `receiptData` requests to the existing Google Play / App Store validation paths while preserving the older provider-specific callable entrypoints for compatibility.
- **2026-03-12 Store repository IAP contract:** `SubscriptionRepository` now exposes `purchaseProduct`, `restorePurchases`, `verifyPurchaseReceipt`, and `fetchAvailableProducts`; Firebase mobile purchases/restores verify through the unified callable while stub/http/web paths keep product catalogs and Stripe checkout fallbacks aligned.
- **2026-03-12 Store bootstrap setup:** App startup now schedules `CrushDI.initializePlatformServices()` after first frame so Firebase/hybrid mobile builds prime a shared native billing service instance, and the Runner Xcode target records the In-App Purchase capability locally.
- **2026-03-13 Discovery eligibility centralization:** App and web discovery deck loading now converge on the backend `fetchDiscoveryCandidates` / `/v1/discovery/deck` pipeline. Eligibility is evaluated from a shared canonical snapshot that accepts both nested mobile `profile.*` documents and legacy flat web user documents, and requester debug status is returned for traceable discovery exclusions.
