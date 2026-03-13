// File generated based on google-services.json
// For full configuration, run: dart pub global run flutterfire_cli:flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChWjZUpH8wxXBgu4z6-2iNJC6nDU0TU7E',
    appId: '1:237716638970:android:2fa0eb63546b07025fcd43',
    messagingSenderId: '237716638970',
    projectId: 'saaed-inventory',
    storageBucket: 'saaed-inventory.firebasestorage.app',
  );

  /// Web config. If you see errors, add a Web app in Firebase Console
  /// (Project Settings → Your apps → Add app → Web) and copy the appId here.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChWjZUpH8wxXBgu4z6-2iNJC6nDU0TU7E',
    appId: '1:237716638970:web:2fa0eb63546b07025fcd43',
    messagingSenderId: '237716638970',
    projectId: 'saaed-inventory',
    storageBucket: 'saaed-inventory.firebasestorage.app',
  );
}
