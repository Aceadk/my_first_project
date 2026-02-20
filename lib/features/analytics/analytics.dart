/// Analytics feature barrel export.
/// Re-exports all analytics-related components.
library;

// Domain (Models)
export 'domain/models/profile_insights.dart';

// Domain (Repositories)
export 'domain/repositories/profile_insights_repository.dart';

// Domain (Use Cases)
export 'domain/usecases/analytics_use_cases.dart';
export 'domain/usecases/load_insights.dart';
export 'domain/usecases/watch_insights.dart';
export 'domain/usecases/record_profile_view.dart';
export 'domain/usecases/get_photo_performance.dart';
export 'domain/usecases/get_insights_for_range.dart';
export 'domain/usecases/record_like_received.dart';

// Presentation (BLoC/Cubit)
export 'presentation/bloc/profile_insights_cubit.dart';

// Presentation (Screens)
export 'presentation/screens/profile_insights_screen.dart';
