import 'dart:async';

import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';

/// Isolated startup bootstrap orchestration for auth session restoration.
///
/// Handles subscription lifecycle around bootstrap so startup callers can keep
/// deterministic and testable behavior.
class SessionBootstrapService {
  SessionBootstrapService({required AuthFlowUseCases authFlowUseCases})
    : _authFlowUseCases = authFlowUseCases;

  final AuthFlowUseCases _authFlowUseCases;

  Future<Result<StreamSubscription<CrushUser?>>> bootstrap({
    required void Function(CrushUser? user) onUserChanged,
    StreamSubscription<CrushUser?>? existingSubscription,
  }) async {
    await existingSubscription?.cancel();

    final subscription = _authFlowUseCases.authStateChanges().listen(
      onUserChanged,
    );

    final bootstrapResult = await _authFlowUseCases.bootstrapSession();
    if (!bootstrapResult.isSuccess) {
      await subscription.cancel();
      return Result.failure(
        bootstrapResult.errorMessage ??
            'Could not connect to authentication. Please try again.',
        code: bootstrapResult.errorCode,
      );
    }

    return Result.success(subscription);
  }
}
