import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

Future<bool> initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (error, stackTrace) {
    debugPrint('Firebase no inicializado. Continuamos en modo local.');
    debugPrint('$error');
    debugPrint('$stackTrace');
    return false;
  }
}
