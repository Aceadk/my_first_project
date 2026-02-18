# TODO: Notifications Module
**Priority:** P1 – High
**Estimated Effort:** 25-35 hours
**Dependencies:** FCM setup (already configured), Cloud Functions
**Assigned:** AI + Developer

---

## NOTIF-001: Build In-App Notification Center
**Files:** `lib/features/notifications/presentation/screens/notification_center_screen.dart` (new), `lib/core/routing/crush_routes.dart`
**Description:** No in-app notification center exists. Users only receive push notifications with no persistent history. Build a notification center screen showing: new matches, messages, likes, profile views, system announcements. Accessible from home screen badge icon.
**Acceptance Criteria:**
- [ ] `NotificationCenterScreen` with grouped notifications: Today, This Week, Earlier
- [ ] Notification types: match, message, like, profile_view, system, boost_expired, weekly_picks
- [ ] Unread indicator (badge) on home screen navigation
- [ ] Mark as read on tap; mark all as read button
- [ ] Tap navigates to relevant screen (match → chat, like → profile)
- [ ] Pull-to-refresh and pagination (20 per page)
- [ ] Route registered at `/notifications`
**Testing:** Widget test for notification list rendering; Cubit test for state management; navigation test for deep links.

---

## NOTIF-002: Implement Notification Category Filtering
**Files:** `lib/features/settings/presentation/screens/notifications_settings_screen.dart`, `lib/core/services/push_notification_service.dart`
**Description:** Notification settings currently show basic toggles. Add category-based filtering: matches, messages, likes, profile views, promotions, safety alerts. Each category can be independently enabled/disabled.
**Acceptance Criteria:**
- [ ] Category toggles: Matches, Messages, Likes, Profile Views, Promotions, Safety Alerts
- [ ] Toggles persisted in Firestore `users/{uid}/preferences/notifications`
- [ ] Cloud Functions check user preferences before sending push
- [ ] Safety alerts cannot be disabled (always on)
- [ ] Settings tile subtitle shows "X of Y enabled"
**Testing:** Widget test for toggle states; Cloud Function test for preference checking.

---

## NOTIF-003: Add Rich Push Notifications with Media
**Files:** `lib/core/services/push_notification_service.dart`, `ios/Runner/NotificationService/` (new), `android/app/src/main/`
**Description:** Push notifications are text-only. Add rich notifications with: profile photos for match/like notifications, message preview for chat notifications, action buttons (Reply, Like Back).
**Acceptance Criteria:**
- [ ] iOS: Notification Service Extension for media attachments
- [ ] Android: BigPictureStyle for photo notifications
- [ ] Match notification shows matcher's profile photo
- [ ] Message notification shows sender's avatar + message preview
- [ ] Action buttons: "Reply" (inline reply), "Like Back" (for like notifications)
- [ ] Image caching for notification media
**Testing:** Manual test on both platforms; verify images load in notification shade.

---

## NOTIF-004: Implement Smart Notification Scheduling
**Files:** `functions/src/notifications/scheduler.ts` (new), `functions/src/index.ts`
**Description:** Notifications should respect user's local time and avoid notification fatigue. Implement: quiet hours (configurable, default 10PM-8AM), batching (group multiple likes into one notification), and smart frequency capping.
**Acceptance Criteria:**
- [ ] Quiet hours: notifications queued during user's quiet hours, delivered after
- [ ] Batching: "You have 5 new likes" instead of 5 separate notifications
- [ ] Frequency cap: max 10 non-message notifications per day
- [ ] User timezone stored in profile for scheduling
- [ ] Messages always delivered immediately (no batching/delay)
**Testing:** Cloud Function tests for scheduling logic; timezone edge case tests.

---

## NOTIF-005: Fix Notification Deep Linking on iPad
**Files:** `lib/core/services/push_notification_service.dart`, `lib/core/routing/crush_routes.dart`
**Description:** Notification deep links may not work correctly with iPad split-view navigation. When tapping a notification on iPad, ensure the correct panel updates in master-detail layouts.
**Acceptance Criteria:**
- [ ] Notification tap opens correct screen on both iPhone and iPad
- [ ] On iPad: notification opens in detail panel (not full navigation push)
- [ ] Background notification tap restores correct navigation state
- [ ] Cold start notification tap navigates after app initialization
**Testing:** Manual test on iPad: tap notification → verify correct screen opens in split view.
