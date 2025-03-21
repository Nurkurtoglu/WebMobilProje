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
        return android;
      case TargetPlatform.iOS:
        return ios;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyASvpGiytyJC-RKMIEhUuWLrgcAvycMH3M',
    appId: '1:478246876140:web:6cbf533782bdfd8babc6c9',
    messagingSenderId: '478246876140',
    projectId: 'study-notes-app2',
    authDomain: 'study-notes-app2.firebaseapp.com',
    storageBucket: 'study-notes-app2.firebasestorage.app',
    measurementId: 'G-RQTJDXM9DE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDNJH26RPGIRPyipeV0hSPsspN50W_rV4',
    appId: '1:478246876140:android:6f2f7fafcdc919eaabc6c9',
    messagingSenderId: '478246876140',
    projectId: 'study-notes-app2',
    storageBucket: 'study-notes-app2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBD6tFvD_HZ_yTDzztbseTFSWDpabvaLcE',
    appId: '1:478246876140:ios:5bad4a494ec721b6abc6c9',
    messagingSenderId: '478246876140',
    projectId: 'study-notes-app2',
    storageBucket: 'study-notes-app2.firebasestorage.app',
    iosBundleId: 'com.example.projeakademix',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBD6tFvD_HZ_yTDzztbseTFSWDpabvaLcE',
    appId: '1:478246876140:ios:5bad4a494ec721b6abc6c9',
    messagingSenderId: '478246876140',
    projectId: 'study-notes-app2',
    storageBucket: 'study-notes-app2.firebasestorage.app',
    iosBundleId: 'com.example.projeakademix',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyASvpGiytyJC-RKMIEhUuWLrgcAvycMH3M',
    appId: '1:478246876140:web:3958f21c3679fe21abc6c9',
    messagingSenderId: '478246876140',
    projectId: 'study-notes-app2',
    authDomain: 'study-notes-app2.firebaseapp.com',
    storageBucket: 'study-notes-app2.firebasestorage.app',
    measurementId: 'G-1DYS3MX5G0',
  );
}
