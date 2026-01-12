/// Dependency Injection barrel export.
/// Contains service locator and dependency configuration.
library di;

// Re-export repository interfaces
export '../../features/auth/data/repositories/auth_repository.dart';
export '../../data/repositories/profile_repository.dart';
export '../../data/repositories/discovery_repository.dart';
export '../../data/repositories/chat_repository.dart';
export '../../data/repositories/subscription_repository.dart';
export '../../data/repositories/call_repository.dart';

// Stub implementations (for development)
export '../../features/auth/data/repositories/impl/stub_auth_repository.dart';
export '../../data/repositories/stub/stub_profile_repository.dart';
export '../../data/repositories/stub/stub_discovery_repository.dart';
export '../../data/repositories/stub/stub_chat_repository.dart';
export '../../data/repositories/stub/stub_subscription_repository.dart';
export '../../data/repositories/stub/stub_call_repository.dart';
