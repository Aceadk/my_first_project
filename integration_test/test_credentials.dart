/// Test credentials for integration testing.
///
/// IMPORTANT: These credentials are for testing purposes only.
/// Do NOT commit real user credentials to version control.
///
/// For CI/CD, use environment variables:
/// ```bash
/// flutter test integration_test/app_test.dart \
///   --dart-define=TEST_EMAIL=your@email.com \
///   --dart-define=TEST_PASSWORD=yourpassword
/// ```
class TestCredentials {
  TestCredentials._();

  // ===========================================================================
  // PRIMARY TEST ACCOUNT
  // ===========================================================================

  /// Primary test account email
  static const String testEmail = String.fromEnvironment(
    'TEST_EMAIL',
    defaultValue: 'adhikarigya8@gmail.com',
  );

  /// Primary test account password
  static const String testPassword = String.fromEnvironment(
    'TEST_PASSWORD',
    defaultValue: 'admin1234',
  );

  // ===========================================================================
  // DEV BYPASS CREDENTIALS (for stub repository testing)
  // ===========================================================================

  /// Dev bypass username (works with StubAuthRepository)
  static const String devBypassUsername = 'admin123';

  /// Dev bypass password (works with StubAuthRepository)
  static const String devBypassPassword = 'admin123';

  // ===========================================================================
  // SECONDARY TEST ACCOUNT (for chat/match testing)
  // ===========================================================================

  /// Secondary test account email (for testing chat between users)
  static const String secondaryEmail = String.fromEnvironment(
    'TEST_EMAIL_2',
    defaultValue: 'test2@crushhour.app',
  );

  /// Secondary test account password
  static const String secondaryPassword = String.fromEnvironment(
    'TEST_PASSWORD_2',
    defaultValue: 'testpass123',
  );

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Whether real Firebase credentials are configured
  static bool get hasRealCredentials =>
      testEmail.isNotEmpty &&
      testPassword.isNotEmpty &&
      testEmail != 'adhikarigya8@gmail.com'; // Check if using defaults

  /// Whether we should use Firebase (real) auth or stub auth
  static bool get useFirebaseAuth =>
      const bool.fromEnvironment('USE_FIREBASE_AUTH', defaultValue: false);

  /// Print credentials info (with password masked)
  static void printInfo() {
    // ignore: avoid_print
    print('Test Credentials:');
    // ignore: avoid_print
    print('  Email: $testEmail');
    // ignore: avoid_print
    print('  Password: ${testPassword.replaceAll(RegExp('.'), '*')}');
    // ignore: avoid_print
    print('  Use Firebase: $useFirebaseAuth');
  }
}
