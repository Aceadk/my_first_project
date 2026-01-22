import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/calls/data/repositories/call_repository.dart';

/// Use case for watching call engine events as a stream.
class WatchCallEventsUseCase extends StreamUseCase<CallEngineEvent, NoParams> {
  final CallRepository _repository;

  WatchCallEventsUseCase(this._repository);

  @override
  Stream<CallEngineEvent> call(NoParams params) {
    return _repository.engineEvents();
  }
}
