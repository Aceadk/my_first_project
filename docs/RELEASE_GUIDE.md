# CrushHour Release Guide

This guide covers the complete release process for Android (Google Play) and iOS (App Store).

## Prerequisites

### Android
- Java 17+ installed
- Android SDK with build-tools
- Release keystore (`crushhour-release.keystore`)
- `android/key.properties` configured
- Google Play Console access

### iOS
- macOS with Xcode 15+
- Apple Developer account ($99/year)
- Certificates and provisioning profiles configured
- App Store Connect access

## Environment Configuration

### 1. Create Production Environment Variables

Copy and configure environment files:

```bash
# App environment
cp .env.example .env
# Edit with production values

# Firebase Functions environment
cd functions
cp .env.example .env
# Edit with production values
```

### 2. Build-Time Configuration

Use `--dart-define` flags for production builds:

```bash
flutter build appbundle --release \
  --dart-define=FLAVOR=production \
  --dart-define=AGORA_APP_ID=your_agora_id \
  --dart-define=ENABLE_ANALYTICS=true \
  --dart-define=ENABLE_CRASHLYTICS=true \
  --dart-define=ENFORCE_APP_CHECK=true
```

## Android Release (Google Play Store)

### 1. Generate Android App Bundle (AAB)

```bash
# Clean and build
flutter clean
flutter pub get
flutter build appbundle --release --dart-define=FLAVOR=production

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 2. Test the AAB Locally

```bash
# Install bundletool (one time)
brew install bundletool

# Create APKs from AAB for testing
bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=build/app/outputs/bundle/release/app-release.apks \
  --ks=../crushhour-release.keystore \
  --ks-key-alias=crushhour \
  --ks-pass=pass:crushhour123

# Install on connected device
bundletool install-apks --apks=build/app/outputs/bundle/release/app-release.apks
```

### 3. Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select CrushHour app
3. Go to **Release > Production > Create new release**
4. Upload the AAB file
5. Add release notes
6. Submit for review

### 4. Google Play Store Listing Requirements

| Asset | Dimensions | Format |
|-------|-----------|--------|
| Feature Graphic | 1024 x 500 | PNG/JPEG |
| Icon | 512 x 512 | PNG (32-bit) |
| Phone Screenshots (2-8) | 16:9 or 9:16 | PNG/JPEG |
| Tablet Screenshots (optional) | 16:9 or 9:16 | PNG/JPEG |

Required text:
- App Title (max 30 chars): "CrushHour - Dating & Friends"
- Short Description (max 80 chars)
- Full Description (max 4000 chars)
- Privacy Policy URL: https://crushhour.app/privacy

## iOS Release (App Store)

### 1. Configure Xcode Project

```bash
# Update pods
cd ios
pod install --repo-update
cd ..
```

Verify in Xcode:
- Bundle Identifier: `com.ace.crush`
- Development Team: `6792W23U3C`
- Signing configured for Release

### 2. Build iOS

```bash
flutter build ios --release --dart-define=FLAVOR=production
```

### 3. Create Archive in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Product > Destination > Any iOS Device**
3. Select **Product > Archive**
4. Wait for archive to complete
5. In Organizer, click **Distribute App**
6. Choose **App Store Connect** > **Upload**

### 4. App Store Connect Configuration

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create app record if new
3. Configure:
   - App Information (name, category, privacy)
   - Pricing and Availability
   - App Store listing (screenshots, description)
   - Review Information

### 5. App Store Asset Requirements

| Asset | iPhone | iPad (optional) |
|-------|--------|-----------------|
| Screenshots | 6.7" & 5.5" required | 12.9" & 11" |
| App Icon | 1024 x 1024 (no alpha) | Same |
| Preview Videos | Up to 30s | Same |

Required:
- Privacy Policy URL
- Support URL
- Age Rating questionnaire
- Sign in with Apple (if social login offered)

## Version Management

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1  # version+buildNumber
```

- **version**: User-visible (e.g., 1.0.0)
- **buildNumber**: Internal, must increment for each upload

## Pre-Release Checklist

### Code Quality
- [ ] `flutter analyze` reports no issues
- [ ] All tests passing
- [ ] No debug code in release build
- [ ] Crashlytics enabled
- [ ] Analytics enabled

### Configuration
- [ ] Firebase production project configured
- [ ] App Check enabled
- [ ] Environment variables set
- [ ] API endpoints pointing to production

### Legal Compliance
- [ ] Privacy Policy URL accessible
- [ ] Terms of Service URL accessible
- [ ] Age gate (18+) implemented
- [ ] GDPR/CCPA compliance
- [ ] Content moderation active

### Store Requirements
- [ ] App icons generated (all sizes)
- [ ] Screenshots prepared
- [ ] Store description written
- [ ] Support email configured
- [ ] Privacy Policy URL provided

## Troubleshooting

### Android

**Build fails with signing error:**
```bash
# Verify key.properties exists and keystore path is correct
cat android/key.properties
ls -la /path/to/keystore
```

**AAB too large:**
```bash
# Analyze APK size
flutter build apk --analyze-size
```

### iOS

**Code signing error:**
1. Open Xcode preferences > Accounts
2. Download manual provisioning profiles
3. In project settings, select correct team and profile

**Archive fails:**
- Clean build folder: Product > Clean Build Folder
- Delete Derived Data
- Reinstall pods: `cd ios && pod deintegrate && pod install`

## Post-Release

1. Monitor Crashlytics for crashes
2. Check Analytics for user metrics
3. Respond to user reviews
4. Plan next version updates

## Quick Commands

```bash
# Build Android AAB
./scripts/build_release.sh android

# Build iOS
./scripts/build_release.sh ios

# Build both
FLAVOR=production ./scripts/build_release.sh all
```
