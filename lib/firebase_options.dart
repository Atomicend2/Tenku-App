import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2cpHaceOxL39n0UFDI1Xj1PTTmwQu2Oo',
    appId: '1:910789964826:android:e9656d85ed6104e4a70da3',
    messagingSenderId: '910789964826',
    projectId: 'tenku-ccc67',
    authDomain: 'tenku-ccc67.firebaseapp.com',
    storageBucket: 'tenku-ccc67.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2cpHaceOxL39n0UFDI1Xj1PTTmwQu2Oo',
    appId: '1:910789964826:android:e9656d85ed6104e4a70da3',
    messagingSenderId: '910789964826',
    projectId: 'tenku-ccc67',
    storageBucket: 'tenku-ccc67.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA2cpHaceOxL39n0UFDI1Xj1PTTmwQu2Oo',
    appId: '1:910789964826:android:e9656d85ed6104e4a70da3',
    messagingSenderId: '910789964826',
    projectId: 'tenku-ccc67',
    storageBucket: 'tenku-ccc67.firebasestorage.app',
    iosBundleId: 'com.tenku.app',
  );
}
