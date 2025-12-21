import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config for the app. Web/desktop values remain placeholders until
/// those apps are configured in Firebase.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCs44KspLwJcp_Y5R5QQGSf2nGnC3LTyrg',
    appId: '1:662206384362:web:77c6605afaa637da1b6f93',
    messagingSenderId: '662206384362',
    projectId: 'crushhour-40c2d',
    storageBucket: 'crushhour-40c2d.firebasestorage.app',
    authDomain: 'crushhour-40c2d.firebaseapp.com',
    measurementId: 'G-L7NDHSJ0E0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-C0BfJ33omaCY6K_hNEyfFrQUrzz6tew',
    appId: '1:662206384362:android:cfd8b017e75ad4081b6f93',
    messagingSenderId: '662206384362',
    projectId: 'crushhour-40c2d',
    storageBucket: 'crushhour-40c2d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBGx1-EZsf4blCFXpd9jtqSzx1c1quGZUc',
    appId: '1:662206384362:ios:117dc807364c0e421b6f93',
    messagingSenderId: '662206384362',
    projectId: 'crushhour-40c2d',
    storageBucket: 'crushhour-40c2d.firebasestorage.app',
    iosBundleId: 'com.example.myFirstProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}
