/// Chat feature barrel export.
/// Re-exports all chat-related components.
library;

// Domain (BLoCs, Events, States)
export 'presentation/bloc/chat_bloc.dart';
export 'presentation/bloc/chat_event.dart';
export 'presentation/bloc/chat_state.dart';
export 'presentation/bloc/matches_bloc.dart';
export 'presentation/bloc/matches_event.dart';
export 'presentation/bloc/matches_state.dart';

// Data (Repositories)
export 'data/repositories/chat_repository.dart';
export 'data/repositories/impl/stub_chat_repository.dart';

// Domain (Use Cases)
export 'domain/usecases/chat_use_cases.dart';

// Presentation (Screens)
export 'presentation/screens/chat_screen.dart';
export 'presentation/screens/chat_list_screen.dart';
export 'presentation/screens/matches_screen.dart';
