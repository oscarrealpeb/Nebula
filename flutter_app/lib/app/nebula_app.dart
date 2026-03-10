import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/portal_role.dart';
import '../screens/child_profile_setup_screen.dart';
import '../screens/caregiver/caregiver_panel_screen.dart';
import '../screens/home_screen.dart';
import '../screens/portal_entry_screen.dart';
import '../screens/welcome_screen.dart';

class NebulaApp extends StatelessWidget {
  const NebulaApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        Widget home;
        if (controller.currentUser == null) {
          home = WelcomeScreen(controller: controller);
        } else if (controller.isAdmin) {
          home = CaregiverPanelScreen(controller: controller);
        } else if (controller.needsChildOnboarding) {
          home = ChildProfileSetupScreen(
            controller: controller,
            isMandatory: true,
          );
        } else if (controller.needsPortalSelection) {
          home = PortalEntryScreen(controller: controller);
        } else if (controller.activePortalRole == PortalRole.child) {
          home = controller.hasChildProfile
              ? HomeScreen(controller: controller)
              : ChildProfileSetupScreen(
                  controller: controller,
                  isMandatory: true,
                );
        } else {
          home = CaregiverPanelScreen(controller: controller);
        }
        return MaterialApp(
          title: 'Habla conmigo',
          debugShowCheckedModeBanner: false,
          theme: buildNebulaTheme(controller.accentColor),
          home: home,
        );
      },
    );
  }
}
