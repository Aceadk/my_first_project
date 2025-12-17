import 'app_logger.dart';
import 'errors.dart';

class Result<T> {
  final T? data;
  final String? errorMessage;
  final String? errorCode;

  const Result._({this.data, this.errorMessage, this.errorCode});

  bool get isSuccess => errorMessage == null;

  static Future<Result<T>> guard<T>(
    Future<T> Function() run, {
    String? logLabel,
    String? fallbackError,
  }) async {
    try {
      final value = await run();
      return Result._(data: value);
    } catch (error, stackTrace) {
      AppLogger.logError(logLabel ?? 'Operation failed', error, stackTrace);
      String? message = fallbackError ?? 'Something went wrong. Please try again.';
      String? code;
      if (error is RepositoryException) {
        message = error.message;
        code = error.code;
      }
      return Result._(
        errorMessage: message,
        errorCode: code,
      );
    }
  }
}
