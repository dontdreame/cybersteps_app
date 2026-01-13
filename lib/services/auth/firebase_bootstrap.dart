import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;

  /// Initialize Firebase (safe). If native config is missing, this will throw.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await Firebase.initializeApp();
    _initialized = true;
  }
}
