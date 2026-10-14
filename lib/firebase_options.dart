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
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6Ri-gSLTCyLH1T66paxOSIhEbMqv4h7A',
    appId: '1:110828752834:web:5d47b76862688a862a105b',
    messagingSenderId: '110828752834',
    projectId: 'test-multitenant-6397f',
    authDomain: 'test-multitenant-6397f.firebaseapp.com',
    storageBucket: 'test-multitenant-6397f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8o2Hp3oDH3r4qr065DishZy-FSj4PuLE',
    appId: '1:110828752834:android:659104094e40789e2a105b',
    messagingSenderId: '110828752834',
    projectId: 'test-multitenant-6397f',
    storageBucket: 'test-multitenant-6397f.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDYXHpXakb2ZgXlNQr3CQyRfu91lDJcWPk',
    appId: '1:110828752834:ios:4a3c0ac74494bdb62a105b',
    messagingSenderId: '110828752834',
    projectId: 'test-multitenant-6397f',
    storageBucket: 'test-multitenant-6397f.firebasestorage.app',
    iosBundleId: 'com.example.flutterMultiTenant',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA-MultiTenantDemoKeyMacos12345678',
    appId: '1:100000000000:ios:abcdef1234567890abcdef',
    messagingSenderId: '100000000000',
    projectId: 'multi-tenant-saas-demo',
    storageBucket: 'multi-tenant-saas-demo.appspot.com',
    iosBundleId: 'com.example.flutterMultiTenant',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA-MultiTenantDemoKeyWin1234567890',
    appId: '1:100000000000:web:abcdef1234567890abcdef',
    messagingSenderId: '100000000000',
    projectId: 'multi-tenant-saas-demo',
    authDomain: 'multi-tenant-saas-demo.firebaseapp.com',
    storageBucket: 'multi-tenant-saas-demo.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyA-MultiTenantDemoKeyLinux12345678',
    appId: '1:100000000000:web:abcdef1234567890abcdef',
    messagingSenderId: '100000000000',
    projectId: 'multi-tenant-saas-demo',
    authDomain: 'multi-tenant-saas-demo.firebaseapp.com',
    storageBucket: 'multi-tenant-saas-demo.appspot.com',
  );
}
