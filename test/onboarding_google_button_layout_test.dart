import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/features/auth/data/repositories/impl/stub_auth_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/screens/auth_gateway_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/login_screen.dart';
import 'package:crushhour/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:crushhour/features/auth/presentation/widgets/google_logo_icon.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AnalyticsService.setInstance(_NoopAnalyticsService());
  });

  tearDown(() {
    AnalyticsService.resetInstance();
  });

  const testCases = <({String name, Widget screen})>[
    (name: 'auth gateway', screen: AuthGatewayScreen()),
    (name: 'login', screen: LoginScreen()),
    (name: 'sign up', screen: SignUpScreen()),
  ];

  const viewports = <({String name, Size size})>[
    (name: 'phone', size: Size(390, 844)),
    (name: 'tablet', size: Size(1024, 1366)),
  ];

  for (final testCase in testCases) {
    for (final viewport in viewports) {
      testWidgets(
        '${testCase.name} Google button stays centered on ${viewport.name}',
        (tester) async {
          final authRepository = StubAuthRepository();
          final authBloc = AuthBloc(authRepository: authRepository);
          addTearDown(authBloc.close);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.binding.setSurfaceSize(viewport.size);
          await tester.pumpWidget(
            _TestHost(
              authRepository: authRepository,
              authBloc: authBloc,
              child: testCase.screen,
            ),
          );

          // Allow auth-gateway fade-in and first-frame layout to settle.
          await tester.pump(const Duration(milliseconds: 1400));

          expect(tester.takeException(), isNull);

          final googleIcon = find.byType(GoogleLogoIcon);
          expect(
            googleIcon,
            findsOneWidget,
            reason: 'Expected branded Google icon on ${testCase.name}',
          );

          final googleLabel = find.text('Continue with Google');
          expect(
            googleLabel,
            findsOneWidget,
            reason: 'Expected Google CTA label on ${testCase.name}',
          );

          final googleButton = find
              .ancestor(
                of: googleIcon,
                matching: find.byType(GlassOutlinedButton),
              )
              .first;

          final iconRect = tester.getRect(googleIcon);
          final textRect = tester.getRect(googleLabel);
          final buttonRect = tester.getRect(googleButton);

          final contentCenterX = (iconRect.left + textRect.right) / 2;
          final buttonCenterX = buttonRect.center.dx;

          expect(
            (contentCenterX - buttonCenterX).abs(),
            lessThan(2.0),
            reason:
                'Google icon+label content should be visually centered in button',
          );
        },
      );
    }
  }
}

class _NoopAnalyticsService extends AnalyticsService {
  _NoopAnalyticsService() : super.forTesting();

  @override
  Future<void> logOnboardingStep({
    required String step,
    required int stepNumber,
    required int totalSteps,
  }) async {}
}

class _TestHost extends StatelessWidget {
  const _TestHost({
    required this.authRepository,
    required this.authBloc,
    required this.child,
  });

  final AuthRepository authRepository;
  final AuthBloc authBloc;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>.value(
      value: authRepository,
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        ),
      ),
    );
  }
}
