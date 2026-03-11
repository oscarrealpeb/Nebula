import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../controllers/app_controller.dart';
import '../widgets/nebula_snack.dart';
import '../widgets/star_difficulty_sheet.dart';
import 'game_placeholder_screen1.dart';
import 'puzzle_screen.dart';

const Color backgroundLilac = Color.fromARGB(255, 255, 255, 255);

class MinigamesScreen extends StatelessWidget {
  const MinigamesScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _openGame(
    BuildContext context, {
    required String gameName,
    required String gameKey,
  }) async {
    final check = controller.canLaunchGame(gameKey);
    if (!check.ok) {
      await NebulaSnack.show(context, message: check.message, ok: false);
      return;
    }

    final sync = await controller.syncGlobalGameContentForPlay();
    if (!context.mounted) return;
    if (!sync.ok) {
      await NebulaSnack.show(context, message: sync.message, ok: false);
      return;
    }

    if (!context.mounted) return;
    final stars = await showStarDifficultySheet(context);
    if (!context.mounted || stars == null) return;

    if (gameKey == 'arma_imagen') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PuzzleScreen(
            controller: controller,
            stars: stars,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GamePlaceholderScreen(
          controller: controller,
          gameName: gameName,
          gameKey: gameKey,
          difficultyStars: stars,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartasLabel = controller.gameLabelForKey('cartas_gemelas');
    final queLabel = controller.gameLabelForKey('que_sigue');
    final dondeLabel = controller.gameLabelForKey('donde_va');
    final armaLabel = controller.gameLabelForKey('arma_imagen');
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(controller.gameLabelForKey('minijuegos')),
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
                'Retos cortos para jugar y aprender con alegria.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF617298),
                    ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
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
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.04,
                        children: [
                          _MiniGameCard(
                            title: cartasLabel,
                            imagePath:
                                'assets/images/games/cartas_gemelas1.png',
                            onTap: () => _openGame(
                              context,
                              gameName: cartasLabel,
                              gameKey: 'cartas_gemelas',
                            ),
                            accentColor: controller.accentColor,
                          ),
                          _MiniGameCard(
                            title: queLabel,
                            imagePath: 'assets/images/games/que_sigue1.png',
                            onTap: () => _openGame(
                              context,
                              gameName: queLabel,
                              gameKey: 'que_sigue',
                            ),
                            accentColor: controller.accentColor,
                          ),
                          _MiniGameCard(
                            title: dondeLabel,
                            imagePath: 'assets/images/games/donde_va1.png',
                            onTap: () => _openGame(
                              context,
                              gameName: dondeLabel,
                              gameKey: 'donde_va',
                            ),
                            accentColor: controller.accentColor,
                          ),
                          _MiniGameCard(
                            title: armaLabel,
                            imagePath:
                                'assets/images/games/arma_la_imagen1.png',
                            onTap: () => _openGame(
                              context,
                              gameName: armaLabel,
                              gameKey: 'arma_imagen',
                            ),
                            accentColor: controller.accentColor,
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: Lottie.asset(
                            'assets/animations/minijuegos1.json',
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
    required this.accentColor,
  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: accentColor,
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
