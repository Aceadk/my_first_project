import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up Firebase mocks for testing.
/// Call this at the start of main() in test files that use Firebase services.
void setupFirebaseAnalyticsMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup Firebase Core mock
  final mockPlatform = MockFirebasePlatform();
  FirebasePlatform.instance = mockPlatform;
}

/// Mock implementation of FirebasePlatform for testing.
class MockFirebasePlatform extends FirebasePlatform {
  MockFirebasePlatform() : super();

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseApp();
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp();
  }

  @override
  List<FirebaseAppPlatform> get apps => [MockFirebaseApp()];
}

/// Mock implementation of FirebaseAppPlatform.
class MockFirebaseApp extends FirebaseAppPlatform {
  MockFirebaseApp() : super(defaultFirebaseAppName, _mockOptions);

  static const FirebaseOptions _mockOptions = FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: 'mock-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
  );

  @override
  FirebaseOptions get options => _mockOptions;

  @override
  String get name => defaultFirebaseAppName;

  @override
  bool get isAutomaticDataCollectionEnabled => false;
}
