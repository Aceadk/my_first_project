/// Profile feature barrel export.
/// Re-exports all profile-related components.
library;

// Domain (BLoCs, Events, States)
export 'presentation/bloc/profile_bloc.dart';
export 'presentation/bloc/profile_event.dart';
export 'presentation/bloc/profile_state.dart';
export 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';

// Data (Repositories)
export 'data/repositories/profile_repository.dart';
export 'data/repositories/impl/stub_profile_repository.dart';

// Data (Services)
export 'data/services/profile_validation_service.dart';
export 'data/services/profile_media_service.dart';

// Models (from shared location)
export 'package:crushhour/data/models/profile.dart';
export 'package:crushhour/data/models/user.dart';
export 'package:crushhour/data/models/preferences.dart';
export 'package:crushhour/data/models/privacy_settings.dart';

// Presentation (Screens)
export 'presentation/screens/profile_view_screen.dart';
export 'presentation/screens/profile_edit_screen.dart';
export 'presentation/screens/profile_setup_screen.dart';
export 'presentation/screens/other_user_profile_screen.dart';
export 'presentation/screens/profile_media_screen.dart';
export 'package:crushhour/features/auth/presentation/screens/basic_info_screen.dart';
export 'package:crushhour/features/auth/presentation/screens/id_verification_screen.dart';

// Presentation (Widgets)
export 'presentation/widgets/profile_completeness_meter.dart';
export 'presentation/widgets/profile_media_picker.dart';
export 'presentation/widgets/profile_field_tile.dart';
export 'presentation/widgets/profile_height_picker.dart';
export 'presentation/widgets/profile_single_select_sheet.dart';
export 'presentation/widgets/profile_multi_select_sheet.dart';
export 'presentation/widgets/profile_chip_display.dart';
