/// Feature flags feature barrel export.
/// Re-exports all feature-flag-related components.
library;

// Domain (Models)
export 'domain/models/feature_flags.dart';

// Domain (Repositories)
export 'domain/repositories/feature_flag_repository.dart';

// Domain (Use Cases)
export 'domain/usecases/feature_flag_use_cases.dart';
export 'domain/usecases/get_bool_flag.dart';
export 'domain/usecases/watch_flags.dart';
export 'domain/usecases/fetch_and_activate_flags.dart';
export 'domain/usecases/get_current_flags.dart';
export 'domain/usecases/get_string_flag.dart';
export 'domain/usecases/get_int_flag.dart';
export 'domain/usecases/initialize_flags.dart';
export 'domain/usecases/force_refresh_flags.dart';

// Presentation (BLoC/Cubit)
export 'presentation/bloc/feature_flag_cubit.dart';
