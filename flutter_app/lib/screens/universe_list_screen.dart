import 'package:flutter/material.dart';
import '../controllers/universe_controller.dart';

class UniverseListScreen extends StatelessWidget {
  const UniverseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explora el Universo"),
        backgroundColor: const Color(0xFF0A0E21),
      ),
      body: const UniverseGrid(), // Llamamos al grid que ya tienes
    );
  }
}