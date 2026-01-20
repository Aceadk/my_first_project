# Project Understanding — CRUSH Dating App

*Last updated: 2026-01-20*

---

## 1. Project Summary

**Project Name:** CRUSH
**Platform:** Flutter (iOS & Android)
**Architecture:** Feature-first Clean Architecture + BLoC/Cubit

**High-level goal:**
Provide a modern, safe, fast, and trustworthy dating experience with clean UX and scalable architecture.

---

## 2. Target Users

* Age range: Adults (18+)
* Location focus: GPS-based local discovery
* Dating intent: Mixed (supports casual and serious via preferences)
* Technical literacy: General consumer app users

User priorities (assumed):

* Fast onboarding
* Trust & safety (verification, blocking, reporting)
* High quality matches
* Smooth performance (swipe animations, real-time chat)
* Clean UI (glass-morphism design system)

---

## 3. Developer Intent (Observed)

Based on repository structure and patterns:

* Focus on:

  * ☑ MVP speed - Multi-backend support (stub for rapid dev)
  * ☑ Production stability - Firebase + HTTP backends ready
  * ☑ Monetization readiness - Full subscription system implemented
  * ☑ Long-term scalability - Feature-modular architecture
  * ☑ Code quality - Clean architecture with proper separation

Notes:

* State management approach: BLoC for complex flows, Cubit for simple UI state
* Routing strategy: GoRouter with redirect-based auth guards
* Backend integration style: Strategy pattern (Firebase/HTTP/Stub switchable)
* Testing maturity: Test files present (auth_bloc_test.dart, deck_gating_test.dart)

---

## 4. Architecture Overview

### Folder Structure

```
lib/
├── app.dart                    # Main app widget with provider setup
├── main.dart                   # Entry point with Firebase init
├── core/                       # Shared business logic & services
│   ├── di.dart                 # Manual dependency injection
│   ├── router.dart             # GoRouter configuration
│   ├── services/               # 12 core singleton services
│   ├── network/                # HTTP client, cert pinning
│   ├── cache/                  # Offline queue, caching layer
│   ├── security/               # Session manager, input sanitizer
│   └── feature_flags/          # Firebase Remote Config
├── features/                   # 10 feature modules
│   ├── auth/
│   ├── profile/
│   ├── discovery/
│   ├── chat/
│   ├── calls/
│   ├── subscription/
│   ├── settings/
│   ├── social/
│   ├── feature_flags/
│   └── analytics/
├── data/                       # Shared models & fake repos
│   ├── models/                 # User, Profile, Match, Message
│   ├── dto/                    # Data transfer objects
│   └── repositories/           # Fake implementations for testing
├── design_system/              # Glass-morphism UI components
│   ├── tokens/                 # Colors, typography, spacing
│   ├── widgets/                # 30+ custom components
│   └── animations/             # Page transitions, celebrations
├── presentation/               # Top-level screens (splash, home)
├── shared/                     # Cross-cutting utilities
└── l10n/                       # Localization
```

### Layers

* **Presentation:**
  * Screens/pages per feature
  * 30+ design system widgets (GlassButton, GlassCard, etc.)
  * 8 BLoCs + 13 Cubits

* **Domain:**
  * Entities in `/lib/data/models/`
  * Use cases in `/lib/features/*/domain/usecases/`
  * Repository interfaces in `/lib/features/*/data/repositories/`

* **Data:**
  * 3 implementations per repo: Firebase, HTTP, Stub
  * DTOs in `/lib/data/dto/` and `/lib/core/network/dto/`
  * Mappers in `/lib/core/network/mappers/`

* **Core:**
  * 12 services (analytics, push, crash reporting, location, etc.)
  * Network client with retry logic & cert pinning
  * Cache layer with offline queue support
  * Security (session manager, input sanitizer)

---

## 5. State Management

* **Library used:** flutter_bloc ^9.1.1
* **DI mechanism:** Manual DI in `/lib/core/di.dart` (CrushDI class)

### BLoCs (8 total - complex event-driven flows):

| BLoC | Feature | Purpose |
|------|---------|---------|
| AuthBloc | Auth | Multi-method auth (phone OTP, email, password) |
| SessionBloc | Auth | Session lifecycle management |
| ProfileBloc | Profile | CRUD, media upload, validation |
| DiscoveryBloc | Discovery | Swipe deck, likes, matches, super likes |
| ChatBloc | Chat | Messages, reactions, typing, presence |
| MatchesBloc | Chat | Match list management |
| CallBloc | Calls | Voice/video call sessions (Agora) |
| SubscriptionBloc | Subscription | Plans, checkout, status |

### Cubits (13 total - simple UI state):

| Cubit | Feature | Purpose |
|-------|---------|---------|
| ThemeCubit | Settings | Light/dark/system theme |
| LocaleCubit | Settings | Language selection |
| NotificationSettingsCubit | Settings | Push preferences |
| PrivacySettingsCubit | Settings | Privacy toggles |
| SafetyCubit | Settings | Safety & reporting |
| StorageSettingsCubit | Settings | Data management |
| DiscoverySettingsCubit | Discovery | Filters (distance, age, gender) |
| BoostCubit | Discovery | Profile boost feature |
| WeeklyPicksCubit | Discovery | Weekly picks |
| FeatureFlagCubit | Feature Flags | Remote config |
| ProfileInsightsCubit | Analytics | Profile analytics |
| DateIdeasCubit | Social | Dating suggestions |
| CompatibilityQuizCubit | Social | Quiz scoring |
| BadgeCounterCubit | Core | Unread counts |

### Known risks:

* AuthBloc handles multiple auth methods - potential complexity
* DiscoveryBloc manages deck + matches - monitor for growth
* State transitions need careful testing for auth flows

---

## 6. Routing System

* **Router used:** go_router ^14.6.0
* **Auth guarding:** Redirect-based via `GoRoute.redirect()` checking AuthBloc state
* **Deep linking:** Firebase dynamic links (`/lib/core/routing/deep_links.dart`)
* **Navigation pattern:** Declarative with custom fade+slide transitions

### Key Routes (34 total):

```dart
static const root = '/';
static const splash = '/splash';
static const authGateway = '/auth';        // Auth parent
static const home = '/home';
static const discovery = '/discover';      // Swipe deck
static const chat = '/chat/:matchId';      // Dynamic route
static const profile = '/profile';
static const settings = '/settings';       // 7 sub-routes
static const calls = '/calls';
```

### Route Guards:

* `RouteGuard` abstract base class
* Implementations: `FeatureFlagGuard`, `PremiumGuard`, `KillSwitchGuard`, `CompositeGuard`
* Auth checks: AuthStatus (unknown/authenticated/unauthenticated)
* Onboarding gates: terms → basic info → profile setup
* Verification gates: email/phone verification

### Critical flows:

* Onboarding → Auth → Home → Discovery → Match → Chat → Profile

---

## 7. Backend & Services

### Multi-Backend Architecture:

```dart
enum BackendMode { stub, firebase, http }
static const BackendMode backendMode = BackendMode.firebase;  // Current
```

### Repositories (8 total):

| Repository | Implementations |
|------------|-----------------|
| AuthRepository | Firebase, HTTP, Stub |
| ProfileRepository | Firebase, HTTP, Stub |
| DiscoveryRepository | Firebase, HTTP, Stub |
| ChatRepository | Firebase, HTTP, Stub |
| CallRepository | Firebase, HTTP, Stub |
| SubscriptionRepository | Firebase, HTTP, Stub |
| FeatureFlagRepository | Firebase, Stub |
| BoostRepository | Stub only (TBD) |

### Core Services (12):

| Service | Purpose |
|---------|---------|
| AnalyticsService | Firebase Analytics, custom events |
| PushNotificationService | FCM, local notifications |
| CrashReportingService | Firebase Crashlytics |
| AppUpdateService | Version checking, forced updates |
| GradualRolloutService | Phased rollout control |
| LocationService | GPS for distance-based discovery |
| OfflineCacheService | Offline queue, sync on reconnect |
| EmailService | Email sending (mailer) |
| DataExportService | GDPR data export |
| HapticService | Vibration feedback |
| BadgeCounterService | Unread counts |
| InAppReviewService | Review prompts |

### Firebase Services:

* firebase_auth ^6.1.3 - Authentication
* cloud_firestore ^6.1.1 - Real-time database
* firebase_storage ^13.0.2 - Media storage
* firebase_messaging ^16.1.0 - Push notifications
* firebase_analytics ^12.1.0 - Analytics
* firebase_remote_config ^6.1.3 - Feature flags
* firebase_crashlytics ^5.0.3 - Crash reporting

### Storage:

* shared_preferences ^2.3.2 - User preferences
* flutter_secure_storage ^9.2.2 - Secure token storage
* cached_network_image ^3.3.1 - Image caching

### Notifications:

* Firebase Cloud Messaging (FCM)
* Local notifications for in-app events

### Media hosting:

* Firebase Storage for photos/videos
* Image picker ^1.1.2 for selection
* Video player ^2.8.7 for playback

---

## 8. UX Philosophy

### Design System:

* **Style:** Glass-morphism (frosted glass effects)
* **Location:** `/lib/design_system/`
* **Tokens:** Colors, Typography, Spacing, Radius, Blur, Gradients

### 30+ Custom Components:

* Glass widgets: GlassButton, GlassCard, GlassAppBar, GlassTextField, GlassChip
* Core UI: PrimaryButton, OtpInput, CrushAvatar, ErrorBanner, EmptyState
* Chat: VoiceNoteRecorder, VoiceNotePlayer, TypingIndicator, ReadReceipt
* Animations: MatchCelebration, SuperLikeAnimation, ConfettiCelebration
* Loaders: SkeletonLoader, LoadingOverlay, GlassRefreshIndicator

### Design goals:

* Minimal friction - Progressive onboarding
* Emotional safety - Verification badges, blocking, reporting
* Visual clarity - Clean glass-morphism aesthetic
* Micro-interactions - Haptic feedback, subtle animations
* Performance first - Skeleton states, lazy loading

### Reference competitors:

* Tinder - Swipe mechanics
* Bumble - Safety features
* Hinge - Prompts/icebreakers
* OkCupid - Compatibility matching

---

## 9. Known Technical Debt

* BoostRepository only has Stub implementation (Firebase TBD)
* Route guards defined but not fully integrated in main router
* Some feature flags may need cleanup
* HTTP backend may need more testing vs Firebase

---

## 10. Open Questions

* What is the production backend mode (Firebase vs HTTP API)?
* Are voice/video calls (Agora) fully implemented?
* What is the subscription pricing/tier structure?
* Is there a web version planned?

---

## 11. Security Architecture

### Authentication:

* Firebase Auth with phone OTP + email verification
* Session tokens with JWT
* Secure token storage (flutter_secure_storage)
* 30-minute inactivity timeout (SessionManager)

### Data Protection:

* SSL/TLS with certificate pinning
* Input sanitization (SQL injection, XSS prevention)
* Secure logging (PII redaction)
* GDPR data export functionality

### Privacy Features:

* Incognito mode (Passport feature)
* Block/report system
* Location consent
* Email/phone verification required

---

## 12. Key Dependencies Summary

| Category | Package | Version |
|----------|---------|---------|
| State | flutter_bloc | ^9.1.1 |
| Routing | go_router | ^14.6.0 |
| Firebase | firebase_core | ^4.3.0 |
| Network | http | ^1.2.2 |
| Storage | shared_preferences | ^2.3.2 |
| Secure Storage | flutter_secure_storage | ^9.2.2 |
| Location | geolocator | ^14.0.2 |
| Images | cached_network_image | ^3.3.1 |
| Audio | just_audio | ^0.9.42 |
| Animations | lottie | ^3.1.3 |
| Permissions | permission_handler | ^11.3.0 |
