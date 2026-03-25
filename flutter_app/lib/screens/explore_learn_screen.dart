import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/data/explore_catalog.dart';
import '../core/data/planet_ladder.dart';
import '../models/game_content_config.dart';
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
    final mergedItems = mergeExploreItems(controller.gameContentConfig.exploreItems);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Explora y aprende'),
      ),
      body: CosmicBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (var index = 0; index < exploreCategoryDefinitions.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == exploreCategoryDefinitions.length - 1 ? 0 : 14,
                ),
                child: _CategorySection(
                  title: exploreCategoryDefinitions[index].label,
                  items: exploreItemsForCategory(
                    items: mergedItems,
                    categoryId: exploreCategoryDefinitions[index].id,
                    onlyEnabled: true,
                  ),
                  unlockedCount:
                      exploreCategoryDefinitions[index].id == 'emociones'
                          ? exploreItemsForCategory(
                              items: mergedItems,
                              categoryId: exploreCategoryDefinitions[index].id,
                              onlyEnabled: true,
                            ).length
                          : math.min(
                              exploreItemsForCategory(
                                items: mergedItems,
                                categoryId: exploreCategoryDefinitions[index].id,
                                onlyEnabled: true,
                              ).length,
                              math.max(0, unlockedByPlanet),
                            ),
                ),
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
  final List<ExploreContentItem> items;
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
            if (items.isEmpty)
              Text(
                'Todavia no hay elementos configurados en esta categoria.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
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
                  final item = items[index];
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
                                title: const Text('\u00bfSabias que...?'),
                                content: Text(item.description),
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
                          unlocked
                              ? item.title
                              : '${item.title} (bloqueado)',
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
