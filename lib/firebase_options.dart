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
    apiKey: 'AIzaSyCm8hy_WwmSPlNxO2_53YzTvp1K2D2i6FE',
    appId: '1:292167160200:web:1773f72c7d11524c7bea3d',
    messagingSenderId: '292167160200',
    projectId: 'testcalendar-ec238',
    authDomain: 'testcalendar-ec238.firebaseapp.com',
    databaseURL: 'https://testcalendar-ec238-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'testcalendar-ec238.appspot.com',
    measurementId: 'G-ZFXH1X2P1V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCQOElLoOKQh80hjmRqb3bPgMEkijrUxRI',
    appId: '1:292167160200:android:b91288719cbe28f77bea3d',
    messagingSenderId: '292167160200',
    projectId: 'testcalendar-ec238',
    databaseURL: 'https://testcalendar-ec238-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'testcalendar-ec238.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAR03oSsLOLXPZ4LGqTC7URY3qeqLAzlgw',
    appId: '1:292167160200:ios:73c102d74ec390cd7bea3d',
    messagingSenderId: '292167160200',
    projectId: 'testcalendar-ec238',
    databaseURL: 'https://testcalendar-ec238-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'testcalendar-ec238.appspot.com',
    iosClientId: '292167160200-bveeomqimgdep807ku6qmf9381jc9g4l.apps.googleusercontent.com',
    iosBundleId: 'com.example.myFlutterWebApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAR03oSsLOLXPZ4LGqTC7URY3qeqLAzlgw',
    appId: '1:292167160200:ios:73c102d74ec390cd7bea3d',
    messagingSenderId: '292167160200',
    projectId: 'testcalendar-ec238',
    databaseURL: 'https://testcalendar-ec238-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'testcalendar-ec238.appspot.com',
    iosClientId: '292167160200-bveeomqimgdep807ku6qmf9381jc9g4l.apps.googleusercontent.com',
    iosBundleId: 'com.example.myFlutterWebApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCm8hy_WwmSPlNxO2_53YzTvp1K2D2i6FE',
    appId: '1:292167160200:web:01a79ca2807ceb167bea3d',
    messagingSenderId: '292167160200',
    projectId: 'testcalendar-ec238',
    authDomain: 'testcalendar-ec238.firebaseapp.com',
    databaseURL: 'https://testcalendar-ec238-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'testcalendar-ec238.appspot.com',
    measurementId: 'G-RV2DHPWK7E',
  );

}