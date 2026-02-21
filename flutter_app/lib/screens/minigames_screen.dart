import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/theme/color_utils.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/star_difficulty_sheet.dart';
import 'game_placeholder_screen.dart';

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
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Minijuegos'),
      ),
      body: CosmicBackground(
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
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.04,
                  children: [
                    _MiniGameCard(
                      title: 'Cartas gemelas',
                      icon: Icons.style_outlined,
                      colorA: tint(shiftHue(color, -12), 0.76),
                      colorB: tint(shiftHue(color, -12), 0.89),
                      onTap: () => _openGame(context, gameName: 'Cartas gemelas'),
                    ),
                    _MiniGameCard(
                      title: 'Que sigue?',
                      icon: Icons.timeline_rounded,
                      colorA: tint(shiftHue(color, 18), 0.75),
                      colorB: tint(shiftHue(color, 18), 0.89),
                      onTap: () => _openGame(context, gameName: 'Que sigue?'),
                    ),
                    _MiniGameCard(
                      title: 'Donde va?',
                      icon: Icons.place_outlined,
                      colorA: tint(shiftHue(color, 38), 0.74),
                      colorB: tint(shiftHue(color, 38), 0.89),
                      onTap: () => _openGame(context, gameName: 'Donde va?'),
                    ),
                    _MiniGameCard(
                      title: 'Arma la imagen',
                      icon: Icons.grid_view_rounded,
                      colorA: tint(shiftHue(color, -34), 0.76),
                      colorB: tint(shiftHue(color, -34), 0.90),
                      onTap: () => _openGame(context, gameName: 'Arma la imagen'),
                    ),
                  ],
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
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorA, colorB],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30, color: const Color(0xFF354D7F)),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
