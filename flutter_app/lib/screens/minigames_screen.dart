import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/star_difficulty_sheet.dart';
import 'game_placeholder_screen1.dart';
import 'package:lottie/lottie.dart';

const Color backgroundLilac = Color.fromARGB(255, 255, 255, 255); // fondo
// const Color cardLilac = Color.fromARGB(255, 143, 115, 198);       // cards

class MinigamesScreen extends StatelessWidget {
  const MinigamesScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _openGame(
    BuildContext context, {
    required String gameName,
  }) async {
    final stars = await showStarDifficultySheet(context);
    if (!context.mounted || stars == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GamePlaceholderScreen(
          controller: controller,
          gameName: gameName,
          difficultyStars: stars,
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      title: const Text('Minijuegos'),
    ),
    backgroundColor: backgroundLilac,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige un minijuego',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF253760),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Retos cortitos para jugar y aprender con alegria.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF617298),
                  ),
            ),
            const SizedBox(height: 14),

            // 👇 ZONA CONTENIDA CON BORDE
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8), // 👈 mínimo espacio
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(width: 2, color: Color(0xFFE4E6F2)),
                    right: BorderSide(width: 2, color: Color(0xFFE4E6F2)),
                    bottom: BorderSide(width: 2, color: Color(0xFFE4E6F2)),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: Stack(
                  children: [

                    // GRID
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.04,
                      children: [
                        _MiniGameCard(
                          title: 'Cartas gemelas',
                          imagePath: 'assets/images/games/cartas_gemelas1.png',
                          onTap: () => _openGame(context, gameName: 'Cartas gemelas'),
                          accentColor: controller.accentColor, // <- aquí
                        ),
                        _MiniGameCard(
                          title: '¿Qué sigue?',
                          imagePath: 'assets/images/games/que_sigue1.png',
                          onTap: () => _openGame(context, gameName: 'Que sigue?'),
                          accentColor: controller.accentColor, // <- aquí
                        ),
                        _MiniGameCard(
                          title: '¿Dónde va?',
                          imagePath: 'assets/images/games/donde_va1.png',
                          onTap: () => _openGame(context, gameName: 'Donde va?'),
                          accentColor: controller.accentColor, // <- aquí
                        ),
                        _MiniGameCard(
                          title: 'Arma la imagen',
                          imagePath: 'assets/images/games/arma_la_imagen1.png',
                          onTap: () => _openGame(context, gameName: 'Arma la imagen'),
                          accentColor: controller.accentColor, // <- aquí
                        ),
                      ],
                    ),

                    // 🚀 ANIMACIÓN DENTRO DEL BORDE
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Lottie.asset(
                          'assets/animations/minijuegos.json',
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}


class _MiniGameCard extends StatelessWidget {
  const _MiniGameCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
    required this.accentColor, // <- nuevo

  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final Color accentColor; // <- nuevo


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: accentColor, // <- antes era cardLilac
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}