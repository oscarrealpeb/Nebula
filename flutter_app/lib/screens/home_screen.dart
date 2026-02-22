import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
// import '../core/theme/color_utils.dart';
import '../core/data/avatar_catalog.dart';
import '../core/data/planet_ladder.dart';
// import '../widgets/cosmic_background.dart';
import '../widgets/star_difficulty_sheet.dart';
import 'explore_learn_screen.dart';
import 'game_placeholder_screen.dart';
import 'minigames_screen.dart';
import 'planet_ladder_screen.dart';
import 'settings/settings_screen.dart';

const Color backgroundLilac = Color.fromARGB(255, 255, 255, 255); // fondo
const Color cardLilac = Color.fromARGB(255, 143, 115, 198);       // cards

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

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
    
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.primary;
    final planet = planetForStars(user.stars);
    final progress = planetProgress(user.stars);
    final remaining = starsToNextPlanet(user.stars);
    final avatarIndex = user.avatarIndex.clamp(0, avatarCatalog.length - 1).toInt();
    final avatar = avatarCatalog[avatarIndex];
    

    return Scaffold(
      backgroundColor: backgroundLilac,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.rocket_launch_rounded,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Nebula',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(controller: controller),
                        ),
                      );
                    },
                    child: Ink(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                      child: const Icon(Icons.settings_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _WelcomeStatusCard(
                accentColor: controller.accentButtonColor,
                username: user.username,
                avatar: avatar,
                isOnline: controller.isOnline,
                planetName: planet.name,
                stars: user.stars,
                progress: progress,
                remaining: remaining,
                onPlanetTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlanetLadderScreen(controller: controller),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              const _SectionHeader(
                title: 'Juegos divertidos',
                subtitle: 'Escoge una aventura y suma estrellitas',
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
                children: [
                  _GameCard(
                    title: 'DESCUBRE',
                    
                    imagePath: 'assets/images/games/descubre_emocion1.png',
                    onTap: () => _openGame(context, gameName: 'Descubre la emocion'),
                    accentColor: controller.accentButtonColor,
                  ),
                  _GameCard(
                    title: 'CONECTA',
                    imagePath: 'assets/images/games/conecta_imagenes1.png',
                    accentColor: controller.accentButtonColor,
                    onTap: () => _openGame(context, gameName: 'Conecta las imagenes'),
                  ),
                  _GameCard(
                    title: 'DILO',
                    imagePath: 'assets/images/games/di_palabra1.png',
                    accentColor: controller.accentButtonColor,
                    onTap: () => _openGame(context, gameName: 'Di la palabra'),
                  ),
                  _GameCard(
                    title: 'EXPLORA',
                    imagePath: 'assets/images/games/explora_aprende1.png',
                    accentColor: controller.accentButtonColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExploreLearnScreen(controller: controller),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 10) / 2;
                  final cardHeight = cardWidth / 1.04;
                  return Center(
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _GameCard(
                        title: 'MINIJUEGOS',
                        imagePath: 'assets/images/games/minijuegos1.png',
                        accentColor: controller.accentButtonColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MinigamesScreen(controller: controller),
                            ),
                          );
                        },
                      ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF253760),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF607297),
              ),
        ),
      ],
    );
  }
}

class _WelcomeStatusCard extends StatelessWidget {
  const _WelcomeStatusCard({
    required this.username,
    required this.avatar,
    required this.isOnline,
    required this.planetName,
    required this.stars,
    required this.progress,
    required this.remaining,
    required this.onPlanetTap,
    required this.accentColor,
  });

  final String username;
  final String avatar;
  final bool isOnline;
  final String planetName;
  final int stars;
  final double progress;
  final int remaining;
  final VoidCallback onPlanetTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,   
      color: accentColor,   
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    avatar,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $username!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline ? 'Listo para jugar' : 'Modo offline',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPlanetTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Planeta $planetName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$stars ⭐',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remaining > 0
                          ? 'Faltan $remaining estrellas.'
                          : 'Rango máximo alcanzado.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _GameCard extends StatelessWidget {
  const _GameCard({
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
        child: Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withValues(alpha: 0.25),
        blurRadius: 10,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
