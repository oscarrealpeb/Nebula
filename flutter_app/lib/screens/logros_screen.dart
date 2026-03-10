import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import 'planet_ladder_screen.dart';

class LogrosScreen extends StatelessWidget {
  const LogrosScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) return const SizedBox.shrink();

    final accent = controller.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];

                final unlocked = user.stars >= achievement.requiredStars;

                return _AchievementCard(
                  achievement: achievement,
                  unlocked: unlocked,
                  accent: accent,
                );
              },
            ),
          ),

          /// BOTONES INFERIORES
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
                    label: "Planetas",
                    selected: false,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                _BottomTabButton(
                  label: "Logros",
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

/// MODELO SIMPLE
class Achievement {
  final String title;
  final String description;
  final int requiredStars;

  Achievement({
    required this.title,
    required this.description,
    required this.requiredStars,
  });
}

/// LISTA DE 20 LOGROS
final List<Achievement> achievements = [

  Achievement(
    title: "Primer Paso",
    description: "Completa tu primera actividad.",
    requiredStars: 50,
  ),
  Achievement(
    title: "Explorador Curioso",
    description: "Descubre 5 cartas nuevas.",
    requiredStars: 150,
  ),
  Achievement(
    title: "Concentración Nivel 1",
    description: "Mantente enfocado en una actividad completa.",
    requiredStars: 250,
  ),
  Achievement(
    title: "Amigo de los Animales",
    description: "Desbloquea 3 cartas de animales.",
    requiredStars: 400,
  ),
  Achievement(
    title: "Valiente",
    description: "Intenta una actividad nueva.",
    requiredStars: 600,
  ),
  Achievement(
    title: "Memoria Activa",
    description: "Completa 3 actividades seguidas sin errores.",
    requiredStars: 800,
  ),
  Achievement(
    title: "Observador Estelar",
    description: "Explora un planeta completo.",
    requiredStars: 1200,
  ),
  Achievement(
    title: "Comunicación Pro",
    description: "Usa correctamente 5 cartas de comunicación.",
    requiredStars: 1500,
  ),
  Achievement(
    title: "Maestro del Juego",
    description: "Completa 10 actividades.",
    requiredStars: 1800,
  ),
  Achievement(
    title: "Control Emocional",
    description: "Termina una actividad difícil con calma.",
    requiredStars: 2100,
  ),
  Achievement(
    title: "Pensador Lógico",
    description: "Resuelve 5 actividades de secuencia.",
    requiredStars: 2500,
  ),
  Achievement(
    title: "Gran Explorador",
    description: "Viaja a un nuevo planeta.",
    requiredStars: 3000,
  ),
  Achievement(
    title: "Atención Máxima",
    description: "Mantente concentrado durante 10 minutos.",
    requiredStars: 3500,
  ),
  Achievement(
    title: "Super Memoria",
    description: "Completa una actividad avanzada.",
    requiredStars: 4000,
  ),
  Achievement(
    title: "Coleccionista",
    description: "Desbloquea 10 cartas.",
    requiredStars: 4500,
  ),
  Achievement(
    title: "Pensamiento Flexible",
    description: "Resuelve una actividad con más de una solución.",
    requiredStars: 5000,
  ),
  Achievement(
    title: "Explorador Galáctico",
    description: "Completa 5 planetas.",
    requiredStars: 6000,
  ),
  Achievement(
    title: "Comunicación Estrella",
    description: "Usa correctamente 10 cartas sociales.",
    requiredStars: 6500,
  ),
  Achievement(
    title: "Constancia Total",
    description: "Juega durante 7 días seguidos.",
    requiredStars: 7500,
  ),
  Achievement(
    title: "Campeón del Universo",
    description: "Alcanza el máximo nivel.",
    requiredStars: 9000,
  ),
];

/// CARD
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
    required this.accent,
  });

  final Achievement achievement;
  final bool unlocked;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: unlocked ? accent.withOpacity(0.08) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: unlocked ? accent : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 40,
              color: unlocked ? accent : Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: unlocked ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: unlocked ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// BOTÓN INFERIOR
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
        color: selected ? color : color.withOpacity(0.2),
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