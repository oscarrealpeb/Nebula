import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/welcome_screen.dart';

class NebulaApp extends StatelessWidget {
  const NebulaApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Nebula',
          debugShowCheckedModeBanner: false,
          theme: buildNebulaTheme(controller.accentColor),
          home: controller.currentUser == null
              ? WelcomeScreen(controller: controller)
              : HomeScreen(controller: controller),
        );
      },
    );
  }
}
