# CRUSH Web Platform - Implementation TODO

**Last Updated:** 2026-01-27
**Status:** In Development - 60% Complete
**Live URL:** https://crush-web-chi.vercel.app
**Repo:** /Users/ace/Desktop/crush-web

---

## Quick Links

- [AUDIT_WEBAPP.md](./AUDIT_WEBAPP.md) - Full audit and architecture
- [ai_change_log.md](./ai_change_log.md) - Change history
- [ai_tasks_board.md](./ai_tasks_board.md) - Task tracking
- [project_flowchart.md](./project_flowchart.md) - App flow diagrams

---

## Implementation Status Overview

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 0: Foundation | **COMPLETE** | 100% |
| Phase 1: Authentication | **MOSTLY COMPLETE** | 95% |
| Phase 2: Onboarding | **COMPLETE** | 100% |
| Phase 3: Discovery | **MOSTLY COMPLETE** | 90% |
| Phase 4: Messaging | **MOSTLY COMPLETE** | 95% |
| Phase 5: Profile & Settings | **MOSTLY COMPLETE** | 90% |
| Phase 6: Safety & Social | **MOSTLY COMPLETE** | 95% |
| Phase 7: Subscription | **MOSTLY COMPLETE** | 80% |
| Phase 8: Marketing Website | **MOSTLY COMPLETE** | 70% |
| Phase 9: Polish & Testing | **NOT STARTED** | 0% |

**Overall Progress: ~90%**

---

## Phase 0: Foundation - COMPLETE

### Monorepo Setup
- [x] Initialize Turborepo with `pnpm create turbo@latest`
- [x] Configure workspace structure (apps/web, packages/core, packages/ui)
- [x] Set up shared TypeScript config
- [x] Set up shared ESLint config
- [x] Set up shared Tailwind config
- [x] Configure Turborepo pipeline (build, dev, test, lint)

### Next.js App Setup
- [x] Create Next.js 14 app with App Router
- [x] Configure `next.config.js`
  - [x] Image domains (Firebase Storage)
  - [x] Webpack optimizations
  - [x] Environment variables
- [x] Set up middleware for auth (`src/middleware.ts`)
- [x] Configure layout structure (route groups)

### Design System Package (@crush/ui)
- [x] Create package structure
- [x] Configure Tailwind CSS
- [x] Define design tokens (colors, spacing, typography)
- [x] Create base components
  - [x] Button (Primary, Secondary, Ghost, Glass)
  - [x] Input (Text, Textarea)
  - [x] Card (Standard)
  - [x] Avatar (with fallback)
  - [x] Badge
  - [x] Skeleton loader
  - [x] Dialog/Modal
  - [x] Toast notifications
  - [x] Dropdown menu

### Firebase Integration (@crush/core)
- [x] Install Firebase SDK
- [x] Create Firebase config (`packages/core/src/firebase/config.ts`)
- [x] Set up AuthProvider
- [x] Configure Firestore
- [x] Configure Storage
- [x] Test connection

### State Management (@crush/core)
- [x] Set up Zustand
- [x] Create store structure
  - [x] Auth store (`packages/core/src/stores/auth.ts`)
  - [x] Match store (`packages/core/src/stores/match.ts`)
  - [x] Message store (`packages/core/src/stores/message.ts`)
  - [x] UI store (`packages/core/src/stores/ui.ts`)
- [x] Set up React Query (optional)

### Services (@crush/core)
- [x] Auth service (`packages/core/src/services/auth.ts`)
- [x] User service (`packages/core/src/services/user.ts`)
- [x] Match service (`packages/core/src/services/match.ts`)
- [x] Message service (`packages/core/src/services/message.ts`)
- [x] Storage service (`packages/core/src/services/storage.ts`)
- [x] Location service (`packages/core/src/services/location.ts`)

### Deployment
- [x] Configure Vercel project
- [x] Set up environment variables (12 Firebase env vars)
- [x] Configure deployment settings
- [x] Test initial deployment - LIVE at crush-web-chi.vercel.app

### CI/CD
- [ ] Create GitHub Actions workflow
- [ ] Configure test job
- [ ] Configure lint job
- [x] Vercel handles auto-deploy on push
- [x] Set up branch protection

---

## Phase 1: Authentication - 95% COMPLETE

### Auth Gateway
- [x] Create `/auth` routes
- [x] Auth layout with branded sidebar
- [x] Mobile responsive layout

### Email/Password Flow
- [x] Create `/auth/login` page
- [x] Create `/auth/signup` page
- [x] Email input with validation
- [x] Password input with show/hide toggle
- [x] Sign in/up actions
- [x] Loading states
- [x] Error handling
- [x] Password strength indicator [Status: DONE]
- [ ] Remember me checkbox

### Phone OTP Flow
- [x] Create `/auth/phone` page
- [x] Phone number input
- [x] reCAPTCHA integration
- [x] OTP verification
- [x] Country code selector component [Status: DONE]
- [x] Resend OTP functionality [Status: DONE]

### Password Reset
- [x] Create `/auth/forgot-password` page
- [x] Email input
- [x] Send reset link action
- [x] Success message

### Session Management
- [x] Create auth middleware
- [x] Token storage (HTTP-only cookies)
- [x] Auth state persistence with Zustand
- [ ] Session refresh logic (auto-refresh)
- [ ] Inactivity timeout
- [ ] Activity tracking

### Route Protection
- [x] Create protected route middleware
- [x] Redirect unauthenticated users
- [x] Handle loading states via AuthInitializer
- [ ] Preserve intended destination

### Logout
- [x] Create logout action
- [x] Clear session
- [x] Clear local state
- [x] Clear auth cookie
- [x] Redirect to auth

### Missing Auth Features (vs Mobile)
- [ ] Email OTP verification
- [ ] Email link sign-in
- [ ] Google sign-in (partial)
- [ ] New device verification
- [ ] Email protection screen
- [ ] Phone protection screen

---

## Phase 2: Onboarding - 100% COMPLETE

### Onboarding Flow
- [x] Progress bar with step indicators
- [x] Step navigation (back/next)
- [x] Animated transitions

### Welcome Step
- [x] Welcome message
- [x] App features preview
- [x] Continue button

### Basics Step
- [x] Display name input
- [x] Date of birth picker with 18+ validation
- [x] Gender selection (Male, Female, Other)
- [x] Form validation
- [ ] Username availability check
- [ ] Last name (optional)

### Photos Step
- [x] Photo upload section
- [x] Photo preview grid
- [x] Main photo indicator
- [x] Delete photo
- [x] Upload progress
- [x] Max 6 photos
- [ ] Drag & drop
- [ ] Crop/adjust modal
- [ ] Reorder functionality

### Interests Step
- [x] Available interests grid (24 interests)
- [x] Selected interests chips
- [x] Min 3, max 10 validation

### Location Step
- [x] Auto-detect location
- [x] Manual city/country input
- [x] Permission handling
- [x] Error handling
- [x] Privacy note

### Completion
- [x] Set `onboardingComplete: true`
- [x] Set `profileComplete: true`
- [x] Redirect to `/discover`

### Missing Features (vs Mobile)
- [ ] Terms & Conditions step
- [ ] ID Verification step
- [x] Sexual orientation [Status: DONE]
- [ ] Email verification step
- [x] Profile prompts [Status: DONE]

---

## Phase 3: Discovery - 85% COMPLETE

### Swipe Deck Interface
- [x] Create `/discover` page
- [x] Card stack component
- [x] Swipeable card with animations
- [x] Profile card design
  - [x] Photo display
  - [x] Name, age
  - [x] Bio preview
  - [x] Interests tags
  - [x] Verified badge
- [x] Loading skeleton
- [x] Empty state

### Action Buttons
- [x] Pass button (X)
- [x] Like button (Heart)
- [x] Super Like button (Plus only)
- [x] Rewind button (Plus only)
- [x] Button animations
- [x] Keyboard shortcuts [Status: DONE]

### Match Celebration
- [x] Match modal component
- [x] Both user photos
- [x] "Send message" CTA
- [x] "Keep swiping" option
- [x] Super Like indicator
- [ ] Confetti animation

### Discovery Filters
- [x] Filters dialog
- [x] Age range slider
- [x] Distance slider
- [x] Gender preferences
- [x] Apply/Reset buttons
- [ ] Save to profile
- [ ] Interest filtering

### Swipe Actions
- [x] Swipe right to like
- [x] Swipe left to pass
- [x] Swipe record in Firestore
- [x] Match detection
- [x] Match creation
- [ ] Swipe up for Super Like
- [ ] Daily limits

### Missing Features (vs Mobile)
- [x] **Likes You Page** [Status: DONE]
- [x] **Weekly Picks Page** [Status: DONE]
- [ ] Profile stories
- [ ] Boost feature
- [ ] Incognito mode
- [ ] Passport mode
- [ ] Photo carousel

---

## Phase 4: Messaging - 90% COMPLETE

### Conversation List
- [x] Create `/messages` page
- [x] Conversation list
- [x] User avatar, name, preview
- [x] Timestamp
- [x] Unread indicator
- [x] Empty state
- [ ] Search
- [ ] Pull to refresh
- [ ] Pinned conversations

### Chat Interface
- [x] Create `/messages/[matchId]` page
- [x] Chat header
- [x] Message bubbles
- [x] Timestamps
- [x] Date separators
- [x] Read receipts
- [x] Delivery status
- [x] Message input
- [x] Send button
- [x] Phone/Video buttons (UI)

### Real-time Updates
- [x] Firestore subscription
- [x] New message handling
- [x] Message status updates
- [ ] Reconnection logic
- [ ] Offline indicator

### Typing Indicators
- [x] Typing status tracking
- [x] Typing animation
- [x] Clear on send
- [x] Debounced updates

### Read Receipts
- [x] Mark read on view
- [x] Read checkmarks
- [x] Batch updates

### Message Pagination
- [x] Infinite scroll up
- [x] Loading indicator
- [x] Scroll position

### Safety Features
- [x] Report dialog
- [x] Report reasons
- [x] Unmatch dialog
- [x] Delete chat dialog
- [x] Safety tips link

### Missing Features (vs Mobile)
- [x] Message reactions [Status: DONE]
- [x] Photo sharing [Status: DONE]
- [ ] Voice notes
- [x] Message edit/unsend [Status: DONE]
- [x] Message requests page [Status: DONE]
- [ ] Ice breakers
- [ ] Video/Audio calls

---

## Phase 5: Profile & Settings - 75% COMPLETE

### Profile View
- [x] Create `/profile` page
- [x] Avatar and header
- [x] Name, age
- [x] Edit button
- [x] Photo gallery
- [x] Bio section
- [x] Interests
- [x] Location
- [ ] Verification badge
- [ ] Lifestyle info
- [ ] Prompts

### Profile Edit
- [x] Create `/profile/edit` page
- [x] Edit basic fields
- [x] Photo management
- [x] Save action
- [x] Sets profileComplete
- [ ] Discard confirmation
- [ ] Photo reordering
- [ ] Photo cropping

### Profile Preview
- [x] Create `/profile/preview` page
- [x] Preview as others see

### Settings Hub
- [x] Create `/settings` page
- [x] Settings layout
- [x] Theme toggle
- [x] Logout action
- [ ] Account section
- [ ] Privacy section
- [ ] Notifications section

### Blocked Users
- [x] Blocked users page
- [x] List blocked
- [x] Unblock action
- [x] Empty state

### Missing Features (vs Mobile)
- [x] **Privacy Settings** [Status: DONE]
- [x] **Notification Settings** [Status: DONE]
- [x] **Discovery Settings** [Status: DONE]
- [x] **Account Security** [Status: DONE]
- [x] **Account Management** [Status: DONE]

---

## Phase 6: Safety & Social - 95% COMPLETE

### Block/Report (from chat only)
- [x] Block from chat
- [x] Report from chat
- [x] Block in Firestore [Status: DONE]
- [x] Remove from matches [Status: DONE]
- [ ] Hide from discovery

### Missing Features (vs Mobile)
- [x] **Date Safety Feature** [Status: DONE]
- [x] **Safety Screen** [Status: DONE]
- [x] **Date Ideas Page** [Status: DONE]
- [x] **Compatibility Quiz** [Status: DONE]
- [x] **Profile Insights** [Status: DONE]
- [x] **Incognito Mode** [Status: DONE]
- [x] **Voice Notes in Chat** [Status: DONE]

---

## Phase 7: Subscription - 80% COMPLETE

### Plans Display
- [x] Create `/premium` page
- [x] Plans comparison
- [x] Free/Plus features
- [x] Pricing display

### Stripe Checkout
- [x] Checkout button
- [x] API route for checkout
- [x] Redirect to Stripe
- [x] Success page
- [ ] Cancel callback
- [ ] Webhook handling

### Feature Gating
- [x] Plus indicators on buttons
- [ ] Plus feature wrapper
- [ ] Upsell modal

### Missing Features (vs Mobile)
- [x] **Subscription Status** [Status: DONE]
- [ ] **Cancel Flow**

---

## Phase 8: Marketing Website - 70% COMPLETE

### Landing Page
- [x] Marketing layout
- [x] Hero section
- [x] CTA buttons
- [x] Features section [Status: DONE]
- [x] How it works [Status: DONE]
- [x] Testimonials [Status: DONE]
- [ ] Download section

### Static Pages
- [x] About page
- [x] Help page
- [x] Privacy Policy
- [x] Terms of Service
- [ ] Features page
- [ ] Pricing page
- [ ] Contact page
- [ ] FAQ page

### SEO
- [ ] Meta tags
- [ ] Open Graph
- [ ] Twitter Cards
- [ ] Schema.org
- [ ] Sitemap.xml
- [ ] Robots.txt

---

## Phase 9: Polish & Testing - 0% COMPLETE

### E2E Tests
- [ ] Auth flow tests
- [ ] Onboarding tests
- [ ] Discovery tests
- [ ] Chat tests
- [ ] Settings tests

### Performance
- [ ] Lighthouse audit
- [ ] Core Web Vitals
- [ ] Bundle analysis
- [ ] Image optimization

### Accessibility
- [ ] Screen reader
- [ ] Keyboard navigation
- [ ] Color contrast
- [ ] Focus management
- [ ] ARIA labels

### Error Handling
- [ ] Error boundaries
- [ ] Fallback UI
- [ ] Retry logic

### Analytics
- [ ] Page views
- [ ] Event tracking
- [ ] Conversion funnel

### Monitoring
- [ ] Error tracking (Sentry)
- [ ] Performance monitoring
- [ ] Uptime alerts

---

## Mobile App Feature Parity Summary

| Feature | Mobile | Web | Priority |
|---------|--------|-----|----------|
| Email/Password Login | Yes | Yes | - |
| Phone OTP | Yes | Yes | - |
| Onboarding Flow | Yes | Yes | - |
| Swipe Deck | Yes | Yes | - |
| Match Modal | Yes | Yes | - |
| Real-time Chat | Yes | Yes | - |
| Typing Indicators | Yes | Yes | - |
| Read Receipts | Yes | Yes | - |
| Profile View/Edit | Yes | Yes | - |
| Theme Toggle | Yes | Yes | - |
| Likes You Page | Yes | Yes | DONE |
| Weekly Picks | Yes | Yes | DONE |
| Message Reactions | Yes | Yes | DONE |
| Photo Sharing | Yes | Yes | DONE |
| Voice Notes | Yes | No | P3 |
| Audio/Video Calls | Yes | No | P3 |
| Privacy Settings | Yes | Yes | DONE |
| Discovery Settings | Yes | Yes | DONE |
| Account Management | Yes | No | P1 |
| Date Safety | Yes | No | P3 |
| Date Ideas | Yes | No | P3 |
| Compatibility Quiz | Yes | No | P3 |
| Profile Insights | Yes | No | P3 |

---

## Priority Implementation Order

### P0 - Critical (DONE)
1. [x] Fix profileComplete flag
2. [x] Fix auth state persistence
3. [x] Deploy to Vercel

### P1 - High Priority (Next Sprint)
1. [x] Terms & Conditions step [Status: DONE]
2. [x] Privacy Settings [Status: DONE]
3. [x] Discovery Settings [Status: DONE]
4. [x] Account Management [Status: DONE]
5. [x] Likes You page [Status: DONE]
6. [x] Photo sharing in chat [Status: DONE]
7. [x] Complete Report/Block [Status: DONE]

### P2 - Medium Priority
1. [x] Message reactions [Status: DONE]
2. [x] Message edit/unsend [Status: DONE]
3. [x] Message requests [Status: DONE]
4. [x] Sexual orientation [Status: DONE]
5. [x] Profile prompts [Status: DONE]
6. [x] Notification settings [Status: DONE]
7. [x] Weekly Picks [Status: DONE]

### P3 - Lower Priority
1. [ ] Voice notes
2. [ ] Audio/Video calls
3. [ ] Date safety
4. [ ] Date ideas
5. [ ] Compatibility quiz
6. [ ] Profile insights
7. [ ] Incognito mode

---

## Architecture Notes

### Current Stack
- **Framework:** Next.js 14 (App Router)
- **State:** Zustand + React Query
- **Styling:** Tailwind CSS
- **UI:** Radix UI + @crush/ui
- **Backend:** Firebase
- **Payments:** Stripe
- **Deployment:** Vercel

### Folder Structure
```
/Users/ace/Desktop/crush-web/
├── apps/web/src/
│   ├── app/
│   │   ├── (marketing)/
│   │   ├── (app)/
│   │   ├── auth/
│   │   └── onboarding/
│   ├── features/
│   └── shared/
└── packages/
    ├── core/
    └── ui/
```

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-01-26 | Initial TODO created | AI |
| 2026-01-27 | Fixed profileComplete flag | AI |
| 2026-01-27 | Fixed auth state with cookies | AI |
| 2026-01-27 | Deployed to Vercel | AI |
| 2026-01-27 | Complete status audit | AI |
| 2026-01-27 | Phase 1: Password strength, country code, resend OTP | AI |
| 2026-01-27 | Phase 3: Keyboard shortcuts for discovery | AI |
| 2026-01-27 | Phase 4: Message reactions, photo sharing | AI |
| 2026-01-27 | Phase 5: Privacy, discovery, notification settings | AI |
| 2026-01-27 | Phase 6: Block user Firestore integration | AI |
| 2026-01-27 | Phase 7: Subscription status display | AI |
| 2026-01-27 | Phase 8: Features, how it works, testimonials | AI |
| 2026-01-27 | P2: Message edit/unsend with 15-min time limit | AI |
| 2026-01-27 | P2: Sexual orientation in onboarding | AI |
| 2026-01-27 | P2: Message requests page (premium feature) | AI |
| 2026-01-27 | P2: Weekly Picks page with compatibility scoring | AI |
| 2026-01-27 | All P2 items completed | AI |
| 2026-01-27 | P1: Account Management page (email, password, data export) | AI |
| 2026-01-27 | All P1 items completed | AI |

---

## Next Steps

1. **Immediate:** P3 items - Voice notes, Date safety features
2. **This Week:** P3 items - Voice notes, Date safety features
3. **This Month:** Phase 9 - Polish, testing, performance optimization
4. **Ongoing:** Marketing pages, SEO, Analytics

---

**Notes:**
- Web app path: `/Users/ace/Desktop/crush-web`
- Mobile app path: `/Users/ace/Desktop/my_first_project`
- Both share Firebase backend
- Live at: https://crush-web-chi.vercel.app

## Parity Backlog (Derived from WEBAPP_PARITY_MATRIX)

_Checklist format with explicit status fields. Use: TODO, DONE, BLOCKED._

### Phase 0
#### core
- [ ] [Status: TODO] `lib/core/accessibility/accessibility.dart` — Dart accessibility.dart
- [ ] [Status: TODO] `lib/core/accessibility/semantics_helper.dart` — Dart semantics_helper.dart
- [ ] [Status: TODO] `lib/core/app_env.dart` — Dart app_env.dart
- [ ] [Status: TODO] `lib/core/app_logger.dart` — Dart app_logger.dart
- [ ] [Status: TODO] `lib/core/cache/cache.dart` — Dart cache.dart
- [ ] [Status: TODO] `lib/core/cache/cache_policy.dart` — Dart cache_policy.dart
- [ ] [Status: TODO] `lib/core/cache/cache_store.dart` — Dart cache_store.dart
- [ ] [Status: TODO] `lib/core/cache/cached_repository.dart` — Dart cached_repository.dart
- [ ] [Status: TODO] `lib/core/cache/offline_queue.dart` — Dart offline_queue.dart
- [ ] [Status: TODO] `lib/core/config/env_config.dart` — Dart env_config.dart
- [ ] [Status: TODO] `lib/core/constants.dart` — Dart constants.dart
- [ ] [Status: TODO] `lib/core/constants/cache_constants.dart` — Dart cache_constants.dart
- [ ] [Status: TODO] `lib/core/constants/constants.dart` — Dart constants.dart
- [ ] [Status: TODO] `lib/core/constants/network_constants.dart` — Dart network_constants.dart
- [ ] [Status: TODO] `lib/core/constants/validation_constants.dart` — Dart validation_constants.dart
- [ ] [Status: TODO] `lib/core/deep_link_bootstrap.dart` — Dart deep_link_bootstrap.dart
- [ ] [Status: TODO] `lib/core/di.dart` — DI di.dart
- [ ] [Status: TODO] `lib/core/di/di.dart` — DI di.dart
- [ ] [Status: TODO] `lib/core/errors.dart` — Dart errors.dart
- [ ] [Status: TODO] `lib/core/extensions/localization_extension.dart` — Dart localization_extension.dart
- [ ] [Status: TODO] `lib/core/feature_flags/feature_flag_widgets.dart` — Dart feature_flag_widgets.dart
- [ ] [Status: TODO] `lib/core/feature_flags/feature_flags.dart` — Dart feature_flags.dart
- [ ] [Status: TODO] `lib/core/firebase_emulator.dart` — Dart firebase_emulator.dart
- [ ] [Status: TODO] `lib/core/network/api_client.dart` — Dart api_client.dart
- [ ] [Status: TODO] `lib/core/network/api_version.dart` — Dart api_version.dart
- [ ] [Status: TODO] `lib/core/network/certificate_pinning.dart` — Dart certificate_pinning.dart
- [ ] [Status: TODO] `lib/core/network/dto/auth_dto.dart` — DTO SendOtpRequestDto, VerifyOtpRequestDto, RefreshTokenRequestDto
- [ ] [Status: TODO] `lib/core/network/dto/base_dto.dart` — DTO DtoMetadata, PaginatedResponse, PaginatedDto
- [ ] [Status: TODO] `lib/core/network/dto/chat_dto.dart` — DTO ConversationDto, ConversationParticipantDto, ConversationsResponseDto
- [ ] [Status: TODO] `lib/core/network/dto/discovery_dto.dart` — DTO DiscoveryDeckDto, DiscoveryProfileDto, SwipeAction
- [ ] [Status: TODO] `lib/core/network/dto/profile_dto.dart` — DTO ProfileDto
- [ ] [Status: TODO] `lib/core/network/mappers/auth_mapper.dart` — Dart auth_mapper.dart
- [ ] [Status: TODO] `lib/core/network/mappers/chat_mapper.dart` — Dart chat_mapper.dart
- [ ] [Status: TODO] `lib/core/network/mappers/discovery_mapper.dart` — Dart discovery_mapper.dart
- [ ] [Status: TODO] `lib/core/network/mappers/mappers.dart` — Dart mappers.dart
- [ ] [Status: TODO] `lib/core/network/mappers/profile_mapper.dart` — Dart profile_mapper.dart
- [ ] [Status: TODO] `lib/core/network/network.dart` — Dart network.dart
- [ ] [Status: TODO] `lib/core/network/realtime/firebase_realtime_service.dart` — Dart firebase_realtime_service.dart
- [ ] [Status: TODO] `lib/core/network/realtime/realtime_connection.dart` — Dart realtime_connection.dart
- [ ] [Status: TODO] `lib/core/performance/performance_monitor.dart` — Dart performance_monitor.dart
- [ ] [Status: TODO] `lib/core/performance/performance_observer.dart` — Dart performance_observer.dart
- [ ] [Status: TODO] `lib/core/result.dart` — Dart result.dart
- [ ] [Status: TODO] `lib/core/router.dart` — Router router.dart
- [ ] [Status: TODO] `lib/core/router_refresh_stream.dart` — Dart router_refresh_stream.dart
- [ ] [Status: TODO] `lib/core/routing/deep_links.dart` — Dart deep_links.dart
- [ ] [Status: TODO] `lib/core/routing/route_guards.dart` — Dart route_guards.dart
- [ ] [Status: TODO] `lib/core/security/input_sanitizer.dart` — Dart input_sanitizer.dart
- [ ] [Status: TODO] `lib/core/security/secure_logger.dart` — Dart secure_logger.dart
- [ ] [Status: TODO] `lib/core/security/session_manager.dart` — Dart session_manager.dart
- [ ] [Status: TODO] `lib/core/services/analytics_service.dart` — Service AnalyticsService
- [ ] [Status: TODO] `lib/core/services/app_state_preserver.dart` — Service AppStatePreserver
- [ ] [Status: TODO] `lib/core/services/app_update_service.dart` — Service AppUpdateService, UpdateCheckResult
- [ ] [Status: TODO] `lib/core/services/badge_counter_service.dart` — Service BadgeCountState, BadgeCounterCubit
- [ ] [Status: TODO] `lib/core/services/crash_reporting_service.dart` — Service CrashReportingService
- [ ] [Status: TODO] `lib/core/services/data_export_service.dart` — Service DataExportService
- [ ] [Status: TODO] `lib/core/services/email_service.dart` — Service EmailService
- [ ] [Status: TODO] `lib/core/services/gradual_rollout_service.dart` — Service GradualRolloutService
- [ ] [Status: TODO] `lib/core/services/haptic_service.dart` — Service HapticService
- [ ] [Status: TODO] `lib/core/services/in_app_review_service.dart` — Service InAppReviewService
- [ ] [Status: TODO] `lib/core/services/location_service.dart` — Service LocationResult, LocationService
- [ ] [Status: TODO] `lib/core/services/offline_cache_service.dart` — Service OfflineCacheService
- [ ] [Status: TODO] `lib/core/services/push_notification_service.dart` — Service PushNotificationService
- [ ] [Status: TODO] `lib/core/services/user_data_clearance_service.dart` — Service UserDataClearanceService
- [ ] [Status: TODO] `lib/core/theme.dart` — Dart theme.dart
- [ ] [Status: TODO] `lib/core/theme/theme.dart` — Design token theme.dart
- [ ] [Status: TODO] `lib/core/ui/snackbar_utils.dart` — Dart snackbar_utils.dart
- [ ] [Status: TODO] `lib/core/utils/constants.dart` — Dart constants.dart
- [ ] [Status: TODO] `lib/core/utils/error_messages.dart` — Dart error_messages.dart
- [ ] [Status: TODO] `lib/core/utils/errors.dart` — Dart errors.dart
- [ ] [Status: TODO] `lib/core/utils/result.dart` — Dart result.dart
- [ ] [Status: TODO] `lib/core/utils/validators.dart` — Dart validators.dart
- [ ] [Status: TODO] `lib/core/validators.dart` — Dart validators.dart
- [ ] [Status: TODO] `lib/core/widgets/update_dialog.dart` — Dart update_dialog.dart

#### data
- [ ] [Status: TODO] `lib/data/dto/profile_dto.dart` — DTO ProfileDto
- [ ] [Status: TODO] `lib/data/dto/user_dto.dart` — DTO UserDto
- [ ] [Status: TODO] `lib/data/models/chat_settings.dart` — Model MessageRetention, ChatSettings
- [ ] [Status: TODO] `lib/data/models/favourites.dart` — Model ProfileFavourites, FavouritesOptions
- [ ] [Status: TODO] `lib/data/models/match.dart` — Model MatchStatus, CrushMatch
- [ ] [Status: TODO] `lib/data/models/message.dart` — Model MessageType, MessageSendStatus, Message
- [ ] [Status: TODO] `lib/data/models/message_request.dart` — Model MessageRequest
- [ ] [Status: TODO] `lib/data/models/preferences.dart` — Model DiscoveryPreferences
- [ ] [Status: TODO] `lib/data/models/privacy_settings.dart` — Model ProfilePrivacySettings
- [ ] [Status: TODO] `lib/data/models/profile.dart` — Model Profile
- [ ] [Status: TODO] `lib/data/models/profile_prompt.dart` — Model ProfilePrompt, PromptQuestions
- [ ] [Status: TODO] `lib/data/models/profile_reaction.dart` — Model ProfileReaction, ReactionContentType, QuickReaction
- [ ] [Status: TODO] `lib/data/models/profile_story.dart` — Model ProfileStory, StoryMediaType, ProfileStoryListExtension
- [ ] [Status: TODO] `lib/data/models/subscription.dart` — Model SubscriptionPlan, SubscriptionPlanX, SubscriptionStatus
- [ ] [Status: TODO] `lib/data/models/user.dart` — Model CrushUser
- [ ] [Status: TODO] `lib/data/repositories/fake_repositories.dart` — Repository FakeAuthRepository
- [ ] [Status: TODO] `lib/data/services/prematch_service.dart` — Service PreMatchService

#### design_system
- [ ] [Status: TODO] `lib/design_system/animations/ds_animations.dart` — Animation ds_animations.dart
- [ ] [Status: TODO] `lib/design_system/design_system.dart` — Dart design_system.dart
- [ ] [Status: TODO] `lib/design_system/theme/app_theme.dart` — Design token app_theme.dart
- [ ] [Status: TODO] `lib/design_system/tokens/blur.dart` — Design token blur.dart
- [ ] [Status: TODO] `lib/design_system/tokens/breakpoints.dart` — Design token breakpoints.dart
- [ ] [Status: TODO] `lib/design_system/tokens/colors.dart` — Design token colors.dart
- [ ] [Status: TODO] `lib/design_system/tokens/elevation.dart` — Design token elevation.dart
- [ ] [Status: TODO] `lib/design_system/tokens/gradients.dart` — Design token gradients.dart
- [ ] [Status: TODO] `lib/design_system/tokens/radius.dart` — Design token radius.dart
- [ ] [Status: TODO] `lib/design_system/tokens/spacing.dart` — Design token spacing.dart
- [ ] [Status: TODO] `lib/design_system/tokens/spacing_widgets.dart` — Design token spacing_widgets.dart
- [ ] [Status: TODO] `lib/design_system/tokens/typography.dart` — Design token typography.dart
- [ ] [Status: TODO] `lib/design_system/utils/accessibility.dart` — Dart accessibility.dart
- [ ] [Status: TODO] `lib/design_system/utils/debouncer.dart` — Dart debouncer.dart
- [ ] [Status: TODO] `lib/design_system/utils/haptics.dart` — Dart haptics.dart
- [ ] [Status: TODO] `lib/design_system/utils/page_transitions.dart` — Dart page_transitions.dart
- [ ] [Status: TODO] `lib/design_system/widgets/app_text_field.dart` — Dart app_text_field.dart
- [ ] [Status: TODO] `lib/design_system/widgets/auth_scaffold.dart` — Dart auth_scaffold.dart
- [ ] [Status: TODO] `lib/design_system/widgets/crush_avatar.dart` — Dart crush_avatar.dart
- [ ] [Status: TODO] `lib/design_system/widgets/crush_badge.dart` — Dart crush_badge.dart
- [ ] [Status: TODO] `lib/design_system/widgets/crush_empty_state.dart` — Dart crush_empty_state.dart
- [ ] [Status: TODO] `lib/design_system/widgets/crush_icon_button.dart` — Dart crush_icon_button.dart
- [ ] [Status: TODO] `lib/design_system/widgets/empty_state.dart` — Dart empty_state.dart
- [ ] [Status: TODO] `lib/design_system/widgets/error_banner.dart` — Dart error_banner.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_app_bar.dart` — Dart glass_app_bar.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_bottom_nav_bar.dart` — Dart glass_bottom_nav_bar.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_button.dart` — Dart glass_button.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_card.dart` — Dart glass_card.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_chip.dart` — Dart glass_chip.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_container.dart` — Dart glass_container.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_refresh_indicator.dart` — Dart glass_refresh_indicator.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_skeleton.dart` — Dart glass_skeleton.dart
- [ ] [Status: TODO] `lib/design_system/widgets/glass_text_field.dart` — Dart glass_text_field.dart
- [ ] [Status: TODO] `lib/design_system/widgets/loading_overlay.dart` — Dart loading_overlay.dart
- [ ] [Status: TODO] `lib/design_system/widgets/match_celebration.dart` — Dart match_celebration.dart
- [ ] [Status: TODO] `lib/design_system/widgets/message_search.dart` — Dart message_search.dart
- [ ] [Status: TODO] `lib/design_system/widgets/onboarding.dart` — Dart onboarding.dart
- [ ] [Status: TODO] `lib/design_system/widgets/otp_input.dart` — Dart otp_input.dart
- [ ] [Status: TODO] `lib/design_system/widgets/primary_button.dart` — Dart primary_button.dart
- [ ] [Status: TODO] `lib/design_system/widgets/profile_completion.dart` — Dart profile_completion.dart
- [ ] [Status: TODO] `lib/design_system/widgets/read_receipt.dart` — Dart read_receipt.dart
- [ ] [Status: TODO] `lib/design_system/widgets/refresh_wrapper.dart` — Dart refresh_wrapper.dart
- [ ] [Status: TODO] `lib/design_system/widgets/responsive_scaffold.dart` — Dart responsive_scaffold.dart
- [ ] [Status: TODO] `lib/design_system/widgets/skeleton_loader.dart` — Dart skeleton_loader.dart
- [ ] [Status: TODO] `lib/design_system/widgets/super_like_animation.dart` — Dart super_like_animation.dart
- [ ] [Status: TODO] `lib/design_system/widgets/typing_indicator.dart` — Dart typing_indicator.dart

#### feature_flags
- [ ] [Status: TODO] `lib/features/feature_flags/data/models/feature_flags.dart` — Model FeatureFlags
- [ ] [Status: TODO] `lib/features/feature_flags/data/repositories/feature_flag_repository.dart` — Repository feature_flag_repository.dart
- [ ] [Status: TODO] `lib/features/feature_flags/data/repositories/impl/firebase_feature_flag_repository.dart` — Repository FirebaseFeatureFlagRepository
- [ ] [Status: TODO] `lib/features/feature_flags/data/repositories/impl/stub_feature_flag_repository.dart` — Repository StubFeatureFlagRepository
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/feature_flag_use_cases.dart` — UseCase feature_flag_use_cases.dart
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/fetch_and_activate_flags.dart` — UseCase FetchAndActivateFlagsUseCase
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/force_refresh_flags.dart` — UseCase ForceRefreshFlagsUseCase
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/get_bool_flag.dart` — UseCase GetBoolFlagParams, GetBoolFlagUseCase
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/get_current_flags.dart` — UseCase GetCurrentFlagsUseCase
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/get_int_flag.dart` — UseCase GetIntFlagParams, GetIntFlagUseCase
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/get_string_flag.dart` — UseCase GetStringFlagParams, GetStringFlagUseCase
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/initialize_flags.dart` — UseCase InitializeFlagsUseCase
- [ ] [Status: TODO] `lib/features/feature_flags/domain/usecases/watch_flags.dart` — UseCase WatchFlagsUseCase
- [ ] [Status: TODO] `lib/features/feature_flags/presentation/bloc/feature_flag_cubit.dart` — State FeatureFlagCubit, FeatureFlagStatus, FeatureFlagState

#### features_root
- [ ] [Status: TODO] `lib/features/features.dart` — Dart features.dart

#### shared
- [ ] [Status: TODO] `lib/shared/shared.dart` — Dart shared.dart
- [ ] [Status: TODO] `lib/shared/utils/profanity_filter.dart` — Dart profanity_filter.dart
- [ ] [Status: TODO] `lib/shared/utils/profile_completeness.dart` — Dart profile_completeness.dart
- [ ] [Status: TODO] `lib/shared/utils/profile_field_options.dart` — Dart profile_field_options.dart
- [ ] [Status: TODO] `lib/shared/utils/profile_media_limits.dart` — Dart profile_media_limits.dart
- [ ] [Status: TODO] `lib/shared/widgets/async_state_scaffold.dart` — Dart async_state_scaffold.dart
- [ ] [Status: TODO] `lib/shared/widgets/cached_image.dart` — Dart cached_image.dart
- [ ] [Status: TODO] `lib/shared/widgets/cached_network_image.dart` — Dart cached_network_image.dart

### Phase 0/1
#### app_shell
- [ ] [Status: TODO] `lib/app.dart` — Dart app.dart
- [ ] [Status: TODO] `lib/config/billing_config.dart` — Dart billing_config.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/showcases/avatars_showcase.dart` — Dart avatars_showcase.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/showcases/badges_showcase.dart` — Dart badges_showcase.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/showcases/buttons_showcase.dart` — Dart buttons_showcase.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/showcases/cards_showcase.dart` — Dart cards_showcase.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/showcases/inputs_showcase.dart` — Dart inputs_showcase.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/showcases/layout_showcase.dart` — Dart layout_showcase.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/showcases/spacing_showcase.dart` — Dart spacing_showcase.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/showcases/states_showcase.dart` — Dart states_showcase.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/widget_catalog_screen.dart` — Dart widget_catalog_screen.dart
- [ ] [Status: TODO] `lib/dev/widget_catalog/widget_showcase.dart` — Dart widget_showcase.dart
- [ ] [Status: TODO] `lib/domain/use_cases/use_case.dart` — Dart use_case.dart
- [ ] [Status: TODO] `lib/domain/use_cases/use_cases.dart` — Dart use_cases.dart
- [ ] [Status: TODO] `lib/main.dart` — Dart main.dart

#### presentation
- [ ] [Status: TODO] `lib/presentation/screens/community_guidelines_screen.dart` — Screen CommunityGuidelinesScreen, _Bullet
- [ ] [Status: TODO] `lib/presentation/screens/home/settings_screen.dart` — Screen SettingsScreen, _SettingsScreenState
- [ ] [Status: TODO] `lib/presentation/screens/home_screen.dart` — Screen HomeScreen, _HomeScreenState
- [ ] [Status: TODO] `lib/presentation/screens/privacy_policy_screen.dart` — Screen PrivacyPolicyScreen
- [ ] [Status: TODO] `lib/presentation/screens/safety_screen.dart` — Screen SafetyScreen, _SafetyScreenState
- [ ] [Status: TODO] `lib/presentation/screens/terms_of_service_screen.dart` — Screen TermsOfServiceScreen
- [ ] [Status: TODO] `lib/presentation/screens/test/test_video_screen.dart` — Screen TestVideoScreen
- [ ] [Status: TODO] `lib/presentation/widgets/onboarding_nav_buttons.dart` — Widget OnboardingNavButtons
- [ ] [Status: TODO] `lib/presentation/widgets/onboarding_progress.dart` — Widget OnboardingProgress
- [ ] [Status: TODO] `lib/presentation/widgets/plus_feature_gate.dart` — Widget PremiumAction, PlusFeatureGate
- [ ] [Status: TODO] `lib/presentation/widgets/primary_button.dart` — Widget primary_button.dart
- [ ] [Status: TODO] `lib/presentation/widgets/upsell_widgets.dart` — Widget UpgradeNudgeCard, IntroBadge, UpsellBullets

### Phase 1
#### auth
- [ ] [Status: TODO] `lib/features/auth/auth.dart` — Dart auth.dart
- [ ] [Status: TODO] `lib/features/auth/data/repositories/auth_repository.dart` — Repository EmailOtpPurpose, EmailOtpPurposeValue
- [ ] [Status: TODO] `lib/features/auth/data/repositories/impl/firebase_auth_repository.dart` — Repository FirebaseAuthRepository
- [ ] [Status: TODO] `lib/features/auth/data/repositories/impl/http_auth_repository.dart` — Repository HttpAuthRepository
- [ ] [Status: TODO] `lib/features/auth/data/repositories/impl/stub_auth_repository.dart` — Repository StubAuthRepository
- [ ] [Status: TODO] `lib/features/auth/domain/usecases/auth_use_cases.dart` — UseCase auth_use_cases.dart
- [ ] [Status: TODO] `lib/features/auth/domain/usecases/send_phone_otp.dart` — UseCase SendPhoneOtpParams, SendPhoneOtpUseCase
- [ ] [Status: TODO] `lib/features/auth/domain/usecases/sign_in_with_password.dart` — UseCase SignInParams, SignInWithPasswordUseCase
- [ ] [Status: TODO] `lib/features/auth/domain/usecases/sign_out.dart` — UseCase SignOutUseCase
- [ ] [Status: TODO] `lib/features/auth/domain/usecases/verify_phone_otp.dart` — UseCase VerifyPhoneOtpParams, VerifyPhoneOtpUseCase
- [ ] [Status: TODO] `lib/features/auth/presentation/bloc/auth_bloc.dart` — State AuthBloc
- [ ] [Status: TODO] `lib/features/auth/presentation/bloc/auth_event.dart` — State AuthStarted, AuthPhoneSubmitted, AuthOtpSubmitted
- [ ] [Status: TODO] `lib/features/auth/presentation/bloc/auth_state.dart` — State AuthStatus, AuthState
- [ ] [Status: TODO] `lib/features/auth/presentation/bloc/session_bloc.dart` — State SessionStarted, SessionUserChanged, SessionSignOutRequested
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/auth_gateway_screen.dart` — Screen AuthGatewayScreen, _AuthGatewayScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/basic_info_screen.dart` — Screen BasicInfoScreen, _BasicInfoScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/change_email_screen.dart` — Screen ChangeEmailScreen, _ChangeEmailScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/email_auth_screen.dart` — Screen EmailAuthScreen, _EmailAuthScreenState, _EmailLinkTab
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/email_protection_screen.dart` — Screen EmailProtectionScreen, _EmailProtectionScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/email_verification_screen.dart` — Screen EmailVerificationScreen, _EmailVerificationScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/forgot_password_screen.dart` — Screen ForgotPasswordScreen, _ForgotPasswordScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/id_verification_screen.dart` — Screen IdVerificationScreen, _IdVerificationScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/login_screen.dart` — Screen LoginScreen, _LoginScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/logout_screen.dart` — Screen LogoutScreen
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/new_device_screen.dart` — Screen NewDeviceScreen, _NewDeviceScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/otp_screen.dart` — Screen OtpScreen, _OtpScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/phone_auth_screen.dart` — Screen PhoneAuthScreen, _PhoneAuthScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/phone_protection_screen.dart` — Screen PhoneProtectionScreen, _PhoneProtectionScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/sign_up_screen.dart` — Screen SignUpScreen, _SignUpScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/splash_screen.dart` — Screen SplashScreen, _SplashScreenState
- [ ] [Status: TODO] `lib/features/auth/presentation/screens/terms_conditions_screen.dart` — Screen TermsConditionsScreen, _TermsConditionsScreenState

### Phase 2/5
#### profile
- [ ] [Status: TODO] `lib/features/profile/data/repositories/impl/firebase_profile_repository.dart` — Repository FirebaseProfileRepository
- [ ] [Status: TODO] `lib/features/profile/data/repositories/impl/http_profile_repository.dart` — Repository HttpProfileRepository
- [ ] [Status: TODO] `lib/features/profile/data/repositories/impl/stub_profile_repository.dart` — Repository StubProfileRepository
- [ ] [Status: TODO] `lib/features/profile/data/repositories/profile_repository.dart` — Repository profile_repository.dart
- [ ] [Status: TODO] `lib/features/profile/data/services/profile_media_service.dart` — Service ProfileMediaService
- [ ] [Status: TODO] `lib/features/profile/data/services/profile_validation_service.dart` — Service RemoteProfileCompleteness, ProfileValidationService, TimeoutException
- [ ] [Status: TODO] `lib/features/profile/domain/usecases/get_current_user.dart` — UseCase GetCurrentUserUseCase
- [ ] [Status: TODO] `lib/features/profile/domain/usecases/mark_id_verified.dart` — UseCase MarkIdVerifiedUseCase
- [ ] [Status: TODO] `lib/features/profile/domain/usecases/profile_use_cases.dart` — UseCase profile_use_cases.dart
- [ ] [Status: TODO] `lib/features/profile/domain/usecases/save_basic_info.dart` — UseCase SaveBasicInfoParams, SaveBasicInfoUseCase
- [ ] [Status: TODO] `lib/features/profile/domain/usecases/save_profile_details.dart` — UseCase SaveProfileDetailsParams, SaveProfileDetailsUseCase
- [ ] [Status: TODO] `lib/features/profile/domain/usecases/update_profile.dart` — UseCase UpdateProfileParams, UpdateProfileUseCase
- [ ] [Status: TODO] `lib/features/profile/domain/usecases/upload_id_document.dart` — UseCase UploadIdDocumentUseCase
- [ ] [Status: TODO] `lib/features/profile/presentation/bloc/profile_bloc.dart` — State ProfileBloc
- [ ] [Status: TODO] `lib/features/profile/presentation/bloc/profile_event.dart` — State ProfileLoadRequested, ProfileSaveRequested, ProfileBasicInfoSubmitted
- [ ] [Status: TODO] `lib/features/profile/presentation/bloc/profile_state.dart` — State ProfileStatus, ProfileState
- [ ] [Status: TODO] `lib/features/profile/presentation/screens/other_user_profile_screen.dart` — Screen OtherUserProfileArgs, OtherUserProfileScreen
- [ ] [Status: TODO] `lib/features/profile/presentation/screens/profile_edit_screen.dart` — Screen ProfileEditScreen, _ProfileEditScreenState
- [ ] [Status: TODO] `lib/features/profile/presentation/screens/profile_media_screen.dart` — Screen ProfileMediaArgs, ProfileMediaScreen, _ProfileMediaScreenState
- [ ] [Status: TODO] `lib/features/profile/presentation/screens/profile_setup_screen.dart` — Screen ProfileSetupScreen, _ProfileSetupScreenState
- [ ] [Status: TODO] `lib/features/profile/presentation/screens/profile_view_screen.dart` — Screen ProfileViewScreen, _ProfileViewScreenState
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/profile_chip_display.dart` — Widget ProfileChipDisplay, ProfileFieldDisplay
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/profile_completeness_meter.dart` — Widget ProfileCompletenessMeter
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/profile_field_tile.dart` — Widget ProfileFieldTile, ProfileSectionHeader
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/profile_height_picker.dart` — Widget ProfileHeightPicker, _ProfileHeightPickerState
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/profile_media_picker.dart` — Widget ProfileMediaSelection, ProfileMediaPicker, _ProfileMediaPickerState
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/profile_multi_select_sheet.dart` — Widget ProfileMultiSelectSheet, _ProfileMultiSelectSheetState
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/profile_single_select_sheet.dart` — Widget ProfileSingleSelectSheet
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/profile_widgets.dart` — Widget profile_widgets.dart
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/prompt_card.dart` — Widget PromptCard, PromptCardList, PromptCardColumn
- [ ] [Status: TODO] `lib/features/profile/presentation/widgets/prompt_editor.dart` — Widget PromptEditor, _PromptTile
- [ ] [Status: TODO] `lib/features/profile/profile.dart` — Dart profile.dart

#### verification
- [ ] [Status: TODO] `lib/features/verification/data/models/photo_verification.dart` — Model PhotoVerification, VerificationStatus, VerificationPose
- [ ] [Status: TODO] `lib/features/verification/data/services/photo_verification_service.dart` — Service PhotoVerificationService
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/get_random_pose.dart` — UseCase GetRandomPoseUseCase
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/get_verification_status.dart` — UseCase GetVerificationStatusParams, GetVerificationStatusUseCase
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/is_user_verified.dart` — UseCase IsUserVerifiedParams, IsUserVerifiedUseCase
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/reset_verification.dart` — UseCase ResetVerificationUseCase
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/start_verification.dart` — UseCase StartVerificationParams, StartVerificationUseCase
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/submit_selfie.dart` — UseCase SubmitSelfieParams, SubmitSelfieUseCase
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/verification_use_cases.dart` — UseCase verification_use_cases.dart
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/watch_current_pose.dart` — UseCase WatchCurrentPoseUseCase
- [ ] [Status: TODO] `lib/features/verification/domain/usecases/watch_verification.dart` — UseCase WatchVerificationUseCase

### Phase 3
#### discovery
- [ ] [Status: TODO] `lib/features/discovery/data/models/daily_likes_limit.dart` — Model DailyLikesLimit
- [ ] [Status: TODO] `lib/features/discovery/data/models/filter_options.dart` — Model DiscoveryFilterOptions, FilterOption, HeightUtils
- [ ] [Status: TODO] `lib/features/discovery/data/models/incognito_settings.dart` — Model IncognitoSettings
- [ ] [Status: TODO] `lib/features/discovery/data/models/like_priority.dart` — Model LikePriority, LikePriorityLevel, LikePriorityLevelExtension
- [ ] [Status: TODO] `lib/features/discovery/data/models/weekly_picks.dart` — Model WeeklyPicks, WeeklyPick
- [ ] [Status: TODO] `lib/features/discovery/data/repositories/boost_repository.dart` — Repository BoostSession, BoostStatus
- [ ] [Status: TODO] `lib/features/discovery/data/repositories/discovery_repository.dart` — Repository DiscoveryFilter
- [ ] [Status: TODO] `lib/features/discovery/data/repositories/impl/firebase_boost_repository.dart` — Repository FirebaseBoostRepository
- [ ] [Status: TODO] `lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart` — Repository FirebaseDiscoveryRepository
- [ ] [Status: TODO] `lib/features/discovery/data/repositories/impl/http_discovery_repository.dart` — Repository HttpDiscoveryRepository
- [ ] [Status: TODO] `lib/features/discovery/data/repositories/impl/hybrid_discovery_repository.dart` — Repository HybridDiscoveryRepository
- [ ] [Status: TODO] `lib/features/discovery/data/repositories/impl/stub_boost_repository.dart` — Repository StubBoostRepository
- [ ] [Status: TODO] `lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart` — Repository StubDiscoveryRepository
- [ ] [Status: TODO] `lib/features/discovery/data/services/daily_likes_service.dart` — Service DailyLikesService, LikeResult
- [ ] [Status: TODO] `lib/features/discovery/data/services/incognito_service.dart` — Service IncognitoService
- [ ] [Status: TODO] `lib/features/discovery/data/services/like_priority_service.dart` — Service LikePriorityService
- [ ] [Status: TODO] `lib/features/discovery/data/services/passport_locations_service.dart` — Service PassportLocationsService
- [ ] [Status: TODO] `lib/features/discovery/data/services/profile_reaction_service.dart` — Service ProfileReactionService, ReactionUpdateType
- [ ] [Status: TODO] `lib/features/discovery/data/services/realtime_match_service.dart` — Service RealtimeMatchNotification, RealtimeMatchService
- [ ] [Status: TODO] `lib/features/discovery/data/services/story_service.dart` — Service StoryService, StoryUpdateType
- [ ] [Status: TODO] `lib/features/discovery/data/services/weekly_picks_service.dart` — Service WeeklyPicksService
- [ ] [Status: TODO] `lib/features/discovery/discovery.dart` — Dart discovery.dart
- [ ] [Status: TODO] `lib/features/discovery/domain/usecases/discovery_use_cases.dart` — UseCase discovery_use_cases.dart
- [ ] [Status: TODO] `lib/features/discovery/domain/usecases/fetch_discovery_deck.dart` — UseCase FetchDeckParams, FetchDiscoveryDeckUseCase
- [ ] [Status: TODO] `lib/features/discovery/domain/usecases/swipe_right.dart` — UseCase SwipeRightParams, SwipeRightResult, SwipeRightUseCase
- [ ] [Status: TODO] `lib/features/discovery/presentation/bloc/boost_cubit.dart` — State BoostState, BoostCubit
- [ ] [Status: TODO] `lib/features/discovery/presentation/bloc/discovery_bloc.dart` — State DiscoveryBloc
- [ ] [Status: TODO] `lib/features/discovery/presentation/bloc/discovery_event.dart` — State DiscoveryDeckRequested, DiscoverySwipedRight, DiscoverySwipedLeft
- [ ] [Status: TODO] `lib/features/discovery/presentation/bloc/discovery_settings_cubit.dart` — State DiscoverySettingsState
- [ ] [Status: TODO] `lib/features/discovery/presentation/bloc/discovery_state.dart` — State DeckStatus, MatchResult, DiscoveryState
- [ ] [Status: TODO] `lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart` — State WeeklyPicksState, WeeklyPicksCubit
- [ ] [Status: TODO] `lib/features/discovery/presentation/screens/deck_screen.dart` — Screen DeckScreen, _DeckScreenState
- [ ] [Status: TODO] `lib/features/discovery/presentation/screens/likes_you_screen.dart` — Screen LikesYouScreen, _LikesYouScreenState
- [ ] [Status: TODO] `lib/features/discovery/presentation/screens/story_viewer_screen.dart` — Screen StoryViewerArgs, StoryViewerScreen, _StoryViewerScreenState
- [ ] [Status: TODO] `lib/features/discovery/presentation/screens/weekly_picks_screen.dart` — Screen WeeklyPicksScreen, _WeeklyPicksScreenState
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/boost_button.dart` — Widget BoostButton
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/content_reaction_button.dart` — Widget ContentReactionButton, _ContentReactionButtonState, _GlassIconButton
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/deck_card_stack.dart` — Widget DeckCardStack, _DeckCardStackState, DeckPreviewStack
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/deck_skeleton.dart` — Widget DeckSkeletonList, SkeletonCard, SkeletonCircle
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/deck_ui_helpers.dart` — Widget DeckActionButton, _DeckActionButtonState, DeckStatusBar
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/empty_deck_animations.dart` — Widget PulsingIconContainer, _PulsingIconContainerState, AnimatedPassportButton
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/match_celebration_modal.dart` — Widget MatchCelebrationModal, _MatchCelebrationModalState
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/profile_video_player.dart` — Widget ProfileVideoPlayer, _ProfileVideoPlayerState
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/story_ring.dart` — Widget StoryRing, _StoryRingPainter, StoryBadge
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/swipe_card.dart` — Widget SwipeCard, _SwipeCardState
- [ ] [Status: TODO] `lib/features/discovery/presentation/widgets/swipeable_card.dart` — Widget SwipeableCard, _SwipeableCardState

### Phase 4
#### chat
- [ ] [Status: TODO] `lib/features/chat/chat.dart` — Dart chat.dart
- [ ] [Status: TODO] `lib/features/chat/data/repositories/chat_repository.dart` — Repository PaginatedResult
- [ ] [Status: TODO] `lib/features/chat/data/repositories/impl/firebase_chat_repository.dart` — Repository FirebaseChatRepository
- [ ] [Status: TODO] `lib/features/chat/data/repositories/impl/http_chat_repository.dart` — Repository HttpChatRepository
- [ ] [Status: TODO] `lib/features/chat/data/repositories/impl/stub_chat_repository.dart` — Repository StubChatRepository
- [ ] [Status: TODO] `lib/features/chat/data/services/ice_breaker_service.dart` — Service IceBreakerService, IceBreakerSuggestion
- [ ] [Status: TODO] `lib/features/chat/data/services/voice_recorder_service.dart` — Service VoiceRecorderService
- [ ] [Status: TODO] `lib/features/chat/domain/usecases/chat_use_cases.dart` — UseCase chat_use_cases.dart
- [ ] [Status: TODO] `lib/features/chat/domain/usecases/send_media.dart` — UseCase SendMediaParams, SendMediaResult, SendMediaUseCase
- [ ] [Status: TODO] `lib/features/chat/domain/usecases/send_message.dart` — UseCase SendMessageParams, SendMessageUseCase
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/chat_bloc.dart` — State ChatBloc
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/chat_event.dart` — State ChatOpened, ChatClosed, ChatMessageSent
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/chat_state.dart` — State SendStatus, ChatState
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart` — State MatchChatSettingsState, MatchChatSettingsCubit
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/matches_bloc.dart` — State MatchesBloc
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/matches_event.dart` — State MatchesLoadRequested, MatchesRefreshRequested, MatchesLoadMoreRequested
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/matches_state.dart` — State MatchesStatus, MatchesState
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/message_requests_cubit.dart` — State MessageRequestsCubit
- [ ] [Status: TODO] `lib/features/chat/presentation/bloc/message_requests_state.dart` — State RequestActionStatus, MessageRequestsState
- [ ] [Status: TODO] `lib/features/chat/presentation/screens/chat_list_screen.dart` — Screen ChatListScreen, _ChatListView
- [ ] [Status: TODO] `lib/features/chat/presentation/screens/chat_screen.dart` — Screen ChatScreenArgs, ChatScreen, _ChatScreenState
- [ ] [Status: TODO] `lib/features/chat/presentation/screens/matches_screen.dart` — Screen MatchesScreen, _MatchesView, _MatchesViewState
- [ ] [Status: TODO] `lib/features/chat/presentation/screens/message_requests_screen.dart` — Screen MessageRequestsScreen, _MessageRequestsView
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/chat_attachment_tile.dart` — Widget ChatAttachmentTile
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/chat_date_separator.dart` — Widget ChatDateSeparator
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/chat_empty_state.dart` — Widget ChatEmptyState, _IceBreakerTile
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/chat_fade_notification.dart` — Widget ChatFadeNotification, _ChatFadeNotificationState
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/chat_reaction_button.dart` — Widget ChatReactionButton, _ChatReactionButtonState
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/chat_send_status_bar.dart` — Widget ChatSendStatusBar
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/chat_typing_indicator.dart` — Widget ChatTypingIndicator, _ChatTypingIndicatorState
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/chat_widgets.dart` — Widget chat_widgets.dart
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/voice_note_player.dart` — Widget VoiceNotePlayer, _VoiceNotePlayerState
- [ ] [Status: TODO] `lib/features/chat/presentation/widgets/voice_note_recorder.dart` — Widget VoiceNoteRecorder, _RecorderState, _VoiceNoteRecorderState

### Phase 5
#### settings
- [ ] [Status: TODO] `lib/features/settings/presentation/bloc/chat_settings_cubit.dart` — State ChatSettingsState, ChatSettingsCubit
- [ ] [Status: TODO] `lib/features/settings/presentation/bloc/locale_cubit.dart` — State LocaleState, LocaleCubit
- [ ] [Status: TODO] `lib/features/settings/presentation/bloc/notification_settings_cubit.dart` — State NotificationSettingsState, NotificationSettingsCubit
- [ ] [Status: TODO] `lib/features/settings/presentation/bloc/privacy_settings_cubit.dart` — State PrivacySettingsCubit
- [ ] [Status: TODO] `lib/features/settings/presentation/bloc/safety_cubit.dart` — State SafetyProfileInfo, SafetyState, SafetyCubit
- [ ] [Status: TODO] `lib/features/settings/presentation/bloc/storage_settings_cubit.dart` — State StorageSettingsState, StorageSettingsCubit
- [ ] [Status: TODO] `lib/features/settings/presentation/bloc/theme_cubit.dart` — State ThemeCubit
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/account_actions_settings_screen.dart` — Screen AccountActionsSettingsScreen, _AccountActionsSettingsScreenState
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/account_security_settings_screen.dart` — Screen AccountSecuritySettingsScreen
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/chat_settings_screen.dart` — Screen ChatSettingsScreen
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/data_storage_settings_screen.dart` — Screen DataStorageSettingsScreen
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/discovery_filters_settings_screen.dart` — Screen DiscoveryFiltersSettingsScreen
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/language_region_settings_screen.dart` — Screen LanguageRegionSettingsScreen
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/notifications_settings_screen.dart` — Screen NotificationsSettingsScreen, _SettingsTile
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/privacy_settings_screen.dart` — Screen PrivacySettingsScreen
- [ ] [Status: TODO] `lib/features/settings/presentation/screens/settings_screen.dart` — Screen SettingsScreen
- [ ] [Status: TODO] `lib/features/settings/settings.dart` — Dart settings.dart

### Phase 6
#### analytics
- [ ] [Status: TODO] `lib/features/analytics/data/models/profile_insights.dart` — Model ProfileInsights, DailyMetric
- [ ] [Status: TODO] `lib/features/analytics/data/services/profile_insights_service.dart` — Service ProfileInsightsService, PhotoPerformance
- [ ] [Status: TODO] `lib/features/analytics/domain/usecases/analytics_use_cases.dart` — UseCase analytics_use_cases.dart
- [ ] [Status: TODO] `lib/features/analytics/domain/usecases/get_insights_for_range.dart` — UseCase GetInsightsForRangeParams, GetInsightsForRangeUseCase
- [ ] [Status: TODO] `lib/features/analytics/domain/usecases/get_photo_performance.dart` — UseCase GetPhotoPerformanceUseCase
- [ ] [Status: TODO] `lib/features/analytics/domain/usecases/load_insights.dart` — UseCase LoadInsightsParams, LoadInsightsUseCase
- [ ] [Status: TODO] `lib/features/analytics/domain/usecases/record_like_received.dart` — UseCase RecordLikeReceivedParams, RecordLikeReceivedUseCase
- [ ] [Status: TODO] `lib/features/analytics/domain/usecases/record_profile_view.dart` — UseCase RecordProfileViewParams, RecordProfileViewUseCase
- [ ] [Status: TODO] `lib/features/analytics/domain/usecases/watch_insights.dart` — UseCase WatchInsightsUseCase
- [ ] [Status: TODO] `lib/features/analytics/presentation/bloc/profile_insights_cubit.dart` — State ProfileInsightsState, ProfileInsightsCubit
- [ ] [Status: TODO] `lib/features/analytics/presentation/screens/profile_insights_screen.dart` — Screen ProfileInsightsScreen, _ProfileInsightsScreenState

#### safety
- [ ] [Status: TODO] `lib/features/safety/data/models/date_plan.dart` — Model DatePlan
- [ ] [Status: TODO] `lib/features/safety/data/services/date_plan_service.dart` — Service DatePlanService
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/add_emergency_contact.dart` — UseCase AddEmergencyContactParams, AddEmergencyContactUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/cancel_date_plan.dart` — UseCase CancelDatePlanParams, CancelDatePlanUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/check_in.dart` — UseCase CheckInParams, CheckInUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/create_date_plan.dart` — UseCase CreateDatePlanParams, CreateDatePlanUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/end_date_safely.dart` — UseCase EndDateSafelyParams, EndDateSafelyUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/get_active_plans.dart` — UseCase GetActivePlansParams, GetActivePlansUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/safety_use_cases.dart` — UseCase safety_use_cases.dart
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/start_date.dart` — UseCase StartDateParams, StartDateUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/trigger_emergency_alert.dart` — UseCase TriggerEmergencyAlertParams, TriggerEmergencyAlertUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/watch_check_in_status.dart` — UseCase WatchCheckInStatusUseCase
- [ ] [Status: TODO] `lib/features/safety/domain/usecases/watch_date_plan.dart` — UseCase WatchDatePlanUseCase

#### social
- [ ] [Status: TODO] `lib/features/social/data/models/compatibility_quiz.dart` — Model CompatibilityQuiz, QuizQuestion, QuizOption
- [ ] [Status: TODO] `lib/features/social/data/models/date_idea.dart` — Model DateIdea, DateCategory, DateCategoryExtension
- [ ] [Status: TODO] `lib/features/social/data/services/compatibility_quiz_service.dart` — Service CompatibilityQuizService
- [ ] [Status: TODO] `lib/features/social/data/services/date_idea_service.dart` — Service DateIdeaService
- [ ] [Status: TODO] `lib/features/social/domain/usecases/complete_quiz.dart` — UseCase CompleteQuizParams, CompleteQuizUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/get_all_date_ideas.dart` — UseCase GetAllDateIdeasUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/get_all_quizzes.dart` — UseCase GetAllQuizzesUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/get_personalized_suggestions.dart` — UseCase GetPersonalizedSuggestionsParams, GetPersonalizedSuggestionsUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/get_quiz_result.dart` — UseCase GetQuizResultParams, GetQuizResultUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/invite_to_quiz.dart` — UseCase InviteToQuizParams, InviteToQuizUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/remove_saved_idea.dart` — UseCase RemoveSavedIdeaParams, RemoveSavedIdeaUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/save_date_idea.dart` — UseCase SaveDateIdeaParams, SaveDateIdeaUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/search_date_ideas.dart` — UseCase SearchDateIdeasParams, SearchDateIdeasUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/send_idea_to_match.dart` — UseCase SendIdeaToMatchParams, SendIdeaToMatchUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/social_use_cases.dart` — UseCase social_use_cases.dart
- [ ] [Status: TODO] `lib/features/social/domain/usecases/start_quiz.dart` — UseCase StartQuizParams, StartQuizUseCase
- [ ] [Status: TODO] `lib/features/social/domain/usecases/submit_quiz_answer.dart` — UseCase SubmitQuizAnswerParams, SubmitQuizAnswerUseCase
- [ ] [Status: TODO] `lib/features/social/presentation/bloc/compatibility_quiz_cubit.dart` — State CompatibilityQuizState, CompatibilityQuizCubit
- [ ] [Status: TODO] `lib/features/social/presentation/bloc/date_ideas_cubit.dart` — State DateIdeasState, DateIdeasCubit
- [ ] [Status: TODO] `lib/features/social/presentation/screens/compatibility_quiz_screen.dart` — Screen CompatibilityQuizScreen, _CompatibilityQuizScreenState
- [ ] [Status: TODO] `lib/features/social/presentation/screens/date_ideas_screen.dart` — Screen DateIdeasScreen, _DateIdeasScreenState

### Phase 7
#### subscription
- [ ] [Status: TODO] `lib/features/subscription/data/repositories/impl/firebase_subscription_repository.dart` — Repository FirebaseSubscriptionRepository
- [ ] [Status: TODO] `lib/features/subscription/data/repositories/impl/http_subscription_repository.dart` — Repository HttpSubscriptionRepository
- [ ] [Status: TODO] `lib/features/subscription/data/repositories/impl/stub_subscription_repository.dart` — Repository StubSubscriptionRepository
- [ ] [Status: TODO] `lib/features/subscription/data/repositories/subscription_repository.dart` — Repository subscription_repository.dart
- [ ] [Status: TODO] `lib/features/subscription/data/services/checkout_service.dart` — Service CheckoutService
- [ ] [Status: TODO] `lib/features/subscription/data/services/subscription_service.dart` — Service SubscriptionService
- [ ] [Status: TODO] `lib/features/subscription/domain/usecases/get_current_plan.dart` — UseCase GetCurrentPlanUseCase
- [ ] [Status: TODO] `lib/features/subscription/domain/usecases/launch_checkout.dart` — UseCase LaunchCheckoutParams, LaunchCheckoutUseCase
- [ ] [Status: TODO] `lib/features/subscription/domain/usecases/refresh_subscription_status.dart` — UseCase RefreshSubscriptionStatusUseCase
- [ ] [Status: TODO] `lib/features/subscription/domain/usecases/start_plus_checkout.dart` — UseCase StartPlusCheckoutUseCase
- [ ] [Status: TODO] `lib/features/subscription/domain/usecases/subscription_use_cases.dart` — UseCase subscription_use_cases.dart
- [ ] [Status: TODO] `lib/features/subscription/domain/usecases/watch_plan_changes.dart` — UseCase WatchPlanChangesUseCase
- [ ] [Status: TODO] `lib/features/subscription/presentation/bloc/subscription_bloc.dart` — State SubscriptionBloc
- [ ] [Status: TODO] `lib/features/subscription/presentation/bloc/subscription_event.dart` — State SubscriptionWatchStarted, PlusCheckoutRequested, SubscriptionPlanUpdated
- [ ] [Status: TODO] `lib/features/subscription/presentation/bloc/subscription_state.dart` — State SubscriptionState
- [ ] [Status: TODO] `lib/features/subscription/subscription.dart` — Dart subscription.dart

### Phase 8 (optional)
#### calls
- [ ] [Status: TODO] `lib/features/calls/calls.dart` — Dart calls.dart
- [ ] [Status: TODO] `lib/features/calls/data/models/call.dart` — Model Call, CallType, CallStatus
- [ ] [Status: TODO] `lib/features/calls/data/repositories/call_repository.dart` — Repository CallSession, CallEngineEventType, CallEngineEvent
- [ ] [Status: TODO] `lib/features/calls/data/repositories/impl/firebase_call_repository.dart` — Repository FirebaseCallRepository
- [ ] [Status: TODO] `lib/features/calls/data/repositories/impl/http_call_repository.dart` — Repository HttpCallRepository
- [ ] [Status: TODO] `lib/features/calls/data/repositories/impl/stub_call_repository.dart` — Repository StubCallRepository
- [ ] [Status: TODO] `lib/features/calls/data/services/call_service.dart` — Service CallService
- [ ] [Status: TODO] `lib/features/calls/domain/usecases/call_use_cases.dart` — UseCase call_use_cases.dart
- [ ] [Status: TODO] `lib/features/calls/domain/usecases/end_call.dart` — UseCase EndCallUseCase
- [ ] [Status: TODO] `lib/features/calls/domain/usecases/start_call.dart` — UseCase StartCallParams, StartCallUseCase
- [ ] [Status: TODO] `lib/features/calls/domain/usecases/watch_call_events.dart` — UseCase WatchCallEventsUseCase
- [ ] [Status: TODO] `lib/features/calls/presentation/bloc/call_bloc.dart` — State CallBloc
- [ ] [Status: TODO] `lib/features/calls/presentation/bloc/call_event.dart` — State CallStarted, CallEnded, CallEngineUpdated
- [ ] [Status: TODO] `lib/features/calls/presentation/bloc/call_state.dart` — State CallStatus, CallState
- [ ] [Status: TODO] `lib/features/calls/presentation/screens/call_screen.dart` — Screen CallScreenArgs, CallScreen, _CallScreenState
- [ ] [Status: TODO] `lib/features/calls/presentation/screens/video_call_screen.dart` — Screen VideoCallArgs, VideoCallScreen

### Phase 9
#### l10n
- [ ] [Status: TODO] `lib/l10n/app_ar.arb` — Localization app_ar.arb
- [ ] [Status: TODO] `lib/l10n/app_bn.arb` — Localization app_bn.arb
- [ ] [Status: TODO] `lib/l10n/app_de.arb` — Localization app_de.arb
- [ ] [Status: TODO] `lib/l10n/app_en.arb` — Localization app_en.arb
- [ ] [Status: TODO] `lib/l10n/app_es.arb` — Localization app_es.arb
- [ ] [Status: TODO] `lib/l10n/app_fr.arb` — Localization app_fr.arb
- [ ] [Status: TODO] `lib/l10n/app_hi.arb` — Localization app_hi.arb
- [ ] [Status: TODO] `lib/l10n/app_id.arb` — Localization app_id.arb
- [ ] [Status: TODO] `lib/l10n/app_ja.arb` — Localization app_ja.arb
- [ ] [Status: TODO] `lib/l10n/app_ko.arb` — Localization app_ko.arb
- [ ] [Status: TODO] `lib/l10n/app_ne.arb` — Localization app_ne.arb
- [ ] [Status: TODO] `lib/l10n/app_pt.arb` — Localization app_pt.arb
- [ ] [Status: TODO] `lib/l10n/app_ru.arb` — Localization app_ru.arb
- [ ] [Status: TODO] `lib/l10n/app_ta.arb` — Localization app_ta.arb
- [ ] [Status: TODO] `lib/l10n/app_te.arb` — Localization app_te.arb
- [ ] [Status: TODO] `lib/l10n/app_tr.arb` — Localization app_tr.arb
- [ ] [Status: TODO] `lib/l10n/app_ur.arb` — Localization app_ur.arb
- [ ] [Status: TODO] `lib/l10n/app_vi.arb` — Localization app_vi.arb
- [ ] [Status: TODO] `lib/l10n/app_yo.arb` — Localization app_yo.arb
- [ ] [Status: TODO] `lib/l10n/app_yue.arb` — Localization app_yue.arb
- [ ] [Status: TODO] `lib/l10n/app_zh.arb` — Localization app_zh.arb
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations.dart` — Dart app_localizations.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_ar.dart` — Dart app_localizations_ar.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_bn.dart` — Dart app_localizations_bn.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_de.dart` — Dart app_localizations_de.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_en.dart` — Dart app_localizations_en.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_es.dart` — Dart app_localizations_es.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_fr.dart` — Dart app_localizations_fr.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_hi.dart` — Dart app_localizations_hi.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_id.dart` — Dart app_localizations_id.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_ja.dart` — Dart app_localizations_ja.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_ko.dart` — Dart app_localizations_ko.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_ne.dart` — Dart app_localizations_ne.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_pt.dart` — Dart app_localizations_pt.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_ru.dart` — Dart app_localizations_ru.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_ta.dart` — Dart app_localizations_ta.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_te.dart` — Dart app_localizations_te.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_tr.dart` — Dart app_localizations_tr.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_ur.dart` — Dart app_localizations_ur.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_vi.dart` — Dart app_localizations_vi.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_yo.dart` — Dart app_localizations_yo.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_yue.dart` — Dart app_localizations_yue.dart
- [ ] [Status: TODO] `lib/l10n/generated/app_localizations_zh.dart` — Dart app_localizations_zh.dart

### Backend
#### cloud_functions
- [ ] [Status: TODO] `functions/agora-test.js` — Node script agora-test.js
- [ ] [Status: TODO] `functions/src/dataconnect-admin-generated/esm/index.esm.js` — Node script index.esm.js
- [ ] [Status: TODO] `functions/src/dataconnect-admin-generated/index.cjs.js` — Node script index.cjs.js
- [ ] [Status: TODO] `functions/src/dataconnect-admin-generated/index.d.ts` — Cloud Function index.d.ts
- [ ] [Status: TODO] `functions/src/index.ts` — Cloud Function index.ts

#### dataconnect
- [ ] [Status: TODO] `dataconnect/dataconnect.yaml` — Config dataconnect.yaml
- [ ] [Status: TODO] `dataconnect/example/connector.yaml` — Config connector.yaml
- [ ] [Status: TODO] `dataconnect/example/queries.gql` — GraphQL queries.gql
- [ ] [Status: TODO] `dataconnect/schema/schema.gql` — GraphQL schema.gql
- [ ] [Status: TODO] `dataconnect/seed_data.gql` — GraphQL seed_data.gql

#### recommendation_service
- [ ] [Status: TODO] `crushhour-recommendation-service/index.js` — Node script index.js
- [ ] [Status: TODO] `crushhour-recommendation-service/package-lock.json` — Config package-lock.json
- [ ] [Status: TODO] `crushhour-recommendation-service/package.json` — Config package.json
- [ ] [Status: TODO] `crushhour-recommendation-service/src/dataconnect-generated/.guides/config.json` — Config config.json
- [ ] [Status: TODO] `crushhour-recommendation-service/src/dataconnect-generated/esm/index.esm.js` — Node script index.esm.js
- [ ] [Status: TODO] `crushhour-recommendation-service/src/dataconnect-generated/esm/package.json` — Config package.json
- [ ] [Status: TODO] `crushhour-recommendation-service/src/dataconnect-generated/index.cjs.js` — Node script index.cjs.js
- [ ] [Status: TODO] `crushhour-recommendation-service/src/dataconnect-generated/index.d.ts` — Cloud Function index.d.ts
- [ ] [Status: TODO] `crushhour-recommendation-service/src/dataconnect-generated/package.json` — Config package.json

### Testing
#### integration_tests
- [ ] [Status: TODO] `integration_test/app_test.dart` — Dart app_test.dart
- [ ] [Status: TODO] `integration_test/auth_flow_test.dart` — Dart auth_flow_test.dart
- [ ] [Status: TODO] `integration_test/chat_flow_test.dart` — Dart chat_flow_test.dart
- [ ] [Status: TODO] `integration_test/discovery_flow_test.dart` — Dart discovery_flow_test.dart
- [ ] [Status: TODO] `integration_test/test_app.dart` — Dart test_app.dart

#### test_driver
- [ ] [Status: TODO] `test_driver/integration_test.dart` — Dart integration_test.dart

#### tests
- [ ] [Status: TODO] `test/async_state_scaffold_test.dart` — Dart async_state_scaffold_test.dart
- [ ] [Status: TODO] `test/auth_bloc_test.dart` — Dart auth_bloc_test.dart
- [ ] [Status: TODO] `test/chat_bloc_media_limit_test.dart` — Dart chat_bloc_media_limit_test.dart
- [ ] [Status: TODO] `test/compatibility_quiz_service_test.dart` — Dart compatibility_quiz_service_test.dart
- [ ] [Status: TODO] `test/daily_likes_service_test.dart` — Dart daily_likes_service_test.dart
- [ ] [Status: TODO] `test/date_idea_service_test.dart` — Dart date_idea_service_test.dart
- [ ] [Status: TODO] `test/deck_gating_test.dart` — Dart deck_gating_test.dart
- [ ] [Status: TODO] `test/discovery_bloc_test.dart` — Dart discovery_bloc_test.dart
- [ ] [Status: TODO] `test/functions_integration_test.dart` — Dart functions_integration_test.dart
- [ ] [Status: TODO] `test/incognito_service_test.dart` — Dart incognito_service_test.dart
- [ ] [Status: TODO] `test/locale_cubit_test.dart` — Dart locale_cubit_test.dart
- [ ] [Status: TODO] `test/matches_bloc_test.dart` — Dart matches_bloc_test.dart
- [ ] [Status: TODO] `test/mock/firebase_mock.dart` — Dart firebase_mock.dart
- [ ] [Status: TODO] `test/profile_completeness_meter_test.dart` — Dart profile_completeness_meter_test.dart
- [ ] [Status: TODO] `test/profile_completeness_test.dart` — Dart profile_completeness_test.dart
- [ ] [Status: TODO] `test/safety_cubit_test.dart` — Dart safety_cubit_test.dart
- [ ] [Status: TODO] `test/storage_settings_cubit_test.dart` — Dart storage_settings_cubit_test.dart
- [ ] [Status: TODO] `test/swipe_card_test.dart` — Dart swipe_card_test.dart
- [ ] [Status: TODO] `test/weekly_picks_service_test.dart` — Dart weekly_picks_service_test.dart
- [ ] [Status: TODO] `test/widget_test.dart` — Dart widget_test.dart
- [ ] [Status: TODO] `test/widgets/design_system_test.dart` — Dart design_system_test.dart

### Assets
#### assets
- [ ] [Status: TODO] `assets/animations/empty_deck.json` — Config empty_deck.json
- [ ] [Status: TODO] `assets/animations/error.json` — Config error.json
- [ ] [Status: TODO] `assets/animations/match_celebration.json` — Config match_celebration.json
- [ ] [Status: TODO] `assets/animations/no_matches.json` — Config no_matches.json
- [ ] [Status: TODO] `assets/animations/no_messages.json` — Config no_messages.json
- [ ] [Status: TODO] `assets/animations/offline.json` — Config offline.json

### Flutter Web (legacy)
#### flutter_web_shell
- [ ] [Status: TODO] `public/.well-known/assetlinks.json` — Config assetlinks.json
- [ ] [Status: TODO] `public/finishSignIn.html` — HTML finishSignIn.html
- [ ] [Status: TODO] `public/index.html` — HTML index.html
- [ ] [Status: TODO] `web/favicon.png` — Asset favicon.png
- [ ] [Status: TODO] `web/icons/Icon-192.png` — Asset Icon-192.png
- [ ] [Status: TODO] `web/icons/Icon-512.png` — Asset Icon-512.png
- [ ] [Status: TODO] `web/icons/Icon-maskable-192.png` — Asset Icon-maskable-192.png
- [ ] [Status: TODO] `web/icons/Icon-maskable-512.png` — Asset Icon-maskable-512.png
- [ ] [Status: TODO] `web/index.html` — HTML index.html
- [ ] [Status: TODO] `web/manifest.json` — Config manifest.json

### Docs
#### docs
- [ ] [Status: TODO] `AUDIT_REPORT.md` — Doc AUDIT_REPORT.md
- [ ] [Status: TODO] `README.md` — Doc README.md
- [ ] [Status: TODO] `docs/AUDIT_WEBAPP.md` — Doc AUDIT_WEBAPP.md
- [ ] [Status: TODO] `docs/Developer_agent_chat.md` — Doc Developer_agent_chat.md
- [ ] [Status: TODO] `docs/TODO_WEBAPP.md` — Doc TODO_WEBAPP.md
- [ ] [Status: TODO] `docs/auth_system.md` — Doc auth_system.md
- [ ] [Status: TODO] `docs/project_dfd.md` — Doc project_dfd.md
- [ ] [Status: TODO] `docs/project_er_diagram.md` — Doc project_er_diagram.md
- [ ] [Status: TODO] `docs/project_flowchart.md` — Doc project_flowchart.md
- [ ] [Status: TODO] `docs/project_understanding.md` — Doc project_understanding.md

### Config
#### config
- [ ] [Status: TODO] `analysis_options.yaml` — Config analysis_options.yaml
- [ ] [Status: TODO] `database.rules.json` — Config database.rules.json
- [ ] [Status: TODO] `firebase.json` — Config firebase.json
- [ ] [Status: TODO] `firestore.indexes.json` — Config firestore.indexes.json
- [ ] [Status: TODO] `firestore.rules` — Security Rules firestore.rules
- [ ] [Status: TODO] `functions/firestore.rules` — Security Rules firestore.rules
- [ ] [Status: TODO] `functions/package-lock.json` — Config package-lock.json
- [ ] [Status: TODO] `functions/package.json` — Config package.json
- [ ] [Status: TODO] `functions/src/dataconnect-admin-generated/esm/package.json` — Config package.json
- [ ] [Status: TODO] `functions/src/dataconnect-admin-generated/package.json` — Config package.json
- [ ] [Status: TODO] `functions/tsconfig.json` — Config tsconfig.json
- [ ] [Status: TODO] `l10n.yaml` — Config l10n.yaml
- [ ] [Status: TODO] `pubspec.lock` — Config pubspec.lock
- [ ] [Status: TODO] `pubspec.yaml` — Config pubspec.yaml
- [ ] [Status: TODO] `storage.rules` — Security Rules storage.rules

