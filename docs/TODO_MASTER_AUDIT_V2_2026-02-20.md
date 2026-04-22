# CRUSH Audit Program V2 - Fresh Start Index

- Program: Comprehensive Audit, Remediation, and Production Readiness
- Date Baseline: 2026-02-20
- Fresh Start Reset: 2026-04-16
- Owner: Engineering + AI Agents
- Status: In Progress

## Global Exit Criteria
- Zero open P0 and P1 items across active backlog docs
- All critical flows covered by automated tests
- iPad compliance complete across portrait, landscape, Split View, and Slide Over
- Store compliance evidence complete for Apple and Google
- Production monitoring, backup, and security baselines verified

## Active Backlog Docs

### Product Modules
- Authentication & Security: `docs/TODO_AUTH_SECURITY.md`
- Profile Frontend: `docs/TODO_PROFILE_FRONTEND.md`
- Profile Backend: `docs/TODO_PROFILE_BACKEND.md`
- Discovery UI: `docs/TODO_DISCOVERY_UI.md`
- Matching Logic: `docs/TODO_MATCHING_LOGIC.md`
- Discovery Backend: `docs/TODO_DISCOVERY_BACKEND.md`
- Chat UI: `docs/TODO_CHAT_UI.md`
- Chat Realtime: `docs/TODO_CHAT_REALTIME.md`
- Chat Backend: `docs/TODO_CHAT_BACKEND.md`
- Calls & RTC: `docs/TODO_CALLS.md`
- Notifications: `docs/TODO_NOTIFICATIONS.md`
- Settings UI: `docs/TODO_SETTINGS_UI.md`
- Account Management: `docs/TODO_ACCOUNT_MGMT.md`
- Onboarding Flow: `docs/TODO_ONBOARDING_FLOW.md`
- Onboarding UI: `docs/TODO_ONBOARDING_UI.md`

### Cross-Cutting Quality
- iPad Compliance: `docs/TODO_IPAD_COMPLIANCE.md`
- Responsive Design: `docs/TODO_RESPONSIVE_DESIGN.md`
- Accessibility: `docs/TODO_ACCESSIBILITY.md`
- State Management: `docs/TODO_STATE_MANAGEMENT.md`
- Error Handling: `docs/TODO_ERROR_HANDLING.md`
- Performance: `docs/TODO_PERFORMANCE.md`
- Internationalization & Localization: `docs/TODO_I18N_L10N.md`
- Testing Matrix: `docs/TODO_TESTING_MATRIX.md`

### Backend & Security
- API Architecture: `docs/TODO_API_ARCHITECTURE.md`
- Database: `docs/TODO_DATABASE.md`
- Real-Time Infrastructure: `docs/TODO_REALTIME.md`
- Security Backend: `docs/TODO_SECURITY_BACKEND.md`
- Security Frontend: `docs/TODO_SECURITY_FRONTEND.md`

### Cleanup & Refactoring
- TODO Comment Audit: `docs/TODO_CLEANUP_COMMENTS.md`
- Dead Code & Unused Assets: `docs/TODO_CLEANUP_DEAD_CODE.md`
- Dependency Audit: `docs/TODO_CLEANUP_DEPENDENCIES.md`
- Refactor Auth: `docs/TODO_REFACTOR_AUTH.md`
- Refactor Profile: `docs/TODO_REFACTOR_PROFILE.md`
- Refactor Discovery: `docs/TODO_REFACTOR_DISCOVERY.md`
- Refactor Chat: `docs/TODO_REFACTOR_CHAT.md`
- Refactor Settings: `docs/TODO_REFACTOR_SETTINGS.md`

### Store & Strategy
- Apple Store Compliance: `docs/TODO_STORE_APPLE.md`
- Google Play Compliance: `docs/TODO_STORE_GOOGLE.md`
- Innovation Backlog: `docs/TODO_INNOVATIONS.md`
- Web Platform Execution Board: `docs/TODO_WEBAPP.md`

## Cleared / Reference Docs
- Subscription & Billing Module: `docs/TODO_SUBSCRIPTION.md` (no open items as of 2026-04-16)

## Fresh Start Rules
- New audit work should be filed in the module-specific TODO docs above, not in ad hoc consolidated checklists.
- `docs/TODO_WEBAPP.md` is now a routing board that maps web work into the module-specific TODO files.
- Historical task evidence stays in `docs/ai_workboard.md` and `docs/Developer_agent_chat.md`, not in the active TODO files.

## Phased Execution Order
1. P0 security, auth, discovery, chat, and store blockers
2. iPad compliance, responsive design, accessibility, and onboarding stability
3. Performance, error handling, state management, and testing hardening
4. Cleanup, refactoring, and innovation packaging
5. Store submission evidence packs and production-readiness signoff

## Reporting Rules
- Every TODO item must include explicit acceptance criteria and test requirements.
- Every completed item must reference changed files and verification evidence in the workboard/task log.
- Every blocked item must include blocker owner and unblock plan.
