# TODO: Notification Module

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_API_ARCHITECTURE.md`, `docs/TODO_SECURITY_FRONTEND.md`, `docs/TODO_SECURITY_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### NOTIF-001 - Audit notification permission timing and education flow
- Files: push notification services, onboarding/settings permission prompts, web permission surfaces
- Description: Verify location, push, and notification requests are contextual and not front-loaded in a way that harms store review or user trust.
- Acceptance Criteria: permission prompts are justified and timed intentionally across mobile and web.
- Testing: manual first-run verification on iOS, Android, and web.
- Status: done
- Evidence: `docs/reports/notification_audit_web_push_2026-05-30.md`

### NOTIF-002 - Verify deep-link routing from every notification state
- Files: push handlers, app routers, notification payload mappers
- Description: Ensure taps from foreground, background, and terminated states navigate to the correct screen with the required context.
- Acceptance Criteria: deep-link matrix documented; broken routes are fixed or tracked.
- Testing: notification smoke tests for foreground, background, and cold start.
- Status: done
- Evidence: `docs/reports/notification_audit_web_push_2026-05-30.md`

### NOTIF-003 - Audit notification preference sync and enforcement
- Files: notification settings screens, backend preference sync, delivery filters
- Description: Confirm client preferences and backend send rules match, including muted channels, blocked users, and premium or safety-specific notifications.
- Acceptance Criteria: preference changes propagate correctly; unwanted notifications are suppressed server-side.
- Testing: preference sync tests and manual end-to-end verification.
- Status: done
- Evidence: `docs/reports/notification_audit_web_push_2026-05-30.md`

### NOTIF-004 - Implement web push parity
- Files: `/Users/ace/crush-web/**/notifications/**`, service worker, FCM web integration
- Description: Add browser push support with permission UX, token lifecycle management, and deep-link behavior aligned with mobile.
- Acceptance Criteria: web push works in supported browsers and routes users to the correct destination.
- Testing: manual browser push verification in Chrome, Safari, and Firefox where supported.
- Status: done
- Evidence: `docs/reports/notification_audit_web_push_2026-05-30.md`

### NOTIF-005 - Make web push registration and delivery production-valid
- Files: `/Users/ace/crush-web/packages/core/src/services/notification.ts`, service worker, notification settings, backend token/pref handlers, `firestore.rules`
- Description: Reconcile the implemented web push client with production App Check, Firestore rules, canonical token metadata, preference enforcement, and real browser delivery evidence.
- Dependencies: `SEC-FE-004`, `DB-004`, `API-008`
- Acceptance Criteria:
  - Web token create/refresh/revoke uses a rules-supported or backend-managed canonical path.
  - Token metadata and notification preferences use one documented schema across clients/backend.
  - Every backend notification category maps to an existing web/mobile destination or an explicit fallback.
  - Permission education, denial, revocation, expired-token cleanup, and logout cleanup are handled.
  - Supported-browser matrix and limitations are documented.
- Testing:
  - Rules/backend tests for token lifecycle and preference enforcement.
  - Notification route tests for foreground, background, and closed states.
  - Staging delivery checks in supported Chrome, Safari, and Firefox configurations.
- Status: open — P0 production-validation follow-up; `NOTIF-004` implementation alone is not sufficient evidence.
