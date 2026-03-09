import 'package:crushhour/data/models/user.dart';

/// Tracks auth identity transitions for auth-sensitive state containers.
///
/// Contract:
/// - Do not reset on first non-null user emission.
/// - Reset on logout (`user == null`) after a signed-in user existed.
/// - Reset on authenticated account switch (user id changed).
/// - Do not reset on repeated emissions for the same user id.
class AuthStateResetPolicy {
  String? _lastUserId;

  bool shouldResetFor(CrushUser? user) {
    final previousUserId = _lastUserId;
    final nextUserId = user?.id;
    _lastUserId = nextUserId;

    if (nextUserId == null) {
      return true;
    }

    if (previousUserId == null) {
      return false;
    }

    return previousUserId != nextUserId;
  }
}
