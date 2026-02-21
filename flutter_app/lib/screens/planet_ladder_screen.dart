import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/data/planet_ladder.dart';
import '../widgets/cosmic_background.dart';

class PlanetLadderScreen extends StatelessWidget {
  const PlanetLadderScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();

    final currentPlanet = planetForStars(user.stars);
    final progress = planetProgress(user.stars);
    final remaining = starsToNextPlanet(user.stars);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Escalera de planetas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Estrellas: ${user.stars}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: CosmicBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: planetLadder.length,
          itemBuilder: (context, index) {
            final planet = planetLadder[index];
            final locked = user.stars < planet.minStars;
            final isCurrent = planet.name == currentPlanet.name;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: locked ? 0.45 : 1,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              planet.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const Spacer(),
                            Text('${planet.minStars}-${planet.maxStars} estrellas'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Recompensa: ${planet.reward}'),
                        if (isCurrent) ...[
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 6),
                          Text(
                            remaining > 0
                                ? 'Te faltan $remaining estrellas (${(progress * 100).toStringAsFixed(0)}%).'
                                : 'Planeta completado.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
