import '../../../core/result.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/discovery_repository.dart';
import '../use_case.dart';

/// Parameters for fetching the discovery deck.
class FetchDeckParams {
  final String userId;

  const FetchDeckParams({required this.userId});
}

/// Use case for fetching profiles for the discovery deck.
///
/// Returns a list of profiles that the user can swipe on.
class FetchDiscoveryDeckUseCase extends UseCase<List<Profile>, FetchDeckParams> {
  final DiscoveryRepository _discoveryRepository;

  FetchDiscoveryDeckUseCase(this._discoveryRepository);

  @override
  Future<Result<List<Profile>>> call(FetchDeckParams params) {
    return Result.guard(
      () => _discoveryRepository.fetchDeck(params.userId),
      logLabel: 'FetchDiscoveryDeckUseCase',
      fallbackError: 'Could not load profiles. Please try again.',
    );
  }
}
