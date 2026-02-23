# CRUSH Web Platform - Implementation TODO

**Status:** In Development - ~96% Complete (core features shipped, polish in progress)
**Live URL:** https://crush-web-chi.vercel.app
**Repo:** /Users/ace/crush-web

## Quick Links

- [AUDIT_WEBAPP.md](./AUDIT_WEBAPP.md) - Full audit and architecture
- [ai_workboard.md](./ai_workboard.md) - Unified AI task/change/collaboration tracker
- [project_flowchart.md](./project_flowchart.md) - App flow diagrams

## Implementation Status Overview

| Phase                       | Status              | Progress |
| --------------------------- | ------------------- | -------- |
| Phase 1: Authentication     | **COMPLETE**        | 100%     |
| Phase 2: Onboarding         | **COMPLETE**        | 100%     |
| Phase 3: Discovery          | **COMPLETE**        | 100%     |
| Phase 4: Messaging          | **MOSTLY COMPLETE** | 99%      |
| Phase 5: Profile & Settings | **COMPLETE**        | 100%     |
| Phase 6: Safety & Social    | **COMPLETE**        | 100%     |
| Phase 7: Subscription       | **MOSTLY COMPLETE** | 95%      |
| Phase 8: Marketing Website  | **COMPLETE**        | 100%     |
| Phase 9: Polish & Testing   | **IN PROGRESS**     | 85%      |

**Overall Progress: ~96%**

## Phase 9: Polish & Testing

### Performance

- [ ] Bundle analysis + code splitting
- [ ] Image optimization audit

## Priority Remaining Work

### P3 - Lower Priority

1. [ ] Audio/Video calls (WebRTC)
2. [ ] Push notifications (FCM web)

## Mobile App Feature Parity Summary

| Feature            | Mobile | Web | Status |
| ------------------ | ------ | --- | ------ |
| Audio/Video Calls  | Yes    | No  | P3     |
| Push Notifications | Yes    | No  | P3     |

## Architecture Notes

### Current Stack

- **Framework:** Next.js 16.1.4 (App Router + Turbopack)
- **State:** Zustand + React Query (TanStack Query)
- **Styling:** Tailwind CSS
- **UI:** Radix UI + @crush/ui
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Payments:** Stripe
- **Deployment:** Vercel (hobby plan, auto-deploy on push)

### Folder Structure

```
/Users/ace/crush-web/
├── apps/web/src/
│   ├── app/
│   │   ├── (marketing)/    # Landing, about, help, privacy, terms, etc.
│   │   ├── (app)/          # Authenticated app shell (discover, messages, etc.)
│   │   ├── auth/           # Login, signup, phone, forgot-password, verify
│   │   ├── onboarding/     # Multi-step onboarding flow
│   │   └── api/            # API routes (auth/session, stripe)
│   ├── features/           # Feature-specific components
│   └── shared/             # Shared components, lib, providers
└── packages/
    ├── core/               # Firebase config, stores, services
    └── ui/                 # Design system components
```

### Key Security Features (added 2026-02-11)

- HttpOnly auth cookies (not XSS-accessible)
- CSRF protection via Origin/Referer verification
- In-memory sliding window rate limiting
- CSP header (Firebase, Stripe, Google Fonts)
- Input validation on all API routes

## Change Log

| Date       | Change                                                                                                                                                                                                                                                                                                 | Author |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| 2026-01-26 | Initial TODO created                                                                                                                                                                                                                                                                                   | AI     |
| 2026-01-27 | Fixed profileComplete flag, auth state with cookies                                                                                                                                                                                                                                                    | AI     |
| 2026-01-27 | Deployed to Vercel                                                                                                                                                                                                                                                                                     | AI     |
| 2026-01-27 | Phase 1-8 feature sprint (all P1/P2 items)                                                                                                                                                                                                                                                             | AI     |
| 2026-02-11 | Audit remediation: JSON-LD, WCAG, dead links, OG images                                                                                                                                                                                                                                                | AI     |
| 2026-02-11 | Security: CSRF, rate limiting, HttpOnly cookies, CSP                                                                                                                                                                                                                                                   | AI     |
| 2026-02-11 | GDPR: Cookie consent banner                                                                                                                                                                                                                                                                            | AI     |
| 2026-02-11 | P0: Fix Firestore env var contamination (%0A in projectId)                                                                                                                                                                                                                                             | AI     |
| 2026-02-11 | Added /auth/verify, redirects for /likes-you, /reset-password                                                                                                                                                                                                                                          | AI     |
| 2026-02-11 | Re-baselined TODO_WEBAPP.md (removed 652-item parity backlog noise)                                                                                                                                                                                                                                    | AI     |
| 2026-02-22 | Added GitHub Actions CI workflow for web repo (lint + test jobs)                                                                                                                                                                                                                                       | AI     |
| 2026-02-22 | Added remember-me session policy, inactivity timeout enforcement, email-link login trigger, pinned chats + inline ice-breakers, and analytics page-view provider wiring                                                                                                                                | AI     |
| 2026-02-23 | Added trusted-device verification flow (auth gating + verification pages + device management in account settings)                                                                                                                                                                                      | AI     |
| 2026-02-23 | Added production-ready monitoring hardening: Sentry wrapper integration, auth user-context wiring, `/api/health` endpoint, and scheduled uptime monitor workflow                                                                                                                                       | AI     |
| 2026-02-23 | Added realtime resiliency in messaging (offline indicators + reconnect refresh flow) and shipped analytics event/funnel tracking across auth, onboarding, discovery, messaging, and premium checkout                                                                                                   | AI     |
| 2026-02-23 | Added retry logic for failed requests in messaging (bounded transient retries + manual resend for failed outbound messages)                                                                                                                                                                            | AI     |
| 2026-02-23 | Added reusable premium feature gating with a shared Plus wrapper and upsell modal, then applied it across Likes You, Insights, Message Requests, and Incognito settings screens                                                                                                                        | AI     |
| 2026-02-23 | Fixed Next.js 16 `useSearchParams` suspense migration blockers across auth/device-verify routes and restored successful production web builds                                                                                                                                                          | AI     |
| 2026-02-23 | Added discovery interest filtering end-to-end (filter type, service filtering logic, and discover filter dialog UI with shared-interest chip selection)                                                                                                                                                | AI     |
| 2026-02-23 | Implemented daily swipe-like limits end-to-end via core swipe enforcement + discovery limit indicator/disabled actions + limit-reached UX feedback and analytics tracking                                                                                                                              | AI     |
| 2026-02-23 | Added backend-level blocked-user exclusion in discovery and weekly picks using canonical `blocks` records with legacy fallback support, preventing blocked profiles from appearing as candidates                                                                                                       | AI     |
| 2026-02-23 | Completed discover-card photo carousel UX with visible previous/next controls, keyboard navigation, and per-card photo position indicator for clearer multi-photo browsing                                                                                                                             | AI     |
| 2026-02-23 | Implemented discovery Boost feature end-to-end with premium-gated activation flow, persistent cooldown/active status, boosted profile prioritization in discovery ranking, and boosted-card visual indicators                                                                                          | AI     |
| 2026-02-23 | Implemented Passport mode with premium-gated destination settings in Discovery Settings, passport-aware distance computation in discovery, and active-passport indicator in Discover UI                                                                                                                | AI     |
| 2026-02-23 | Implemented profile stories end-to-end with new core story types/service/store, discover story tray upload flow, card story badges, and full-screen story viewer with view tracking                                                                                                                    | AI     |
| 2026-02-23 | Completed Phase 9 quality pass: Lighthouse mobile/desktop audits, fixed homepage heading-order + color-contrast issues, and split runtime providers so marketing pages avoid loading app-auth/query client stack; improved home Lighthouse scores to 78 (mobile) / 94 (desktop) with accessibility 100 | AI     |
| 2026-02-23 | Completed Phase 5 UI Polish & Accessibility (Partial): Profile verification mock, lifestyle info fields, photo drag-and-drop/cropping, unsaved changes guard, ARIA labels, focus rings, and text contrast fixes                                                                                        | AI     |
| 2026-02-23 | Implemented inline Terms of Service summary view into the Onboarding flow                                                                                                                                                                                                                              | AI     |

## Notes

- Web app path: `/Users/ace/crush-web`
- Mobile app path: `/Users/ace/my_first_project`
- Both share Firebase backend (project: crush-265f7)
- Live at: https://crush-web-chi.vercel.app
- The mobile parity backlog (Dart file → TS mapping) was removed from this file. It was a raw file listing, not actionable tasks. See `AUDIT_WEBAPP.md` for the full parity matrix if needed.
