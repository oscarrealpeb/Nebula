import 'package:flutter/material.dart';

import 'app/nebula_app.dart';
import 'controllers/app_controller.dart';
import 'firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseEnabled = await initializeFirebaseSafely();
  final controller = await AppController.bootstrap(
    firebaseEnabled: firebaseEnabled,
  );
  runApp(NebulaApp(controller: controller));
}
