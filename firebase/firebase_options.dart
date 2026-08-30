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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2J8MPP_YPToWFLLrRC1PeJtZp8xeBPtE',
    appId: '1:244904937545:web:09629907cb2d398f441798',
    messagingSenderId: '244904937545',
    projectId: 'medical-clinical-tool',
    authDomain: 'medical-clinical-tool.firebaseapp.com',
    storageBucket: 'medical-clinical-tool.firebasestorage.app',
    measurementId: 'G-958K3SXWMH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvoe9N1oqX6mooFnt766rtnXW7Odl3aNM',
    appId: '1:244904937545:android:14cb448d76e61c5b441798',
    messagingSenderId: '244904937545',
    projectId: 'medical-clinical-tool',
    storageBucket: 'medical-clinical-tool.firebasestorage.app',
  );
}
