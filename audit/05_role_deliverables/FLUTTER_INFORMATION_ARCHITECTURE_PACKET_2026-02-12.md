# Flutter + Information Architecture Packet (2026-02-12)

## Architecture Snapshot
- App structure is feature-oriented under `lib/features/*` with cross-cutting code in `lib/core/*`.
- Primary route orchestration in `lib/core/router.dart` using `GoRouter`.
- Auth/onboarding gating is centralized in router redirect logic.

## Navigation Inventory
- Declared route constants: 55 (`audit/raw/mobile_routes_raw.txt`).
- Critical user journey route chain:
- Splash -> Auth Gateway -> Terms -> Basic Info -> Profile Setup -> Email Verification -> Home
- Discovery and messaging routes present: `/likes-you`, `/weekly-picks`, `/chat`, `/message-requests`.

## Information Architecture Risks
- Router file is large and policy-heavy (`lib/core/router.dart`), increasing change risk.
- Multiple onboarding and verification branches increase edge-case complexity.

## Required Remediation
- Split routing policy and route declarations into modular files by domain.
- Add route-level integration tests for every auth/onboarding branch.
- Produce diagram artifact for all route transitions and deep-link entry points.

## Dependency Matrix (Flutter)
- Direct dependencies: 50 (see `audit/raw/pubspec_direct_deps_raw.txt`).
- Outdated baseline: 60 upgradable, 12 constrained below resolvable versions.

## Platform Configuration Checklist (initial)
- iOS/Android directories present.
- Firebase config and rules files present.
- App Tracking Transparency package present (`app_tracking_transparency`).
- Store compliance verification still pending in Phase 2.
