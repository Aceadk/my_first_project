import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default Firebase configuration for supported Crush platforms.
///
/// This keeps startup deterministic across mobile, desktop, and web.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => macos,
      TargetPlatform.windows => windows,
      _ => throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for this platform.',
      ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBFXkqAFLzZm8TZe0wNmvxXPWlK2a0n_XM',
    appId: '1:72015170328:web:843883af66c2defe17ec6d',
    messagingSenderId: '72015170328',
    projectId: 'crush-265f7',
    authDomain: 'crush-265f7.firebaseapp.com',
    storageBucket: 'crush-265f7.firebasestorage.app',
    databaseURL: 'https://crush-265f7-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4gYpqwSFXzMgfTZF1LPMZZ92M0-Fwi7M',
    appId: '1:72015170328:android:2d9554cc4d9596ad17ec6d',
    messagingSenderId: '72015170328',
    projectId: 'crush-265f7',
    storageBucket: 'crush-265f7.firebasestorage.app',
    databaseURL: 'https://crush-265f7-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBfdagoHbSSr8n76h1il_yPE0WCP84vEyc',
    appId: '1:72015170328:ios:9f25dd836575951117ec6d',
    messagingSenderId: '72015170328',
    projectId: 'crush-265f7',
    storageBucket: 'crush-265f7.firebasestorage.app',
    iosBundleId: 'com.ace.crush',
    iosClientId:
        '72015170328-er7n0bjh53bj6favk67m3ebduqa2952b.apps.googleusercontent.com',
    databaseURL: 'https://crush-265f7-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBfdagoHbSSr8n76h1il_yPE0WCP84vEyc',
    appId: '1:72015170328:ios:9f25dd836575951117ec6d',
    messagingSenderId: '72015170328',
    projectId: 'crush-265f7',
    storageBucket: 'crush-265f7.firebasestorage.app',
    iosBundleId: 'com.ace.crush',
    iosClientId:
        '72015170328-er7n0bjh53bj6favk67m3ebduqa2952b.apps.googleusercontent.com',
    databaseURL: 'https://crush-265f7-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBFXkqAFLzZm8TZe0wNmvxXPWlK2a0n_XM',
    appId: '1:72015170328:web:843883af66c2defe17ec6d',
    messagingSenderId: '72015170328',
    projectId: 'crush-265f7',
    authDomain: 'crush-265f7.firebaseapp.com',
    storageBucket: 'crush-265f7.firebasestorage.app',
    databaseURL: 'https://crush-265f7-default-rtdb.firebaseio.com',
  );
}
