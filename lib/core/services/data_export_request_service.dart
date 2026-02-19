import 'package:cloud_functions/cloud_functions.dart';

class DataExportRequestService {
  DataExportRequestService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<DataExportRequestResult> requestExport() async {
    try {
      final callable = _functions.httpsCallable('requestDataExport');
      final response = await callable.call<Map<String, dynamic>>(
        <String, dynamic>{},
      );
      final payload = response.data;

      final requestId = payload['requestId'] as String?;
      final status = payload['status'] as String? ?? 'queued';
      final nextAllowedAt = payload['nextAllowedAt'];
      final nextAllowedAtIso =
          nextAllowedAt is String && nextAllowedAt.isNotEmpty
          ? nextAllowedAt
          : null;

      return DataExportRequestResult.success(
        requestId: requestId,
        status: status,
        nextAllowedAtIso: nextAllowedAtIso,
      );
    } on FirebaseFunctionsException catch (error) {
      String? nextAllowedAtIso;
      final details = error.details;
      if (details is Map) {
        final value = details['nextAllowedAt'];
        if (value is String && value.isNotEmpty) {
          nextAllowedAtIso = value;
        }
      }
      return DataExportRequestResult.failure(
        code: error.code,
        message: error.message ?? 'Could not request data export.',
        nextAllowedAtIso: nextAllowedAtIso,
      );
    } catch (error) {
      return DataExportRequestResult.failure(
        code: 'unknown',
        message: error.toString(),
      );
    }
  }
}

class DataExportRequestResult {
  const DataExportRequestResult._({
    required this.isSuccess,
    this.requestId,
    this.status,
    this.nextAllowedAtIso,
    this.code,
    this.message,
  });

  final bool isSuccess;
  final String? requestId;
  final String? status;
  final String? nextAllowedAtIso;
  final String? code;
  final String? message;

  factory DataExportRequestResult.success({
    String? requestId,
    required String status,
    String? nextAllowedAtIso,
  }) {
    return DataExportRequestResult._(
      isSuccess: true,
      requestId: requestId,
      status: status,
      nextAllowedAtIso: nextAllowedAtIso,
    );
  }

  factory DataExportRequestResult.failure({
    required String code,
    required String message,
    String? nextAllowedAtIso,
  }) {
    return DataExportRequestResult._(
      isSuccess: false,
      code: code,
      message: message,
      nextAllowedAtIso: nextAllowedAtIso,
    );
  }
}
