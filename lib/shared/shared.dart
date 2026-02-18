/// Shared components barrel export.
/// Re-exports shared widgets, models, and utilities.
library;

// Shared DTOs (canonical source)
export 'dto/dto.dart';

// Shared Widgets
export 'widgets/async_state_scaffold.dart';
export 'widgets/cached_network_image.dart';
export '../presentation/widgets/plus_feature_gate.dart';

// Core Utilities
export '../core/utils/result.dart';
export '../core/utils/constants.dart';
export '../core/validators.dart';
