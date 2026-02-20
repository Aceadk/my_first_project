/// Settings feature barrel export.
/// Re-exports all settings-related components.
library;

// Domain (Cubits)
export 'presentation/bloc/theme_cubit.dart';
export 'presentation/bloc/locale_cubit.dart';
export 'presentation/bloc/notification_settings_cubit.dart';
export 'presentation/bloc/storage_settings_cubit.dart';
export 'presentation/bloc/safety_cubit.dart';
export 'presentation/bloc/privacy_settings_cubit.dart';
export 'presentation/bloc/chat_settings_cubit.dart';

// Subscription (cross-feature)
export '../subscription/presentation/bloc/subscription_bloc.dart';
export '../subscription/presentation/bloc/subscription_event.dart';
export '../subscription/presentation/bloc/subscription_state.dart';

// Data (Models)
export '../../data/models/subscription.dart';

// Presentation (Screens)
export 'presentation/screens/settings_screen.dart';
export 'presentation/screens/notifications_settings_screen.dart';
export 'presentation/screens/language_region_settings_screen.dart';
export 'presentation/screens/discovery_filters_settings_screen.dart';
export 'presentation/screens/data_storage_settings_screen.dart';
export 'presentation/screens/account_security_settings_screen.dart';
export 'presentation/screens/account_actions_settings_screen.dart';
export 'presentation/screens/privacy_settings_screen.dart';
export 'presentation/screens/chat_settings_screen.dart';
export 'presentation/screens/subscription_settings_screen.dart';
