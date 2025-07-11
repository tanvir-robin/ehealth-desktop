// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC1JHkIsrdWw6dG1c3M15pYuJwbrKffRiU',
    appId: '1:447061470523:ios:7521dfecbbee7f2cbb1b1e',
    messagingSenderId: '447061470523',
    projectId: 'healthcare-algorix',
    storageBucket: 'healthcare-algorix.firebasestorage.app',
    iosBundleId: 'com.example.ehealthDesktop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAeQqpOEs83pa7IT09ThlKSf9X6_vCkU9U',
    appId: '1:447061470523:web:b5e4feec7087afe2bb1b1e',
    messagingSenderId: '447061470523',
    projectId: 'healthcare-algorix',
    authDomain: 'healthcare-algorix.firebaseapp.com',
    storageBucket: 'healthcare-algorix.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBxTwyEaVEgPOB3SYX5jAtYFdOGyMYgmm0',
    appId: '1:447061470523:web:00f410aa308c2b2ebb1b1e',
    messagingSenderId: '447061470523',
    projectId: 'healthcare-algorix',
    authDomain: 'healthcare-algorix.firebaseapp.com',
    storageBucket: 'healthcare-algorix.firebasestorage.app',
  );

}