import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/data/planet_ladder.dart';
import '../widgets/cosmic_background.dart';

class ExploreLearnScreen extends StatelessWidget {
  const ExploreLearnScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();

    final progressStars = controller.progressStars;
    final planetIndex = planetLadder.indexOf(planetForStars(progressStars));
    final unlockedByPlanet = 3 + planetIndex;

    final animals = [
      'Perro',
      'Gato',
      'Pajaro',
      'Leon',
      'Elefante',
      'Pinguino',
      'Delfin',
      'Lobo',
    ];
    final objects = [
      'Pelota',
      'Libro',
      'Avion',
      'Bicicleta',
      'Reloj',
      'Luna',
      'Cohete',
      'Planeta',
    ];
    final emotions = [
      'Feliz',
      'Triste',
      'Enojado',
      'Sorprendido',
      'Calmado',
      'Asustado',
    ];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Explora y aprende'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CategorySection(
              title: 'Animales',
              items: animals,
              unlockedCount: unlockedByPlanet.clamp(3, animals.length).toInt(),
            ),
            const SizedBox(height: 14),
            _CategorySection(
              title: 'Cosas',
              items: objects,
              unlockedCount: unlockedByPlanet.clamp(3, objects.length).toInt(),
            ),
            const SizedBox(height: 14),
            _CategorySection(
              title: 'Emociones',
              items: emotions,
              unlockedCount: emotions.length,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.items,
    required this.unlockedCount,
  });

  final String title;
  final List<String> items;
  final int unlockedCount;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, index) {
                final unlocked = index < unlockedCount;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: unlocked
                      ? () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              title: const Text('Sabias que...?'),
                              content: Text(
                                '${items[index]} aparece en varios retos para reforzar el aprendizaje visual y verbal.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: unlocked
                          ? primary.withValues(alpha: 0.12)
                          : const Color(0xFFE7E7E7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        unlocked ? items[index] : '${items[index]} (bloqueado)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: unlocked
                              ? const Color(0xFF203666)
                              : const Color(0xFF808080),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
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
