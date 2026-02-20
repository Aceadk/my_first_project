/// Calls feature barrel export.
/// Re-exports all calls-related components.
library;

// Data (Repositories)
export 'data/repositories/call_repository.dart';
export 'data/repositories/impl/stub_call_repository.dart';
export 'data/services/call_quality_service.dart';
export 'data/services/callkit_service.dart';
export 'data/services/native_pip_service.dart';

// Presentation (Bloc)
export 'presentation/bloc/call_bloc.dart';
export 'presentation/bloc/call_event.dart';
export 'presentation/bloc/call_state.dart';

// Presentation (Screens)
export 'presentation/screens/call_screen.dart';
export 'presentation/screens/call_history_screen.dart';
export 'presentation/screens/incoming_call_screen.dart';
export 'presentation/screens/video_call_screen.dart';

// Presentation (Widgets)
export 'presentation/widgets/call_safety_controls.dart';
export 'presentation/widgets/pip_video_overlay.dart';
