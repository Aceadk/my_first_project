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

### ERR-001: Codebase-wide `catch (e)` → `catch (e, s)` migration (P2) — **DEFERRED**

- **Description**: 50+ remaining catch blocks across the codebase. Low-risk individually but accumulate to make debugging hard.
- **Status**: Deferred to batch migration — not blocking any features.
