# Cleanup Dead Code Module

Priority: P2-P3

This document tracks dead code candidates identified via `dart analyze`, `@deprecated` annotations, and manual review.

## Action Items

### [x] DC-001: Annotate legacy `exercise` field as `@Deprecated` (P3)

- **Description**: `Profile.exercise` is commented as "Legacy field, kept for compatibility" but lacks a `@Deprecated` annotation. It duplicates `Profile.workout`.
- **Affected Files**: `lib/shared/dto/profile.dart` (line 143)
- **Fix**: Add `@Deprecated('Use workout instead')` annotation for static analysis visibility.

### DC-002: Migrate `watchMessages()` callers to paginated API (P2) — **BLOCKED**

- **Description**: `ChatRepository.watchMessages()` is annotated as deprecated but still actively used in `message_handling_bloc.dart` (line 408), `chat_list_screen.dart` (line 538), and all 4 repository implementations. Cannot be removed until all callers migrate to `watchNewMessages` + `fetchMessagesPaginated`.
- **Affected Files**: 7 files across domain, data, and presentation layers
- **Status**: Requires coordinated migration — not safe to remove now.

### DC-003: Remove `Profile.prompts` field after full migration to `profilePrompts` (P3) — **BLOCKED**

- **Description**: `Profile.prompts` (List\<String>) is `@Deprecated` in favor of `profilePrompts` (List\<ProfilePrompt>). Still serialized in `profile_dto.dart` and `stub_auth_repository.dart` for backward compatibility.
- **Affected Files**: `lib/shared/dto/profile.dart`, `lib/data/dto/profile_dto.dart`, `lib/features/auth/data/repositories/impl/stub_auth_repository.dart`
- **Status**: Requires backend migration to stop sending the old field.

### [x] DC-004: Consolidate backward-compatibility re-export barrel files (P3)

- **Description**: 4 barrel files exist solely to re-export domain layer interfaces from data layer paths for backward compatibility. These add confusion about canonical import paths.
- **Files**:
  - `lib/features/profile/data/repositories/profile_repository.dart`
  - `lib/features/auth/data/repositories/auth_repository.dart`
  - `lib/features/chat/data/repositories/chat_repository.dart`
  - `lib/features/discovery/data/repositories/boost_repository.dart`
- **Fix**: Keep these but add `@Deprecated` annotation pointing to the canonical domain-layer import.
