<p align="center">
  <img src="assets/icons/app_icon.png" alt="Crush app icon" width="160">
</p>

<h1 align="center">Crush</h1>

<p align="center">
  A safety-first dating platform for adults, built with Flutter and Firebase.
</p>

<p align="center">
  <a href="https://github.com/Aceadk/my_first_project/actions/workflows/ci.yml">
    <img src="https://github.com/Aceadk/my_first_project/actions/workflows/ci.yml/badge.svg" alt="CI status">
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter" alt="Flutter 3.35+">
  <img src="https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart" alt="Dart 3.9+">
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black" alt="Firebase backend">
</p>

<p align="center">
  <a href="https://crush.app">Website</a> |
  <a href="https://github.com/Aceadk/crush-web">Web client</a> |
  <a href="docs/API_CATALOG.md">API catalog</a> |
  <a href="docs/RELEASE_GUIDE.md">Release guide</a>
</p>

## Overview

Crush is an 18+ dating product focused on discovery, meaningful matches,
real-time communication, and user safety.

This repository owns:

- the Flutter application for iOS and Android;
- the Firebase backend, security rules, indexes, and scheduled jobs;
- shared domain contracts for auth, profiles, discovery, chat, calls,
  subscriptions, notifications, and account lifecycle;
- automated Flutter, Cloud Functions, rules, and security validation lanes.

The production web experience is a separate Next.js application in
[`Aceadk/crush-web`](https://github.com/Aceadk/crush-web). Both clients are
designed to use the same Firebase project and backend contracts.

## Product Capabilities

| Area                    | Current capability                                                                                                                                                                |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Authentication          | Email/password, email OTP, phone OTP, Google, Apple on native mobile, password reset, email verification, session management, and device verification flows                       |
| Onboarding and profiles | 18+ age gate, terms acceptance, profile prompts, interests, preferences, location, photo/video media, completeness checks, profile editing, and verification UX                   |
| Discovery               | Swipe deck, server-filtered candidates, distance and preference filters, likes, matches, message requests, weekly picks, stories, boosts, incognito, and passport-style discovery |
| Messaging               | Match chat, text/media/voice messages, reactions, typing, presence, read state, message requests, edit/unsend controls, retention settings, pinning, and unmatch                  |
| Safety                  | Block/report flows, safety appeals, moderation hooks, date-safety tools, account controls, private profile settings, and signed access for protected chat media                   |
| Calls                   | Native voice/video call architecture with signaling, Agora token support, CallKit integration, call history, and Picture-in-Picture support                                       |
| Crush Plus              | Native Apple/Google in-app purchases, Stripe support for web/backend paths, promo codes, server-owned entitlements, restore/sync flows, and premium feature gates                 |
| Notifications           | FCM registration, local notifications, notification preferences, deep links, match/message/subscription events, and an in-app notification center                                 |
| Experience              | Feature-first design system, light/dark/luxury themes, Remote Config rollouts, accessibility regression coverage, responsive layouts, and 20+ localization catalogs               |

Some capabilities are controlled by Remote Config, platform support, account
eligibility, or Crush Plus entitlement. Native calling is implemented in code,
but production release still requires provider credentials and real-device
validation for PushKit/CallKit, Android incoming-call behavior, permissions,
PiP, and network recovery.

## Architecture

The app uses feature-first clean architecture with BLoC/Cubit state management,
GoRouter navigation, and repository interfaces that keep presentation code
separate from Firebase and HTTP implementations.

```text
Flutter UI
  -> BLoC / Cubit
    -> domain use cases
      -> repository interfaces
        -> Firebase, HTTP, hybrid, or stub implementations

Firebase platform
  -> Authentication and App Check
  -> Cloud Firestore and Realtime Database
  -> Cloud Storage for Firebase
  -> Cloud Functions and versioned REST API
  -> Cloud Messaging, Remote Config, Analytics, Crashlytics, Performance
```

Firebase is the default runtime backend. HTTP, hybrid, and stub repository modes
remain available for API compatibility, local development, demos, and focused
tests.

## Repository Map

```text
lib/
  core/                 shared routing, DI, security, networking, startup, cache
  design_system/        tokens, themes, reusable components, accessibility
  features/             auth, profile, discovery, chat, calls, safety, settings,
                        subscriptions, notifications, analytics, social features
  l10n/                 ARB catalogs and generated localizations
  app.dart              root providers, router host, lifecycle and deep links
  main.dart             guarded startup and Firebase/platform initialization

functions/
  src/index.ts          callable functions, REST API, triggers, webhooks, jobs
  test/                 isolated backend and security regression suites

firestore.rules         client authorization and protected-field rules
storage.rules           media access, MIME type, ownership, and size rules
database.rules.json     Realtime Database authorization
firestore.indexes.json  production query indexes

test/                   Flutter unit, widget, contract, and regression tests
integration_test/       onboarding, discovery, chat, and safety journeys
docs/                   contracts, architecture, audits, runbooks, release notes
public/                 Firebase Hosting pages and app-link metadata
```

## Technology

- Flutter and Dart
- BLoC/Cubit, GoRouter, and repository-based dependency injection
- Firebase Auth, Firestore, Realtime Database, Storage, Functions, FCM,
  Remote Config, Analytics, Crashlytics, Performance, and App Check
- TypeScript Cloud Functions on Node.js 22
- Apple StoreKit and Google Play Billing through `in_app_purchase`
- Stripe for web/backend subscription compatibility
- Agora-backed native call services
- GitHub Actions for analysis, tests, rules verification, and security guards

## Getting Started

### Prerequisites

- Flutter 3.35 or newer
- Dart 3.9 or newer
- Node.js 22
- Firebase CLI
- Xcode and CocoaPods for iOS development
- Android Studio/SDK for Android development
- Java 21 when running the Firestore emulator lane locally

### Install dependencies

```bash
git clone https://github.com/Aceadk/my_first_project.git
cd my_first_project

flutter pub get
npm --prefix functions ci
```

### Firebase configuration

The maintained project contains platform configuration for its active Firebase
environment. For a fork or a new Firebase project:

```bash
flutterfire configure
firebase use <firebase-project-id>
```

Do not commit service-account JSON, provider secrets, keystores, private keys,
or populated `.env` files.

Cloud Functions environment values belong in `functions/.env`, based on
`functions/.env.example`. Mobile build-time values are supplied with
`--dart-define`; the canonical key list is in
[`docs/ENV_KEY_MATRIX.md`](docs/ENV_KEY_MATRIX.md).

### Run the app

```bash
flutter devices
flutter run -d <device-id>
```

For iOS dependency setup:

```bash
cd ios
pod install
open Runner.xcworkspace
```

### Run with Firebase emulators

Start the emulator services directly from the repository root:

```bash
firebase emulators:start --only auth,functions,firestore
```

In another terminal:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

The app resolves Android emulator networking to `10.0.2.2`; other local
platforms default to `localhost`. Override with
`--dart-define=FIREBASE_EMULATOR_HOST=<host>` when needed.

## Runtime Configuration

| Define                   | Purpose                                            |
| ------------------------ | -------------------------------------------------- |
| `FLAVOR`                 | `development`, `staging`, or `production`          |
| `API_BASE_URL`           | Optional versioned REST API function base URL      |
| `USE_FIREBASE_EMULATOR`  | Routes supported Firebase SDKs to local emulators  |
| `FIREBASE_EMULATOR_HOST` | Overrides the emulator host                        |
| `AGORA_APP_ID`           | Enables configured native call services            |
| `ENABLE_ANALYTICS`       | Controls analytics initialization                  |
| `ENABLE_CRASHLYTICS`     | Controls crash reporting                           |
| `ENABLE_PERFORMANCE`     | Controls performance monitoring                    |
| `ENFORCE_APP_CHECK`      | Enables client-side App Check enforcement behavior |

Feature availability is also managed through Firebase Remote Config and
server-owned subscription entitlements.

## Quality Gates

Run the primary local checks:

```bash
flutter analyze
flutter test

npm --prefix functions run lint
npm --prefix functions test

scripts/check_firestore_rules_sync.sh
```

CI additionally runs startup guards, accessibility regression tests, coverage
artifact checks, dependency audits, release-contract checks, secret scans, and
Firebase Rules validation.

## Deployment

Deploy rules and indexes explicitly to the intended project:

```bash
firebase deploy \
  --only firestore:rules,firestore:indexes,storage,database \
  --project <firebase-project-id>
```

Build and deploy Cloud Functions:

```bash
npm --prefix functions run build
firebase deploy --only functions --project <firebase-project-id>
```

Provider credentials, App Check, APNs/FCM, billing products, authorized domains,
and store signing are external configuration and must be validated before a
production release. Use:

- [`docs/RELEASE_GUIDE.md`](docs/RELEASE_GUIDE.md)
- [`docs/reports/PRODUCTION_CUTOVER_2026-03-11.md`](docs/reports/PRODUCTION_CUTOVER_2026-03-11.md)
- [`docs/PRODUCTION_CUTOVER_TICKET_TEMPLATE.md`](docs/PRODUCTION_CUTOVER_TICKET_TEMPLATE.md)

## Security and Privacy

Security-sensitive behavior is designed to be server-owned:

- Firestore, Realtime Database, and Storage rules restrict client access.
- Entitlements, verification state, matches, moderation, and account lifecycle
  operations are written by trusted backend paths.
- App Check is supported across mobile and backend entry points.
- Authentication tokens and local secrets use secure storage.
- Media uploads enforce ownership, type, and size restrictions.
- Account deletion includes a grace period, cancellation, and data export flow.
- CI includes abuse tests, rules parity checks, secret scans, and dependency
  auditing.

See [`docs/risk_notes.md`](docs/risk_notes.md) and
[`docs/API_CATALOG.md`](docs/API_CATALOG.md) for deeper implementation detail.

## Current Project Status

Crush is actively developed. The maintained source includes substantial
production-oriented behavior and automated coverage, but some release evidence
remains operational rather than purely code-based:

- real-device call validation;
- Apple, Google, Stripe, Agora, APNs, and FCM provider configuration;
- subscription sandbox lifecycle validation;
- App Check enforcement rollout;
- final store review assets, credentials, and release sign-off.

Historical reports and TODO files under `docs/` may describe earlier project
states. Prefer current source, contract documents, and dated release runbooks
when they disagree.

## Documentation

- [API contract catalog](docs/API_CATALOG.md)
- [Design system](docs/DESIGN_SYSTEM.md)
- [Environment key matrix](docs/ENV_KEY_MATRIX.md)
- [Auth system](docs/auth_system.md)
- [Architecture overview](docs/project_understanding.md)
- [Data-flow diagram](docs/project_dfd.md)
- [Entity relationship model](docs/project_er_diagram.md)
- [Release guide](docs/RELEASE_GUIDE.md)
