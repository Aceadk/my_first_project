# Discovery Backend Module

Priority: P1-P2

This document tracks outstanding remediation and audit actions for the Discovery Backend domain.

## Action Items

### [x] DISC-001: Hardcoded endpoint strings in HttpDiscoveryRepository (P2)

- **Description**: `fetchTopPicks`, `fetchLikesYou`, `superLike`, `rewindLastSwipe`, and `fetchProfileById` use hardcoded path strings instead of `ApiEndpoints` constants. This makes endpoint management inconsistent and error-prone.
- **Affected Files**: `lib/features/discovery/data/repositories/impl/http_discovery_repository.dart`, `lib/core/network/api_version.dart`
- **Fix**: Add missing constants to `ApiEndpoints` and reference them in the repository.

### [x] DISC-002: `fetchProfileById` uses unsanitized `profileId` in URL path (P1)

- **Description**: `fetchProfileById` constructs the URL as `'/profiles/$profileId'` without validating the input. A malicious or malformed `profileId` containing `/` or `..` could result in path traversal or unexpected API calls.
- **Affected Files**: `lib/features/discovery/data/repositories/impl/http_discovery_repository.dart` (line 193)
- **Fix**: Validate that `profileId` matches expected format (alphanumeric + limited special chars) and encode it with `Uri.encodeComponent`.

### [x] DISC-003: Free-user swipe counter is in-memory only — resets on app restart (P2)

- **Description**: `SwipeRightUseCase._remainingFreeSwipesToday` is a plain `int?` field. It resets to `null` every time the app restarts, giving free users unlimited swipes by simply restarting the app.
- **Affected Files**: `lib/features/discovery/domain/usecases/swipe_right.dart`
- **Fix**: Persist the counter and date to SharedPreferences so it survives app restarts.
