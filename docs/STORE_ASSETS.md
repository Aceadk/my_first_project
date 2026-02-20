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
| iPhone 15 Pro Max | 1290 x 2796 | Yes |
| iPhone 8 Plus | 1242 x 2208 | Yes |
| iPad Pro 12.9" | 2048 x 2732 | No |
| iPad Pro 11" | 1668 x 2388 | No |

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

### Demo Account (for App Store review)
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
