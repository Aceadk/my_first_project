# Error Handling Module

Priority: P1-P2

This document tracks outstanding remediation and audit actions for the Error Handling domain.

## Audit Summary

### ✅ What's Already Working

- **Global error handlers**: `runZonedGuarded`, `FlutterError.onError`, and isolate error handler are set up in `crash_reporting_service.dart`
- **Crash reporting pipeline**: `AppLogger.error()` → `CrashReportingService.recordError()` → Firebase Crashlytics
- **`AppLogger.error()`** accepts `error:`, `stackTrace:`, and `data:` parameters
- **`rethrow`** used correctly in 20+ places for error propagation
- **`AppLogger.blocError()`** exists for structured BLoC error context

### ⚠️ Systemic Issue

50+ `catch (e) {` blocks across the codebase never capture `StackTrace`. All `AppLogger.error()` calls pass only the error message string — never the actual error object or stack trace. This makes production Crashlytics reports useless for debugging.

## Action Items

### [x] ERR-001: Add stack trace capture to critical repository catch blocks (P1)

- **Description**: Repository-layer catch blocks in notification, subscription, and analytics services log errors as strings without stack traces. This makes production crash reports impossible to diagnose.
- **Affected Files**: `firebase_notification_repository.dart`, `firebase_subscription_repository.dart`, `profile_insights_cubit.dart`
- **Fix**: Change `catch (e)` → `catch (e, s)` and pass both `error: e` and `stackTrace: s` to `AppLogger.error()`.

### [x] ERR-002: Add stack trace capture to profile media service (P1)

- **Description**: `profile_media_service.dart` has 8 catch blocks handling Firebase upload/download errors. None capture stack traces.
- **Affected Files**: `lib/features/profile/data/services/profile_media_service.dart`
- **Fix**: Add `StackTrace` capture to the 4 generic `catch (e)` blocks (the `on FirebaseException` blocks already have structured handling).

### ERR-003: Codebase-wide `catch (e)` → `catch (e, s)` migration (P2) — **DEFERRED**

- **Description**: 50+ remaining catch blocks across the codebase. Low-risk individually but accumulate to make debugging hard.
- **Status**: Deferred to batch migration — not blocking any features.
