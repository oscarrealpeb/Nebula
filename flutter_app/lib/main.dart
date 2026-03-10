import 'package:flutter/material.dart';

import 'app/nebula_app.dart';
import 'controllers/app_controller.dart';
import 'firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {

    /// Inicializa Firebase de forma segura
    final firebaseEnabled = await initializeFirebaseSafely();

    /// Inicializa controlador principal de la app
    final controller = await AppController.bootstrap(
      firebaseEnabled: firebaseEnabled,
    );

    /// Inicia la aplicación
    runApp(
      NebulaApp(controller: controller),
    );

  } catch (e, stack) {

    /// Si algo falla al arrancar la app
    debugPrint("Error inicializando Nebula: $e");
    debugPrintStack(stackTrace: stack);

    runApp(
      const _StartupErrorApp(),
    );
  }
}

/// App que se muestra si falla el arranque
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            "Error iniciando Nebula",
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}