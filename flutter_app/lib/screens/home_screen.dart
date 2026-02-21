import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/theme/color_utils.dart';
import '../core/data/avatar_catalog.dart';
import '../core/data/planet_ladder.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/star_difficulty_sheet.dart';
import 'explore_learn_screen.dart';
import 'game_placeholder_screen.dart';
import 'minigames_screen.dart';
import 'planet_ladder_screen.dart';
import 'settings/settings_screen.dart';

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
      body: CosmicBackground(
        child: SafeArea(
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
              Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tint(shiftHue(color, -8), 0.80),
                        tint(shiftHue(color, 20), 0.88),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                    'Hola, ${user.username}!',
                                    style: const TextStyle(
                                      color: Color(0xFF22335D),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    controller.isOnline ? 'Listo para jugar' : 'Modo offline',
                                    style: const TextStyle(
                                      color: Color(0xFF4D5F86),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlanetLadderScreen(controller: controller),
                              ),
                            );
                          },
                          child: Ink(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withValues(alpha: 0.90),
                              border: Border.all(
                                color: const Color(0xFFD7E2F8),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Planeta ${planet.name}',
                                      style: const TextStyle(
                                        color: Color(0xFF253862),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${user.stars} estrellas',
                                      style: const TextStyle(
                                        color: Color(0xFF3B4E77),
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
                                    backgroundColor: const Color(0xFFE8ECF5),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFFC55E),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  remaining > 0
                                      ? 'Faltan $remaining estrellas para el siguiente planeta.'
                                      : 'Ya alcanzaste el rango maximo.',
                                  style: const TextStyle(
                                    color: Color(0xFF526488),
                                    fontSize: 12,
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
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.04,
                children: [
                  _GameCard(
                    title: 'Descubre la emocion',
                    subtitle: 'Reconoce expresiones',
                    icon: Icons.psychology_alt_outlined,
                    colorA: tint(shiftHue(color, -12), 0.76),
                    colorB: tint(shiftHue(color, -12), 0.89),
                    onTap: () => _openGame(context, gameName: 'Descubre la emocion'),
                  ),
                  _GameCard(
                    title: 'Conecta las imagenes',
                    subtitle: 'Une pares correctos',
                    icon: Icons.hub_outlined,
                    colorA: tint(shiftHue(color, 18), 0.75),
                    colorB: tint(shiftHue(color, 18), 0.89),
                    onTap: () => _openGame(context, gameName: 'Conecta las imagenes'),
                  ),
                  _GameCard(
                    title: 'Di la palabra',
                    subtitle: 'Voz y vocabulario',
                    icon: Icons.record_voice_over_outlined,
                    colorA: tint(shiftHue(color, 38), 0.74),
                    colorB: tint(shiftHue(color, 38), 0.89),
                    onTap: () => _openGame(context, gameName: 'Di la palabra'),
                  ),
                  _GameCard(
                    title: 'Explora y aprende',
                    subtitle: 'Animales y objetos',
                    icon: Icons.menu_book_outlined,
                    colorA: tint(shiftHue(color, -34), 0.76),
                    colorB: tint(shiftHue(color, -34), 0.90),
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
                        title: 'Minijuegos',
                        subtitle: '4 retos cortitos',
                        icon: Icons.extension_rounded,
                        colorA: tint(shiftHue(color, 55), 0.78),
                        colorB: tint(shiftHue(color, 55), 0.90),
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

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.colorA,
    required this.colorB,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color colorA;
  final Color colorB;

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
                Icon(icon, size: 32, color: const Color(0xFF354D7F)),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A5A7D),
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
