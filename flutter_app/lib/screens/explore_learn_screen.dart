import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import 'universe_list_screen.dart';

class ExploreLearnScreen extends StatelessWidget {
  final AppController controller;

  const ExploreLearnScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final color = controller.accentButtonColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Explora y aprende"),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.9,
          children: [
            // 🐶 ANIMALES
            _ExploreCard(
              title: "ANIMALES",
              imagePath: 'assets/images/explore/animales.png',
              color: color,
              onTap: () {},
            ),

            // 🧸 COSAS
            _ExploreCard(
              title: "COSAS",
              imagePath: 'assets/images/explore/cosas.png',
              color: color,
              onTap: () {},
            ),

            // 😊 EMOCIONES
            _ExploreCard(
              title: "EMOCIONES",
              imagePath: 'assets/images/explore/emociones.png',
              color: color,
              onTap: () {},
            ),

            // 🌌 UNIVERSO
            _ExploreCard(
              title: "UNIVERSO",
              imagePath: 'assets/images/explore/universo.png',
              color: color,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UniverseListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔥 ESTE ES EL QUE TE FALTABA (MUY IMPORTANTE)
////////////////////////////////////////////////////////////

class _ExploreCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final Color color;

  const _ExploreCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}