# CRUSH Web Platform - Implementation TODO

**Last Updated:** 2026-01-26
**Status:** Planning Complete - Ready for Implementation

---

## Quick Links

- [AUDIT_WEBAPP.md](./AUDIT_WEBAPP.md) - Full audit and architecture
- [ai_change_log.md](./ai_change_log.md) - Change history
- [ai_tasks_board.md](./ai_tasks_board.md) - Task tracking

---

## Implementation Status Overview

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 0: Foundation | Not Started | 0% |
| Phase 1: Authentication | Not Started | 0% |
| Phase 2: Onboarding | Not Started | 0% |
| Phase 3: Discovery | Not Started | 0% |
| Phase 4: Messaging | Not Started | 0% |
| Phase 5: Profile & Settings | Not Started | 0% |
| Phase 6: Safety & Social | Not Started | 0% |
| Phase 7: Subscription | Not Started | 0% |
| Phase 8: Marketing Website | Not Started | 0% |
| Phase 9: Polish & Testing | Not Started | 0% |

---

## Phase 0: Foundation

### Monorepo Setup
- [ ] Initialize Turborepo with `pnpm create turbo@latest`
- [ ] Configure workspace structure (apps/, packages/)
- [ ] Set up shared TypeScript config
- [ ] Set up shared ESLint config
- [ ] Set up shared Tailwind config
- [ ] Configure Turborepo pipeline (build, dev, test, lint)

### Next.js App Setup
- [ ] Create Next.js 14 app with App Router
- [ ] Configure `next.config.js`
  - [ ] Image domains (Firebase Storage)
  - [ ] Webpack optimizations
  - [ ] Environment variables
- [ ] Set up middleware for auth
- [ ] Configure layout structure

### Design System Package (@crush/ui)
- [ ] Create package structure
- [ ] Configure Tailwind CSS
- [ ] Define design tokens (colors, spacing, typography)
  - [ ] Primary colors (#FF4081)
  - [ ] Background colors (light/dark)
  - [ ] Text colors
  - [ ] Spacing scale
  - [ ] Typography scale
  - [ ] Border radius
  - [ ] Shadows
- [ ] Create base components
  - [ ] Button (Primary, Secondary, Ghost, Glass)
  - [ ] Input (Text, Textarea, Select)
  - [ ] Card (Standard, Glass)
  - [ ] Avatar
  - [ ] Badge
  - [ ] Skeleton loader
  - [ ] Empty state
  - [ ] Loading spinner
  - [ ] Modal/Dialog
  - [ ] Toast notifications

### Firebase Integration
- [ ] Install Firebase SDK
- [ ] Create Firebase config
- [ ] Set up AuthProvider
- [ ] Configure Firestore
- [ ] Configure Storage
- [ ] Test connection

### State Management
- [ ] Set up Zustand
- [ ] Create store structure
  - [ ] Auth store skeleton
  - [ ] Profile store skeleton
  - [ ] Discovery store skeleton
  - [ ] Chat store skeleton
- [ ] Set up React Query
- [ ] Create query client

### Deployment
- [ ] Configure Vercel project
- [ ] Set up environment variables
- [ ] Configure deployment settings
- [ ] Test initial deployment

### CI/CD
- [ ] Create GitHub Actions workflow
- [ ] Configure test job
- [ ] Configure lint job
- [ ] Configure deploy job
- [ ] Set up branch protection

---

## Phase 1: Authentication

### Auth Gateway
- [ ] Create `/auth` page
- [ ] Design login/signup choice UI
- [ ] Add social proof elements
- [ ] Mobile responsive layout

### Phone OTP Flow
- [ ] Create `/auth/phone` page
- [ ] Country code selector component
- [ ] Phone number input with validation
- [ ] Send OTP button
- [ ] OTP input component (6 digits)
- [ ] Verify OTP action
- [ ] Loading states
- [ ] Error handling
- [ ] Resend OTP functionality

### Email/Password Flow
- [ ] Create `/auth/login` page
- [ ] Create `/auth/signup` page
- [ ] Email input with validation
- [ ] Password input with strength indicator
- [ ] Show/hide password toggle
- [ ] Remember me checkbox
- [ ] Sign in/up actions
- [ ] Loading states
- [ ] Error handling

### Password Reset
- [ ] Create `/auth/forgot-password` page
- [ ] Email input
- [ ] Send reset link action
- [ ] Success message

### Session Management
- [ ] Create auth middleware
- [ ] Token storage (HTTP-only cookies preferred)
- [ ] Session refresh logic
- [ ] Inactivity timeout (30 min)
- [ ] Activity tracking

### Route Protection
- [ ] Create protected route wrapper
- [ ] Redirect unauthenticated users
- [ ] Handle loading states
- [ ] Preserve intended destination

### Logout
- [ ] Create logout action
- [ ] Clear session
- [ ] Clear local state
- [ ] Redirect to auth

---

## Phase 2: Onboarding

### Terms Acceptance
- [ ] Create `/onboarding/terms` page
- [ ] Display terms content
- [ ] Privacy policy link
- [ ] Accept checkbox
- [ ] Continue button
- [ ] Track acceptance

### Basic Info Form
- [ ] Create `/onboarding/basic-info` page
- [ ] First name input
- [ ] Last name input (optional)
- [ ] Username input with availability check
- [ ] Date of birth picker
- [ ] Age calculation and validation (18+)
- [ ] Gender selection (Male, Female, Non-binary, Other)
- [ ] Form validation
- [ ] Save action
- [ ] Loading states

### Profile Setup
- [ ] Create `/onboarding/profile` page
- [ ] Photo upload section
  - [ ] Drag & drop zone
  - [ ] File picker button
  - [ ] Photo preview
  - [ ] Crop/adjust modal
  - [ ] Reorder functionality
  - [ ] Delete photo
  - [ ] Upload progress
  - [ ] Max 6 photos
- [ ] Bio textarea
  - [ ] Character counter (500 max)
  - [ ] Placeholder suggestions
- [ ] Interests selection
  - [ ] Available interests grid
  - [ ] Selected interests chips
  - [ ] Min 3, max 10
- [ ] Location selection
  - [ ] Manual city/country input
  - [ ] Browser geolocation option
  - [ ] Location preview
- [ ] Profile prompts (optional)
  - [ ] Select prompt question
  - [ ] Write answer
  - [ ] Add up to 3

### Profile Completeness
- [ ] Completeness meter component
- [ ] Calculate completion percentage
- [ ] Show missing items
- [ ] Encourage completion

### ID Verification (Optional)
- [ ] Create `/onboarding/verify-id` page
- [ ] ID type selection
- [ ] Document upload
- [ ] Selfie capture
- [ ] Skip option
- [ ] Verification status

---

## Phase 3: Discovery

### Swipe Deck Interface
- [ ] Create `/discover` page
- [ ] Card stack component
- [ ] Swipeable card implementation
  - [ ] Touch/drag gestures
  - [ ] Mouse drag support
  - [ ] Keyboard navigation (arrow keys, space)
  - [ ] Swipe threshold detection
  - [ ] Animation on swipe
- [ ] Profile card design
  - [ ] Photo carousel
  - [ ] Name, age, distance
  - [ ] Bio preview
  - [ ] Interests tags
  - [ ] Prompts section
  - [ ] Expand for full profile

### Action Buttons
- [ ] Pass button (X) - red
- [ ] Like button (Heart) - green
- [ ] Super Like button (Star) - blue (Plus only)
- [ ] Rewind button (Undo) - yellow (Plus only)
- [ ] Boost button (Lightning) - purple (Plus only)
- [ ] Button animations
- [ ] Keyboard shortcuts

### Match Celebration
- [ ] Match modal component
- [ ] Confetti animation
- [ ] Both user photos
- [ ] "Send message" CTA
- [ ] "Keep swiping" option
- [ ] Animation timing

### Discovery Filters
- [ ] Filters modal/drawer
- [ ] Age range slider (18-99)
- [ ] Distance slider (1-100+ km/mi)
- [ ] Gender preferences (checkboxes)
- [ ] Apply/Reset buttons
- [ ] Save preferences

### Super Like (Plus)
- [ ] Super like action
- [ ] Animation effect
- [ ] Notification to recipient
- [ ] Limited uses indicator

### Rewind (Plus)
- [ ] Rewind action
- [ ] Restore last profile
- [ ] Animation
- [ ] Limited uses

### Likes You (Plus)
- [ ] Create `/discover/likes` page
- [ ] Blurred grid preview (Free)
- [ ] Full grid (Plus)
- [ ] Like count badge
- [ ] Tap to view profile
- [ ] Quick like/pass actions

### Weekly Picks
- [ ] Create `/discover/picks` page
- [ ] Curated profiles grid
- [ ] Refresh weekly
- [ ] Special badge indicator

### Empty States
- [ ] No more profiles
- [ ] Expand filters suggestion
- [ ] Come back later message
- [ ] Loading skeleton

---

## Phase 4: Messaging

### Conversation List
- [ ] Create `/messages` page
- [ ] Conversation list component
- [ ] Conversation item
  - [ ] User avatar
  - [ ] Name
  - [ ] Last message preview
  - [ ] Timestamp
  - [ ] Unread indicator
  - [ ] Online status dot
- [ ] Empty state
- [ ] Search conversations
- [ ] Pull to refresh

### Chat Interface
- [ ] Create `/messages/[matchId]` page
- [ ] Chat header
  - [ ] User avatar
  - [ ] Name
  - [ ] Online status
  - [ ] More options menu
- [ ] Message list
  - [ ] Message bubbles
  - [ ] Sent/received styling
  - [ ] Timestamps
  - [ ] Date separators
  - [ ] Read receipts
  - [ ] Delivery status
- [ ] Message input
  - [ ] Text input
  - [ ] Send button
  - [ ] Attachment button
  - [ ] Emoji picker

### Real-time Updates
- [ ] Firestore subscription
- [ ] New message handling
- [ ] Message status updates
- [ ] Reconnection logic
- [ ] Offline indicator

### Typing Indicators
- [ ] Firebase RTDB integration
- [ ] Debounced typing status
- [ ] Typing animation
- [ ] Clear on send

### Read Receipts
- [ ] Mark messages read on view
- [ ] Read receipt checkmarks
- [ ] Batch updates

### Message Reactions
- [ ] Long press/right click menu
- [ ] Reaction picker
- [ ] Add reaction action
- [ ] Display reactions
- [ ] Remove own reaction

### Photo Sharing
- [ ] Attachment button
- [ ] Image picker
- [ ] Image preview
- [ ] Upload with progress
- [ ] Display in chat
- [ ] Full-screen view

### Message Actions (Plus)
- [ ] Edit message
  - [ ] Edit mode
  - [ ] Save changes
  - [ ] "Edited" indicator
- [ ] Unsend message
  - [ ] Confirmation
  - [ ] Remove from both sides
  - [ ] "Message removed" placeholder

### Message Pagination
- [ ] Load 50 messages initially
- [ ] Infinite scroll up
- [ ] Loading indicator
- [ ] Maintain scroll position

### Message Requests
- [ ] Create `/messages/requests` page
- [ ] Pending requests list
- [ ] Accept/Decline actions
- [ ] Request notification

### Ice Breakers
- [ ] Suggestion carousel
- [ ] Tap to send
- [ ] Contextual suggestions

---

## Phase 5: Profile & Settings

### Profile View
- [ ] Create `/profile` page
- [ ] Profile header
  - [ ] Avatar
  - [ ] Name, age
  - [ ] Verification badge
  - [ ] Edit button
- [ ] Photo gallery
- [ ] Bio section
- [ ] Interests tags
- [ ] Prompts display
- [ ] Lifestyle info
- [ ] Preview as others see

### Profile Edit
- [ ] Create `/profile/edit` page
- [ ] All editable fields
- [ ] Photo management
- [ ] Save changes
- [ ] Discard changes
- [ ] Validation

### Other User Profile
- [ ] Create `/u/[userId]` page
- [ ] Full profile view
- [ ] Report button
- [ ] Block button
- [ ] Unmatch button (if matched)

### Settings Hub
- [ ] Create `/settings` page
- [ ] Settings categories
- [ ] Navigation to sub-pages

### Privacy Settings
- [ ] Name visibility toggles
- [ ] Age visibility
- [ ] Distance visibility
- [ ] Active status visibility
- [ ] Read receipts toggle

### Notification Settings
- [ ] New matches toggle
- [ ] Messages toggle
- [ ] Likes toggle
- [ ] Marketing toggle
- [ ] Push permission request

### Discovery Settings
- [ ] Age preference
- [ ] Distance preference
- [ ] Gender preferences
- [ ] Show me in discovery toggle

### Account Security
- [ ] Change password
- [ ] Connected devices
- [ ] Two-factor authentication
- [ ] Login history

### Account Management
- [ ] Change email
- [ ] Change phone
- [ ] Export data (GDPR)
- [ ] Deactivate account
- [ ] Delete account

---

## Phase 6: Safety & Social

### Block User
- [ ] Block action
- [ ] Confirmation modal
- [ ] Block user in Firestore
- [ ] Remove from matches
- [ ] Hide from discovery

### Report User
- [ ] Report button
- [ ] Report reason selection
- [ ] Additional details
- [ ] Submit report
- [ ] Confirmation

### Blocked Users List
- [ ] Create blocked users page
- [ ] List blocked users
- [ ] Unblock action
- [ ] Empty state

### Date Ideas
- [ ] Create `/date-ideas` page
- [ ] Ideas categories
- [ ] Random idea generator
- [ ] Save favorites
- [ ] Share with match

### Compatibility Quiz
- [ ] Quiz modal
- [ ] Question flow
- [ ] Score calculation
- [ ] Results display
- [ ] Share with match

---

## Phase 7: Subscription

### Plans Display
- [ ] Plans comparison component
- [ ] Free tier features
- [ ] Plus tier features
- [ ] Pricing display
- [ ] Feature highlights

### Stripe Checkout
- [ ] Checkout button
- [ ] Redirect to Stripe
- [ ] Success callback
- [ ] Cancel callback
- [ ] Webhook handling

### Subscription Status
- [ ] Current plan display
- [ ] Renewal date
- [ ] Payment method
- [ ] Invoice history

### Feature Gating
- [ ] Plus feature wrapper
- [ ] Upsell modal
- [ ] Feature preview
- [ ] Upgrade CTA

### Cancel Flow
- [ ] Cancel subscription
- [ ] Retention offer
- [ ] Confirmation
- [ ] Downgrade handling

---

## Phase 8: Marketing Website

### Landing Page
- [ ] Hero section
  - [ ] Headline
  - [ ] Subheadline
  - [ ] CTA buttons
  - [ ] Hero image/animation
- [ ] Features section
- [ ] How it works
- [ ] Testimonials
- [ ] Download section
- [ ] Footer

### Features Page
- [ ] Feature showcase
- [ ] Screenshots
- [ ] Feature details
- [ ] CTA

### Pricing Page
- [ ] Plans comparison
- [ ] FAQ
- [ ] CTA

### About Page
- [ ] Company story
- [ ] Team (optional)
- [ ] Mission/values
- [ ] Press kit

### Contact Page
- [ ] Contact form
- [ ] Email
- [ ] Social links

### FAQ Page
- [ ] FAQ accordion
- [ ] Categories
- [ ] Search

### Legal Pages
- [ ] Privacy Policy
- [ ] Terms of Service
- [ ] Community Guidelines
- [ ] Safety Tips

### SEO
- [ ] Meta tags
- [ ] Open Graph
- [ ] Twitter Cards
- [ ] Schema.org
- [ ] Sitemap
- [ ] Robots.txt
- [ ] Canonical URLs

---

## Phase 9: Polish & Testing

### E2E Tests
- [ ] Auth flow tests
- [ ] Onboarding flow tests
- [ ] Discovery tests
- [ ] Chat tests
- [ ] Settings tests

### Performance
- [ ] Lighthouse audit
- [ ] Core Web Vitals
- [ ] Bundle analysis
- [ ] Image optimization
- [ ] Code splitting

### Accessibility
- [ ] Screen reader testing
- [ ] Keyboard navigation
- [ ] Color contrast
- [ ] Focus management
- [ ] ARIA labels

### Error Handling
- [ ] Error boundaries
- [ ] Fallback UI
- [ ] Retry logic
- [ ] User-friendly messages

### Analytics
- [ ] Page views
- [ ] Event tracking
- [ ] Conversion funnel
- [ ] User segments

### Monitoring
- [ ] Error tracking (Sentry)
- [ ] Performance monitoring
- [ ] Uptime alerts
- [ ] Log aggregation

---

## Notes & Decisions

### Decision Log

| Date | Decision | Reasoning |
|------|----------|-----------|
| 2026-01-26 | Use Next.js instead of Flutter Web | SEO requirements, bundle size, web-native UX |
| 2026-01-26 | Turborepo monorepo | Shared packages, incremental builds |
| 2026-01-26 | Zustand + React Query | Simple state, great caching |
| 2026-01-26 | Tailwind CSS | Design token parity, fast iteration |

### Open Questions

1. Should we support multiple languages from day 1?
2. Do we need a separate admin dashboard?
3. Should calls (audio/video) be in initial release?
4. What's the timeline for mobile app parity?

### Dependencies

- Firebase project already configured
- Stripe account set up
- Agora SDK for calls (if included)
- Domain configured for Vercel

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-01-26 | Initial TODO created | AI |

---

**Next Steps:**
1. Review and approve audit document
2. Begin Phase 0: Foundation setup
3. Create GitHub repository for web project
4. Set up Vercel project
