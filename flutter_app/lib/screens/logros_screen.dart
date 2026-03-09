import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../core/data/achievement_catalog.dart';
import 'planet_ladder_screen.dart';

class LogrosScreen extends StatelessWidget {
  const LogrosScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();
    final accent = controller.accentColor;
    final unlocked = user.unlockedAchievementIds.toSet();
    final unlockedCount = achievementCatalog
        .where((achievement) => unlocked.contains(achievement.id))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Desbloqueados: $unlockedCount de ${achievementCatalog.length}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.80,
              ),
              itemCount: achievementCatalog.length,
              itemBuilder: (context, index) {
                final achievement = achievementCatalog[index];
                final isUnlocked = unlocked.contains(achievement.id);
                return _AchievementCard(
                  achievement: achievement,
                  unlocked: isUnlocked,
                  accent: accent,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PlanetLadderScreen(controller: controller),
                      ),
                    );
                  },
                  child: _BottomTabButton(
                    label: 'Planetas',
                    selected: false,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                _BottomTabButton(
                  label: 'Logros',
                  selected: true,
                  color: accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
    required this.accent,
  });

  final AchievementDefinition achievement;
  final bool unlocked;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tone = unlocked ? achievement.iconColor : Colors.grey.shade500;

    return Card(
      color: unlocked
          ? achievement.iconColor.withValues(alpha: 0.09)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: unlocked ? achievement.iconColor : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement.icon,
              size: 40,
              color: tone,
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: unlocked ? Colors.black : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: unlocked ? Colors.black87 : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: unlocked
                    ? achievement.iconColor.withValues(alpha: 0.16)
                    : Colors.grey.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unlocked ? 'Desbloqueado' : 'Bloqueado',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTabButton extends StatelessWidget {
  const _BottomTabButton({
    required this.label,
    required this.selected,
    required this.color,
  });

  final String label;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      constraints: const BoxConstraints(
        minWidth: 140,
        minHeight: 50,
      ),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
