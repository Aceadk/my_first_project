/// Auth feature barrel export.
/// Re-exports all auth-related components from their current locations.
/// This establishes the feature-first structure for gradual migration.
library auth;

// Domain (BLoCs, Events, States)
export '../../logic/auth/auth_bloc.dart';
export '../../logic/auth/auth_event.dart';
export '../../logic/auth/auth_state.dart';
export '../../logic/auth/email_auth_bloc.dart';
export '../../logic/auth/phone_auth_bloc.dart';
export '../../logic/auth/session_bloc.dart';

// Data (Repositories)
export '../../data/repositories/auth_repository.dart';
export '../../data/repositories/stub/stub_auth_repository.dart';
export '../../data/repositories/firebase/firebase_auth_repository.dart';

// Presentation (Screens)
export '../../presentation/screens/login_screen.dart';
export '../../presentation/screens/sign_up_screen.dart';
export '../../presentation/screens/otp_screen.dart';
export '../../presentation/screens/forgot_password_screen.dart';
export '../../presentation/screens/email_auth_screen.dart';
export '../../presentation/screens/phone_auth_screen.dart';
export '../../presentation/screens/auth_gateway_screen.dart';
