import 'app_logger.dart';

class Result<T> {
  final T? data;
  final String? errorMessage;

  const Result._({this.data, this.errorMessage});

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
      return Result._(
        errorMessage:
            fallbackError ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
