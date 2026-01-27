# CRUSH Web Platform - Comprehensive Audit & Migration Plan

**Document Version:** 1.0.0
**Created:** 2026-01-26
**Last Updated:** 2026-01-26
**Author:** AI Engineering Team

---

## Executive Summary

This document provides a complete audit and migration plan for building a **production-grade web platform** for the CRUSH dating app. The plan covers:

1. **Full Web Application** - Feature-complete logged-in experience
2. **Marketing Website** - SEO-optimized public pages for user acquisition
3. **Admin Dashboard** - Moderation and analytics (proposed)

**Source Codebase Analysis:**
- **~197,600 lines of code** across 455 Dart files
- **51 screens**, **60+ reusable widgets**
- **8 BLoCs + 13 Cubits** for state management
- **34+ routes** with auth guards
- **Multi-backend**: Firebase (primary) + HTTP API + Stub (testing)

---

## Table of Contents

1. [Tech Stack Decision](#1-tech-stack-decision)
2. [Feature Inventory](#2-feature-inventory)
3. [Screen-to-Screen Mapping](#3-screen-to-screen-mapping)
4. [Architecture Design](#4-architecture-design)
5. [Implementation Phases](#5-implementation-phases)
6. [API & Backend Requirements](#6-api--backend-requirements)
7. [Design System Migration](#7-design-system-migration)
8. [Security Considerations](#8-security-considerations)
9. [Performance Requirements](#9-performance-requirements)
10. [SEO & Marketing Website](#10-seo--marketing-website)
11. [Testing Strategy](#11-testing-strategy)
12. [Deployment Strategy](#12-deployment-strategy)
13. [Risk Assessment](#13-risk-assessment)
14. [Implementation Checklist](#14-implementation-checklist)

---

## 1. Tech Stack Decision

### Options Evaluated

| Criteria | Flutter Web | Next.js (React) |
|----------|-------------|-----------------|
| **Code Reuse** | 95% (same codebase) | 0% (rebuild) |
| **Bundle Size** | ~2-4MB | ~200-500KB |
| **SEO** | Poor (SPA) | Excellent (SSR/SSG) |
| **Performance** | Medium | Excellent |
| **Web-Native UX** | Adapted | Native |
| **Marketing Site** | Separate build needed | Integrated |
| **Development Speed** | Faster initially | Faster long-term |
| **Maintenance** | Single codebase | Separate codebases |
| **Core Web Vitals** | Challenging | Easy to optimize |

### Recommendation: **Next.js (React)**

**Primary Reasons:**

1. **SEO is Critical** - Marketing website needs server-side rendering for Google indexing
2. **Bundle Size** - Flutter Web bundles are 4-10x larger than optimized React
3. **Web-Native Experience** - Better accessibility, keyboard navigation, browser integration
4. **Performance** - Easier to achieve 90+ Lighthouse scores
5. **Marketing Integration** - Single deployment for app + marketing site
6. **Developer Pool** - Easier to hire React developers than Flutter web specialists
7. **Long-term Maintenance** - Web-specific optimizations are simpler

**Trade-offs Accepted:**
- Complete rebuild (~4-6 weeks for core features)
- Different state management patterns
- Separate codebase from mobile

### Proposed Web Stack

```
Frontend:
├── Framework:      Next.js 14+ (App Router)
├── Language:       TypeScript 5.x
├── State:          Zustand + React Query (TanStack)
├── Forms:          React Hook Form + Zod
├── Styling:        Tailwind CSS + Radix UI
├── Animations:     Framer Motion
├── Real-time:      Socket.io / Firebase SDK
├── Testing:        Vitest + Playwright

Backend (Existing):
├── Firebase Auth   (existing)
├── Cloud Firestore (existing)
├── Cloud Functions (existing)
├── Firebase Storage (existing)
├── Stripe          (existing)

Hosting:
├── Frontend:       Vercel (Next.js optimized)
├── CDN:            Vercel Edge Network
├── Analytics:      Vercel Analytics + Firebase Analytics
```

---

## 2. Feature Inventory

### 2.1 Authentication Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Phone OTP Login | ✅ Complete | P0 | Firebase Auth |
| Email/Password Login | ✅ Complete | P0 | Firebase Auth |
| Email Link (Passwordless) | ✅ Complete | P1 | Firebase Auth |
| Session Management | ✅ Complete | P0 | 30-min timeout |
| Multi-Device Verification | ✅ Complete | P1 | New device flow |
| Terms Acceptance | ✅ Complete | P0 | Legal gate |
| Account Deactivation | ✅ Complete | P1 | Soft delete |
| Account Deletion | ✅ Complete | P1 | GDPR compliance |
| 2FA (Email/Phone) | ✅ Complete | P1 | Protection screens |

### 2.2 Profile Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Basic Info Setup | ✅ Complete | P0 | Name, DOB, Gender |
| Photo Upload (6 max) | ✅ Complete | P0 | Firebase Storage |
| Video Upload (1 max) | ✅ Complete | P1 | Firebase Storage |
| Bio & Interests | ✅ Complete | P0 | Text + tags |
| Profile Prompts | ✅ Complete | P0 | Icebreakers |
| Location (Manual/GPS) | ✅ Complete | P0 | Browser geolocation |
| Height Picker | ✅ Complete | P1 | cm/ft conversion |
| Lifestyle Fields | ✅ Complete | P1 | Drinking, smoking, etc. |
| Privacy Controls | ✅ Complete | P1 | Name visibility |
| Profile Completion Meter | ✅ Complete | P0 | Progress indicator |
| ID Verification | ✅ Complete | P2 | Document upload |

### 2.3 Discovery Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Swipe Deck | ✅ Complete | P0 | Core feature |
| Like (Swipe Right) | ✅ Complete | P0 | Match creation |
| Pass (Swipe Left) | ✅ Complete | P0 | Skip profile |
| Super Like | ✅ Complete | P1 | Plus feature |
| Rewind/Undo | ✅ Complete | P1 | Plus feature |
| Profile Boost | ✅ Complete | P2 | Plus feature |
| Discovery Filters | ✅ Complete | P0 | Age, distance, gender |
| Weekly Picks | ✅ Complete | P1 | Curated recommendations |
| Likes You (Blurred) | ✅ Complete | P1 | Plus feature |
| Match Celebration | ✅ Complete | P0 | Animation modal |
| Keyboard Navigation | N/A | P0 | Web-specific |

### 2.4 Chat Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Match List | ✅ Complete | P0 | Conversation list |
| Real-time Messaging | ✅ Complete | P0 | Firestore streams |
| Read Receipts | ✅ Complete | P0 | Message status |
| Typing Indicators | ✅ Complete | P0 | Real-time |
| Message Reactions | ✅ Complete | P1 | Emoji reactions |
| Photo Sharing | ✅ Complete | P1 | In-chat media |
| Voice Notes | ✅ Complete | P2 | Audio recording |
| Message Editing | ✅ Complete | P1 | Plus feature |
| Message Unsend | ✅ Complete | P1 | Plus feature |
| Message Search | ✅ Complete | P2 | Search within chat |
| Message Requests | ✅ Complete | P1 | Pre-match messages |
| Pagination (50/page) | ✅ Complete | P0 | Infinite scroll |
| Date Separators | ✅ Complete | P0 | Visual grouping |
| Ice Breaker Suggestions | ✅ Complete | P1 | Conversation starters |

### 2.5 Calls Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Audio Calls | ✅ Complete | P2 | Agora SDK |
| Video Calls | ✅ Complete | P2 | Agora SDK |
| Call Controls | ✅ Complete | P2 | Mute, camera, speaker |

### 2.6 Subscription Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Plan Display | ✅ Complete | P0 | Free vs Plus |
| Stripe Checkout | ✅ Complete | P0 | Web checkout |
| Subscription Status | ✅ Complete | P0 | Current plan |
| Cancel Subscription | ✅ Complete | P1 | Self-service |
| Restore Purchases | ✅ Complete | P1 | Sync with Stripe |
| Feature Gating | ✅ Complete | P0 | Plus-only features |

### 2.7 Settings Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Theme (Light/Dark) | ✅ Complete | P0 | System preference |
| Notifications | ✅ Complete | P1 | Web Push API |
| Privacy Settings | ✅ Complete | P1 | Name visibility |
| Language Selection | ✅ Complete | P2 | Multi-language |
| Discovery Filters | ✅ Complete | P0 | Age, distance, gender |
| Data Export (GDPR) | ✅ Complete | P1 | JSON download |
| Cache Management | ✅ Complete | P2 | Clear cache |
| Account Security | ✅ Complete | P1 | Password, 2FA |
| Chat Settings | ✅ Complete | P1 | Message retention |

### 2.8 Safety Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Block User | ✅ Complete | P0 | Prevent contact |
| Report User | ✅ Complete | P0 | Safety team review |
| Unblock User | ✅ Complete | P1 | Settings management |
| Blocked Users List | ✅ Complete | P1 | View/manage blocks |
| Date Safety Plan | ✅ Complete | P2 | Emergency contacts |

### 2.9 Social Features

| Feature | Flutter Status | Web Priority | Notes |
|---------|----------------|--------------|-------|
| Date Ideas | ✅ Complete | P2 | Activity suggestions |
| Compatibility Quiz | ✅ Complete | P2 | Match scoring |
| Profile Insights | ✅ Complete | P2 | View analytics |

---

## 3. Screen-to-Screen Mapping

### 3.1 Authentication Screens (17 → 12)

| Flutter Screen | Web Route | Notes |
|----------------|-----------|-------|
| `splash_screen.dart` | `/` (handled by middleware) | Server-side auth check |
| `auth_gateway_screen.dart` | `/auth` | Login/signup choice |
| `login_screen.dart` | `/auth/login` | Combined login |
| `sign_up_screen.dart` | `/auth/signup` | Registration |
| `phone_auth_screen.dart` | `/auth/phone` | Phone OTP |
| `email_auth_screen.dart` | `/auth/email` | Email login |
| `otp_screen.dart` | `/auth/verify` | OTP input |
| `forgot_password_screen.dart` | `/auth/forgot-password` | Password reset |
| `email_verification_screen.dart` | `/auth/verify-email` | Email confirm |
| `new_device_screen.dart` | `/auth/verify-device` | Device verification |
| `basic_info_screen.dart` | `/onboarding/basic-info` | Onboarding step 1 |
| `terms_conditions_screen.dart` | `/onboarding/terms` | Legal acceptance |
| `logout_screen.dart` | Modal/Dialog | Not a full page |
| `email_protection_screen.dart` | `/settings/security/email` | Merged into settings |
| `phone_protection_screen.dart` | `/settings/security/phone` | Merged into settings |
| `change_email_screen.dart` | `/settings/account/email` | Merged into settings |
| `id_verification_screen.dart` | `/onboarding/verify-id` | Optional step |

### 3.2 Profile Screens (5 → 5)

| Flutter Screen | Web Route | Notes |
|----------------|-----------|-------|
| `profile_setup_screen.dart` | `/onboarding/profile` | Onboarding step 2 |
| `profile_view_screen.dart` | `/profile` | Own profile |
| `profile_edit_screen.dart` | `/profile/edit` | Edit profile |
| `profile_media_screen.dart` | `/profile/media` | Photo/video management |
| `other_user_profile_screen.dart` | `/u/[userId]` | View other profiles |

### 3.3 Discovery Screens (4 → 4)

| Flutter Screen | Web Route | Notes |
|----------------|-----------|-------|
| `deck_screen.dart` | `/discover` | Main swipe interface |
| `likes_you_screen.dart` | `/discover/likes` | Plus feature |
| `weekly_picks_screen.dart` | `/discover/picks` | Curated picks |
| `story_viewer_screen.dart` | Modal | Story overlay |

### 3.4 Chat Screens (4 → 3)

| Flutter Screen | Web Route | Notes |
|----------------|-----------|-------|
| `chat_list_screen.dart` | `/messages` | Conversation list |
| `matches_screen.dart` | `/matches` | Match grid |
| `chat_screen.dart` | `/messages/[matchId]` | Conversation |
| `message_requests_screen.dart` | `/messages/requests` | Pending requests |

### 3.5 Settings Screens (9 → 1 with sub-routes)

| Flutter Screen | Web Route | Notes |
|----------------|-----------|-------|
| `settings_screen.dart` | `/settings` | Settings hub |
| `privacy_settings_screen.dart` | `/settings/privacy` | Tab/section |
| `notifications_settings_screen.dart` | `/settings/notifications` | Tab/section |
| `language_region_settings_screen.dart` | `/settings/language` | Tab/section |
| `discovery_filters_settings_screen.dart` | `/settings/discovery` | Tab/section |
| `data_storage_settings_screen.dart` | `/settings/data` | Tab/section |
| `account_security_settings_screen.dart` | `/settings/security` | Tab/section |
| `account_actions_settings_screen.dart` | `/settings/account` | Tab/section |
| `chat_settings_screen.dart` | `/settings/chat` | Tab/section |

### 3.6 Other Screens

| Flutter Screen | Web Route | Notes |
|----------------|-----------|-------|
| `home_screen.dart` | Layout wrapper | Tab navigation |
| `call_screen.dart` | Modal | Audio call overlay |
| `video_call_screen.dart` | `/call/[matchId]` | Full-screen video |
| `safety_screen.dart` | `/safety` | Public page |
| `community_guidelines_screen.dart` | `/guidelines` | Public page |
| `privacy_policy_screen.dart` | `/privacy` | Public page |
| `terms_of_service_screen.dart` | `/terms` | Public page |
| `date_ideas_screen.dart` | `/date-ideas` | Social feature |
| `compatibility_quiz_screen.dart` | Modal | Quiz overlay |
| `profile_insights_screen.dart` | `/profile/insights` | Analytics |

### 3.7 Web Routes Summary

```
/ (Marketing Landing Page)
├── /features
├── /pricing
├── /about
├── /contact
├── /faq
├── /privacy (Privacy Policy)
├── /terms (Terms of Service)
├── /guidelines (Community Guidelines)
├── /safety (Safety Tips)
├── /download (App Store Links)
│
/auth
├── /auth/login
├── /auth/signup
├── /auth/phone
├── /auth/email
├── /auth/verify
├── /auth/forgot-password
├── /auth/verify-email
├── /auth/verify-device
│
/onboarding
├── /onboarding/terms
├── /onboarding/basic-info
├── /onboarding/profile
├── /onboarding/verify-id (optional)
│
/app (Authenticated - Layout)
├── /discover (Swipe Deck)
│   ├── /discover/likes (Plus)
│   └── /discover/picks
├── /matches
├── /messages
│   ├── /messages/requests
│   └── /messages/[matchId]
├── /profile
│   ├── /profile/edit
│   ├── /profile/media
│   └── /profile/insights
├── /settings
│   ├── /settings/privacy
│   ├── /settings/notifications
│   ├── /settings/discovery
│   ├── /settings/security
│   ├── /settings/account
│   ├── /settings/data
│   ├── /settings/language
│   └── /settings/chat
├── /u/[userId] (View Profile)
├── /date-ideas
└── /call/[matchId] (Video Call)
```

---

## 4. Architecture Design

### 4.1 Project Structure

```
crush-web/
├── apps/
│   ├── web/                      # Next.js Web App
│   │   ├── app/                  # App Router
│   │   │   ├── (marketing)/      # Public pages (landing, etc.)
│   │   │   ├── (auth)/           # Auth pages
│   │   │   ├── (onboarding)/     # Onboarding flow
│   │   │   ├── (app)/            # Authenticated app
│   │   │   ├── api/              # API routes (if needed)
│   │   │   ├── layout.tsx        # Root layout
│   │   │   └── page.tsx          # Landing page
│   │   ├── components/           # App-specific components
│   │   ├── hooks/                # Custom React hooks
│   │   ├── lib/                  # App utilities
│   │   └── styles/               # Global styles
│   │
│   └── admin/                    # Admin Dashboard (future)
│
├── packages/
│   ├── ui/                       # Shared UI library
│   │   ├── components/           # Reusable components
│   │   │   ├── buttons/
│   │   │   ├── cards/
│   │   │   ├── forms/
│   │   │   ├── modals/
│   │   │   ├── navigation/
│   │   │   └── feedback/
│   │   ├── primitives/           # Base components (Radix UI)
│   │   └── styles/               # Design tokens
│   │
│   ├── core/                     # Business logic
│   │   ├── auth/                 # Auth utilities
│   │   ├── api/                  # API client
│   │   ├── firebase/             # Firebase SDK wrappers
│   │   ├── store/                # Zustand stores
│   │   ├── hooks/                # Shared hooks
│   │   └── types/                # TypeScript types
│   │
│   ├── features/                 # Feature modules
│   │   ├── auth/
│   │   ├── profile/
│   │   ├── discovery/
│   │   ├── chat/
│   │   ├── calls/
│   │   ├── subscription/
│   │   └── settings/
│   │
│   └── config/                   # Shared configuration
│       ├── eslint-config/
│       ├── tailwind-config/
│       └── typescript-config/
│
├── .github/
│   └── workflows/                # CI/CD
│
├── docs/                         # Documentation
│
├── turbo.json                    # Turborepo config
├── pnpm-workspace.yaml           # Workspace config
└── package.json                  # Root package
```

### 4.2 State Management Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    React Components                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Zustand    │  │ React Query  │  │   Context    │  │
│  │   Stores     │  │   (Server)   │  │  (UI State)  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                  │          │
├─────────┴─────────────────┴──────────────────┴──────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │               Service Layer                       │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐ │   │
│  │  │AuthSvc  │ │ProfileSvc│ │ ChatSvc │ │DiscSvc│ │   │
│  │  └────┬────┘ └────┬────┘ └────┬────┘ └───┬────┘ │   │
│  └───────┼──────────┼──────────┼───────────┼───────┘   │
│          │          │          │           │            │
├──────────┴──────────┴──────────┴───────────┴────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Firebase SDK / API Client            │   │
│  │  ┌────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐ │   │
│  │  │  Auth  │ │ Firestore│ │ Storage │ │Functions│ │   │
│  │  └────────┘ └──────────┘ └─────────┘ └────────┘ │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 4.3 Zustand Store Structure

```typescript
// stores/auth.store.ts
interface AuthStore {
  user: User | null;
  status: 'idle' | 'loading' | 'authenticated' | 'unauthenticated';
  actions: {
    signIn: (method: AuthMethod, credentials: Credentials) => Promise<void>;
    signOut: () => Promise<void>;
    refreshSession: () => Promise<void>;
  };
}

// stores/profile.store.ts
interface ProfileStore {
  profile: Profile | null;
  completeness: ProfileCompleteness;
  actions: {
    updateProfile: (updates: Partial<Profile>) => Promise<void>;
    uploadPhoto: (file: File) => Promise<string>;
    removePhoto: (index: number) => Promise<void>;
  };
}

// stores/discovery.store.ts
interface DiscoveryStore {
  deck: Profile[];
  currentIndex: number;
  filters: DiscoveryFilters;
  actions: {
    loadDeck: () => Promise<void>;
    swipe: (direction: 'left' | 'right', profileId: string) => Promise<Match | null>;
    superLike: (profileId: string) => Promise<Match | null>;
    rewind: () => Promise<void>;
  };
}

// stores/chat.store.ts
interface ChatStore {
  conversations: Conversation[];
  activeConversation: Conversation | null;
  messages: Record<string, Message[]>;
  typing: Record<string, string[]>;
  actions: {
    loadConversations: () => Promise<void>;
    loadMessages: (matchId: string, cursor?: string) => Promise<void>;
    sendMessage: (matchId: string, content: MessageContent) => Promise<void>;
    markRead: (matchId: string) => Promise<void>;
    setTyping: (matchId: string, isTyping: boolean) => void;
  };
}
```

### 4.4 Component Architecture

```
Component Hierarchy:

<RootLayout>                        # Theme, fonts, providers
  <AuthProvider>                    # Firebase Auth context
    <QueryProvider>                 # React Query
      <ThemeProvider>               # Light/dark mode
        {children}                  # Page content
      </ThemeProvider>
    </QueryProvider>
  </AuthProvider>
</RootLayout>

<AppLayout>                         # Authenticated layout
  <Sidebar>                         # Desktop navigation
    <UserAvatar />
    <NavLinks />
  </Sidebar>
  <MobileNav>                       # Mobile bottom nav
    <NavTabs />
  </MobileNav>
  <MainContent>
    {children}                      # Page content
  </MainContent>
</AppLayout>
```

---

## 5. Implementation Phases

### Phase 0: Foundation (Week 1)

**Goal:** Project setup, infrastructure, design system foundation

**Tasks:**
- [ ] Initialize Turborepo monorepo
- [ ] Configure Next.js 14 with App Router
- [ ] Set up TypeScript, ESLint, Prettier
- [ ] Configure Tailwind CSS with design tokens
- [ ] Set up Firebase SDK (Auth, Firestore, Storage)
- [ ] Create base UI components (Button, Input, Card)
- [ ] Configure Zustand stores skeleton
- [ ] Set up React Query
- [ ] Configure Vercel deployment
- [ ] Set up environment variables

**Deliverables:**
- Working Next.js app with deployment
- Design system foundation
- Firebase integration

### Phase 1: Authentication (Week 2)

**Goal:** Complete auth flows matching mobile app

**Tasks:**
- [ ] Auth gateway page (login/signup choice)
- [ ] Phone OTP authentication
- [ ] Email/password authentication
- [ ] Session management (30-min timeout)
- [ ] Protected route middleware
- [ ] Auth state persistence
- [ ] Logout functionality
- [ ] Forgot password flow
- [ ] New device verification

**Deliverables:**
- Complete auth system
- Route protection
- Session handling

### Phase 2: Onboarding (Week 2-3)

**Goal:** User onboarding flow

**Tasks:**
- [ ] Terms acceptance screen
- [ ] Basic info form (name, DOB, gender, username)
- [ ] Profile setup (photos, bio, interests, location)
- [ ] Profile completeness meter
- [ ] Photo upload with cropping
- [ ] Location selection (manual + browser GPS)
- [ ] Prompt/icebreaker selection
- [ ] ID verification (optional)
- [ ] Onboarding progress indicator

**Deliverables:**
- Complete onboarding flow
- Profile creation

### Phase 3: Discovery (Week 3-4)

**Goal:** Swipe deck and matching

**Tasks:**
- [ ] Swipe deck interface (keyboard + mouse + touch)
- [ ] Profile card component
- [ ] Like/Pass actions
- [ ] Match celebration modal
- [ ] Discovery filters UI
- [ ] Super Like (Plus)
- [ ] Rewind/Undo (Plus)
- [ ] Likes You screen (Plus)
- [ ] Weekly Picks
- [ ] Empty deck state

**Deliverables:**
- Full discovery experience
- Matching system

### Phase 4: Messaging (Week 4-5)

**Goal:** Real-time chat system

**Tasks:**
- [ ] Conversation list
- [ ] Chat interface
- [ ] Real-time message subscription
- [ ] Send text messages
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Message reactions
- [ ] Photo sharing
- [ ] Message pagination
- [ ] Message editing (Plus)
- [ ] Message unsend (Plus)
- [ ] Message requests
- [ ] Ice breaker suggestions

**Deliverables:**
- Complete chat system
- Real-time updates

### Phase 5: Profile & Settings (Week 5-6)

**Goal:** Profile management and settings

**Tasks:**
- [ ] Profile view page
- [ ] Profile edit page
- [ ] Other user profile view
- [ ] Settings hub
- [ ] Privacy settings
- [ ] Notification settings
- [ ] Discovery filters
- [ ] Account security
- [ ] Data export (GDPR)
- [ ] Account deletion

**Deliverables:**
- Profile management
- All settings

### Phase 6: Safety & Social (Week 6)

**Goal:** Safety features and social engagement

**Tasks:**
- [ ] Block user
- [ ] Report user
- [ ] Blocked users management
- [ ] Date ideas page
- [ ] Compatibility quiz
- [ ] Profile insights

**Deliverables:**
- Safety features
- Social features

### Phase 7: Subscription (Week 6-7)

**Goal:** Stripe billing integration

**Tasks:**
- [ ] Plans display
- [ ] Stripe Checkout integration
- [ ] Subscription status
- [ ] Feature gating
- [ ] Cancel subscription
- [ ] Upgrade prompts

**Deliverables:**
- Complete billing system

### Phase 8: Calls (Week 7) - Optional

**Goal:** Voice/video calling

**Tasks:**
- [ ] Audio call UI
- [ ] Video call UI
- [ ] Agora SDK integration
- [ ] Call controls

**Deliverables:**
- Calling feature (if prioritized)

### Phase 9: Marketing Website (Week 7-8)

**Goal:** SEO-optimized public pages

**Tasks:**
- [ ] Landing page
- [ ] Features page
- [ ] Pricing page
- [ ] About page
- [ ] Contact page
- [ ] FAQ page
- [ ] Privacy Policy
- [ ] Terms of Service
- [ ] Safety Guidelines
- [ ] App download links
- [ ] SEO optimization
- [ ] Open Graph tags
- [ ] Sitemap generation

**Deliverables:**
- Complete marketing site
- SEO implementation

### Phase 10: Polish & Testing (Week 8)

**Goal:** Production readiness

**Tasks:**
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Accessibility audit
- [ ] Mobile responsiveness
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Offline handling
- [ ] Analytics integration
- [ ] Error monitoring (Sentry)

**Deliverables:**
- Production-ready application

---

## 6. API & Backend Requirements

### 6.1 Existing Endpoints (No Changes Needed)

The Flutter app uses Firebase + Cloud Functions. Web can use the same:

**Firebase Auth:**
- Phone OTP verification
- Email/password auth
- Custom token generation

**Cloud Firestore:**
- `/users/{uid}` - User profiles
- `/profiles/{uid}` - Discovery profiles
- `/matches/{matchId}` - Match documents
- `/matches/{matchId}/messages/{messageId}` - Messages

**Cloud Functions:**
- `fetchDiscoveryCandidates` - Deck loading
- `swipeRight` - Like action
- `swipeLeft` - Pass action
- `sendMessage` - Message delivery
- `createCheckoutSession` - Stripe checkout

### 6.2 New/Modified Endpoints Needed

| Endpoint | Purpose | Priority |
|----------|---------|----------|
| `POST /api/auth/session` | Web session management | P0 |
| `POST /api/upload/signed-url` | Pre-signed upload URLs | P0 |
| `GET /api/sitemap.xml` | Dynamic sitemap | P1 |
| `POST /api/contact` | Contact form submission | P1 |

### 6.3 Real-time Subscriptions

Web will use the same Firestore real-time listeners:

```typescript
// Messages subscription
onSnapshot(
  query(collection(db, 'matches', matchId, 'messages'), orderBy('createdAt', 'desc'), limit(50)),
  (snapshot) => { /* update state */ }
);

// Typing indicators
onValue(ref(rtdb, `typing/${matchId}`), (snapshot) => { /* update state */ });

// Presence
onDisconnect(ref(rtdb, `presence/${userId}`)).set(false);
```

---

## 7. Design System Migration

### 7.1 Design Tokens Translation

**Flutter → Tailwind CSS:**

```dart
// Flutter (DsColors)
static const primary = Color(0xFFFF4081);
static const backgroundDark = Color(0xFF0B0B0C);
```

```css
/* Tailwind (tailwind.config.js) */
colors: {
  primary: {
    DEFAULT: '#FF4081',
    light: '#FF79A8',
    dark: '#C60055',
  },
  background: {
    light: '#FFFFFF',
    dark: '#0B0B0C',
  },
}
```

### 7.2 Component Mapping

| Flutter Widget | React Component | Package |
|----------------|-----------------|---------|
| `GlassButton` | `<GlassButton />` | @crush/ui |
| `GlassCard` | `<GlassCard />` | @crush/ui |
| `GlassTextField` | `<GlassInput />` | @crush/ui |
| `CrushAvatar` | `<Avatar />` | @crush/ui |
| `SkeletonLoader` | `<Skeleton />` | @crush/ui |
| `EmptyState` | `<EmptyState />` | @crush/ui |
| `SwipeCard` | `<SwipeCard />` | @crush/features |
| `VoiceNotePlayer` | `<VoicePlayer />` | @crush/features |
| `TypingIndicator` | `<TypingDots />` | @crush/ui |

### 7.3 Glass Effect Implementation

```typescript
// Glass effect with Tailwind
const glassStyles = {
  base: 'bg-white/10 dark:bg-white/5 backdrop-blur-xl',
  border: 'border border-white/20',
  shadow: 'shadow-lg shadow-black/5',
};

// Component
<div className={cn(glassStyles.base, glassStyles.border, glassStyles.shadow)}>
  {children}
</div>
```

---

## 8. Security Considerations

### 8.1 Authentication Security

- [ ] HTTP-only cookies for session tokens
- [ ] CSRF protection
- [ ] Rate limiting on auth endpoints
- [ ] Secure session storage
- [ ] XSS prevention (React handles most)
- [ ] Content Security Policy headers

### 8.2 Data Protection

- [ ] Input sanitization
- [ ] File upload validation
- [ ] Image processing (strip EXIF)
- [ ] PII handling compliance
- [ ] GDPR data export
- [ ] Account deletion workflow

### 8.3 Firebase Security

- [ ] Firestore security rules (existing)
- [ ] Storage security rules (existing)
- [ ] Cloud Functions authentication
- [ ] API key restrictions

---

## 9. Performance Requirements

### 9.1 Core Web Vitals Targets

| Metric | Target | Notes |
|--------|--------|-------|
| LCP (Largest Contentful Paint) | < 2.5s | Critical for landing page |
| FID (First Input Delay) | < 100ms | Interactive elements |
| CLS (Cumulative Layout Shift) | < 0.1 | Stable layouts |
| TTI (Time to Interactive) | < 3.5s | App shell |
| FCP (First Contentful Paint) | < 1.8s | Initial render |

### 9.2 Bundle Size Targets

| Bundle | Target | Notes |
|--------|--------|-------|
| Initial JS | < 150KB | First load |
| CSS | < 50KB | Tailwind purged |
| Images | Optimized | next/image |
| Fonts | < 100KB | Subset fonts |

### 9.3 Optimization Strategies

- [ ] Route-based code splitting
- [ ] Image optimization (next/image, WebP, AVIF)
- [ ] Font subsetting
- [ ] Lazy loading (below-fold content)
- [ ] Service worker caching
- [ ] CDN edge caching
- [ ] Database query optimization
- [ ] Real-time connection pooling

---

## 10. SEO & Marketing Website

### 10.1 Marketing Pages

| Page | Route | Purpose |
|------|-------|---------|
| Landing | `/` | Hero, features, CTA |
| Features | `/features` | Feature showcase |
| Pricing | `/pricing` | Plans comparison |
| About | `/about` | Company story |
| Contact | `/contact` | Contact form |
| FAQ | `/faq` | Common questions |
| Download | `/download` | App store links |

### 10.2 Legal Pages

| Page | Route | Purpose |
|------|-------|---------|
| Privacy Policy | `/privacy` | Privacy policy |
| Terms of Service | `/terms` | Terms & conditions |
| Community Guidelines | `/guidelines` | User guidelines |
| Safety | `/safety` | Safety tips |

### 10.3 SEO Requirements

- [ ] Server-side rendering (SSR)
- [ ] Meta tags (title, description)
- [ ] Open Graph tags
- [ ] Twitter Card tags
- [ ] Schema.org markup
- [ ] Sitemap.xml
- [ ] Robots.txt
- [ ] Canonical URLs
- [ ] Alt text for images
- [ ] Heading hierarchy
- [ ] Mobile-friendly design
- [ ] Page speed optimization

### 10.4 Analytics

- [ ] Google Analytics 4
- [ ] Firebase Analytics
- [ ] Conversion tracking
- [ ] Event tracking
- [ ] User journey mapping
- [ ] A/B testing framework

---

## 11. Testing Strategy

### 11.1 Unit Tests

```typescript
// Example: Auth store tests
describe('AuthStore', () => {
  it('should sign in with phone OTP', async () => {
    const { signIn } = useAuthStore.getState().actions;
    await signIn('phone', { phone: '+1234567890', code: '123456' });
    expect(useAuthStore.getState().status).toBe('authenticated');
  });
});
```

### 11.2 Integration Tests

```typescript
// Example: Chat flow
describe('Chat Flow', () => {
  it('should send and receive messages', async () => {
    // Send message
    await chatService.sendMessage(matchId, { text: 'Hello!' });

    // Verify in Firestore
    const messages = await getMessages(matchId);
    expect(messages[0].text).toBe('Hello!');
  });
});
```

### 11.3 E2E Tests (Playwright)

```typescript
// Example: Onboarding flow
test('complete onboarding flow', async ({ page }) => {
  await page.goto('/auth/signup');
  await page.fill('[name="phone"]', '+1234567890');
  await page.click('button[type="submit"]');
  // ... continue flow
  await expect(page).toHaveURL('/discover');
});
```

### 11.4 Test Coverage Targets

| Category | Target |
|----------|--------|
| Unit Tests | 80% |
| Integration | 60% |
| E2E (Critical Paths) | 100% |

---

## 12. Deployment Strategy

### 12.1 Environments

| Environment | URL | Purpose |
|-------------|-----|---------|
| Development | localhost:3000 | Local development |
| Preview | pr-*.vercel.app | PR previews |
| Staging | staging.crush.app | Pre-production |
| Production | crush.app | Live |

### 12.2 CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - run: pnpm install
      - run: pnpm test
      - run: pnpm lint

  deploy-preview:
    needs: test
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}

  deploy-production:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-args: '--prod'
```

### 12.3 Monitoring

- [ ] Vercel Analytics
- [ ] Sentry error tracking
- [ ] Firebase Performance
- [ ] Uptime monitoring
- [ ] Log aggregation

---

## 13. Risk Assessment

### 13.1 Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Firebase SDK web compatibility | Medium | Test early, have HTTP fallback |
| Real-time performance at scale | Medium | Connection pooling, pagination |
| Third-party API rate limits | Low | Caching, exponential backoff |
| Browser compatibility | Low | Test matrix, polyfills |
| Mobile web experience | Medium | Responsive-first design |

### 13.2 Project Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Scope creep | High | Strict phase gates |
| Feature parity gaps | Medium | Detailed mapping doc |
| Timeline slippage | Medium | Buffer time, MVP focus |
| Backend changes needed | Low | Minimal backend work |

---

## 14. Implementation Checklist

### Phase 0: Foundation
- [ ] Monorepo setup (Turborepo)
- [ ] Next.js 14 configuration
- [ ] TypeScript setup
- [ ] Tailwind CSS + design tokens
- [ ] Firebase SDK integration
- [ ] Vercel deployment
- [ ] CI/CD pipeline
- [ ] Environment variables

### Phase 1: Authentication
- [ ] Auth gateway page
- [ ] Phone OTP flow
- [ ] Email/password flow
- [ ] Session management
- [ ] Route protection
- [ ] Logout
- [ ] Forgot password

### Phase 2: Onboarding
- [ ] Terms acceptance
- [ ] Basic info form
- [ ] Photo upload
- [ ] Profile setup
- [ ] Location selection
- [ ] Completeness meter

### Phase 3: Discovery
- [ ] Swipe deck
- [ ] Profile cards
- [ ] Like/Pass actions
- [ ] Match modal
- [ ] Filters
- [ ] Super Like
- [ ] Rewind
- [ ] Likes You
- [ ] Weekly Picks

### Phase 4: Messaging
- [ ] Conversation list
- [ ] Chat interface
- [ ] Real-time updates
- [ ] Send messages
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Reactions
- [ ] Photo sharing
- [ ] Pagination
- [ ] Edit/Unsend

### Phase 5: Profile & Settings
- [ ] Profile view
- [ ] Profile edit
- [ ] Other user profile
- [ ] Settings pages
- [ ] Privacy settings
- [ ] Notifications
- [ ] Account management

### Phase 6: Safety & Social
- [ ] Block/Report
- [ ] Blocked users list
- [ ] Date ideas
- [ ] Compatibility quiz

### Phase 7: Subscription
- [ ] Plans display
- [ ] Stripe Checkout
- [ ] Subscription status
- [ ] Feature gating
- [ ] Cancel flow

### Phase 8: Marketing Site
- [ ] Landing page
- [ ] Features page
- [ ] Pricing page
- [ ] About/Contact
- [ ] FAQ
- [ ] Legal pages
- [ ] SEO setup

### Phase 9: Polish
- [ ] E2E tests
- [ ] Performance optimization
- [ ] Accessibility
- [ ] Error handling
- [ ] Analytics
- [ ] Monitoring

---

## Appendix A: File Structure Reference

```
crush-web/
├── apps/
│   └── web/
│       ├── app/
│       │   ├── (marketing)/
│       │   │   ├── page.tsx              # Landing page
│       │   │   ├── features/page.tsx
│       │   │   ├── pricing/page.tsx
│       │   │   ├── about/page.tsx
│       │   │   ├── contact/page.tsx
│       │   │   ├── faq/page.tsx
│       │   │   ├── privacy/page.tsx
│       │   │   ├── terms/page.tsx
│       │   │   ├── guidelines/page.tsx
│       │   │   └── layout.tsx
│       │   │
│       │   ├── (auth)/
│       │   │   ├── auth/
│       │   │   │   ├── page.tsx          # Auth gateway
│       │   │   │   ├── login/page.tsx
│       │   │   │   ├── signup/page.tsx
│       │   │   │   ├── phone/page.tsx
│       │   │   │   ├── verify/page.tsx
│       │   │   │   └── forgot-password/page.tsx
│       │   │   └── layout.tsx
│       │   │
│       │   ├── (onboarding)/
│       │   │   ├── onboarding/
│       │   │   │   ├── terms/page.tsx
│       │   │   │   ├── basic-info/page.tsx
│       │   │   │   ├── profile/page.tsx
│       │   │   │   └── verify-id/page.tsx
│       │   │   └── layout.tsx
│       │   │
│       │   ├── (app)/
│       │   │   ├── discover/
│       │   │   │   ├── page.tsx          # Swipe deck
│       │   │   │   ├── likes/page.tsx
│       │   │   │   └── picks/page.tsx
│       │   │   ├── matches/page.tsx
│       │   │   ├── messages/
│       │   │   │   ├── page.tsx          # Conversation list
│       │   │   │   ├── requests/page.tsx
│       │   │   │   └── [matchId]/page.tsx
│       │   │   ├── profile/
│       │   │   │   ├── page.tsx
│       │   │   │   ├── edit/page.tsx
│       │   │   │   ├── media/page.tsx
│       │   │   │   └── insights/page.tsx
│       │   │   ├── settings/
│       │   │   │   ├── page.tsx
│       │   │   │   ├── privacy/page.tsx
│       │   │   │   ├── notifications/page.tsx
│       │   │   │   ├── discovery/page.tsx
│       │   │   │   ├── security/page.tsx
│       │   │   │   └── account/page.tsx
│       │   │   ├── u/[userId]/page.tsx   # View other profile
│       │   │   ├── date-ideas/page.tsx
│       │   │   ├── call/[matchId]/page.tsx
│       │   │   └── layout.tsx            # App shell
│       │   │
│       │   ├── api/
│       │   │   ├── auth/[...nextauth]/route.ts
│       │   │   ├── upload/route.ts
│       │   │   └── contact/route.ts
│       │   │
│       │   ├── layout.tsx                # Root layout
│       │   ├── not-found.tsx
│       │   └── error.tsx
│       │
│       ├── components/
│       │   ├── app/                      # App-specific
│       │   ├── marketing/                # Marketing-specific
│       │   └── shared/                   # Shared
│       │
│       ├── hooks/
│       ├── lib/
│       ├── styles/
│       ├── public/
│       ├── next.config.js
│       ├── tailwind.config.ts
│       └── tsconfig.json
│
└── packages/
    ├── ui/
    ├── core/
    ├── features/
    └── config/
```

---

## Appendix B: Commands Reference

```bash
# Development
pnpm dev                    # Start dev server
pnpm dev --filter web       # Start web app only

# Building
pnpm build                  # Build all packages
pnpm build --filter web     # Build web app

# Testing
pnpm test                   # Run all tests
pnpm test:e2e              # Run E2E tests
pnpm test:coverage         # Generate coverage

# Linting
pnpm lint                   # Lint all
pnpm lint:fix              # Fix lint issues

# Type checking
pnpm typecheck             # Check types

# Deployment
vercel                     # Deploy preview
vercel --prod              # Deploy production
```

---

**Document End**

*This document will be updated as implementation progresses. All changes should be logged in the AI Change Log.*
