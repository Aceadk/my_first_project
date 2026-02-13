# Security Audit Report -- CRUSH Dating App
**Date:** 2026-02-12
**Auditor:** AI (Claude Opus 4.6)
**Scope:** Flutter mobile app, Firebase backend, Next.js web app
**Overall Security Score: 7.5/10**

---

## 1. Executive Security Summary

The CRUSH dating app demonstrates a solid security foundation with multiple layers of protection including Firebase Authentication, end-to-end encryption for chat, secure token handling, GDPR compliance infrastructure, and rate limiting. The primary security gaps are infrastructure configuration issues (Firebase Storage not initialized, Play Integrity not configured) and enforcement gaps (App Check monitoring only, email verification soft-enforced, chat media access too broad).

### Score Breakdown
| Security Domain | Score | Weight | Weighted |
|-----------------|-------|--------|----------|
| Authentication & Authorization | 8.5/10 | 25% | 2.13 |
| Data Encryption & Privacy | 8.5/10 | 20% | 1.70 |
| Secrets Management | 7.5/10 | 15% | 1.13 |
| Input Validation | 7.0/10 | 10% | 0.70 |
| Storage Security | 6.0/10 | 10% | 0.60 |
| Infrastructure Security | 5.5/10 | 10% | 0.55 |
| Logging & Monitoring | 7.5/10 | 10% | 0.75 |
| **Weighted Total** | | **100%** | **7.55/10** |

---

## 2. Authentication & Authorization Assessment (8.5/10)

### Strengths
- **Multi-method authentication** via Firebase Auth: email/password, phone OTP, magic link, Sign in with Apple
- **Sign in with Apple implemented** (`sign_in_with_apple` package) -- required for App Store when offering social login
- **Age gate (18+)** at signup entry point with non-dismissible dialog
- **Session management** via SessionBloc with proper auth state tracking
- **Rate limiting on auth endpoints:**
  - OTP Request: 5/10min, 20min block
  - OTP Verify: 10/10min, 20min block
  - Login: 8/10min, 20min block
  - Signup: 5/10min, 20min block
  - Password Reset: 5/10min, 20min block
- **Account security screens:** email protection, phone protection, change email, new device verification
- **HttpOnly auth cookie** for web app (CSRF protection via Origin/Referer verification)

### Findings
| ID | Severity | Finding | Status |
|---|---|---|---|
| SEC-AUTH-001 | P2 | Email verification is soft-enforced. Users can access features without verifying email. | OPEN |
| SEC-AUTH-002 | P0 | Android Play Integrity not configured for App Check attestation. | OPEN |
| SEC-AUTH-003 | P2 | App Check in monitor mode for most endpoints (ENFORCE_APP_CHECK partially enabled). | OPEN |
| SEC-AUTH-004 | INFO | Firebase Auth handles token refresh, revocation, and session persistence automatically. | OK |

### Recommendations
1. **P0:** Configure Android Play Integrity in Play Console and Firebase Console
2. **P2:** Add server-side email verification check (`auth.token.email_verified`) to sensitive Cloud Functions
3. **P2:** Audit all callable functions for `verifyAppCheck()` coverage; enable enforcement

---

## 3. Secrets Management (7.5/10)

### Strengths
- **Migrated to `defineSecret()`** for Cloud Functions secrets (Stripe, Agora, OTP keys)
- **Flutter Secure Storage (v10)** for sensitive client-side data (encrypted keychain/keystore)
- **No hardcoded API keys** in Flutter source code (Firebase config via google-services.json / GoogleService-Info.plist)
- **Environment variables** for web app Firebase config (NEXT_PUBLIC_FIREBASE_*)
- **`.env.example`** provided without actual secret values

### Findings
| ID | Severity | Finding | Status |
|---|---|---|---|
| SEC-SEC-001 | P1 | Web `.env` files previously contained tab characters in API keys, causing auth failures. | RESOLVED |
| SEC-SEC-002 | INFO | Firebase config values are not truly secret (public API keys are expected in Firebase). | OK |
| SEC-SEC-003 | INFO | Stripe secret key managed via `defineSecret()` in Cloud Functions (not exposed to client). | OK |

### Recommendations
1. Rotate any keys that may have been exposed during the `.env` contamination incident
2. Add secret scanning to CI pipeline (e.g., `gitleaks` or GitHub secret scanning)
3. Document secret rotation procedures

---

## 4. Input Validation Assessment (7.0/10)

### Strengths
- **Content moderation service** with profanity filtering (includes leetspeak bypass detection)
- **Personal info detection** (phone numbers, email addresses, social handles in bios/messages)
- **Spam pattern detection** in user-generated content
- **Harassment/threat detection** in messages
- **Age validation** (18-75 range) during onboarding
- **Stripe checkout validation** -- client-controlled discount percent removed; uses Stripe-native `allow_promotion_codes`
- **Rate limiting on report/block operations:**
  - Report: 10/hour, 2-hour block
  - Block: 20/hour, 1-hour block
  - Unblock: 30/hour, 30-min block

### Findings
| ID | Severity | Finding | Status |
|---|---|---|---|
| SEC-VAL-001 | P2 | Inconsistent input validation patterns across features (some use form validators, others rely on backend). | OPEN |
| SEC-VAL-002 | INFO | Profanity filter normalization bug (R-125) was discovered and fixed. | RESOLVED |
| SEC-VAL-003 | P1 | Stripe checkout security vulnerability (client-controlled discount percent) was fixed. | RESOLVED |

### Recommendations
1. Standardize input validation with shared validators for common fields (email, phone, name, bio)
2. Add server-side validation for all user input that reaches Cloud Functions
3. Implement file type and size validation for all media uploads

---

## 5. Data Privacy Assessment -- GDPR & PII (8.5/10)

### Strengths
- **GDPR consent infrastructure:**
  - `ConsentService` for managing user consent with SharedPreferences persistence
  - Cookie consent banner on web (accept/decline, localStorage persistence)
  - App Tracking Transparency (ATT) framework integration for iOS
  - `TrackingConsentService` for tracking status management
- **Data export capability** via `DataExportService` (user data, profile, preferences, matches, messages)
- **Account deletion flow** available in settings
- **Privacy controls:**
  - Name visibility settings (public/private)
  - Incognito mode for discovery
  - Discovery hide option
  - Privacy settings cubit with granular controls
- **iOS Privacy Manifest** (`PrivacyInfo.xcprivacy`) properly configured and added to Xcode build:
  - Declares UserDefaults, FileTimestamp, SystemBootTime, DiskSpace API usage
  - Declares collected data types: Name, Email, Phone, DOB, Photos, Location, UserID
- **Legal pages** accessible in-app and via public URLs:
  - Privacy Policy: `https://crushhour.app/privacy`
  - Terms of Service: `https://crushhour.app/terms`
- **User data clearance on logout** via `UserDataClearanceService`
- **Secure logging** prevents PII and tokens from appearing in logs

### Findings
| ID | Severity | Finding | Status |
|---|---|---|---|
| SEC-PRIV-001 | P1 | Account deletion completeness not verified across Firestore/RTDB/Storage. | OPEN |
| SEC-PRIV-002 | INFO | Data export covers user, profile, preferences, matches, and messages. | OK |
| SEC-PRIV-003 | INFO | GDPR cookie consent implemented for web. | OK |
| SEC-PRIV-004 | P2 | DOB and distance exposed for non-matched likes (R-007). | OPEN (Monitoring) |

### Recommendations
1. **P1:** Verify and document complete data deletion flow across all Firebase services
2. **P2:** Consider showing age instead of DOB for non-matched profiles
3. Add data retention policy documentation
4. Implement data processing agreement (DPA) template for third-party services

---

## 6. Storage Security Assessment (6.0/10)

### Strengths
- **Firestore security rules** enforce authentication for all reads/writes
- **Storage rules** exist for profile photos, videos, and chat media with user-scoped paths:
  - `users/{uid}/photos/{fileName}` -- owner write, authenticated read
  - `users/{uid}/videos/{fileName}` -- owner write, authenticated read
  - `chat_media/{matchId}/{userId}/{fileName}` -- authenticated read/write
- **Rule null-safety** handles both flat (web) and nested (mobile) document structures
- **File size limits** enforced in storage rules

### Findings
| ID | Severity | Finding | Status |
|---|---|---|---|
| SEC-STOR-001 | P0 | Firebase Storage NOT INITIALIZED for production project `crush-265f7`. | OPEN -- BLOCKER |
| SEC-STOR-002 | P2 | Chat media read rules do not verify match membership. Any authenticated user can read `chat_media/{matchId}/*` if they know the matchId. | OPEN |
| SEC-STOR-003 | P2 | Flat vs nested Firestore doc structure (R-124) creates rule complexity; every new rule must handle both. | MITIGATED |
| SEC-STOR-004 | INFO | Legacy storage paths maintained for backward compatibility. | OK |

### Recommendations
1. **P0:** Enable Firebase Storage in Console immediately
2. **P2:** Add match membership check to chat media storage rules:
   ```
   allow read: if request.auth != null
     && exists(/databases/$(database)/documents/matches/$(matchId))
     && request.auth.uid in get(/databases/$(database)/documents/matches/$(matchId)).data.userIds;
   ```
3. Plan for normalizing Firestore document structure (flat vs nested)

---

## 7. Encryption & Transport Security (9.0/10)

### Strengths
- **End-to-end encryption for chat messages:**
  - Algorithm: AES-GCM 256-bit
  - Key derivation: SHA-256(matchId + sorted userIds + pepper)
  - Enabled by default (`_e2eeDefaultEnabled = true`)
  - Handles both encrypted and plain text messages for backward compatibility
  - Can be toggled at runtime via `ChatE2eeToggled` event
  - Environment variable override: `ENABLE_CHAT_E2EE=false`
- **Firebase provides TLS for all transport** (Firestore, Auth, Storage, Functions)
- **Secure Storage** for sensitive client-side data via `flutter_secure_storage` (v10)
  - Uses Keychain on iOS, Encrypted SharedPreferences on Android
- **Certificate pinning capability** via network layer
- **HttpOnly cookies** for web auth tokens (prevents XSS-based token theft)

### Findings
| ID | Severity | Finding | Status |
|---|---|---|---|
| SEC-ENC-001 | INFO | E2EE applies to text messages only; media URLs are not encrypted. | ACCEPTED |
| SEC-ENC-002 | INFO | E2EE key derivation uses match-specific pepper for forward secrecy. | OK |
| SEC-ENC-003 | P2 | Web CSP uses `unsafe-inline` for styles, weakening XSS protection. | OPEN |

### Recommendations
1. Consider encrypting media URLs in chat (not the media content itself, which is at-rest encrypted by Firebase)
2. Migrate CSP to nonce-based for complete XSS protection

---

## 8. Logging & Monitoring Assessment (7.5/10)

### Strengths
- **SecureLogger** (`lib/core/security/secure_logger.dart`):
  - Token redaction: shows `first4...last4 (N chars)` format
  - `logToken()`, `logTokenRefresh()`, `logTokenError()` methods
  - `logAuth()` for safe auth event logging
  - `logSecurityEvent()` for audit-worthy events
  - `_neverLogFullTokens` constant ensuring tokens are always redacted
- **AppLogger** with structured logging (info, error, debug levels)
- **Firebase Analytics** for event tracking
- **Firebase Performance** monitoring
- **Firebase Crashlytics** for crash reporting
- **No token leakage** in auth repositories or network layer (verified)

### Findings
| ID | Severity | Finding | Status |
|---|---|---|---|
| SEC-LOG-001 | P2 | ~260 `debugPrint` statements in production code. While compiled out in release mode, indicates lack of structured logging discipline. | OPEN |
| SEC-LOG-002 | P2 | 25 web source files contain `console.log/console.error` that could leak info in browser console. | OPEN |
| SEC-LOG-003 | INFO | FCM and App Check tokens were previously logged in full. | RESOLVED |

### Recommendations
1. Replace all `debugPrint` with `AppLogger` calls
2. Replace web `console.log` with structured logging utility (disabled in production)
3. Add audit logging for sensitive operations (account deletion, payment events, role changes)

---

## 9. Missing Security Features Checklist

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Multi-factor authentication (MFA) | Not implemented | P3 | Firebase Auth supports MFA; consider for premium users |
| Login attempt notification | Not implemented | P3 | Email/push notification on new device login |
| Biometric auth (Face ID / Touch ID) | Not implemented | P3 | `local_auth` package can be added |
| Password strength meter | Not implemented | P3 | Frontend-only; Firebase handles password hashing |
| Session timeout / auto-logout | Not implemented | P3 | Consider for inactive sessions (30-60 min) |
| IP-based anomaly detection | Not implemented | P3 | Firebase Auth does basic device tracking |
| API request signing | Partial (App Check) | P2 | App Check provides request attestation |
| Content Security Policy (nonce-based) | Partial (unsafe-inline) | P1 | CSP exists but needs nonce-based styles |
| Distributed rate limiting | Partial (in-memory) | P1 | Works per-instance; needs Redis for distributed |
| Email verification enforcement | Partial (client-only) | P2 | Needs server-side check on Cloud Functions |
| Match-membership media access | Not implemented | P2 | Storage rules need match verification |
| Photo EXIF stripping | Not verified | P2 | Check if image_picker strips EXIF data |
| Message retention / auto-delete | Not implemented | P3 | Consider for privacy-sensitive users |
| Security headers (web) | Partial | P2 | CSP present; add X-Frame-Options, X-Content-Type-Options |
| Dependency vulnerability scanning | Not configured | P2 | Add to CI pipeline |

---

## 10. Backend Security Surface

### Cloud Functions Security
| Endpoint Type | Count | Auth Required | Rate Limited | App Check |
|---------------|-------|---------------|--------------|-----------|
| Callable functions | 36 | Yes (all) | Partial | Monitor mode |
| REST endpoints | 29 | Yes (most) | Auth endpoints | No |
| Firestore triggers | 5 | N/A (server) | N/A | N/A |
| Pub/Sub jobs | 2 | N/A (server) | N/A | N/A |
| HTTPS handlers | 2 | Varies | stripeWebhook: Stripe signature | No |

### Rate Limiting Coverage
| Endpoint | Limit | Window | Block Duration |
|----------|-------|--------|----------------|
| OTP Request | 5 | 10 min | 20 min |
| OTP Verify | 10 | 10 min | 20 min |
| Login | 8 | 10 min | 20 min |
| Signup | 5 | 10 min | 20 min |
| Password Reset | 5 | 10 min | 20 min |
| Report User | 10 | 60 min | 120 min |
| Block User | 20 | 60 min | 60 min |
| Unblock User | 30 | 60 min | 30 min |
| Stripe Checkout (web) | 10 | 15 min | N/A |
| Web Session API | 20 | 15 min | N/A |

---

## 11. Threat Model Summary

### High-Value Targets
1. **User PII** (name, email, phone, DOB, photos, location)
2. **Chat messages** (E2EE protected)
3. **Payment data** (handled by Stripe; no PCI scope)
4. **Auth tokens** (Firebase managed; SecureLogger prevents leaks)

### Primary Threat Vectors
| Vector | Risk | Mitigation | Residual Risk |
|--------|------|------------|---------------|
| Credential stuffing | Medium | Rate limiting on auth endpoints | Low |
| API abuse (bots) | Medium | App Check (monitor mode) | Medium (until enforced) |
| XSS (web) | Low | CSP + HttpOnly cookies | Low (unsafe-inline remains) |
| CSRF (web) | Low | Origin/Referer verification | Low |
| Media enumeration | Medium | Auth required for storage | Medium (no match check) |
| Account takeover | Low | Firebase Auth + rate limits | Low |
| Data exfiltration | Low | Firestore rules + auth | Low |
| Insider threat | Medium | Audit logging partial | Medium |

---

## 12. Compliance Status

| Requirement | Status | Notes |
|-------------|--------|-------|
| GDPR (EU) | Partial compliance | Consent, export, deletion present; DPA and retention policy needed |
| CCPA (California) | Partial compliance | Cookie consent; data sale opt-out not explicitly addressed |
| Apple App Store Privacy | Configured | Privacy manifest, ATT, nutrition labels need verification |
| Google Play Data Safety | Not verified | Data safety form alignment needed |
| PCI DSS | Not in scope | Stripe handles all payment card data |
| SOC 2 | Not applicable | Firebase provides SOC 2 compliance for infrastructure |

---

## 13. Recommendations Summary (Priority Order)

### P0 -- Immediate
1. Enable Firebase Storage in Console
2. Configure Android Play Integrity

### P1 -- Within 2 Weeks
3. Migrate CSP to nonce-based (remove `unsafe-inline`)
4. Implement Redis-backed distributed rate limiting
5. Verify account deletion completeness

### P2 -- Within 4 Weeks
6. Enforce email verification server-side
7. Add match-membership to chat media storage rules
8. Enable App Check enforcement on all callables
9. Replace debugPrint with structured logging
10. Add dependency vulnerability scanning to CI
11. Add security headers to web (X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
12. Verify EXIF stripping on uploaded photos

### P3 -- Backlog
13. Consider MFA for premium users
14. Add biometric auth option
15. Implement session timeout
16. Add message auto-delete option
17. Add login attempt notifications
