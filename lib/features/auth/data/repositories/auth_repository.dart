/// Auth repository interface.
///
/// This file re-exports the domain layer interface for backwards compatibility.
/// New code should import from the domain layer directly:
///   import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
library;

export 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
export 'package:crushhour/features/auth/domain/repositories/linked_accounts_repository.dart';
