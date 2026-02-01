import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

/// Sets up Firebase mocks for testing.
/// Uses the newer Firebase platform interface approach.
void setupFirebaseMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup mock Firebase platform
  setupFirebaseCoreMocks();
}

/// Setup Firebase Core mocks using the platform interface.
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register a mock Firebase platform
  FirebasePlatform.instance = _MockFirebasePlatform();
}

/// Mock implementation of FirebasePlatform for testing.
class _MockFirebasePlatform extends FirebasePlatform {
  _MockFirebasePlatform() : super();

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _MockFirebaseAppPlatform(name);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _MockFirebaseAppPlatform(name ?? defaultFirebaseAppName);
  }

  @override
  List<FirebaseAppPlatform> get apps => [_MockFirebaseAppPlatform(defaultFirebaseAppName)];
}

/// Mock implementation of FirebaseAppPlatform for testing.
class _MockFirebaseAppPlatform extends FirebaseAppPlatform {
  _MockFirebaseAppPlatform(String name) : super(name, _mockOptions);

  static const FirebaseOptions _mockOptions = FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: 'mock-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
  );

  @override
  Future<void> delete() async {}

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}
