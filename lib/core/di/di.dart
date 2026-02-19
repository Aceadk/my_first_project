/// Dependency Injection barrel export.
/// Contains service locator and dependency configuration.
library;

// Re-export repository interfaces
export '../../features/auth/domain/repositories/auth_repository.dart';
export '../../features/profile/data/repositories/profile_repository.dart';
export '../../features/discovery/domain/repositories/discovery_repository.dart';
export '../../features/chat/domain/repositories/chat_repository.dart';
export '../../features/subscription/domain/repositories/subscription_repository.dart';
export '../../features/calls/data/repositories/call_repository.dart';

// Stub implementations (for development)
export '../../features/auth/data/repositories/impl/stub_auth_repository.dart';
export '../../features/profile/data/repositories/impl/stub_profile_repository.dart';
export '../../features/discovery/data/repositories/impl/stub_discovery_repository.dart';
export '../../features/chat/data/repositories/impl/stub_chat_repository.dart';
export '../../features/subscription/data/repositories/impl/stub_subscription_repository.dart';
export '../../features/calls/data/repositories/impl/stub_call_repository.dart';
