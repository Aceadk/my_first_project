/// Calls feature barrel export.
/// Re-exports all calls-related components.
library calls;

// Data (Repositories)
export 'data/repositories/call_repository.dart';
export 'data/repositories/impl/stub_call_repository.dart';

// Presentation (Bloc)
export 'presentation/bloc/call_bloc.dart';
export 'presentation/bloc/call_event.dart';
export 'presentation/bloc/call_state.dart';

// Presentation (Screens)
export 'presentation/screens/call_screen.dart';
export 'presentation/screens/video_call_screen.dart';
