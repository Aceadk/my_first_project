export 'package:crushhour/features/profile/data/services/profile_validation_service.dart'
    show RemoteProfileCompleteness;
import 'package:crushhour/features/profile/data/services/profile_validation_service.dart';

abstract class ProfileValidationRepository {
  Future<RemoteProfileCompleteness> validate({String minimum = 'swipe'});
}
