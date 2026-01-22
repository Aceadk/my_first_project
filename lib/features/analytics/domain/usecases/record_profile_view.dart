import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';

/// Parameters for recording a profile view.
class RecordProfileViewParams {
  final String viewerUserId;

  const RecordProfileViewParams({required this.viewerUserId});
}

/// Use case for recording when a profile is viewed.
class RecordProfileViewUseCase extends UseCase<void, RecordProfileViewParams>
    with ValidatingUseCase<void, RecordProfileViewParams> {
  final ProfileInsightsService _service;

  RecordProfileViewUseCase([ProfileInsightsService? service])
      : _service = service ?? ProfileInsightsService.instance;

  @override
  String? validate(RecordProfileViewParams params) {
    if (params.viewerUserId.trim().isEmpty) {
      return 'Viewer user ID is required';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(RecordProfileViewParams params) {
    return Result.guard(
      () => _service.recordProfileView(params.viewerUserId),
      logLabel: 'RecordProfileViewUseCase',
      fallbackError: 'Unable to record profile view.',
    );
  }
}
