# Flutter + Information Architecture Packet -- CRUSH Dating App
**Date:** 2026-02-12
**Version:** 2.0 (Comprehensive Update)

---

## 1. Architecture Diagram (Text Representation)

```
+-----------------------------------------------------------------------+
|                           CRUSH Dating App                             |
+-----------------------------------------------------------------------+
|                                                                        |
|  +---------------------------+   +---------------------------+         |
|  |     PRESENTATION LAYER    |   |      CORE / SHARED        |         |
|  |                           |   |                           |         |
|  |  Screens (40+)            |   |  Router (GoRouter)        |         |
|  |  Widgets (35+)            |   |  DI Container (di.dart)   |         |
|  |  BLoCs (10)               |   |  Design System            |         |
|  |  Cubits (15)              |   |  App Logger               |         |
|  |                           |   |  Secure Logger             |         |
|  +-----------+---------------+   |  Network Layer             |         |
|              |                   |  Analytics Service          |         |
|              | Events/States     |  App Check Service          |         |
|              v                   |  Push Notifications         |         |
|  +---------------------------+   |  Performance Monitor        |         |
|  |       DOMAIN LAYER        |   |  Badge Counter              |         |
|  |                           |   +---------------------------+         |
|  |  Use Cases (77)           |                                         |
|  |  Entity Definitions       |   +---------------------------+         |
|  |  Repository Interfaces    |   |     EXTERNAL SERVICES      |         |
|  |    (11 abstract classes)  |   |                           |         |
|  |                           |   |                           |         |
|  +-----------+---------------+   |  Firebase Auth             |         |
|              |                   |  Cloud Firestore           |         |
|              | Interfaces         |  Firebase Storage          |         |
|              v                   |  Cloud Functions           |         |
|  +---------------------------+   |  Firebase Messaging        |         |
|  |        DATA LAYER         |   |  Firebase Analytics        |         |
|  |                           |   |  Firebase App Check        |         |
|  |  Repositories (3x impl)  |   |  Firebase Remote Config    |         |
|  |    - Firebase             |   |  Firebase Performance      |         |
|  |    - HTTP (REST API)      |   |  Firebase Crashlytics      |         |
|  |    - Stub (Dev/Test)      |   |  Stripe (Payments)         |         |
|  |  Data Models / DTOs       |   |  Agora (Calls)             |         |
|  |  Services (15+)           |   |  Resend (Email)            |         |
|  |  Mappers                  |   +---------------------------+         |
|  +---------------------------+                                         |
|                                                                        |
+-----------------------------------------------------------------------+
|                     FIREBASE BACKEND (Cloud Functions)                  |
|  36 Callable Functions | 29 REST Endpoints | 5 Triggers | 2 Pub/Sub  |
+-----------------------------------------------------------------------+
```

### Layer Dependencies (Target vs Actual)

```
TARGET (Clean Architecture):
  Presentation --> Domain --> Data --> External

ACTUAL (73 violations):
  Presentation --> Domain --> Data --> External
  Presentation ----DIRECT----> Data  (73 files)
```

---

## 2. Route Inventory (56 Routes)

### Auth & Onboarding Routes (13)
| Route | Path | Screen |
|-------|------|--------|
| splash | `/splash` | SplashScreen |
| authGateway | `/auth` | AuthGatewayScreen |
| login | `/auth/login` | LoginScreen |
| signUp | `/auth/signup` | SignUpScreen |
| forgotPassword | `/auth/forgot` | ForgotPasswordScreen |
| otp | `/auth/otp` | OtpScreen |
| resetPassword | `/auth/reset` | ResetPasswordScreen |
| phoneAuth | `/auth/phone` | PhoneAuthScreen |
| emailAuth | `/auth/email` | EmailAuthScreen |
| emailVerification | `/email-verification` | EmailVerificationScreen |
| basicInfo | `/basic-info` | BasicInfoScreen |
| profileSetup | `/profile-setup` | ProfileSetupScreen |
| termsConditions | `/terms-conditions` | TermsConditionsScreen |

### Core App Routes (6)
| Route | Path | Screen |
|-------|------|--------|
| home | `/home` | HomeScreen (TabBar: Discover, Matches, Chat, Profile) |
| chat | `/chat` | ChatScreen |
| messageRequests | `/message-requests` | MessageRequestsScreen |
| call | `/call` | CallScreen |
| videoCall | `/video-call` | VideoCallScreen |
| logout | `/logout` | LogoutScreen |

### Profile Routes (5)
| Route | Path | Screen |
|-------|------|--------|
| profile | `/profile` | ProfileViewScreen |
| profileEdit | `/profile/edit` | ProfileEditScreen |
| profileMedia | `/profile/media` | ProfileMediaScreen |
| storyViewer | `/story-viewer` | StoryViewerScreen |
| userProfile | `/user-profile` | OtherUserProfileScreen |

### Settings Routes (10)
| Route | Path | Screen |
|-------|------|--------|
| settings | `/settings` | SettingsScreen |
| appearanceSettings | `/settings/appearance` | AppearanceSettingsScreen |
| privacySettings | `/settings/privacy` | PrivacySettingsScreen |
| notificationsSettings | `/settings/notifications` | NotificationsSettingsScreen |
| languageSettings | `/settings/language` | LanguageRegionSettingsScreen |
| discoverySettings | `/settings/discovery` | DiscoveryFiltersSettingsScreen |
| storageSettings | `/settings/storage` | DataStorageSettingsScreen |
| securitySettings | `/settings/security` | AccountSecuritySettingsScreen |
| accountSettings | `/settings/account` | AccountActionsSettingsScreen |
| chatSettings | `/settings/chat` | ChatSettingsScreen |

### Discovery & Social Routes (6)
| Route | Path | Screen |
|-------|------|--------|
| likesYou | `/likes-you` | LikesYouScreen |
| weeklyPicks | `/weekly-picks` | WeeklyPicksScreen |
| dateIdeas | `/date-ideas` | DateIdeasScreen |
| compatibilityQuiz | `/compatibility-quiz` | CompatibilityQuizScreen |
| profileInsights | `/profile-insights` | ProfileInsightsScreen |

### Security & Verification Routes (5)
| Route | Path | Screen |
|-------|------|--------|
| emailProtection | `/email-protection` | EmailProtectionScreen |
| phoneProtection | `/phone-protection` | PhoneProtectionScreen |
| changeEmail | `/change-email` | ChangeEmailScreen |
| newDevice | `/new-device` | NewDeviceScreen |
| idVerification | `/id-verification` | IdVerificationScreen |
| idVerificationSettings | `/settings/id-verification` | IdVerificationScreen |

### Safety Routes (2)
| Route | Path | Screen |
|-------|------|--------|
| safety | `/safety` | SafetyScreen |
| safetyGuidelines | `/safety-guidelines` | SafetyGuidelinesScreen |

### Legal & Info Routes (5)
| Route | Path | Screen |
|-------|------|--------|
| privacyPolicy | `/privacy-policy` | PrivacyPolicyScreen |
| termsOfService | `/terms-of-service` | TermsOfServiceScreen |
| support | `/support` | SupportScreen |
| communityGuidelines | `/community-guidelines` | CommunityGuidelinesScreen |
| productFeatures | `/product-features` | ProductFeaturesScreen |
| pricing | `/pricing` | PricingScreen |

### Development Routes (1)
| Route | Path | Screen |
|-------|------|--------|
| widgetCatalog | `/dev/widget-catalog` | WidgetCatalog |

### Critical User Journey Route Chain
```
/splash -> /auth -> /terms-conditions -> /basic-info -> /profile-setup -> /email-verification -> /home
```

---

## 3. BLoC/Cubit Inventory (25 Total: 10 BLoCs + 15 Cubits)

### BLoCs (10)
| BLoC | File | LOC | Feature | Tested |
|------|------|-----|---------|--------|
| AuthBloc | `lib/features/auth/presentation/bloc/auth_bloc.dart` | ~400 | auth | Partial |
| SessionBloc | `lib/features/auth/presentation/bloc/session_bloc.dart` | ~200 | auth | No |
| ProfileBloc | `lib/features/profile/presentation/bloc/profile_bloc.dart` | ~350 | profile | Partial |
| DiscoveryBloc | `lib/features/discovery/presentation/bloc/discovery_bloc.dart` | ~500 | discovery | Partial |
| ChatBloc | `lib/features/chat/presentation/bloc/chat_bloc.dart` | 824 | chat | No |
| MatchesBloc | `lib/features/chat/presentation/bloc/matches_bloc.dart` | ~300 | chat | Partial |
| SubscriptionBloc | `lib/features/subscription/presentation/bloc/subscription_bloc.dart` | ~250 | subscription | Partial |
| CallBloc | `lib/features/calls/presentation/bloc/call_bloc.dart` | ~200 | calls | No |

### Cubits (15)
| Cubit | File | Feature | Tested |
|-------|------|---------|--------|
| ProfileInsightsCubit | `lib/features/analytics/presentation/bloc/profile_insights_cubit.dart` | analytics | No |
| PrivacySettingsCubit | `lib/features/settings/presentation/bloc/privacy_settings_cubit.dart` | settings | Yes (100%) |
| NotificationSettingsCubit | `lib/features/settings/presentation/bloc/notification_settings_cubit.dart` | settings | Yes (100%) |
| LocaleCubit | `lib/features/settings/presentation/bloc/locale_cubit.dart` | settings | Yes |
| SafetyCubit | `lib/features/settings/presentation/bloc/safety_cubit.dart` | settings | Partial |
| StorageSettingsCubit | `lib/features/settings/presentation/bloc/storage_settings_cubit.dart` | settings | Yes |
| ChatSettingsCubit | `lib/features/settings/presentation/bloc/chat_settings_cubit.dart` | settings | Yes (81.82%) |
| ThemeCubit | `lib/features/settings/presentation/bloc/theme_cubit.dart` | settings | Yes (100%) |
| BadgeCounterCubit | `lib/core/services/badge_counter_service.dart` | core | No |
| MatchChatSettingsCubit | `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart` | chat | Yes (79.17%) |
| MessageRequestsCubit | `lib/features/chat/presentation/bloc/message_requests_cubit.dart` | chat | No |
| CompatibilityQuizCubit | `lib/features/social/presentation/bloc/compatibility_quiz_cubit.dart` | social | Partial |
| DateIdeasCubit | `lib/features/social/presentation/bloc/date_ideas_cubit.dart` | social | No |
| FeatureFlagCubit | `lib/features/feature_flags/presentation/bloc/feature_flag_cubit.dart` | feature_flags | No |
| DiscoverySettingsCubit | `lib/features/discovery/presentation/bloc/discovery_settings_cubit.dart` | discovery | Yes (85.78%) |
| WeeklyPicksCubit | `lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart` | discovery | Partial |
| BoostCubit | `lib/features/discovery/presentation/bloc/boost_cubit.dart` | discovery | No |

---

## 4. Feature Module Inventory (13 Features)

| # | Feature | Files | BLoCs/Cubits | Use Cases | Repos | Screens |
|---|---------|-------|--------------|-----------|-------|---------|
| 1 | discovery | 46 | 4 (DiscoveryBloc, DiscoverySettingsCubit, WeeklyPicksCubit, BoostCubit) | 3 | 5 impl | 4 |
| 2 | chat | 33 | 4 (ChatBloc, MatchesBloc, MatchChatSettingsCubit, MessageRequestsCubit) | 3 | 3 impl | 4 |
| 3 | profile | 32 | 1 (ProfileBloc) | 6 | 3 impl | 4 |
| 4 | auth | 31 | 2 (AuthBloc, SessionBloc) | 4 | 3 impl | 13 |
| 5 | social | 21 | 2 (CompatibilityQuizCubit, DateIdeasCubit) | 10 | 0 (services) | 2 |
| 6 | settings | 19 | 7 (Privacy, Notification, Locale, Safety, Storage, Chat, Theme) | 0 | 0 | 10 |
| 7 | subscription | 17 | 1 (SubscriptionBloc) | 4 | 3 impl | 0 (widget) |
| 8 | calls | 16 | 1 (CallBloc) | 3 | 3 impl | 2 |
| 9 | feature_flags | 14 | 1 (FeatureFlagCubit) | 8 | 2 impl | 0 |
| 10 | safety | 13 | 0 | 7 | 0 (service) | 0 |
| 11 | analytics | 11 | 1 (ProfileInsightsCubit) | 6 | 0 (service) | 1 |
| 12 | verification | 11 | 0 | 7 | 0 (service) | 0 |
| 13 | about | 2 | 0 | 0 | 0 | 2 |

---

## 5. Dependency Matrix (50 Direct Flutter Dependencies)

### Core Framework
| Package | Purpose | Category |
|---------|---------|----------|
| flutter | Flutter SDK | Framework |
| flutter_localizations | i18n support | Framework |
| cupertino_icons | iOS-style icons | UI |
| intl | Internationalization utilities | i18n |

### State Management & Navigation
| Package | Purpose | Category |
|---------|---------|----------|
| flutter_bloc | BLoC/Cubit state management | State |
| equatable | Value equality for states/events | State |
| go_router (v17) | Declarative routing with guards | Navigation |
| app_links | Deep linking support | Navigation |

### Firebase Suite (12 packages)
| Package | Purpose | Category |
|---------|---------|----------|
| firebase_core | Firebase initialization | Infrastructure |
| firebase_auth | Authentication (email, phone, Apple, Google) | Auth |
| cloud_firestore | NoSQL database | Data |
| cloud_functions | Callable functions client | Data |
| firebase_storage | File/media storage | Data |
| firebase_messaging | Push notifications | Comms |
| firebase_analytics | Event tracking | Analytics |
| firebase_remote_config | Feature flags | Config |
| firebase_performance | Performance monitoring | Monitoring |
| firebase_crashlytics | Crash reporting | Monitoring |
| firebase_database | Realtime Database | Data |
| firebase_app_check | Device attestation | Security |

### Media & Communication
| Package | Purpose | Category |
|---------|---------|----------|
| image_picker | Photo/video selection | Media |
| video_player | Video playback | Media |
| file_picker | Generic file selection | Media |
| record | Audio recording | Media |
| just_audio | Audio playback | Media |
| audio_waveforms | Audio visualization | Media |
| cached_network_image | Image caching/loading | Media |
| lottie | Lottie animations | UI |
| confetti | Celebration animations | UI |
| web_socket_channel | WebSocket for real-time | Comms |

### Security & Privacy
| Package | Purpose | Category |
|---------|---------|----------|
| flutter_secure_storage (v10) | Encrypted key-value storage | Security |
| crypto | Hashing (SHA-256) | Security |
| cryptography | AES-GCM encryption (E2EE chat) | Security |
| app_tracking_transparency | iOS ATT framework | Privacy |
| sign_in_with_apple | Apple Sign In (App Store compliance) | Auth |

### Platform & Utilities
| Package | Purpose | Category |
|---------|---------|----------|
| uuid | Unique ID generation | Utility |
| path | File path manipulation | Utility |
| http | HTTP client | Network |
| shared_preferences | Local key-value storage | Storage |
| path_provider | File system paths | Storage |
| url_launcher | Open URLs/emails | Utility |
| permission_handler (v12) | Runtime permissions | Platform |
| geolocator | GPS location | Location |
| geocoding | Reverse geocoding | Location |
| google_fonts (v8) | Google Fonts loading | UI |
| package_info_plus | App version info | Utility |
| flutter_local_notifications (v20) | Local notifications | Comms |
| mailer | Email sending | Comms |
| share_plus | Share sheet integration | Utility |
| in_app_review | App Store/Play Store review prompt | Utility |

### Functions Backend Dependencies (10 runtime)
| Package | Purpose | Category |
|---------|---------|----------|
| firebase-functions | Cloud Functions framework | Backend |
| firebase-admin | Admin SDK | Backend |
| express | REST API framework | Backend |
| cors | CORS middleware | Backend |
| stripe | Payment processing | Payments |
| @google-cloud/bigquery | Analytics data warehouse | Analytics |
| agora-access-token | Video/voice call tokens | Comms |
| multer | File upload handling | Backend |
| bcryptjs | Password hashing | Security |

---

## 6. Information Architecture Risks

### High Risk
1. **Router file is large and policy-heavy** -- `lib/core/router.dart` contains all 56 routes, redirect logic, and auth guards in a single file, increasing change risk
2. **Multiple onboarding branches** -- Email verification, phone verification, basic info, profile setup create complex redirect conditions
3. **ChatBloc complexity** -- 824 LOC with no dedicated tests makes it the highest-risk state management unit

### Medium Risk
4. **73 clean architecture violations** -- Presentation layer directly imports data layer in 73 files
5. **Flat vs nested Firestore structure** -- Web creates flat user docs, mobile creates nested. Both work but create rule complexity
6. **Three repository implementations** per interface (Firebase/HTTP/Stub) increases maintenance surface

### Low Risk
7. **Feature-first structure is well-maintained** -- 13 modules with clear boundaries
8. **DI centralized in di.dart** -- Single registration point reduces wiring errors

---

## 7. Required Remediation

### Architecture
- [x] Split router.dart into modular route files by feature domain (CR-AUD-027, P3-ARCH-001)
- [x] Fix 73 presentation-to-data layer violations — 11 domain repository interfaces created, all presentation imports fixed (CR-AUD-027/027b/027c/027d, P1-ARCH-001)
- [ ] Split ChatBloc into sub-BLoCs (target: under 300 LOC each)
- [ ] Extract shared DTOs to common layer
- [ ] Standardize error handling on Result/Either pattern

### Testing
- [ ] Add BLoC unit tests for top 8 BLoCs
- [ ] Add route-level integration tests for every auth/onboarding branch
- [ ] Raise line coverage from 8.79% to 40% (phase 1)
- [ ] Add web unit tests (auth store, API routes, utilities)

### Documentation
- [ ] Produce visual diagram for all route transitions and deep-link entry points
- [ ] Publish API contract catalog for 36 callables + 29 REST endpoints
- [ ] Document BLoC state machines for critical flows

---

## 8. Platform Configuration Status

| Item | Status | Notes |
|------|--------|-------|
| iOS directory | Present | Xcode project configured |
| Android directory | Present | Gradle Kotlin DSL |
| Firebase config files | Present | google-services.json + GoogleService-Info.plist |
| Firestore rules | Deployed | Null-safe for flat/nested structures |
| Storage rules | NOT deployed | Firebase Storage not initialized (P0) |
| iOS Privacy Manifest | Configured | Added to Xcode project build |
| App Tracking Transparency | Present | `app_tracking_transparency` package |
| Sign in with Apple | Present | `sign_in_with_apple` package |
| App Check | Configured | DeviceCheck (iOS) + Play Integrity (Android) |
| CI/CD | Configured | GitHub Actions with Flutter 3.35.0 |
