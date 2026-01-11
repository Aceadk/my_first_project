/// Profile feature barrel export.
/// Re-exports all profile-related components from their current locations.
library profile;

// Domain (BLoCs, Events, States)
export '../../logic/profile/profile_bloc.dart';
export '../../logic/profile/profile_event.dart';
export '../../logic/profile/profile_state.dart';
export '../../logic/privacy/privacy_settings_cubit.dart';

// Data (Repositories, Models)
export '../../data/repositories/profile_repository.dart';
export '../../data/repositories/stub/stub_profile_repository.dart';
export '../../data/models/profile.dart';
export '../../data/models/user.dart';
export '../../data/models/preferences.dart';
export '../../data/models/privacy_settings.dart';

// Presentation (Screens)
export '../../presentation/screens/profile_view_screen.dart';
export '../../presentation/screens/profile_edit_screen.dart';
export '../../presentation/screens/profile_setup_screen.dart';
export '../../presentation/screens/other_user_profile_screen.dart';
export '../../presentation/screens/basic_info_screen.dart';
export '../../presentation/screens/id_verification_screen.dart';
