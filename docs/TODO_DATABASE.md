# Database Module

Priority: P1-P2

This document tracks outstanding remediation and audit actions for the Database domain (SharedPreferences, caching, offline queue).

## Action Items

### [x] DB-001: OfflineActionQueue has no max queue size — unbounded growth risk (P1)

- **Description**: `OfflineActionQueue._queue` (Queue) has no size limit. If the device is offline for an extended period, the queue can grow unboundedly, consuming memory and causing `_persist()` to write an increasingly large JSON blob to SharedPreferences.
- **Affected Files**: `lib/core/cache/offline_queue.dart`
- **Fix**: Add a `maxQueueSize` (e.g., 500) and drop the oldest entries when exceeded.

### [x] DB-002: UserDataClearanceService doesn't clear OfflineActionQueue or OfflineCacheService (P1)

- **Description**: `clearAllUserData()` only clears specific SharedPreferences keys and the image cache. It doesn't clear the `OfflineActionQueue` storage key (`offline_action_queue`) or the `OfflineCacheService` profile cache. A new user logging into the same device would see the previous user's queued actions and cached profiles.
- **Affected Files**: `lib/core/services/user_data_clearance_service.dart`
- **Fix**: Add `offline_action_queue` and `offline_profile_cache`/`offline_deck_cache` keys to the clearance list.

### [x] DB-003: `processAll()` doesn't reset `_isProcessing` on exception break (P1)

- **Description**: When `processAll()` catches an exception, it calls `_scheduleRetry()` and `break`s out of the while loop. But `_isProcessing = false` is only set after the loop exits normally. The `break` skips past the `_isProcessing = false` assignment, causing the queue to be permanently stuck in "processing" state until app restart.
- **Affected Files**: `lib/core/cache/offline_queue.dart` (lines 124-177)
- **Fix**: Wrap the while-loop body in try-finally to ensure `_isProcessing` is always reset.

### [x] DB-004: Silent cache corruption in `_getCachedProfiles` (P2)

- **Description**: When `_getCachedProfiles()` catches a JSON parse error, it silently returns an empty map without logging. This makes debugging data corruption issues impossible.
- **Affected Files**: `lib/core/services/offline_cache_service.dart` (lines 248-265)
- **Fix**: Add `AppLogger.error()` call in the catch block.
