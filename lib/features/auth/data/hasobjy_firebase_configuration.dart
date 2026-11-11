import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public app configuration from the registered Android JSON / iOS plist.
/// Server credentials never belong here. No Analytics or Messaging is enabled.
abstract final class HasobjyFirebaseConfiguration {
  static const projectId = 'cit-learn-dc483';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Mobile authentication only');
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError('Mobile authentication only'),
    };
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBD1VTkb9nz-Jkn-OvX2i7LPxKU8oxtKvU',
    appId: '1:637124336690:android:251e502c45941c9222302b',
    messagingSenderId: '637124336690',
    projectId: projectId,
    storageBucket: 'cit-learn-dc483.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDI5REel2fLcbnFP7dZxrlxR8D6N05FoiQ',
    appId: '1:637124336690:ios:5414a5f959d0362622302b',
    messagingSenderId: '637124336690',
    projectId: projectId,
    storageBucket: 'cit-learn-dc483.firebasestorage.app',
    iosBundleId: 'com.devmind.cit.learn',
    iosClientId: '637124336690-q31nv9rdo829dilk6n9d785kvafplhtp.apps.googleusercontent.com',
  );

  static Future<FirebaseAuth> initializeAuth() async {
    final options = currentPlatform;
    final app = await Firebase.initializeApp(options: options);
    if (app.options.projectId != projectId ||
        app.options.appId != options.appId) {
      throw StateError('Unexpected Firebase application');
    }
    return FirebaseAuth.instanceFor(app: app);
  }
}
