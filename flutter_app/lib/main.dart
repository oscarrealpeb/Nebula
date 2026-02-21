import 'package:flutter/material.dart';

import 'app/nebula_app.dart';
import 'controllers/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.bootstrap();
  runApp(NebulaApp(controller: controller));
}
