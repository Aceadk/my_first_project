import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up Firebase mocks for testing.
/// Call this at the start of main() in test files that use Firebase services.
void setupFirebaseAnalyticsMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup Firebase Core mock
  final mockPlatform = MockFirebasePlatform();
  FirebasePlatform.instance = mockPlatform;

  // Setup Firebase Analytics mock
  _setupFirebaseAnalyticsMock();

  // Setup Firebase Auth mock
  _setupFirebaseAuthMock();

  // Setup SharedPreferences mock
  _setupSharedPreferencesMock();

  // Setup FlutterSecureStorage mock
  _setupFlutterSecureStorageMock();

  // Setup Firebase Messaging mock
  _setupFirebaseMessagingMock();
}

void _setupFirebaseAuthMock() {
  const channel = MethodChannel('plugins.flutter.io/firebase_auth');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Auth#signOut':
        return null;
      case 'Auth#signInWithCredential':
        return {'user': _mockUserData};
      default:
        return null;
    }
  });
}

void _setupSharedPreferencesMock() {
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getAll':
        return <String, dynamic>{};
      case 'clear':
        return true;
      case 'remove':
        return true;
      case 'setBool':
      case 'setInt':
      case 'setDouble':
      case 'setString':
      case 'setStringList':
        return true;
      default:
        return null;
    }
  });
}

// In-memory storage for FlutterSecureStorage mock
final Map<String, String> _secureStorageData = {};

/// Clears all mock secure storage data between tests.
void clearSecureStorageMock() {
  _secureStorageData.clear();
}

void _setupFlutterSecureStorageMock() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'read':
        final key = methodCall.arguments['key'] as String?;
        return key != null ? _secureStorageData[key] : null;
      case 'write':
        final key = methodCall.arguments['key'] as String?;
        final value = methodCall.arguments['value'] as String?;
        if (key != null && value != null) {
          _secureStorageData[key] = value;
        }
        return null;
      case 'delete':
        final key = methodCall.arguments['key'] as String?;
        if (key != null) {
          _secureStorageData.remove(key);
        }
        return null;
      case 'deleteAll':
        _secureStorageData.clear();
        return null;
      case 'readAll':
        return Map<String, String>.from(_secureStorageData);
      case 'containsKey':
        final key = methodCall.arguments['key'] as String?;
        return key != null && _secureStorageData.containsKey(key);
      default:
        return null;
    }
  });
}

const Map<String, dynamic> _mockUserData = {
  'uid': 'mock-user-id',
  'email': 'mock@example.com',
  'displayName': 'Mock User',
  'photoURL': null,
  'phoneNumber': '+1234567890',
  'emailVerified': true,
  'isAnonymous': false,
  'creationTimestamp': 1609459200000,
  'lastSignInTimestamp': 1609459200000,
  'tenantId': null,
  'providerData': [],
};

void _setupFirebaseMessagingMock() {
  const channel = MethodChannel('plugins.flutter.io/firebase_messaging');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Messaging#getToken':
        return <dynamic, dynamic>{'token': 'mock-fcm-token'};
      case 'Messaging#deleteToken':
        return null;
      case 'Messaging#getInitialMessage':
        return null;
      case 'Messaging#subscribeToTopic':
        return null;
      case 'Messaging#unsubscribeFromTopic':
        return null;
      case 'Messaging#requestPermission':
        return {
          'authorizationStatus': 1, // authorized
          'alert': 1,
          'badge': 1,
          'sound': 1,
          'announcement': 0,
          'carPlay': 0,
          'criticalAlert': 0,
          'provisional': 0,
          'showPreviews': 1,
          'timeSensitive': 0,
        };
      case 'Messaging#getNotificationSettings':
        return {
          'authorizationStatus': 1,
          'alert': 1,
          'badge': 1,
          'sound': 1,
          'announcement': 0,
          'carPlay': 0,
          'criticalAlert': 0,
          'provisional': 0,
          'showPreviews': 1,
          'timeSensitive': 0,
        };
      default:
        return null;
    }
  });
}

void _setupFirebaseAnalyticsMock() {
  const channel = MethodChannel(
    'plugins.flutter.io/firebase_analytics',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    // Return null for all analytics calls - they're fire-and-forget
    return null;
  });

  // Mock the Pigeon-based API (newer versions of firebase_analytics)
  const pigeonChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.logEvent',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pigeonChannel, (MethodCall methodCall) async {
    return null;
  });

  // Mock all Firebase Analytics Pigeon channels
  final pigeonChannels = [
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.logEvent',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setUserId',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setUserProperty',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setAnalyticsCollectionEnabled',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setSessionTimeoutDuration',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.resetAnalyticsData',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setDefaultEventParameters',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.getAppInstanceId',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.getSessionId',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.setConsent',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.initiateOnDeviceConversionMeasurementWithEmailAddress',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.initiateOnDeviceConversionMeasurementWithHashedEmailAddress',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.initiateOnDeviceConversionMeasurementWithPhoneNumber',
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.initiateOnDeviceConversionMeasurementWithHashedPhoneNumber',
  ];

  for (final channelName in pigeonChannels) {
    final channel = MethodChannel(channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  }
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
    storageBucket: 'mock-project-id.appspot.com',
  );

  @override
  FirebaseOptions get options => _mockOptions;

  @override
  String get name => defaultFirebaseAppName;

  @override
  bool get isAutomaticDataCollectionEnabled => false;
}
