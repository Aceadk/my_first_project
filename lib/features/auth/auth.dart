/// Auth feature barrel export.
/// Re-exports all auth-related components.
library auth;

// Domain (BLoCs, Events, States)
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/bloc/auth_event.dart';
export 'presentation/bloc/auth_state.dart';
export 'presentation/bloc/session_bloc.dart';

// Data (Repositories)
export 'data/repositories/auth_repository.dart';
export 'data/repositories/impl/stub_auth_repository.dart';
export 'data/repositories/impl/firebase_auth_repository.dart';

// Domain (Use Cases)
export 'domain/usecases/auth_use_cases.dart';
export 'domain/usecases/send_phone_otp.dart';
export 'domain/usecases/verify_phone_otp.dart';
export 'domain/usecases/sign_in_with_password.dart';
export 'domain/usecases/sign_out.dart';

// Presentation (Screens)
export 'presentation/screens/login_screen.dart';
export 'presentation/screens/sign_up_screen.dart';
export 'presentation/screens/otp_screen.dart';
export 'presentation/screens/forgot_password_screen.dart';
export 'presentation/screens/email_auth_screen.dart';
export 'presentation/screens/phone_auth_screen.dart';
export 'presentation/screens/auth_gateway_screen.dart';
