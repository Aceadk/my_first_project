# CRUSH Web Platform - Implementation TODO

**Status:** In Development - ~85% Complete (core features shipped, polish in progress)
**Live URL:** https://crush-web-chi.vercel.app
**Repo:** /Users/ace/crush-web

## Quick Links

- [AUDIT_WEBAPP.md](./AUDIT_WEBAPP.md) - Full audit and architecture
- [ai_change_log.md](./ai_change_log.md) - Change history
- [ai_tasks_board.md](./ai_tasks_board.md) - Task tracking
- [project_flowchart.md](./project_flowchart.md) - App flow diagrams


## Implementation Status Overview

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1: Authentication | **MOSTLY COMPLETE** | 95% |
| Phase 2: Onboarding | **COMPLETE** | 100% |
| Phase 3: Discovery | **MOSTLY COMPLETE** | 90% |
| Phase 4: Messaging | **MOSTLY COMPLETE** | 95% |
| Phase 5: Profile & Settings | **MOSTLY COMPLETE** | 90% |
| Phase 6: Safety & Social | **COMPLETE** | 100% |
| Phase 7: Subscription | **MOSTLY COMPLETE** | 80% |
| Phase 8: Marketing Website | **COMPLETE** | 100% |
| Phase 9: Polish & Testing | **IN PROGRESS** | 40% |

**Overall Progress: ~85%**


## Phase 0: Foundation -
### CI/CD
- [ ] GitHub Actions workflow (test + lint jobs)

## Phase 1: Authentication 

### Email/Password Flow

- [ ] Remember me checkbox

### Session Management

- [ ] Inactivity timeout

### Remaining Auth Features
- [ ] Email link sign-in
- [ ] Google sign-in (partial setup exists)
- [ ] New device verification

### Remaining
- [ ] Drag & drop photo reorder
- [ ] Crop/adjust modal
- [ ] Terms & Conditions step (inline)


## Phase 3: Discovery 

### Match Celebration

- [ ] Confetti animation

### Discovery Filters
- [ ] Save filters to profile
- [ ] Interest filtering

### Swipe Actions
- [ ] Swipe up for Super Like
- [ ] Daily limits

### Remaining
- [ ] Profile stories
- [ ] Boost feature
- [ ] Passport mode
- [ ] Photo carousel on profile cards

## Phase 4: Messaging 

### Conversation List
- [ ] Search conversations
- [ ] Pinned conversations

### Real-time
- [ ] Reconnection logic / offline indicator

### Remaining
- [ ] Voice notes
- [ ] Video/Audio calls
- [ ] Ice breakers / suggested starters


## Phase 5: Profile & Settings

### Remaining
- [ ] Profile verification badge
- [ ] Lifestyle info section
- [ ] Photo reordering/cropping in edit
- [ ] Discard unsaved changes confirmation

## Phase 6: Safety & Social 

- [ ] Hide blocked users from discovery (backend rule)

## Phase 7: Subscription - 80% COMPLETE

### Feature Gating
- [ ] Plus feature wrapper component
- [ ] Upsell modal

### Subscription Status
- [ ] Cancel flow

### Accessibility (PARTIAL)
- [ ] Full screen reader audit
- [ ] Keyboard navigation audit
- [ ] Color contrast audit
- [ ] Focus management
- [ ] ARIA labels review

### Performance
- [ ] Lighthouse audit + fixes
- [ ] Core Web Vitals optimization
- [ ] Bundle analysis + code splitting
- [ ] Image optimization audit

### Error Handling

- [ ] Fallback UI for loading/error states
- [ ] Retry logic for failed requests

### Analytics & Monitoring
- [ ] Page view tracking
- [ ] Event tracking + conversion funnel
- [ ] Error tracking (Sentry or similar)
- [ ] Uptime monitoring


## Mobile App Feature Parity Summary

| Feature | Mobile | Web | Status |
|---------|--------|-----|--------|
| Email/Password Login | Yes | Yes | Done |
| Phone OTP | Yes | Yes | Done |
| Onboarding Flow | Yes | Yes | Done |
| Swipe Deck | Yes | Yes | Done |
| Match Modal | Yes | Yes | Done |
| Real-time Chat | Yes | Yes | Done |
| Typing Indicators | Yes | Yes | Done |
| Read Receipts | Yes | Yes | Done |
| Profile View/Edit | Yes | Yes | Done |
| Theme Toggle | Yes | Yes | Done |
| Likes You Page | Yes | Yes | Done |
| Weekly Picks | Yes | Yes | Done |
| Message Reactions | Yes | Yes | Done |
| Photo Sharing | Yes | Yes | Done |
| Privacy Settings | Yes | Yes | Done |
| Discovery Settings | Yes | Yes | Done |
| Account Management | Yes | Yes | Done |
| Date Safety | Yes | Yes | Done |
| Date Ideas | Yes | Yes | Done |
| Compatibility Quiz | Yes | Yes | Done |
| Profile Insights | Yes | Yes | Done |
| Incognito Mode | Yes | Yes | Done |
| Voice Notes | Yes | No | P3 |
| Audio/Video Calls | Yes | No | P3 |
| Push Notifications | Yes | No | P3 |
| Profile Stories | Yes | No | P3 |
| Boost Feature | Yes | No | P3 |

---

## Priority Remaining Work

### P2 - Medium Priority
2. [ ] Lighthouse performance audit + fixes
3. [ ] Google sign-in integration
4. [ ] Photo drag & drop reorder

### P3 - Lower Priority
1. [ ] Voice notes in chat
2. [ ] Audio/Video calls (WebRTC)
3. [ ] Push notifications (FCM web)
4. [ ] Profile stories
5. [ ] Boost feature
6. [ ] Confetti animation on match
7. [ ] Conversation search + pin
8. [ ] Ice breakers / suggested starters
9. [ ] GitHub Actions CI (test + lint)
10. [ ] Sentry error tracking
11. [ ] Analytics integration


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

| Date | Change | Author |
|------|--------|--------|
| 2026-01-26 | Initial TODO created | AI |
| 2026-01-27 | Fixed profileComplete flag, auth state with cookies | AI |
| 2026-01-27 | Deployed to Vercel | AI |
| 2026-01-27 | Phase 1-8 feature sprint (all P1/P2 items) | AI |
| 2026-02-11 | Audit remediation: JSON-LD, WCAG, dead links, OG images | AI |
| 2026-02-11 | Security: CSRF, rate limiting, HttpOnly cookies, CSP | AI |
| 2026-02-11 | GDPR: Cookie consent banner | AI |
| 2026-02-11 | P0: Fix Firestore env var contamination (%0A in projectId) | AI |
| 2026-02-11 | Added /auth/verify, redirects for /likes-you, /reset-password | AI |
| 2026-02-11 | Re-baselined TODO_WEBAPP.md (removed 652-item parity backlog noise) | AI |

## Notes

- Web app path: `/Users/ace/crush-web`
- Mobile app path: `/Users/ace/my_first_project`
- Both share Firebase backend (project: crush-265f7)
- Live at: https://crush-web-chi.vercel.app
- The mobile parity backlog (Dart file → TS mapping) was removed from this file. It was a raw file listing, not actionable tasks. See `AUDIT_WEBAPP.md` for the full parity matrix if needed.
