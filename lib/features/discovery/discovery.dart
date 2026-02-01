/// Discovery feature barrel export.
/// Re-exports all discovery-related components.
library;

// Domain (BLoCs, Events, States)
export 'presentation/bloc/discovery_bloc.dart';
export 'presentation/bloc/discovery_event.dart';
export 'presentation/bloc/discovery_state.dart';
export 'presentation/bloc/discovery_settings_cubit.dart';

// Data (Repositories)
export 'data/repositories/discovery_repository.dart';
export 'data/repositories/impl/stub_discovery_repository.dart';

// Domain (Use Cases)
export 'domain/usecases/discovery_use_cases.dart';
export 'domain/usecases/fetch_discovery_deck.dart';
export 'domain/usecases/swipe_right.dart';

// Presentation (Screens)
export 'presentation/screens/deck_screen.dart';

// Presentation (Widgets)
export 'presentation/widgets/swipe_card.dart';
export 'presentation/widgets/swipeable_card.dart';
export 'presentation/widgets/deck_card_stack.dart';
export 'presentation/widgets/deck_skeleton.dart';
export 'presentation/widgets/deck_ui_helpers.dart';
