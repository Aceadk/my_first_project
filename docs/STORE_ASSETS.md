# CrushHour Store Assets

This document contains all the text content and asset specifications needed for App Store and Google Play Store listings.

## App Information

| Field | Value |
|-------|-------|
| App Name | Crush|
| Bundle ID (iOS) | com.ace.crush |
| Package Name (Android) | com.ace.crush |
| Category | Social Networking / Dating |
| Age Rating | 17+ (iOS) / Mature 17+ (Android) |

## App Store Listing

### Title (30 characters max)
```
CrushHour - Dating & Friends
```

### Subtitle (30 characters, iOS only)
```
Find Your Perfect Match
```

### Short Description (80 characters)
```
Meet real people nearby. Swipe, match, and chat with verified singles in your area.
```

### Full Description

```
Find meaningful connections with CrushHour, the dating app that puts authenticity first.

DISCOVER YOUR PERFECT MATCH
Swipe through profiles of verified singles in your area. Our smart matching algorithm learns your preferences to show you compatible people who share your interests and values.

VERIFIED PROFILES
Trust matters in dating. Our multi-level verification system helps you connect with real people:
- Photo verification with selfie matching
- ID verification for enhanced trust
- Premium verified badges

SAFETY FIRST
Your safety is our priority:
- Block and report features
- Content moderation
- Privacy controls
- Incognito mode for discreet browsing

PREMIUM FEATURES
Upgrade to CrushHour Plus for:
- Unlimited likes and super likes
- See who likes you
- Rewind your last swipe
- 7-day message retention
- Priority in discovery

REAL CONNECTIONS
- Send messages before matching with Message Requests
- Video and voice calls with matches
- Voice notes in chat
- Real-time typing indicators

DESIGNED FOR ADULTS
CrushHour is exclusively for adults 18 and older. We take age verification seriously to maintain a safe community.

PRIVACY MATTERS
- End-to-end encrypted messages
- Control who sees your profile
- Delete your data anytime
- No ads

Download CrushHour today and start making real connections!

Terms of Service: https://crushhour.app/terms
Privacy Policy: https://crushhour.app/privacy
```

### Keywords (iOS, 100 characters max)
```
dating,match,love,relationship,singles,meet,chat,swipe,verified,local,nearby,friends,connection
```

### What's New (Release Notes Template)
```
Version X.X.X

NEW FEATURES
- [Feature 1]
- [Feature 2]

IMPROVEMENTS
- [Improvement 1]
- [Improvement 2]

BUG FIXES
- [Fix 1]
- [Fix 2]

We're constantly improving CrushHour. Please rate us if you enjoy the app!
```

## Screenshot Requirements

### iOS Screenshots

| Device | Size | Required |
|--------|------|----------|
| iPhone 6.9" display | 1260 x 2736 / 1290 x 2796 / 1320 x 2868 | Recommended primary |
| iPhone 6.5" display | 1284 x 2778 / 1242 x 2688 | Required if 6.9" set not provided |
| iPad 13" display | 2064 x 2752 / 2048 x 2732 | Required if app runs on iPad |
| iPad 11" display | 1488 x 2266 / 1668 x 2388 | Optional supplemental |

### Android Screenshots

| Type | Size | Required |
|------|------|----------|
| Phone | 16:9 or 9:16 (min 320px) | Yes (2-8) |
| 7" Tablet | 16:9 or 9:16 | No |
| 10" Tablet | 16:9 or 9:16 | No |

### Recommended Screenshot Content

1. **Welcome/Splash** - App logo with tagline
2. **Discovery/Swipe** - Showing a profile card with swipe actions
3. **Matches** - Match list with verification badges
4. **Chat** - Conversation with message features
5. **Profile** - User profile with photos and prompts
6. **Verification** - Verification badge and trust features
7. **Safety** - Safety features and controls
8. **Premium** - Plus subscription benefits

## App Icons

### iOS App Icon
- Size: 1024 x 1024 pixels
- Format: PNG (no alpha/transparency)
- No rounded corners (iOS adds them)

### Android Adaptive Icon
- Foreground: 432 x 432 (with safe zone)
- Background: Solid color #0D0E12
- Legacy icon: 512 x 512

### Icon Files Location
```
assets/icons/
├── app_icon.png              # Base icon (1024x1024)
├── app_icon_foreground.png   # Android adaptive foreground
└── README.md                 # Icon specifications
```

### Generate Icons
```bash
dart run flutter_launcher_icons
```

## Feature Graphic (Android)

- Size: 1024 x 500 pixels
- Format: PNG or JPEG
- Content: App logo, tagline, key visual

## Promotional Video (Optional)

- Duration: 15-30 seconds
- Format: MP4
- Resolution: 1080p or higher
- Content: App demo with key features

## App Review Information

### Demo Account (App Store + Google Play review)
```
Email: demo@crushhour.app
Password: [Provide during submission]
```

### Notes for Reviewer
```
CrushHour is a dating app for adults 18 and older.

Demo Account Usage:
- The demo account is pre-configured with matches for testing
- You can test swiping, matching, and messaging features
- Video calls require two devices

Age Verification:
- We require users to confirm they are 18+ during signup
- Date of birth is collected during onboarding
- Users under 18 cannot create accounts

Content Moderation:
- All content is moderated for safety
- Users can block and report inappropriate behavior
- We have 24/7 moderation support

In-App Purchases:
- CrushHour Plus subscription ($9.99/month)
- Provides unlimited likes, see who likes you, etc.
```

### App Store Subscription Disclosure (Required In-App)

Use this disclosure template in paywall/checkout UI and keep it aligned with App Store Connect subscription metadata:

```
CrushHour Plus (Auto-Renewable Subscription)
- Title: CrushHour Plus
- Length: 1 month
- Price: $9.99 per month (or local equivalent shown by Apple)
- Billing: Payment is charged to Apple ID at confirmation of purchase
- Renewal: Subscription auto-renews unless canceled at least 24 hours before the end of the current period
- Renewal charge timing: Account is charged for renewal within 24 hours prior to period end
- Manage/cancel: Manage or cancel in Settings > Apple ID > Subscriptions
- Terms: https://crushhour.app/terms
- Privacy: https://crushhour.app/privacy
```

### App Store Subscription Review Notes (App Review Information)

Add this to **App Store Connect > App Review Information > Notes**:

```
Subscription review guidance:
- Product: CrushHour Plus (auto-renewable, monthly).
- Price baseline in app: $9.99/month (localized price shown by App Store at purchase).
- Test path:
  1) Log in with demo account credentials listed above.
  2) Navigate to Profile > Settings > Subscription.
  3) Tap "Upgrade to Plus" to open the native StoreKit purchase sheet.
  4) Tap "Restore Purchases" to verify restored entitlement handling.
- If additional environment/test account details are needed, use Notes field updates before submission.
```

### App Store In-App Purchase Metadata Checklist

Before submitting, verify each subscription item in App Store Connect:
- [ ] Subscription display name and description are complete and reviewer-ready
- [ ] Subscription duration and pricing are configured and match in-app copy
- [ ] Review screenshot is uploaded for subscription review
- [ ] Subscription status is `Ready to Submit` before sending to review
- [ ] First subscription/new subscription type is attached to a new app version submission

### Google Play Reviewer Instructions (App Access form)

Use this block in **Play Console > App content > App access**:

```
App access required: Yes

Instruction set #1 (Core app):
1) Open CrushHour and tap "Log In".
2) Use demo@crushhour.app / [submission password].
3) Complete onboarding prompts if shown.
4) Navigate Discovery, Matches, and Chat from the bottom nav.

Instruction set #2 (Subscription flow):
1) Go to Profile > Settings > Subscription.
2) Tap "Upgrade to Plus" to open native Google Play purchase sheet.
3) Use a Play license tester account for purchase simulation.
4) Restore path: Settings > Subscription > Restore Purchases.
```

### Google Play Subscription Disclosure (Listing + In-App Copy)

Keep this copy consistent across:
- Play Store listing description
- In-app paywall/checkout copy
- Policy declarations and reviewer notes

```
CrushHour Plus
- Price: $9.99 per month (or local equivalent shown by Google Play)
- Billing cycle: Monthly recurring subscription
- Renewal: Auto-renews until canceled
- Cancellation: Manage or cancel anytime in Google Play Subscriptions
- Access: Plus features remain active until the current paid period ends
- Terms: https://crushhour.app/terms
- Privacy: https://crushhour.app/privacy
```

### Google Play App Content Declarations Checklist

Before submitting a release, confirm all required Play Console forms are current:
- [ ] Ads declaration (Yes/No, matches actual app behavior)
- [ ] App access instructions (valid login and flow steps)
- [ ] Data safety form (data collection/sharing + security practices)
- [ ] Content rating questionnaire (IARC) completed
- [ ] Target audience + content section completed
- [ ] Sensitive permissions declarations (if any) completed
- [ ] Financial features / billing disclosures reviewed for subscription terms

## Support Information

| Field | Value |
|-------|-------|
| Support URL | https://crushhour.app/support |
| Support Email | support@crushhour.app |
| Privacy Policy | https://crushhour.app/privacy |
| Terms of Service | https://crushhour.app/terms |
| Marketing URL | https://crushhour.app |

## Content Rating

### iOS Age Rating
- Age Rating: 17+
- Reasons: Infrequent/Mild Mature/Suggestive Themes

### Android Content Rating
- IARC Rating: Mature 17+
- Content Descriptors: Users Interact, In-App Purchases

## Localization

Currently supported languages:
- English (en) - Primary

Planned languages:
- Spanish (es)
- French (fr)
- German (de)
- Portuguese (pt)

## Store Listing Updates Checklist

Before each release:
- [ ] Update version number in description if shown
- [ ] Update "What's New" section
- [ ] Add new screenshots if UI changed significantly
- [ ] Update keywords if features changed
- [ ] Verify all URLs are working
- [ ] Test demo account is accessible
- [ ] Verify App Review demo account credentials are valid and do not expire
- [ ] Verify iOS paywall includes title/length/price + Terms/Privacy links
- [ ] Verify iOS paywall includes renewal/cancellation disclosures
- [ ] Verify Plus pricing text matches in-app paywall (`$9.99/month` current baseline)
- [ ] Verify recurring billing/auto-renew/cancel disclosure is visible before purchase
