// firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('FirebaseOptions have not been configured for Web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBP04GtOUqUIm-iufYoSfHRJXaZhUYHUkk',
    appId: '1:1017336705068:android:36f5ac9d9ac4424e2f2189',
    messagingSenderId: '1017336705068',
    projectId: 'it-english-app-clean',
    storageBucket: 'it-english-app-clean.appspot.com',
  );
}
