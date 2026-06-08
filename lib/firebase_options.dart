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
    apiKey: 'AIzaSyDZe3kiO3HJUJ2XcZsWCW7YaQE3gY6iDJs',
    appId: '1:305121585498:web:b7908d98389c8752a0ab63',
    messagingSenderId: '305121585498',
    projectId: 'crush-f5352',
    authDomain: 'crush-f5352.firebaseapp.com',
    storageBucket: 'crush-f5352.firebasestorage.app',
    measurementId: 'G-VYN87B0YBR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvqQwCPPLdI1rJR1PQoUOo5bpkbou7A0o',
    appId: '1:305121585498:android:37d3912047732785a0ab63',
    messagingSenderId: '305121585498',
    projectId: 'crush-f5352',
    storageBucket: 'crush-f5352.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDo1H-39hL37B0IW2GkDbCMveYRBANKoVw',
    appId: '1:305121585498:ios:3d67f77928072ef8a0ab63',
    messagingSenderId: '305121585498',
    projectId: 'crush-f5352',
    storageBucket: 'crush-f5352.firebasestorage.app',
    iosBundleId: 'com.ace.crush',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDo1H-39hL37B0IW2GkDbCMveYRBANKoVw',
    appId: '1:305121585498:ios:3d67f77928072ef8a0ab63',
    messagingSenderId: '305121585498',
    projectId: 'crush-f5352',
    storageBucket: 'crush-f5352.firebasestorage.app',
    iosBundleId: 'com.ace.crush',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDZe3kiO3HJUJ2XcZsWCW7YaQE3gY6iDJs',
    appId: '1:305121585498:web:b7908d98389c8752a0ab63',
    messagingSenderId: '305121585498',
    projectId: 'crush-f5352',
    authDomain: 'crush-f5352.firebaseapp.com',
    storageBucket: 'crush-f5352.firebasestorage.app',
    measurementId: 'G-VYN87B0YBR',
  );
}
