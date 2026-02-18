/// Barrel file for shared DTOs used across multiple feature domains.
///
/// All models in this directory are used by 2+ features and serve as the
/// canonical source of truth. Original files in `lib/data/models/` re-export
/// from here for backward compatibility.
library;

export 'chat_settings.dart';
export 'favourites.dart';
export 'match.dart';
export 'message.dart';
export 'preferences.dart';
export 'privacy_settings.dart';
export 'profile.dart';
export 'profile_prompt.dart';
export 'subscription.dart';
export 'user.dart';
