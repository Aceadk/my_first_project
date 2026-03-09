# TODO: Store Apple Module

Priority: P0-P1

This document tracks Apple App Store compliance and in-app purchase remediation.

## Tasks

### STORE-APL-003 - Server-Side Apple Receipt Validation
- Files: `functions/src/index.ts`, `functions/src/subscription/*`
- Description: Implement App Store Server API receipt validation and persist authoritative subscription state.
- Acceptance Criteria:
  - callable or REST endpoint verifies Apple transaction/receipt payloads.
  - validation result updates subscription plan/status/renewal metadata in Firestore.
  - duplicate transaction protections are applied.
- Testing:
  - function unit tests with mocked Apple API responses
  - integration test with sandbox payload fixtures
- Status: completed

### STORE-APL-004 - Restore Purchases Compliance Flow
- Files: `lib/features/subscription/presentation/*`, `lib/features/settings/presentation/screens/settings_screen.dart`
- Description: Implement Apple-compliant restore flow that verifies restored purchases server-side and surfaces clear user feedback.
- Acceptance Criteria:
  - restore action is accessible in subscription UI/settings.
  - restored transactions are verified by backend before entitlement activation.
  - empty restore and restore error states are handled.
- Testing:
  - widget test for restore states
  - manual iOS sandbox restore validation
- Status: completed

### STORE-APL-005 - Apple Subscription Review Metadata Checklist
- Files: `docs/STORE_ASSETS.md`, `docs/RELEASE_GUIDE.md`
- Description: Ensure Apple-required subscription disclosure text and review metadata are present and consistent with in-app paywall copy.
- Acceptance Criteria:
  - pricing/renewal terms, cancellation info, privacy policy, and terms links are present.
  - review notes include test account and subscription review guidance.
  - screenshots and metadata checklist include subscription screens.
- Testing:
  - manual checklist validation against App Store Connect requirements
- Status: completed

## Notes

- In-App Purchase capability is configured through Apple Developer/App Store Connect and Xcode target capabilities. It is not represented as an app entitlement key in this project.
- `STORE-APL-001` is dependency-level setup only; purchase flow implementation is tracked in `STORE-APL-002` and `TODO_SUBSCRIPTION.md` (`SUB-002` through `SUB-010`).
