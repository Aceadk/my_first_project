import 'package:crushhour/core/utils/result.dart';

/// Base interface for all use cases.
/// Use cases encapsulate single business operations, separating
/// business logic from presentation (BLoCs) and data layers.
///
/// Type parameters:
/// - [T] The return type of the use case
/// - [P] The parameters type (use [NoParams] for parameterless use cases)
abstract class UseCase<T, P> {
  /// Execute the use case with the given parameters.
  Future<Result<T>> call(P params);
}

/// Base interface for synchronous use cases.
abstract class SyncUseCase<T, P> {
  /// Execute the use case synchronously.
  Result<T> call(P params);
}

/// Marker class for use cases that don't require parameters.
class NoParams {
  const NoParams();
}

/// Base interface for stream-based use cases (queries that return streams).
abstract class StreamUseCase<T, P> {
  /// Execute the use case and return a stream.
  Stream<T> call(P params);
}

/// Mixin for use cases that need to validate parameters before execution.
mixin ValidatingUseCase<T, P> on UseCase<T, P> {
  /// Validate the parameters before execution.
  /// Returns null if valid, error message if invalid.
  String? validate(P params);

  @override
  Future<Result<T>> call(P params) async {
    final validationError = validate(params);
    if (validationError != null) {
      return Result.failure(validationError);
    }
    return execute(params);
  }

  /// Execute the use case after validation passes.
  Future<Result<T>> execute(P params);
}
