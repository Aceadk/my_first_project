/// Discovery feature barrel export.
/// Re-exports all discovery-related components from their current locations.
library discovery;

// Domain (BLoCs, Events, States)
export '../../logic/discovery/discovery_bloc.dart';
export '../../logic/discovery/discovery_event.dart';
export '../../logic/discovery/discovery_state.dart';
export '../../logic/discovery/discovery_settings_cubit.dart';

// Data (Repositories, Models)
export '../../data/repositories/discovery_repository.dart';
export '../../data/repositories/stub/stub_discovery_repository.dart';
export '../../data/models/profile.dart';

// Presentation (Screens, Widgets)
export '../../presentation/screens/deck_screen.dart';
export '../../presentation/widgets/deck_card_stack.dart';
export '../../presentation/widgets/swipeable_card.dart';
