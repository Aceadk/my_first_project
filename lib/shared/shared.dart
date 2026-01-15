/// Shared components barrel export.
/// Re-exports shared widgets, models, and utilities.
library shared;

// Shared Widgets
export 'widgets/async_state_scaffold.dart';
export 'widgets/cached_network_image.dart';
export '../presentation/widgets/plus_feature_gate.dart';

// Shared Models
export '../data/models/user.dart';
export '../data/models/profile.dart';
export '../data/models/message.dart';
export '../data/models/match.dart';
export '../data/models/subscription.dart';
export '../data/models/preferences.dart';
export '../data/models/privacy_settings.dart';

// Core Utilities
export '../core/utils/result.dart';
export '../core/utils/constants.dart';
export '../core/utils/validators.dart';
