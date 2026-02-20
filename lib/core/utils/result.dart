import 'dart:async';
import 'dart:io';

import '../app_logger.dart';
import '../errors.dart';

/// A lightweight Result type for explicit error handling.
///
/// Use [Result.success] to wrap a successful value and [Result.failure] to wrap
/// an error. The static [Result.guard] helper catches exceptions thrown by async
/// operations and converts them into [Result.failure] values automatically.
///
/// Helper methods:
/// - [isSuccess] / [isFailure] — quick status checks
/// - [valueOrNull] — returns [data] if success, null otherwise
/// - [getOrElse] — returns [data] if success, a fallback value otherwise
/// - [map] — transforms the success value while preserving failures
/// - [flatMap] — chains Result-returning transformations
/// - [fold] — collapses success/failure into a single value
class Result<T> {
  final T? data;
  final String? errorMessage;
  final String? errorCode;

  const Result._({this.data, this.errorMessage, this.errorCode});

  /// Create a successful result with data.
  const Result.success(T data) : this._(data: data);

  /// Create a failed result with an error message.
  const Result.failure(String message, {String? code})
    : this._(errorMessage: message, errorCode: code);

  /// Whether this result represents a success (no error).
  bool get isSuccess => errorMessage == null;

  /// Whether this result represents a failure (has an error).
  bool get isFailure => errorMessage != null;

  /// Returns the success value if present, or null.
  ///
  /// Alias for [data] that reads more clearly in pattern-matching style code:
  /// ```dart
  /// final name = result.valueOrNull ?? 'Anonymous';
  /// ```
  T? get valueOrNull => isSuccess ? data : null;

  /// Returns the success value if present, or [defaultValue].
  ///
  /// ```dart
  /// final user = result.getOrElse(CrushUser.anonymous());
  /// ```
  T getOrElse(T defaultValue) =>
      (isSuccess && data != null) ? data as T : defaultValue;

  /// Transforms the success value using [transform], preserving failures.
  ///
  /// ```dart
  /// final nameResult = userResult.map((user) => user.displayName);
  /// ```
  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess && data != null) {
      return Result<R>.success(transform(data as T));
    }
    return Result<R>.failure(errorMessage ?? 'Unknown error', code: errorCode);
  }

  /// Chains a Result-returning transformation on the success value.
  ///
  /// Unlike [map], the transform itself can fail and return a [Result.failure].
  /// ```dart
  /// final profileResult = userResult.flatMap((user) => fetchProfile(user.id));
  /// ```
  Result<R> flatMap<R>(Result<R> Function(T) transform) {
    if (isSuccess && data != null) {
      return transform(data as T);
    }
    return Result<R>.failure(errorMessage ?? 'Unknown error', code: errorCode);
  }

  /// Collapses both success and failure cases into a single value.
  ///
  /// ```dart
  /// final message = result.fold(
  ///   onSuccess: (user) => 'Welcome, ${user.name}!',
  ///   onFailure: (error, code) => 'Login failed: $error',
  /// );
  /// ```
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String error, String? code) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onFailure(errorMessage ?? 'Unknown error', errorCode);
  }

  /// Wraps an async operation in a try/catch and returns a [Result].
  ///
  /// On success, returns [Result.success] with the value.
  /// On failure, logs the error and returns [Result.failure] with a
  /// user-friendly message derived from the exception type.
  static Future<Result<T>> guard<T>(
    Future<T> Function() run, {
    String? logLabel,
    String? fallbackError,
  }) async {
    try {
      final value = await run();
      return Result._(data: value);
    } catch (error, stackTrace) {
      AppLogger.error(
        logLabel ?? 'Operation failed',
        error: error,
        stackTrace: stackTrace,
      );
      String? message =
          fallbackError ?? 'Something went wrong. Please try again.';
      String? code;
      if (error is SocketException || error is TimeoutException) {
        message =
            'Internet connection error. Check Wi-Fi or data, then refresh.';
        code = 'network_unavailable';
      } else if (error is RepositoryException) {
        message = error.message;
        code = error.code;
      }
      return Result._(errorMessage: message, errorCode: code);
    }
  }

  /// Synchronous version of [guard] for operations that don't return Futures.
  static Result<T> guardSync<T>(
    T Function() run, {
    String? logLabel,
    String? fallbackError,
  }) {
    try {
      final value = run();
      return Result.success(value);
    } catch (error, stackTrace) {
      AppLogger.error(
        logLabel ?? 'Operation failed',
        error: error,
        stackTrace: stackTrace,
      );
      String? message =
          fallbackError ?? 'Something went wrong. Please try again.';
      String? code;
      if (error is SocketException || error is TimeoutException) {
        message =
            'Internet connection error. Check Wi-Fi or data, then refresh.';
        code = 'network_unavailable';
      } else if (error is RepositoryException) {
        message = error.message;
        code = error.code;
      }
      return Result._(errorMessage: message, errorCode: code);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($data)';
    }
    return 'Result.failure($errorMessage${errorCode != null ? ', code: $errorCode' : ''})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Result<T> &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          errorMessage == other.errorMessage &&
          errorCode == other.errorCode;

  @override
  int get hashCode => Object.hash(data, errorMessage, errorCode);
}
