import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;


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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDF9AJOG3ld1SjNYT_riyDyTT9WZRfeiCQ',
    appId: '1:264007970281:web:cfc71d8cf4340eab4e6f78',
    messagingSenderId: '264007970281',
    projectId: 'present-me-e81de',
    authDomain: 'present-me-e81de.firebaseapp.com',
    storageBucket: 'present-me-e81de.firebasestorage.app',
    measurementId: 'G-ZK5HVQB3BV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC0YFpBPpYbnGcVFdpIdfg3UiqO4w4nLa8',
    appId: '1:264007970281:android:e24546d04ec3872e4e6f78',
    messagingSenderId: '264007970281',
    projectId: 'present-me-e81de',
    storageBucket: 'present-me-e81de.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBf8rF1pd637s85XgHfM9InVPPrOxo5q6Y',
    appId: '1:264007970281:ios:02d2bdeeefe39ff74e6f78',
    messagingSenderId: '264007970281',
    projectId: 'present-me-e81de',
    storageBucket: 'present-me-e81de.firebasestorage.app',
    iosBundleId: 'com.example.presentMeFlutter',
  );
}
