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

Canonical key reference:
- App/web-shell keys: `docs/ENV_KEY_MATRIX.md`
- Functions keys: `functions/.env.example`

Legacy aliases (`APP_ENV`, `CRUSH_API_BASE_URL`, `USE_EMULATORS`, `EMULATOR_HOST`) are migration-only and should not be used in new release commands.

### 2. Build-Time Configuration

Use `--dart-define` flags for production builds:

```bash
flutter build appbundle --release \
  --dart-define=FLAVOR=production \
  --dart-define=API_BASE_URL=https://us-central1-crushhour.cloudfunctions.net \
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

### 3. Upload to Internal Testing First

1. Go to [Google Play Console](https://play.google.com/console)
2. Select CrushHour app
3. Open **Release > Testing > Internal testing**
4. Create a release and upload the AAB
5. Add release notes and save
6. Add/confirm internal testers (up to 100)
7. Roll out to internal testing and verify install + purchase/restore flows

### 4. Complete Play Console App Content Declarations

Before production submission, verify **Policy and programs > App content** is current:
- Ads declaration
- App access (reviewer login instructions)
- Data safety
- Content rating
- Target audience and content
- Sensitive permissions declarations (if used)

### 5. Add Reviewer App Access Instructions

In **App content > App access**, provide working credentials and exact steps:
- Demo account email/password
- Navigation path to core features (Discovery, Matches, Chat)
- Navigation path to subscription screen and restore action
- Any environment/test constraints (for example, license tester account for billing tests)

### 6. Google Play Store Listing Requirements

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

### 7. Subscription Compliance Check (Google Play)

Ensure recurring billing disclosures are aligned between listing and in-app checkout:
- Product name: `CrushHour Plus`
- Price: `$9.99/month` baseline (localized price may vary in Play)
- Recurrence: monthly auto-renewing subscription
- Cancellation path: Google Play Subscriptions management
- Terms URL: https://crushhour.app/terms
- Privacy URL: https://crushhour.app/privacy

Pricing shown in app must match the billed Play price configuration for the same product period.

### 8. Production Rollout

1. Open **Release > Production > Create new release**
2. Promote the validated build from testing (or upload the final AAB)
3. Confirm release notes + country/track configuration
4. Submit for review
5. Plan for review time (some updates may take up to 7 days)

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
   - In-App Purchases and Subscriptions (group, products, pricing)
   - App Store listing (screenshots, description)
   - Review Information (demo credentials + reviewer notes)

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

### 6. Subscription Compliance Check (App Store)

For auto-renewable subscriptions, verify in-app and metadata consistency:
- Product title, length, and price are clearly displayed in paywall/checkout UI
- Auto-renewal behavior and cancellation path are disclosed before purchase
- Terms of Service and Privacy Policy links are visible before purchase
- In-app price text matches current App Store Connect subscription pricing
- Subscription review screenshot and review notes are provided in App Store Connect

### 7. App Review Submission Checklist (iOS)

Before sending to review:
- App Review demo account credentials work and do not expire
- Review Notes include exact path to subscription screen and restore flow
- First subscription/new subscription type is attached to an app version submission
- Subscription status in App Store Connect is `Ready to Submit`
- Any gated/test-only behavior is explained in Review Notes

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
- [ ] `scripts/check_env_alias_migration_status.sh` passes (no deprecated alias emitters in release/CI paths)
- [ ] `scripts/generate_env_alias_migration_audit_report.sh` generated and archived under `docs/reports/`
- [ ] Production cutover ticket created from `docs/PRODUCTION_CUTOVER_TICKET_TEMPLATE.md` and validated with `scripts/check_release_cutover_ticket_contract.sh <ticket-path>`

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
- [ ] App Store subscription title/length/price and legal links are shown in-app
- [ ] App Store Review Notes include test account + subscription test steps
- [ ] App Store subscription metadata is `Ready to Submit` with review screenshot
- [ ] Play App content declarations are complete and current
- [ ] Reviewer app-access instructions are valid and tested
- [ ] Subscription disclosure copy matches in-app checkout wording

## Operator Runbook: Env Alias Migration Go/No-Go

This runbook is mandatory before production cutover and uses the Pass 19 audit artifact format.

### Run

```bash
scripts/generate_env_alias_migration_audit_report.sh
```

Expected output file:
- `docs/reports/ENV_ALIAS_MIGRATION_AUDIT_YYYY-MM-DD.md`

Create cutover ticket from template and validate it:

```bash
scripts/create_production_cutover_ticket.sh
# Fill remaining real values (owner/build links/approvals), then validate.
scripts/check_release_cutover_ticket_contract.sh docs/reports/PRODUCTION_CUTOVER_$(date -u +%F).md
```

CI release-ref gate:
- For release branches/tags, CI runs `scripts/check_release_cutover_ticket_release_ref_gate.sh`.
- Optional override for non-standard ticket path: set repo variable `RELEASE_CUTOVER_TICKET_PATH`.

### Go/No-Go Criteria

| Gate | GO (required) | NO-GO (block release) |
| --- | --- | --- |
| Artifact recency | Artifact date matches release day or was regenerated after the last release-config change. | Missing artifact or stale artifact date. |
| Top-level statuses | `Checkpoint status: PASS` and `Allowlist guard status: PASS`. | Either status is `FAIL`. |
| Checkpoint evidence | `Checkpoint Output` includes `Env alias migration checkpoint passed.` | Missing checkpoint-pass line or script error text. |
| Allowlist evidence | `Allowlist Guard Output` includes `Deprecated env alias guard passed.` | Missing allowlist-pass line or alias violations reported. |
| Milestone semantics | After `2026-06-30`, output should show freeze checkpoint active. After `2026-09-30`, checkpoint must pass with no legacy compatibility references remaining. | Any post-milestone mismatch, alias emitter hit, or legacy-reference failure reported by checkpoint script. |
| Cutover ticket evidence | `scripts/check_release_cutover_ticket_contract.sh <ticket-path>` passes with exact dated audit artifact reference. | Missing/invalid dated artifact reference, missing `PASS` statuses, or referenced artifact file not found. |
| Release-ref CI gate | On `release*` branches and release tags (`v*`, `release-*`), CI gate `scripts/check_release_cutover_ticket_release_ref_gate.sh` passes. | Release ref detected and concrete ticket validation fails or no ticket path can be resolved. |

### Release Log Note (Required)

Record the audited file and result in the release ticket/notes, for example:

`docs/reports/ENV_ALIAS_MIGRATION_AUDIT_2026-03-11.md (checkpoint=PASS, allowlist=PASS)`

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
